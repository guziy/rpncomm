#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <pthread.h>

/*
!  interfaces for use by Fortran code
  integer(C_INT) function c_rpn_comm_unlink(name) BIND(C,name='f_RPN_COMM_unlink')  ! interface to libc open function  !InTf!
    import :: C_PTR, C_INT                                           !InTf!
    type(C_PTR), value :: name                                       !InTf!
  end function c_rpn_comm_unlink                                     !InTf!

  integer(C_INT) function c_rpn_comm_open(name, mode) BIND(C,name='f_RPN_COMM_open')  ! interface to libc open function  !InTf!
    import :: C_INT, C_PTR                                           !InTf!
    integer(C_INT), intent(IN), value :: mode                        !InTf!
    type(C_PTR), value :: name                                       !InTf!
  end function c_rpn_comm_open                                       !InTf!

  integer(C_LONG_LONG) function rpn_comm_read(fd,buffer,nbytes) BIND(C,name='f_RPN_COMM_read')  ! interface to libc read function  !InTf!
    import :: C_INT, C_PTR, C_LONG_LONG                              !InTf!
    integer(C_INT), intent(IN), value :: fd                          !InTf!
    integer(C_LONG_LONG), intent(IN), value :: nbytes                !InTf!
    type(C_PTR), value :: buffer                                     !InTf!
  end function rpn_comm_read                                         !InTf!

  integer(C_LONG_LONG) function rpn_comm_write(fd,buffer,nbytes) BIND(C,name='f_RPN_COMM_write')  ! interface to libc write function  !InTf!
    import :: C_INT, C_PTR, C_LONG_LONG                              !InTf!
    integer(C_INT), intent(IN), value :: fd                          !InTf!
    integer(C_LONG_LONG), intent(IN), value :: nbytes                !InTf!
    type(C_PTR), value :: buffer                                     !InTf!
  end function rpn_comm_write                                        !InTf!

  integer(C_INT) function rpn_comm_close(fd) BIND(C,name='f_RPN_COMM_close')  ! interface to libc close function  !InTf!
    import :: C_INT                                                  !InTf!
    integer(C_INT), intent(IN), value :: fd                          !InTf!
  end function rpn_comm_close                                        !InTf!

  integer(C_LONG_LONG) function rpn_comm_file_size(fd) BIND(C,name='f_RPN_COMM_file_size')  ! via libc fstat function  !InTf!
    import :: C_INT, C_LONG_LONG                                     !InTf!
    integer(C_INT), intent(IN), value :: fd                          !InTf!
  end function rpn_comm_file_size                                    !InTf!

  integer(C_INT) function rpn_comm_wait(id) BIND(C,name='f_RPN_COMM_wait') ! wait for asynchronous copy with tag = id to terminate  !InTf!
    import :: C_INT                                                  !InTf!
    integer(C_INT), intent(IN), value :: id                          !InTf!
  end function rpn_comm_wait                                         !InTf!

  integer(C_INT) function rpn_comm_copy(fd1,fd2,asynchronous) BIND(C,name='f_RPN_COMM_copy')  ! C descriptor copy, possibly asunchronous  !InTf!
    import :: C_INT                                                  !InTf!
    integer(C_INT), intent(IN), value :: fd1,fd2,asynchronous        !InTf!
  end function rpn_comm_copy                                         !InTf!
*/

int f_RPN_COMM_unlink(const char *pathname)  /* libc unlink interface for Fortran */
{
  return ( unlink(pathname) ) ;
}

int f_RPN_COMM_open(const char *pathname, int rwflag)  /* libc open interface for Fortran */
{
  int flags = O_RDONLY ;
  int mode = 0777;

  if(rwflag != 0) flags = O_RDWR + O_CREAT ;
  return ( open(pathname, flags, mode) ) ;
}

long long f_RPN_COMM_read(int fd, void *buf, long long Count)  /* libc read interface for Fortran */
{
  size_t count = Count;
  return( read(fd, buf, count) ) ;
}

long long f_RPN_COMM_write(int fd, void *buf, long long Count)  /* libc write interface for Fortran */
{
  size_t count = Count;
  return( write(fd, buf, count) ) ;
}

