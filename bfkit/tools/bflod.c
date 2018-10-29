/****************************************************************************\
  bflod.c - hex file uploader for bfkit

  Compile with : gcc -g -Wall -o bflod bflod.c

  This is free software in terms of the GNU General Public License as
  published by the Free Software Foundation. Absolutely no warranty.

  (C) 2008, ISI/ETH Zurich, strebel@isi.ee.ethz.ch
\****************************************************************************/

#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#define  DEVTT  "/dev/ttyUSB0"

char *help =
"\n(rev 1.1) usage: %s [options] [hexfile]\n\n"
"-d ..  use other device (default %s)\n"
"-b ..  set baud rate (default 1000000)\n"
"-t     start terminal (after program upload)\n"
"-e     provide local echo in terminal mode\n"
"-x     enable external SDRAM\n"
"-h     display this help text\n";

struct termios oldtio, newtio; /* old and new tty settings */
struct termios oldsio, newsio; /* old and new stdio settings */
char   *prgnam = "bflod";      /* name of this program */
char   *devnam = DEVTT;        /* name of serial device */
int    ifil = -1;              /* input file descriptor */
int    devd = -1;              /* output file descriptor */
int    tmod = 0;               /* true if tty settings modified */
int    smod = 0;               /* true if stdio settings modified */
int    baud = B1000000;        /* bits per second (constant from termios.h) */
int    bnum = 1000000;         /* bits per second (integer) */
int    xram = 0;               /* initialize external SDRAM */
int    term = 0;               /* terminal mode after file download */
int    echo = 0;               /* local echo */

void die(char *fmt, ...)       /* exit with an error message */
{ 
  va_list ap;
  if (ifil > 0) close(ifil);
  if (tmod) tcsetattr(devd, TCSANOW, &oldtio);
  if (smod) tcsetattr(0, TCSANOW, &oldsio);
  if (devd > 0) close(devd);
  if (!fmt[0]) exit(0);
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\n\n");
  exit(1);
}

void scanparams(int cnt, char **arg)
{ 
  int i = 0, j = 0;
  while (arg[0][j]) j++;
  while (j && arg[0][j-1] != '/') j--;
  prgnam = &arg[0][j];
  while (++i < cnt) {
    if (arg[i][j=0] == '-') {
      do {
        j++;
        switch (arg[i][j]) {
          case 'h': die(help, prgnam, DEVTT);
          case 't': term = 1; break;
          case 'x': xram = 1; break;
          case 'e': echo = 1; break;
          case 'b':
            if (arg[i][++j]) bnum = strtol(&arg[i][j], NULL, 0); 
            else if (++i < cnt) bnum = strtol(&arg[i][j=0], NULL, 0);
            if (bnum == 1200) baud = B1200;
            else if (bnum == 2400) baud = B2400;
            else if (bnum == 4800) baud = B4800;
            else if (bnum == 9600) baud = B9600;
            else if (bnum == 19200) baud = B19200;
            else if (bnum == 38400) baud = B38400;
            else if (bnum == 57600) baud = B57600;
            else if (bnum == 115200) baud = B115200;
            else if (bnum == 230400) baud = B230400;
            else if (bnum == 460800) baud = B460800;
            else if (bnum == 500000) baud = B500000;
            else if (bnum == 576000) baud =  B576000;
            else if (bnum == 921600) baud =  B921600;
            else if (bnum == 1000000) baud =  B1000000;
            else die("baud rate %d not supported", bnum);
            j = 0; break;
          case 'd':
            if (arg[i][++j]) devnam = &arg[i][j]; 
            else if (++i < cnt) devnam = &arg[i][0];
            else die("argument required for option -d");
            j = 0; break;
          default:
            if (arg[i][j] || j <= 1) die("unknown option -%c", arg[i][j]);
            j = 0; break;
        }
      } while (j);
    } else {
      if (ifil < 0) {
        ifil = open(arg[i], O_RDONLY);
        if (ifil < 0) die("cannot open infile %s", arg[i]);
      } else die("too many arguments");
    }
  }
  devd = open(devnam, O_RDWR | O_NOCTTY | O_NONBLOCK);
  if (devd < 0) die("cannot open %s", devnam);
}

void siginthandler(void)       /* restore setting at ^c */
{ 
  die("sigint");
}

