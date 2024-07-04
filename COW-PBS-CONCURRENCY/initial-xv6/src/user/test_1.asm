
user/_test_1:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int
main(int argc, char *argv[]) {
   0:	7135                	add	sp,sp,-160
   2:	ed06                	sd	ra,152(sp)
   4:	e922                	sd	s0,144(sp)
   6:	e526                	sd	s1,136(sp)
   8:	e14a                	sd	s2,128(sp)
   a:	fcce                	sd	s3,120(sp)
   c:	f8d2                	sd	s4,112(sp)
   e:	1100                	add	s0,sp,160
    int x1 = getreadcount();
  10:	00000097          	auipc	ra,0x0
  14:	3a2080e7          	jalr	930(ra) # 3b2 <getreadcount>
  18:	8a2a                	mv	s4,a0
    int x2 = getreadcount();
  1a:	00000097          	auipc	ra,0x0
  1e:	398080e7          	jalr	920(ra) # 3b2 <getreadcount>
  22:	892a                	mv	s2,a0
    char buf[100];
    (void) read(4, buf, 1);
  24:	4605                	li	a2,1
  26:	f6840593          	add	a1,s0,-152
  2a:	4511                	li	a0,4
  2c:	00000097          	auipc	ra,0x0
  30:	2f6080e7          	jalr	758(ra) # 322 <read>
    int x3 = getreadcount();
  34:	00000097          	auipc	ra,0x0
  38:	37e080e7          	jalr	894(ra) # 3b2 <getreadcount>
  3c:	89aa                	mv	s3,a0
  3e:	3e800493          	li	s1,1000
    int i;
    for (i = 0; i < 1000; i++) {
        (void) read(4, buf, 1);
  42:	4605                	li	a2,1
  44:	f6840593          	add	a1,s0,-152
  48:	4511                	li	a0,4
  4a:	00000097          	auipc	ra,0x0
  4e:	2d8080e7          	jalr	728(ra) # 322 <read>
    for (i = 0; i < 1000; i++) {
  52:	34fd                	addw	s1,s1,-1
  54:	f4fd                	bnez	s1,42 <main+0x42>
    }
    int x4 = getreadcount();
  56:	00000097          	auipc	ra,0x0
  5a:	35c080e7          	jalr	860(ra) # 3b2 <getreadcount>
    printf("XV6_TEST_OUTPUT %d %d %d\n", x2-x1, x3-x2, x4-x3);
  5e:	413506bb          	subw	a3,a0,s3
  62:	4129863b          	subw	a2,s3,s2
  66:	414905bb          	subw	a1,s2,s4
  6a:	00000517          	auipc	a0,0x0
  6e:	7c650513          	add	a0,a0,1990 # 830 <malloc+0xee>
  72:	00000097          	auipc	ra,0x0
  76:	618080e7          	jalr	1560(ra) # 68a <printf>
    exit(0);
  7a:	4501                	li	a0,0
  7c:	00000097          	auipc	ra,0x0
  80:	28e080e7          	jalr	654(ra) # 30a <exit>

0000000000000084 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  84:	1141                	add	sp,sp,-16
  86:	e406                	sd	ra,8(sp)
  88:	e022                	sd	s0,0(sp)
  8a:	0800                	add	s0,sp,16
  extern int main();
  main();
  8c:	00000097          	auipc	ra,0x0
  90:	f74080e7          	jalr	-140(ra) # 0 <main>
  exit(0);
  94:	4501                	li	a0,0
  96:	00000097          	auipc	ra,0x0
  9a:	274080e7          	jalr	628(ra) # 30a <exit>

000000000000009e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  9e:	1141                	add	sp,sp,-16
  a0:	e422                	sd	s0,8(sp)
  a2:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  a4:	87aa                	mv	a5,a0
  a6:	0585                	add	a1,a1,1
  a8:	0785                	add	a5,a5,1
  aa:	fff5c703          	lbu	a4,-1(a1)
  ae:	fee78fa3          	sb	a4,-1(a5)
  b2:	fb75                	bnez	a4,a6 <strcpy+0x8>
    ;
  return os;
}
  b4:	6422                	ld	s0,8(sp)
  b6:	0141                	add	sp,sp,16
  b8:	8082                	ret

00000000000000ba <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ba:	1141                	add	sp,sp,-16
  bc:	e422                	sd	s0,8(sp)
  be:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  c0:	00054783          	lbu	a5,0(a0)
  c4:	cb91                	beqz	a5,d8 <strcmp+0x1e>
  c6:	0005c703          	lbu	a4,0(a1)
  ca:	00f71763          	bne	a4,a5,d8 <strcmp+0x1e>
    p++, q++;
  ce:	0505                	add	a0,a0,1
  d0:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  d2:	00054783          	lbu	a5,0(a0)
  d6:	fbe5                	bnez	a5,c6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  d8:	0005c503          	lbu	a0,0(a1)
}
  dc:	40a7853b          	subw	a0,a5,a0
  e0:	6422                	ld	s0,8(sp)
  e2:	0141                	add	sp,sp,16
  e4:	8082                	ret

