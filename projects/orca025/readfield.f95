SUBROUTINE readfields

  USE netcdf
  USE mod_param
  USE mod_vel
  USE mod_coord
  USE mod_time
  USE mod_grid
  USE mod_name
  USE mod_vel
  USE mod_traj
  USE mod_getfile
  use mod_seed

#ifdef tempsalt
  USE mod_dens
  USE mod_stat
#endif
  IMPLICIT none
  

  ! = Loop variables
  INTEGER                                      :: i, j, k ,kk, im, ip, jm, jp, imm, ii, jmm, jpp, l
  INTEGER                                      :: kbot,ktop
  INTEGER, SAVE                                :: nread

  ! = Variables used for getfield procedures
  CHARACTER (len=200)                        :: gridFile ,fieldFile
  ! = Variables for filename generation
  CHARACTER (len=200)                        :: dataprefix

#ifdef orca1
  INTEGER, PARAMETER :: IMTG=???,JMTG=???
#elif orca025l75h6
  INTEGER, PARAMETER :: IMTG=1440,JMTG=1021,KMM=75
#endif

  REAL*4, ALLOCATABLE, DIMENSION(:,:)         	:: temp2d_simp
  REAL*4, ALLOCATABLE, DIMENSION(:,:,:)       	:: temp3d_simp

  REAL*4 										:: dd,dmult,uint,vint,zint
  
#ifdef tempsalt
 REAL*4, ALLOCATABLE, DIMENSION(:) :: tempb, saltb, rhob, depthb,latb
#endif

 LOGICAL around

!---------------------------------------------------------------

#ifdef initxyt
  alloCondGrid: if ( .not. allocated (ntimask) ) then
     allocate ( ntimask(NTID,IJKMAX2,3) , trajinit(NTID,IJKMAX2,3) )
  end if alloCondGrid
#endif

 alloCondUVW: if(.not. allocated (temp2d_simp)) then
   allocate ( temp3d_simp(IMT,JMT,KM), temp2d_simp(IMT,JMT)  )
#ifdef tempsalt
   allocate ( tempb(KM), saltb(KM), rhob(KM), depthb(KM), latb(KM))
#endif
 end if alloCondUVW

  ! === swap between datasets ===
  hs(:,:,1)=hs(:,:,2)
  uflux(:,:,:,1)=uflux(:,:,:,2)
  vflux(:,:,:,1)=vflux(:,:,:,2)
#ifdef tempsalt 
  tem(:,:,:,1)=tem(:,:,:,2)
  sal(:,:,:,1)=sal(:,:,:,2)
  rho(:,:,:,1)=rho(:,:,:,2)
#endif

! -------------------------------------------------------------

! === Initialising fields ===
  initFieldcond: if(ints.eq.intstart) then
     hs     = 0.
     uflux  = 0.
     vflux  = 0.
#ifdef tempsalt
     tem    = 0.
     sal    = 0.
     rho    = 0.
#endif

ihour=startHour
iday=startDay
imon=startMon
iyear=startYear
if(ngcm.le.24) then
ihour=24-ngcm
iday=startDay-5
imon=startMon
endif
     
else

! ----------------------------------------------------------------

! === Update clockworks ===
  iday=iday+nff*ngcm/24
  
  if(iday > idmax(imon,1999)) then ! why 1999 and not iyear?????
    iday=iday-idmax(imon,1999)
    imon=imon+1
    if(imon == 13) then
       imon=1
       iyear=iyear+1
     if(iyear.eq.yearmax+1) iyear=yearmin
    endif
  elseif(iday <=0) then
    imon=imon-1
    if(imon == 0) then
       imon=12
       iyear=iyear-1
     if(iyear.eq.yearmin-1) iyear=yearmax
    endif
    iday=iday+idmax(imon,1999)
   endif

endif initFieldcond

! === Time number ===
ntime=10000*iyear+100*imon+iday

! ------------------------------------------------------------

! === Find the file for this timestep ===

#ifdef orca1
 dataprefix='xxxx/ORCA1-N202_xxxxxxxx'
 write(dataprefix(17:24),'(i8)') ntime
 write(dataprefix(1:4),'(i4)') iyear
 fieldFile = trim(inDataDir)//trim(dataprefix)/'d05'
