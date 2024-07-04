
user/_test_2:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int
main(int argc, char *argv[]) {
   0:	7175                	add	sp,sp,-144
   2:	e506                	sd	ra,136(sp)
   4:	e122                	sd	s0,128(sp)
   6:	fca6                	sd	s1,120(sp)
   8:	f8ca                	sd	s2,112(sp)
   a:	0900                	add	s0,sp,144
    int x1 = getreadcount();
   c:	00000097          	auipc	ra,0x0
  10:	39a080e7          	jalr	922(ra) # 3a6 <getreadcount>
  14:	892a                	mv	s2,a0

    int rc = fork();
  16:	00000097          	auipc	ra,0x0
  1a:	2e0080e7          	jalr	736(ra) # 2f6 <fork>
  1e:	fca42e23          	sw	a0,-36(s0)
  22:	64e1                	lui	s1,0x18
  24:	6a048493          	add	s1,s1,1696 # 186a0 <base+0x17690>

    int total = 0;
    int i;
    for (i = 0; i < 100000; i++) {
        char buf[100];
        (void) read(4, buf, 1);
  28:	4605                	li	a2,1
  2a:	f7840593          	add	a1,s0,-136
  2e:	4511                	li	a0,4
  30:	00000097          	auipc	ra,0x0
  34:	2e6080e7          	jalr	742(ra) # 316 <read>
    for (i = 0; i < 100000; i++) {
  38:	34fd                	addw	s1,s1,-1
  3a:	f4fd                	bnez	s1,28 <main+0x28>
    }
    // https://wiki.osdev.org/Shutdown
    // (void) shutdown();

    if (rc > 0) {
  3c:	fdc42783          	lw	a5,-36(s0)
  40:	00f04763          	bgtz	a5,4e <main+0x4e>
        (void) wait(&rc);
        int x2 = getreadcount();
        total += (x2 - x1);
        printf("XV6_TEST_OUTPUT %d\n", total);
    }
    exit(0);
  44:	4501                	li	a0,0
  46:	00000097          	auipc	ra,0x0
  4a:	2b8080e7          	jalr	696(ra) # 2fe <exit>
        (void) wait(&rc);
  4e:	fdc40513          	add	a0,s0,-36
  52:	00000097          	auipc	ra,0x0
  56:	2b4080e7          	jalr	692(ra) # 306 <wait>
        int x2 = getreadcount();
  5a:	00000097          	auipc	ra,0x0
  5e:	34c080e7          	jalr	844(ra) # 3a6 <getreadcount>
        printf("XV6_TEST_OUTPUT %d\n", total);
  62:	412505bb          	subw	a1,a0,s2
  66:	00000517          	auipc	a0,0x0
  6a:	7ba50513          	add	a0,a0,1978 # 820 <malloc+0xea>
  6e:	00000097          	auipc	ra,0x0
  72:	610080e7          	jalr	1552(ra) # 67e <printf>
  76:	b7f9                	j	44 <main+0x44>

0000000000000078 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  78:	1141                	add	sp,sp,-16
  7a:	e406                	sd	ra,8(sp)
  7c:	e022                	sd	s0,0(sp)
  7e:	0800                	add	s0,sp,16
  extern int main();
  main();
  80:	00000097          	auipc	ra,0x0
  84:	f80080e7          	jalr	-128(ra) # 0 <main>
  exit(0);
  88:	4501                	li	a0,0
  8a:	00000097          	auipc	ra,0x0
  8e:	274080e7          	jalr	628(ra) # 2fe <exit>

0000000000000092 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  92:	1141                	add	sp,sp,-16
  94:	e422                	sd	s0,8(sp)
  96:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  98:	87aa                	mv	a5,a0
  9a:	0585                	add	a1,a1,1
  9c:	0785                	add	a5,a5,1
  9e:	fff5c703          	lbu	a4,-1(a1)
  a2:	fee78fa3          	sb	a4,-1(a5)
  a6:	fb75                	bnez	a4,9a <strcpy+0x8>
    ;
  return os;
}
  a8:	6422                	ld	s0,8(sp)
  aa:	0141                	add	sp,sp,16
  ac:	8082                	ret

00000000000000ae <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ae:	1141                	add	sp,sp,-16
  b0:	e422                	sd	s0,8(sp)
  b2:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  b4:	00054783          	lbu	a5,0(a0)
  b8:	cb91                	beqz	a5,cc <strcmp+0x1e>
  ba:	0005c703          	lbu	a4,0(a1)
  be:	00f71763          	bne	a4,a5,cc <strcmp+0x1e>
    p++, q++;
  c2:	0505                	add	a0,a0,1
  c4:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	fbe5                	bnez	a5,ba <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  cc:	0005c503          	lbu	a0,0(a1)
}
  d0:	40a7853b          	subw	a0,a5,a0
  d4:	6422                	ld	s0,8(sp)
  d6:	0141                	add	sp,sp,16
  d8:	8082                	ret