00000000000000e6 <strlen>:

uint
strlen(const char *s)
{
  e6:	1141                	add	sp,sp,-16
  e8:	e422                	sd	s0,8(sp)
  ea:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ec:	00054783          	lbu	a5,0(a0)
  f0:	cf91                	beqz	a5,10c <strlen+0x26>
  f2:	0505                	add	a0,a0,1
  f4:	87aa                	mv	a5,a0
  f6:	86be                	mv	a3,a5
  f8:	0785                	add	a5,a5,1
  fa:	fff7c703          	lbu	a4,-1(a5)
  fe:	ff65                	bnez	a4,f6 <strlen+0x10>
 100:	40a6853b          	subw	a0,a3,a0
 104:	2505                	addw	a0,a0,1
    ;
  return n;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	add	sp,sp,16
 10a:	8082                	ret
  for(n = 0; s[n]; n++)
 10c:	4501                	li	a0,0
 10e:	bfe5                	j	106 <strlen+0x20>

0000000000000110 <memset>:

void*
memset(void *dst, int c, uint n)
{
 110:	1141                	add	sp,sp,-16
 112:	e422                	sd	s0,8(sp)
 114:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 116:	ca19                	beqz	a2,12c <memset+0x1c>
 118:	87aa                	mv	a5,a0
 11a:	1602                	sll	a2,a2,0x20
 11c:	9201                	srl	a2,a2,0x20
 11e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 122:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 126:	0785                	add	a5,a5,1
 128:	fee79de3          	bne	a5,a4,122 <memset+0x12>
  }
  return dst;
}
 12c:	6422                	ld	s0,8(sp)
 12e:	0141                	add	sp,sp,16
 130:	8082                	ret

0000000000000132 <strchr>:

char*
strchr(const char *s, char c)
{
 132:	1141                	add	sp,sp,-16
 134:	e422                	sd	s0,8(sp)
 136:	0800                	add	s0,sp,16
  for(; *s; s++)
 138:	00054783          	lbu	a5,0(a0)
 13c:	cb99                	beqz	a5,152 <strchr+0x20>
    if(*s == c)
 13e:	00f58763          	beq	a1,a5,14c <strchr+0x1a>
  for(; *s; s++)
 142:	0505                	add	a0,a0,1
 144:	00054783          	lbu	a5,0(a0)
 148:	fbfd                	bnez	a5,13e <strchr+0xc>
      return (char*)s;
  return 0;
 14a:	4501                	li	a0,0
}
 14c:	6422                	ld	s0,8(sp)
 14e:	0141                	add	sp,sp,16
 150:	8082                	ret
  return 0;
 152:	4501                	li	a0,0
 154:	bfe5                	j	14c <strchr+0x1a>

0000000000000156 <gets>:

