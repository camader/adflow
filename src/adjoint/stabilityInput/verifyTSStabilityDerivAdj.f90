!
!     ******************************************************************
!     *                                                                *
!     * File:          verifyTSStabilityDerivAdj.f90                   *
!     * Author:        C.A.(Sandy) Mader                               *
!     * Starting date: 11-26-2009                                      *
!     * Last modified: 11-26-2009                                      *
!     *                                                                *
!     ******************************************************************
!
      subroutine verifyTSStabilityDerivAdj(level)
!
!     ******************************************************************
!     *                                                                *
!     * Computes the Time spectral stability derivatives for the       *
!     * current configuration for the finest grid level over all time  *
!     * instances using the                                            *
!     * auxiliary routines modified for tapenade and compares them to  *
!     * the stability derivatives computed with the original code.     *
!     *                                                                *
!     * This is only executed in debug mode.                           *
!     *                                                                *
!     ******************************************************************
!
      use blockPointers
      use communication       ! myID
      use inputPhysics        !
      use flowVarRefState     !
      use inputDiscretization ! spaceDiscr
      use iteration           ! currentLevel
      use monitor             ! monLoc, MonGlob, nMonSum
      use inputTimeSpectral   ! nTimeInstancesMax
      use section             !nsections, sections%
      use bcTypes             ! EulerWall, NSWallAdiabatic, NSWallIsothermal
      use monitor             ! timeunsteady...
      
      implicit none
!
!     Subroutine arguments.
!
      integer(kind=intType), intent(in) :: level
!
!     Local variables.
!
      integer(kind=intType) :: discr, nHalo
      integer(kind=intType) :: mm, nn, sps,nnn

      logical :: fineGrid, correctForK, exchangeTurb

      integer(kind=intType)::liftIndex

      real(kind=realType), dimension(:,:,:,:), allocatable :: xAdj,wAdj
      real(kind=realType), dimension(:,:,:), allocatable :: pAdj
!      real(kind=realType), dimension(:,:,:,:), allocatable :: siAdj, sjAdj, skAdj

      real(kind=realType), dimension(3) ::rotRateAdj,rotCenterAdj
      
      integer(kind=intType) :: i2Beg, i2End, j2Beg, j2End
      integer(kind=intType) :: iiBeg, iiEnd, jjBeg, jjEnd

      real(kind=realType), dimension(3) :: cFpAdj, cFvAdj
      real(kind=realType), dimension(3) :: cMpAdj, cMvAdj

      real(kind=realType), dimension(3) :: cFp, cFv
      real(kind=realType), dimension(3) :: cMp, cMv

      real(kind=realType), dimension(3) :: cFpFD, cFvFD
      real(kind=realType), dimension(3) :: cMpFD, cMvFD

      real(kind=realType), dimension(nTimeIntervalsSpectral) :: Cl,Cd,Cfx,Cfy,Cfz,Cmx,Cmy,Cmz
      real(kind=realType), dimension(nTimeIntervalsSpectral) :: ClAdj,CdAdj,CfxAdj,CfyAdj,CfzAdj, &
                                                           CmxAdj,CmyAdj,CmzAdj
!      real(kind=realType), dimension(:,:,:),allocatable:: normAdj
      real(kind=realType), dimension(3) :: refPoint
      real(kind=realType) :: yplusMax

      real(kind=realType) :: alphaAdj, betaAdj,MachAdj,machCoefAdj,machGridAdj
      REAL(KIND=REALTYPE) :: prefAdj, rhorefAdj,pInfCorrAdj
      REAL(KIND=REALTYPE) :: pinfdimAdj, rhoinfdimAdj
      REAL(KIND=REALTYPE) :: rhoinfAdj, pinfAdj
      REAL(KIND=REALTYPE) :: murefAdj, timerefAdj

      integer(kind=intType) :: nmonsum2 ,i
      real(kind=realType),  dimension(:), allocatable :: monLoc1, monGlob1
      real(kind=realType),  dimension(:), allocatable :: monLoc2, monGlob2

      real(kind=realType) :: fact!temporary

      logical :: contributeToForce, viscousSubface,secondhalo

      integer :: ierr

      real(kind=realType)::dcldp,dcldpdot,dcmzdp,dcmzdpdot         
      real(kind=realType)::dcldq,dcldqdot,dcmzdq,dcmzdqdot
      real(kind=realType)::dcldr,dcldrdot,dcmzdr,dcmzdrdot
      real(kind=realType)::dcldalpha,dcldalphadot,dcmzdalpha,dcmzdalphadot
      real(kind=realType)::dcldMach,dcldMachdot,dcmzdMach,dcmzdMachdot
      real(kind=realType)::cl0,cl0dot,cmz0,cmz0dot

      real(kind=realType)::cl0Adj,cmz0Adj,dcldalphaAdj,dcmzdalphaAdj

      real(kind=realType), dimension(nSections) :: t
