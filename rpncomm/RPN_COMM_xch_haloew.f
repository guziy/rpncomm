!/* RMNLIB - Library of useful routines for C and FORTRAN programming
! * Copyright (C) 1975-2001  Division de Recherche en Prevision Numerique
! *                          Environnement Canada
! *
! * This library is free software; you can redistribute it and/or
! * modify it under the terms of the GNU Lesser General Public
! * License as published by the Free Software Foundation,
! * version 2.1 of the License.
! *
! * This library is distributed in the hope that it will be useful,
! * but WITHOUT ANY WARRANTY; without even the implied warranty of
! * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
! * Lesser General Public License for more details.
! *
! * You should have received a copy of the GNU Lesser General Public
! * License along with this library; if not, write to the
! * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
! * Boston, MA 02111-1307, USA.
! */

	SUBROUTINE RPN_COMM_xch_haloew(g,minx,maxx,miny,maxy,
     %             ni,jmin,jmax,nk,halox,haloy,periodx,periody)
	use rpn_comm
	implicit none
!
!	exchange a halo with neighbours
!

	integer minx,maxx,miny,maxy,ni,nj,nk,halox,haloy,jmin,jmax
	logical periodx,periody
!	integer *8 mem_time, exch_time, ewtime
	integer g(minx:maxx,miny:maxy,nk)
!
	
	include 'mpif.h'
!
!	integer *8 time_base,temp_time
	integer, dimension(halox,jmin:jmax,nk) :: halo_to_east,
     &         halo_to_west, halo_from_east, halo_from_west

!
	integer i, j, k, m
	integer nwds
	integer sendtag, gettag, ierr
	integer status(MPI_STATUS_SIZE)
	logical east,west,north,south
	integer eastpe,westpe,northpe,southpe

	integer tag_2e, tag_2w   ! tags for west_to_east and east_to_west moves
        integer, dimension(4) :: requests            ! table of requests
        integer, dimension(MPI_STATUS_SIZE,4) :: statuses  ! table of statuses
        integer messages ! number of pending asynchronous messages
	
	east=(bnd_east) .and. (.not.periodx)
	eastpe=pe_id(pe_mex+1,pe_mey)
	west=(bnd_west) .and. (.not.periodx)
	westpe=pe_id(pe_mex-1,pe_mey)
        north=(bnd_north) .and. (.not.periody)
        northpe=pe_id(pe_mex,pe_mey+1)
        south=(bnd_south) .and. (.not.periody)
        southpe=pe_id(pe_mex,pe_mey-1)
!
!       take care of the periodic one processor case
!
	if ( pe_nx.eq.1 ) then
	  if(periodx) then
	    do k=1,nk
	    do j=jmin,jmax
	    do m=1,halox
	      g(m-halox,j,k)=g(ni+m-halox,j,k)
	      g(ni+m,j,k)=g(m,j,k)
	    enddo
	    enddo
	    enddo
	  endif
	  return
	endif
!
!  extract east and west halos simultaneously (cache usage)
!
!	exch_time=0
!	mem_time=0
!	temp_time=time_base()
	if(halox.eq.4)then
	  do k=1,nk
	  do j=jmin,jmax
	    halo_to_east(1,j,k)=g(ni+1-halox,j,k)
	    halo_to_west(1,j,k)=g(1         ,j,k)
	    halo_to_east(2,j,k)=g(ni+2-halox,j,k)
	    halo_to_west(2,j,k)=g(2         ,j,k)
	    halo_to_east(3,j,k)=g(ni+3-halox,j,k)
	    halo_to_west(3,j,k)=g(3         ,j,k)
	    halo_to_east(4,j,k)=g(ni+4-halox,j,k)
	    halo_to_west(4,j,k)=g(4         ,j,k)
	  enddo
	  enddo
	elseif(halox.eq.3)then
	  do k=1,nk
	  do j=jmin,jmax
	    halo_to_east(1,j,k)=g(ni+1-halox,j,k)
	    halo_to_west(1,j,k)=g(1         ,j,k)
	    halo_to_east(2,j,k)=g(ni+2-halox,j,k)
	    halo_to_west(2,j,k)=g(2         ,j,k)
	    halo_to_east(3,j,k)=g(ni+3-halox,j,k)
	    halo_to_west(3,j,k)=g(3         ,j,k)
	  enddo
	  enddo
	elseif(halox.eq.2)then
	  do k=1,nk
	  do j=jmin,jmax
	    halo_to_east(1,j,k)=g(ni+1-halox,j,k)
	    halo_to_west(1,j,k)=g(1         ,j,k)
	    halo_to_east(2,j,k)=g(ni+2-halox,j,k)
	    halo_to_west(2,j,k)=g(2         ,j,k)
	  enddo
	  enddo
	elseif(halox.eq.1)then
	  do k=1,nk
	  do j=jmin,jmax
	    halo_to_east(1,j,k)=g(ni+1-halox,j,k)
	    halo_to_west(1,j,k)=g(1         ,j,k)
	  enddo
	  enddo
	else
	  do k=1,mod(nk,2)
	  do j=jmin,jmax
	  do m=1,halox
	    halo_to_east(m  ,j,k  )=g(ni+m  -halox,j,k  )
	    halo_to_west(m  ,j,k  )=g(m  ,j,k  )
	  enddo
	  enddo
	  enddo
	  do k=1+mod(nk,2),nk,2
	  do j=jmin,jmax
	  do m=1,halox
	    halo_to_east(m  ,j,k  )=g(ni+m  -halox,j,k  )
	    halo_to_west(m  ,j,k  )=g(m  ,j,k  )
	    halo_to_east(m  ,j,k+1)=g(ni+m  -halox,j,k+1)
	    halo_to_west(m  ,j,k+1)=g(m  ,j,k+1)
	  enddo
	  enddo
	  enddo
	endif