00000000000000da <strlen>:

uint
strlen(const char *s)
{
  da:	1141                	add	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  e0:	00054783          	lbu	a5,0(a0)
  e4:	cf91                	beqz	a5,100 <strlen+0x26>
  e6:	0505                	add	a0,a0,1
  e8:	87aa                	mv	a5,a0
  ea:	86be                	mv	a3,a5
  ec:	0785                	add	a5,a5,1
  ee:	fff7c703          	lbu	a4,-1(a5)
  f2:	ff65                	bnez	a4,ea <strlen+0x10>
  f4:	40a6853b          	subw	a0,a3,a0
  f8:	2505                	addw	a0,a0,1
    ;
  return n;
}
  fa:	6422                	ld	s0,8(sp)
  fc:	0141                	add	sp,sp,16
  fe:	8082                	ret
  for(n = 0; s[n]; n++)
 100:	4501                	li	a0,0
 102:	bfe5                	j	fa <strlen+0x20>

0000000000000104 <memset>:

void*
memset(void *dst, int c, uint n)
{
 104:	1141                	add	sp,sp,-16
 106:	e422                	sd	s0,8(sp)
 108:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 10a:	ca19                	beqz	a2,120 <memset+0x1c>
 10c:	87aa                	mv	a5,a0
 10e:	1602                	sll	a2,a2,0x20
 110:	9201                	srl	a2,a2,0x20
 112:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 116:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 11a:	0785                	add	a5,a5,1
 11c:	fee79de3          	bne	a5,a4,116 <memset+0x12>
  }
  return dst;
}
 120:	6422                	ld	s0,8(sp)
 122:	0141                	add	sp,sp,16
 124:	8082                	ret

0000000000000126 <strchr>:

char*
strchr(const char *s, char c)
{
 126:	1141                	add	sp,sp,-16
 128:	e422                	sd	s0,8(sp)
 12a:	0800                	add	s0,sp,16
  for(; *s; s++)
 12c:	00054783          	lbu	a5,0(a0)
 130:	cb99                	beqz	a5,146 <strchr+0x20>
    if(*s == c)
 132:	00f58763          	beq	a1,a5,140 <strchr+0x1a>
  for(; *s; s++)
 136:	0505                	add	a0,a0,1
 138:	00054783          	lbu	a5,0(a0)
 13c:	fbfd                	bnez	a5,132 <strchr+0xc>
      return (char*)s;
  return 0;
 13e:	4501                	li	a0,0
}
 140:	6422                	ld	s0,8(sp)
 142:	0141                	add	sp,sp,16
 144:	8082                	ret
  return 0;
 146:	4501                	li	a0,0
 148:	bfe5                	j	140 <strchr+0x1a>

000000000000014a <gets>:

