   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade - Version 2.2 (r1239) - Wed 28 Jun 2006 04:59:55 PM CEST
   !  
   !  Differentiation of residualadj in reverse (adjoint) mode:
   !   gradient, with respect to input variables: rotrateadj voladj
   !                padj radkadj radjadj dwadj wadj radiadj sfacekadj
   !                skadj sfacejadj sjadj sfaceiadj siadj vis2 vis4
   !                kappacoef cdisrk
   !   of linear combination of output variables: dwadj massflowfamilydiss
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          residual.f90                                    *
   !      * Author:        C.A.(Sandy) Mader                               *
   !      * Starting date: 04-21-2008                                      *
   !      * Last modified: 04-28-2008                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE RESIDUALADJ_B(wadj, wadjb, padj, padjb, siadj, siadjb, sjadj&
   &  , sjadjb, skadj, skadjb, voladj, voladjb, normadj, sfaceiadj, &
   &  sfaceiadjb, sfacejadj, sfacejadjb, sfacekadj, sfacekadjb, radiadj, &
   &  radiadjb, radjadj, radjadjb, radkadj, radkadjb, dwadj, dwadjb, icell&
   &  , jcell, kcell, rotrateadj, rotrateadjb, correctfork, nn, level, sps)
   USE blockpointers
   USE cgnsgrid
   USE flowvarrefstate
   USE inputdiscretization
   USE inputiteration
   USE inputtimespectral
   USE iteration
   IMPLICIT NONE
   !* real(iblank(iCell,jCell,kCell), realType)
   LOGICAL, INTENT(IN) :: correctfork
   REAL(KIND=REALTYPE) :: dwadj(nw, ntimeintervalsspectral), dwadjb(nw, &
   &  ntimeintervalsspectral)
   INTEGER(KIND=INTTYPE) :: icell, jcell, kcell, level, nn, sps
   REAL(KIND=REALTYPE) :: normadj(nbocos, -2:2, -2:2, 3, &
   &  ntimeintervalsspectral)
   REAL(KIND=REALTYPE), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: padj
   REAL(KIND=REALTYPE) :: padjb(-2:2, -2:2, -2:2, ntimeintervalsspectral)
   REAL(KIND=REALTYPE) :: radiadj(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral), radiadjb(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral), radjadj(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral), radjadjb(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral), radkadj(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral), radkadjb(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral)
   REAL(KIND=REALTYPE), DIMENSION(3), INTENT(IN) :: rotrateadj
   REAL(KIND=REALTYPE) :: rotrateadjb(3)
   REAL(KIND=REALTYPE), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: sfaceiadj
   REAL(KIND=REALTYPE), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: sfacejadj
   REAL(KIND=REALTYPE), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: sfacekadj
   REAL(KIND=REALTYPE) :: sfaceiadjb(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), sfacejadjb(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), sfacekadjb(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral)
   REAL(KIND=REALTYPE) :: siadj(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral), siadjb(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral), sjadj(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral), sjadjb(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral), skadj(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral), skadjb(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral)
   REAL(KIND=REALTYPE) :: voladj(0:0, 0:0, 0:0, ntimeintervalsspectral), &
   &  voladjb(0:0, 0:0, 0:0, ntimeintervalsspectral)
   REAL(KIND=REALTYPE) :: wadj(-2:2, -2:2, -2:2, nw, &
   &  ntimeintervalsspectral), wadjb(-2:2, -2:2, -2:2, nw, &
   &  ntimeintervalsspectral)
   INTEGER :: branch
   INTEGER(KIND=INTTYPE) :: discr
   REAL(KIND=REALTYPE) :: dwadj2(nw, ntimeintervalsspectral)
   LOGICAL :: finegrid
   REAL(KIND=REALTYPE) :: fwadj(nw, ntimeintervalsspectral)
   INTEGER(KIND=INTTYPE) :: i, j, k, l
   !
   !      ******************************************************************
   !      *                                                                *
   !      * residual computes the residual of the mean flow equations on   *
   !      * the current MG level.                                          *
   !      *                                                                *
   !      ******************************************************************
   !
   !       Subroutine Variables
   !integer(kind=intType), intent(in) :: discr
   !
   !      Local variables.
   !
   !sps, nn, discr
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   !   Come back to this later....
   !!$       ! Add the source terms from the level 0 cooling model.
   !!$
   !!$       call level0CoolingModel
   ! Set the value of rFil, which controls the fraction of the old
   ! dissipation residual to be used. This is only for the runge-kutta
   ! schemes; for other smoothers rFil is simply set to 1.0.
   ! Note the index rkStage+1 for cdisRK. The reason is that the
   ! residual computation is performed before rkStage is incremented.
   IF (smoother .EQ. rungekutta) THEN
   rfil = cdisrk(rkstage+1)
   CALL PUSHINTEGER4(0)
   ELSE
   rfil = one
   CALL PUSHINTEGER4(1)
   END IF
   ! Initialize the local arrays to monitor the massflows to zero.
   ! Set the value of the discretization, depending on the grid level,
   ! and the logical fineGrid, which indicates whether or not this
   ! is the finest grid level of the current mg cycle.
   discr = spacediscrcoarse
   IF (currentlevel .EQ. 1) THEN
   discr = spacediscr
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   finegrid = .false.
   IF (currentlevel .EQ. groundlevel) THEN
   finegrid = .true.
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   !moved outside...
   !!$
   !!$       ! Loop over the number of spectral solutions and local
   !!$       ! number of blocks.
   !!$
   !!$       spectralLoop: do sps=1,nTimeIntervalsSpectral
   !!$         domainLoop: do nn=1,nDom
   !!$
   !!$           ! Set the pointers to this block and compute the central
   !!$           ! inviscid flux.
   !!$
   !!$           call setPointers(nn, currentLevel, sps)
   !********************
   !print *,'before central',wAdj(:,:,:,irho)!
   CALL INVISCIDCENTRALFLUXADJ(wadj, padj, dwadj, siadj, sjadj, skadj, &
   &                        voladj, sfaceiadj, sfacejadj, sfacekadj, &
   &                        rotrateadj, icell, jcell, kcell, nn, level, sps&
   &                       )
   !print *,'After inviscid upwind',dwAdj
   !               call inviscidUpwindFluxAdj2(wAdj,  pAdj,  dwAdj2, &
   !                                        iCell, jCell, kCell,finegrid)
   !!$ !              call inviscidUpwindFluxAdj2(w(icell-2:icell+2,jcell-2:jcell+2,kcell-2:kcell+2,:), p(icell-2:icell+2,jcell-2:jc
   !ell+2,kcell-2:kcell+2),  dwAdj2, &
   !!$ !                                       iCell, jCell, kCell,finegrid)
   !!$ !              
   !!$ !              fw(:,:,:,:) = 0.0
   !!$!
   !!$ !              call inviscidUpwindFlux(fineGrid)
   !!$ !              do l=1,nwf
   !!$ !                 do k=2,kl
   !!$ !                    do j=2,jl
   !!$ !                       do i=2,il
   !!$ !                          dw(i,j,k,l) = (dw(i,j,k,l) + fw(i,j,k,l)) &
   !!$ !                               * real(iblank(i,j,k), realType)
   !!$ !                       enddo
   !!$ !                    enddo
   !!$  !                enddo
   !!$  !             enddo
   !!$  !             do i = 1,nw
   !!$  !                !if (abs(dwAdj(i)-dwAdj2(i))>0.0) then
   !!$  !                if (abs(dwAdj(i)-fw(icell,jcell,kcell,i))>0.0) then
   !!$  !                !if (1.0>0.0) then
   !!$  !                   print *,abs(dwAdj(i)-fw(icell,jcell,kcell,i)),'dwadjup',dwAdj(i),'up2',dwAdj2(i),i,icell,jcell,kcell,fw(
   !icell,jcell,kcell,i)
   !!$  !                endif
   !!$  !             enddo
   !print *,'after inviscid central',dwadj
   ! Compute the artificial dissipation fluxes.
   ! This depends on the parameter discr.
   SELECT CASE  (discr) 
   CASE (dissscalar) 
   ! Standard scalar dissipation scheme.
   IF (finegrid) THEN
   CALL PUSHREAL8ARRAY(wadj, 5**3*nw*ntimeintervalsspectral)
   !print *,'calling dissipation!'
   !stop
   !fw(:,:,:,:) = 0.0
   !call inviscidDissFluxScalar()
   CALL INVISCIDDISSFLUXSCALARADJ(wadj, padj, dwadj, radiadj, radjadj&
   &                               , radkadj, icell, jcell, kcell, nn, &
   &                               level, sps)
   !!$!               do i = 1,nw
   !!$!                  !if (abs(dwAdj(i)-dwAdj2(i))>0.0) then
   !!$!                  !if (abs(dwAdj(i)-fw(icell,jcell,kcell,i))>1e-16) then
   !!$!                  !if (1.0>0.0) then
   !!$!                     print *,abs(dwAdj(i)-fw(icell,jcell,kcell,i)),'dwadjscalar',dwAdj(i),'scalar2',i,icell,jcell,kcell,fw(ic
   !ell,jcell,kcell,i)
   !!$!                  !endif
   !!$!               enddo
   !stop
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(2)
   END IF
   CASE (upwind) 
   !===========================================================
   !!$!             case (dissMatrix) ! Matrix dissipation scheme.
   !!$!
   !!$!               if( fineGrid ) then
   !!$!                 call inviscidDissFluxMatrixAdj()
   !!$!               else
   !!$!                 call terminate("residualAdj", &
   !!$!                        "ADjoint does not function on coarse grid level")
   !!$!                 !call inviscidDissFluxMatrixCoarse
   !!$!               endif
   !===========================================================
   !!$ !            case (dissCusp) ! Cusp dissipation scheme.
   !!$!
   !!$!               if( fineGrid ) then
   !!$!                 call inviscidDissFluxCuspAdj()
   !!$!               else
   !!$!                 call terminate("residualAdj", &
   !!$!                        "ADjoint does not function on coarse grid level")
   !!$!                 !call inviscidDissFluxCuspCoarse
   !!$!               endif
   !===========================================================
   ! Dissipation via an upwind scheme.
   !print *,'before upwind',wAdj(:,:,:,irho)!,  pAdj,  dwAdj, &
   ! siAdj, sjAdj, skAdj, &
   ! sFaceIAdj,sFaceJAdj,sFaceKAdj,&
   ! iCell, jCell, kCell,finegrid
   CALL INVISCIDUPWINDFLUXADJ(wadj, padj, dwadj, siadj, sjadj, skadj, &
   &                         sfaceiadj, sfacejadj, sfacekadj, icell, jcell&
   &                         , kcell, finegrid, nn, level, sps)
   CALL PUSHINTEGER4(3)
   CASE DEFAULT
   CALL PUSHINTEGER4(0)
   END SELECT
   l = 0
   CALL POPINTEGER4(branch)
   IF (branch .LT. 2) THEN
   IF (branch .LT. 1) THEN
   padjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   radkadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   radjadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   wadjb(-2:2, -2:2, -2:2, 1:nw, 1:ntimeintervalsspectral) = 0.0
   radiadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   sfacekadjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   skadjb(-3:2, -3:2, -3:2, 1:3, 1:ntimeintervalsspectral) = 0.0
   sfacejadjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   sjadjb(-3:2, -3:2, -3:2, 1:3, 1:ntimeintervalsspectral) = 0.0
   sfaceiadjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   siadjb(-3:2, -3:2, -3:2, 1:3, 1:ntimeintervalsspectral) = 0.0
   GOTO 100
   ELSE
   CALL POPREAL8ARRAY(wadj, 5**3*nw*ntimeintervalsspectral)
   CALL INVISCIDDISSFLUXSCALARADJ_B(wadj, wadjb, padj, padjb, dwadj, &
   &                                 dwadjb, radiadj, radiadjb, radjadj, &
   &                                 radjadjb, radkadj, radkadjb, icell, &
   &                                 jcell, kcell, nn, level, sps)
   END IF
   ELSE IF (branch .LT. 3) THEN
   padjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   radkadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   radjadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   wadjb(-2:2, -2:2, -2:2, 1:nw, 1:ntimeintervalsspectral) = 0.0
   radiadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   ELSE
   CALL INVISCIDUPWINDFLUXADJ_B(wadj, wadjb, padj, padjb, dwadj, dwadjb&
   &                           , siadj, siadjb, sjadj, sjadjb, skadj, &
   &                           skadjb, sfaceiadj, sfaceiadjb, sfacejadj, &
   &                           sfacejadjb, sfacekadj, sfacekadjb, icell, &
   &                           jcell, kcell, finegrid, nn, level, sps)
   radkadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   radjadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   radiadjb(-1:1, -1:1, -1:1, 1:ntimeintervalsspectral) = 0.0
   GOTO 100
   END IF
   sfacekadjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   skadjb(-3:2, -3:2, -3:2, 1:3, 1:ntimeintervalsspectral) = 0.0
   sfacejadjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   sjadjb(-3:2, -3:2, -3:2, 1:3, 1:ntimeintervalsspectral) = 0.0
   sfaceiadjb(-2:2, -2:2, -2:2, 1:ntimeintervalsspectral) = 0.0
   siadjb(-3:2, -3:2, -3:2, 1:3, 1:ntimeintervalsspectral) = 0.0
   100 CALL INVISCIDCENTRALFLUXADJ_B(wadj, wadjb, padj, padjb, dwadj, &
   &                             dwadjb, siadj, siadjb, sjadj, sjadjb, &
   &                             skadj, skadjb, voladj, voladjb, sfaceiadj&
   &                             , sfaceiadjb, sfacejadj, sfacejadjb, &
   &                             sfacekadj, sfacekadjb, rotrateadj, &
   &                             rotrateadjb, icell, jcell, kcell, nn, &
   &                             level, sps)
   CALL POPINTEGER4(branch)
   CALL POPINTEGER4(branch)
   CALL POPINTEGER4(branch)
  
   END SUBROUTINE RESIDUALADJ_B
