!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade - Version 2.2 (r1239) - Wed 28 Jun 2006 04:59:55 PM CEST
!  
!  Differentiation of gridvelocitiesfineleveladj in reverse (adjoint) mode:
!   gradient, with respect to input variables: rotrateadj xadj
!                machgridadj skadj sjadj veldirfreestreamadj siadj
!                coscoeffouryrot coscoeffourxrot coefpolzrot omegafourzrot
!                coefpolyrot omegafouryrot coefpolxrot omegafourxrot
!                sincoeffourzrot sincoeffouryrot sincoeffourxrot
!                coscoeffourzrot
!   of linear combination of output variables: rotrateadj sfacekadj
!                skadj sfacejadj sjadj sfaceiadj sadj siadj
!
!      ******************************************************************
!      *                                                                *
!      * File:          gridVelocities.f90                              *
!      * Author:        Edwin van der Weide,C.A.(Sandy) Mader           *
!      * Starting date: 02-23-2004                                      *
!      * Last modified: 10-22-2008                                      *
!      *                                                                *
!      ******************************************************************
!
SUBROUTINE GRIDVELOCITIESFINELEVELADJ_B(useoldcoor, t, sps, xadj, xadjb&
&  , siadj, siadjb, sjadj, sjadjb, skadj, skadjb, rotcenteradj, &
&  rotrateadj, rotrateadjb, sadj, sadjb, sfaceiadj, sfaceiadjb, &
&  sfacejadj, sfacejadjb, sfacekadj, sfacekadjb, machgridadj, &
&  machgridadjb, veldirfreestreamadj, veldirfreestreamadjb, icell, jcell&
&  , kcell)
  USE blockpointers
  USE cgnsgrid
  USE flowvarrefstate
  USE inputmotion
  USE inputunsteady
  USE iteration
  IMPLICIT NONE
!      enddo domains
  INTEGER(KIND=INTTYPE), INTENT(IN) :: icell
  INTEGER(KIND=INTTYPE), INTENT(IN) :: jcell
  INTEGER(KIND=INTTYPE), INTENT(IN) :: kcell
  REAL(KIND=REALTYPE), INTENT(IN) :: machgridadj
  REAL(KIND=REALTYPE) :: machgridadjb
  REAL(KIND=REALTYPE), DIMENSION(3), INTENT(IN) :: rotcenteradj
  REAL(KIND=REALTYPE), DIMENSION(3), INTENT(IN) :: rotrateadj
  REAL(KIND=REALTYPE) :: rotrateadjb(3)
  REAL(KIND=REALTYPE) :: sadj(-2:2, -2:2, -2:2, 3), sadjb(-2:2, -2:2, -2&
&  :2, 3)
  REAL(KIND=REALTYPE) :: sfaceiadj(-2:2, -2:2, -2:2), sfaceiadjb(-2:2, -&
&  2:2, -2:2), sfacejadj(-2:2, -2:2, -2:2), sfacejadjb(-2:2, -2:2, -2:2)&
&  , sfacekadj(-2:2, -2:2, -2:2), sfacekadjb(-2:2, -2:2, -2:2)
  REAL(KIND=REALTYPE), DIMENSION(-3:2, -3:2, -3:2, 3), INTENT(IN) :: &
&  siadj
  REAL(KIND=REALTYPE) :: siadjb(-3:2, -3:2, -3:2, 3), sjadjb(-3:2, -3:2&
&  , -3:2, 3), skadjb(-3:2, -3:2, -3:2, 3)
  REAL(KIND=REALTYPE), DIMENSION(-3:2, -3:2, -3:2, 3), INTENT(IN) :: &
&  sjadj
  REAL(KIND=REALTYPE), DIMENSION(-3:2, -3:2, -3:2, 3), INTENT(IN) :: &
&  skadj
  INTEGER(KIND=INTTYPE), INTENT(IN) :: sps
  REAL(KIND=REALTYPE), DIMENSION(*), INTENT(IN) :: t
  LOGICAL, INTENT(IN) :: useoldcoor
  REAL(KIND=REALTYPE), DIMENSION(3), INTENT(IN) :: veldirfreestreamadj
  REAL(KIND=REALTYPE) :: veldirfreestreamadjb(3)
  REAL(KIND=REALTYPE), DIMENSION(-3:2, -3:2, -3:2, 3), INTENT(IN) :: &
&  xadj
  REAL(KIND=REALTYPE) :: xadjb(-3:2, -3:2, -3:2, 3)
  INTEGER :: ad_from, ad_from0, ad_from1, ad_from2, ad_from3, ad_from4, &