!for debug
real(kind=realType), dimension(3) :: cfpadjout, cmpadjout
!
!     ******************************************************************
!     *                                                                *
!     * Begin execution.                                               *
!     *                                                                *
!     ******************************************************************
!
      if(myID == 0) then
        write(*,*) "Running verifyTSStabilityDerivAdj..."
        !write(*,10) "CL","CD","Cfx","Cmx"
      endif

      ! Set the grid level of the current MG cycle, the value of the
      ! discretization and the logical fineGrid.

      currentLevel = level
      discr        = spaceDiscr
      fineGrid     = .true.

      ! Determine whether or not the total energy must be corrected
      ! for the presence of the turbulent kinetic energy and whether
      ! or not turbulence variables should be exchanged.

      correctForK  = .false.
      exchangeTurb = .false.
      secondhalo = .true.
!
!     ******************************************************************
!     *                                                                *
!     * Exchange halo data to make sure it is up-to-date.              *
!     * (originally called inside "rungeKuttaSmoother" subroutine).    *
!     *                                                                *
!     ******************************************************************

      ! allocate monLoc2, monGlob2

      nmonsum2 = 8
 !     print *,'allocating monsum'
      allocate(monLoc1(nmonsum2), monGlob1(nmonsum2))
      allocate(monLoc2(nmonsum2), monGlob2(nmonsum2))

!      print *,'exchanging halo data'
      ! Exchange the pressure if the pressure must be exchanged early.
      ! Only the first halo's are needed, thus whalo1 is called.
      ! Only on the fine grid.
      
      if(exchangePressureEarly .and. currentLevel <= groundLevel) &
           call whalo1(currentLevel, 1_intType, 0_intType, .true.,&
           .false., .false.)
      
      ! Apply all boundary conditions to all blocks on this level.
      
      call applyAllBC(secondHalo)
      
      ! Exchange the solution. Either whalo1 or whalo2
      ! must be called.
      
      if( secondHalo ) then
         call whalo2(currentLevel, 1_intType, nMGVar, .true., &
              .true., .true.)
      else
         call whalo1(currentLevel, 1_intType, nMGVar, .true., &
              .true., .true.)
      endif

      call mpi_barrier(SUmb_comm_world, ierr)      
!
!     ******************************************************************
!     *                                                                *
!     * Compute the stability derivatives using the original routine.  *
!     *                                                                *
!     ******************************************************************
!
      dcldalpha = 0.0
      dcmzdalpha = 0.0
      call computeTSDerivatives(cl0,cmz0,dcldalpha,dcmzdalpha)
      
!
!     ******************************************************************
!     *                                                                *
!     * Compute the forces using the tapenade routines.                *
!     *                                                                *
!     ******************************************************************
        