char*
gets(char *buf, int max)
{
 156:	711d                	add	sp,sp,-96
 158:	ec86                	sd	ra,88(sp)
 15a:	e8a2                	sd	s0,80(sp)
 15c:	e4a6                	sd	s1,72(sp)
 15e:	e0ca                	sd	s2,64(sp)
 160:	fc4e                	sd	s3,56(sp)
 162:	f852                	sd	s4,48(sp)
 164:	f456                	sd	s5,40(sp)
 166:	f05a                	sd	s6,32(sp)
 168:	ec5e                	sd	s7,24(sp)
 16a:	1080                	add	s0,sp,96
 16c:	8baa                	mv	s7,a0
 16e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 170:	892a                	mv	s2,a0
 172:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 174:	4aa9                	li	s5,10
 176:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 178:	89a6                	mv	s3,s1
 17a:	2485                	addw	s1,s1,1
 17c:	0344d863          	bge	s1,s4,1ac <gets+0x56>
    cc = read(0, &c, 1);
 180:	4605                	li	a2,1
 182:	faf40593          	add	a1,s0,-81
 186:	4501                	li	a0,0
 188:	00000097          	auipc	ra,0x0
 18c:	19a080e7          	jalr	410(ra) # 322 <read>
    if(cc < 1)
 190:	00a05e63          	blez	a0,1ac <gets+0x56>
    buf[i++] = c;
 194:	faf44783          	lbu	a5,-81(s0)
 198:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 19c:	01578763          	beq	a5,s5,1aa <gets+0x54>
 1a0:	0905                	add	s2,s2,1
 1a2:	fd679be3          	bne	a5,s6,178 <gets+0x22>
  for(i=0; i+1 < max; ){
 1a6:	89a6                	mv	s3,s1
 1a8:	a011                	j	1ac <gets+0x56>
 1aa:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ac:	99de                	add	s3,s3,s7
 1ae:	00098023          	sb	zero,0(s3)
  return buf;
}
 1b2:	855e                	mv	a0,s7
 1b4:	60e6                	ld	ra,88(sp)
 1b6:	6446                	ld	s0,80(sp)
 1b8:	64a6                	ld	s1,72(sp)
 1ba:	6906                	ld	s2,64(sp)
 1bc:	79e2                	ld	s3,56(sp)
 1be:	7a42                	ld	s4,48(sp)
 1c0:	7aa2                	ld	s5,40(sp)
 1c2:	7b02                	ld	s6,32(sp)
 1c4:	6be2                	ld	s7,24(sp)
 1c6:	6125                	add	sp,sp,96
 1c8:	8082                	ret

00000000000001ca <stat>:

int
stat(const char *n, struct stat *st)
{
 1ca:	1101                	add	sp,sp,-32
 1cc:	ec06                	sd	ra,24(sp)
 1ce:	e822                	sd	s0,16(sp)
 1d0:	e426                	sd	s1,8(sp)
 1d2:	e04a                	sd	s2,0(sp)
 1d4:	1000                	add	s0,sp,32
 1d6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1d8:	4581                	li	a1,0
 1da:	00000097          	auipc	ra,0x0
 1de:	170080e7          	jalr	368(ra) # 34a <open>
  if(fd < 0)
 1e2:	02054563          	bltz	a0,20c <stat+0x42>
 1e6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1e8:	85ca                	mv	a1,s2
 1ea:	00000097          	auipc	ra,0x0
 1ee:	178080e7          	jalr	376(ra) # 362 <fstat>
 1f2:	892a                	mv	s2,a0
  close(fd);
 1f4:	8526                	mv	a0,s1
 1f6:	00000097          	auipc	ra,0x0
 1fa:	13c080e7          	jalr	316(ra) # 332 <close>
  return r;
}
 1fe:	854a                	mv	a0,s2
 200:	60e2                	ld	ra,24(sp)
 202:	6442                	ld	s0,16(sp)
 204:	64a2                	ld	s1,8(sp)
 206:	6902                	ld	s2,0(sp)
 208:	6105                	add	sp,sp,32
 20a:	8082                	ret
    return -1;
 20c:	597d                	li	s2,-1
 20e:	bfc5                	j	1fe <stat+0x34>

0000000000000210 <atoi>:

int
atoi(const char *s)
{
 210:	1141                	add	sp,sp,-16
 212:	e422                	sd	s0,8(sp)
 214:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 216:	00054683          	lbu	a3,0(a0)
 21a:	fd06879b          	addw	a5,a3,-48
 21e:	0ff7f793          	zext.b	a5,a5
 222:	4625                	li	a2,9
 224:	02f66863          	bltu	a2,a5,254 <atoi+0x44>
 228:	872a                	mv	a4,a0
  n = 0;
 22a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 22c:	0705                	add	a4,a4,1
 22e:	0025179b          	sllw	a5,a0,0x2
 232:	9fa9                	addw	a5,a5,a0
 234:	0017979b          	sllw	a5,a5,0x1
 238:	9fb5                	addw	a5,a5,a3
 23a:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 23e:	00074683          	lbu	a3,0(a4)
 242:	fd06879b          	addw	a5,a3,-48
 246:	0ff7f793          	zext.b	a5,a5
 24a:	fef671e3          	bgeu	a2,a5,22c <atoi+0x1c>
  return n;
}
 24e:	6422                	ld	s0,8(sp)
 250:	0141                	add	sp,sp,16
 252:	8082                	ret
  n = 0;
 254:	4501                	li	a0,0
 256:	bfe5                	j	24e <atoi+0x3e>

0000000000000258 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 258:	1141                	add	sp,sp,-16
 25a:	e422                	sd	s0,8(sp)
 25c:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 25e:	02b57463          	bgeu	a0,a1,286 <memmove+0x2e>
    while(n-- > 0)
 262:	00c05f63          	blez	a2,280 <memmove+0x28>
 266:	1602                	sll	a2,a2,0x20
 268:	9201                	srl	a2,a2,0x20
 26a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 26e:	872a                	mv	a4,a0
      *dst++ = *src++;
 270:	0585                	add	a1,a1,1
 272:	0705                	add	a4,a4,1
 274:	fff5c683          	lbu	a3,-1(a1)
 278:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 27c:	fee79ae3          	bne	a5,a4,270 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 280:	6422                	ld	s0,8(sp)
 282:	0141                	add	sp,sp,16
 284:	8082                	ret
    dst += n;
 286:	00c50733          	add	a4,a0,a2
    src += n;
 28a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 28c:	fec05ae3          	blez	a2,280 <memmove+0x28>
 290:	fff6079b          	addw	a5,a2,-1
 294:	1782                	sll	a5,a5,0x20
 296:	9381                	srl	a5,a5,0x20
 298:	fff7c793          	not	a5,a5
 29c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 29e:	15fd                	add	a1,a1,-1
 2a0:	177d                	add	a4,a4,-1
 2a2:	0005c683          	lbu	a3,0(a1)
 2a6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2aa:	fee79ae3          	bne	a5,a4,29e <memmove+0x46>
 2ae:	bfc9                	j	280 <memmove+0x28>

00000000000002b0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2b0:	1141                	add	sp,sp,-16
 2b2:	e422                	sd	s0,8(sp)
 2b4:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2b6:	ca05                	beqz	a2,2e6 <memcmp+0x36>
 2b8:	fff6069b          	addw	a3,a2,-1
 2bc:	1682                	sll	a3,a3,0x20
 2be:	9281                	srl	a3,a3,0x20
 2c0:	0685                	add	a3,a3,1
 2c2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2c4:	00054783          	lbu	a5,0(a0)
 2c8:	0005c703          	lbu	a4,0(a1)
 2cc:	00e79863          	bne	a5,a4,2dc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2d0:	0505                	add	a0,a0,1
    p2++;
 2d2:	0585                	add	a1,a1,1
  while (n-- > 0) {
 2d4:	fed518e3          	bne	a0,a3,2c4 <memcmp+0x14>
  }
  return 0;
 2d8:	4501                	li	a0,0
 2da:	a019                	j	2e0 <memcmp+0x30>
      return *p1 - *p2;
 2dc:	40e7853b          	subw	a0,a5,a4
}
 2e0:	6422                	ld	s0,8(sp)
 2e2:	0141                	add	sp,sp,16
 2e4:	8082                	ret
  return 0;
 2e6:	4501                	li	a0,0
 2e8:	bfe5                	j	2e0 <memcmp+0x30>