&  ad_to, ad_to0, ad_to1, ad_to2, ad_to3, ad_to4, branch
  INTEGER(KIND=INTTYPE) :: i, ii, iie, j, jje, k, kke
  INTEGER(KIND=INTTYPE) :: iend, istart, jend, jstart, kend, kstart
  INTEGER(KIND=INTTYPE) :: mm, nn
  REAL(KIND=REALTYPE) :: oneover4dt, oneover8dt
  REAL(KIND=REALTYPE) :: rotationmatrixadj(3, 3)
  REAL(KIND=REALTYPE) :: rotationpointadj(3), rotpointadj(3)
  REAL(KIND=REALTYPE) :: sfaceadj(-2:2, -2:2), sfaceadjb(-2:2, -2:2)
  REAL(KIND=REALTYPE), DIMENSION(:, :, :), POINTER :: ss, xx
  REAL(KIND=REALTYPE) :: ssadj(-3:2, -3:2, 3), ssadjb(-3:2, -3:2, 3), &
&  xxadj(-3:2, -3:2, 3), xxadjb(-3:2, -3:2, 3)
  REAL(KIND=REALTYPE) :: ainf, velxgrid, velxgridb, velygrid, velygridb&
&  , velzgrid, velzgridb
  REAL(KIND=REALTYPE) :: velxgrid0, velxgrid0b, velygrid0, velygrid0b, &
&  velzgrid0, velzgrid0b
  REAL(KIND=REALTYPE) :: sc(3), scb(3), tempb, tempb0, tempb1, tempb2, &
&  tempb3, tempb4, xc(3), xcb(3), xxc(3), xxcb(3)
  REAL(KIND=REALTYPE), DIMENSION(:, :, :, :), POINTER :: xxold
  INTRINSIC SQRT
  EXTERNAL TERMINATE
!
!      ******************************************************************
!      *                                                                *
!      * gridVelocitiesFineLevel computes the grid velocities for       *
!      * the cell centers and the normal grid velocities for the faces  *
!      * of moving blocks for the currently finest grid, i.e.           *
!      * groundLevel. The velocities are computed at time t for         *
!      * spectral mode sps. If useOldCoor is .true. the velocities      *
!      * are determined using the unsteady time integrator in           *
!      * combination with the old coordinates; otherwise the analytic   *
!      * form is used.                                                  *
!      *                                                                *
!      ******************************************************************
!
!
!      Subroutine arguments.
!
!real(kind=realType), dimension(:,:), intent(out) :: sFace
!new ADjoint variables
!real(kind=realType) :: volAdj
!real(kind=realType), dimension(nBocos,-2:2,-2:2,3), intent(out) :: normAdj
!
!      Local variables.
!
!real(kind=realType), dimension(:,:), pointer :: sFace
!
!      ******************************************************************
!      *                                                                *
!      * Begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! Compute the mesh velocity from the given mesh Mach number.
!  aInf = sqrt(gammaInf*pInf/rhoInf)
!  velxGrid = aInf*MachGrid(1)
!  velyGrid = aInf*MachGrid(2)
!  velzGrid = aInf*MachGrid(3)
!velxGrid = zero
!velyGrid = zero
!velzGrid = zero
  ainf = SQRT(gammainf*pinf/rhoinf)
  velxgrid0 = ainf*machgridadj*(-veldirfreestreamadj(1))
  velygrid0 = ainf*machgridadj*(-veldirfreestreamadj(2))
  velzgrid0 = ainf*machgridadj*(-veldirfreestreamadj(3))
! Compute the derivative of the rotation matrix and the rotation
! point; needed for velocity due to the rigid body rotation of
! the entire grid. It is assumed that the rigid body motion of
! the grid is only specified if there is only 1 section present.
  CALL DERIVATIVEROTMATRIXRIGIDADJ(rotationmatrixadj, rotationpointadj, &
&                             rotpointadj, t(1))
!!$!       ! Loop over the number of local blocks.
!!$!
!!$!       domains: do nn=1,nDom!
!!$!
!!$!         ! Set the pointers for this block.!
!!$
!!$!         call setPointersAdj(nn, groundLevel, sps)!
!!$!
! Check for a moving block.
  IF (blockismoving) THEN
! Determine the situation we are having here.
    IF (useoldcoor) THEN
      xadjb(-3:2, -3:2, -3:2, 1:3) = 0.0
      velxgrid0b = 0.0
      velzgrid0b = 0.0
      velygrid0b = 0.0
    ELSE