char*
gets(char *buf, int max)
{
 14a:	711d                	add	sp,sp,-96
 14c:	ec86                	sd	ra,88(sp)
 14e:	e8a2                	sd	s0,80(sp)
 150:	e4a6                	sd	s1,72(sp)
 152:	e0ca                	sd	s2,64(sp)
 154:	fc4e                	sd	s3,56(sp)
 156:	f852                	sd	s4,48(sp)
 158:	f456                	sd	s5,40(sp)
 15a:	f05a                	sd	s6,32(sp)
 15c:	ec5e                	sd	s7,24(sp)
 15e:	1080                	add	s0,sp,96
 160:	8baa                	mv	s7,a0
 162:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 164:	892a                	mv	s2,a0
 166:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 168:	4aa9                	li	s5,10
 16a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 16c:	89a6                	mv	s3,s1
 16e:	2485                	addw	s1,s1,1
 170:	0344d863          	bge	s1,s4,1a0 <gets+0x56>
    cc = read(0, &c, 1);
 174:	4605                	li	a2,1
 176:	faf40593          	add	a1,s0,-81
 17a:	4501                	li	a0,0
 17c:	00000097          	auipc	ra,0x0
 180:	19a080e7          	jalr	410(ra) # 316 <read>
    if(cc < 1)
 184:	00a05e63          	blez	a0,1a0 <gets+0x56>
    buf[i++] = c;
 188:	faf44783          	lbu	a5,-81(s0)
 18c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 190:	01578763          	beq	a5,s5,19e <gets+0x54>
 194:	0905                	add	s2,s2,1
 196:	fd679be3          	bne	a5,s6,16c <gets+0x22>
  for(i=0; i+1 < max; ){
 19a:	89a6                	mv	s3,s1
 19c:	a011                	j	1a0 <gets+0x56>
 19e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1a0:	99de                	add	s3,s3,s7
 1a2:	00098023          	sb	zero,0(s3)
  return buf;
}
 1a6:	855e                	mv	a0,s7
 1a8:	60e6                	ld	ra,88(sp)
 1aa:	6446                	ld	s0,80(sp)
 1ac:	64a6                	ld	s1,72(sp)
 1ae:	6906                	ld	s2,64(sp)
 1b0:	79e2                	ld	s3,56(sp)
 1b2:	7a42                	ld	s4,48(sp)
 1b4:	7aa2                	ld	s5,40(sp)
 1b6:	7b02                	ld	s6,32(sp)
 1b8:	6be2                	ld	s7,24(sp)
 1ba:	6125                	add	sp,sp,96
 1bc:	8082                	ret

00000000000001be <stat>:

int
stat(const char *n, struct stat *st)
{
 1be:	1101                	add	sp,sp,-32
 1c0:	ec06                	sd	ra,24(sp)
 1c2:	e822                	sd	s0,16(sp)
 1c4:	e426                	sd	s1,8(sp)
 1c6:	e04a                	sd	s2,0(sp)
 1c8:	1000                	add	s0,sp,32
 1ca:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1cc:	4581                	li	a1,0
 1ce:	00000097          	auipc	ra,0x0
 1d2:	170080e7          	jalr	368(ra) # 33e <open>
  if(fd < 0)
 1d6:	02054563          	bltz	a0,200 <stat+0x42>
 1da:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1dc:	85ca                	mv	a1,s2
 1de:	00000097          	auipc	ra,0x0
 1e2:	178080e7          	jalr	376(ra) # 356 <fstat>
 1e6:	892a                	mv	s2,a0
  close(fd);
 1e8:	8526                	mv	a0,s1
 1ea:	00000097          	auipc	ra,0x0
 1ee:	13c080e7          	jalr	316(ra) # 326 <close>
  return r;
}
 1f2:	854a                	mv	a0,s2
 1f4:	60e2                	ld	ra,24(sp)
 1f6:	6442                	ld	s0,16(sp)
 1f8:	64a2                	ld	s1,8(sp)
 1fa:	6902                	ld	s2,0(sp)
 1fc:	6105                	add	sp,sp,32
 1fe:	8082                	ret
    return -1;
 200:	597d                	li	s2,-1
 202:	bfc5                	j	1f2 <stat+0x34>

0000000000000204 <atoi>:

int
atoi(const char *s)
{
 204:	1141                	add	sp,sp,-16
 206:	e422                	sd	s0,8(sp)
 208:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 20a:	00054683          	lbu	a3,0(a0)
 20e:	fd06879b          	addw	a5,a3,-48
 212:	0ff7f793          	zext.b	a5,a5
 216:	4625                	li	a2,9
 218:	02f66863          	bltu	a2,a5,248 <atoi+0x44>
 21c:	872a                	mv	a4,a0
  n = 0;
 21e:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 220:	0705                	add	a4,a4,1
 222:	0025179b          	sllw	a5,a0,0x2
 226:	9fa9                	addw	a5,a5,a0
 228:	0017979b          	sllw	a5,a5,0x1
 22c:	9fb5                	addw	a5,a5,a3
 22e:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 232:	00074683          	lbu	a3,0(a4)
 236:	fd06879b          	addw	a5,a3,-48
 23a:	0ff7f793          	zext.b	a5,a5
 23e:	fef671e3          	bgeu	a2,a5,220 <atoi+0x1c>
  return n;
}
 242:	6422                	ld	s0,8(sp)
 244:	0141                	add	sp,sp,16
 246:	8082                	ret
  n = 0;
 248:	4501                	li	a0,0
 24a:	bfe5                	j	242 <atoi+0x3e>

000000000000024c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 24c:	1141                	add	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 252:	02b57463          	bgeu	a0,a1,27a <memmove+0x2e>
    while(n-- > 0)
 256:	00c05f63          	blez	a2,274 <memmove+0x28>
 25a:	1602                	sll	a2,a2,0x20
 25c:	9201                	srl	a2,a2,0x20
 25e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 262:	872a                	mv	a4,a0
      *dst++ = *src++;
 264:	0585                	add	a1,a1,1
 266:	0705                	add	a4,a4,1
 268:	fff5c683          	lbu	a3,-1(a1)
 26c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 270:	fee79ae3          	bne	a5,a4,264 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 274:	6422                	ld	s0,8(sp)
 276:	0141                	add	sp,sp,16
 278:	8082                	ret
    dst += n;
 27a:	00c50733          	add	a4,a0,a2
    src += n;
 27e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 280:	fec05ae3          	blez	a2,274 <memmove+0x28>
 284:	fff6079b          	addw	a5,a2,-1
 288:	1782                	sll	a5,a5,0x20
 28a:	9381                	srl	a5,a5,0x20
 28c:	fff7c793          	not	a5,a5
 290:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 292:	15fd                	add	a1,a1,-1
 294:	177d                	add	a4,a4,-1
 296:	0005c683          	lbu	a3,0(a1)
 29a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 29e:	fee79ae3          	bne	a5,a4,292 <memmove+0x46>
 2a2:	bfc9                	j	274 <memmove+0x28>

00000000000002a4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2a4:	1141                	add	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2aa:	ca05                	beqz	a2,2da <memcmp+0x36>
 2ac:	fff6069b          	addw	a3,a2,-1
 2b0:	1682                	sll	a3,a3,0x20
 2b2:	9281                	srl	a3,a3,0x20
 2b4:	0685                	add	a3,a3,1
 2b6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2b8:	00054783          	lbu	a5,0(a0)
 2bc:	0005c703          	lbu	a4,0(a1)
 2c0:	00e79863          	bne	a5,a4,2d0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2c4:	0505                	add	a0,a0,1
    p2++;
 2c6:	0585                	add	a1,a1,1
  while (n-- > 0) {
 2c8:	fed518e3          	bne	a0,a3,2b8 <memcmp+0x14>
  }
  return 0;
 2cc:	4501                	li	a0,0
 2ce:	a019                	j	2d4 <memcmp+0x30>
      return *p1 - *p2;
 2d0:	40e7853b          	subw	a0,a5,a4
}
 2d4:	6422                	ld	s0,8(sp)
 2d6:	0141                	add	sp,sp,16
 2d8:	8082                	ret
  return 0;
 2da:	4501                	li	a0,0
 2dc:	bfe5                	j	2d4 <memcmp+0x30>

