
module mod_write

  USE mod_time, only: intstart,ints
  USE mod_name, only: casename, case, Project
  USE mod_time 
  USE mod_active_particles, only: upr !!Joakim edit
  USE mod_tempsalt, only: n2Dtracers, n3Dtracers, tracers2D, tracers3D
  ! USE mod_traj, only: ib,jb,kb

  IMPLICIT NONE
  INTEGER                                    :: intminInOutFile
  CHARACTER(LEN=200)                         :: outDataDir, outDataFile
  CHARACTER (LEN=200)                        ::  projdir="", ormdir=""
  CHARACTER(LEN=200)                         :: inargstr1='', inargstr2=''
  INTEGER                                    :: twritetype = 0
  INTEGER                                    :: binwritetype = 0
  INTEGER                                    :: fileseq = 0
  INTEGER, SAVE                              :: binRecL
  CHARACTER(LEN=20)                          :: rankstamp=''
  LOGICAL                                    :: outdirdate = .true.
  LOGICAL                                    :: outdircase = .true.
  CHARACTER (LEN=30)                         :: yearstr
  
CONTAINS


  subroutine setup_outdatadir

    if (len(trim(outDataDir)) == 0) then
       CALL getenv('TRMOUTDATADIR', projdir)
       if (len(trim(projdir)) .ne. 0) then
          print *, 'Using outdatdir defined by TRMOUTDATADIR'
          outDataDir = trim(projdir) // trim(Project) // '/'
       end if
    end if
    if (outdircase .eqv. .true.) outDataDir = trim(outDataDir) // trim(Case) // '/'
    if (outdirdate .eqv. .true.) then
       yearstr = 'XXXXXXXX-XXXX'
       write (yearstr(1:4),'(I4.4)') int(startYear)
       write (yearstr(5:6),'(I2.2)') int(startMon)
       write (yearstr(7:8),'(I2.2)') int(startDay)
       write (yearstr(10:11),'(I2.2)') int(startHour)
       write (yearstr(12:13),'(I2.2)') int(startMin)
       outDataDir = trim(outDataDir)//trim(yearstr) // '/'
    end if    
    call system('mkdir -p ' // trim(outDataDir))
    
  end subroutine setup_outdatadir

  
  subroutine open_outfiles

    IMPLICIT NONE
    CHARACTER(LEN=200)                         :: fullWritePref
    CHARACTER(LEN=20)                          :: intminstamp='', partstamp=''
    
    if ((intminInOutFile.eq.1) .or. (intminInOutFile.eq.3)) then
       write (intminstamp, '(A,i8.8)') '_t', intstart
    end if
    if ((intminInOutFile.eq.2) .or. (intminInOutFile.eq.3)) then
         write (partstamp, '(A,i6.6)') '_p', max(ints-intstart,0)+1
      end if
      
    fullWritePref =  trim(outDataDir)  // trim(outDataFile) //    &
                     trim(inargstr1)   // trim(inargstr2)   //    & 
                     trim(intminstamp) // trim(partstamp)   //    &
                     trim(rankstamp)

#if defined textwrite
    open(56, file=trim(fullWritePref)//'_run.asc')    
    open(57, file=trim(fullWritePref)//'_out.asc')  
    open(58, file=trim(fullWritePref)//'_ini.asc')   
    open(59, file=trim(fullWritePref)//'_err.asc')
#endif

#if defined binwrite
    if (binwritetype == 0) then
       binRecL = 24
    else if (binwritetype == 1) then
       binRecL = 36
    else if (binwritetype == 2) then
       binRecL = 36 + 4*n2Dtracers + 4*n3Dtracers
       print*,'binRecL is ',binRecL
    else
       binRecL = 72
    end if
    
    !open(unit=75 ,file=trim(fullWritePref)//'_out.bin', &  
    !     access='direct' ,form='unformatted' ,recl=24 ,status='replace')
    !open(unit=76 ,file=trim(fullWritePref)//'_run.bin', &  
    !     access='direct' ,form='unformatted' ,recl=24 ,status='replace')
    !open(unit=77 ,file=trim(fullWritePref)//'_kll.bin', &
    !     access='direct' ,form='unformatted' ,recl=24 ,status='replace')
    !open(unit=78 ,file=trim(fullWritePref)//'_ini.bin', &  
    !     access='direct' ,form='unformatted' ,recl=24 ,status='replace')
    !open(unit=79 ,file=trim(fullWritePref)//'_err.bin', &  
    !     access='direct' ,form='unformatted' ,recl=24 ,status='replace')
    open(unit=75 ,file=trim(fullWritePref)//'_out.bin', &
         access='direct' ,form='unformatted' ,recl=binRecL ,status='replace') !!Joakim edit
    !open(unit=76 ,file=trim(fullWritePref)//'_run.bin', &
    !     access='direct' ,form='unformatted' ,recl=32 ,status='replace') !!Joakim edit
    open(unit=76 ,file=trim(fullWritePref)//'_run.bin', &
         access='direct' ,form='unformatted' ,recl=binRecL ,status='replace') !!Joakim edit
    open(unit=77 ,file=trim(fullWritePref)//'_kll.bin', &
         access='direct' ,form='unformatted' ,recl=binRecL ,status='replace') !!Joakim edit
    open(unit=78 ,file=trim(fullWritePref)//'_ini.bin', &
         access='direct' ,form='unformatted' ,recl=binRecL ,status='replace') !!Joakim edit
    open(unit=79 ,file=trim(fullWritePref)//'_err.bin', &
         access='direct' ,form='unformatted' ,recl=binRecL ,status='replace') !!Joakim edit
#endif

#if defined csvwrite
    open(unit=85, file=trim(fullWritePref)//'_out.csv', status='replace')
    open(unit=86, file=trim(fullWritePref)//'_run.csv', status='replace')
    open(unit=87, file=trim(fullWritePref)//'_kll.csv', status='replace')
    open(unit=88, file=trim(fullWritePref)//'_ini.csv', status='replace')
    open(unit=89, file=trim(fullWritePref)//'_err.csv', status='replace')
#endif


#ifdef streamxy
    open(51,file=trim(fullWritePref)//'_psi_xy_yx.bin',form='unformatted')
#endif
#if defined streamv
    open(52,file=trim(fullWritePref)//'_psi_yz_xz.bin',form='unformatted')
#endif
#if defined streamr 
    open(53,file=trim(fullWritePref)//'_psi_xr_yr.bin',form='unformatted')
#endif
#ifdef stream_thermohaline
    open(54,file=trim(fullWritePref)//'_psi_ts.bin',form='unformatted')
#endif

#ifdef rerun
    open(67, file=trim(fullWritePref)//'_rerun.asc')
#endif




  end subroutine open_outfiles

  subroutine close_outfiles
#if defined textwrite
    close(56)
    close(57)
    close(58)
    close(59)
#endif
#if defined binwrite
    close(75)
    close(76)
    close(77)
    close(78)
    close(79)
#endif
#if defined csvwrite
    close(75)
    close(76)
    close(77)
    close(78)
    close(79)
#endif
  end subroutine close_outfiles

  subroutine writedata(sel)
    USE mod_time
    USE mod_pos
    USE mod_traj
    USE mod_loopvars
    USE mod_name

    IMPLICIT NONE

    REAL                                 :: vort
    INTEGER                              :: sel ,xf ,yf ,zf ,n
    INTEGER*8, SAVE                      :: recPosIn=0  ,recPosOut=0
    INTEGER*8, SAVE                      :: recPosRun=0 ,recPosErr=0
    INTEGER*8, SAVE                      :: recPosKll=0
    INTEGER*4                            :: ntrac4
    INTEGER                              :: ziter
    REAL(DP)                             :: zx1,zy1,zz1,ztt,zt0,zvol
    REAL*4                               :: x14 ,y14 ,z14, tt14, t014
    REAL*4                               :: lapu14 ,lapv14 ,lapu24, lapv24, dlapu4, dlapv4, vort24, hdiv24, &
                                            dvort4, dhdiv4, upr4, vpr4
    REAL(DP), DIMENSION(n3Dtracers)      :: trc3D
    REAL*4, DIMENSION(n3Dtracers)        :: trc3D4 
    REAL*8                               :: twrite
    ! === Variables to interpolate fields ===
    REAL                                       :: temp, salt, dens
    REAL                                       :: temp2, salt2, dens2
#if defined  tes 
566 format(i8,i7,f8.3,f8.3,f7.3,2f10.2 &
         ,f10.0,f6.2,f6.2,f6.2,f6.0,8e8.1 )
#elif defined atmospheric 
566 format(i8,i7,f7.2,f7.2,f7.2,f10.2,f10.2 &
         ,f15.0,f8.2,f8.2,f8.2,f6.0,8e8.1 )
#elif defined orc
    !566 format(i8,i7,2f8.2,f6.2,2f10.2 &
    !         ,f12.0,f6.1,f6.2,f6.2,f6.0,8e8.1 )
566 format(i8,i7,2f9.3,f9.2,2f14.2 &
         ,f12.0,f6.1,f6.2,f6.2,f6.0,8e8.1 )
#else
566 format(i8,i7,2f9.3,f9.2,2f14.2 &
         ,f12.0,f6.1,f6.2,f6.2,f6.0,8e8.1 )
    !566 format(i7,i7,f7.2,f7.2,f7.1,f10.4,f10.4 &
    !         ,f13.4,f6.2,f6.2,f6.2,f6.0,8e8.1 )
#endif
    
    xf   = floor(x1)
    yf   = floor(y1)
    zf   = floor(z1)
    
    !if ((sel .ne. 19) .and. (sel.ne.40)) then
       ! this requires too much memory
       !       vort = (vvel(xf+1,yf,zf)-vvel(xf-1,yf,zf))/4000 - &
       !            (uvel(xf,yf+1,zf)-uvel(xf,yf-1,zf))/4000   
    !end if
    
#if defined tempsalt
    call interp2(ib,jb,kb,temp,salt,dens)
#endif

#ifdef newtracers
    call interp_gen3D(ib,jb,kb,x1,y1,z1,n3Dtracers,trc3D,2,method='nearest')
#else
    !trc3D(1) = temp
    !trc3D(2) = salt
    !trc3D(3) = dens
#endif

! 
! Get data for this trajectory
! 
ziter = trajectories(ntrac)%niter    
zx1   = trajectories(ntrac)%x1
zy1   = trajectories(ntrac)%y1
zz1   = trajectories(ntrac)%z1
ztt   = trajectories(ntrac)%tt
zt0   = trajectories(ntrac)%t0
zvol  = trajectories(ntrac)%subvol

#if defined textwrite 
    select case (sel)
    case (10)
       !write(58,566) ntrac,niter,x1,y1,z1,tt/tday,t0/tday,subvol,temp,salt,dens
       write(58,566) ntrac,ziter,zx1,zy1,zz1,ztt/tday,zt0/tday,zvol,temp,salt,dens
!       if(temp==0.) stop 4867
    case (11)
       !if(  (kriva == 1 .AND. nrj(4,ntrac) == niter-1   ) .or. &
       !     (kriva == 2 .AND. scrivi                    ) .or. &
       !     (kriva == 3                                 ) .or. &
       !     (kriva == 4 .AND. niter == 1                ) .or. &
       !     (kriva == 5 .AND.                                  &
       !   &  MOD((REAL(tt)-REAL(t0))*REAL(NGCM)/REAL(ITER), 3600.) == 0.d0 ) .or. &
       !     (kriva == 6 .AND. .not.scrivi                  ) ) then
       if(  (kriva == 1 .AND. trajectories(ntrac)%niter == niter-1   ) .or. &
            (kriva == 2 .AND. scrivi                    ) .or. &
            (kriva == 3                                 ) .or. &
            (kriva == 4 .AND. niter == 1                ) .or. &
            (kriva == 5 .AND.                                  &
          &  MOD((REAL(tt)-REAL(t0))*REAL(NGCM)/REAL(ITER), 3600.) == 0.d0 ) .or. &
            (kriva == 6 .AND. .not.scrivi                  ) ) then
!#if defined tempsalt
!           !call interp(ib,jb,kb,x1,y1,z1,temp,salt,dens,1) 
!           call interp2(ib,jb,kb,temp,salt,dens)
!#endif
#if defined biol
          write(56,566) ntrac,ints,x1,y1,z1,tt/3600.,t0/3600.
#else
#if defined tempsalt
          !write(56,566) ntrac,ints,x1,y1,z1,tt/tday,t0/tday,subvol,temp,salt,dens
          write(56,566) ntrac,ints,zx1,zy1,zz1,ztt/tday,zt0/tday,zvol,temp,salt,dens
#else
          !write(56,566) ntrac,ints,x1,y1,z1,tt/tday,t0/tday,subvol
          write(56,566) ntrac,ints,zx1,zy1,zz1,ztt/tday,zt0/tday,zvol
#endif        
#endif        
       endif
    case (13)
       ! === write sed pos ===
       write(57,566) ntrac,niter,x1,y1,z1, &
            tt/tday,t0/tday,subvol,temp,salt,dens 
    case (14)
       write(56,566) ntrac,ints,x1,y1,z1, &
            tt/60.,t0/3600.,subvol,temp,salt,dens
    case (15)
       write(57,566) ntrac,ints,x1,y1,z1, &
            tt/tday,t0/tday,subvol,temp,salt,dens
    case (16)
       if(kriva.ne.0 ) then
#if defined tempsalt
           !call interp(ib,jb,kb,x1,y1,z1,temp,salt,dens,1) 
           call interp2(ib,jb,kb,temp,salt,dens)
#endif
#ifdef newtracers
           call interp_gen3D(ib,jb,kb,x1,y1,z1,n3Dtracers,trc3D,2,method='nearest')
#endif           
          write(56,566) ntrac,ints,x1,y1,z1, &
               tt/tday,t0/tday,subvol,temp,salt,dens
       end if
    case (17)
       write(57,566) ntrac,ints,x1,y1,z1,tt/tday,t0/tday,subvol &
            ,temp,salt,dens  
    case (19)
       ! === write last sedimentation positions ===
       open(34,file=trim(outDataDir)//trim(outDataFile)//'_sed.asc') 
       do n=1,ntracmax
        !if(nrj(1,n).ne.0) then
        if(trajectories(n)%ib /= 0) then
         !write(34,566) n,nrj(4,n),trj(1,n),trj(2,n),trj(3,n),trj(4,n)/tday,trj(7,n)/tday
         write(34,566) n,trajectories(n)%niter,trajectories(n)%x1,trajectories(n)%y1,trajectories(n)%z1, &
                     & trajectories(n)%tt/tday,trajectories(n)%t0/tday
      endif
       enddo
       close(34)
    case (40)
       !write(59,566) ntrac,ints,x1,y1,z1,tt/tday,t0/tday,subvol,temp,salt,dens  
       write(59,566) ntrac,ints,zx1,zy1,zz1,ztt/tday,zt0/tday,zvol,temp,salt,dens
    case (99) !switch
       
    end select
#endif 
   
#if defined binwrite 
    ntrac4=int(ntrac,kind=4)
    x14=real(x1,kind=4)
    y14=real(y1,kind=4)
    z14=real(z1,kind=4)
    tt14=real(tt/tday,kind=4)!Joakim edit
    t014=real(t0/tday,kind=4)!Joakim edit
    lapu14 = real(lapu1,kind=4)!Joakim edit
    lapu24 = real(lapu2,kind=4)!Joakim edit
    lapv14 = real(lapv1,kind=4)!Joakim edit
    lapv24 = real(lapv2,kind=4)!Joakim edit
    vort24 = real(vort2,kind=4)!Joakim edit
    hdiv24 = real(hdiv2,kind=4)!Joakim edit
    dlapu4 = real(dlapu,kind=4)!Joakim edit
    dlapv4 = real(dlapv,kind=4)!Joakim edit
    dvort4 = real(dvort,kind=4)!Joakim edit
    dhdiv4 = real(dhdiv,kind=4)!Joakim edit
    upr4   = real(upr(1,1),kind=4)!Joakim edit
    vpr4   = real(upr(3,1),kind=4)!Joakim edit
    
#ifdef newtracers
    !
    ! Experimental new tracer interpolation scheme
    !
    call interp_gen3D(ib,jb,kb,x1,y1,z1,n3Dtracers,trc3D,2,method='nearest')     
    trc3D4 = real(trc3D,kind=4)
#else
    trc3D4(:) = 0.
#endif
    
    if (twritetype==1) then
       twrite = tt
    else if (twritetype==2) then
       call updateclock
       twrite = currJDtot
    else
       twrite = real(ints,kind=8)
    end if
    select case (sel)       
    case (10) !in
       recPosIn = recPosIn + 1
       if (binwritetype == 0) then
          write(unit=78 ,rec=recPosIn) ntrac,twrite,x14,y14,z14
       else if (binwritetype == 1) then
          write(unit=78 ,rec=recPosIn) ntrac,twrite,x14,y14,z14,tt14,t014 !!Joakim edit
       else if (binwritetype == 2) then
          write(unit=78, rec=recPosIn) ntrac,twrite, x14,y14,z14,tt14,t014, trc3D4(1:n3Dtracers)          
       else
          write(unit=78 ,rec=recPosIn) ntrac,twrite,x14,y14,z14,tt14,t014, &
                                       lapu14,lapu24,lapv14,lapv24,upr4,vpr4,vort24,hdiv24,dvort4,dhdiv4
       end if
       return
    case (11)
       !if(  (kriva == 1 .and. nrj(4,ntrac)  ==  niter-1 ) .or. &
       if(  (kriva == 1 .and. trajectories(ntrac)%niter  ==  niter-1 ) .or. &
            (kriva == 2 .and. scrivi                    ) .or. &
            (kriva == 3                                 ) .or. &
            (kriva == 4 .and. niter == 1                ) .or. &
            (kriva == 5 .and. abs(dmod(tt-t0,9.d0)) < 1e-5 ) .or. &
            (kriva == 6 .and. .not.scrivi                  ) ) then
#if defined tempsalt
          call interp(ib,jb,kb,x1,y1,z1,temp, salt,  dens,1)
 !         call interp(ib,jb,kb,x1,y1,z1,temp2,salt2, dens2,2)
          !z14=real(salt*rb+salt2*(1-rb),kind=4)
#endif
#ifdef newtracers
          call interp_gen3D(ib,jb,kb,x1,y1,z1,n3Dtracers,tracers3D,2,method='linear')
#endif
          recPosRun = recPosRun+1
          if (binwritetype == 0) then
             write(unit=76 ,rec=recPosRun) ntrac4,twrite,x14,y14,z14
          else if (binwritetype == 1) then
             write(unit=76 ,rec=recPosRun) ntrac4,twrite,x14,y14,z14,tt14,t014
          else 
             write(unit=76 ,rec=recPosRun) ntrac,twrite,x14,y14,z14,tt14,t014,&
                                           lapu14,lapu24,lapv14,lapv24,upr4,vpr4,vort24,hdiv24,dvort4,dhdiv4 !!Joakim edit
          end if
       end if
    case (13)
       recPosKll = recPosKll + 1
       if (binwritetype == 0) then
          write(unit=77 ,rec=recPosKll) ntrac,twrite,x14,y14,z14
       else if (binwritetype == 1) then
          write(unit=77 ,rec=recPosKll) ntrac,twrite,x14,y14,z14,tt14,t014 
       else
          write(unit=77 ,rec=recPosKll) ntrac,twrite,x14,y14,z14,tt14,t014,&
                                        lapu14,lapu24,lapv14,lapv24,upr4,vpr4,vort24,hdiv24,dvort4,dhdiv4 
       end if
    case (15)
       recPosRun = recPosRun + 1
       if (binwritetype == 0) then
          write(unit=76 ,rec=recPosRun) ntrac4,twrite,x14,y14,z14
       else if (binwritetype == 1) then
          write(unit=76 ,rec=recPosRun) ntrac4,twrite,x14,y14,z14,tt14,t014
       else
          write(unit=76 ,rec=recPosRun) ntrac4,twrite,x14,y14,z14,tt14,t014,&
                                        lapu14,lapu24,lapv14,lapv24, upr4, vpr4, vort24,hdiv24,dvort4,dhdiv4 
       end if
    case (17) !out
       recPosOut = recPosOut + 1
       if (binwritetype == 0) then
          write(unit=77 ,rec=recPosOut) ntrac,twrite,x14,y14,z14
       else if (binwritetype == 1) then
          write(unit=77 ,rec=recPosOut) ntrac,twrite,x14,y14,z14,tt14,t014 !!Joakim edit
       else
          write(unit=77 ,rec=recPosOut) ntrac,twrite,x14,y14,z14,tt14,t014, &
                                        lapu14,lapu24,lapv14,lapv24, upr4, vpr4, vort24,hdiv24,dvort4,dhdiv4
       end if
    case (19) !end
       recPosOut = recPosOut + 1
       if (binwritetype == 0) then
          write(unit=75 ,rec=recPosOut) ntrac,twrite,x14,y14,z14
       else if (binwritetype == 1) then
          write(unit=75 ,rec=recPosOut) ntrac,twrite,x14,y14,z14,tt14,t014 !!Joakim edit
       else
          write(unit=75 ,rec=recPosOut) ntrac,twrite,x14,y14,z14,tt14,t014, &
                                        lapu14,lapu24,lapv14,lapv24, upr4, vpr4, vort24,hdiv24,dvort4,dhdiv4
       end if
    case (40) !error
       recPosErr=recPosErr + 1    
       if (binwritetype == 0) then
          write(unit=79 ,rec=recPosErr) ntrac,twrite,x14,y14,z14
       else if (binwritetype == 1) then
          write(unit=79 ,rec=recPosErr) ntrac,twrite,x14,y14,z14,tt14,t014 !!Joakim edit
       else
          write(unit=79 ,rec=recPosErr) ntrac,twrite,x14,y14,z14,tt14,t014, &
                                        lapu14,lapu24,lapv14,lapv24, upr4, vpr4, vort24,hdiv24,dvort4,dhdiv4
       end if
    case (99) !switch
       if ((recPosRun > 50000000).and.(intminInOutFile.eq.2)) then
          call close_outfiles
          call open_outfiles
          recPosRun = 0
          recPosIn  = 0
          recPosOut = 0
          recPosErr = 0
          print *, "Switched run file" 
       end if
    end select
#endif    

#if defined csvwrite 
    x14=real(x1,kind=4)
    y14=real(y1,kind=4)
    z14=real(z1,kind=4)
    if (twritetype==1) then
       twrite = tt
    else if (twritetype==2) then
       call updateclock
       twrite = currJDtot
    else
       twrite = real(ints,kind=8)
    end if
    select case (sel)       
    case (10)
       write(88,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
       return
    case (11)
       !if(  (kriva == 1 .and. nrj(4,ntrac)  ==  niter-1 ) .or. &
       if(  (kriva == 1 .and. trajectories(ntrac)%niter  ==  niter-1 ) .or. &
            (kriva == 2 .and. scrivi                    ) .or. &
            (kriva == 3                                 ) .or. &
            (kriva == 4 .and. niter == 1                ) .or. &
            (kriva == 5 .and. abs(dmod(tt-t0,9.d0)) < 1e-5 ) .or. &
            (kriva == 6 .and. .not.scrivi                  )  ) then
          !!!! CALL FIELD-INTERP !!!!
          write(86,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
       end if
    case (13)
       write(87,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
    case (15)
       write(86,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
    case (17)
       write(87,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
    case (19)
       write(85,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
    case (40)
       write(89,"(I0,4(',',F0.5))")  ntrac, twrite, x14, y14, z14
    case (99) !switch
       
    end select
#endif   
  end subroutine writedata

end module mod_write