!     ******************************************************************
!     * From forcesAndMoments.f90                                      *
!     * Determine the reference point for the moment computation in    *
!     * meters.                                                        *
!     ******************************************************************
 !     print *,' starting Tapenade routines'
      refPoint(1) = LRef*pointRef(1)
      refPoint(2) = LRef*pointRef(2)
      refPoint(3) = LRef*pointRef(3)

      ! Initialize the force and moment coefficients to 0 as well as
      ! yplusMax.
     
      ClAdj  = zero
      CDAdj  = zero
      CmxAdj = zero
      CmyAdj = zero
      CmzAdj = zero
      CfxAdj = zero
      CfyAdj = zero
      CfzAdj = zero

      yplusMax = zero

      spectralLoopAdj: do sps=1,nTimeIntervalsSpectral

         !zero the force components
         cFpAdj(1) = zero; cFpAdj(2) = zero; cFpAdj(3) = zero
         cFvAdj(1) = zero; cFvAdj(2) = zero; cFvAdj(3) = zero
         cMpAdj(1) = zero; cMpAdj(2) = zero; cMpAdj(3) = zero
         cMvAdj(1) = zero; cMvAdj(2) = zero; cMvAdj(3) = zero
         

         ! Loop over the number of local blocks.
         
         domainForcesLoop: do nn=1,nDom
         !   print *,'setting pointers'
            ! Set some pointers to make the code more readable.
            call setPointersAdj(nn,groundlevel,sps)
          !  print *,'allocating'
            allocate(xAdj(0:ie,0:je,0:ke,3), stat=ierr)
            if(ierr /= 0)                              &
                 call terminate("Memory allocation failure for xAdj.")

  
            allocate(wAdj(0:ib,0:jb,0:kb,nw), stat=ierr)
            if(ierr /= 0)                              &
                 call terminate("Memory allocation failure for wAdj.")

            allocate(pAdj(0:ib,0:jb,0:kb), stat=ierr)
            if(ierr /= 0)                              &
                 call terminate("Memory allocation failure for pAdj.")

            righthanded = flowDoms(nn,level,sps)%righthanded

          !  print *,'copying stencil'
            ! Copy the coordinates into xAdj and
            ! Compute the face normals on the subfaces
            call  copyADjointForcesStencil(wAdj,xAdj,alphaAdj,betaAdj,&
           MachAdj,machCoefAdj,machGridAdj,prefAdj,rhorefAdj, pinfdimAdj,&
           rhoinfdimAdj,rhoinfAdj, pinfAdj,rotRateAdj,rotCenterAdj,murefAdj,&
           timerefAdj,pInfCorrAdj,nn,level,sps,liftIndex)

            !call copyADjointForcesStencil(wAdj,xAdj,nn,level,sps)

            bocoLoop: do mm=1,nBocos
               ! Check if this BC needs force integration (Either EulerWall or NSWall)

!s               invForce: if(BCType(mm) == EulerWall        .or. &
!s                            BCType(mm) == NSWallAdiabatic .or.  &
!s                            BCType(mm) == NSWallIsothermal) then
           !    print *,'setting indicies'
                  ! Determine the range of cell indices of the owned cells
                  ! Notice these are not the node indices
                  iiBeg = BCData(mm)%icBeg
                  iiEnd = BCData(mm)%icEnd
                  jjBeg = BCData(mm)%jcBeg
                  jjEnd = BCData(mm)%jcEnd

                  i2Beg= BCData(mm)%inBeg+1; i2End = BCData(mm)%inEnd
                  j2Beg= BCData(mm)%jnBeg+1; j2End = BCData(mm)%jnEnd


!                  allocate(normAdj(iiBeg:iiEnd,jjBeg:jjEnd,3), stat=ierr)
!                  ! Allocate the memory for the full block stencil
 
!                  allocate(siAdj(1:2,iiBeg:iiEnd,jjBeg:jjEnd,3), stat=ierr)
!                  if(ierr /= 0)                              &
!                       call terminate("Memory allocation failure for siAdj.")
                  
!                  allocate(sjAdj(iiBeg:iiEnd,1:2,jjBeg:jjEnd,3), stat=ierr)
!                  if(ierr /= 0)                              &
!                       call terminate("Memory allocation failure for sjAdj.")
                  