00000000000002de <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2de:	1141                	add	sp,sp,-16
 2e0:	e406                	sd	ra,8(sp)
 2e2:	e022                	sd	s0,0(sp)
 2e4:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2e6:	00000097          	auipc	ra,0x0
 2ea:	f66080e7          	jalr	-154(ra) # 24c <memmove>
}
 2ee:	60a2                	ld	ra,8(sp)
 2f0:	6402                	ld	s0,0(sp)
 2f2:	0141                	add	sp,sp,16
 2f4:	8082                	ret

00000000000002f6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2f6:	4885                	li	a7,1
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <exit>:
.global exit
exit:
 li a7, SYS_exit
 2fe:	4889                	li	a7,2
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <wait>:
.global wait
wait:
 li a7, SYS_wait
 306:	488d                	li	a7,3
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 30e:	4891                	li	a7,4
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <read>:
.global read
read:
 li a7, SYS_read
 316:	4895                	li	a7,5
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <write>:
.global write
write:
 li a7, SYS_write
 31e:	48c1                	li	a7,16
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <close>:
.global close
close:
 li a7, SYS_close
 326:	48d5                	li	a7,21
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <kill>:
.global kill
kill:
 li a7, SYS_kill
 32e:	4899                	li	a7,6
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <exec>:
.global exec
exec:
 li a7, SYS_exec
 336:	489d                	li	a7,7
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <open>:
.global open
open:
 li a7, SYS_open
 33e:	48bd                	li	a7,15
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 346:	48c5                	li	a7,17
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 34e:	48c9                	li	a7,18
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 356:	48a1                	li	a7,8
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <link>:
.global link
link:
 li a7, SYS_link
 35e:	48cd                	li	a7,19
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 366:	48d1                	li	a7,20
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 36e:	48a5                	li	a7,9
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <dup>:
.global dup
dup:
 li a7, SYS_dup
 376:	48a9                	li	a7,10
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 37e:	48ad                	li	a7,11
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 386:	48b1                	li	a7,12
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 38e:	48b5                	li	a7,13
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 396:	48b9                	li	a7,14
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 39e:	48d9                	li	a7,22
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 3a6:	48dd                	li	a7,23
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3ae:	48e1                	li	a7,24
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3b6:	1101                	add	sp,sp,-32
 3b8:	ec06                	sd	ra,24(sp)
 3ba:	e822                	sd	s0,16(sp)
 3bc:	1000                	add	s0,sp,32
 3be:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3c2:	4605                	li	a2,1
 3c4:	fef40593          	add	a1,s0,-17
 3c8:	00000097          	auipc	ra,0x0
 3cc:	f56080e7          	jalr	-170(ra) # 31e <write>
}
 3d0:	60e2                	ld	ra,24(sp)
 3d2:	6442                	ld	s0,16(sp)
 3d4:	6105                	add	sp,sp,32
 3d6:	8082                	ret