!	mem_time=mem_time+time_base()-temp_time
	if(async_exch) THEN !  asynchronous simultaneous west to east and east to west moves
	  nwds=halox*(jmax-jmin+1)*nk
	  sendtag=pe_medomm 
	  tag_2w=westpe
	  tag_2e=eastpe
          messages = 0
	  if(.not. east) then
	    messages = messages + 1
	    call MPI_ISEND(halo_to_east,nwds,MPI_INTEGER,eastpe,   ! send to east neighbor unless i am east PE
     %           sendtag,PE_DEFCOMM,requests(messages),ierr)       ! tag is PE grid ordinal of sender
	    messages = messages + 1
            call MPI_IRECV(halo_from_east,nwds,MPI_INTEGER,eastpe, ! get from east neighbor unless i am east PE
     %           eastpe,PE_DEFCOMM,requests(messages),ierr)        ! sender was eastpe therefore tag is eastpe
          endif
	  if(.not. west) then
	    messages = messages + 1
	    call MPI_ISEND(halo_to_west,nwds,MPI_INTEGER,westpe,  ! send to west neighbor unless i am west PE
     %           sendtag,PE_DEFCOMM,requests(messages),ierr)      ! tag is PE grid ordinal of sender
	    messages = messages + 1
            call MPI_IRECV(halo_from_west,nwds,MPI_INTEGER,westpe, ! get from west neighbor unless i am west PE
     %           westpe,PE_DEFCOMM,requests(messages),ierr)        ! sender was westpe therefore tag is westpe
          endif
	  call MPI_waitall(messages,requests,statuses,ierr)  ! wait for all E-W and W-E messages to complete
!
	ELSE   ! THE FOLLOWING CODE WILL EVENTUALLY BE DEPRECATED WHEN async CODE IS FULLY DEBUGGED
!
!  process west to east move
!	
!	temp_time=time_base()
!
	nwds=halox*(jmax-jmin+1)*nk
	sendtag=pe_medomm
	gettag=westpe
	tag_2e=westpe
!
!	call tmg_start(94,'COMM XCH EW')
	if(west) then
!	  send to east_neighbor
	  if(.not.east)then
	    call MPI_SEND(halo_to_east,nwds,MPI_INTEGER,eastpe,
     %	         sendtag,PE_DEFCOMM,ierr)
	  endif
	else if(east) then
!	  receive from west_neighbor
	  call MPI_RECV(halo_from_west,nwds,MPI_INTEGER,westpe,
     %	       gettag,PE_DEFCOMM,status,ierr)
	else
!	  send to east_neighbor and receive from west_neighbor
	  call MPI_SENDRECV(
     %         halo_to_east,nwds,MPI_INTEGER,eastpe,sendtag,
     %         halo_from_west,nwds,MPI_INTEGER,westpe,gettag,
     %	       PE_DEFCOMM,status,ierr)
	endif
!
!
!  process east to west move
!
	nwds=halox*(jmax-jmin+1)*nk
	sendtag=pe_medomm
	gettag=eastpe
	tag_2w=eastpe
!
	
	if(east) then