00000000000002ea <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ea:	1141                	add	sp,sp,-16
 2ec:	e406                	sd	ra,8(sp)
 2ee:	e022                	sd	s0,0(sp)
 2f0:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2f2:	00000097          	auipc	ra,0x0
 2f6:	f66080e7          	jalr	-154(ra) # 258 <memmove>
}
 2fa:	60a2                	ld	ra,8(sp)
 2fc:	6402                	ld	s0,0(sp)
 2fe:	0141                	add	sp,sp,16
 300:	8082                	ret

0000000000000302 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 302:	4885                	li	a7,1
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <exit>:
.global exit
exit:
 li a7, SYS_exit
 30a:	4889                	li	a7,2
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <wait>:
.global wait
wait:
 li a7, SYS_wait
 312:	488d                	li	a7,3
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 31a:	4891                	li	a7,4
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <read>:
.global read
read:
 li a7, SYS_read
 322:	4895                	li	a7,5
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <write>:
.global write
write:
 li a7, SYS_write
 32a:	48c1                	li	a7,16
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <close>:
.global close
close:
 li a7, SYS_close
 332:	48d5                	li	a7,21
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <kill>:
.global kill
kill:
 li a7, SYS_kill
 33a:	4899                	li	a7,6
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <exec>:
.global exec
exec:
 li a7, SYS_exec
 342:	489d                	li	a7,7
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <open>:
.global open
open:
 li a7, SYS_open
 34a:	48bd                	li	a7,15
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 352:	48c5                	li	a7,17
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 35a:	48c9                	li	a7,18
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 362:	48a1                	li	a7,8
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <link>:
.global link
link:
 li a7, SYS_link
 36a:	48cd                	li	a7,19
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 372:	48d1                	li	a7,20
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 37a:	48a5                	li	a7,9
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <dup>:
.global dup
dup:
 li a7, SYS_dup
 382:	48a9                	li	a7,10
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 38a:	48ad                	li	a7,11
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 392:	48b1                	li	a7,12
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 39a:	48b5                	li	a7,13
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a2:	48b9                	li	a7,14
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3aa:	48d9                	li	a7,22
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 3b2:	48dd                	li	a7,23
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3ba:	48e1                	li	a7,24
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3c2:	1101                	add	sp,sp,-32
 3c4:	ec06                	sd	ra,24(sp)
 3c6:	e822                	sd	s0,16(sp)
 3c8:	1000                	add	s0,sp,32
 3ca:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ce:	4605                	li	a2,1
 3d0:	fef40593          	add	a1,s0,-17
 3d4:	00000097          	auipc	ra,0x0
 3d8:	f56080e7          	jalr	-170(ra) # 32a <write>
}
 3dc:	60e2                	ld	ra,24(sp)
 3de:	6442                	ld	s0,16(sp)
 3e0:	6105                	add	sp,sp,32
 3e2:	8082                	ret