#elif orca025
 dataprefix='xxxx/ORCA025-N112_xxxxxxxx'
 write(dataprefix(19:26),'(i8)') ntime
 write(dataprefix(1:4),'(i4)') iyear
 fieldFile = trim(inDataDir)//trim(dataprefix)//'d05'
 fieldFile = trim(inDataDir)//'fields/'//trim(dataprefix)//'d05'
#elif orca025l75h6
 if(ngcm.eq.  3) dataprefix='ORCA025.L75-SLB2_3h_19900101_19901231_grid_'
! if(ngcm.eq.6) dataprefix='ORCA025.L75-SLB2_6h_19580101_19581231_grid_'
 if(ngcm.eq.  6) dataprefix='ORCA025.L75-SLB2_6h_20050101_20051231_grid_'
 if(ngcm.eq.730) dataprefix='ORCA025.L75-SLB0_730h_19770101_19771231_grid_'
! write(dataprefix(19:26),'(i8)') ntime
 write(dataprefix(23:26),'(i4)') iyear
 write(dataprefix(32:35),'(i4)') iyear
! print *,dataprefix
! stop 4906
! fieldFile = trim(inDataDir)//trim(dataprefix)
 fieldFile = trim(inDataDir)//'fields/'//trim(dataprefix)
! print *,fieldFile
  nread=mod(ints-1,intmax)+1
  start2D  = [subGridImin ,subGridJmin ,  1 , nread ]
  start3D  = [subGridImin ,subGridJmin ,  1 , nread ]
#else
 stop 39573
#endif

