#if defined(SELF_TEST)
program self_test
call RPN_COMM_test_limit(6)
stop
end
#endif
!/! RPN_COMM - Library of useful routines for C and FORTRAN programming
! ! Copyright (C) 1975-2015  Recherche en Prevision Numerique
! !                          Environnement Canada
! !
! ! This library is free software; you can redistribute it and/or
! ! modify it under the terms of the GNU Lesser General Public
! ! License as published by the Free Software Foundation,
! ! version 2.1 of the License.
! !
! ! This library is distributed in the hope that it will be useful,
! ! but WITHOUT ANY WARRANTY; without even the implied warranty of
! ! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
! ! Lesser General Public License for more details.
! !
! ! You should have received a copy of the GNU Lesser General Public
! ! License along with this library; if not, write to the
! ! Free Software Foundation, Inc., 59 Temple Place - Suite 330,
! ! Boston, MA 02111-1307, USA.
! !/
      subroutine RPN_COMM_test_limit(NPE)
!****f* RPN_COMM/Use Example
! EXAMPLE
      implicit none
      integer, intent(IN) :: NPE
!      integer, parameter :: NPE=6
      integer, dimension(NPE) :: count, offset
      integer :: my_id, gmin, gmax, lmini, lmaxi, status
      integer :: RPN_COMM_limit_2
      external :: RPN_COMM_limit_2

      gmin = 1
      gmax = 13
      print 101,'NPE, gmin, gmax :',NPE,gmin,gmax
      print 101,'relax =',0
      status = RPN_COMM_limit_2(0, npe, gmin, gmax,lmini,lmaxi,count, offset,0)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax',' stat'
      print 101, 'pe_me=',0, lmini,lmaxi, gmin, gmax, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      print 101,'NPE, gmin, gmax :',NPE,gmin,gmax
      print 101,'relax =',1
      status = RPN_COMM_limit_2(0, npe, gmin, gmax,lmini,lmaxi,count, offset,1)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax',' stat'
      print 101, 'pe_me=',0, lmini,lmaxi, gmin, gmax, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      print 101,'NPE, gmin, gmax :',NPE,gmin,gmax
      print 101,'relax =',2
      status = RPN_COMM_limit_2(0, npe, gmin, gmax,lmini,lmaxi,count, offset,2)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax',' stat'
      print 101, 'pe_me=',0, lmini,lmaxi, gmin, gmax, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      gmin = 1
      gmax = 13
      print 101,'NPE, gmin, gmax :',NPE,gmin,gmax
      print 101,'relax =',3
      do my_id=0,NPE-1
        status = RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,3)
        print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax',' stat'
        print 101, 'pe_me=',my_id, lmini,lmaxi, gmin, gmax, status
        print 101, 'count=',count
        print 101, 'offst=',offset
        print *,''
      enddo
!******
      print *, '---------------------------'
101   format(A,10I6)
102   format(A,10A6)
      my_id=NPE-1
      status = RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,1)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax','relax',' stat'
      print 101, 'pe_me=',my_id, lmini,lmaxi, gmin, gmax, 1, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      gmax = 5
      status = RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,1)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax','relax',' stat'
      print 101, 'pe_me=',my_id, lmini,lmaxi, gmin, gmax, 1, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      gmax = 5
      status = RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,2)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax','relax',' stat'
      print 101, 'pe_me=',my_id, lmini,lmaxi, gmin, gmax, 2, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      status = RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,3)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax','relax',' stat'
      print 101, 'pe_me=',my_id, lmini,lmaxi, gmin, gmax, 3, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      gmax = 8
      status = RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,3)
      print 102, '      ','   ID',' mini',' maxi',' gmin',' gmax','relax',' stat'
      print 101, 'pe_me=',my_id, lmini,lmaxi, gmin, gmax, 3, status
      print 101, 'count=',count
      print 101, 'offst=',offset
      print *, '---------------------------'
      end subroutine RPN_COMM_test_limit
!**function  RPN_COMM_limit_2 global domain decomposition function (along one dimension)
!InTf!
!!integer function RPN_COMM_limit_2(my_id, npe, gmin, gmax,lmini,lmaxi,count, offset,relax)!InTf!
!****f* RPN_COMM/RPN_COMM_limit_2
! SYNOPSIS
      integer function RPN_COMM_limit_2(my_id, npe, gmin, gmax, &
     &     lmini,lmaxi,count, offset,relax)
! AUTHOR
!  M.Valin Recherche en Prevision Numerique 2015
! IGNORE
      implicit none                                                !InTf!