!	  send to west_neighbor
	  if(.not.west) then
	    call MPI_SEND(halo_to_west,nwds,MPI_INTEGER,westpe,
     %	         sendtag,PE_DEFCOMM,ierr)
	  endif
	else if(west) then
!	  receive from east_neighbor
	  call MPI_RECV(halo_from_east,nwds,MPI_INTEGER,eastpe,
     %	       gettag,PE_DEFCOMM,status,ierr)
	else
!	  send to west_neighbor and receive from east_neighbor
	  call MPI_SENDRECV(
     %         halo_to_west,nwds,MPI_INTEGER,westpe,sendtag,
     %	       halo_from_east,nwds,MPI_INTEGER,eastpe,gettag,
     %	       PE_DEFCOMM,status,ierr)
	endif
!
	ENDIF  ! END OF CODE TO BE DEPRECATED
!
!	call tmg_stop(94)
!	exch_time=exch_time+time_base()-temp_time
!
!  put halos back into array simultaneously (cache usage)
!
!	temp_time=time_base()
	if(halox.eq.4)then
	  do k=1,nk
	  do j=jmin,jmax
	    if(.not.west)then
	      g(-3,j,k)=halo_from_west(1,j,k)
	      g(-2,j,k)=halo_from_west(2,j,k)
	      g(-1,j,k)=halo_from_west(3,j,k)
	      g( 0,j,k)=halo_from_west(4,j,k)
	    endif
	    if(.not.east)then
	      g(ni+1,j,k)=halo_from_east(1,j,k)
	      g(ni+2,j,k)=halo_from_east(2,j,k)
	      g(ni+3,j,k)=halo_from_east(3,j,k)
	      g(ni+4,j,k)=halo_from_east(4,j,k)
	    endif
	  enddo
	  enddo
	elseif(halox.eq.3)then
	  do k=1,nk
	  do j=jmin,jmax
	    if(.not.west)then
	      g(-2,j,k)=halo_from_west(1,j,k)
	      g(-1,j,k)=halo_from_west(2,j,k)
	      g( 0,j,k)=halo_from_west(3,j,k)
	    endif
	    if(.not.east)then
	      g(ni+1,j,k)=halo_from_east(1,j,k)
	      g(ni+2,j,k)=halo_from_east(2,j,k)
	      g(ni+3,j,k)=halo_from_east(3,j,k)
	    endif
	  enddo
	  enddo
	elseif(halox.eq.2)then
	  do k=1,nk
	  do j=jmin,jmax
	    if(.not.west)then
	      g(-1,j,k)=halo_from_west(1,j,k)
	      g( 0,j,k)=halo_from_west(2,j,k)
	    endif
	    if(.not.east)then
	      g(ni+1,j,k)=halo_from_east(1,j,k)
	      g(ni+2,j,k)=halo_from_east(2,j,k)
	    endif
	  enddo
	  enddo
	elseif(halox.eq.1)then
	  do k=1,nk
	  do j=jmin,jmax
	    if(.not.west)then
	      g( 0,j,k)=halo_from_west(1,j,k)
	    endif
	    if(.not.east)then
	      g(ni+1,j,k)=halo_from_east(1,j,k)
	    endif
	  enddo
	  enddo
	else
	  do k=1,mod(nk,2)
	  do j=jmin,jmax
	    if(.not.west)then
	      do m=1,halox
	        g(m-halox,j,k  )=halo_from_west(m,j,k  )
	      enddo
	    endif
	    if(.not.east)then
	      do m=1,halox
	        g(ni+m,j,k  )=halo_from_east(m,j,k  )
	      enddo
	    endif
	  enddo
	  enddo
	  do k=1+mod(nk,2),nk,2
	  do j=jmin,jmax
	    if(.not.west)then
	      do m=1,halox
	        g(m-halox,j,k  )=halo_from_west(m,j,k  )
	        g(m-halox,j,k+1)=halo_from_west(m,j,k+1)
!	        g(m-halox,j,k+2)=halo_from_west(m,j,k+2)
!	        g(m-halox,j,k+3)=halo_from_west(m,j,k+3)
	      enddo
	    endif
	    if(.not.east)then
	      do m=1,halox
	        g(ni+m,j,k  )=halo_from_east(m,j,k  )
	        g(ni+m,j,k+1)=halo_from_east(m,j,k+1)
!	        g(ni+m,j,k+2)=halo_from_east(m,j,k+2)
!	        g(ni+m,j,k+3)=halo_from_east(m,j,k+3)
	      enddo
	    endif
	  enddo
	  enddo
	endif


        return
        end