!                  allocate(skAdj(iiBeg:iiEnd,jjBeg:jjEnd,1:2,3), stat=ierr)
!                  if(ierr /= 0)                              &
!                       call terminate("Memory allocation failure for skAdj.")
                  

                  t = timeUnsteadyRestart
                  
                  if(equationMode == timeSpectral) then
                     do nnn=1,nSections
                        !t(nnn) = t(nnn) + (sps2-1)*sections(nnn)%timePeriod &
                        !     /         real(nTimeIntervalsSpectral,realType)
                        t(nnn) = t(nnn) + (sps-1)*sections(nnn)%timePeriod &
                             /         (nTimeIntervalsSpectral*1.0)!to make denomenator a real number...
                     enddo
                  endif
               !   print *,'calling computeforces',mm,nn

                  call computeForcesAdj(xAdj,wAdj,pAdj, &
                       iiBeg,iiEnd,jjBeg,jjEnd,i2Beg,i2End,j2Beg,j2End, &
                       mm,cFxAdj,cFyAdj,cFzAdj,cMxAdj,cMyAdj,cMzAdj,&
                       yplusMax,refPoint,CLAdj,CDAdj,  &
                       nn,level,sps,cFpAdj,cMpAdj,righthanded,secondhalo,&
                       alphaAdj,betaAdj,machAdj,machcoefAdj,machGridAdj,&
                       prefAdj,rhorefAdj, pinfdimAdj, rhoinfdimAdj,&
                       rhoinfAdj, pinfAdj,murefAdj, timerefAdj,pInfCorrAdj,&
                       rotCenterAdj, rotRateAdj,liftIndex,t)
                  !print *,'forces computed'
                  !print *,'cfpadj',cfpadj,cmpadj,'cladj',cladj,'cdadj',cdadj


!                  deallocate(normAdj,siAdj,sjAdj,skAdj)
!               end if invForce


            end do bocoLoop
!            print *,'deallocating p'
            deallocate(pAdj)
!            print *,'deallocating w'
            deallocate(wAdj)
 !           print *,'deallocating x'
            deallocate(xAdj)
  !          print *,'deallocation finished'
!            deallocate(wAdj)
      

         end do domainForcesLoop
     !    print *,'finished domain loop'
!write(*,'(a5,2i5,7g)')'adj',myID,sps,ClAdj(sps),cfpadjout(1),cfpadjout(2),cfpadjout(3),cmpadjout(1),cmpadjout(2),cmpadjout(3)      
         monLoc2(1) = CLAdj(sps)
         monLoc2(2) = CDAdj(sps)
         monLoc2(3) = CfxAdj(sps)
         monLoc2(4) = CfyAdj(sps)
         monLoc2(5) = CfzAdj(sps)
         monLoc2(6) = CMxAdj(sps)
         monLoc2(7) = CMyAdj(sps)
         monLoc2(8) = CMzAdj(sps)
         
         ! Determine the global sum of the summation monitoring
         ! variables. The sum is made known to all processors.
!         write(*,*)'adj ',myID,monLoc2(1)
     !    write(*,*)'nmonsum',nMonSum
         call mpi_allreduce(monLoc2, monGlob2, nMonSum2, sumb_real, &
              mpi_sum, SUmb_comm_world, ierr)
     !    print *,'reduction complete'
         ! Transfer the cost function values to output arguments.
     !     print *,'assigning results'
         CLAdj(sps)  = monGlob2(1)
         CDAdj(sps)  = monGlob2(2)
         CfxAdj(sps) = monGlob2(3)
         CfyAdj(sps) = monGlob2(4)
         CfzAdj(sps) = monGlob2(5) 
         CMxAdj(sps) = monGlob2(6)
         CMyAdj(sps) = monGlob2(7)
         CMzAdj(sps) = monGlob2(8)

      end do spectralLoopAdj

      call mpi_barrier(SUmb_comm_world, ierr)


      cl0Adj =0.0
      cmz0Adj =0.0
      dcldalphaAdj =0.0
      dcmzdalphaAdj =0.0
      !Now compute the stability derivatives

      call computeTSStabilityDerivAdj(cFxAdj,cFyAdj,cFzAdj,cMxAdj,&
                       cMyAdj,cMzAdj,CLAdj,CDAdj,&
                       cl0Adj,cmz0Adj,dcldalphaAdj,dcmzdalphaAdj)


      ! Root processor outputs results.
 !     print *,'printing results'
      if(myID == 0) then
         write(*,*) 'Stability Derivative verification results'
         write(*,*) 'Cl0   cmz0   dcldalpha   dcmzdalpha'
         write(*,20) "Original", cl0,cmz0,dcldalpha,dcmzdalpha
         write(*,20) "Adjoint ", cl0Adj,cmz0Adj,dcldalphaAdj,dcmzdalphaAdj
      endif
             
      !print *,'finished computing derivatives'
      ! Flush the output buffer and synchronize the processors.
       
      call f77flush()

       
      ! Output format.
       
10    format(1x,4a14)
20    format(1x,a,8(1x,e13.6))

    end subroutine verifyTSStabilityDerivAdj
     