!
!            ************************************************************
!            *                                                          *
!            * The velocities must be determined analytically.          *
!            *                                                          *
!            ************************************************************
!
!!! Pass these in, set them in copyADjointStencil.f90
!!$
!!$             ! Store the rotation center and determine the
!!$             ! nonDimensional rotation rate of this block. As the
!!$             ! reference length is 1 timeRef == 1/uRef and at the end
!!$             ! the nonDimensional velocity is computed.
!!$
!!$             j = nbkGlobal
!!$
!!$             rotCenter = cgnsDoms(j)%rotCenter
!!$             rotRate   = timeRef*cgnsDoms(j)%rotRate
!subtract off the rotational velocity of the center of the grid
! to account for the added overall velocity.
      velxgrid = velxgrid0 + 1*(rotrateadj(2)*rotcenteradj(3)-rotrateadj&
&        (3)*rotcenteradj(2))
      velygrid = velygrid0 + 1*(rotrateadj(3)*rotcenteradj(1)-rotrateadj&
&        (1)*rotcenteradj(3))
      velzgrid = velzgrid0 + 1*(rotrateadj(1)*rotcenteradj(2)-rotrateadj&
&        (2)*rotcenteradj(1))
!
!            ************************************************************
!            *                                                          *
!            * Grid velocities of the cell centers, including the       *
!            * 1st level halo cells.                                    *
!            *                                                          *
!            ************************************************************
!
! Loop over the cells, including the 1st level halo's.
      kstart = -2
      kend = 2
      jstart = -2
      jend = 2
      istart = -2
      iend = 2
      ad_from = kstart
!-2,2
      DO k=ad_from,kend
        ad_from0 = jstart
!-2,2
        DO j=ad_from0,jend
          ad_from1 = istart
!-2,2
          DO i=ad_from1,iend
!!$             do k=1,ke
!!$               do j=1,je
!!$                 do i=1,ie
! Determine the coordinates of the cell center,
! which are stored in xc.
            xc(1) = eighth*(xadj(i-1, j-1, k-1, 1)+xadj(i, j-1, k-1, 1)+&
&              xadj(i-1, j, k-1, 1)+xadj(i, j, k-1, 1)+xadj(i-1, j-1, k&
&              , 1)+xadj(i, j-1, k, 1)+xadj(i-1, j, k, 1)+xadj(i, j, k, &
&              1))
            xc(2) = eighth*(xadj(i-1, j-1, k-1, 2)+xadj(i, j-1, k-1, 2)+&
&              xadj(i-1, j, k-1, 2)+xadj(i, j, k-1, 2)+xadj(i-1, j-1, k&
&              , 2)+xadj(i, j-1, k, 2)+xadj(i-1, j, k, 2)+xadj(i, j, k, &
&              2))
            xc(3) = eighth*(xadj(i-1, j-1, k-1, 3)+xadj(i, j-1, k-1, 3)+&
&              xadj(i-1, j, k-1, 3)+xadj(i, j, k-1, 3)+xadj(i-1, j-1, k&
&              , 3)+xadj(i, j-1, k, 3)+xadj(i-1, j, k, 3)+xadj(i, j, k, &
&              3))
            CALL PUSHREAL8(xxc(1))
! Determine the coordinates relative to the
! center of rotation.
            xxc(1) = xc(1) - rotcenteradj(1)
            CALL PUSHREAL8(xxc(2))
            xxc(2) = xc(2) - rotcenteradj(2)
            CALL PUSHREAL8(xxc(3))
            xxc(3) = xc(3) - rotcenteradj(3)
! Determine the rotation speed of the cell center,
! which is omega*r.
            sc(1) = rotrateadj(2)*xxc(3) - rotrateadj(3)*xxc(2)
            sc(2) = rotrateadj(3)*xxc(1) - rotrateadj(1)*xxc(3)
            sc(3) = rotrateadj(1)*xxc(2) - rotrateadj(2)*xxc(1)
            CALL PUSHREAL8(xxc(1))
! Determine the coordinates relative to the
! rigid body rotation point.
            xxc(1) = xc(1) - rotationpointadj(1)
            CALL PUSHREAL8(xxc(2))
            xxc(2) = xc(2) - rotationpointadj(2)
            CALL PUSHREAL8(xxc(3))
            xxc(3) = xc(3) - rotationpointadj(3)
! Determine the total velocity of the cell center.
! This is a combination of rotation speed of this
! block and the entire rigid body rotation.
          END DO
          CALL PUSHINTEGER4(i - 1)
          CALL PUSHINTEGER4(ad_from1)
        END DO
        CALL PUSHINTEGER4(j - 1)
        CALL PUSHINTEGER4(ad_from0)
      END DO
      CALL PUSHINTEGER4(k - 1)
      CALL PUSHINTEGER4(ad_from)
!
!            ************************************************************
!            *                                                          *
!            * Normal grid velocities of the faces.                     *
!            *                                                          *
!            ************************************************************
!
! Loop over the three directions.
loopdirection:DO mm=1,3
        kstart = -2
        kend = 2
        jstart = -2
        jend = 2
        istart = -2
        iend = 2