int f_RPN_COMM_close(int fd)  /* libc close interface for Fortran */
{
  return(close(fd));
}

long long f_RPN_COMM_file_size(int fd)  /* libc close interface for Fortran */
{
  struct stat fstatus;
  int status = fstat(fd, &fstatus);
  return(fstatus.st_size);
}

#define BUFSIZE 1024*1024*4
#define MAX_SIMULTANEOUS_COPIES 1

static pthread_t my_thread[MAX_SIMULTANEOUS_COPIES];   /* asynchronous copy thread id (one for now, more eventually) */
static int *thread_args[MAX_SIMULTANEOUS_COPIES];      /* argument list for above */
static int thread_active = 0;                          /* number of active threads (for now, 0 or 1) */
static int debug = 0;

static int f_RPN_COMM_copy_1(int fd1, int fd2)  /* copy fd1 into fd2 (synchronous copy code) */
{
  char buffer[BUFSIZE];
  int nbytes;
  int written, towrite;

  if(debug>=10) printf("copy 1: synchronous copy of fd %d onto fd %d\n",fd1,fd2);
  while( (nbytes = read(fd1,buffer,BUFSIZE)) > 0 ) {  /* loop until nothing to read */
    towrite = nbytes ;
    while(1) {                  /* loop until all bytes read are written */
      written = write(fd2,buffer,towrite);
      if(written <= 0) break ;  /* write problem */
      towrite -= written;
      if(towrite == 0) break ;  /* everything written */
    }
    if(towrite != 0) break;  /* short write, error */
  }
  if(debug>=10) printf("synchronous copy done,\n");
  if(towrite != 0) return(-1);  /* short write, return an error */
  return (close(fd1) + close(fd2));  /*return compound status of close */
}

static void *f_RPN_COMM_copy_2(void *FDS)  /* copy fds[0] onto fds[1], called by pthread_create, calls f_RPN_COMM_copy_1 */
{
  int *fds = (int *) FDS;
  int status;
  if(debug>=10) printf("start of thread, copying fd %d onto fd %d\n",fds[0],fds[1]);
  status = f_RPN_COMM_copy_1(fds[0],fds[1]);
  if(debug>=10) printf("thread copy done, status=%d\n",status);
  if(status == 0) return (NULL);
  return ( &thread_active );  /* return non null pointer upon failure */
}

int f_RPN_COMM_wait(int id)  /* wait for asynchronous copy to terminate (Fortran interface) */
{
  void *retval;
  int status;

  if(id != 1) return(-1);              /* only one thread supported for the time being */
  if(thread_active == 0) return(-1);   /* nothing to wait for, return error */
  status = pthread_join(my_thread[0],&retval);  /* wait for thread to terminate */
  if(debug>=1) printf("INFO: copy thread %d finished execution with status %d\n",id,status);
  thread_active = 0;
  if(retval == NULL) return(0);        /* null return from thread, OK */
  return (-1);
}
 
int f_RPN_COMM_copy(int fd1, int fd2, int async)  /* Fortran interface to possibly asynchronous file to file copy */
{
  if(fd1==-1 && fd2==-1 ) { debug = async ; return(0); };
  if(async == 0) {                      /* synchronous copy */
    if(debug>=1) printf("f_RPN_COMM_copy: synchronous copy of fd %d onto fd %d\n",fd1,fd2);
    return ( f_RPN_COMM_copy_1(fd1,fd2) );
  } else {                              /* asynchronous copy */
    if( thread_active ) return (-1);    /* a copy thread is already active, OOPS */
    thread_args[0] = (int *) malloc(2*sizeof(int));
    thread_active = 1;
    if(debug>=1) printf("f_RPN_COMM_copy: starting asynchronous copy of fd %d onto fd %d, copy thread %d\n",fd1,fd2,thread_active);
    thread_args[0][0] = fd1;                       /* build thread argument list */
    thread_args[0][1] = fd2;
    if ( 0 == pthread_create(&my_thread[0], NULL, f_RPN_COMM_copy_2, (void *)thread_args[0]) ) return (thread_active) ;
    return (-1);
  }
}