!
! ARGUMENTS
!  IN   my_id   "tile" ordinal along decomposition axis (0 -> npe-1)
!  IN   npe    number of "tiles" (PEs) along this dimension
!  IN   gmin,gmax
!              global index space along this dimension is gmin:gmax (usually 1:n)
!  OUT  lmini,lmaxi
!              this "tile" will cover index range lmini:lmaxi in global space
!  OUT  count(1:npe)
!              count(i) = number of points along this dimension for PE with ordinal I-1
!  OUT  offset(1:npe)
!              offset(i) = offset from gmin for PE with ordinal I-1
!  IN   relax  decomposition mode
!          0 : strict mode, all tiles but last one must have same dimension, 
!              last tile may be shorter but may not have zero dimension
!          1 : some tiles at end may be 1 shorter than tiles at beginning, 
!              zero size not allowed for these shorter tiles
!          2 : same as relax=1 but zero dimension tiles at end are allowed 
!              (useful only if more PEs than points)
!          3 : tiles with same length possibly followed by ONE shorter tile 
!              possibly followed by ONE or MORE zero size tiles
!
! Notes
!     this function is totally stand alone and could eventually be moved into the rmnlib library
!     mode 2 only makes sense when one has more PEs than points
!******
!*
      integer, intent(IN) ::  my_id, npe, gmin, gmax, relax         !InTf!
      integer, intent(OUT) :: lmini,lmaxi                           !InTf!
      integer, intent(OUT) :: count(npe),offset(npe)                !InTf!

      integer gtot
      integer val1, val2, i

      lmini = -1
      lmaxi = -1
      gtot = gmax - gmin + 1    ! number of points to be distributed

      val1 = (gtot + npe - 1)/npe           ! ceiling(gtot/npe)
      count = val1
      val2 = val1
      offset(1) = 0
      do i=2,npe
        count(i) = min(count(i),gtot-val2)
        offset(i) = offset(i-1) + count(i-1)
        val2 = val2 + count(i)
      enddo
!
      if(gtot < npe) then                   ! less points than PEs, there will be zero sized tiles at end and relax is 0 or 1
          if( relax < 2) goto 777           ! ERROR
          goto 666                          ! count is OK, go compute offset if relax >= 2
      end if
!
      if(relax == 3) goto 666               ! count is OK, go compute offset
!
      val2 = gtot - (npe-1)*val1            ! potential size of last "tile" in strict mode
      if (val2 <= 0) then                   ! in STRICT mode last "tile" would have a negative size
        if(relax == 0) goto 777             ! STRICT mode, and last "tile" would have a negative size, ERROR
        val1 = gtot/npe                     ! relaxed distribution rule, try mode 1 with val1 = floor(gtot/npe)
      endif
!
      count = val1                          ! [ceiling or floor](gtot/npe)
      if(val2 > 0) then                     ! strict mode will work, use it
         count(npe) = val2
      else                                  ! relaxed mode (1 or 2) (val2 <= 0 in mode 0 case already taken care of)
        do i=1,mod(gtot,npe)                ! add 1 to the size of some tiles at beginning to distribute leftovers
          count(i)=count(i)+1
        end do
      end if
!                                             we are now ready to compute offset using values in count
666   do i= 2, npe                          ! use count table to compute offsets from beginning (ORIGIN 0)
         offset(i) = offset(i-1) + count(i-1)
      enddo
!
      lmini = gmin + offset(my_id+1)             ! start of "tile" in global space
      lmaxi = min(gmax,lmini+count(my_id+1)-1)   ! end of "tile" in global space

      RPN_COMM_limit_2 = 0                  ! SUCCESS
      return

777   continue      ! something bad happened, print error message and return error status
      print *, 'RPN_COMM_limit_2: invalid decomposition'
      print *, 'Nb of elements =', gtot
      print *, 'Nb of pe =', npe
      print *, 'relax =', relax
      RPN_COMM_limit_2 = -1
      return
      end function RPN_COMM_limit_2                       !InTf!
!InTf!
!!integer function RPN_COMM_limit(my_id, npe, gmin, gmax, lmini,lmaxi,count, offset) !InTf!
!****f* RPN_COMM/RPN_COMM_limit
! SYNOPSIS
      integer function RPN_COMM_limit(my_id, npe, gmin, gmax, lmini,&
     &     lmaxi,count, offset)
! IGNORE
      implicit none                                        !InTf!
! ARGUMENTS
      integer, intent(IN) ::  my_id, npe, gmin, gmax       !InTf!
      integer, intent(OUT) :: lmini,lmaxi                  !InTf!
      integer, intent(OUT) :: count(npe),offset(npe)       !InTf!
! Notes
!     old function, calls newer RPN_COMM_limit_2 forcing STRICT decomposition mode
!     kept for compatibility with older versions of this library
!******
      external RPN_COMM_limit_2
      integer RPN_COMM_limit_2
      RPN_COMM_limit = &
     &     RPN_COMM_limit_2(my_id, npe, gmin, gmax, lmini,&
     &     lmaxi,count, offset,0) ! call with relax=0 (strict mode)
      return
      end function RPN_COMM_limit                          !InTf!
