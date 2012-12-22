!
!      ******************************************************************
!      *                                                                *
!      * File:          viscSurface.f90                                 *
!      * Author:        Edwin van der Weide                             *
!      * Starting date: 12-12-2003                                      *
!      * Last modified: 02-10-2006                                      *
!      *                                                                *
!      ******************************************************************
!
       module viscSurface
!
!      ******************************************************************
!      *                                                                *
!      * Local module to store the viscous surface mesh and some        *
!      * periodic info for the sections.                                *
!      *                                                                *
!      ******************************************************************
!
       use adtAPI, only : adtIntType, adtRealType
       use precision
       implicit none
       save

       ! nquadVisc:             Number of local quads on the viscous
       !                        bodies.
       ! nNodeVisc:             Number of local nodes on the viscous
       !                        bodies.
       ! nquadViscGlob:         Global number of viscous quads.
       ! connVisc(4,nquadVisc): Connectivity of the local viscous
       !                        quads.
       ! coorVisc(3,nNodeVisc): The coordinates of the local nodes.


       integer(kind=adtIntType) :: nquadVisc, nNodeVisc
       integer(kind=adtIntType) :: nquadViscGlob

       integer(kind=adtIntType), dimension(:,:), allocatable :: connVisc
       real(kind=adtRealType),   dimension(:,:), allocatable :: coorVisc

       ! rotMatrixSections(nSections,3,3): Rotation matrices needed
       !                                   for the alignment of the
       !                                   sections. The rotation
       !                                   matrix is a**n, where a is
       !                                   periodic transformation
       !                                   matrix; n is an integer.

       real(kind=realType), dimension(:,:,:), allocatable :: &
                                                    rotMatrixSections


       type faceList
          
          ! n_unique_face        : The number of unique faces this processor
          !                        requries
          ! unique_elem_id       : The list of unique faces this processor 
          !                        requires

          integer(kind=intType) :: n
          integer(kind=intType), dimension(:), allocatable :: id
          logical               :: wallAssociated
       end type faceList

       type(faceList), allocatable, dimension(:,:) :: unique_face_info

       end module viscSurface