00000000000003d8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3d8:	7139                	add	sp,sp,-64
 3da:	fc06                	sd	ra,56(sp)
 3dc:	f822                	sd	s0,48(sp)
 3de:	f426                	sd	s1,40(sp)
 3e0:	f04a                	sd	s2,32(sp)
 3e2:	ec4e                	sd	s3,24(sp)
 3e4:	0080                	add	s0,sp,64
 3e6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3e8:	c299                	beqz	a3,3ee <printint+0x16>
 3ea:	0805c963          	bltz	a1,47c <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3ee:	2581                	sext.w	a1,a1
  neg = 0;
 3f0:	4881                	li	a7,0
 3f2:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 3f6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3f8:	2601                	sext.w	a2,a2
 3fa:	00000517          	auipc	a0,0x0
 3fe:	49e50513          	add	a0,a0,1182 # 898 <digits>
 402:	883a                	mv	a6,a4
 404:	2705                	addw	a4,a4,1
 406:	02c5f7bb          	remuw	a5,a1,a2
 40a:	1782                	sll	a5,a5,0x20
 40c:	9381                	srl	a5,a5,0x20
 40e:	97aa                	add	a5,a5,a0
 410:	0007c783          	lbu	a5,0(a5)
 414:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 418:	0005879b          	sext.w	a5,a1
 41c:	02c5d5bb          	divuw	a1,a1,a2
 420:	0685                	add	a3,a3,1
 422:	fec7f0e3          	bgeu	a5,a2,402 <printint+0x2a>
  if(neg)
 426:	00088c63          	beqz	a7,43e <printint+0x66>
    buf[i++] = '-';
 42a:	fd070793          	add	a5,a4,-48
 42e:	00878733          	add	a4,a5,s0
 432:	02d00793          	li	a5,45
 436:	fef70823          	sb	a5,-16(a4)
 43a:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 43e:	02e05863          	blez	a4,46e <printint+0x96>
 442:	fc040793          	add	a5,s0,-64
 446:	00e78933          	add	s2,a5,a4
 44a:	fff78993          	add	s3,a5,-1
 44e:	99ba                	add	s3,s3,a4
 450:	377d                	addw	a4,a4,-1
 452:	1702                	sll	a4,a4,0x20
 454:	9301                	srl	a4,a4,0x20
 456:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 45a:	fff94583          	lbu	a1,-1(s2)
 45e:	8526                	mv	a0,s1
 460:	00000097          	auipc	ra,0x0
 464:	f56080e7          	jalr	-170(ra) # 3b6 <putc>
  while(--i >= 0)
 468:	197d                	add	s2,s2,-1
 46a:	ff3918e3          	bne	s2,s3,45a <printint+0x82>
}
 46e:	70e2                	ld	ra,56(sp)
 470:	7442                	ld	s0,48(sp)
 472:	74a2                	ld	s1,40(sp)
 474:	7902                	ld	s2,32(sp)
 476:	69e2                	ld	s3,24(sp)
 478:	6121                	add	sp,sp,64
 47a:	8082                	ret
    x = -xx;
 47c:	40b005bb          	negw	a1,a1
    neg = 1;
 480:	4885                	li	a7,1
    x = -xx;
 482:	bf85                	j	3f2 <printint+0x1a>