00000000000003e4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3e4:	7139                	add	sp,sp,-64
 3e6:	fc06                	sd	ra,56(sp)
 3e8:	f822                	sd	s0,48(sp)
 3ea:	f426                	sd	s1,40(sp)
 3ec:	f04a                	sd	s2,32(sp)
 3ee:	ec4e                	sd	s3,24(sp)
 3f0:	0080                	add	s0,sp,64
 3f2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3f4:	c299                	beqz	a3,3fa <printint+0x16>
 3f6:	0805c963          	bltz	a1,488 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3fa:	2581                	sext.w	a1,a1
  neg = 0;
 3fc:	4881                	li	a7,0
 3fe:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 402:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 404:	2601                	sext.w	a2,a2
 406:	00000517          	auipc	a0,0x0
 40a:	4aa50513          	add	a0,a0,1194 # 8b0 <digits>
 40e:	883a                	mv	a6,a4
 410:	2705                	addw	a4,a4,1
 412:	02c5f7bb          	remuw	a5,a1,a2
 416:	1782                	sll	a5,a5,0x20
 418:	9381                	srl	a5,a5,0x20
 41a:	97aa                	add	a5,a5,a0
 41c:	0007c783          	lbu	a5,0(a5)
 420:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 424:	0005879b          	sext.w	a5,a1
 428:	02c5d5bb          	divuw	a1,a1,a2
 42c:	0685                	add	a3,a3,1
 42e:	fec7f0e3          	bgeu	a5,a2,40e <printint+0x2a>
  if(neg)
 432:	00088c63          	beqz	a7,44a <printint+0x66>
    buf[i++] = '-';
 436:	fd070793          	add	a5,a4,-48
 43a:	00878733          	add	a4,a5,s0
 43e:	02d00793          	li	a5,45
 442:	fef70823          	sb	a5,-16(a4)
 446:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 44a:	02e05863          	blez	a4,47a <printint+0x96>
 44e:	fc040793          	add	a5,s0,-64
 452:	00e78933          	add	s2,a5,a4
 456:	fff78993          	add	s3,a5,-1
 45a:	99ba                	add	s3,s3,a4
 45c:	377d                	addw	a4,a4,-1
 45e:	1702                	sll	a4,a4,0x20
 460:	9301                	srl	a4,a4,0x20
 462:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 466:	fff94583          	lbu	a1,-1(s2)
 46a:	8526                	mv	a0,s1
 46c:	00000097          	auipc	ra,0x0
 470:	f56080e7          	jalr	-170(ra) # 3c2 <putc>
  while(--i >= 0)
 474:	197d                	add	s2,s2,-1
 476:	ff3918e3          	bne	s2,s3,466 <printint+0x82>
}
 47a:	70e2                	ld	ra,56(sp)
 47c:	7442                	ld	s0,48(sp)
 47e:	74a2                	ld	s1,40(sp)
 480:	7902                	ld	s2,32(sp)
 482:	69e2                	ld	s3,24(sp)
 484:	6121                	add	sp,sp,64
 486:	8082                	ret
    x = -xx;
 488:	40b005bb          	negw	a1,a1
    neg = 1;
 48c:	4885                	li	a7,1
    x = -xx;
 48e:	bf85                	j	3fe <printint+0x1a>