!if(iCell==2)  iStart=-1
!if(iCell==il) iEnd=1
!if(jCell==2)  jStart=-1
!if(jCell==jl) jEnd=1 
!if(kCell==kl) kEnd=1
!if(kCell==2)  kStart=-2
! Set the upper boundaries depending on the direction.
        ad_from2 = istart
!
!              **********************************************************
!              *                                                        *
!              * Normal grid velocities in generalized i-direction.     *
!              * mm == 1: i-direction                                   *
!              * mm == 2: j-direction                                   *
!              * mm == 3: k-direction                                   *
!              *                                                        *
!              **********************************************************
!
!do i=0,iie
        DO i=ad_from2,iend
! Set the pointers for the coordinates, normals and
! normal velocities for this generalized i-plane.
! This depends on the value of mm.
          SELECT CASE  (mm) 
          CASE (1_intType) 
! normals in i-direction
            xxadj = xadj(i, :, :, :)
            CALL PUSHREAL8ARRAY(ssadj, 6**2*3)
            ssadj = siadj(i, :, :, :)
            CALL PUSHINTEGER4(1)
          CASE (2_intType) 
! normals in j-direction
            xxadj = xadj(:, i, :, :)
            CALL PUSHREAL8ARRAY(ssadj, 6**2*3)
            ssadj = sjadj(:, i, :, :)
            CALL PUSHINTEGER4(2)
          CASE (3_intType) 
! normals in k-direction
            xxadj = xadj(:, :, i, :)
            CALL PUSHREAL8ARRAY(ssadj, 6**2*3)
            ssadj = skadj(:, :, i, :)
            CALL PUSHINTEGER4(3)
          CASE DEFAULT
            CALL PUSHINTEGER4(0)
          END SELECT
          ad_from3 = kstart
! Loop over the k and j-direction of this generalized
! i-face. Note that due to the usage of the pointer
! xx an offset of +1 must be used in the coordinate
! array, because x originally starts at 0 for the
! i, j and k indices.
!do k=1,kke
! do j=1,jje
          DO k=ad_from3,kend
            ad_from4 = jstart
            DO j=ad_from4,jend
! Determine the coordinates of the face center,
! which are stored in xc.
!xc(1) = fourth*(xxAdj(j+1,k+1,1) + xxAdj(j,k+1,1) &
!      +         xxAdj(j+1,k,  1) + xxAdj(j,k,  1))
!xc(2) = fourth*(xxAdj(j+1,k+1,2) + xxAdj(j,k+1,2) &
!      +         xxAdj(j+1,k,  2) + xxAdj(j,k,  2))
!xc(3) = fourth*(xxAdj(j+1,k+1,3) + xxAdj(j,k+1,3) &
!      +         xxAdj(j+1,k,  3) + xxAdj(j,k,  3))
              xc(1) = fourth*(xxadj(j, k, 1)+xxadj(j-1, k, 1)+xxadj(j, k&
&                -1, 1)+xxadj(j-1, k-1, 1))
              xc(2) = fourth*(xxadj(j, k, 2)+xxadj(j-1, k, 2)+xxadj(j, k&
&                -1, 2)+xxadj(j-1, k-1, 2))
              xc(3) = fourth*(xxadj(j, k, 3)+xxadj(j-1, k, 3)+xxadj(j, k&
&                -1, 3)+xxadj(j-1, k-1, 3))
              CALL PUSHREAL8(xxc(1))
! Determine the coordinates relative to the
! center of rotation.
              xxc(1) = xc(1) - rotcenteradj(1)
              CALL PUSHREAL8(xxc(2))
              xxc(2) = xc(2) - rotcenteradj(2)
              CALL PUSHREAL8(xxc(3))
              xxc(3) = xc(3) - rotcenteradj(3)
              CALL PUSHREAL8(sc(1))
! Determine the rotation speed of the face center,
! which is omega*r.
              sc(1) = rotrateadj(2)*xxc(3) - rotrateadj(3)*xxc(2)
              CALL PUSHREAL8(sc(2))
              sc(2) = rotrateadj(3)*xxc(1) - rotrateadj(1)*xxc(3)
              CALL PUSHREAL8(sc(3))
              sc(3) = rotrateadj(1)*xxc(2) - rotrateadj(2)*xxc(1)
              CALL PUSHREAL8(xxc(1))
! Determine the coordinates relative to the
! rigid body rotation point.
              xxc(1) = xc(1) - rotationpointadj(1)
              CALL PUSHREAL8(xxc(2))
              xxc(2) = xc(2) - rotationpointadj(2)
              CALL PUSHREAL8(xxc(3))
              xxc(3) = xc(3) - rotationpointadj(3)
              CALL PUSHREAL8(sc(1))
! Determine the total velocity of the cell face.
! This is a combination of rotation speed of this
! block and the entire rigid body rotation.
              sc(1) = sc(1) + velxgrid + rotationmatrixadj(1, 1)*xxc(1) &