0000000000000484 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 484:	715d                	add	sp,sp,-80
 486:	e486                	sd	ra,72(sp)
 488:	e0a2                	sd	s0,64(sp)
 48a:	fc26                	sd	s1,56(sp)
 48c:	f84a                	sd	s2,48(sp)
 48e:	f44e                	sd	s3,40(sp)
 490:	f052                	sd	s4,32(sp)
 492:	ec56                	sd	s5,24(sp)
 494:	e85a                	sd	s6,16(sp)
 496:	e45e                	sd	s7,8(sp)
 498:	e062                	sd	s8,0(sp)
 49a:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 49c:	0005c903          	lbu	s2,0(a1)
 4a0:	18090c63          	beqz	s2,638 <vprintf+0x1b4>
 4a4:	8aaa                	mv	s5,a0
 4a6:	8bb2                	mv	s7,a2
 4a8:	00158493          	add	s1,a1,1
  state = 0;
 4ac:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4ae:	02500a13          	li	s4,37
 4b2:	4b55                	li	s6,21
 4b4:	a839                	j	4d2 <vprintf+0x4e>
        putc(fd, c);
 4b6:	85ca                	mv	a1,s2
 4b8:	8556                	mv	a0,s5
 4ba:	00000097          	auipc	ra,0x0
 4be:	efc080e7          	jalr	-260(ra) # 3b6 <putc>
 4c2:	a019                	j	4c8 <vprintf+0x44>
    } else if(state == '%'){
 4c4:	01498d63          	beq	s3,s4,4de <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 4c8:	0485                	add	s1,s1,1
 4ca:	fff4c903          	lbu	s2,-1(s1)
 4ce:	16090563          	beqz	s2,638 <vprintf+0x1b4>
    if(state == 0){
 4d2:	fe0999e3          	bnez	s3,4c4 <vprintf+0x40>
      if(c == '%'){
 4d6:	ff4910e3          	bne	s2,s4,4b6 <vprintf+0x32>
        state = '%';
 4da:	89d2                	mv	s3,s4
 4dc:	b7f5                	j	4c8 <vprintf+0x44>
      if(c == 'd'){
 4de:	13490263          	beq	s2,s4,602 <vprintf+0x17e>
 4e2:	f9d9079b          	addw	a5,s2,-99
 4e6:	0ff7f793          	zext.b	a5,a5
 4ea:	12fb6563          	bltu	s6,a5,614 <vprintf+0x190>
 4ee:	f9d9079b          	addw	a5,s2,-99
 4f2:	0ff7f713          	zext.b	a4,a5
 4f6:	10eb6f63          	bltu	s6,a4,614 <vprintf+0x190>
 4fa:	00271793          	sll	a5,a4,0x2
 4fe:	00000717          	auipc	a4,0x0
 502:	34270713          	add	a4,a4,834 # 840 <malloc+0x10a>
 506:	97ba                	add	a5,a5,a4
 508:	439c                	lw	a5,0(a5)
 50a:	97ba                	add	a5,a5,a4
 50c:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 50e:	008b8913          	add	s2,s7,8
 512:	4685                	li	a3,1
 514:	4629                	li	a2,10
 516:	000ba583          	lw	a1,0(s7)
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	ebc080e7          	jalr	-324(ra) # 3d8 <printint>
 524:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 526:	4981                	li	s3,0
 528:	b745                	j	4c8 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 52a:	008b8913          	add	s2,s7,8
 52e:	4681                	li	a3,0
 530:	4629                	li	a2,10
 532:	000ba583          	lw	a1,0(s7)
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	ea0080e7          	jalr	-352(ra) # 3d8 <printint>
 540:	8bca                	mv	s7,s2
      state = 0;
 542:	4981                	li	s3,0
 544:	b751                	j	4c8 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 546:	008b8913          	add	s2,s7,8
 54a:	4681                	li	a3,0
 54c:	4641                	li	a2,16
 54e:	000ba583          	lw	a1,0(s7)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e84080e7          	jalr	-380(ra) # 3d8 <printint>
 55c:	8bca                	mv	s7,s2
      state = 0;
 55e:	4981                	li	s3,0
 560:	b7a5                	j	4c8 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 562:	008b8c13          	add	s8,s7,8
 566:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 56a:	03000593          	li	a1,48
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e46080e7          	jalr	-442(ra) # 3b6 <putc>
  putc(fd, 'x');
 578:	07800593          	li	a1,120
 57c:	8556                	mv	a0,s5
 57e:	00000097          	auipc	ra,0x0
 582:	e38080e7          	jalr	-456(ra) # 3b6 <putc>
 586:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 588:	00000b97          	auipc	s7,0x0
 58c:	310b8b93          	add	s7,s7,784 # 898 <digits>
 590:	03c9d793          	srl	a5,s3,0x3c
 594:	97de                	add	a5,a5,s7
 596:	0007c583          	lbu	a1,0(a5)
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	e1a080e7          	jalr	-486(ra) # 3b6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5a4:	0992                	sll	s3,s3,0x4
 5a6:	397d                	addw	s2,s2,-1
 5a8:	fe0914e3          	bnez	s2,590 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5ac:	8be2                	mv	s7,s8
      state = 0;
 5ae:	4981                	li	s3,0
 5b0:	bf21                	j	4c8 <vprintf+0x44>
        s = va_arg(ap, char*);
 5b2:	008b8993          	add	s3,s7,8
 5b6:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5ba:	02090163          	beqz	s2,5dc <vprintf+0x158>
        while(*s != 0){
 5be:	00094583          	lbu	a1,0(s2)
 5c2:	c9a5                	beqz	a1,632 <vprintf+0x1ae>
          putc(fd, *s);
 5c4:	8556                	mv	a0,s5
 5c6:	00000097          	auipc	ra,0x0
 5ca:	df0080e7          	jalr	-528(ra) # 3b6 <putc>
          s++;
 5ce:	0905                	add	s2,s2,1
        while(*s != 0){
 5d0:	00094583          	lbu	a1,0(s2)
 5d4:	f9e5                	bnez	a1,5c4 <vprintf+0x140>
        s = va_arg(ap, char*);
 5d6:	8bce                	mv	s7,s3
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	b5fd                	j	4c8 <vprintf+0x44>
          s = "(null)";
 5dc:	00000917          	auipc	s2,0x0
 5e0:	25c90913          	add	s2,s2,604 # 838 <malloc+0x102>
        while(*s != 0){
 5e4:	02800593          	li	a1,40
 5e8:	bff1                	j	5c4 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 5ea:	008b8913          	add	s2,s7,8
 5ee:	000bc583          	lbu	a1,0(s7)
 5f2:	8556                	mv	a0,s5
 5f4:	00000097          	auipc	ra,0x0
 5f8:	dc2080e7          	jalr	-574(ra) # 3b6 <putc>
 5fc:	8bca                	mv	s7,s2
      state = 0;
 5fe:	4981                	li	s3,0
 600:	b5e1                	j	4c8 <vprintf+0x44>
        putc(fd, c);
 602:	02500593          	li	a1,37
 606:	8556                	mv	a0,s5
 608:	00000097          	auipc	ra,0x0
 60c:	dae080e7          	jalr	-594(ra) # 3b6 <putc>
      state = 0;
 610:	4981                	li	s3,0
 612:	bd5d                	j	4c8 <vprintf+0x44>
        putc(fd, '%');
 614:	02500593          	li	a1,37
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	d9c080e7          	jalr	-612(ra) # 3b6 <putc>
        putc(fd, c);
 622:	85ca                	mv	a1,s2
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	d90080e7          	jalr	-624(ra) # 3b6 <putc>
      state = 0;
 62e:	4981                	li	s3,0
 630:	bd61                	j	4c8 <vprintf+0x44>
        s = va_arg(ap, char*);
 632:	8bce                	mv	s7,s3
      state = 0;
 634:	4981                	li	s3,0
 636:	bd49                	j	4c8 <vprintf+0x44>
    }
  }
}
 638:	60a6                	ld	ra,72(sp)
 63a:	6406                	ld	s0,64(sp)
 63c:	74e2                	ld	s1,56(sp)
 63e:	7942                	ld	s2,48(sp)
 640:	79a2                	ld	s3,40(sp)
 642:	7a02                	ld	s4,32(sp)
 644:	6ae2                	ld	s5,24(sp)
 646:	6b42                	ld	s6,16(sp)
 648:	6ba2                	ld	s7,8(sp)
 64a:	6c02                	ld	s8,0(sp)
 64c:	6161                	add	sp,sp,80
 64e:	8082                	ret

0000000000000650 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 650:	715d                	add	sp,sp,-80
 652:	ec06                	sd	ra,24(sp)
 654:	e822                	sd	s0,16(sp)
 656:	1000                	add	s0,sp,32
 658:	e010                	sd	a2,0(s0)
 65a:	e414                	sd	a3,8(s0)
 65c:	e818                	sd	a4,16(s0)
 65e:	ec1c                	sd	a5,24(s0)
 660:	03043023          	sd	a6,32(s0)
 664:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 668:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 66c:	8622                	mv	a2,s0
 66e:	00000097          	auipc	ra,0x0
 672:	e16080e7          	jalr	-490(ra) # 484 <vprintf>
}
 676:	60e2                	ld	ra,24(sp)
 678:	6442                	ld	s0,16(sp)
 67a:	6161                	add	sp,sp,80
 67c:	8082                	ret

000000000000067e <printf>:

void
printf(const char *fmt, ...)
{
 67e:	711d                	add	sp,sp,-96
 680:	ec06                	sd	ra,24(sp)
 682:	e822                	sd	s0,16(sp)
 684:	1000                	add	s0,sp,32
 686:	e40c                	sd	a1,8(s0)
 688:	e810                	sd	a2,16(s0)
 68a:	ec14                	sd	a3,24(s0)
 68c:	f018                	sd	a4,32(s0)
 68e:	f41c                	sd	a5,40(s0)
 690:	03043823          	sd	a6,48(s0)
 694:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 698:	00840613          	add	a2,s0,8
 69c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6a0:	85aa                	mv	a1,a0
 6a2:	4505                	li	a0,1
 6a4:	00000097          	auipc	ra,0x0
 6a8:	de0080e7          	jalr	-544(ra) # 484 <vprintf>
}
 6ac:	60e2                	ld	ra,24(sp)
 6ae:	6442                	ld	s0,16(sp)
 6b0:	6125                	add	sp,sp,96
 6b2:	8082                	ret

00000000000006b4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6b4:	1141                	add	sp,sp,-16
 6b6:	e422                	sd	s0,8(sp)
 6b8:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ba:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6be:	00001797          	auipc	a5,0x1
 6c2:	9427b783          	ld	a5,-1726(a5) # 1000 <freep>
 6c6:	a02d                	j	6f0 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6c8:	4618                	lw	a4,8(a2)
 6ca:	9f2d                	addw	a4,a4,a1
 6cc:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6d0:	6398                	ld	a4,0(a5)
 6d2:	6310                	ld	a2,0(a4)
 6d4:	a83d                	j	712 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6d6:	ff852703          	lw	a4,-8(a0)
 6da:	9f31                	addw	a4,a4,a2
 6dc:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6de:	ff053683          	ld	a3,-16(a0)
 6e2:	a091                	j	726 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e4:	6398                	ld	a4,0(a5)
 6e6:	00e7e463          	bltu	a5,a4,6ee <free+0x3a>
 6ea:	00e6ea63          	bltu	a3,a4,6fe <free+0x4a>
{
 6ee:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f0:	fed7fae3          	bgeu	a5,a3,6e4 <free+0x30>
 6f4:	6398                	ld	a4,0(a5)
 6f6:	00e6e463          	bltu	a3,a4,6fe <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6fa:	fee7eae3          	bltu	a5,a4,6ee <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6fe:	ff852583          	lw	a1,-8(a0)
 702:	6390                	ld	a2,0(a5)
 704:	02059813          	sll	a6,a1,0x20
 708:	01c85713          	srl	a4,a6,0x1c
 70c:	9736                	add	a4,a4,a3
 70e:	fae60de3          	beq	a2,a4,6c8 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 712:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 716:	4790                	lw	a2,8(a5)
 718:	02061593          	sll	a1,a2,0x20
 71c:	01c5d713          	srl	a4,a1,0x1c
 720:	973e                	add	a4,a4,a5
 722:	fae68ae3          	beq	a3,a4,6d6 <free+0x22>
    p->s.ptr = bp->s.ptr;
 726:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 728:	00001717          	auipc	a4,0x1
 72c:	8cf73c23          	sd	a5,-1832(a4) # 1000 <freep>
}
 730:	6422                	ld	s0,8(sp)
 732:	0141                	add	sp,sp,16
 734:	8082                	ret

0000000000000736 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 736:	7139                	add	sp,sp,-64
 738:	fc06                	sd	ra,56(sp)
 73a:	f822                	sd	s0,48(sp)
 73c:	f426                	sd	s1,40(sp)
 73e:	f04a                	sd	s2,32(sp)
 740:	ec4e                	sd	s3,24(sp)
 742:	e852                	sd	s4,16(sp)
 744:	e456                	sd	s5,8(sp)
 746:	e05a                	sd	s6,0(sp)
 748:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 74a:	02051493          	sll	s1,a0,0x20
 74e:	9081                	srl	s1,s1,0x20
 750:	04bd                	add	s1,s1,15
 752:	8091                	srl	s1,s1,0x4
 754:	0014899b          	addw	s3,s1,1
 758:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 75a:	00001517          	auipc	a0,0x1
 75e:	8a653503          	ld	a0,-1882(a0) # 1000 <freep>
 762:	c515                	beqz	a0,78e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 764:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 766:	4798                	lw	a4,8(a5)
 768:	02977f63          	bgeu	a4,s1,7a6 <malloc+0x70>
  if(nu < 4096)
 76c:	8a4e                	mv	s4,s3
 76e:	0009871b          	sext.w	a4,s3
 772:	6685                	lui	a3,0x1
 774:	00d77363          	bgeu	a4,a3,77a <malloc+0x44>
 778:	6a05                	lui	s4,0x1
 77a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 77e:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 782:	00001917          	auipc	s2,0x1
 786:	87e90913          	add	s2,s2,-1922 # 1000 <freep>
  if(p == (char*)-1)
 78a:	5afd                	li	s5,-1
 78c:	a895                	j	800 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 78e:	00001797          	auipc	a5,0x1
 792:	88278793          	add	a5,a5,-1918 # 1010 <base>
 796:	00001717          	auipc	a4,0x1
 79a:	86f73523          	sd	a5,-1942(a4) # 1000 <freep>
 79e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7a0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7a4:	b7e1                	j	76c <malloc+0x36>
      if(p->s.size == nunits)
 7a6:	02e48c63          	beq	s1,a4,7de <malloc+0xa8>
        p->s.size -= nunits;
 7aa:	4137073b          	subw	a4,a4,s3
 7ae:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7b0:	02071693          	sll	a3,a4,0x20
 7b4:	01c6d713          	srl	a4,a3,0x1c
 7b8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ba:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7be:	00001717          	auipc	a4,0x1
 7c2:	84a73123          	sd	a0,-1982(a4) # 1000 <freep>
      return (void*)(p + 1);
 7c6:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ca:	70e2                	ld	ra,56(sp)
 7cc:	7442                	ld	s0,48(sp)
 7ce:	74a2                	ld	s1,40(sp)
 7d0:	7902                	ld	s2,32(sp)
 7d2:	69e2                	ld	s3,24(sp)
 7d4:	6a42                	ld	s4,16(sp)
 7d6:	6aa2                	ld	s5,8(sp)
 7d8:	6b02                	ld	s6,0(sp)
 7da:	6121                	add	sp,sp,64
 7dc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7de:	6398                	ld	a4,0(a5)
 7e0:	e118                	sd	a4,0(a0)
 7e2:	bff1                	j	7be <malloc+0x88>
  hp->s.size = nu;
 7e4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7e8:	0541                	add	a0,a0,16
 7ea:	00000097          	auipc	ra,0x0
 7ee:	eca080e7          	jalr	-310(ra) # 6b4 <free>
  return freep;
 7f2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7f6:	d971                	beqz	a0,7ca <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7fa:	4798                	lw	a4,8(a5)
 7fc:	fa9775e3          	bgeu	a4,s1,7a6 <malloc+0x70>
    if(p == freep)
 800:	00093703          	ld	a4,0(s2)
 804:	853e                	mv	a0,a5
 806:	fef719e3          	bne	a4,a5,7f8 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 80a:	8552                	mv	a0,s4
 80c:	00000097          	auipc	ra,0x0
 810:	b7a080e7          	jalr	-1158(ra) # 386 <sbrk>
  if(p == (char*)-1)
 814:	fd5518e3          	bne	a0,s5,7e4 <malloc+0xae>
        return 0;
 818:	4501                	li	a0,0
 81a:	bf45                	j	7ca <malloc+0x94>