0000000000000490 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 490:	715d                	add	sp,sp,-80
 492:	e486                	sd	ra,72(sp)
 494:	e0a2                	sd	s0,64(sp)
 496:	fc26                	sd	s1,56(sp)
 498:	f84a                	sd	s2,48(sp)
 49a:	f44e                	sd	s3,40(sp)
 49c:	f052                	sd	s4,32(sp)
 49e:	ec56                	sd	s5,24(sp)
 4a0:	e85a                	sd	s6,16(sp)
 4a2:	e45e                	sd	s7,8(sp)
 4a4:	e062                	sd	s8,0(sp)
 4a6:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4a8:	0005c903          	lbu	s2,0(a1)
 4ac:	18090c63          	beqz	s2,644 <vprintf+0x1b4>
 4b0:	8aaa                	mv	s5,a0
 4b2:	8bb2                	mv	s7,a2
 4b4:	00158493          	add	s1,a1,1
  state = 0;
 4b8:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4ba:	02500a13          	li	s4,37
 4be:	4b55                	li	s6,21
 4c0:	a839                	j	4de <vprintf+0x4e>
        putc(fd, c);
 4c2:	85ca                	mv	a1,s2
 4c4:	8556                	mv	a0,s5
 4c6:	00000097          	auipc	ra,0x0
 4ca:	efc080e7          	jalr	-260(ra) # 3c2 <putc>
 4ce:	a019                	j	4d4 <vprintf+0x44>
    } else if(state == '%'){
 4d0:	01498d63          	beq	s3,s4,4ea <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 4d4:	0485                	add	s1,s1,1
 4d6:	fff4c903          	lbu	s2,-1(s1)
 4da:	16090563          	beqz	s2,644 <vprintf+0x1b4>
    if(state == 0){
 4de:	fe0999e3          	bnez	s3,4d0 <vprintf+0x40>
      if(c == '%'){
 4e2:	ff4910e3          	bne	s2,s4,4c2 <vprintf+0x32>
        state = '%';
 4e6:	89d2                	mv	s3,s4
 4e8:	b7f5                	j	4d4 <vprintf+0x44>
      if(c == 'd'){
 4ea:	13490263          	beq	s2,s4,60e <vprintf+0x17e>
 4ee:	f9d9079b          	addw	a5,s2,-99
 4f2:	0ff7f793          	zext.b	a5,a5
 4f6:	12fb6563          	bltu	s6,a5,620 <vprintf+0x190>
 4fa:	f9d9079b          	addw	a5,s2,-99
 4fe:	0ff7f713          	zext.b	a4,a5
 502:	10eb6f63          	bltu	s6,a4,620 <vprintf+0x190>
 506:	00271793          	sll	a5,a4,0x2
 50a:	00000717          	auipc	a4,0x0
 50e:	34e70713          	add	a4,a4,846 # 858 <malloc+0x116>
 512:	97ba                	add	a5,a5,a4
 514:	439c                	lw	a5,0(a5)
 516:	97ba                	add	a5,a5,a4
 518:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 51a:	008b8913          	add	s2,s7,8
 51e:	4685                	li	a3,1
 520:	4629                	li	a2,10
 522:	000ba583          	lw	a1,0(s7)
 526:	8556                	mv	a0,s5
 528:	00000097          	auipc	ra,0x0
 52c:	ebc080e7          	jalr	-324(ra) # 3e4 <printint>
 530:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 532:	4981                	li	s3,0
 534:	b745                	j	4d4 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 536:	008b8913          	add	s2,s7,8
 53a:	4681                	li	a3,0
 53c:	4629                	li	a2,10
 53e:	000ba583          	lw	a1,0(s7)
 542:	8556                	mv	a0,s5
 544:	00000097          	auipc	ra,0x0
 548:	ea0080e7          	jalr	-352(ra) # 3e4 <printint>
 54c:	8bca                	mv	s7,s2
      state = 0;
 54e:	4981                	li	s3,0
 550:	b751                	j	4d4 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 552:	008b8913          	add	s2,s7,8
 556:	4681                	li	a3,0
 558:	4641                	li	a2,16
 55a:	000ba583          	lw	a1,0(s7)
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	e84080e7          	jalr	-380(ra) # 3e4 <printint>
 568:	8bca                	mv	s7,s2
      state = 0;
 56a:	4981                	li	s3,0
 56c:	b7a5                	j	4d4 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 56e:	008b8c13          	add	s8,s7,8
 572:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 576:	03000593          	li	a1,48
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e46080e7          	jalr	-442(ra) # 3c2 <putc>
  putc(fd, 'x');
 584:	07800593          	li	a1,120
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	e38080e7          	jalr	-456(ra) # 3c2 <putc>
 592:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 594:	00000b97          	auipc	s7,0x0
 598:	31cb8b93          	add	s7,s7,796 # 8b0 <digits>
 59c:	03c9d793          	srl	a5,s3,0x3c
 5a0:	97de                	add	a5,a5,s7
 5a2:	0007c583          	lbu	a1,0(a5)
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	e1a080e7          	jalr	-486(ra) # 3c2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5b0:	0992                	sll	s3,s3,0x4
 5b2:	397d                	addw	s2,s2,-1
 5b4:	fe0914e3          	bnez	s2,59c <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5b8:	8be2                	mv	s7,s8
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	bf21                	j	4d4 <vprintf+0x44>
        s = va_arg(ap, char*);
 5be:	008b8993          	add	s3,s7,8
 5c2:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5c6:	02090163          	beqz	s2,5e8 <vprintf+0x158>
        while(*s != 0){
 5ca:	00094583          	lbu	a1,0(s2)
 5ce:	c9a5                	beqz	a1,63e <vprintf+0x1ae>
          putc(fd, *s);
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	df0080e7          	jalr	-528(ra) # 3c2 <putc>
          s++;
 5da:	0905                	add	s2,s2,1
        while(*s != 0){
 5dc:	00094583          	lbu	a1,0(s2)
 5e0:	f9e5                	bnez	a1,5d0 <vprintf+0x140>
        s = va_arg(ap, char*);
 5e2:	8bce                	mv	s7,s3
      state = 0;
 5e4:	4981                	li	s3,0
 5e6:	b5fd                	j	4d4 <vprintf+0x44>
          s = "(null)";
 5e8:	00000917          	auipc	s2,0x0
 5ec:	26890913          	add	s2,s2,616 # 850 <malloc+0x10e>
        while(*s != 0){
 5f0:	02800593          	li	a1,40
 5f4:	bff1                	j	5d0 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 5f6:	008b8913          	add	s2,s7,8
 5fa:	000bc583          	lbu	a1,0(s7)
 5fe:	8556                	mv	a0,s5
 600:	00000097          	auipc	ra,0x0
 604:	dc2080e7          	jalr	-574(ra) # 3c2 <putc>
 608:	8bca                	mv	s7,s2
      state = 0;
 60a:	4981                	li	s3,0
 60c:	b5e1                	j	4d4 <vprintf+0x44>
        putc(fd, c);
 60e:	02500593          	li	a1,37
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	dae080e7          	jalr	-594(ra) # 3c2 <putc>
      state = 0;
 61c:	4981                	li	s3,0
 61e:	bd5d                	j	4d4 <vprintf+0x44>
        putc(fd, '%');
 620:	02500593          	li	a1,37
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	d9c080e7          	jalr	-612(ra) # 3c2 <putc>
        putc(fd, c);
 62e:	85ca                	mv	a1,s2
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	d90080e7          	jalr	-624(ra) # 3c2 <putc>
      state = 0;
 63a:	4981                	li	s3,0
 63c:	bd61                	j	4d4 <vprintf+0x44>
        s = va_arg(ap, char*);
 63e:	8bce                	mv	s7,s3
      state = 0;
 640:	4981                	li	s3,0
 642:	bd49                	j	4d4 <vprintf+0x44>
    }
  }
}
 644:	60a6                	ld	ra,72(sp)
 646:	6406                	ld	s0,64(sp)
 648:	74e2                	ld	s1,56(sp)
 64a:	7942                	ld	s2,48(sp)
 64c:	79a2                	ld	s3,40(sp)
 64e:	7a02                	ld	s4,32(sp)
 650:	6ae2                	ld	s5,24(sp)
 652:	6b42                	ld	s6,16(sp)
 654:	6ba2                	ld	s7,8(sp)
 656:	6c02                	ld	s8,0(sp)
 658:	6161                	add	sp,sp,80
 65a:	8082                	ret

000000000000065c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 65c:	715d                	add	sp,sp,-80
 65e:	ec06                	sd	ra,24(sp)
 660:	e822                	sd	s0,16(sp)
 662:	1000                	add	s0,sp,32
 664:	e010                	sd	a2,0(s0)
 666:	e414                	sd	a3,8(s0)
 668:	e818                	sd	a4,16(s0)
 66a:	ec1c                	sd	a5,24(s0)
 66c:	03043023          	sd	a6,32(s0)
 670:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 674:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 678:	8622                	mv	a2,s0
 67a:	00000097          	auipc	ra,0x0
 67e:	e16080e7          	jalr	-490(ra) # 490 <vprintf>
}
 682:	60e2                	ld	ra,24(sp)
 684:	6442                	ld	s0,16(sp)
 686:	6161                	add	sp,sp,80
 688:	8082                	ret

000000000000068a <printf>:

void
printf(const char *fmt, ...)
{
 68a:	711d                	add	sp,sp,-96
 68c:	ec06                	sd	ra,24(sp)
 68e:	e822                	sd	s0,16(sp)
 690:	1000                	add	s0,sp,32
 692:	e40c                	sd	a1,8(s0)
 694:	e810                	sd	a2,16(s0)
 696:	ec14                	sd	a3,24(s0)
 698:	f018                	sd	a4,32(s0)
 69a:	f41c                	sd	a5,40(s0)
 69c:	03043823          	sd	a6,48(s0)
 6a0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6a4:	00840613          	add	a2,s0,8
 6a8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ac:	85aa                	mv	a1,a0
 6ae:	4505                	li	a0,1
 6b0:	00000097          	auipc	ra,0x0
 6b4:	de0080e7          	jalr	-544(ra) # 490 <vprintf>
}
 6b8:	60e2                	ld	ra,24(sp)
 6ba:	6442                	ld	s0,16(sp)
 6bc:	6125                	add	sp,sp,96
 6be:	8082                	ret

00000000000006c0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6c0:	1141                	add	sp,sp,-16
 6c2:	e422                	sd	s0,8(sp)
 6c4:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6c6:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ca:	00001797          	auipc	a5,0x1
 6ce:	9367b783          	ld	a5,-1738(a5) # 1000 <freep>
 6d2:	a02d                	j	6fc <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6d4:	4618                	lw	a4,8(a2)
 6d6:	9f2d                	addw	a4,a4,a1
 6d8:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6dc:	6398                	ld	a4,0(a5)
 6de:	6310                	ld	a2,0(a4)
 6e0:	a83d                	j	71e <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6e2:	ff852703          	lw	a4,-8(a0)
 6e6:	9f31                	addw	a4,a4,a2
 6e8:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6ea:	ff053683          	ld	a3,-16(a0)
 6ee:	a091                	j	732 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f0:	6398                	ld	a4,0(a5)
 6f2:	00e7e463          	bltu	a5,a4,6fa <free+0x3a>
 6f6:	00e6ea63          	bltu	a3,a4,70a <free+0x4a>
{
 6fa:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6fc:	fed7fae3          	bgeu	a5,a3,6f0 <free+0x30>
 700:	6398                	ld	a4,0(a5)
 702:	00e6e463          	bltu	a3,a4,70a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 706:	fee7eae3          	bltu	a5,a4,6fa <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 70a:	ff852583          	lw	a1,-8(a0)
 70e:	6390                	ld	a2,0(a5)
 710:	02059813          	sll	a6,a1,0x20
 714:	01c85713          	srl	a4,a6,0x1c
 718:	9736                	add	a4,a4,a3
 71a:	fae60de3          	beq	a2,a4,6d4 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 71e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 722:	4790                	lw	a2,8(a5)
 724:	02061593          	sll	a1,a2,0x20
 728:	01c5d713          	srl	a4,a1,0x1c
 72c:	973e                	add	a4,a4,a5
 72e:	fae68ae3          	beq	a3,a4,6e2 <free+0x22>
    p->s.ptr = bp->s.ptr;
 732:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 734:	00001717          	auipc	a4,0x1
 738:	8cf73623          	sd	a5,-1844(a4) # 1000 <freep>
}
 73c:	6422                	ld	s0,8(sp)
 73e:	0141                	add	sp,sp,16
 740:	8082                	ret

0000000000000742 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 742:	7139                	add	sp,sp,-64
 744:	fc06                	sd	ra,56(sp)
 746:	f822                	sd	s0,48(sp)
 748:	f426                	sd	s1,40(sp)
 74a:	f04a                	sd	s2,32(sp)
 74c:	ec4e                	sd	s3,24(sp)
 74e:	e852                	sd	s4,16(sp)
 750:	e456                	sd	s5,8(sp)
 752:	e05a                	sd	s6,0(sp)
 754:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 756:	02051493          	sll	s1,a0,0x20
 75a:	9081                	srl	s1,s1,0x20
 75c:	04bd                	add	s1,s1,15
 75e:	8091                	srl	s1,s1,0x4
 760:	0014899b          	addw	s3,s1,1
 764:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 766:	00001517          	auipc	a0,0x1
 76a:	89a53503          	ld	a0,-1894(a0) # 1000 <freep>
 76e:	c515                	beqz	a0,79a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 770:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 772:	4798                	lw	a4,8(a5)
 774:	02977f63          	bgeu	a4,s1,7b2 <malloc+0x70>
  if(nu < 4096)
 778:	8a4e                	mv	s4,s3
 77a:	0009871b          	sext.w	a4,s3
 77e:	6685                	lui	a3,0x1
 780:	00d77363          	bgeu	a4,a3,786 <malloc+0x44>
 784:	6a05                	lui	s4,0x1
 786:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 78a:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 78e:	00001917          	auipc	s2,0x1
 792:	87290913          	add	s2,s2,-1934 # 1000 <freep>
  if(p == (char*)-1)
 796:	5afd                	li	s5,-1
 798:	a895                	j	80c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 79a:	00001797          	auipc	a5,0x1
 79e:	87678793          	add	a5,a5,-1930 # 1010 <base>
 7a2:	00001717          	auipc	a4,0x1
 7a6:	84f73f23          	sd	a5,-1954(a4) # 1000 <freep>
 7aa:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ac:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7b0:	b7e1                	j	778 <malloc+0x36>
      if(p->s.size == nunits)
 7b2:	02e48c63          	beq	s1,a4,7ea <malloc+0xa8>
        p->s.size -= nunits;
 7b6:	4137073b          	subw	a4,a4,s3
 7ba:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7bc:	02071693          	sll	a3,a4,0x20
 7c0:	01c6d713          	srl	a4,a3,0x1c
 7c4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7c6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7ca:	00001717          	auipc	a4,0x1
 7ce:	82a73b23          	sd	a0,-1994(a4) # 1000 <freep>
      return (void*)(p + 1);
 7d2:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7d6:	70e2                	ld	ra,56(sp)
 7d8:	7442                	ld	s0,48(sp)
 7da:	74a2                	ld	s1,40(sp)
 7dc:	7902                	ld	s2,32(sp)
 7de:	69e2                	ld	s3,24(sp)
 7e0:	6a42                	ld	s4,16(sp)
 7e2:	6aa2                	ld	s5,8(sp)
 7e4:	6b02                	ld	s6,0(sp)
 7e6:	6121                	add	sp,sp,64
 7e8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7ea:	6398                	ld	a4,0(a5)
 7ec:	e118                	sd	a4,0(a0)
 7ee:	bff1                	j	7ca <malloc+0x88>
  hp->s.size = nu;
 7f0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7f4:	0541                	add	a0,a0,16
 7f6:	00000097          	auipc	ra,0x0
 7fa:	eca080e7          	jalr	-310(ra) # 6c0 <free>
  return freep;
 7fe:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 802:	d971                	beqz	a0,7d6 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 804:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 806:	4798                	lw	a4,8(a5)
 808:	fa9775e3          	bgeu	a4,s1,7b2 <malloc+0x70>
    if(p == freep)
 80c:	00093703          	ld	a4,0(s2)
 810:	853e                	mv	a0,a5
 812:	fef719e3          	bne	a4,a5,804 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 816:	8552                	mv	a0,s4
 818:	00000097          	auipc	ra,0x0
 81c:	b7a080e7          	jalr	-1158(ra) # 392 <sbrk>
  if(p == (char*)-1)
 820:	fd5518e3          	bne	a0,s5,7f0 <malloc+0xae>
        return 0;
 824:	4501                	li	a0,0
 826:	bf45                	j	7d6 <malloc+0x94>