! print *,fieldFile
! Sea surface height
ierr=NF90_OPEN(trim(fieldFile)//'T.nc',NF90_NOWRITE,ncid)
ierr=NF90_INQ_VARID(ncid,'sossheig',varid)
if(ierr.ne.0) then
 print *,'file not found:',trim(fieldFile)//'T.nc'
 stop 3768
endif
ierr=NF90_GET_VAR(ncid,varid,temp2d_simp,start2d,count2d)
if(ierr.ne.0) stop 3799
ierr=NF90_CLOSE(ncid)

do j=1,JMT
 do i=1,IMT+1
  ii=i
  if(ii.eq.IMT+1) ii=1
  hs(i,j,2)=temp2d_simp(ii,j)
 enddo
enddo

do i=4,IMT
 ii=IMT+4-i
 hs(i,JMT+1,2)=hs(ii,JMT-3,2)  !  north fold 
enddo

#ifdef tempsalt 
! Temperature
gridFile = trim(fieldFile)//'T.nc'
ierr=NF90_OPEN(trim(gridFile),NF90_NOWRITE,ncid)
if(ierr.ne.0) stop 5751
ierr=NF90_INQ_VARID(ncid,'votemper',varid) 
if(ierr.ne.0) stop 3769
ierr=NF90_GET_VAR(ncid,varid,temp3d_simp,start3d,count3d)
if(ierr.ne.0) stop 3799
ierr=NF90_CLOSE(ncid)
do i=1,IMT
 do j=1,JMT
  do k=1,kmt(i,j)
   kk=KM+1-k
   tem(i,j,kk,2)=temp3d_simp(i,j,k)
  enddo
 enddo
enddo
   
! Salinity
ierr=NF90_OPEN(trim(gridFile),NF90_NOWRITE,ncid)
if(ierr.ne.0) stop 5751
ierr=NF90_INQ_VARID(ncid,'vosaline',varid) 
if(ierr.ne.0) stop 3769
ierr=NF90_GET_VAR(ncid,varid,temp3d_simp,start3d,count3d)
if(ierr.ne.0) stop 3799
ierr=NF90_CLOSE(ncid)
do i=1,IMT
 do j=1,JMT
  do k=1,kmt(i,j)
   kk=KM+1-k
   sal(i,j,kk,2)=temp3d_simp(i,j,k)
  enddo
 enddo
enddo

depthb=0.
do j=1,JMT
 latb=-80+0.25*float(j+subGridJmin-1)
 do i=1,IMT
  do k=1,kmt(i,j)
   kk=KM+1-k
   tempb(k)=tem(i,j,kk,2)
   saltb(k)=sal(i,j,kk,2)
  enddo
  call statvd(tempb, saltb, rhob ,KM ,depthb ,latb)
  do k=1,kmt(i,j)
   kk=KM+1-k
   rho(i,j,kk,2)=rhob(k)-1000.
  enddo
 enddo
enddo

#endif     

dmult=1.  ! amplification of the velocity amplitude by simple multiplication
! u velocity
gridFile = trim(fieldFile)//'U.nc'
ierr=NF90_OPEN(trim(gridFile),NF90_NOWRITE,ncid)
if(ierr.ne.0) stop 5751
ierr=NF90_INQ_VARID(ncid,'vozocrtx',varid) 
if(ierr.ne.0) stop 3769
ierr=NF90_GET_VAR(ncid,varid,temp3d_simp,start3d,count3d)
if(ierr.ne.0) stop 3799
ierr=NF90_CLOSE(ncid)
do i=1,IMT
 do j=1,JMT
  do k=1,kmu(i,j)
   kk=KM+1-k
   dd = dz(kk) 
   if(k.eq.1) dd = dd + 0.5*(hs(i,j,2) + hs(i+1,j,2))
   if(k.eq.kmu(i,j)) dd = botbox(i+subGridImin-1,j+subGridJmin-1,1)
   uflux(i,j,kk,2)=temp3d_simp(i,j,k) * dyu(i,j) * dd * dmult
  enddo
 enddo
enddo

! v velocity
gridFile = trim(fieldFile)//'V.nc'
ierr=NF90_OPEN(trim(gridFile),NF90_NOWRITE,ncid)
if(ierr.ne.0) stop 5751
ierr=NF90_INQ_VARID(ncid,'vomecrty',varid) ! kmt field
if(ierr.ne.0) stop 3770
ierr=NF90_GET_VAR(ncid,varid,temp3d_simp,start3d,count3d)
if(ierr.ne.0) stop 3799
ierr=NF90_CLOSE(ncid)

!  north fold 
do i=4,IMT
 ii=IMT+4-i
! vflux(i,JMT,:,2)=-vflux(ii,JMT-3,:,2)
enddo

do i=1,IMT
 do j=1,JMT
  do k=1,kmv(i,j)
   kk=KM+1-k
   dd = dz(kk) 
   if(k.eq.1) dd = dd + 0.5*(hs(i,j,2) + hs(i,j+1,2))
   if(k.eq.kmv(i,j)) dd = botbox(i+subGridImin-1,j+subGridJmin-1,2)
   vflux(i,j,kk,2)=temp3d_simp(i,j,k) * dxv(i,j) * dd * dmult
  enddo
 enddo
enddo



#ifdef drifter
! average velocity/transport over surface drifter drogue depth to simulate drifter trajectories
kbot=65 ; ktop=66 ! number of surface layers to integrat over
do i=1,imt
 do j=1,jmt
 
  uint=0. ; vint=0. ; zint=0.
  if(ktop.eq.KM) zint=hs(i,j,2)
  do k=kbot,ktop
   uint=uint+uflux(i,j,k,2) ! integrated transport
   vint=vint+vflux(i,j,k,2)
   zint=zint+dz(k)          ! total depth of drougued drifter
  enddo
  ! weighted transport for each layer
  do k=kbot,KM
   if(k.ne.KM) then
    uflux(i,j,k,2)=uint*dz(k)/zint 
    vflux(i,j,k,2)=vint*dz(k)/zint
   else
    uflux(i,j,k,2)=uint*(hs(i,j,2)+dz(k))/zint
    vflux(i,j,k,2)=vint*(hs(i,j,2)+dz(k))/zint
   endif
  enddo

 enddo
enddo

#endif


 deallocate ( temp3d_simp, temp2d_simp )
     
#ifdef tempsalt
 deallocate ( tempb, saltb, rhob, depthb, latb )
#endif

  return
end subroutine readfields