&                + rotationmatrixadj(1, 2)*xxc(2) + rotationmatrixadj(1&
&                , 3)*xxc(3)
              CALL PUSHREAL8(sc(2))
              sc(2) = sc(2) + velygrid + rotationmatrixadj(2, 1)*xxc(1) &
&                + rotationmatrixadj(2, 2)*xxc(2) + rotationmatrixadj(2&
&                , 3)*xxc(3)
              CALL PUSHREAL8(sc(3))
              sc(3) = sc(3) + velzgrid + rotationmatrixadj(3, 1)*xxc(1) &
&                + rotationmatrixadj(3, 2)*xxc(2) + rotationmatrixadj(3&
&                , 3)*xxc(3)
! Store the dot product of grid velocity sc and
! the normal ss in sFace.
            END DO
            CALL PUSHINTEGER4(j - 1)
            CALL PUSHINTEGER4(ad_from4)
          END DO
          CALL PUSHINTEGER4(k - 1)
          CALL PUSHINTEGER4(ad_from3)
          SELECT CASE  (mm) 
          CASE (1_intType) 
            CALL PUSHINTEGER4(2)
          CASE (2_intType) 
            CALL PUSHINTEGER4(3)
          CASE (3_intType) 
            CALL PUSHINTEGER4(4)
          CASE DEFAULT
            CALL PUSHINTEGER4(1)
          END SELECT
        END DO
        CALL PUSHINTEGER4(i - 1)
        CALL PUSHINTEGER4(ad_from2)
      END DO loopdirection
      xadjb(-3:2, -3:2, -3:2, 1:3) = 0.0
      ssadjb(-3:2, -3:2, 1:3) = 0.0
      velygridb = 0.0
      xcb(1:3) = 0.0
      xxcb(1:3) = 0.0
      velzgridb = 0.0
      xxadjb(-3:2, -3:2, 1:3) = 0.0
      scb(1:3) = 0.0
      velxgridb = 0.0
      sfaceadjb(-2:2, -2:2) = 0.0
      DO mm=3,1,-1
        CALL POPINTEGER4(ad_from2)
        CALL POPINTEGER4(ad_to2)
        DO i=ad_to2,ad_from2,-1
          CALL POPINTEGER4(branch)
          IF (branch .LT. 3) THEN
            IF (.NOT.branch .LT. 2) THEN
              sfaceadjb = sfaceadjb + sfaceiadjb(i, :, :)
              sfaceiadjb(i, :, :) = 0.0
            END IF
          ELSE IF (branch .LT. 4) THEN
            sfaceadjb = sfaceadjb + sfacejadjb(:, i, :)
            sfacejadjb(:, i, :) = 0.0
          ELSE
            sfaceadjb = sfaceadjb + sfacekadjb(:, :, i)
            sfacekadjb(:, :, i) = 0.0
          END IF
          CALL POPINTEGER4(ad_from3)
          CALL POPINTEGER4(ad_to3)
          DO k=ad_to3,ad_from3,-1
            CALL POPINTEGER4(ad_from4)
            CALL POPINTEGER4(ad_to4)
            DO j=ad_to4,ad_from4,-1
              scb(1) = scb(1) + ssadj(j, k, 1)*sfaceadjb(j, k)
              ssadjb(j, k, 1) = ssadjb(j, k, 1) + sc(1)*sfaceadjb(j, k)
              scb(2) = scb(2) + ssadj(j, k, 2)*sfaceadjb(j, k)
              ssadjb(j, k, 2) = ssadjb(j, k, 2) + sc(2)*sfaceadjb(j, k)
              scb(3) = scb(3) + ssadj(j, k, 3)*sfaceadjb(j, k)
              ssadjb(j, k, 3) = ssadjb(j, k, 3) + sc(3)*sfaceadjb(j, k)
              sfaceadjb(j, k) = 0.0
              CALL POPREAL8(sc(3))
              velzgridb = velzgridb + scb(3)
              xxcb(1) = xxcb(1) + rotationmatrixadj(3, 1)*scb(3)
              xxcb(2) = xxcb(2) + rotationmatrixadj(3, 2)*scb(3)
              xxcb(3) = xxcb(3) + rotationmatrixadj(3, 3)*scb(3)
              CALL POPREAL8(sc(2))
              velygridb = velygridb + scb(2)
              xxcb(1) = xxcb(1) + rotationmatrixadj(2, 1)*scb(2)
              xxcb(2) = xxcb(2) + rotationmatrixadj(2, 2)*scb(2)
              xxcb(3) = xxcb(3) + rotationmatrixadj(2, 3)*scb(2)
              CALL POPREAL8(sc(1))
              velxgridb = velxgridb + scb(1)
              xxcb(1) = xxcb(1) + rotationmatrixadj(1, 1)*scb(1)
              xxcb(2) = xxcb(2) + rotationmatrixadj(1, 2)*scb(1)
              xxcb(3) = xxcb(3) + rotationmatrixadj(1, 3)*scb(1)
              CALL POPREAL8(xxc(3))
              xcb(3) = xcb(3) + xxcb(3)
              xxcb(3) = 0.0
              CALL POPREAL8(xxc(2))
              xcb(2) = xcb(2) + xxcb(2)
              xxcb(2) = 0.0
              CALL POPREAL8(xxc(1))
              xcb(1) = xcb(1) + xxcb(1)
              xxcb(1) = 0.0
              CALL POPREAL8(sc(3))
              rotrateadjb(1) = rotrateadjb(1) + xxc(2)*scb(3)
              xxcb(2) = xxcb(2) + rotrateadj(1)*scb(3)
              rotrateadjb(2) = rotrateadjb(2) - xxc(1)*scb(3)
              xxcb(1) = xxcb(1) - rotrateadj(2)*scb(3)
              scb(3) = 0.0
              CALL POPREAL8(sc(2))
              rotrateadjb(3) = rotrateadjb(3) + xxc(1)*scb(2)
              xxcb(1) = xxcb(1) + rotrateadj(3)*scb(2)
              rotrateadjb(1) = rotrateadjb(1) - xxc(3)*scb(2)
              xxcb(3) = xxcb(3) - rotrateadj(1)*scb(2)
              scb(2) = 0.0
              CALL POPREAL8(sc(1))
              rotrateadjb(2) = rotrateadjb(2) + xxc(3)*scb(1)
              xxcb(3) = xxcb(3) + rotrateadj(2)*scb(1)
              rotrateadjb(3) = rotrateadjb(3) - xxc(2)*scb(1)
              xxcb(2) = xxcb(2) - rotrateadj(3)*scb(1)
              scb(1) = 0.0
              CALL POPREAL8(xxc(3))
              xcb(3) = xcb(3) + xxcb(3)
              xxcb(3) = 0.0
              CALL POPREAL8(xxc(2))
              xcb(2) = xcb(2) + xxcb(2)
              xxcb(2) = 0.0
              CALL POPREAL8(xxc(1))
              xcb(1) = xcb(1) + xxcb(1)
              xxcb(1) = 0.0
              tempb2 = fourth*xcb(3)
              xxadjb(j, k, 3) = xxadjb(j, k, 3) + tempb2
              xxadjb(j-1, k, 3) = xxadjb(j-1, k, 3) + tempb2
              xxadjb(j, k-1, 3) = xxadjb(j, k-1, 3) + tempb2
              xxadjb(j-1, k-1, 3) = xxadjb(j-1, k-1, 3) + tempb2
              xcb(3) = 0.0
              tempb3 = fourth*xcb(2)
              xxadjb(j, k, 2) = xxadjb(j, k, 2) + tempb3
              xxadjb(j-1, k, 2) = xxadjb(j-1, k, 2) + tempb3
              xxadjb(j, k-1, 2) = xxadjb(j, k-1, 2) + tempb3
              xxadjb(j-1, k-1, 2) = xxadjb(j-1, k-1, 2) + tempb3
              xcb(2) = 0.0
              tempb4 = fourth*xcb(1)
              xxadjb(j, k, 1) = xxadjb(j, k, 1) + tempb4
              xxadjb(j-1, k, 1) = xxadjb(j-1, k, 1) + tempb4
              xxadjb(j, k-1, 1) = xxadjb(j, k-1, 1) + tempb4
              xxadjb(j-1, k-1, 1) = xxadjb(j-1, k-1, 1) + tempb4
              xcb(1) = 0.0
            END DO
          END DO
          CALL POPINTEGER4(branch)
          IF (branch .LT. 2) THEN
            IF (.NOT.branch .LT. 1) THEN
              CALL POPREAL8ARRAY(ssadj, 6**2*3)
              siadjb(i, :, :, :) = siadjb(i, :, :, :) + ssadjb
              xadjb(i, :, :, :) = xadjb(i, :, :, :) + xxadjb
              ssadjb(-3:2, -3:2, 1:3) = 0.0
              xxadjb(-3:2, -3:2, 1:3) = 0.0
            END IF
          ELSE IF (branch .LT. 3) THEN
            CALL POPREAL8ARRAY(ssadj, 6**2*3)
            sjadjb(:, i, :, :) = sjadjb(:, i, :, :) + ssadjb
            xadjb(:, i, :, :) = xadjb(:, i, :, :) + xxadjb
            ssadjb(-3:2, -3:2, 1:3) = 0.0
            xxadjb(-3:2, -3:2, 1:3) = 0.0
          ELSE
            CALL POPREAL8ARRAY(ssadj, 6**2*3)
            skadjb(:, :, i, :) = skadjb(:, :, i, :) + ssadjb
            xadjb(:, :, i, :) = xadjb(:, :, i, :) + xxadjb
            ssadjb(-3:2, -3:2, 1:3) = 0.0
            xxadjb(-3:2, -3:2, 1:3) = 0.0
          END IF
        END DO
      END DO
      CALL POPINTEGER4(ad_from)
      CALL POPINTEGER4(ad_to)
      DO k=ad_to,ad_from,-1
        CALL POPINTEGER4(ad_from0)
        CALL POPINTEGER4(ad_to0)
        DO j=ad_to0,ad_from0,-1
          CALL POPINTEGER4(ad_from1)
          CALL POPINTEGER4(ad_to1)
          DO i=ad_to1,ad_from1,-1
            scb(3) = scb(3) + sadjb(i, j, k, 3)
            velzgridb = velzgridb + sadjb(i, j, k, 3)
            xxcb(1) = xxcb(1) + rotationmatrixadj(3, 1)*sadjb(i, j, k, 3&
&              )
            xxcb(2) = xxcb(2) + rotationmatrixadj(3, 2)*sadjb(i, j, k, 3&
&              )
            xxcb(3) = xxcb(3) + rotationmatrixadj(3, 3)*sadjb(i, j, k, 3&
&              )
            sadjb(i, j, k, 3) = 0.0
            scb(2) = scb(2) + sadjb(i, j, k, 2)
            velygridb = velygridb + sadjb(i, j, k, 2)
            xxcb(1) = xxcb(1) + rotationmatrixadj(2, 1)*sadjb(i, j, k, 2&
&              )
            xxcb(2) = xxcb(2) + rotationmatrixadj(2, 2)*sadjb(i, j, k, 2&
&              )
            xxcb(3) = xxcb(3) + rotationmatrixadj(2, 3)*sadjb(i, j, k, 2&
&              )
            sadjb(i, j, k, 2) = 0.0
            scb(1) = scb(1) + sadjb(i, j, k, 1)
            velxgridb = velxgridb + sadjb(i, j, k, 1)
            xxcb(1) = xxcb(1) + rotationmatrixadj(1, 1)*sadjb(i, j, k, 1&
&              )
            xxcb(2) = xxcb(2) + rotationmatrixadj(1, 2)*sadjb(i, j, k, 1&
&              )
            xxcb(3) = xxcb(3) + rotationmatrixadj(1, 3)*sadjb(i, j, k, 1&
&              )
            sadjb(i, j, k, 1) = 0.0
            CALL POPREAL8(xxc(3))
            xcb(3) = xcb(3) + xxcb(3)
            xxcb(3) = 0.0
            CALL POPREAL8(xxc(2))
            xcb(2) = xcb(2) + xxcb(2)
            xxcb(2) = 0.0
            CALL POPREAL8(xxc(1))
            xcb(1) = xcb(1) + xxcb(1)
            xxcb(1) = 0.0
            rotrateadjb(1) = rotrateadjb(1) + xxc(2)*scb(3)
            xxcb(2) = xxcb(2) + rotrateadj(1)*scb(3)
            rotrateadjb(2) = rotrateadjb(2) - xxc(1)*scb(3)
            xxcb(1) = xxcb(1) - rotrateadj(2)*scb(3)
            scb(3) = 0.0
            rotrateadjb(3) = rotrateadjb(3) + xxc(1)*scb(2)
            xxcb(1) = xxcb(1) + rotrateadj(3)*scb(2)
            rotrateadjb(1) = rotrateadjb(1) - xxc(3)*scb(2)
            xxcb(3) = xxcb(3) - rotrateadj(1)*scb(2)
            scb(2) = 0.0
            rotrateadjb(2) = rotrateadjb(2) + xxc(3)*scb(1)
            xxcb(3) = xxcb(3) + rotrateadj(2)*scb(1)
            rotrateadjb(3) = rotrateadjb(3) - xxc(2)*scb(1)
            xxcb(2) = xxcb(2) - rotrateadj(3)*scb(1)
            scb(1) = 0.0
            CALL POPREAL8(xxc(3))
            xcb(3) = xcb(3) + xxcb(3)
            xxcb(3) = 0.0
            CALL POPREAL8(xxc(2))
            xcb(2) = xcb(2) + xxcb(2)
            xxcb(2) = 0.0
            CALL POPREAL8(xxc(1))
            xcb(1) = xcb(1) + xxcb(1)
            xxcb(1) = 0.0
            tempb = eighth*xcb(3)
            xadjb(i-1, j-1, k-1, 3) = xadjb(i-1, j-1, k-1, 3) + tempb
            xadjb(i, j-1, k-1, 3) = xadjb(i, j-1, k-1, 3) + tempb
            xadjb(i-1, j, k-1, 3) = xadjb(i-1, j, k-1, 3) + tempb
            xadjb(i, j, k-1, 3) = xadjb(i, j, k-1, 3) + tempb
            xadjb(i-1, j-1, k, 3) = xadjb(i-1, j-1, k, 3) + tempb
            xadjb(i, j-1, k, 3) = xadjb(i, j-1, k, 3) + tempb
            xadjb(i-1, j, k, 3) = xadjb(i-1, j, k, 3) + tempb
            xadjb(i, j, k, 3) = xadjb(i, j, k, 3) + tempb
            xcb(3) = 0.0
            tempb0 = eighth*xcb(2)
            xadjb(i-1, j-1, k-1, 2) = xadjb(i-1, j-1, k-1, 2) + tempb0
            xadjb(i, j-1, k-1, 2) = xadjb(i, j-1, k-1, 2) + tempb0
            xadjb(i-1, j, k-1, 2) = xadjb(i-1, j, k-1, 2) + tempb0
            xadjb(i, j, k-1, 2) = xadjb(i, j, k-1, 2) + tempb0
            xadjb(i-1, j-1, k, 2) = xadjb(i-1, j-1, k, 2) + tempb0
            xadjb(i, j-1, k, 2) = xadjb(i, j-1, k, 2) + tempb0
            xadjb(i-1, j, k, 2) = xadjb(i-1, j, k, 2) + tempb0
            xadjb(i, j, k, 2) = xadjb(i, j, k, 2) + tempb0
            xcb(2) = 0.0
            tempb1 = eighth*xcb(1)
            xadjb(i-1, j-1, k-1, 1) = xadjb(i-1, j-1, k-1, 1) + tempb1
            xadjb(i, j-1, k-1, 1) = xadjb(i, j-1, k-1, 1) + tempb1
            xadjb(i-1, j, k-1, 1) = xadjb(i-1, j, k-1, 1) + tempb1
            xadjb(i, j, k-1, 1) = xadjb(i, j, k-1, 1) + tempb1
            xadjb(i-1, j-1, k, 1) = xadjb(i-1, j-1, k, 1) + tempb1
            xadjb(i, j-1, k, 1) = xadjb(i, j-1, k, 1) + tempb1
            xadjb(i-1, j, k, 1) = xadjb(i-1, j, k, 1) + tempb1
            xadjb(i, j, k, 1) = xadjb(i, j, k, 1) + tempb1
            xcb(1) = 0.0
          END DO
        END DO
      END DO
      velzgrid0b = velzgridb
      rotrateadjb(1) = rotrateadjb(1) + rotcenteradj(2)*velzgridb
      rotrateadjb(2) = rotrateadjb(2) - rotcenteradj(1)*velzgridb
      velygrid0b = velygridb
      rotrateadjb(3) = rotrateadjb(3) + rotcenteradj(1)*velygridb
      rotrateadjb(1) = rotrateadjb(1) - rotcenteradj(3)*velygridb
      velxgrid0b = velxgridb
      rotrateadjb(2) = rotrateadjb(2) + rotcenteradj(3)*velxgridb
      rotrateadjb(3) = rotrateadjb(3) - rotcenteradj(2)*velxgridb
    END IF
  ELSE
    xadjb(-3:2, -3:2, -3:2, 1:3) = 0.0
    velxgrid0b = 0.0
    velzgrid0b = 0.0
    velygrid0b = 0.0
  END IF
  veldirfreestreamadjb(1:3) = 0.0
  machgridadjb = -(ainf*veldirfreestreamadj(1)*velxgrid0b) - ainf*&
&    veldirfreestreamadj(2)*velygrid0b - ainf*veldirfreestreamadj(3)*&
&    velzgrid0b
  veldirfreestreamadjb(3) = -(ainf*machgridadj*velzgrid0b)
  veldirfreestreamadjb(2) = veldirfreestreamadjb(2) - ainf*machgridadj*&
&    velygrid0b
  veldirfreestreamadjb(1) = veldirfreestreamadjb(1) - ainf*machgridadj*&
&    velxgrid0b
!  coscoeffourzrotb(:) = 0.0
!  sincoeffourxrotb(:) = 0.0
!  sincoeffouryrotb(:) = 0.0
!  sincoeffourzrotb(:) = 0.0
!  omegafourxrotb = 0.0
!  coefpolxrotb(:) = 0.0
!  omegafouryrotb = 0.0
!  coefpolyrotb(:) = 0.0
!  omegafourzrotb = 0.0
!  coefpolzrotb(:) = 0.0
!  coscoeffourxrotb(:) = 0.0
!  coscoeffouryrotb(:) = 0.0
END SUBROUTINE GRIDVELOCITIESFINELEVELADJ_B