void tty_init(int baud)
{ 
  if (!tmod && tcgetattr(devd, &oldtio) < 0) die("error saving tc");
  newtio.c_cflag = baud | CS8 | CLOCAL | CREAD;
  newtio.c_iflag = IGNPAR;
  newtio.c_oflag = 0;
  newtio.c_lflag = 0;
  newtio.c_cc[VMIN] = 0;
  newtio.c_cc[VTIME] = 0;
  if (tcsetattr(devd, TCSANOW, &newtio) < 0) die("error setting tc");
  tmod = 1;
  if (tcflush(devd, TCIOFLUSH) < 0) die("error flushing tty");
}

void sio_init(void)
{ 
  tcgetattr(0,&oldsio);
  tcgetattr(0,&newsio);
  newsio.c_lflag &= ~(ICANON | ECHO);
  newsio.c_cc[VMIN] = 0;
  newsio.c_cc[VTIME] = 0;
  if (tcsetattr(0, TCSANOW, &newsio) < 0) die("error setting stdio");
  smod = 1;
}

int write_available(int fd, int millis)
{ fd_set fdsout;
  struct timeval tv;
  FD_ZERO(&fdsout);
  FD_SET(fd, &fdsout);
  tv.tv_sec = millis / 1000;
  tv.tv_usec = (millis % 1000) * 1000;
  if (select(fd+1, NULL, &fdsout, NULL, &tv) <= 0) return 0;
  if (!(FD_ISSET(fd, &fdsout))) return 0;
  return 1;
}

int read_available(int fd, int millis)
{ 
  fd_set fdsin;
  struct timeval tv;
  FD_ZERO(&fdsin);
  FD_SET(fd, &fdsin);
  tv.tv_sec = millis / 1000;
  tv.tv_usec = (millis % 1000) * 1000;
  if (select(fd+1, &fdsin, NULL, NULL, &tv) <= 0) return 0;
  if (!(FD_ISSET(fd, &fdsin))) return 0;
  return 1;
}

unsigned char rxbyte(void)      /* receive a byte */
{ 
  unsigned char bt;
  if (!read_available(devd, 1000)) die("rx timeout");
  if (read(devd, &bt, 1) != 1) die("rx error");
  return bt;
}

void txbyte(unsigned char bt)   /* transmit a byte, clear input */
{ 
  if (!write_available(devd, 1000)) die("tx timeout");
  if (write(devd, &bt, 1) != 1) die("tx error");
}

void txhex(unsigned char bt)    /* send a byte as two hex chars to UART */
{ 
  unsigned char bb;
  bb = (bt >> 4) & 0x0F;
  if (bb < 0x0A) txbyte(bb + 48); else txbyte(bb + 55);
  bb = bt & 0x0F;
  if (bb < 0x0A) txbyte(bb + 48); else txbyte(bb + 55);
}

void txstr(char *str)           /* send a zero terminated string to UART */
{ while (*str) txbyte(*(str++));
}

void chgbaud(int bdiv)
{ while (read_available(devd, 0)) rxbyte();
  txbyte(':');
  txhex(0x00);
  txhex((bdiv >> 8) & 0xFF);
  txhex(bdiv & 0xFF);
  txhex(0x0F);
  txhex((0xF1 - ((bdiv >> 8) & 0xFF) - (bdiv & 0xFF)) & 0xFF);
  if (rxbyte() != '!') die("communication error");
}

int main(int argc, char **argv)
{ 
  unsigned char ch;
  
  scanparams(argc, (char **)&(argv[0]));
  signal(SIGINT, (void *) siginthandler);

  if (ifil > 0) {
    tty_init(B9600); // initial speed of bfkit
    chgbaud(6000000/bnum); // checks also presence of bfkit
    if (bnum != 9600) tty_init(baud);
    if (xram) chgbaud(0); // init SDRAM
    while (read(ifil, &ch, 1) == 1) {
      txbyte(ch);
      /* added byte delay since tcdrain() does not work */
      usleep(10000000/bnum);
    }
		usleep(100000);
  }
  
  if (term) {
    if (ifil <= 0) tty_init(baud);
    if (isatty(0)) sio_init(); else die("stdin not a console");
    printf("%s terminal: %s, %d/N/8/1, ", prgnam, devnam, bnum);
    printf("echo %s, ", echo ? "on" : "off");
    printf("exit if ESC received\r\n");
    fflush(stdout);
    while (1) {
      if (read_available(0, 0)) {
        if (read(0, &ch, 1) != 1) die("error reading stdin");
        if (echo) {
          printf("%c", ch);
          fflush(stdout);
        }
        txbyte(ch);
      }
      if (read_available(devd, 100)) {
        ch = rxbyte();
        if (ch == 27) break;
        printf("%c", ch);
        fflush(stdout);
      }
    }
    printf("\n");
  }
  
  die("");
  return 0;
}
