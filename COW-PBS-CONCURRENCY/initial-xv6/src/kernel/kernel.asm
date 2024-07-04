
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	add	sp,sp,-1472 # 80008a40 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8b070713          	add	a4,a4,-1872 # 80008900 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	25e78793          	add	a5,a5,606 # 800062c0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbbe77>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	ece78793          	add	a5,a5,-306 # 80000f7a <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	710080e7          	jalr	1808(ra) # 8000283a <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8bc50513          	add	a0,a0,-1860 # 80010a40 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	b4e080e7          	jalr	-1202(ra) # 80000cda <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8ac48493          	add	s1,s1,-1876 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	93c90913          	add	s2,s2,-1732 # 80010ad8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	960080e7          	jalr	-1696(ra) # 80001b14 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	4c8080e7          	jalr	1224(ra) # 80002684 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	206080e7          	jalr	518(ra) # 800023d0 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	86270713          	add	a4,a4,-1950 # 80010a40 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	5d4080e7          	jalr	1492(ra) # 800027e4 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	81850513          	add	a0,a0,-2024 # 80010a40 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	b5e080e7          	jalr	-1186(ra) # 80000d8e <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	80250513          	add	a0,a0,-2046 # 80010a40 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	b48080e7          	jalr	-1208(ra) # 80000d8e <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	86f72523          	sw	a5,-1942(a4) # 80010ad8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	77850513          	add	a0,a0,1912 # 80010a40 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	a0a080e7          	jalr	-1526(ra) # 80000cda <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	5a2080e7          	jalr	1442(ra) # 80002890 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	74a50513          	add	a0,a0,1866 # 80010a40 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a90080e7          	jalr	-1392(ra) # 80000d8e <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	72670713          	add	a4,a4,1830 # 80010a40 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	6fc78793          	add	a5,a5,1788 # 80010a40 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7667a783          	lw	a5,1894(a5) # 80010ad8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ba70713          	add	a4,a4,1722 # 80010a40 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6aa48493          	add	s1,s1,1706 # 80010a40 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	66e70713          	add	a4,a4,1646 # 80010a40 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6ef72c23          	sw	a5,1784(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	63278793          	add	a5,a5,1586 # 80010a40 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	6ac7a523          	sw	a2,1706(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	69e50513          	add	a0,a0,1694 # 80010ad8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	ff2080e7          	jalr	-14(ra) # 80002434 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5e450513          	add	a0,a0,1508 # 80010a40 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	7e6080e7          	jalr	2022(ra) # 80000c4a <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	37c78793          	add	a5,a5,892 # 802417f0 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5a07ac23          	sw	zero,1464(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b6e50513          	add	a0,a0,-1170 # 800080d8 <digits+0x98>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	34f72223          	sw	a5,836(a4) # 800088c0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	548dad83          	lw	s11,1352(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	4f250513          	add	a0,a0,1266 # 80010ae8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	6dc080e7          	jalr	1756(ra) # 80000cda <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	39450513          	add	a0,a0,916 # 80010ae8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	632080e7          	jalr	1586(ra) # 80000d8e <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	37848493          	add	s1,s1,888 # 80010ae8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	4c8080e7          	jalr	1224(ra) # 80000c4a <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	33850513          	add	a0,a0,824 # 80010b08 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	472080e7          	jalr	1138(ra) # 80000c4a <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	49a080e7          	jalr	1178(ra) # 80000c8e <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0c47a783          	lw	a5,196(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	50c080e7          	jalr	1292(ra) # 80000d2e <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0947b783          	ld	a5,148(a5) # 800088c8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	09473703          	ld	a4,148(a4) # 800088d0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	2aaa0a13          	add	s4,s4,682 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	06248493          	add	s1,s1,98 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	06298993          	add	s3,s3,98 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	ba4080e7          	jalr	-1116(ra) # 80002434 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	23c50513          	add	a0,a0,572 # 80010b08 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	406080e7          	jalr	1030(ra) # 80000cda <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fe47a783          	lw	a5,-28(a5) # 800088c0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fea73703          	ld	a4,-22(a4) # 800088d0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fda7b783          	ld	a5,-38(a5) # 800088c8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	20e98993          	add	s3,s3,526 # 80010b08 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fc648493          	add	s1,s1,-58 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fc690913          	add	s2,s2,-58 # 800088d0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	ab6080e7          	jalr	-1354(ra) # 800023d0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1d848493          	add	s1,s1,472 # 80010b08 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7b623          	sd	a4,-116(a5) # 800088d0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	438080e7          	jalr	1080(ra) # 80000d8e <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	15248493          	add	s1,s1,338 # 80010b08 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	31a080e7          	jalr	794(ra) # 80000cda <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	3bc080e7          	jalr	956(ra) # 80000d8e <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009e4:	7179                	add	sp,sp,-48
    800009e6:	f406                	sd	ra,40(sp)
    800009e8:	f022                	sd	s0,32(sp)
    800009ea:	ec26                	sd	s1,24(sp)
    800009ec:	e84a                	sd	s2,16(sp)
    800009ee:	e44e                	sd	s3,8(sp)
    800009f0:	1800                	add	s0,sp,48
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    800009f2:	03451793          	sll	a5,a0,0x34
    800009f6:	eba5                	bnez	a5,80000a66 <kfree+0x82>
    800009f8:	84aa                	mv	s1,a0
    800009fa:	00242797          	auipc	a5,0x242
    800009fe:	f8e78793          	add	a5,a5,-114 # 80242988 <end>
    80000a02:	06f56263          	bltu	a0,a5,80000a66 <kfree+0x82>
    80000a06:	47c5                	li	a5,17
    80000a08:	07ee                	sll	a5,a5,0x1b
    80000a0a:	04f57e63          	bgeu	a0,a5,80000a66 <kfree+0x82>
    panic("kfree");

  acquire(&ref_lock);
    80000a0e:	00010517          	auipc	a0,0x10
    80000a12:	13250513          	add	a0,a0,306 # 80010b40 <ref_lock>
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2c4080e7          	jalr	708(ra) # 80000cda <acquire>
  if (arr[((uint64)pa) / 4096] <= 1)
    80000a1e:	00c4d793          	srl	a5,s1,0xc
    80000a22:	00279693          	sll	a3,a5,0x2
    80000a26:	00010717          	auipc	a4,0x10
    80000a2a:	15270713          	add	a4,a4,338 # 80010b78 <arr>
    80000a2e:	9736                	add	a4,a4,a3
    80000a30:	4318                	lw	a4,0(a4)
    80000a32:	4685                	li	a3,1
    80000a34:	04e6d163          	bge	a3,a4,80000a76 <kfree+0x92>
    kmem.freelist = r;
    release(&kmem.lock);
  }
  else
  {
    arr[((uint64)pa) / 4096]--;
    80000a38:	078a                	sll	a5,a5,0x2
    80000a3a:	00010697          	auipc	a3,0x10
    80000a3e:	13e68693          	add	a3,a3,318 # 80010b78 <arr>
    80000a42:	97b6                	add	a5,a5,a3
    80000a44:	377d                	addw	a4,a4,-1
    80000a46:	c398                	sw	a4,0(a5)
    release(&ref_lock);
    80000a48:	00010517          	auipc	a0,0x10
    80000a4c:	0f850513          	add	a0,a0,248 # 80010b40 <ref_lock>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	33e080e7          	jalr	830(ra) # 80000d8e <release>
  }
  return;
}
    80000a58:	70a2                	ld	ra,40(sp)
    80000a5a:	7402                	ld	s0,32(sp)
    80000a5c:	64e2                	ld	s1,24(sp)
    80000a5e:	6942                	ld	s2,16(sp)
    80000a60:	69a2                	ld	s3,8(sp)
    80000a62:	6145                	add	sp,sp,48
    80000a64:	8082                	ret
    panic("kfree");
    80000a66:	00007517          	auipc	a0,0x7
    80000a6a:	5fa50513          	add	a0,a0,1530 # 80008060 <digits+0x20>
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	ace080e7          	jalr	-1330(ra) # 8000053c <panic>
    arr[((uint64)pa) / 4096] = 0;
    80000a76:	078a                	sll	a5,a5,0x2
    80000a78:	00010717          	auipc	a4,0x10
    80000a7c:	10070713          	add	a4,a4,256 # 80010b78 <arr>
    80000a80:	97ba                	add	a5,a5,a4
    80000a82:	0007a023          	sw	zero,0(a5)
    release(&ref_lock);
    80000a86:	00010917          	auipc	s2,0x10
    80000a8a:	0ba90913          	add	s2,s2,186 # 80010b40 <ref_lock>
    80000a8e:	854a                	mv	a0,s2
    80000a90:	00000097          	auipc	ra,0x0
    80000a94:	2fe080e7          	jalr	766(ra) # 80000d8e <release>
    memset(pa, 1, PGSIZE);
    80000a98:	6605                	lui	a2,0x1
    80000a9a:	4585                	li	a1,1
    80000a9c:	8526                	mv	a0,s1
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	338080e7          	jalr	824(ra) # 80000dd6 <memset>
    acquire(&kmem.lock);
    80000aa6:	00010997          	auipc	s3,0x10
    80000aaa:	0b298993          	add	s3,s3,178 # 80010b58 <kmem>
    80000aae:	854e                	mv	a0,s3
    80000ab0:	00000097          	auipc	ra,0x0
    80000ab4:	22a080e7          	jalr	554(ra) # 80000cda <acquire>
    r->next = kmem.freelist;
    80000ab8:	03093783          	ld	a5,48(s2)
    80000abc:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000abe:	02993823          	sd	s1,48(s2)
    release(&kmem.lock);
    80000ac2:	854e                	mv	a0,s3
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	2ca080e7          	jalr	714(ra) # 80000d8e <release>
    80000acc:	b771                	j	80000a58 <kfree+0x74>

0000000080000ace <freerange>:
{
    80000ace:	715d                	add	sp,sp,-80
    80000ad0:	e486                	sd	ra,72(sp)
    80000ad2:	e0a2                	sd	s0,64(sp)
    80000ad4:	fc26                	sd	s1,56(sp)
    80000ad6:	f84a                	sd	s2,48(sp)
    80000ad8:	f44e                	sd	s3,40(sp)
    80000ada:	f052                	sd	s4,32(sp)
    80000adc:	ec56                	sd	s5,24(sp)
    80000ade:	e85a                	sd	s6,16(sp)
    80000ae0:	e45e                	sd	s7,8(sp)
    80000ae2:	0880                	add	s0,sp,80
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000ae4:	6785                	lui	a5,0x1
    80000ae6:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000aea:	953a                	add	a0,a0,a4
    80000aec:	777d                	lui	a4,0xfffff
    80000aee:	00e574b3          	and	s1,a0,a4
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000af2:	97a6                	add	a5,a5,s1
    80000af4:	04f5e863          	bltu	a1,a5,80000b44 <freerange+0x76>
    80000af8:	89ae                	mv	s3,a1
    acquire(&ref_lock);
    80000afa:	00010917          	auipc	s2,0x10
    80000afe:	04690913          	add	s2,s2,70 # 80010b40 <ref_lock>
    arr[((uint64)p) / 4096] = 1;
    80000b02:	00010b97          	auipc	s7,0x10
    80000b06:	076b8b93          	add	s7,s7,118 # 80010b78 <arr>
    80000b0a:	4b05                	li	s6,1
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b0c:	6a85                	lui	s5,0x1
    80000b0e:	6a09                	lui	s4,0x2
    acquire(&ref_lock);
    80000b10:	854a                	mv	a0,s2
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	1c8080e7          	jalr	456(ra) # 80000cda <acquire>
    arr[((uint64)p) / 4096] = 1;
    80000b1a:	00c4d793          	srl	a5,s1,0xc
    80000b1e:	078a                	sll	a5,a5,0x2
    80000b20:	97de                	add	a5,a5,s7
    80000b22:	0167a023          	sw	s6,0(a5)
    release(&ref_lock);
    80000b26:	854a                	mv	a0,s2
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	266080e7          	jalr	614(ra) # 80000d8e <release>
    kfree(p);
    80000b30:	8526                	mv	a0,s1
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	eb2080e7          	jalr	-334(ra) # 800009e4 <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b3a:	87a6                	mv	a5,s1
    80000b3c:	94d6                	add	s1,s1,s5
    80000b3e:	97d2                	add	a5,a5,s4
    80000b40:	fcf9f8e3          	bgeu	s3,a5,80000b10 <freerange+0x42>
}
    80000b44:	60a6                	ld	ra,72(sp)
    80000b46:	6406                	ld	s0,64(sp)
    80000b48:	74e2                	ld	s1,56(sp)
    80000b4a:	7942                	ld	s2,48(sp)
    80000b4c:	79a2                	ld	s3,40(sp)
    80000b4e:	7a02                	ld	s4,32(sp)
    80000b50:	6ae2                	ld	s5,24(sp)
    80000b52:	6b42                	ld	s6,16(sp)
    80000b54:	6ba2                	ld	s7,8(sp)
    80000b56:	6161                	add	sp,sp,80
    80000b58:	8082                	ret

0000000080000b5a <kinit>:
{
    80000b5a:	1141                	add	sp,sp,-16
    80000b5c:	e406                	sd	ra,8(sp)
    80000b5e:	e022                	sd	s0,0(sp)
    80000b60:	0800                	add	s0,sp,16
  initlock(&ref_lock, "ref_counter");
    80000b62:	00007597          	auipc	a1,0x7
    80000b66:	50658593          	add	a1,a1,1286 # 80008068 <digits+0x28>
    80000b6a:	00010517          	auipc	a0,0x10
    80000b6e:	fd650513          	add	a0,a0,-42 # 80010b40 <ref_lock>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	0d8080e7          	jalr	216(ra) # 80000c4a <initlock>
  initlock(&kmem.lock, "kmem");
    80000b7a:	00007597          	auipc	a1,0x7
    80000b7e:	4fe58593          	add	a1,a1,1278 # 80008078 <digits+0x38>
    80000b82:	00010517          	auipc	a0,0x10
    80000b86:	fd650513          	add	a0,a0,-42 # 80010b58 <kmem>
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	0c0080e7          	jalr	192(ra) # 80000c4a <initlock>
  freerange(end, (void *)PHYSTOP);
    80000b92:	45c5                	li	a1,17
    80000b94:	05ee                	sll	a1,a1,0x1b
    80000b96:	00242517          	auipc	a0,0x242
    80000b9a:	df250513          	add	a0,a0,-526 # 80242988 <end>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	f30080e7          	jalr	-208(ra) # 80000ace <freerange>
}
    80000ba6:	60a2                	ld	ra,8(sp)
    80000ba8:	6402                	ld	s0,0(sp)
    80000baa:	0141                	add	sp,sp,16
    80000bac:	8082                	ret

0000000080000bae <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bae:	1101                	add	sp,sp,-32
    80000bb0:	ec06                	sd	ra,24(sp)
    80000bb2:	e822                	sd	s0,16(sp)
    80000bb4:	e426                	sd	s1,8(sp)
    80000bb6:	e04a                	sd	s2,0(sp)
    80000bb8:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bba:	00010517          	auipc	a0,0x10
    80000bbe:	f9e50513          	add	a0,a0,-98 # 80010b58 <kmem>
    80000bc2:	00000097          	auipc	ra,0x0
    80000bc6:	118080e7          	jalr	280(ra) # 80000cda <acquire>
  r = kmem.freelist;
    80000bca:	00010497          	auipc	s1,0x10
    80000bce:	fa64b483          	ld	s1,-90(s1) # 80010b70 <kmem+0x18>
  if (r)
    80000bd2:	c0bd                	beqz	s1,80000c38 <kalloc+0x8a>
    kmem.freelist = r->next;
    80000bd4:	609c                	ld	a5,0(s1)
    80000bd6:	00010917          	auipc	s2,0x10
    80000bda:	f6a90913          	add	s2,s2,-150 # 80010b40 <ref_lock>
    80000bde:	02f93823          	sd	a5,48(s2)
  release(&kmem.lock);
    80000be2:	00010517          	auipc	a0,0x10
    80000be6:	f7650513          	add	a0,a0,-138 # 80010b58 <kmem>
    80000bea:	00000097          	auipc	ra,0x0
    80000bee:	1a4080e7          	jalr	420(ra) # 80000d8e <release>

  if (r)
  {
    memset((char *)r, 100, PGSIZE); // fill with junk
    80000bf2:	6605                	lui	a2,0x1
    80000bf4:	06400593          	li	a1,100
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	1dc080e7          	jalr	476(ra) # 80000dd6 <memset>
    acquire(&ref_lock);
    80000c02:	854a                	mv	a0,s2
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	0d6080e7          	jalr	214(ra) # 80000cda <acquire>
    arr[((uint64)r) / 4096] = 1;
    80000c0c:	00c4d713          	srl	a4,s1,0xc
    80000c10:	070a                	sll	a4,a4,0x2
    80000c12:	00010797          	auipc	a5,0x10
    80000c16:	f6678793          	add	a5,a5,-154 # 80010b78 <arr>
    80000c1a:	97ba                	add	a5,a5,a4
    80000c1c:	4705                	li	a4,1
    80000c1e:	c398                	sw	a4,0(a5)
    release(&ref_lock);
    80000c20:	854a                	mv	a0,s2
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	16c080e7          	jalr	364(ra) # 80000d8e <release>
  }
  return (void *)r;
    80000c2a:	8526                	mv	a0,s1
    80000c2c:	60e2                	ld	ra,24(sp)
    80000c2e:	6442                	ld	s0,16(sp)
    80000c30:	64a2                	ld	s1,8(sp)
    80000c32:	6902                	ld	s2,0(sp)
    80000c34:	6105                	add	sp,sp,32
    80000c36:	8082                	ret
  release(&kmem.lock);
    80000c38:	00010517          	auipc	a0,0x10
    80000c3c:	f2050513          	add	a0,a0,-224 # 80010b58 <kmem>
    80000c40:	00000097          	auipc	ra,0x0
    80000c44:	14e080e7          	jalr	334(ra) # 80000d8e <release>
  if (r)
    80000c48:	b7cd                	j	80000c2a <kalloc+0x7c>

0000000080000c4a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c4a:	1141                	add	sp,sp,-16
    80000c4c:	e422                	sd	s0,8(sp)
    80000c4e:	0800                	add	s0,sp,16
  lk->name = name;
    80000c50:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c52:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c56:	00053823          	sd	zero,16(a0)
}
    80000c5a:	6422                	ld	s0,8(sp)
    80000c5c:	0141                	add	sp,sp,16
    80000c5e:	8082                	ret

0000000080000c60 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c60:	411c                	lw	a5,0(a0)
    80000c62:	e399                	bnez	a5,80000c68 <holding+0x8>
    80000c64:	4501                	li	a0,0
  return r;
}
    80000c66:	8082                	ret
{
    80000c68:	1101                	add	sp,sp,-32
    80000c6a:	ec06                	sd	ra,24(sp)
    80000c6c:	e822                	sd	s0,16(sp)
    80000c6e:	e426                	sd	s1,8(sp)
    80000c70:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c72:	6904                	ld	s1,16(a0)
    80000c74:	00001097          	auipc	ra,0x1
    80000c78:	e84080e7          	jalr	-380(ra) # 80001af8 <mycpu>
    80000c7c:	40a48533          	sub	a0,s1,a0
    80000c80:	00153513          	seqz	a0,a0
}
    80000c84:	60e2                	ld	ra,24(sp)
    80000c86:	6442                	ld	s0,16(sp)
    80000c88:	64a2                	ld	s1,8(sp)
    80000c8a:	6105                	add	sp,sp,32
    80000c8c:	8082                	ret

0000000080000c8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c8e:	1101                	add	sp,sp,-32
    80000c90:	ec06                	sd	ra,24(sp)
    80000c92:	e822                	sd	s0,16(sp)
    80000c94:	e426                	sd	s1,8(sp)
    80000c96:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c98:	100024f3          	csrr	s1,sstatus
    80000c9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ca0:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ca6:	00001097          	auipc	ra,0x1
    80000caa:	e52080e7          	jalr	-430(ra) # 80001af8 <mycpu>
    80000cae:	5d3c                	lw	a5,120(a0)
    80000cb0:	cf89                	beqz	a5,80000cca <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cb2:	00001097          	auipc	ra,0x1
    80000cb6:	e46080e7          	jalr	-442(ra) # 80001af8 <mycpu>
    80000cba:	5d3c                	lw	a5,120(a0)
    80000cbc:	2785                	addw	a5,a5,1
    80000cbe:	dd3c                	sw	a5,120(a0)
}
    80000cc0:	60e2                	ld	ra,24(sp)
    80000cc2:	6442                	ld	s0,16(sp)
    80000cc4:	64a2                	ld	s1,8(sp)
    80000cc6:	6105                	add	sp,sp,32
    80000cc8:	8082                	ret
    mycpu()->intena = old;
    80000cca:	00001097          	auipc	ra,0x1
    80000cce:	e2e080e7          	jalr	-466(ra) # 80001af8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cd2:	8085                	srl	s1,s1,0x1
    80000cd4:	8885                	and	s1,s1,1
    80000cd6:	dd64                	sw	s1,124(a0)
    80000cd8:	bfe9                	j	80000cb2 <push_off+0x24>

0000000080000cda <acquire>:
{
    80000cda:	1101                	add	sp,sp,-32
    80000cdc:	ec06                	sd	ra,24(sp)
    80000cde:	e822                	sd	s0,16(sp)
    80000ce0:	e426                	sd	s1,8(sp)
    80000ce2:	1000                	add	s0,sp,32
    80000ce4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ce6:	00000097          	auipc	ra,0x0
    80000cea:	fa8080e7          	jalr	-88(ra) # 80000c8e <push_off>
  if(holding(lk))
    80000cee:	8526                	mv	a0,s1
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	f70080e7          	jalr	-144(ra) # 80000c60 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cf8:	4705                	li	a4,1
  if(holding(lk))
    80000cfa:	e115                	bnez	a0,80000d1e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cfc:	87ba                	mv	a5,a4
    80000cfe:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d02:	2781                	sext.w	a5,a5
    80000d04:	ffe5                	bnez	a5,80000cfc <acquire+0x22>
  __sync_synchronize();
    80000d06:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d0a:	00001097          	auipc	ra,0x1
    80000d0e:	dee080e7          	jalr	-530(ra) # 80001af8 <mycpu>
    80000d12:	e888                	sd	a0,16(s1)
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	add	sp,sp,32
    80000d1c:	8082                	ret
    panic("acquire");
    80000d1e:	00007517          	auipc	a0,0x7
    80000d22:	36250513          	add	a0,a0,866 # 80008080 <digits+0x40>
    80000d26:	00000097          	auipc	ra,0x0
    80000d2a:	816080e7          	jalr	-2026(ra) # 8000053c <panic>

0000000080000d2e <pop_off>:

void
pop_off(void)
{
    80000d2e:	1141                	add	sp,sp,-16
    80000d30:	e406                	sd	ra,8(sp)
    80000d32:	e022                	sd	s0,0(sp)
    80000d34:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000d36:	00001097          	auipc	ra,0x1
    80000d3a:	dc2080e7          	jalr	-574(ra) # 80001af8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d42:	8b89                	and	a5,a5,2
  if(intr_get())
    80000d44:	e78d                	bnez	a5,80000d6e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d46:	5d3c                	lw	a5,120(a0)
    80000d48:	02f05b63          	blez	a5,80000d7e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d4c:	37fd                	addw	a5,a5,-1
    80000d4e:	0007871b          	sext.w	a4,a5
    80000d52:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d54:	eb09                	bnez	a4,80000d66 <pop_off+0x38>
    80000d56:	5d7c                	lw	a5,124(a0)
    80000d58:	c799                	beqz	a5,80000d66 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d5e:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d62:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	add	sp,sp,16
    80000d6c:	8082                	ret
    panic("pop_off - interruptible");
    80000d6e:	00007517          	auipc	a0,0x7
    80000d72:	31a50513          	add	a0,a0,794 # 80008088 <digits+0x48>
    80000d76:	fffff097          	auipc	ra,0xfffff
    80000d7a:	7c6080e7          	jalr	1990(ra) # 8000053c <panic>
    panic("pop_off");
    80000d7e:	00007517          	auipc	a0,0x7
    80000d82:	32250513          	add	a0,a0,802 # 800080a0 <digits+0x60>
    80000d86:	fffff097          	auipc	ra,0xfffff
    80000d8a:	7b6080e7          	jalr	1974(ra) # 8000053c <panic>

0000000080000d8e <release>:
{
    80000d8e:	1101                	add	sp,sp,-32
    80000d90:	ec06                	sd	ra,24(sp)
    80000d92:	e822                	sd	s0,16(sp)
    80000d94:	e426                	sd	s1,8(sp)
    80000d96:	1000                	add	s0,sp,32
    80000d98:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d9a:	00000097          	auipc	ra,0x0
    80000d9e:	ec6080e7          	jalr	-314(ra) # 80000c60 <holding>
    80000da2:	c115                	beqz	a0,80000dc6 <release+0x38>
  lk->cpu = 0;
    80000da4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000da8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dac:	0f50000f          	fence	iorw,ow
    80000db0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000db4:	00000097          	auipc	ra,0x0
    80000db8:	f7a080e7          	jalr	-134(ra) # 80000d2e <pop_off>
}
    80000dbc:	60e2                	ld	ra,24(sp)
    80000dbe:	6442                	ld	s0,16(sp)
    80000dc0:	64a2                	ld	s1,8(sp)
    80000dc2:	6105                	add	sp,sp,32
    80000dc4:	8082                	ret
    panic("release");
    80000dc6:	00007517          	auipc	a0,0x7
    80000dca:	2e250513          	add	a0,a0,738 # 800080a8 <digits+0x68>
    80000dce:	fffff097          	auipc	ra,0xfffff
    80000dd2:	76e080e7          	jalr	1902(ra) # 8000053c <panic>

0000000080000dd6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dd6:	1141                	add	sp,sp,-16
    80000dd8:	e422                	sd	s0,8(sp)
    80000dda:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ddc:	ca19                	beqz	a2,80000df2 <memset+0x1c>
    80000dde:	87aa                	mv	a5,a0
    80000de0:	1602                	sll	a2,a2,0x20
    80000de2:	9201                	srl	a2,a2,0x20
    80000de4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000de8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dec:	0785                	add	a5,a5,1
    80000dee:	fee79de3          	bne	a5,a4,80000de8 <memset+0x12>
  }
  return dst;
}
    80000df2:	6422                	ld	s0,8(sp)
    80000df4:	0141                	add	sp,sp,16
    80000df6:	8082                	ret

0000000080000df8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000df8:	1141                	add	sp,sp,-16
    80000dfa:	e422                	sd	s0,8(sp)
    80000dfc:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dfe:	ca05                	beqz	a2,80000e2e <memcmp+0x36>
    80000e00:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e04:	1682                	sll	a3,a3,0x20
    80000e06:	9281                	srl	a3,a3,0x20
    80000e08:	0685                	add	a3,a3,1
    80000e0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	0005c703          	lbu	a4,0(a1)
    80000e14:	00e79863          	bne	a5,a4,80000e24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e18:	0505                	add	a0,a0,1
    80000e1a:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000e1c:	fed518e3          	bne	a0,a3,80000e0c <memcmp+0x14>
  }

  return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	a019                	j	80000e28 <memcmp+0x30>
      return *s1 - *s2;
    80000e24:	40e7853b          	subw	a0,a5,a4
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	add	sp,sp,16
    80000e2c:	8082                	ret
  return 0;
    80000e2e:	4501                	li	a0,0
    80000e30:	bfe5                	j	80000e28 <memcmp+0x30>

0000000080000e32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e32:	1141                	add	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e38:	c205                	beqz	a2,80000e58 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e3a:	02a5e263          	bltu	a1,a0,80000e5e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e3e:	1602                	sll	a2,a2,0x20
    80000e40:	9201                	srl	a2,a2,0x20
    80000e42:	00c587b3          	add	a5,a1,a2
{
    80000e46:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e48:	0585                	add	a1,a1,1
    80000e4a:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fdbc679>
    80000e4c:	fff5c683          	lbu	a3,-1(a1)
    80000e50:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e54:	fef59ae3          	bne	a1,a5,80000e48 <memmove+0x16>

  return dst;
}
    80000e58:	6422                	ld	s0,8(sp)
    80000e5a:	0141                	add	sp,sp,16
    80000e5c:	8082                	ret
  if(s < d && s + n > d){
    80000e5e:	02061693          	sll	a3,a2,0x20
    80000e62:	9281                	srl	a3,a3,0x20
    80000e64:	00d58733          	add	a4,a1,a3
    80000e68:	fce57be3          	bgeu	a0,a4,80000e3e <memmove+0xc>
    d += n;
    80000e6c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e6e:	fff6079b          	addw	a5,a2,-1
    80000e72:	1782                	sll	a5,a5,0x20
    80000e74:	9381                	srl	a5,a5,0x20
    80000e76:	fff7c793          	not	a5,a5
    80000e7a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e7c:	177d                	add	a4,a4,-1
    80000e7e:	16fd                	add	a3,a3,-1
    80000e80:	00074603          	lbu	a2,0(a4)
    80000e84:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e88:	fee79ae3          	bne	a5,a4,80000e7c <memmove+0x4a>
    80000e8c:	b7f1                	j	80000e58 <memmove+0x26>

0000000080000e8e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e8e:	1141                	add	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000e96:	00000097          	auipc	ra,0x0
    80000e9a:	f9c080e7          	jalr	-100(ra) # 80000e32 <memmove>
}
    80000e9e:	60a2                	ld	ra,8(sp)
    80000ea0:	6402                	ld	s0,0(sp)
    80000ea2:	0141                	add	sp,sp,16
    80000ea4:	8082                	ret

0000000080000ea6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ea6:	1141                	add	sp,sp,-16
    80000ea8:	e422                	sd	s0,8(sp)
    80000eaa:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eac:	ce11                	beqz	a2,80000ec8 <strncmp+0x22>
    80000eae:	00054783          	lbu	a5,0(a0)
    80000eb2:	cf89                	beqz	a5,80000ecc <strncmp+0x26>
    80000eb4:	0005c703          	lbu	a4,0(a1)
    80000eb8:	00f71a63          	bne	a4,a5,80000ecc <strncmp+0x26>
    n--, p++, q++;
    80000ebc:	367d                	addw	a2,a2,-1
    80000ebe:	0505                	add	a0,a0,1
    80000ec0:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ec2:	f675                	bnez	a2,80000eae <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ec4:	4501                	li	a0,0
    80000ec6:	a809                	j	80000ed8 <strncmp+0x32>
    80000ec8:	4501                	li	a0,0
    80000eca:	a039                	j	80000ed8 <strncmp+0x32>
  if(n == 0)
    80000ecc:	ca09                	beqz	a2,80000ede <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ece:	00054503          	lbu	a0,0(a0)
    80000ed2:	0005c783          	lbu	a5,0(a1)
    80000ed6:	9d1d                	subw	a0,a0,a5
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	add	sp,sp,16
    80000edc:	8082                	ret
    return 0;
    80000ede:	4501                	li	a0,0
    80000ee0:	bfe5                	j	80000ed8 <strncmp+0x32>

0000000080000ee2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ee2:	1141                	add	sp,sp,-16
    80000ee4:	e422                	sd	s0,8(sp)
    80000ee6:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ee8:	87aa                	mv	a5,a0
    80000eea:	86b2                	mv	a3,a2
    80000eec:	367d                	addw	a2,a2,-1
    80000eee:	00d05963          	blez	a3,80000f00 <strncpy+0x1e>
    80000ef2:	0785                	add	a5,a5,1
    80000ef4:	0005c703          	lbu	a4,0(a1)
    80000ef8:	fee78fa3          	sb	a4,-1(a5)
    80000efc:	0585                	add	a1,a1,1
    80000efe:	f775                	bnez	a4,80000eea <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f00:	873e                	mv	a4,a5
    80000f02:	9fb5                	addw	a5,a5,a3
    80000f04:	37fd                	addw	a5,a5,-1
    80000f06:	00c05963          	blez	a2,80000f18 <strncpy+0x36>
    *s++ = 0;
    80000f0a:	0705                	add	a4,a4,1
    80000f0c:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000f10:	40e786bb          	subw	a3,a5,a4
    80000f14:	fed04be3          	bgtz	a3,80000f0a <strncpy+0x28>
  return os;
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	add	sp,sp,16
    80000f1c:	8082                	ret

0000000080000f1e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f1e:	1141                	add	sp,sp,-16
    80000f20:	e422                	sd	s0,8(sp)
    80000f22:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f24:	02c05363          	blez	a2,80000f4a <safestrcpy+0x2c>
    80000f28:	fff6069b          	addw	a3,a2,-1
    80000f2c:	1682                	sll	a3,a3,0x20
    80000f2e:	9281                	srl	a3,a3,0x20
    80000f30:	96ae                	add	a3,a3,a1
    80000f32:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f34:	00d58963          	beq	a1,a3,80000f46 <safestrcpy+0x28>
    80000f38:	0585                	add	a1,a1,1
    80000f3a:	0785                	add	a5,a5,1
    80000f3c:	fff5c703          	lbu	a4,-1(a1)
    80000f40:	fee78fa3          	sb	a4,-1(a5)
    80000f44:	fb65                	bnez	a4,80000f34 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f46:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f4a:	6422                	ld	s0,8(sp)
    80000f4c:	0141                	add	sp,sp,16
    80000f4e:	8082                	ret

0000000080000f50 <strlen>:

int
strlen(const char *s)
{
    80000f50:	1141                	add	sp,sp,-16
    80000f52:	e422                	sd	s0,8(sp)
    80000f54:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f56:	00054783          	lbu	a5,0(a0)
    80000f5a:	cf91                	beqz	a5,80000f76 <strlen+0x26>
    80000f5c:	0505                	add	a0,a0,1
    80000f5e:	87aa                	mv	a5,a0
    80000f60:	86be                	mv	a3,a5
    80000f62:	0785                	add	a5,a5,1
    80000f64:	fff7c703          	lbu	a4,-1(a5)
    80000f68:	ff65                	bnez	a4,80000f60 <strlen+0x10>
    80000f6a:	40a6853b          	subw	a0,a3,a0
    80000f6e:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000f70:	6422                	ld	s0,8(sp)
    80000f72:	0141                	add	sp,sp,16
    80000f74:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f76:	4501                	li	a0,0
    80000f78:	bfe5                	j	80000f70 <strlen+0x20>

0000000080000f7a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f7a:	1141                	add	sp,sp,-16
    80000f7c:	e406                	sd	ra,8(sp)
    80000f7e:	e022                	sd	s0,0(sp)
    80000f80:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	b66080e7          	jalr	-1178(ra) # 80001ae8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f8a:	00008717          	auipc	a4,0x8
    80000f8e:	94e70713          	add	a4,a4,-1714 # 800088d8 <started>
  if(cpuid() == 0){
    80000f92:	c139                	beqz	a0,80000fd8 <main+0x5e>
    while(started == 0)
    80000f94:	431c                	lw	a5,0(a4)
    80000f96:	2781                	sext.w	a5,a5
    80000f98:	dff5                	beqz	a5,80000f94 <main+0x1a>
      ;
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	b4a080e7          	jalr	-1206(ra) # 80001ae8 <cpuid>
    80000fa6:	85aa                	mv	a1,a0
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	12050513          	add	a0,a0,288 # 800080c8 <digits+0x88>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5d6080e7          	jalr	1494(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000fb8:	00000097          	auipc	ra,0x0
    80000fbc:	0d8080e7          	jalr	216(ra) # 80001090 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fc0:	00002097          	auipc	ra,0x2
    80000fc4:	bfc080e7          	jalr	-1028(ra) # 80002bbc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fc8:	00005097          	auipc	ra,0x5
    80000fcc:	338080e7          	jalr	824(ra) # 80006300 <plicinithart>
  }

  scheduler();        
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	0ec080e7          	jalr	236(ra) # 800020bc <scheduler>
    consoleinit();
    80000fd8:	fffff097          	auipc	ra,0xfffff
    80000fdc:	474080e7          	jalr	1140(ra) # 8000044c <consoleinit>
    printfinit();
    80000fe0:	fffff097          	auipc	ra,0xfffff
    80000fe4:	786080e7          	jalr	1926(ra) # 80000766 <printfinit>
    printf("\n");
    80000fe8:	00007517          	auipc	a0,0x7
    80000fec:	0f050513          	add	a0,a0,240 # 800080d8 <digits+0x98>
    80000ff0:	fffff097          	auipc	ra,0xfffff
    80000ff4:	596080e7          	jalr	1430(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0b850513          	add	a0,a0,184 # 800080b0 <digits+0x70>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	586080e7          	jalr	1414(ra) # 80000586 <printf>
    printf("\n");
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	0d050513          	add	a0,a0,208 # 800080d8 <digits+0x98>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	576080e7          	jalr	1398(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80001018:	00000097          	auipc	ra,0x0
    8000101c:	b42080e7          	jalr	-1214(ra) # 80000b5a <kinit>
    kvminit();       // create kernel page table
    80001020:	00000097          	auipc	ra,0x0
    80001024:	326080e7          	jalr	806(ra) # 80001346 <kvminit>
    kvminithart();   // turn on paging
    80001028:	00000097          	auipc	ra,0x0
    8000102c:	068080e7          	jalr	104(ra) # 80001090 <kvminithart>
    procinit();      // process table
    80001030:	00001097          	auipc	ra,0x1
    80001034:	a04080e7          	jalr	-1532(ra) # 80001a34 <procinit>
    trapinit();      // trap vectors
    80001038:	00002097          	auipc	ra,0x2
    8000103c:	b5c080e7          	jalr	-1188(ra) # 80002b94 <trapinit>
    trapinithart();  // install kernel trap vector
    80001040:	00002097          	auipc	ra,0x2
    80001044:	b7c080e7          	jalr	-1156(ra) # 80002bbc <trapinithart>
    plicinit();      // set up interrupt controller
    80001048:	00005097          	auipc	ra,0x5
    8000104c:	2a2080e7          	jalr	674(ra) # 800062ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001050:	00005097          	auipc	ra,0x5
    80001054:	2b0080e7          	jalr	688(ra) # 80006300 <plicinithart>
    binit();         // buffer cache
    80001058:	00002097          	auipc	ra,0x2
    8000105c:	484080e7          	jalr	1156(ra) # 800034dc <binit>
    iinit();         // inode table
    80001060:	00003097          	auipc	ra,0x3
    80001064:	b22080e7          	jalr	-1246(ra) # 80003b82 <iinit>
    fileinit();      // file table
    80001068:	00004097          	auipc	ra,0x4
    8000106c:	a98080e7          	jalr	-1384(ra) # 80004b00 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001070:	00005097          	auipc	ra,0x5
    80001074:	398080e7          	jalr	920(ra) # 80006408 <virtio_disk_init>
    userinit();      // first user process
    80001078:	00001097          	auipc	ra,0x1
    8000107c:	db4080e7          	jalr	-588(ra) # 80001e2c <userinit>
    __sync_synchronize();
    80001080:	0ff0000f          	fence
    started = 1;
    80001084:	4785                	li	a5,1
    80001086:	00008717          	auipc	a4,0x8
    8000108a:	84f72923          	sw	a5,-1966(a4) # 800088d8 <started>
    8000108e:	b789                	j	80000fd0 <main+0x56>

0000000080001090 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80001090:	1141                	add	sp,sp,-16
    80001092:	e422                	sd	s0,8(sp)
    80001094:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001096:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000109a:	00008797          	auipc	a5,0x8
    8000109e:	8467b783          	ld	a5,-1978(a5) # 800088e0 <kernel_pagetable>
    800010a2:	83b1                	srl	a5,a5,0xc
    800010a4:	577d                	li	a4,-1
    800010a6:	177e                	sll	a4,a4,0x3f
    800010a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010aa:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010ae:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010b2:	6422                	ld	s0,8(sp)
    800010b4:	0141                	add	sp,sp,16
    800010b6:	8082                	ret

00000000800010b8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010b8:	7139                	add	sp,sp,-64
    800010ba:	fc06                	sd	ra,56(sp)
    800010bc:	f822                	sd	s0,48(sp)
    800010be:	f426                	sd	s1,40(sp)
    800010c0:	f04a                	sd	s2,32(sp)
    800010c2:	ec4e                	sd	s3,24(sp)
    800010c4:	e852                	sd	s4,16(sp)
    800010c6:	e456                	sd	s5,8(sp)
    800010c8:	e05a                	sd	s6,0(sp)
    800010ca:	0080                	add	s0,sp,64
    800010cc:	84aa                	mv	s1,a0
    800010ce:	89ae                	mv	s3,a1
    800010d0:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    800010d2:	57fd                	li	a5,-1
    800010d4:	83e9                	srl	a5,a5,0x1a
    800010d6:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    800010d8:	4b31                	li	s6,12
  if (va >= MAXVA)
    800010da:	04b7f263          	bgeu	a5,a1,8000111e <walk+0x66>
    panic("walk");
    800010de:	00007517          	auipc	a0,0x7
    800010e2:	00250513          	add	a0,a0,2 # 800080e0 <digits+0xa0>
    800010e6:	fffff097          	auipc	ra,0xfffff
    800010ea:	456080e7          	jalr	1110(ra) # 8000053c <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    800010ee:	060a8663          	beqz	s5,8000115a <walk+0xa2>
    800010f2:	00000097          	auipc	ra,0x0
    800010f6:	abc080e7          	jalr	-1348(ra) # 80000bae <kalloc>
    800010fa:	84aa                	mv	s1,a0
    800010fc:	c529                	beqz	a0,80001146 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010fe:	6605                	lui	a2,0x1
    80001100:	4581                	li	a1,0
    80001102:	00000097          	auipc	ra,0x0
    80001106:	cd4080e7          	jalr	-812(ra) # 80000dd6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000110a:	00c4d793          	srl	a5,s1,0xc
    8000110e:	07aa                	sll	a5,a5,0xa
    80001110:	0017e793          	or	a5,a5,1
    80001114:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    80001118:	3a5d                	addw	s4,s4,-9 # 1ff7 <_entry-0x7fffe009>
    8000111a:	036a0063          	beq	s4,s6,8000113a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000111e:	0149d933          	srl	s2,s3,s4
    80001122:	1ff97913          	and	s2,s2,511
    80001126:	090e                	sll	s2,s2,0x3
    80001128:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    8000112a:	00093483          	ld	s1,0(s2)
    8000112e:	0014f793          	and	a5,s1,1
    80001132:	dfd5                	beqz	a5,800010ee <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001134:	80a9                	srl	s1,s1,0xa
    80001136:	04b2                	sll	s1,s1,0xc
    80001138:	b7c5                	j	80001118 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000113a:	00c9d513          	srl	a0,s3,0xc
    8000113e:	1ff57513          	and	a0,a0,511
    80001142:	050e                	sll	a0,a0,0x3
    80001144:	9526                	add	a0,a0,s1
}
    80001146:	70e2                	ld	ra,56(sp)
    80001148:	7442                	ld	s0,48(sp)
    8000114a:	74a2                	ld	s1,40(sp)
    8000114c:	7902                	ld	s2,32(sp)
    8000114e:	69e2                	ld	s3,24(sp)
    80001150:	6a42                	ld	s4,16(sp)
    80001152:	6aa2                	ld	s5,8(sp)
    80001154:	6b02                	ld	s6,0(sp)
    80001156:	6121                	add	sp,sp,64
    80001158:	8082                	ret
        return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7ed                	j	80001146 <walk+0x8e>

000000008000115e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    8000115e:	57fd                	li	a5,-1
    80001160:	83e9                	srl	a5,a5,0x1a
    80001162:	00b7f463          	bgeu	a5,a1,8000116a <walkaddr+0xc>
    return 0;
    80001166:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001168:	8082                	ret
{
    8000116a:	1141                	add	sp,sp,-16
    8000116c:	e406                	sd	ra,8(sp)
    8000116e:	e022                	sd	s0,0(sp)
    80001170:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001172:	4601                	li	a2,0
    80001174:	00000097          	auipc	ra,0x0
    80001178:	f44080e7          	jalr	-188(ra) # 800010b8 <walk>
  if (pte == 0)
    8000117c:	c105                	beqz	a0,8000119c <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    8000117e:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    80001180:	0117f693          	and	a3,a5,17
    80001184:	4745                	li	a4,17
    return 0;
    80001186:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001188:	00e68663          	beq	a3,a4,80001194 <walkaddr+0x36>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	add	sp,sp,16
    80001192:	8082                	ret
  pa = PTE2PA(*pte);
    80001194:	83a9                	srl	a5,a5,0xa
    80001196:	00c79513          	sll	a0,a5,0xc
  return pa;
    8000119a:	bfcd                	j	8000118c <walkaddr+0x2e>
    return 0;
    8000119c:	4501                	li	a0,0
    8000119e:	b7fd                	j	8000118c <walkaddr+0x2e>

00000000800011a0 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011a0:	715d                	add	sp,sp,-80
    800011a2:	e486                	sd	ra,72(sp)
    800011a4:	e0a2                	sd	s0,64(sp)
    800011a6:	fc26                	sd	s1,56(sp)
    800011a8:	f84a                	sd	s2,48(sp)
    800011aa:	f44e                	sd	s3,40(sp)
    800011ac:	f052                	sd	s4,32(sp)
    800011ae:	ec56                	sd	s5,24(sp)
    800011b0:	e85a                	sd	s6,16(sp)
    800011b2:	e45e                	sd	s7,8(sp)
    800011b4:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    800011b6:	c639                	beqz	a2,80001204 <mappages+0x64>
    800011b8:	8aaa                	mv	s5,a0
    800011ba:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    800011bc:	777d                	lui	a4,0xfffff
    800011be:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011c2:	fff58993          	add	s3,a1,-1
    800011c6:	99b2                	add	s3,s3,a2
    800011c8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011cc:	893e                	mv	s2,a5
    800011ce:	40f68a33          	sub	s4,a3,a5
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    800011d2:	6b85                	lui	s7,0x1
    800011d4:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    800011d8:	4605                	li	a2,1
    800011da:	85ca                	mv	a1,s2
    800011dc:	8556                	mv	a0,s5
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	eda080e7          	jalr	-294(ra) # 800010b8 <walk>
    800011e6:	cd1d                	beqz	a0,80001224 <mappages+0x84>
    if (*pte & PTE_V)
    800011e8:	611c                	ld	a5,0(a0)
    800011ea:	8b85                	and	a5,a5,1
    800011ec:	e785                	bnez	a5,80001214 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ee:	80b1                	srl	s1,s1,0xc
    800011f0:	04aa                	sll	s1,s1,0xa
    800011f2:	0164e4b3          	or	s1,s1,s6
    800011f6:	0014e493          	or	s1,s1,1
    800011fa:	e104                	sd	s1,0(a0)
    if (a == last)
    800011fc:	05390063          	beq	s2,s3,8000123c <mappages+0x9c>
    a += PGSIZE;
    80001200:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001202:	bfc9                	j	800011d4 <mappages+0x34>
    panic("mappages: size");
    80001204:	00007517          	auipc	a0,0x7
    80001208:	ee450513          	add	a0,a0,-284 # 800080e8 <digits+0xa8>
    8000120c:	fffff097          	auipc	ra,0xfffff
    80001210:	330080e7          	jalr	816(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001214:	00007517          	auipc	a0,0x7
    80001218:	ee450513          	add	a0,a0,-284 # 800080f8 <digits+0xb8>
    8000121c:	fffff097          	auipc	ra,0xfffff
    80001220:	320080e7          	jalr	800(ra) # 8000053c <panic>
      return -1;
    80001224:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001226:	60a6                	ld	ra,72(sp)
    80001228:	6406                	ld	s0,64(sp)
    8000122a:	74e2                	ld	s1,56(sp)
    8000122c:	7942                	ld	s2,48(sp)
    8000122e:	79a2                	ld	s3,40(sp)
    80001230:	7a02                	ld	s4,32(sp)
    80001232:	6ae2                	ld	s5,24(sp)
    80001234:	6b42                	ld	s6,16(sp)
    80001236:	6ba2                	ld	s7,8(sp)
    80001238:	6161                	add	sp,sp,80
    8000123a:	8082                	ret
  return 0;
    8000123c:	4501                	li	a0,0
    8000123e:	b7e5                	j	80001226 <mappages+0x86>

0000000080001240 <kvmmap>:
{
    80001240:	1141                	add	sp,sp,-16
    80001242:	e406                	sd	ra,8(sp)
    80001244:	e022                	sd	s0,0(sp)
    80001246:	0800                	add	s0,sp,16
    80001248:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000124a:	86b2                	mv	a3,a2
    8000124c:	863e                	mv	a2,a5
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	f52080e7          	jalr	-174(ra) # 800011a0 <mappages>
    80001256:	e509                	bnez	a0,80001260 <kvmmap+0x20>
}
    80001258:	60a2                	ld	ra,8(sp)
    8000125a:	6402                	ld	s0,0(sp)
    8000125c:	0141                	add	sp,sp,16
    8000125e:	8082                	ret
    panic("kvmmap");
    80001260:	00007517          	auipc	a0,0x7
    80001264:	ea850513          	add	a0,a0,-344 # 80008108 <digits+0xc8>
    80001268:	fffff097          	auipc	ra,0xfffff
    8000126c:	2d4080e7          	jalr	724(ra) # 8000053c <panic>

0000000080001270 <kvmmake>:
{
    80001270:	1101                	add	sp,sp,-32
    80001272:	ec06                	sd	ra,24(sp)
    80001274:	e822                	sd	s0,16(sp)
    80001276:	e426                	sd	s1,8(sp)
    80001278:	e04a                	sd	s2,0(sp)
    8000127a:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	932080e7          	jalr	-1742(ra) # 80000bae <kalloc>
    80001284:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001286:	6605                	lui	a2,0x1
    80001288:	4581                	li	a1,0
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	b4c080e7          	jalr	-1204(ra) # 80000dd6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001292:	4719                	li	a4,6
    80001294:	6685                	lui	a3,0x1
    80001296:	10000637          	lui	a2,0x10000
    8000129a:	100005b7          	lui	a1,0x10000
    8000129e:	8526                	mv	a0,s1
    800012a0:	00000097          	auipc	ra,0x0
    800012a4:	fa0080e7          	jalr	-96(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012a8:	4719                	li	a4,6
    800012aa:	6685                	lui	a3,0x1
    800012ac:	10001637          	lui	a2,0x10001
    800012b0:	100015b7          	lui	a1,0x10001
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f8a080e7          	jalr	-118(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012be:	4719                	li	a4,6
    800012c0:	004006b7          	lui	a3,0x400
    800012c4:	0c000637          	lui	a2,0xc000
    800012c8:	0c0005b7          	lui	a1,0xc000
    800012cc:	8526                	mv	a0,s1
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	f72080e7          	jalr	-142(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800012d6:	00007917          	auipc	s2,0x7
    800012da:	d2a90913          	add	s2,s2,-726 # 80008000 <etext>
    800012de:	4729                	li	a4,10
    800012e0:	80007697          	auipc	a3,0x80007
    800012e4:	d2068693          	add	a3,a3,-736 # 8000 <_entry-0x7fff8000>
    800012e8:	4605                	li	a2,1
    800012ea:	067e                	sll	a2,a2,0x1f
    800012ec:	85b2                	mv	a1,a2
    800012ee:	8526                	mv	a0,s1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	f50080e7          	jalr	-176(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800012f8:	4719                	li	a4,6
    800012fa:	46c5                	li	a3,17
    800012fc:	06ee                	sll	a3,a3,0x1b
    800012fe:	412686b3          	sub	a3,a3,s2
    80001302:	864a                	mv	a2,s2
    80001304:	85ca                	mv	a1,s2
    80001306:	8526                	mv	a0,s1
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	f38080e7          	jalr	-200(ra) # 80001240 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001310:	4729                	li	a4,10
    80001312:	6685                	lui	a3,0x1
    80001314:	00006617          	auipc	a2,0x6
    80001318:	cec60613          	add	a2,a2,-788 # 80007000 <_trampoline>
    8000131c:	040005b7          	lui	a1,0x4000
    80001320:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001322:	05b2                	sll	a1,a1,0xc
    80001324:	8526                	mv	a0,s1
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	f1a080e7          	jalr	-230(ra) # 80001240 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000132e:	8526                	mv	a0,s1
    80001330:	00000097          	auipc	ra,0x0
    80001334:	66e080e7          	jalr	1646(ra) # 8000199e <proc_mapstacks>
}
    80001338:	8526                	mv	a0,s1
    8000133a:	60e2                	ld	ra,24(sp)
    8000133c:	6442                	ld	s0,16(sp)
    8000133e:	64a2                	ld	s1,8(sp)
    80001340:	6902                	ld	s2,0(sp)
    80001342:	6105                	add	sp,sp,32
    80001344:	8082                	ret

0000000080001346 <kvminit>:
{
    80001346:	1141                	add	sp,sp,-16
    80001348:	e406                	sd	ra,8(sp)
    8000134a:	e022                	sd	s0,0(sp)
    8000134c:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	f22080e7          	jalr	-222(ra) # 80001270 <kvmmake>
    80001356:	00007797          	auipc	a5,0x7
    8000135a:	58a7b523          	sd	a0,1418(a5) # 800088e0 <kernel_pagetable>
}
    8000135e:	60a2                	ld	ra,8(sp)
    80001360:	6402                	ld	s0,0(sp)
    80001362:	0141                	add	sp,sp,16
    80001364:	8082                	ret

0000000080001366 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001366:	715d                	add	sp,sp,-80
    80001368:	e486                	sd	ra,72(sp)
    8000136a:	e0a2                	sd	s0,64(sp)
    8000136c:	fc26                	sd	s1,56(sp)
    8000136e:	f84a                	sd	s2,48(sp)
    80001370:	f44e                	sd	s3,40(sp)
    80001372:	f052                	sd	s4,32(sp)
    80001374:	ec56                	sd	s5,24(sp)
    80001376:	e85a                	sd	s6,16(sp)
    80001378:	e45e                	sd	s7,8(sp)
    8000137a:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    8000137c:	03459793          	sll	a5,a1,0x34
    80001380:	e795                	bnez	a5,800013ac <uvmunmap+0x46>
    80001382:	8a2a                	mv	s4,a0
    80001384:	892e                	mv	s2,a1
    80001386:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001388:	0632                	sll	a2,a2,0xc
    8000138a:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    8000138e:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001390:	6b05                	lui	s6,0x1
    80001392:	0735e263          	bltu	a1,s3,800013f6 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    80001396:	60a6                	ld	ra,72(sp)
    80001398:	6406                	ld	s0,64(sp)
    8000139a:	74e2                	ld	s1,56(sp)
    8000139c:	7942                	ld	s2,48(sp)
    8000139e:	79a2                	ld	s3,40(sp)
    800013a0:	7a02                	ld	s4,32(sp)
    800013a2:	6ae2                	ld	s5,24(sp)
    800013a4:	6b42                	ld	s6,16(sp)
    800013a6:	6ba2                	ld	s7,8(sp)
    800013a8:	6161                	add	sp,sp,80
    800013aa:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ac:	00007517          	auipc	a0,0x7
    800013b0:	d6450513          	add	a0,a0,-668 # 80008110 <digits+0xd0>
    800013b4:	fffff097          	auipc	ra,0xfffff
    800013b8:	188080e7          	jalr	392(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800013bc:	00007517          	auipc	a0,0x7
    800013c0:	d6c50513          	add	a0,a0,-660 # 80008128 <digits+0xe8>
    800013c4:	fffff097          	auipc	ra,0xfffff
    800013c8:	178080e7          	jalr	376(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800013cc:	00007517          	auipc	a0,0x7
    800013d0:	d6c50513          	add	a0,a0,-660 # 80008138 <digits+0xf8>
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	168080e7          	jalr	360(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800013dc:	00007517          	auipc	a0,0x7
    800013e0:	d7450513          	add	a0,a0,-652 # 80008150 <digits+0x110>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	158080e7          	jalr	344(ra) # 8000053c <panic>
    *pte = 0;
    800013ec:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013f0:	995a                	add	s2,s2,s6
    800013f2:	fb3972e3          	bgeu	s2,s3,80001396 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    800013f6:	4601                	li	a2,0
    800013f8:	85ca                	mv	a1,s2
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	cbc080e7          	jalr	-836(ra) # 800010b8 <walk>
    80001404:	84aa                	mv	s1,a0
    80001406:	d95d                	beqz	a0,800013bc <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    80001408:	6108                	ld	a0,0(a0)
    8000140a:	00157793          	and	a5,a0,1
    8000140e:	dfdd                	beqz	a5,800013cc <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001410:	3ff57793          	and	a5,a0,1023
    80001414:	fd7784e3          	beq	a5,s7,800013dc <uvmunmap+0x76>
    if (do_free)
    80001418:	fc0a8ae3          	beqz	s5,800013ec <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000141c:	8129                	srl	a0,a0,0xa
      kfree((void *)pa);
    8000141e:	0532                	sll	a0,a0,0xc
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	5c4080e7          	jalr	1476(ra) # 800009e4 <kfree>
    80001428:	b7d1                	j	800013ec <uvmunmap+0x86>

000000008000142a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000142a:	1101                	add	sp,sp,-32
    8000142c:	ec06                	sd	ra,24(sp)
    8000142e:	e822                	sd	s0,16(sp)
    80001430:	e426                	sd	s1,8(sp)
    80001432:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	77a080e7          	jalr	1914(ra) # 80000bae <kalloc>
    8000143c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    8000143e:	c519                	beqz	a0,8000144c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001440:	6605                	lui	a2,0x1
    80001442:	4581                	li	a1,0
    80001444:	00000097          	auipc	ra,0x0
    80001448:	992080e7          	jalr	-1646(ra) # 80000dd6 <memset>
  return pagetable;
}
    8000144c:	8526                	mv	a0,s1
    8000144e:	60e2                	ld	ra,24(sp)
    80001450:	6442                	ld	s0,16(sp)
    80001452:	64a2                	ld	s1,8(sp)
    80001454:	6105                	add	sp,sp,32
    80001456:	8082                	ret

0000000080001458 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001458:	7179                	add	sp,sp,-48
    8000145a:	f406                	sd	ra,40(sp)
    8000145c:	f022                	sd	s0,32(sp)
    8000145e:	ec26                	sd	s1,24(sp)
    80001460:	e84a                	sd	s2,16(sp)
    80001462:	e44e                	sd	s3,8(sp)
    80001464:	e052                	sd	s4,0(sp)
    80001466:	1800                	add	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001468:	6785                	lui	a5,0x1
    8000146a:	04f67863          	bgeu	a2,a5,800014ba <uvmfirst+0x62>
    8000146e:	8a2a                	mv	s4,a0
    80001470:	89ae                	mv	s3,a1
    80001472:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001474:	fffff097          	auipc	ra,0xfffff
    80001478:	73a080e7          	jalr	1850(ra) # 80000bae <kalloc>
    8000147c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000147e:	6605                	lui	a2,0x1
    80001480:	4581                	li	a1,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	954080e7          	jalr	-1708(ra) # 80000dd6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    8000148a:	4779                	li	a4,30
    8000148c:	86ca                	mv	a3,s2
    8000148e:	6605                	lui	a2,0x1
    80001490:	4581                	li	a1,0
    80001492:	8552                	mv	a0,s4
    80001494:	00000097          	auipc	ra,0x0
    80001498:	d0c080e7          	jalr	-756(ra) # 800011a0 <mappages>
  memmove(mem, src, sz);
    8000149c:	8626                	mv	a2,s1
    8000149e:	85ce                	mv	a1,s3
    800014a0:	854a                	mv	a0,s2
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	990080e7          	jalr	-1648(ra) # 80000e32 <memmove>
}
    800014aa:	70a2                	ld	ra,40(sp)
    800014ac:	7402                	ld	s0,32(sp)
    800014ae:	64e2                	ld	s1,24(sp)
    800014b0:	6942                	ld	s2,16(sp)
    800014b2:	69a2                	ld	s3,8(sp)
    800014b4:	6a02                	ld	s4,0(sp)
    800014b6:	6145                	add	sp,sp,48
    800014b8:	8082                	ret
    panic("uvmfirst: more than a page");
    800014ba:	00007517          	auipc	a0,0x7
    800014be:	cae50513          	add	a0,a0,-850 # 80008168 <digits+0x128>
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	07a080e7          	jalr	122(ra) # 8000053c <panic>

00000000800014ca <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014ca:	1101                	add	sp,sp,-32
    800014cc:	ec06                	sd	ra,24(sp)
    800014ce:	e822                	sd	s0,16(sp)
    800014d0:	e426                	sd	s1,8(sp)
    800014d2:	1000                	add	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    800014d4:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    800014d6:	00b67d63          	bgeu	a2,a1,800014f0 <uvmdealloc+0x26>
    800014da:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    800014dc:	6785                	lui	a5,0x1
    800014de:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014e0:	00f60733          	add	a4,a2,a5
    800014e4:	76fd                	lui	a3,0xfffff
    800014e6:	8f75                	and	a4,a4,a3
    800014e8:	97ae                	add	a5,a5,a1
    800014ea:	8ff5                	and	a5,a5,a3
    800014ec:	00f76863          	bltu	a4,a5,800014fc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014f0:	8526                	mv	a0,s1
    800014f2:	60e2                	ld	ra,24(sp)
    800014f4:	6442                	ld	s0,16(sp)
    800014f6:	64a2                	ld	s1,8(sp)
    800014f8:	6105                	add	sp,sp,32
    800014fa:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014fc:	8f99                	sub	a5,a5,a4
    800014fe:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001500:	4685                	li	a3,1
    80001502:	0007861b          	sext.w	a2,a5
    80001506:	85ba                	mv	a1,a4
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	e5e080e7          	jalr	-418(ra) # 80001366 <uvmunmap>
    80001510:	b7c5                	j	800014f0 <uvmdealloc+0x26>

0000000080001512 <uvmalloc>:
  if (newsz < oldsz)
    80001512:	0ab66563          	bltu	a2,a1,800015bc <uvmalloc+0xaa>
{
    80001516:	7139                	add	sp,sp,-64
    80001518:	fc06                	sd	ra,56(sp)
    8000151a:	f822                	sd	s0,48(sp)
    8000151c:	f426                	sd	s1,40(sp)
    8000151e:	f04a                	sd	s2,32(sp)
    80001520:	ec4e                	sd	s3,24(sp)
    80001522:	e852                	sd	s4,16(sp)
    80001524:	e456                	sd	s5,8(sp)
    80001526:	e05a                	sd	s6,0(sp)
    80001528:	0080                	add	s0,sp,64
    8000152a:	8aaa                	mv	s5,a0
    8000152c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000152e:	6785                	lui	a5,0x1
    80001530:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001532:	95be                	add	a1,a1,a5
    80001534:	77fd                	lui	a5,0xfffff
    80001536:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000153a:	08c9f363          	bgeu	s3,a2,800015c0 <uvmalloc+0xae>
    8000153e:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001540:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	66a080e7          	jalr	1642(ra) # 80000bae <kalloc>
    8000154c:	84aa                	mv	s1,a0
    if (mem == 0)
    8000154e:	c51d                	beqz	a0,8000157c <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001550:	6605                	lui	a2,0x1
    80001552:	4581                	li	a1,0
    80001554:	00000097          	auipc	ra,0x0
    80001558:	882080e7          	jalr	-1918(ra) # 80000dd6 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000155c:	875a                	mv	a4,s6
    8000155e:	86a6                	mv	a3,s1
    80001560:	6605                	lui	a2,0x1
    80001562:	85ca                	mv	a1,s2
    80001564:	8556                	mv	a0,s5
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	c3a080e7          	jalr	-966(ra) # 800011a0 <mappages>
    8000156e:	e90d                	bnez	a0,800015a0 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001570:	6785                	lui	a5,0x1
    80001572:	993e                	add	s2,s2,a5
    80001574:	fd4968e3          	bltu	s2,s4,80001544 <uvmalloc+0x32>
  return newsz;
    80001578:	8552                	mv	a0,s4
    8000157a:	a809                	j	8000158c <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000157c:	864e                	mv	a2,s3
    8000157e:	85ca                	mv	a1,s2
    80001580:	8556                	mv	a0,s5
    80001582:	00000097          	auipc	ra,0x0
    80001586:	f48080e7          	jalr	-184(ra) # 800014ca <uvmdealloc>
      return 0;
    8000158a:	4501                	li	a0,0
}
    8000158c:	70e2                	ld	ra,56(sp)
    8000158e:	7442                	ld	s0,48(sp)
    80001590:	74a2                	ld	s1,40(sp)
    80001592:	7902                	ld	s2,32(sp)
    80001594:	69e2                	ld	s3,24(sp)
    80001596:	6a42                	ld	s4,16(sp)
    80001598:	6aa2                	ld	s5,8(sp)
    8000159a:	6b02                	ld	s6,0(sp)
    8000159c:	6121                	add	sp,sp,64
    8000159e:	8082                	ret
      kfree(mem);
    800015a0:	8526                	mv	a0,s1
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	442080e7          	jalr	1090(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015aa:	864e                	mv	a2,s3
    800015ac:	85ca                	mv	a1,s2
    800015ae:	8556                	mv	a0,s5
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f1a080e7          	jalr	-230(ra) # 800014ca <uvmdealloc>
      return 0;
    800015b8:	4501                	li	a0,0
    800015ba:	bfc9                	j	8000158c <uvmalloc+0x7a>
    return oldsz;
    800015bc:	852e                	mv	a0,a1
}
    800015be:	8082                	ret
  return newsz;
    800015c0:	8532                	mv	a0,a2
    800015c2:	b7e9                	j	8000158c <uvmalloc+0x7a>

00000000800015c4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800015c4:	7179                	add	sp,sp,-48
    800015c6:	f406                	sd	ra,40(sp)
    800015c8:	f022                	sd	s0,32(sp)
    800015ca:	ec26                	sd	s1,24(sp)
    800015cc:	e84a                	sd	s2,16(sp)
    800015ce:	e44e                	sd	s3,8(sp)
    800015d0:	e052                	sd	s4,0(sp)
    800015d2:	1800                	add	s0,sp,48
    800015d4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    800015d6:	84aa                	mv	s1,a0
    800015d8:	6905                	lui	s2,0x1
    800015da:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800015dc:	4985                	li	s3,1
    800015de:	a829                	j	800015f8 <freewalk+0x34>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e0:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015e2:	00c79513          	sll	a0,a5,0xc
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	fde080e7          	jalr	-34(ra) # 800015c4 <freewalk>
      pagetable[i] = 0;
    800015ee:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    800015f2:	04a1                	add	s1,s1,8
    800015f4:	03248163          	beq	s1,s2,80001616 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015f8:	609c                	ld	a5,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800015fa:	00f7f713          	and	a4,a5,15
    800015fe:	ff3701e3          	beq	a4,s3,800015e0 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001602:	8b85                	and	a5,a5,1
    80001604:	d7fd                	beqz	a5,800015f2 <freewalk+0x2e>
    {
      panic("freewalk: leaf");
    80001606:	00007517          	auipc	a0,0x7
    8000160a:	b8250513          	add	a0,a0,-1150 # 80008188 <digits+0x148>
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	f2e080e7          	jalr	-210(ra) # 8000053c <panic>
    }
  }
  kfree((void *)pagetable);
    80001616:	8552                	mv	a0,s4
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	3cc080e7          	jalr	972(ra) # 800009e4 <kfree>
}
    80001620:	70a2                	ld	ra,40(sp)
    80001622:	7402                	ld	s0,32(sp)
    80001624:	64e2                	ld	s1,24(sp)
    80001626:	6942                	ld	s2,16(sp)
    80001628:	69a2                	ld	s3,8(sp)
    8000162a:	6a02                	ld	s4,0(sp)
    8000162c:	6145                	add	sp,sp,48
    8000162e:	8082                	ret

0000000080001630 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001630:	1101                	add	sp,sp,-32
    80001632:	ec06                	sd	ra,24(sp)
    80001634:	e822                	sd	s0,16(sp)
    80001636:	e426                	sd	s1,8(sp)
    80001638:	1000                	add	s0,sp,32
    8000163a:	84aa                	mv	s1,a0
  if (sz > 0)
    8000163c:	e999                	bnez	a1,80001652 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    8000163e:	8526                	mv	a0,s1
    80001640:	00000097          	auipc	ra,0x0
    80001644:	f84080e7          	jalr	-124(ra) # 800015c4 <freewalk>
}
    80001648:	60e2                	ld	ra,24(sp)
    8000164a:	6442                	ld	s0,16(sp)
    8000164c:	64a2                	ld	s1,8(sp)
    8000164e:	6105                	add	sp,sp,32
    80001650:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80001652:	6785                	lui	a5,0x1
    80001654:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001656:	95be                	add	a1,a1,a5
    80001658:	4685                	li	a3,1
    8000165a:	00c5d613          	srl	a2,a1,0xc
    8000165e:	4581                	li	a1,0
    80001660:	00000097          	auipc	ra,0x0
    80001664:	d06080e7          	jalr	-762(ra) # 80001366 <uvmunmap>
    80001668:	bfd9                	j	8000163e <uvmfree+0xe>

000000008000166a <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.

int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    8000166a:	715d                	add	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	add	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    80001682:	c275                	beqz	a2,80001766 <uvmcopy+0xfc>
    80001684:	8b2a                	mv	s6,a0
    80001686:	8aae                	mv	s5,a1
    80001688:	8a32                	mv	s4,a2
    8000168a:	4901                	li	s2,0
    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    {
      // kfree(mem);
      goto err;
    }
    acquire(&ref_lock);
    8000168c:	0000f997          	auipc	s3,0xf
    80001690:	4b498993          	add	s3,s3,1204 # 80010b40 <ref_lock>
    arr[pa / 4096]++;
    80001694:	0000fb97          	auipc	s7,0xf
    80001698:	4e4b8b93          	add	s7,s7,1252 # 80010b78 <arr>
    8000169c:	a0bd                	j	8000170a <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    8000169e:	00007517          	auipc	a0,0x7
    800016a2:	afa50513          	add	a0,a0,-1286 # 80008198 <digits+0x158>
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	e96080e7          	jalr	-362(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016ae:	00007517          	auipc	a0,0x7
    800016b2:	b0a50513          	add	a0,a0,-1270 # 800081b8 <digits+0x178>
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	e86080e7          	jalr	-378(ra) # 8000053c <panic>
      flags &= ~PTE_W;
    800016be:	3fb77713          	and	a4,a4,1019
    800016c2:	08076713          	or	a4,a4,128
      *pte = (*pte & ~PTE_W) | PTE_C;
    800016c6:	f7b7f793          	and	a5,a5,-133
    800016ca:	0807e793          	or	a5,a5,128
    800016ce:	e11c                	sd	a5,0(a0)
    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    800016d0:	86a6                	mv	a3,s1
    800016d2:	6605                	lui	a2,0x1
    800016d4:	85ca                	mv	a1,s2
    800016d6:	8556                	mv	a0,s5
    800016d8:	00000097          	auipc	ra,0x0
    800016dc:	ac8080e7          	jalr	-1336(ra) # 800011a0 <mappages>
    800016e0:	8c2a                	mv	s8,a0
    800016e2:	e939                	bnez	a0,80001738 <uvmcopy+0xce>
    acquire(&ref_lock);
    800016e4:	854e                	mv	a0,s3
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	5f4080e7          	jalr	1524(ra) # 80000cda <acquire>
    arr[pa / 4096]++;
    800016ee:	80a9                	srl	s1,s1,0xa
    800016f0:	94de                	add	s1,s1,s7
    800016f2:	409c                	lw	a5,0(s1)
    800016f4:	2785                	addw	a5,a5,1
    800016f6:	c09c                	sw	a5,0(s1)
    release(&ref_lock);
    800016f8:	854e                	mv	a0,s3
    800016fa:	fffff097          	auipc	ra,0xfffff
    800016fe:	694080e7          	jalr	1684(ra) # 80000d8e <release>
  for (i = 0; i < sz; i += PGSIZE)
    80001702:	6785                	lui	a5,0x1
    80001704:	993e                	add	s2,s2,a5
    80001706:	05497363          	bgeu	s2,s4,8000174c <uvmcopy+0xe2>
    if ((pte = walk(old, i, 0)) == 0)
    8000170a:	4601                	li	a2,0
    8000170c:	85ca                	mv	a1,s2
    8000170e:	855a                	mv	a0,s6
    80001710:	00000097          	auipc	ra,0x0
    80001714:	9a8080e7          	jalr	-1624(ra) # 800010b8 <walk>
    80001718:	d159                	beqz	a0,8000169e <uvmcopy+0x34>
    if ((*pte & PTE_V) == 0)
    8000171a:	611c                	ld	a5,0(a0)
    8000171c:	0017f713          	and	a4,a5,1
    80001720:	d759                	beqz	a4,800016ae <uvmcopy+0x44>
    pa = PTE2PA(*pte);
    80001722:	00a7d493          	srl	s1,a5,0xa
    80001726:	04b2                	sll	s1,s1,0xc
    flags = PTE_FLAGS(*pte);
    80001728:	0007871b          	sext.w	a4,a5
    if (flags & PTE_W)
    8000172c:	0047f693          	and	a3,a5,4
    80001730:	f6d9                	bnez	a3,800016be <uvmcopy+0x54>
    flags = PTE_FLAGS(*pte);
    80001732:	3ff77713          	and	a4,a4,1023
    80001736:	bf69                	j	800016d0 <uvmcopy+0x66>
  }
  return 0;

err:

  uvmunmap(new, 0, i / PGSIZE, 1);
    80001738:	4685                	li	a3,1
    8000173a:	00c95613          	srl	a2,s2,0xc
    8000173e:	4581                	li	a1,0
    80001740:	8556                	mv	a0,s5
    80001742:	00000097          	auipc	ra,0x0
    80001746:	c24080e7          	jalr	-988(ra) # 80001366 <uvmunmap>
  return -1;
    8000174a:	5c7d                	li	s8,-1
}
    8000174c:	8562                	mv	a0,s8
    8000174e:	60a6                	ld	ra,72(sp)
    80001750:	6406                	ld	s0,64(sp)
    80001752:	74e2                	ld	s1,56(sp)
    80001754:	7942                	ld	s2,48(sp)
    80001756:	79a2                	ld	s3,40(sp)
    80001758:	7a02                	ld	s4,32(sp)
    8000175a:	6ae2                	ld	s5,24(sp)
    8000175c:	6b42                	ld	s6,16(sp)
    8000175e:	6ba2                	ld	s7,8(sp)
    80001760:	6c02                	ld	s8,0(sp)
    80001762:	6161                	add	sp,sp,80
    80001764:	8082                	ret
  return 0;
    80001766:	4c01                	li	s8,0
    80001768:	b7d5                	j	8000174c <uvmcopy+0xe2>

000000008000176a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    8000176a:	1141                	add	sp,sp,-16
    8000176c:	e406                	sd	ra,8(sp)
    8000176e:	e022                	sd	s0,0(sp)
    80001770:	0800                	add	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001772:	4601                	li	a2,0
    80001774:	00000097          	auipc	ra,0x0
    80001778:	944080e7          	jalr	-1724(ra) # 800010b8 <walk>
  if (pte == 0)
    8000177c:	c901                	beqz	a0,8000178c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000177e:	611c                	ld	a5,0(a0)
    80001780:	9bbd                	and	a5,a5,-17
    80001782:	e11c                	sd	a5,0(a0)
}
    80001784:	60a2                	ld	ra,8(sp)
    80001786:	6402                	ld	s0,0(sp)
    80001788:	0141                	add	sp,sp,16
    8000178a:	8082                	ret
    panic("uvmclear");
    8000178c:	00007517          	auipc	a0,0x7
    80001790:	a4c50513          	add	a0,a0,-1460 # 800081d8 <digits+0x198>
    80001794:	fffff097          	auipc	ra,0xfffff
    80001798:	da8080e7          	jalr	-600(ra) # 8000053c <panic>

000000008000179c <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0, flags;
  pte_t *pte;
  while (len > 0)
    8000179c:	c2d5                	beqz	a3,80001840 <copyout+0xa4>
{
    8000179e:	711d                	add	sp,sp,-96
    800017a0:	ec86                	sd	ra,88(sp)
    800017a2:	e8a2                	sd	s0,80(sp)
    800017a4:	e4a6                	sd	s1,72(sp)
    800017a6:	e0ca                	sd	s2,64(sp)
    800017a8:	fc4e                	sd	s3,56(sp)
    800017aa:	f852                	sd	s4,48(sp)
    800017ac:	f456                	sd	s5,40(sp)
    800017ae:	f05a                	sd	s6,32(sp)
    800017b0:	ec5e                	sd	s7,24(sp)
    800017b2:	e862                	sd	s8,16(sp)
    800017b4:	e466                	sd	s9,8(sp)
    800017b6:	1080                	add	s0,sp,96
    800017b8:	8baa                	mv	s7,a0
    800017ba:	89ae                	mv	s3,a1
    800017bc:	8b32                	mv	s6,a2
    800017be:	8ab6                	mv	s5,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800017c0:	7cfd                	lui	s9,0xfffff
      if (flags & PTE_C)
      {
        handel_page_fault(pagetable, (void *)va0);
        pa0 = walkaddr(pagetable, va0);
      }
      n = PGSIZE - (dstva - va0);
    800017c2:	6c05                	lui	s8,0x1
    800017c4:	a081                	j	80001804 <copyout+0x68>
        handel_page_fault(pagetable, (void *)va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	855e                	mv	a0,s7
    800017ca:	00001097          	auipc	ra,0x1
    800017ce:	40a080e7          	jalr	1034(ra) # 80002bd4 <handel_page_fault>
        pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	855e                	mv	a0,s7
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	988080e7          	jalr	-1656(ra) # 8000115e <walkaddr>
    800017de:	8a2a                	mv	s4,a0
    800017e0:	a0b9                	j	8000182e <copyout+0x92>
      if (n > len)
        n = len;
      memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017e2:	41298533          	sub	a0,s3,s2
    800017e6:	0004861b          	sext.w	a2,s1
    800017ea:	85da                	mv	a1,s6
    800017ec:	9552                	add	a0,a0,s4
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	644080e7          	jalr	1604(ra) # 80000e32 <memmove>

      len -= n;
    800017f6:	409a8ab3          	sub	s5,s5,s1
      src += n;
    800017fa:	9b26                	add	s6,s6,s1
      dstva = va0 + PGSIZE;
    800017fc:	018909b3          	add	s3,s2,s8
  while (len > 0)
    80001800:	020a8e63          	beqz	s5,8000183c <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    80001804:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    80001808:	85ca                	mv	a1,s2
    8000180a:	855e                	mv	a0,s7
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	952080e7          	jalr	-1710(ra) # 8000115e <walkaddr>
    80001814:	8a2a                	mv	s4,a0
    if (pa0)
    80001816:	c51d                	beqz	a0,80001844 <copyout+0xa8>
      pte = walk(pagetable, va0, 0);
    80001818:	4601                	li	a2,0
    8000181a:	85ca                	mv	a1,s2
    8000181c:	855e                	mv	a0,s7
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	89a080e7          	jalr	-1894(ra) # 800010b8 <walk>
      if (flags & PTE_C)
    80001826:	611c                	ld	a5,0(a0)
    80001828:	0807f793          	and	a5,a5,128
    8000182c:	ffc9                	bnez	a5,800017c6 <copyout+0x2a>
      n = PGSIZE - (dstva - va0);
    8000182e:	413904b3          	sub	s1,s2,s3
    80001832:	94e2                	add	s1,s1,s8
    80001834:	fa9af7e3          	bgeu	s5,s1,800017e2 <copyout+0x46>
    80001838:	84d6                	mv	s1,s5
    8000183a:	b765                	j	800017e2 <copyout+0x46>
    else
    {
      return -1;
    }
  }
  return 0;
    8000183c:	4501                	li	a0,0
    8000183e:	a021                	j	80001846 <copyout+0xaa>
    80001840:	4501                	li	a0,0
}
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
}
    80001846:	60e6                	ld	ra,88(sp)
    80001848:	6446                	ld	s0,80(sp)
    8000184a:	64a6                	ld	s1,72(sp)
    8000184c:	6906                	ld	s2,64(sp)
    8000184e:	79e2                	ld	s3,56(sp)
    80001850:	7a42                	ld	s4,48(sp)
    80001852:	7aa2                	ld	s5,40(sp)
    80001854:	7b02                	ld	s6,32(sp)
    80001856:	6be2                	ld	s7,24(sp)
    80001858:	6c42                	ld	s8,16(sp)
    8000185a:	6ca2                	ld	s9,8(sp)
    8000185c:	6125                	add	sp,sp,96
    8000185e:	8082                	ret

0000000080001860 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001860:	caa5                	beqz	a3,800018d0 <copyin+0x70>
{
    80001862:	715d                	add	sp,sp,-80
    80001864:	e486                	sd	ra,72(sp)
    80001866:	e0a2                	sd	s0,64(sp)
    80001868:	fc26                	sd	s1,56(sp)
    8000186a:	f84a                	sd	s2,48(sp)
    8000186c:	f44e                	sd	s3,40(sp)
    8000186e:	f052                	sd	s4,32(sp)
    80001870:	ec56                	sd	s5,24(sp)
    80001872:	e85a                	sd	s6,16(sp)
    80001874:	e45e                	sd	s7,8(sp)
    80001876:	e062                	sd	s8,0(sp)
    80001878:	0880                	add	s0,sp,80
    8000187a:	8b2a                	mv	s6,a0
    8000187c:	8a2e                	mv	s4,a1
    8000187e:	8c32                	mv	s8,a2
    80001880:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001882:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001884:	6a85                	lui	s5,0x1
    80001886:	a01d                	j	800018ac <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001888:	018505b3          	add	a1,a0,s8
    8000188c:	0004861b          	sext.w	a2,s1
    80001890:	412585b3          	sub	a1,a1,s2
    80001894:	8552                	mv	a0,s4
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	59c080e7          	jalr	1436(ra) # 80000e32 <memmove>

    len -= n;
    8000189e:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018a2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018a4:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800018a8:	02098263          	beqz	s3,800018cc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800018ac:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018b0:	85ca                	mv	a1,s2
    800018b2:	855a                	mv	a0,s6
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	8aa080e7          	jalr	-1878(ra) # 8000115e <walkaddr>
    if (pa0 == 0)
    800018bc:	cd01                	beqz	a0,800018d4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018be:	418904b3          	sub	s1,s2,s8
    800018c2:	94d6                	add	s1,s1,s5
    800018c4:	fc99f2e3          	bgeu	s3,s1,80001888 <copyin+0x28>
    800018c8:	84ce                	mv	s1,s3
    800018ca:	bf7d                	j	80001888 <copyin+0x28>
  }
  return 0;
    800018cc:	4501                	li	a0,0
    800018ce:	a021                	j	800018d6 <copyin+0x76>
    800018d0:	4501                	li	a0,0
}
    800018d2:	8082                	ret
      return -1;
    800018d4:	557d                	li	a0,-1
}
    800018d6:	60a6                	ld	ra,72(sp)
    800018d8:	6406                	ld	s0,64(sp)
    800018da:	74e2                	ld	s1,56(sp)
    800018dc:	7942                	ld	s2,48(sp)
    800018de:	79a2                	ld	s3,40(sp)
    800018e0:	7a02                	ld	s4,32(sp)
    800018e2:	6ae2                	ld	s5,24(sp)
    800018e4:	6b42                	ld	s6,16(sp)
    800018e6:	6ba2                	ld	s7,8(sp)
    800018e8:	6c02                	ld	s8,0(sp)
    800018ea:	6161                	add	sp,sp,80
    800018ec:	8082                	ret

00000000800018ee <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    800018ee:	c2dd                	beqz	a3,80001994 <copyinstr+0xa6>
{
    800018f0:	715d                	add	sp,sp,-80
    800018f2:	e486                	sd	ra,72(sp)
    800018f4:	e0a2                	sd	s0,64(sp)
    800018f6:	fc26                	sd	s1,56(sp)
    800018f8:	f84a                	sd	s2,48(sp)
    800018fa:	f44e                	sd	s3,40(sp)
    800018fc:	f052                	sd	s4,32(sp)
    800018fe:	ec56                	sd	s5,24(sp)
    80001900:	e85a                	sd	s6,16(sp)
    80001902:	e45e                	sd	s7,8(sp)
    80001904:	0880                	add	s0,sp,80
    80001906:	8a2a                	mv	s4,a0
    80001908:	8b2e                	mv	s6,a1
    8000190a:	8bb2                	mv	s7,a2
    8000190c:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    8000190e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001910:	6985                	lui	s3,0x1
    80001912:	a02d                	j	8000193c <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001914:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001918:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    8000191a:	37fd                	addw	a5,a5,-1
    8000191c:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001920:	60a6                	ld	ra,72(sp)
    80001922:	6406                	ld	s0,64(sp)
    80001924:	74e2                	ld	s1,56(sp)
    80001926:	7942                	ld	s2,48(sp)
    80001928:	79a2                	ld	s3,40(sp)
    8000192a:	7a02                	ld	s4,32(sp)
    8000192c:	6ae2                	ld	s5,24(sp)
    8000192e:	6b42                	ld	s6,16(sp)
    80001930:	6ba2                	ld	s7,8(sp)
    80001932:	6161                	add	sp,sp,80
    80001934:	8082                	ret
    srcva = va0 + PGSIZE;
    80001936:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    8000193a:	c8a9                	beqz	s1,8000198c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000193c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001940:	85ca                	mv	a1,s2
    80001942:	8552                	mv	a0,s4
    80001944:	00000097          	auipc	ra,0x0
    80001948:	81a080e7          	jalr	-2022(ra) # 8000115e <walkaddr>
    if (pa0 == 0)
    8000194c:	c131                	beqz	a0,80001990 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000194e:	417906b3          	sub	a3,s2,s7
    80001952:	96ce                	add	a3,a3,s3
    80001954:	00d4f363          	bgeu	s1,a3,8000195a <copyinstr+0x6c>
    80001958:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    8000195a:	955e                	add	a0,a0,s7
    8000195c:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001960:	daf9                	beqz	a3,80001936 <copyinstr+0x48>
    80001962:	87da                	mv	a5,s6
    80001964:	885a                	mv	a6,s6
      if (*p == '\0')
    80001966:	41650633          	sub	a2,a0,s6
    while (n > 0)
    8000196a:	96da                	add	a3,a3,s6
    8000196c:	85be                	mv	a1,a5
      if (*p == '\0')
    8000196e:	00f60733          	add	a4,a2,a5
    80001972:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbc678>
    80001976:	df59                	beqz	a4,80001914 <copyinstr+0x26>
        *dst = *p;
    80001978:	00e78023          	sb	a4,0(a5)
      dst++;
    8000197c:	0785                	add	a5,a5,1
    while (n > 0)
    8000197e:	fed797e3          	bne	a5,a3,8000196c <copyinstr+0x7e>
    80001982:	14fd                	add	s1,s1,-1
    80001984:	94c2                	add	s1,s1,a6
      --max;
    80001986:	8c8d                	sub	s1,s1,a1
      dst++;
    80001988:	8b3e                	mv	s6,a5
    8000198a:	b775                	j	80001936 <copyinstr+0x48>
    8000198c:	4781                	li	a5,0
    8000198e:	b771                	j	8000191a <copyinstr+0x2c>
      return -1;
    80001990:	557d                	li	a0,-1
    80001992:	b779                	j	80001920 <copyinstr+0x32>
  int got_null = 0;
    80001994:	4781                	li	a5,0
  if (got_null)
    80001996:	37fd                	addw	a5,a5,-1
    80001998:	0007851b          	sext.w	a0,a5
}
    8000199c:	8082                	ret

000000008000199e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000199e:	7139                	add	sp,sp,-64
    800019a0:	fc06                	sd	ra,56(sp)
    800019a2:	f822                	sd	s0,48(sp)
    800019a4:	f426                	sd	s1,40(sp)
    800019a6:	f04a                	sd	s2,32(sp)
    800019a8:	ec4e                	sd	s3,24(sp)
    800019aa:	e852                	sd	s4,16(sp)
    800019ac:	e456                	sd	s5,8(sp)
    800019ae:	e05a                	sd	s6,0(sp)
    800019b0:	0080                	add	s0,sp,64
    800019b2:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800019b4:	0022f497          	auipc	s1,0x22f
    800019b8:	5f448493          	add	s1,s1,1524 # 80230fa8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800019bc:	8b26                	mv	s6,s1
    800019be:	00006a97          	auipc	s5,0x6
    800019c2:	642a8a93          	add	s5,s5,1602 # 80008000 <etext>
    800019c6:	04000937          	lui	s2,0x4000
    800019ca:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019cc:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019ce:	00236a17          	auipc	s4,0x236
    800019d2:	bdaa0a13          	add	s4,s4,-1062 # 802375a8 <tickslock>
    char *pa = kalloc();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	1d8080e7          	jalr	472(ra) # 80000bae <kalloc>
    800019de:	862a                	mv	a2,a0
    if (pa == 0)
    800019e0:	c131                	beqz	a0,80001a24 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800019e2:	416485b3          	sub	a1,s1,s6
    800019e6:	858d                	sra	a1,a1,0x3
    800019e8:	000ab783          	ld	a5,0(s5)
    800019ec:	02f585b3          	mul	a1,a1,a5
    800019f0:	2585                	addw	a1,a1,1
    800019f2:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f6:	4719                	li	a4,6
    800019f8:	6685                	lui	a3,0x1
    800019fa:	40b905b3          	sub	a1,s2,a1
    800019fe:	854e                	mv	a0,s3
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	840080e7          	jalr	-1984(ra) # 80001240 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a08:	19848493          	add	s1,s1,408
    80001a0c:	fd4495e3          	bne	s1,s4,800019d6 <proc_mapstacks+0x38>
  }
}
    80001a10:	70e2                	ld	ra,56(sp)
    80001a12:	7442                	ld	s0,48(sp)
    80001a14:	74a2                	ld	s1,40(sp)
    80001a16:	7902                	ld	s2,32(sp)
    80001a18:	69e2                	ld	s3,24(sp)
    80001a1a:	6a42                	ld	s4,16(sp)
    80001a1c:	6aa2                	ld	s5,8(sp)
    80001a1e:	6b02                	ld	s6,0(sp)
    80001a20:	6121                	add	sp,sp,64
    80001a22:	8082                	ret
      panic("kalloc");
    80001a24:	00006517          	auipc	a0,0x6
    80001a28:	7c450513          	add	a0,a0,1988 # 800081e8 <digits+0x1a8>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b10080e7          	jalr	-1264(ra) # 8000053c <panic>

0000000080001a34 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a34:	7139                	add	sp,sp,-64
    80001a36:	fc06                	sd	ra,56(sp)
    80001a38:	f822                	sd	s0,48(sp)
    80001a3a:	f426                	sd	s1,40(sp)
    80001a3c:	f04a                	sd	s2,32(sp)
    80001a3e:	ec4e                	sd	s3,24(sp)
    80001a40:	e852                	sd	s4,16(sp)
    80001a42:	e456                	sd	s5,8(sp)
    80001a44:	e05a                	sd	s6,0(sp)
    80001a46:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	7a858593          	add	a1,a1,1960 # 800081f0 <digits+0x1b0>
    80001a50:	0022f517          	auipc	a0,0x22f
    80001a54:	12850513          	add	a0,a0,296 # 80230b78 <pid_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	1f2080e7          	jalr	498(ra) # 80000c4a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a60:	00006597          	auipc	a1,0x6
    80001a64:	79858593          	add	a1,a1,1944 # 800081f8 <digits+0x1b8>
    80001a68:	0022f517          	auipc	a0,0x22f
    80001a6c:	12850513          	add	a0,a0,296 # 80230b90 <wait_lock>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	1da080e7          	jalr	474(ra) # 80000c4a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a78:	0022f497          	auipc	s1,0x22f
    80001a7c:	53048493          	add	s1,s1,1328 # 80230fa8 <proc>
  {
    initlock(&p->lock, "proc");
    80001a80:	00006b17          	auipc	s6,0x6
    80001a84:	788b0b13          	add	s6,s6,1928 # 80008208 <digits+0x1c8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a88:	8aa6                	mv	s5,s1
    80001a8a:	00006a17          	auipc	s4,0x6
    80001a8e:	576a0a13          	add	s4,s4,1398 # 80008000 <etext>
    80001a92:	04000937          	lui	s2,0x4000
    80001a96:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a98:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a9a:	00236997          	auipc	s3,0x236
    80001a9e:	b0e98993          	add	s3,s3,-1266 # 802375a8 <tickslock>
    initlock(&p->lock, "proc");
    80001aa2:	85da                	mv	a1,s6
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	1a4080e7          	jalr	420(ra) # 80000c4a <initlock>
    p->state = UNUSED;
    80001aae:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001ab2:	415487b3          	sub	a5,s1,s5
    80001ab6:	878d                	sra	a5,a5,0x3
    80001ab8:	000a3703          	ld	a4,0(s4)
    80001abc:	02e787b3          	mul	a5,a5,a4
    80001ac0:	2785                	addw	a5,a5,1
    80001ac2:	00d7979b          	sllw	a5,a5,0xd
    80001ac6:	40f907b3          	sub	a5,s2,a5
    80001aca:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001acc:	19848493          	add	s1,s1,408
    80001ad0:	fd3499e3          	bne	s1,s3,80001aa2 <procinit+0x6e>
  }
}
    80001ad4:	70e2                	ld	ra,56(sp)
    80001ad6:	7442                	ld	s0,48(sp)
    80001ad8:	74a2                	ld	s1,40(sp)
    80001ada:	7902                	ld	s2,32(sp)
    80001adc:	69e2                	ld	s3,24(sp)
    80001ade:	6a42                	ld	s4,16(sp)
    80001ae0:	6aa2                	ld	s5,8(sp)
    80001ae2:	6b02                	ld	s6,0(sp)
    80001ae4:	6121                	add	sp,sp,64
    80001ae6:	8082                	ret

0000000080001ae8 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001ae8:	1141                	add	sp,sp,-16
    80001aea:	e422                	sd	s0,8(sp)
    80001aec:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aee:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001af0:	2501                	sext.w	a0,a0
    80001af2:	6422                	ld	s0,8(sp)
    80001af4:	0141                	add	sp,sp,16
    80001af6:	8082                	ret

0000000080001af8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001af8:	1141                	add	sp,sp,-16
    80001afa:	e422                	sd	s0,8(sp)
    80001afc:	0800                	add	s0,sp,16
    80001afe:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b00:	2781                	sext.w	a5,a5
    80001b02:	079e                	sll	a5,a5,0x7
  return c;
}
    80001b04:	0022f517          	auipc	a0,0x22f
    80001b08:	0a450513          	add	a0,a0,164 # 80230ba8 <cpus>
    80001b0c:	953e                	add	a0,a0,a5
    80001b0e:	6422                	ld	s0,8(sp)
    80001b10:	0141                	add	sp,sp,16
    80001b12:	8082                	ret

0000000080001b14 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b14:	1101                	add	sp,sp,-32
    80001b16:	ec06                	sd	ra,24(sp)
    80001b18:	e822                	sd	s0,16(sp)
    80001b1a:	e426                	sd	s1,8(sp)
    80001b1c:	1000                	add	s0,sp,32
  push_off();
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	170080e7          	jalr	368(ra) # 80000c8e <push_off>
    80001b26:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b28:	2781                	sext.w	a5,a5
    80001b2a:	079e                	sll	a5,a5,0x7
    80001b2c:	0022f717          	auipc	a4,0x22f
    80001b30:	04c70713          	add	a4,a4,76 # 80230b78 <pid_lock>
    80001b34:	97ba                	add	a5,a5,a4
    80001b36:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	1f6080e7          	jalr	502(ra) # 80000d2e <pop_off>
  return p;
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6105                	add	sp,sp,32
    80001b4a:	8082                	ret

0000000080001b4c <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b4c:	1141                	add	sp,sp,-16
    80001b4e:	e406                	sd	ra,8(sp)
    80001b50:	e022                	sd	s0,0(sp)
    80001b52:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	fc0080e7          	jalr	-64(ra) # 80001b14 <myproc>
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	232080e7          	jalr	562(ra) # 80000d8e <release>

  if (first)
    80001b64:	00007797          	auipc	a5,0x7
    80001b68:	d0c7a783          	lw	a5,-756(a5) # 80008870 <first.1>
    80001b6c:	eb89                	bnez	a5,80001b7e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b6e:	00001097          	auipc	ra,0x1
    80001b72:	11e080e7          	jalr	286(ra) # 80002c8c <usertrapret>
}
    80001b76:	60a2                	ld	ra,8(sp)
    80001b78:	6402                	ld	s0,0(sp)
    80001b7a:	0141                	add	sp,sp,16
    80001b7c:	8082                	ret
    first = 0;
    80001b7e:	00007797          	auipc	a5,0x7
    80001b82:	ce07a923          	sw	zero,-782(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001b86:	4505                	li	a0,1
    80001b88:	00002097          	auipc	ra,0x2
    80001b8c:	f7a080e7          	jalr	-134(ra) # 80003b02 <fsinit>
    80001b90:	bff9                	j	80001b6e <forkret+0x22>

0000000080001b92 <allocpid>:
{
    80001b92:	1101                	add	sp,sp,-32
    80001b94:	ec06                	sd	ra,24(sp)
    80001b96:	e822                	sd	s0,16(sp)
    80001b98:	e426                	sd	s1,8(sp)
    80001b9a:	e04a                	sd	s2,0(sp)
    80001b9c:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001b9e:	0022f917          	auipc	s2,0x22f
    80001ba2:	fda90913          	add	s2,s2,-38 # 80230b78 <pid_lock>
    80001ba6:	854a                	mv	a0,s2
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	132080e7          	jalr	306(ra) # 80000cda <acquire>
  pid = nextpid;
    80001bb0:	00007797          	auipc	a5,0x7
    80001bb4:	cc478793          	add	a5,a5,-828 # 80008874 <nextpid>
    80001bb8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bba:	0014871b          	addw	a4,s1,1
    80001bbe:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bc0:	854a                	mv	a0,s2
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	1cc080e7          	jalr	460(ra) # 80000d8e <release>
}
    80001bca:	8526                	mv	a0,s1
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	add	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <proc_pagetable>:
{
    80001bd8:	1101                	add	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	add	s0,sp,32
    80001be4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	844080e7          	jalr	-1980(ra) # 8000142a <uvmcreate>
    80001bee:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bf0:	c121                	beqz	a0,80001c30 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bf2:	4729                	li	a4,10
    80001bf4:	00005697          	auipc	a3,0x5
    80001bf8:	40c68693          	add	a3,a3,1036 # 80007000 <_trampoline>
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	040005b7          	lui	a1,0x4000
    80001c02:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c04:	05b2                	sll	a1,a1,0xc
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	59a080e7          	jalr	1434(ra) # 800011a0 <mappages>
    80001c0e:	02054863          	bltz	a0,80001c3e <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c12:	4719                	li	a4,6
    80001c14:	05893683          	ld	a3,88(s2)
    80001c18:	6605                	lui	a2,0x1
    80001c1a:	020005b7          	lui	a1,0x2000
    80001c1e:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c20:	05b6                	sll	a1,a1,0xd
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	57c080e7          	jalr	1404(ra) # 800011a0 <mappages>
    80001c2c:	02054163          	bltz	a0,80001c4e <proc_pagetable+0x76>
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	add	sp,sp,32
    80001c3c:	8082                	ret
    uvmfree(pagetable, 0);
    80001c3e:	4581                	li	a1,0
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	9ee080e7          	jalr	-1554(ra) # 80001630 <uvmfree>
    return 0;
    80001c4a:	4481                	li	s1,0
    80001c4c:	b7d5                	j	80001c30 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c4e:	4681                	li	a3,0
    80001c50:	4605                	li	a2,1
    80001c52:	040005b7          	lui	a1,0x4000
    80001c56:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c58:	05b2                	sll	a1,a1,0xc
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	70a080e7          	jalr	1802(ra) # 80001366 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c64:	4581                	li	a1,0
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	9c8080e7          	jalr	-1592(ra) # 80001630 <uvmfree>
    return 0;
    80001c70:	4481                	li	s1,0
    80001c72:	bf7d                	j	80001c30 <proc_pagetable+0x58>

0000000080001c74 <proc_freepagetable>:
{
    80001c74:	1101                	add	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	e04a                	sd	s2,0(sp)
    80001c7e:	1000                	add	s0,sp,32
    80001c80:	84aa                	mv	s1,a0
    80001c82:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c84:	4681                	li	a3,0
    80001c86:	4605                	li	a2,1
    80001c88:	040005b7          	lui	a1,0x4000
    80001c8c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c8e:	05b2                	sll	a1,a1,0xc
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	6d6080e7          	jalr	1750(ra) # 80001366 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c98:	4681                	li	a3,0
    80001c9a:	4605                	li	a2,1
    80001c9c:	020005b7          	lui	a1,0x2000
    80001ca0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ca2:	05b6                	sll	a1,a1,0xd
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	6c0080e7          	jalr	1728(ra) # 80001366 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cae:	85ca                	mv	a1,s2
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	97e080e7          	jalr	-1666(ra) # 80001630 <uvmfree>
}
    80001cba:	60e2                	ld	ra,24(sp)
    80001cbc:	6442                	ld	s0,16(sp)
    80001cbe:	64a2                	ld	s1,8(sp)
    80001cc0:	6902                	ld	s2,0(sp)
    80001cc2:	6105                	add	sp,sp,32
    80001cc4:	8082                	ret

0000000080001cc6 <freeproc>:
{
    80001cc6:	1101                	add	sp,sp,-32
    80001cc8:	ec06                	sd	ra,24(sp)
    80001cca:	e822                	sd	s0,16(sp)
    80001ccc:	e426                	sd	s1,8(sp)
    80001cce:	1000                	add	s0,sp,32
    80001cd0:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001cd2:	6d28                	ld	a0,88(a0)
    80001cd4:	c509                	beqz	a0,80001cde <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	d0e080e7          	jalr	-754(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001cde:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ce2:	68a8                	ld	a0,80(s1)
    80001ce4:	c511                	beqz	a0,80001cf0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ce6:	64ac                	ld	a1,72(s1)
    80001ce8:	00000097          	auipc	ra,0x0
    80001cec:	f8c080e7          	jalr	-116(ra) # 80001c74 <proc_freepagetable>
  p->pagetable = 0;
    80001cf0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cf4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cf8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cfc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d00:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d04:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d08:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d0c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d10:	0004ac23          	sw	zero,24(s1)
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	add	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <allocproc>:
{
    80001d1e:	1101                	add	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d2a:	0022f497          	auipc	s1,0x22f
    80001d2e:	27e48493          	add	s1,s1,638 # 80230fa8 <proc>
    80001d32:	00236917          	auipc	s2,0x236
    80001d36:	87690913          	add	s2,s2,-1930 # 802375a8 <tickslock>
    acquire(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f9e080e7          	jalr	-98(ra) # 80000cda <acquire>
    if (p->state == UNUSED)
    80001d44:	4c9c                	lw	a5,24(s1)
    80001d46:	cf81                	beqz	a5,80001d5e <allocproc+0x40>
      release(&p->lock);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	044080e7          	jalr	68(ra) # 80000d8e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d52:	19848493          	add	s1,s1,408
    80001d56:	ff2492e3          	bne	s1,s2,80001d3a <allocproc+0x1c>
  return 0;
    80001d5a:	4481                	li	s1,0
    80001d5c:	a849                	j	80001dee <allocproc+0xd0>
  p->pid = allocpid();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	e34080e7          	jalr	-460(ra) # 80001b92 <allocpid>
    80001d66:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d68:	4785                	li	a5,1
    80001d6a:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	e42080e7          	jalr	-446(ra) # 80000bae <kalloc>
    80001d74:	892a                	mv	s2,a0
    80001d76:	eca8                	sd	a0,88(s1)
    80001d78:	c151                	beqz	a0,80001dfc <allocproc+0xde>
  p->pagetable = proc_pagetable(p);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	e5c080e7          	jalr	-420(ra) # 80001bd8 <proc_pagetable>
    80001d84:	892a                	mv	s2,a0
    80001d86:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d88:	c551                	beqz	a0,80001e14 <allocproc+0xf6>
  memset(&p->context, 0, sizeof(p->context));
    80001d8a:	07000613          	li	a2,112
    80001d8e:	4581                	li	a1,0
    80001d90:	06048513          	add	a0,s1,96
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	042080e7          	jalr	66(ra) # 80000dd6 <memset>
  p->context.ra = (uint64)forkret;
    80001d9c:	00000797          	auipc	a5,0x0
    80001da0:	db078793          	add	a5,a5,-592 # 80001b4c <forkret>
    80001da4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da6:	60bc                	ld	a5,64(s1)
    80001da8:	6705                	lui	a4,0x1
    80001daa:	97ba                	add	a5,a5,a4
    80001dac:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001dae:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001db2:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001db6:	00007797          	auipc	a5,0x7
    80001dba:	b3a7a783          	lw	a5,-1222(a5) # 800088f0 <ticks>
    80001dbe:	16f4a623          	sw	a5,364(s1)
  p->priority = 75;
    80001dc2:	04b00793          	li	a5,75
    80001dc6:	16f4aa23          	sw	a5,372(s1)
  p->static_priority = 50;
    80001dca:	03200793          	li	a5,50
    80001dce:	16f4ac23          	sw	a5,376(s1)
  p->RBI = 25;
    80001dd2:	47e5                	li	a5,25
    80001dd4:	18f4a023          	sw	a5,384(s1)
  p->n_run = 0;
    80001dd8:	1804a423          	sw	zero,392(s1)
  p->rbi_check = 1;
    80001ddc:	4785                	li	a5,1
    80001dde:	18f4a223          	sw	a5,388(s1)
  p->ready_queue_time = 0;
    80001de2:	1804a623          	sw	zero,396(s1)
  p->last_run_time = 0;
    80001de6:	1804a823          	sw	zero,400(s1)
  p->spent_slp_time = 0;
    80001dea:	1804aa23          	sw	zero,404(s1)
}
    80001dee:	8526                	mv	a0,s1
    80001df0:	60e2                	ld	ra,24(sp)
    80001df2:	6442                	ld	s0,16(sp)
    80001df4:	64a2                	ld	s1,8(sp)
    80001df6:	6902                	ld	s2,0(sp)
    80001df8:	6105                	add	sp,sp,32
    80001dfa:	8082                	ret
    freeproc(p);
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	ec8080e7          	jalr	-312(ra) # 80001cc6 <freeproc>
    release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	f86080e7          	jalr	-122(ra) # 80000d8e <release>
    return 0;
    80001e10:	84ca                	mv	s1,s2
    80001e12:	bff1                	j	80001dee <allocproc+0xd0>
    freeproc(p);
    80001e14:	8526                	mv	a0,s1
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	eb0080e7          	jalr	-336(ra) # 80001cc6 <freeproc>
    release(&p->lock);
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	f6e080e7          	jalr	-146(ra) # 80000d8e <release>
    return 0;
    80001e28:	84ca                	mv	s1,s2
    80001e2a:	b7d1                	j	80001dee <allocproc+0xd0>

0000000080001e2c <userinit>:
{
    80001e2c:	1101                	add	sp,sp,-32
    80001e2e:	ec06                	sd	ra,24(sp)
    80001e30:	e822                	sd	s0,16(sp)
    80001e32:	e426                	sd	s1,8(sp)
    80001e34:	1000                	add	s0,sp,32
  p = allocproc();
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	ee8080e7          	jalr	-280(ra) # 80001d1e <allocproc>
    80001e3e:	84aa                	mv	s1,a0
  initproc = p;
    80001e40:	00007797          	auipc	a5,0x7
    80001e44:	aaa7b423          	sd	a0,-1368(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e48:	03400613          	li	a2,52
    80001e4c:	00007597          	auipc	a1,0x7
    80001e50:	a3458593          	add	a1,a1,-1484 # 80008880 <initcode>
    80001e54:	6928                	ld	a0,80(a0)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	602080e7          	jalr	1538(ra) # 80001458 <uvmfirst>
  p->sz = PGSIZE;
    80001e5e:	6785                	lui	a5,0x1
    80001e60:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e62:	6cb8                	ld	a4,88(s1)
    80001e64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e68:	6cb8                	ld	a4,88(s1)
    80001e6a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e6c:	4641                	li	a2,16
    80001e6e:	00006597          	auipc	a1,0x6
    80001e72:	3a258593          	add	a1,a1,930 # 80008210 <digits+0x1d0>
    80001e76:	15848513          	add	a0,s1,344
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	0a4080e7          	jalr	164(ra) # 80000f1e <safestrcpy>
  p->cwd = namei("/");
    80001e82:	00006517          	auipc	a0,0x6
    80001e86:	39e50513          	add	a0,a0,926 # 80008220 <digits+0x1e0>
    80001e8a:	00002097          	auipc	ra,0x2
    80001e8e:	696080e7          	jalr	1686(ra) # 80004520 <namei>
    80001e92:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e96:	478d                	li	a5,3
    80001e98:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	ef2080e7          	jalr	-270(ra) # 80000d8e <release>
}
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6105                	add	sp,sp,32
    80001eac:	8082                	ret

0000000080001eae <growproc>:
{
    80001eae:	1101                	add	sp,sp,-32
    80001eb0:	ec06                	sd	ra,24(sp)
    80001eb2:	e822                	sd	s0,16(sp)
    80001eb4:	e426                	sd	s1,8(sp)
    80001eb6:	e04a                	sd	s2,0(sp)
    80001eb8:	1000                	add	s0,sp,32
    80001eba:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	c58080e7          	jalr	-936(ra) # 80001b14 <myproc>
    80001ec4:	84aa                	mv	s1,a0
  sz = p->sz;
    80001ec6:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001ec8:	01204c63          	bgtz	s2,80001ee0 <growproc+0x32>
  else if (n < 0)
    80001ecc:	02094663          	bltz	s2,80001ef8 <growproc+0x4a>
  p->sz = sz;
    80001ed0:	e4ac                	sd	a1,72(s1)
  return 0;
    80001ed2:	4501                	li	a0,0
}
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6902                	ld	s2,0(sp)
    80001edc:	6105                	add	sp,sp,32
    80001ede:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001ee0:	4691                	li	a3,4
    80001ee2:	00b90633          	add	a2,s2,a1
    80001ee6:	6928                	ld	a0,80(a0)
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	62a080e7          	jalr	1578(ra) # 80001512 <uvmalloc>
    80001ef0:	85aa                	mv	a1,a0
    80001ef2:	fd79                	bnez	a0,80001ed0 <growproc+0x22>
      return -1;
    80001ef4:	557d                	li	a0,-1
    80001ef6:	bff9                	j	80001ed4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ef8:	00b90633          	add	a2,s2,a1
    80001efc:	6928                	ld	a0,80(a0)
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	5cc080e7          	jalr	1484(ra) # 800014ca <uvmdealloc>
    80001f06:	85aa                	mv	a1,a0
    80001f08:	b7e1                	j	80001ed0 <growproc+0x22>

0000000080001f0a <fork>:
{
    80001f0a:	7139                	add	sp,sp,-64
    80001f0c:	fc06                	sd	ra,56(sp)
    80001f0e:	f822                	sd	s0,48(sp)
    80001f10:	f426                	sd	s1,40(sp)
    80001f12:	f04a                	sd	s2,32(sp)
    80001f14:	ec4e                	sd	s3,24(sp)
    80001f16:	e852                	sd	s4,16(sp)
    80001f18:	e456                	sd	s5,8(sp)
    80001f1a:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001f1c:	00000097          	auipc	ra,0x0
    80001f20:	bf8080e7          	jalr	-1032(ra) # 80001b14 <myproc>
    80001f24:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	df8080e7          	jalr	-520(ra) # 80001d1e <allocproc>
    80001f2e:	10050c63          	beqz	a0,80002046 <fork+0x13c>
    80001f32:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f34:	048ab603          	ld	a2,72(s5)
    80001f38:	692c                	ld	a1,80(a0)
    80001f3a:	050ab503          	ld	a0,80(s5)
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	72c080e7          	jalr	1836(ra) # 8000166a <uvmcopy>
    80001f46:	04054863          	bltz	a0,80001f96 <fork+0x8c>
  np->sz = p->sz;
    80001f4a:	048ab783          	ld	a5,72(s5)
    80001f4e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f52:	058ab683          	ld	a3,88(s5)
    80001f56:	87b6                	mv	a5,a3
    80001f58:	058a3703          	ld	a4,88(s4)
    80001f5c:	12068693          	add	a3,a3,288
    80001f60:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f64:	6788                	ld	a0,8(a5)
    80001f66:	6b8c                	ld	a1,16(a5)
    80001f68:	6f90                	ld	a2,24(a5)
    80001f6a:	01073023          	sd	a6,0(a4)
    80001f6e:	e708                	sd	a0,8(a4)
    80001f70:	eb0c                	sd	a1,16(a4)
    80001f72:	ef10                	sd	a2,24(a4)
    80001f74:	02078793          	add	a5,a5,32
    80001f78:	02070713          	add	a4,a4,32
    80001f7c:	fed792e3          	bne	a5,a3,80001f60 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f80:	058a3783          	ld	a5,88(s4)
    80001f84:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f88:	0d0a8493          	add	s1,s5,208
    80001f8c:	0d0a0913          	add	s2,s4,208
    80001f90:	150a8993          	add	s3,s5,336
    80001f94:	a00d                	j	80001fb6 <fork+0xac>
    freeproc(np);
    80001f96:	8552                	mv	a0,s4
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	d2e080e7          	jalr	-722(ra) # 80001cc6 <freeproc>
    release(&np->lock);
    80001fa0:	8552                	mv	a0,s4
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	dec080e7          	jalr	-532(ra) # 80000d8e <release>
    return -1;
    80001faa:	597d                	li	s2,-1
    80001fac:	a059                	j	80002032 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001fae:	04a1                	add	s1,s1,8
    80001fb0:	0921                	add	s2,s2,8
    80001fb2:	01348b63          	beq	s1,s3,80001fc8 <fork+0xbe>
    if (p->ofile[i])
    80001fb6:	6088                	ld	a0,0(s1)
    80001fb8:	d97d                	beqz	a0,80001fae <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fba:	00003097          	auipc	ra,0x3
    80001fbe:	bd8080e7          	jalr	-1064(ra) # 80004b92 <filedup>
    80001fc2:	00a93023          	sd	a0,0(s2)
    80001fc6:	b7e5                	j	80001fae <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001fc8:	150ab503          	ld	a0,336(s5)
    80001fcc:	00002097          	auipc	ra,0x2
    80001fd0:	d70080e7          	jalr	-656(ra) # 80003d3c <idup>
    80001fd4:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fd8:	4641                	li	a2,16
    80001fda:	158a8593          	add	a1,s5,344
    80001fde:	158a0513          	add	a0,s4,344
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	f3c080e7          	jalr	-196(ra) # 80000f1e <safestrcpy>
  pid = np->pid;
    80001fea:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001fee:	8552                	mv	a0,s4
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	d9e080e7          	jalr	-610(ra) # 80000d8e <release>
  acquire(&wait_lock);
    80001ff8:	0022f497          	auipc	s1,0x22f
    80001ffc:	b9848493          	add	s1,s1,-1128 # 80230b90 <wait_lock>
    80002000:	8526                	mv	a0,s1
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	cd8080e7          	jalr	-808(ra) # 80000cda <acquire>
  np->parent = p;
    8000200a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	d7e080e7          	jalr	-642(ra) # 80000d8e <release>
  acquire(&np->lock);
    80002018:	8552                	mv	a0,s4
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	cc0080e7          	jalr	-832(ra) # 80000cda <acquire>
  np->state = RUNNABLE;
    80002022:	478d                	li	a5,3
    80002024:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002028:	8552                	mv	a0,s4
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	d64080e7          	jalr	-668(ra) # 80000d8e <release>
}
    80002032:	854a                	mv	a0,s2
    80002034:	70e2                	ld	ra,56(sp)
    80002036:	7442                	ld	s0,48(sp)
    80002038:	74a2                	ld	s1,40(sp)
    8000203a:	7902                	ld	s2,32(sp)
    8000203c:	69e2                	ld	s3,24(sp)
    8000203e:	6a42                	ld	s4,16(sp)
    80002040:	6aa2                	ld	s5,8(sp)
    80002042:	6121                	add	sp,sp,64
    80002044:	8082                	ret
    return -1;
    80002046:	597d                	li	s2,-1
    80002048:	b7ed                	j	80002032 <fork+0x128>

000000008000204a <find_priority>:
{
    8000204a:	1141                	add	sp,sp,-16
    8000204c:	e422                	sd	s0,8(sp)
    8000204e:	0800                	add	s0,sp,16
  int a = 3 * p->last_run_time;
    80002050:	19052703          	lw	a4,400(a0)
  a = a - p->spent_slp_time;
    80002054:	19452603          	lw	a2,404(a0)
  a = a - p->ready_queue_time;
    80002058:	18c52683          	lw	a3,396(a0)
  if (p->rbi_check == 1)
    8000205c:	18452583          	lw	a1,388(a0)
    80002060:	4785                	li	a5,1
    80002062:	04f58963          	beq	a1,a5,800020b4 <find_priority+0x6a>
  int a = 3 * p->last_run_time;
    80002066:	0017179b          	sllw	a5,a4,0x1
    8000206a:	9fb9                	addw	a5,a5,a4
  a = a - p->spent_slp_time;
    8000206c:	9f91                	subw	a5,a5,a2
  a = a - p->ready_queue_time;
    8000206e:	9f95                	subw	a5,a5,a3
  int y = (a * 50) / b;
    80002070:	03200593          	li	a1,50
    80002074:	02b787bb          	mulw	a5,a5,a1
  int b = p->spent_slp_time + p->ready_queue_time + p->last_run_time + 1;
    80002078:	9f31                	addw	a4,a4,a2
    8000207a:	2705                	addw	a4,a4,1
    8000207c:	9f35                	addw	a4,a4,a3
  int y = (a * 50) / b;
    8000207e:	02e7c7bb          	divw	a5,a5,a4
    p->RBI = 0;
    80002082:	4701                	li	a4,0
  if (y > 0)
    80002084:	00f05463          	blez	a5,8000208c <find_priority+0x42>
    p->RBI = y;
    80002088:	0007871b          	sext.w	a4,a5
    8000208c:	18e52023          	sw	a4,384(a0)
  int f = p->static_priority + p->RBI;
    80002090:	17852783          	lw	a5,376(a0)
    80002094:	9fb9                	addw	a5,a5,a4
  if (f > 100)
    80002096:	0007869b          	sext.w	a3,a5
    8000209a:	06400713          	li	a4,100
    8000209e:	00d75463          	bge	a4,a3,800020a6 <find_priority+0x5c>
    800020a2:	06400793          	li	a5,100
  p->priority = priority;
    800020a6:	16f52a23          	sw	a5,372(a0)
}
    800020aa:	0007851b          	sext.w	a0,a5
    800020ae:	6422                	ld	s0,8(sp)
    800020b0:	0141                	add	sp,sp,16
    800020b2:	8082                	ret
    p->rbi_check = 0;
    800020b4:	18052223          	sw	zero,388(a0)
    y = 25;
    800020b8:	47e5                	li	a5,25
    800020ba:	b7f9                	j	80002088 <find_priority+0x3e>

00000000800020bc <scheduler>:
{
    800020bc:	711d                	add	sp,sp,-96
    800020be:	ec86                	sd	ra,88(sp)
    800020c0:	e8a2                	sd	s0,80(sp)
    800020c2:	e4a6                	sd	s1,72(sp)
    800020c4:	e0ca                	sd	s2,64(sp)
    800020c6:	fc4e                	sd	s3,56(sp)
    800020c8:	f852                	sd	s4,48(sp)
    800020ca:	f456                	sd	s5,40(sp)
    800020cc:	f05a                	sd	s6,32(sp)
    800020ce:	ec5e                	sd	s7,24(sp)
    800020d0:	e862                	sd	s8,16(sp)
    800020d2:	e466                	sd	s9,8(sp)
    800020d4:	1080                	add	s0,sp,96
    800020d6:	8792                	mv	a5,tp
  int id = r_tp();
    800020d8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020da:	00779693          	sll	a3,a5,0x7
    800020de:	0022f717          	auipc	a4,0x22f
    800020e2:	a9a70713          	add	a4,a4,-1382 # 80230b78 <pid_lock>
    800020e6:	9736                	add	a4,a4,a3
    800020e8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &min_proc->context);
    800020ec:	0022f717          	auipc	a4,0x22f
    800020f0:	ac470713          	add	a4,a4,-1340 # 80230bb0 <cpus+0x8>
    800020f4:	00e68cb3          	add	s9,a3,a4
    for (p = proc; p < &proc[NPROC]; p++)
    800020f8:	00235917          	auipc	s2,0x235
    800020fc:	4b090913          	add	s2,s2,1200 # 802375a8 <tickslock>
    struct proc *min_proc = 0;
    80002100:	4b01                	li	s6,0
    int min_priority = 1000;
    80002102:	3e800a93          	li	s5,1000
        c->proc = min_proc;
    80002106:	0022fb97          	auipc	s7,0x22f
    8000210a:	a72b8b93          	add	s7,s7,-1422 # 80230b78 <pid_lock>
    8000210e:	9bb6                	add	s7,s7,a3
    80002110:	a079                	j	8000219e <scheduler+0xe2>
      else if (p->state == RUNNABLE && current_priority == min_priority && min_proc->n_run > p->n_run)
    80002112:	09478863          	beq	a5,s4,800021a2 <scheduler+0xe6>
      release(&p->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	c76080e7          	jalr	-906(ra) # 80000d8e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002120:	19848493          	add	s1,s1,408
    80002124:	0b248063          	beq	s1,s2,800021c4 <scheduler+0x108>
      acquire(&p->lock);
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	bb0080e7          	jalr	-1104(ra) # 80000cda <acquire>
      current_priority = p->priority;
    80002132:	1744a783          	lw	a5,372(s1)
      if (p->state == RUNNABLE && current_priority < min_priority)
    80002136:	4c98                	lw	a4,24(s1)
    80002138:	fd371fe3          	bne	a4,s3,80002116 <scheduler+0x5a>
      current_priority = p->priority;
    8000213c:	2781                	sext.w	a5,a5
      if (p->state == RUNNABLE && current_priority < min_priority)
    8000213e:	fd47dae3          	bge	a5,s4,80002112 <scheduler+0x56>
    80002142:	8c26                	mv	s8,s1
        min_priority = current_priority;
    80002144:	8a3e                	mv	s4,a5
      release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	c46080e7          	jalr	-954(ra) # 80000d8e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002150:	19848493          	add	s1,s1,408
    80002154:	fd249ae3          	bne	s1,s2,80002128 <scheduler+0x6c>
      acquire(&min_proc->lock);
    80002158:	84e2                	mv	s1,s8
    8000215a:	8562                	mv	a0,s8
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b7e080e7          	jalr	-1154(ra) # 80000cda <acquire>
      if (min_proc->state == RUNNABLE)
    80002164:	018c2703          	lw	a4,24(s8) # 1018 <_entry-0x7fffefe8>
    80002168:	478d                	li	a5,3
    8000216a:	02f71563          	bne	a4,a5,80002194 <scheduler+0xd8>
        min_proc->state = RUNNING;
    8000216e:	4791                	li	a5,4
    80002170:	00fc2c23          	sw	a5,24(s8)
        min_proc->n_run++;
    80002174:	188c2783          	lw	a5,392(s8)
    80002178:	2785                	addw	a5,a5,1
    8000217a:	18fc2423          	sw	a5,392(s8)
        c->proc = min_proc;
    8000217e:	038bb823          	sd	s8,48(s7)
        swtch(&c->context, &min_proc->context);
    80002182:	060c0593          	add	a1,s8,96
    80002186:	8566                	mv	a0,s9
    80002188:	00001097          	auipc	ra,0x1
    8000218c:	9a2080e7          	jalr	-1630(ra) # 80002b2a <swtch>
        c->proc = 0;
    80002190:	020bb823          	sd	zero,48(s7)
      release(&min_proc->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	bf8080e7          	jalr	-1032(ra) # 80000d8e <release>
      if (p->state == RUNNABLE && current_priority < min_priority)
    8000219e:	498d                	li	s3,3
    800021a0:	a025                	j	800021c8 <scheduler+0x10c>
      else if (p->state == RUNNABLE && current_priority == min_priority && min_proc->n_run > p->n_run)
    800021a2:	188c2683          	lw	a3,392(s8)
    800021a6:	1884a703          	lw	a4,392(s1)
    800021aa:	06d76363          	bltu	a4,a3,80002210 <scheduler+0x154>
      else if (p->state == RUNNABLE && current_priority == min_priority && min_proc->n_run == p->n_run && min_proc->ctime > p->ctime)
    800021ae:	f8e69ce3          	bne	a3,a4,80002146 <scheduler+0x8a>
    800021b2:	16cc2683          	lw	a3,364(s8)
    800021b6:	16c4a703          	lw	a4,364(s1)
    800021ba:	f8d776e3          	bgeu	a4,a3,80002146 <scheduler+0x8a>
    800021be:	8c26                	mv	s8,s1
        min_priority = current_priority;
    800021c0:	8a3e                	mv	s4,a5
    800021c2:	b751                	j	80002146 <scheduler+0x8a>
    if (min_proc != 0)
    800021c4:	f80c1ae3          	bnez	s8,80002158 <scheduler+0x9c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021cc:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d0:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021d4:	0022f497          	auipc	s1,0x22f
    800021d8:	dd448493          	add	s1,s1,-556 # 80230fa8 <proc>
      acquire(&p->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	afc080e7          	jalr	-1284(ra) # 80000cda <acquire>
      current_priority = find_priority(p);
    800021e6:	8526                	mv	a0,s1
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	e62080e7          	jalr	-414(ra) # 8000204a <find_priority>
      release(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	b9c080e7          	jalr	-1124(ra) # 80000d8e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800021fa:	19848493          	add	s1,s1,408
    800021fe:	fd249fe3          	bne	s1,s2,800021dc <scheduler+0x120>
    struct proc *min_proc = 0;
    80002202:	8c5a                	mv	s8,s6
    int min_priority = 1000;
    80002204:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002206:	0022f497          	auipc	s1,0x22f
    8000220a:	da248493          	add	s1,s1,-606 # 80230fa8 <proc>
    8000220e:	bf29                	j	80002128 <scheduler+0x6c>
    80002210:	8c26                	mv	s8,s1
        min_priority = current_priority;
    80002212:	8a3e                	mv	s4,a5
    80002214:	bf0d                	j	80002146 <scheduler+0x8a>

0000000080002216 <sched>:
{
    80002216:	7179                	add	sp,sp,-48
    80002218:	f406                	sd	ra,40(sp)
    8000221a:	f022                	sd	s0,32(sp)
    8000221c:	ec26                	sd	s1,24(sp)
    8000221e:	e84a                	sd	s2,16(sp)
    80002220:	e44e                	sd	s3,8(sp)
    80002222:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	8f0080e7          	jalr	-1808(ra) # 80001b14 <myproc>
    8000222c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	a32080e7          	jalr	-1486(ra) # 80000c60 <holding>
    80002236:	c93d                	beqz	a0,800022ac <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002238:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000223a:	2781                	sext.w	a5,a5
    8000223c:	079e                	sll	a5,a5,0x7
    8000223e:	0022f717          	auipc	a4,0x22f
    80002242:	93a70713          	add	a4,a4,-1734 # 80230b78 <pid_lock>
    80002246:	97ba                	add	a5,a5,a4
    80002248:	0a87a703          	lw	a4,168(a5)
    8000224c:	4785                	li	a5,1
    8000224e:	06f71763          	bne	a4,a5,800022bc <sched+0xa6>
  if (p->state == RUNNING)
    80002252:	4c98                	lw	a4,24(s1)
    80002254:	4791                	li	a5,4
    80002256:	06f70b63          	beq	a4,a5,800022cc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000225a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000225e:	8b89                	and	a5,a5,2
  if (intr_get())
    80002260:	efb5                	bnez	a5,800022dc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002262:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002264:	0022f917          	auipc	s2,0x22f
    80002268:	91490913          	add	s2,s2,-1772 # 80230b78 <pid_lock>
    8000226c:	2781                	sext.w	a5,a5
    8000226e:	079e                	sll	a5,a5,0x7
    80002270:	97ca                	add	a5,a5,s2
    80002272:	0ac7a983          	lw	s3,172(a5)
    80002276:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002278:	2781                	sext.w	a5,a5
    8000227a:	079e                	sll	a5,a5,0x7
    8000227c:	0022f597          	auipc	a1,0x22f
    80002280:	93458593          	add	a1,a1,-1740 # 80230bb0 <cpus+0x8>
    80002284:	95be                	add	a1,a1,a5
    80002286:	06048513          	add	a0,s1,96
    8000228a:	00001097          	auipc	ra,0x1
    8000228e:	8a0080e7          	jalr	-1888(ra) # 80002b2a <swtch>
    80002292:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002294:	2781                	sext.w	a5,a5
    80002296:	079e                	sll	a5,a5,0x7
    80002298:	993e                	add	s2,s2,a5
    8000229a:	0b392623          	sw	s3,172(s2)
}
    8000229e:	70a2                	ld	ra,40(sp)
    800022a0:	7402                	ld	s0,32(sp)
    800022a2:	64e2                	ld	s1,24(sp)
    800022a4:	6942                	ld	s2,16(sp)
    800022a6:	69a2                	ld	s3,8(sp)
    800022a8:	6145                	add	sp,sp,48
    800022aa:	8082                	ret
    panic("sched p->lock");
    800022ac:	00006517          	auipc	a0,0x6
    800022b0:	f7c50513          	add	a0,a0,-132 # 80008228 <digits+0x1e8>
    800022b4:	ffffe097          	auipc	ra,0xffffe
    800022b8:	288080e7          	jalr	648(ra) # 8000053c <panic>
    panic("sched locks");
    800022bc:	00006517          	auipc	a0,0x6
    800022c0:	f7c50513          	add	a0,a0,-132 # 80008238 <digits+0x1f8>
    800022c4:	ffffe097          	auipc	ra,0xffffe
    800022c8:	278080e7          	jalr	632(ra) # 8000053c <panic>
    panic("sched running");
    800022cc:	00006517          	auipc	a0,0x6
    800022d0:	f7c50513          	add	a0,a0,-132 # 80008248 <digits+0x208>
    800022d4:	ffffe097          	auipc	ra,0xffffe
    800022d8:	268080e7          	jalr	616(ra) # 8000053c <panic>
    panic("sched interruptible");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	f7c50513          	add	a0,a0,-132 # 80008258 <digits+0x218>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	258080e7          	jalr	600(ra) # 8000053c <panic>

00000000800022ec <yield>:
{
    800022ec:	1101                	add	sp,sp,-32
    800022ee:	ec06                	sd	ra,24(sp)
    800022f0:	e822                	sd	s0,16(sp)
    800022f2:	e426                	sd	s1,8(sp)
    800022f4:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	81e080e7          	jalr	-2018(ra) # 80001b14 <myproc>
    800022fe:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	9da080e7          	jalr	-1574(ra) # 80000cda <acquire>
  p->state = RUNNABLE;
    80002308:	478d                	li	a5,3
    8000230a:	cc9c                	sw	a5,24(s1)
  sched();
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	f0a080e7          	jalr	-246(ra) # 80002216 <sched>
  release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	a78080e7          	jalr	-1416(ra) # 80000d8e <release>
}
    8000231e:	60e2                	ld	ra,24(sp)
    80002320:	6442                	ld	s0,16(sp)
    80002322:	64a2                	ld	s1,8(sp)
    80002324:	6105                	add	sp,sp,32
    80002326:	8082                	ret

0000000080002328 <set_priority>:
{
    80002328:	7179                	add	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	e052                	sd	s4,0(sp)
    80002336:	1800                	add	s0,sp,48
    80002338:	892a                	mv	s2,a0
    8000233a:	8a2e                	mv	s4,a1
  for (p = proc; p < &proc[NPROC]; p++)
    8000233c:	0022f497          	auipc	s1,0x22f
    80002340:	c6c48493          	add	s1,s1,-916 # 80230fa8 <proc>
    80002344:	00235997          	auipc	s3,0x235
    80002348:	26498993          	add	s3,s3,612 # 802375a8 <tickslock>
    acquire(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	98c080e7          	jalr	-1652(ra) # 80000cda <acquire>
    if (p->pid == pid)
    80002356:	589c                	lw	a5,48(s1)
    80002358:	01278d63          	beq	a5,s2,80002372 <set_priority+0x4a>
    release(&p->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	a30080e7          	jalr	-1488(ra) # 80000d8e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002366:	19848493          	add	s1,s1,408
    8000236a:	ff3491e3          	bne	s1,s3,8000234c <set_priority+0x24>
  int old_priority = -1;
    8000236e:	597d                	li	s2,-1
    80002370:	a0b9                	j	800023be <set_priority+0x96>
      old_priority = find_priority(p);
    80002372:	8526                	mv	a0,s1
    80002374:	00000097          	auipc	ra,0x0
    80002378:	cd6080e7          	jalr	-810(ra) # 8000204a <find_priority>
    8000237c:	892a                	mv	s2,a0
      p->static_priority = priority;
    8000237e:	000a079b          	sext.w	a5,s4
    80002382:	16f4ac23          	sw	a5,376(s1)
      p->RBI = 25;
    80002386:	4765                	li	a4,25
    80002388:	18e4a023          	sw	a4,384(s1)
      int pp = p->static_priority + 25;
    8000238c:	27e5                	addw	a5,a5,25
      if (pp > 100)
    8000238e:	0007869b          	sext.w	a3,a5
    80002392:	06400713          	li	a4,100
    80002396:	00d75463          	bge	a4,a3,8000239e <set_priority+0x76>
    8000239a:	06400793          	li	a5,100
      p->priority = pp;
    8000239e:	16f4aa23          	sw	a5,372(s1)
      p->rbi_check = 1;
    800023a2:	4785                	li	a5,1
    800023a4:	18f4a223          	sw	a5,388(s1)
      release(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	9e4080e7          	jalr	-1564(ra) # 80000d8e <release>
  if (pp < old_priority)
    800023b2:	01205663          	blez	s2,800023be <set_priority+0x96>
    yield();
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	f36080e7          	jalr	-202(ra) # 800022ec <yield>
}
    800023be:	854a                	mv	a0,s2
    800023c0:	70a2                	ld	ra,40(sp)
    800023c2:	7402                	ld	s0,32(sp)
    800023c4:	64e2                	ld	s1,24(sp)
    800023c6:	6942                	ld	s2,16(sp)
    800023c8:	69a2                	ld	s3,8(sp)
    800023ca:	6a02                	ld	s4,0(sp)
    800023cc:	6145                	add	sp,sp,48
    800023ce:	8082                	ret

00000000800023d0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023d0:	7179                	add	sp,sp,-48
    800023d2:	f406                	sd	ra,40(sp)
    800023d4:	f022                	sd	s0,32(sp)
    800023d6:	ec26                	sd	s1,24(sp)
    800023d8:	e84a                	sd	s2,16(sp)
    800023da:	e44e                	sd	s3,8(sp)
    800023dc:	1800                	add	s0,sp,48
    800023de:	89aa                	mv	s3,a0
    800023e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	732080e7          	jalr	1842(ra) # 80001b14 <myproc>
    800023ea:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8ee080e7          	jalr	-1810(ra) # 80000cda <acquire>
  release(lk);
    800023f4:	854a                	mv	a0,s2
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	998080e7          	jalr	-1640(ra) # 80000d8e <release>

  // Go to sleep.
  p->chan = chan;
    800023fe:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002402:	4789                	li	a5,2
    80002404:	cc9c                	sw	a5,24(s1)

  sched();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	e10080e7          	jalr	-496(ra) # 80002216 <sched>

  // Tidy up.
  p->chan = 0;
    8000240e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	97a080e7          	jalr	-1670(ra) # 80000d8e <release>
  acquire(lk);
    8000241c:	854a                	mv	a0,s2
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	8bc080e7          	jalr	-1860(ra) # 80000cda <acquire>
}
    80002426:	70a2                	ld	ra,40(sp)
    80002428:	7402                	ld	s0,32(sp)
    8000242a:	64e2                	ld	s1,24(sp)
    8000242c:	6942                	ld	s2,16(sp)
    8000242e:	69a2                	ld	s3,8(sp)
    80002430:	6145                	add	sp,sp,48
    80002432:	8082                	ret

0000000080002434 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002434:	7139                	add	sp,sp,-64
    80002436:	fc06                	sd	ra,56(sp)
    80002438:	f822                	sd	s0,48(sp)
    8000243a:	f426                	sd	s1,40(sp)
    8000243c:	f04a                	sd	s2,32(sp)
    8000243e:	ec4e                	sd	s3,24(sp)
    80002440:	e852                	sd	s4,16(sp)
    80002442:	e456                	sd	s5,8(sp)
    80002444:	0080                	add	s0,sp,64
    80002446:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002448:	0022f497          	auipc	s1,0x22f
    8000244c:	b6048493          	add	s1,s1,-1184 # 80230fa8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002450:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002452:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002454:	00235917          	auipc	s2,0x235
    80002458:	15490913          	add	s2,s2,340 # 802375a8 <tickslock>
    8000245c:	a811                	j	80002470 <wakeup+0x3c>
      }
      release(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	92e080e7          	jalr	-1746(ra) # 80000d8e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002468:	19848493          	add	s1,s1,408
    8000246c:	03248663          	beq	s1,s2,80002498 <wakeup+0x64>
    if (p != myproc())
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	6a4080e7          	jalr	1700(ra) # 80001b14 <myproc>
    80002478:	fea488e3          	beq	s1,a0,80002468 <wakeup+0x34>
      acquire(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	85c080e7          	jalr	-1956(ra) # 80000cda <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002486:	4c9c                	lw	a5,24(s1)
    80002488:	fd379be3          	bne	a5,s3,8000245e <wakeup+0x2a>
    8000248c:	709c                	ld	a5,32(s1)
    8000248e:	fd4798e3          	bne	a5,s4,8000245e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002492:	0154ac23          	sw	s5,24(s1)
    80002496:	b7e1                	j	8000245e <wakeup+0x2a>
    }
  }
}
    80002498:	70e2                	ld	ra,56(sp)
    8000249a:	7442                	ld	s0,48(sp)
    8000249c:	74a2                	ld	s1,40(sp)
    8000249e:	7902                	ld	s2,32(sp)
    800024a0:	69e2                	ld	s3,24(sp)
    800024a2:	6a42                	ld	s4,16(sp)
    800024a4:	6aa2                	ld	s5,8(sp)
    800024a6:	6121                	add	sp,sp,64
    800024a8:	8082                	ret

00000000800024aa <reparent>:
{
    800024aa:	7179                	add	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	add	s0,sp,48
    800024ba:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024bc:	0022f497          	auipc	s1,0x22f
    800024c0:	aec48493          	add	s1,s1,-1300 # 80230fa8 <proc>
      pp->parent = initproc;
    800024c4:	00006a17          	auipc	s4,0x6
    800024c8:	424a0a13          	add	s4,s4,1060 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024cc:	00235997          	auipc	s3,0x235
    800024d0:	0dc98993          	add	s3,s3,220 # 802375a8 <tickslock>
    800024d4:	a029                	j	800024de <reparent+0x34>
    800024d6:	19848493          	add	s1,s1,408
    800024da:	01348d63          	beq	s1,s3,800024f4 <reparent+0x4a>
    if (pp->parent == p)
    800024de:	7c9c                	ld	a5,56(s1)
    800024e0:	ff279be3          	bne	a5,s2,800024d6 <reparent+0x2c>
      pp->parent = initproc;
    800024e4:	000a3503          	ld	a0,0(s4)
    800024e8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	f4a080e7          	jalr	-182(ra) # 80002434 <wakeup>
    800024f2:	b7d5                	j	800024d6 <reparent+0x2c>
}
    800024f4:	70a2                	ld	ra,40(sp)
    800024f6:	7402                	ld	s0,32(sp)
    800024f8:	64e2                	ld	s1,24(sp)
    800024fa:	6942                	ld	s2,16(sp)
    800024fc:	69a2                	ld	s3,8(sp)
    800024fe:	6a02                	ld	s4,0(sp)
    80002500:	6145                	add	sp,sp,48
    80002502:	8082                	ret

0000000080002504 <exit>:
{
    80002504:	7179                	add	sp,sp,-48
    80002506:	f406                	sd	ra,40(sp)
    80002508:	f022                	sd	s0,32(sp)
    8000250a:	ec26                	sd	s1,24(sp)
    8000250c:	e84a                	sd	s2,16(sp)
    8000250e:	e44e                	sd	s3,8(sp)
    80002510:	e052                	sd	s4,0(sp)
    80002512:	1800                	add	s0,sp,48
    80002514:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	5fe080e7          	jalr	1534(ra) # 80001b14 <myproc>
    8000251e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002520:	00006797          	auipc	a5,0x6
    80002524:	3c87b783          	ld	a5,968(a5) # 800088e8 <initproc>
    80002528:	0d050493          	add	s1,a0,208
    8000252c:	15050913          	add	s2,a0,336
    80002530:	02a79363          	bne	a5,a0,80002556 <exit+0x52>
    panic("init exiting");
    80002534:	00006517          	auipc	a0,0x6
    80002538:	d3c50513          	add	a0,a0,-708 # 80008270 <digits+0x230>
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	000080e7          	jalr	ra # 8000053c <panic>
      fileclose(f);
    80002544:	00002097          	auipc	ra,0x2
    80002548:	6a0080e7          	jalr	1696(ra) # 80004be4 <fileclose>
      p->ofile[fd] = 0;
    8000254c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002550:	04a1                	add	s1,s1,8
    80002552:	01248563          	beq	s1,s2,8000255c <exit+0x58>
    if (p->ofile[fd])
    80002556:	6088                	ld	a0,0(s1)
    80002558:	f575                	bnez	a0,80002544 <exit+0x40>
    8000255a:	bfdd                	j	80002550 <exit+0x4c>
  begin_op();
    8000255c:	00002097          	auipc	ra,0x2
    80002560:	1c4080e7          	jalr	452(ra) # 80004720 <begin_op>
  iput(p->cwd);
    80002564:	1509b503          	ld	a0,336(s3)
    80002568:	00002097          	auipc	ra,0x2
    8000256c:	9cc080e7          	jalr	-1588(ra) # 80003f34 <iput>
  end_op();
    80002570:	00002097          	auipc	ra,0x2
    80002574:	22a080e7          	jalr	554(ra) # 8000479a <end_op>
  p->cwd = 0;
    80002578:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000257c:	0022e497          	auipc	s1,0x22e
    80002580:	61448493          	add	s1,s1,1556 # 80230b90 <wait_lock>
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	754080e7          	jalr	1876(ra) # 80000cda <acquire>
  reparent(p);
    8000258e:	854e                	mv	a0,s3
    80002590:	00000097          	auipc	ra,0x0
    80002594:	f1a080e7          	jalr	-230(ra) # 800024aa <reparent>
  wakeup(p->parent);
    80002598:	0389b503          	ld	a0,56(s3)
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	e98080e7          	jalr	-360(ra) # 80002434 <wakeup>
  acquire(&p->lock);
    800025a4:	854e                	mv	a0,s3
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	734080e7          	jalr	1844(ra) # 80000cda <acquire>
  p->xstate = status;
    800025ae:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025b2:	4795                	li	a5,5
    800025b4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800025b8:	00006797          	auipc	a5,0x6
    800025bc:	3387a783          	lw	a5,824(a5) # 800088f0 <ticks>
    800025c0:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	7c8080e7          	jalr	1992(ra) # 80000d8e <release>
  sched();
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	c48080e7          	jalr	-952(ra) # 80002216 <sched>
  panic("zombie exit");
    800025d6:	00006517          	auipc	a0,0x6
    800025da:	caa50513          	add	a0,a0,-854 # 80008280 <digits+0x240>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	f5e080e7          	jalr	-162(ra) # 8000053c <panic>

00000000800025e6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025e6:	7179                	add	sp,sp,-48
    800025e8:	f406                	sd	ra,40(sp)
    800025ea:	f022                	sd	s0,32(sp)
    800025ec:	ec26                	sd	s1,24(sp)
    800025ee:	e84a                	sd	s2,16(sp)
    800025f0:	e44e                	sd	s3,8(sp)
    800025f2:	1800                	add	s0,sp,48
    800025f4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025f6:	0022f497          	auipc	s1,0x22f
    800025fa:	9b248493          	add	s1,s1,-1614 # 80230fa8 <proc>
    800025fe:	00235997          	auipc	s3,0x235
    80002602:	faa98993          	add	s3,s3,-86 # 802375a8 <tickslock>
  {
    acquire(&p->lock);
    80002606:	8526                	mv	a0,s1
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	6d2080e7          	jalr	1746(ra) # 80000cda <acquire>
    if (p->pid == pid)
    80002610:	589c                	lw	a5,48(s1)
    80002612:	01278d63          	beq	a5,s2,8000262c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	776080e7          	jalr	1910(ra) # 80000d8e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002620:	19848493          	add	s1,s1,408
    80002624:	ff3491e3          	bne	s1,s3,80002606 <kill+0x20>
  }
  return -1;
    80002628:	557d                	li	a0,-1
    8000262a:	a829                	j	80002644 <kill+0x5e>
      p->killed = 1;
    8000262c:	4785                	li	a5,1
    8000262e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002630:	4c98                	lw	a4,24(s1)
    80002632:	4789                	li	a5,2
    80002634:	00f70f63          	beq	a4,a5,80002652 <kill+0x6c>
      release(&p->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	754080e7          	jalr	1876(ra) # 80000d8e <release>
      return 0;
    80002642:	4501                	li	a0,0
}
    80002644:	70a2                	ld	ra,40(sp)
    80002646:	7402                	ld	s0,32(sp)
    80002648:	64e2                	ld	s1,24(sp)
    8000264a:	6942                	ld	s2,16(sp)
    8000264c:	69a2                	ld	s3,8(sp)
    8000264e:	6145                	add	sp,sp,48
    80002650:	8082                	ret
        p->state = RUNNABLE;
    80002652:	478d                	li	a5,3
    80002654:	cc9c                	sw	a5,24(s1)
    80002656:	b7cd                	j	80002638 <kill+0x52>

0000000080002658 <setkilled>:

void setkilled(struct proc *p)
{
    80002658:	1101                	add	sp,sp,-32
    8000265a:	ec06                	sd	ra,24(sp)
    8000265c:	e822                	sd	s0,16(sp)
    8000265e:	e426                	sd	s1,8(sp)
    80002660:	1000                	add	s0,sp,32
    80002662:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	676080e7          	jalr	1654(ra) # 80000cda <acquire>
  p->killed = 1;
    8000266c:	4785                	li	a5,1
    8000266e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	71c080e7          	jalr	1820(ra) # 80000d8e <release>
}
    8000267a:	60e2                	ld	ra,24(sp)
    8000267c:	6442                	ld	s0,16(sp)
    8000267e:	64a2                	ld	s1,8(sp)
    80002680:	6105                	add	sp,sp,32
    80002682:	8082                	ret

0000000080002684 <killed>:

int killed(struct proc *p)
{
    80002684:	1101                	add	sp,sp,-32
    80002686:	ec06                	sd	ra,24(sp)
    80002688:	e822                	sd	s0,16(sp)
    8000268a:	e426                	sd	s1,8(sp)
    8000268c:	e04a                	sd	s2,0(sp)
    8000268e:	1000                	add	s0,sp,32
    80002690:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	648080e7          	jalr	1608(ra) # 80000cda <acquire>
  k = p->killed;
    8000269a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000269e:	8526                	mv	a0,s1
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	6ee080e7          	jalr	1774(ra) # 80000d8e <release>
  return k;
}
    800026a8:	854a                	mv	a0,s2
    800026aa:	60e2                	ld	ra,24(sp)
    800026ac:	6442                	ld	s0,16(sp)
    800026ae:	64a2                	ld	s1,8(sp)
    800026b0:	6902                	ld	s2,0(sp)
    800026b2:	6105                	add	sp,sp,32
    800026b4:	8082                	ret

00000000800026b6 <wait>:
{
    800026b6:	715d                	add	sp,sp,-80
    800026b8:	e486                	sd	ra,72(sp)
    800026ba:	e0a2                	sd	s0,64(sp)
    800026bc:	fc26                	sd	s1,56(sp)
    800026be:	f84a                	sd	s2,48(sp)
    800026c0:	f44e                	sd	s3,40(sp)
    800026c2:	f052                	sd	s4,32(sp)
    800026c4:	ec56                	sd	s5,24(sp)
    800026c6:	e85a                	sd	s6,16(sp)
    800026c8:	e45e                	sd	s7,8(sp)
    800026ca:	e062                	sd	s8,0(sp)
    800026cc:	0880                	add	s0,sp,80
    800026ce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	444080e7          	jalr	1092(ra) # 80001b14 <myproc>
    800026d8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026da:	0022e517          	auipc	a0,0x22e
    800026de:	4b650513          	add	a0,a0,1206 # 80230b90 <wait_lock>
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5f8080e7          	jalr	1528(ra) # 80000cda <acquire>
    havekids = 0;
    800026ea:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026ec:	4a15                	li	s4,5
        havekids = 1;
    800026ee:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f0:	00235997          	auipc	s3,0x235
    800026f4:	eb898993          	add	s3,s3,-328 # 802375a8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026f8:	0022ec17          	auipc	s8,0x22e
    800026fc:	498c0c13          	add	s8,s8,1176 # 80230b90 <wait_lock>
    80002700:	a0d1                	j	800027c4 <wait+0x10e>
          pid = pp->pid;
    80002702:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002706:	000b0e63          	beqz	s6,80002722 <wait+0x6c>
    8000270a:	4691                	li	a3,4
    8000270c:	02c48613          	add	a2,s1,44
    80002710:	85da                	mv	a1,s6
    80002712:	05093503          	ld	a0,80(s2)
    80002716:	fffff097          	auipc	ra,0xfffff
    8000271a:	086080e7          	jalr	134(ra) # 8000179c <copyout>
    8000271e:	04054163          	bltz	a0,80002760 <wait+0xaa>
          freeproc(pp);
    80002722:	8526                	mv	a0,s1
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	5a2080e7          	jalr	1442(ra) # 80001cc6 <freeproc>
          release(&pp->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	660080e7          	jalr	1632(ra) # 80000d8e <release>
          release(&wait_lock);
    80002736:	0022e517          	auipc	a0,0x22e
    8000273a:	45a50513          	add	a0,a0,1114 # 80230b90 <wait_lock>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	650080e7          	jalr	1616(ra) # 80000d8e <release>
}
    80002746:	854e                	mv	a0,s3
    80002748:	60a6                	ld	ra,72(sp)
    8000274a:	6406                	ld	s0,64(sp)
    8000274c:	74e2                	ld	s1,56(sp)
    8000274e:	7942                	ld	s2,48(sp)
    80002750:	79a2                	ld	s3,40(sp)
    80002752:	7a02                	ld	s4,32(sp)
    80002754:	6ae2                	ld	s5,24(sp)
    80002756:	6b42                	ld	s6,16(sp)
    80002758:	6ba2                	ld	s7,8(sp)
    8000275a:	6c02                	ld	s8,0(sp)
    8000275c:	6161                	add	sp,sp,80
    8000275e:	8082                	ret
            release(&pp->lock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	62c080e7          	jalr	1580(ra) # 80000d8e <release>
            release(&wait_lock);
    8000276a:	0022e517          	auipc	a0,0x22e
    8000276e:	42650513          	add	a0,a0,1062 # 80230b90 <wait_lock>
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	61c080e7          	jalr	1564(ra) # 80000d8e <release>
            return -1;
    8000277a:	59fd                	li	s3,-1
    8000277c:	b7e9                	j	80002746 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000277e:	19848493          	add	s1,s1,408
    80002782:	03348463          	beq	s1,s3,800027aa <wait+0xf4>
      if (pp->parent == p)
    80002786:	7c9c                	ld	a5,56(s1)
    80002788:	ff279be3          	bne	a5,s2,8000277e <wait+0xc8>
        acquire(&pp->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	54c080e7          	jalr	1356(ra) # 80000cda <acquire>
        if (pp->state == ZOMBIE)
    80002796:	4c9c                	lw	a5,24(s1)
    80002798:	f74785e3          	beq	a5,s4,80002702 <wait+0x4c>
        release(&pp->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	5f0080e7          	jalr	1520(ra) # 80000d8e <release>
        havekids = 1;
    800027a6:	8756                	mv	a4,s5
    800027a8:	bfd9                	j	8000277e <wait+0xc8>
    if (!havekids || killed(p))
    800027aa:	c31d                	beqz	a4,800027d0 <wait+0x11a>
    800027ac:	854a                	mv	a0,s2
    800027ae:	00000097          	auipc	ra,0x0
    800027b2:	ed6080e7          	jalr	-298(ra) # 80002684 <killed>
    800027b6:	ed09                	bnez	a0,800027d0 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027b8:	85e2                	mv	a1,s8
    800027ba:	854a                	mv	a0,s2
    800027bc:	00000097          	auipc	ra,0x0
    800027c0:	c14080e7          	jalr	-1004(ra) # 800023d0 <sleep>
    havekids = 0;
    800027c4:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027c6:	0022e497          	auipc	s1,0x22e
    800027ca:	7e248493          	add	s1,s1,2018 # 80230fa8 <proc>
    800027ce:	bf65                	j	80002786 <wait+0xd0>
      release(&wait_lock);
    800027d0:	0022e517          	auipc	a0,0x22e
    800027d4:	3c050513          	add	a0,a0,960 # 80230b90 <wait_lock>
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	5b6080e7          	jalr	1462(ra) # 80000d8e <release>
      return -1;
    800027e0:	59fd                	li	s3,-1
    800027e2:	b795                	j	80002746 <wait+0x90>

00000000800027e4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027e4:	7179                	add	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	e052                	sd	s4,0(sp)
    800027f2:	1800                	add	s0,sp,48
    800027f4:	84aa                	mv	s1,a0
    800027f6:	892e                	mv	s2,a1
    800027f8:	89b2                	mv	s3,a2
    800027fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	318080e7          	jalr	792(ra) # 80001b14 <myproc>
  if (user_dst)
    80002804:	c08d                	beqz	s1,80002826 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002806:	86d2                	mv	a3,s4
    80002808:	864e                	mv	a2,s3
    8000280a:	85ca                	mv	a1,s2
    8000280c:	6928                	ld	a0,80(a0)
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	f8e080e7          	jalr	-114(ra) # 8000179c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002816:	70a2                	ld	ra,40(sp)
    80002818:	7402                	ld	s0,32(sp)
    8000281a:	64e2                	ld	s1,24(sp)
    8000281c:	6942                	ld	s2,16(sp)
    8000281e:	69a2                	ld	s3,8(sp)
    80002820:	6a02                	ld	s4,0(sp)
    80002822:	6145                	add	sp,sp,48
    80002824:	8082                	ret
    memmove((char *)dst, src, len);
    80002826:	000a061b          	sext.w	a2,s4
    8000282a:	85ce                	mv	a1,s3
    8000282c:	854a                	mv	a0,s2
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	604080e7          	jalr	1540(ra) # 80000e32 <memmove>
    return 0;
    80002836:	8526                	mv	a0,s1
    80002838:	bff9                	j	80002816 <either_copyout+0x32>

000000008000283a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000283a:	7179                	add	sp,sp,-48
    8000283c:	f406                	sd	ra,40(sp)
    8000283e:	f022                	sd	s0,32(sp)
    80002840:	ec26                	sd	s1,24(sp)
    80002842:	e84a                	sd	s2,16(sp)
    80002844:	e44e                	sd	s3,8(sp)
    80002846:	e052                	sd	s4,0(sp)
    80002848:	1800                	add	s0,sp,48
    8000284a:	892a                	mv	s2,a0
    8000284c:	84ae                	mv	s1,a1
    8000284e:	89b2                	mv	s3,a2
    80002850:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	2c2080e7          	jalr	706(ra) # 80001b14 <myproc>
  if (user_src)
    8000285a:	c08d                	beqz	s1,8000287c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000285c:	86d2                	mv	a3,s4
    8000285e:	864e                	mv	a2,s3
    80002860:	85ca                	mv	a1,s2
    80002862:	6928                	ld	a0,80(a0)
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	ffc080e7          	jalr	-4(ra) # 80001860 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000286c:	70a2                	ld	ra,40(sp)
    8000286e:	7402                	ld	s0,32(sp)
    80002870:	64e2                	ld	s1,24(sp)
    80002872:	6942                	ld	s2,16(sp)
    80002874:	69a2                	ld	s3,8(sp)
    80002876:	6a02                	ld	s4,0(sp)
    80002878:	6145                	add	sp,sp,48
    8000287a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000287c:	000a061b          	sext.w	a2,s4
    80002880:	85ce                	mv	a1,s3
    80002882:	854a                	mv	a0,s2
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	5ae080e7          	jalr	1454(ra) # 80000e32 <memmove>
    return 0;
    8000288c:	8526                	mv	a0,s1
    8000288e:	bff9                	j	8000286c <either_copyin+0x32>

0000000080002890 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002890:	715d                	add	sp,sp,-80
    80002892:	e486                	sd	ra,72(sp)
    80002894:	e0a2                	sd	s0,64(sp)
    80002896:	fc26                	sd	s1,56(sp)
    80002898:	f84a                	sd	s2,48(sp)
    8000289a:	f44e                	sd	s3,40(sp)
    8000289c:	f052                	sd	s4,32(sp)
    8000289e:	ec56                	sd	s5,24(sp)
    800028a0:	e85a                	sd	s6,16(sp)
    800028a2:	e45e                	sd	s7,8(sp)
    800028a4:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	83250513          	add	a0,a0,-1998 # 800080d8 <digits+0x98>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	cd8080e7          	jalr	-808(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028b6:	0022f497          	auipc	s1,0x22f
    800028ba:	84a48493          	add	s1,s1,-1974 # 80231100 <proc+0x158>
    800028be:	00235917          	auipc	s2,0x235
    800028c2:	e4290913          	add	s2,s2,-446 # 80237700 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028c8:	00006997          	auipc	s3,0x6
    800028cc:	9c898993          	add	s3,s3,-1592 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800028d0:	00006a97          	auipc	s5,0x6
    800028d4:	9c8a8a93          	add	s5,s5,-1592 # 80008298 <digits+0x258>
    printf("\n");
    800028d8:	00006a17          	auipc	s4,0x6
    800028dc:	800a0a13          	add	s4,s4,-2048 # 800080d8 <digits+0x98>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e0:	00006b97          	auipc	s7,0x6
    800028e4:	9f8b8b93          	add	s7,s7,-1544 # 800082d8 <states.0>
    800028e8:	a00d                	j	8000290a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028ea:	ed86a583          	lw	a1,-296(a3)
    800028ee:	8556                	mv	a0,s5
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c96080e7          	jalr	-874(ra) # 80000586 <printf>
    printf("\n");
    800028f8:	8552                	mv	a0,s4
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c8c080e7          	jalr	-884(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002902:	19848493          	add	s1,s1,408
    80002906:	03248263          	beq	s1,s2,8000292a <procdump+0x9a>
    if (p->state == UNUSED)
    8000290a:	86a6                	mv	a3,s1
    8000290c:	ec04a783          	lw	a5,-320(s1)
    80002910:	dbed                	beqz	a5,80002902 <procdump+0x72>
      state = "???";
    80002912:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002914:	fcfb6be3          	bltu	s6,a5,800028ea <procdump+0x5a>
    80002918:	02079713          	sll	a4,a5,0x20
    8000291c:	01d75793          	srl	a5,a4,0x1d
    80002920:	97de                	add	a5,a5,s7
    80002922:	6390                	ld	a2,0(a5)
    80002924:	f279                	bnez	a2,800028ea <procdump+0x5a>
      state = "???";
    80002926:	864e                	mv	a2,s3
    80002928:	b7c9                	j	800028ea <procdump+0x5a>
  }
}
    8000292a:	60a6                	ld	ra,72(sp)
    8000292c:	6406                	ld	s0,64(sp)
    8000292e:	74e2                	ld	s1,56(sp)
    80002930:	7942                	ld	s2,48(sp)
    80002932:	79a2                	ld	s3,40(sp)
    80002934:	7a02                	ld	s4,32(sp)
    80002936:	6ae2                	ld	s5,24(sp)
    80002938:	6b42                	ld	s6,16(sp)
    8000293a:	6ba2                	ld	s7,8(sp)
    8000293c:	6161                	add	sp,sp,80
    8000293e:	8082                	ret

0000000080002940 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002940:	711d                	add	sp,sp,-96
    80002942:	ec86                	sd	ra,88(sp)
    80002944:	e8a2                	sd	s0,80(sp)
    80002946:	e4a6                	sd	s1,72(sp)
    80002948:	e0ca                	sd	s2,64(sp)
    8000294a:	fc4e                	sd	s3,56(sp)
    8000294c:	f852                	sd	s4,48(sp)
    8000294e:	f456                	sd	s5,40(sp)
    80002950:	f05a                	sd	s6,32(sp)
    80002952:	ec5e                	sd	s7,24(sp)
    80002954:	e862                	sd	s8,16(sp)
    80002956:	e466                	sd	s9,8(sp)
    80002958:	e06a                	sd	s10,0(sp)
    8000295a:	1080                	add	s0,sp,96
    8000295c:	8b2a                	mv	s6,a0
    8000295e:	8bae                	mv	s7,a1
    80002960:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	1b2080e7          	jalr	434(ra) # 80001b14 <myproc>
    8000296a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000296c:	0022e517          	auipc	a0,0x22e
    80002970:	22450513          	add	a0,a0,548 # 80230b90 <wait_lock>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	366080e7          	jalr	870(ra) # 80000cda <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000297c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000297e:	4a15                	li	s4,5
        havekids = 1;
    80002980:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002982:	00235997          	auipc	s3,0x235
    80002986:	c2698993          	add	s3,s3,-986 # 802375a8 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000298a:	0022ed17          	auipc	s10,0x22e
    8000298e:	206d0d13          	add	s10,s10,518 # 80230b90 <wait_lock>
    80002992:	a8e9                	j	80002a6c <waitx+0x12c>
          pid = np->pid;
    80002994:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002998:	1684a783          	lw	a5,360(s1)
    8000299c:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800029a0:	16c4a703          	lw	a4,364(s1)
    800029a4:	9f3d                	addw	a4,a4,a5
    800029a6:	1704a783          	lw	a5,368(s1)
    800029aa:	9f99                	subw	a5,a5,a4
    800029ac:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029b0:	000b0e63          	beqz	s6,800029cc <waitx+0x8c>
    800029b4:	4691                	li	a3,4
    800029b6:	02c48613          	add	a2,s1,44
    800029ba:	85da                	mv	a1,s6
    800029bc:	05093503          	ld	a0,80(s2)
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	ddc080e7          	jalr	-548(ra) # 8000179c <copyout>
    800029c8:	04054363          	bltz	a0,80002a0e <waitx+0xce>
          freeproc(np);
    800029cc:	8526                	mv	a0,s1
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	2f8080e7          	jalr	760(ra) # 80001cc6 <freeproc>
          release(&np->lock);
    800029d6:	8526                	mv	a0,s1
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	3b6080e7          	jalr	950(ra) # 80000d8e <release>
          release(&wait_lock);
    800029e0:	0022e517          	auipc	a0,0x22e
    800029e4:	1b050513          	add	a0,a0,432 # 80230b90 <wait_lock>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	3a6080e7          	jalr	934(ra) # 80000d8e <release>
  }
}
    800029f0:	854e                	mv	a0,s3
    800029f2:	60e6                	ld	ra,88(sp)
    800029f4:	6446                	ld	s0,80(sp)
    800029f6:	64a6                	ld	s1,72(sp)
    800029f8:	6906                	ld	s2,64(sp)
    800029fa:	79e2                	ld	s3,56(sp)
    800029fc:	7a42                	ld	s4,48(sp)
    800029fe:	7aa2                	ld	s5,40(sp)
    80002a00:	7b02                	ld	s6,32(sp)
    80002a02:	6be2                	ld	s7,24(sp)
    80002a04:	6c42                	ld	s8,16(sp)
    80002a06:	6ca2                	ld	s9,8(sp)
    80002a08:	6d02                	ld	s10,0(sp)
    80002a0a:	6125                	add	sp,sp,96
    80002a0c:	8082                	ret
            release(&np->lock);
    80002a0e:	8526                	mv	a0,s1
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	37e080e7          	jalr	894(ra) # 80000d8e <release>
            release(&wait_lock);
    80002a18:	0022e517          	auipc	a0,0x22e
    80002a1c:	17850513          	add	a0,a0,376 # 80230b90 <wait_lock>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	36e080e7          	jalr	878(ra) # 80000d8e <release>
            return -1;
    80002a28:	59fd                	li	s3,-1
    80002a2a:	b7d9                	j	800029f0 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a2c:	19848493          	add	s1,s1,408
    80002a30:	03348463          	beq	s1,s3,80002a58 <waitx+0x118>
      if (np->parent == p)
    80002a34:	7c9c                	ld	a5,56(s1)
    80002a36:	ff279be3          	bne	a5,s2,80002a2c <waitx+0xec>
        acquire(&np->lock);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	29e080e7          	jalr	670(ra) # 80000cda <acquire>
        if (np->state == ZOMBIE)
    80002a44:	4c9c                	lw	a5,24(s1)
    80002a46:	f54787e3          	beq	a5,s4,80002994 <waitx+0x54>
        release(&np->lock);
    80002a4a:	8526                	mv	a0,s1
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	342080e7          	jalr	834(ra) # 80000d8e <release>
        havekids = 1;
    80002a54:	8756                	mv	a4,s5
    80002a56:	bfd9                	j	80002a2c <waitx+0xec>
    if (!havekids || p->killed)
    80002a58:	c305                	beqz	a4,80002a78 <waitx+0x138>
    80002a5a:	02892783          	lw	a5,40(s2)
    80002a5e:	ef89                	bnez	a5,80002a78 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a60:	85ea                	mv	a1,s10
    80002a62:	854a                	mv	a0,s2
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	96c080e7          	jalr	-1684(ra) # 800023d0 <sleep>
    havekids = 0;
    80002a6c:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002a6e:	0022e497          	auipc	s1,0x22e
    80002a72:	53a48493          	add	s1,s1,1338 # 80230fa8 <proc>
    80002a76:	bf7d                	j	80002a34 <waitx+0xf4>
      release(&wait_lock);
    80002a78:	0022e517          	auipc	a0,0x22e
    80002a7c:	11850513          	add	a0,a0,280 # 80230b90 <wait_lock>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	30e080e7          	jalr	782(ra) # 80000d8e <release>
      return -1;
    80002a88:	59fd                	li	s3,-1
    80002a8a:	b79d                	j	800029f0 <waitx+0xb0>

0000000080002a8c <update_time>:

void update_time()
{
    80002a8c:	7139                	add	sp,sp,-64
    80002a8e:	fc06                	sd	ra,56(sp)
    80002a90:	f822                	sd	s0,48(sp)
    80002a92:	f426                	sd	s1,40(sp)
    80002a94:	f04a                	sd	s2,32(sp)
    80002a96:	ec4e                	sd	s3,24(sp)
    80002a98:	e852                	sd	s4,16(sp)
    80002a9a:	e456                	sd	s5,8(sp)
    80002a9c:	0080                	add	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a9e:	0022e497          	auipc	s1,0x22e
    80002aa2:	50a48493          	add	s1,s1,1290 # 80230fa8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002aa6:	4991                	li	s3,4
      p->rtime++;
      p->last_run_time++;
      p->spent_slp_time = 0;
      // p->n_run++;
    }
    else if (p->state == SLEEPING)
    80002aa8:	4a09                	li	s4,2
    {
      p->last_run_time = 0;
      p->spent_slp_time++;
    }
    else if (p->state == RUNNABLE)
    80002aaa:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002aac:	00235917          	auipc	s2,0x235
    80002ab0:	afc90913          	add	s2,s2,-1284 # 802375a8 <tickslock>
    80002ab4:	a035                	j	80002ae0 <update_time+0x54>
      p->rtime++;
    80002ab6:	1684a783          	lw	a5,360(s1)
    80002aba:	2785                	addw	a5,a5,1
    80002abc:	16f4a423          	sw	a5,360(s1)
      p->last_run_time++;
    80002ac0:	1904a783          	lw	a5,400(s1)
    80002ac4:	2785                	addw	a5,a5,1
    80002ac6:	18f4a823          	sw	a5,400(s1)
      p->spent_slp_time = 0;
    80002aca:	1804aa23          	sw	zero,404(s1)
    {
      p->last_run_time = 0;
      p->ready_queue_time++;
    }
    // printf("%d %d %d", p->pid, p., p->state);
    release(&p->lock);
    80002ace:	8526                	mv	a0,s1
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	2be080e7          	jalr	702(ra) # 80000d8e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ad8:	19848493          	add	s1,s1,408
    80002adc:	03248e63          	beq	s1,s2,80002b18 <update_time+0x8c>
    acquire(&p->lock);
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	1f8080e7          	jalr	504(ra) # 80000cda <acquire>
    if (p->state == RUNNING)
    80002aea:	4c9c                	lw	a5,24(s1)
    80002aec:	fd3785e3          	beq	a5,s3,80002ab6 <update_time+0x2a>
    else if (p->state == SLEEPING)
    80002af0:	01478c63          	beq	a5,s4,80002b08 <update_time+0x7c>
    else if (p->state == RUNNABLE)
    80002af4:	fd579de3          	bne	a5,s5,80002ace <update_time+0x42>
      p->last_run_time = 0;
    80002af8:	1804a823          	sw	zero,400(s1)
      p->ready_queue_time++;
    80002afc:	18c4a783          	lw	a5,396(s1)
    80002b00:	2785                	addw	a5,a5,1
    80002b02:	18f4a623          	sw	a5,396(s1)
    80002b06:	b7e1                	j	80002ace <update_time+0x42>
      p->last_run_time = 0;
    80002b08:	1804a823          	sw	zero,400(s1)
      p->spent_slp_time++;
    80002b0c:	1944a783          	lw	a5,404(s1)
    80002b10:	2785                	addw	a5,a5,1
    80002b12:	18f4aa23          	sw	a5,404(s1)
    80002b16:	bf65                	j	80002ace <update_time+0x42>
  //     {
  //       printf("%d %d %d\n", p->pid, ticks, p->priority);
  //     }
  //   }
  // }
    80002b18:	70e2                	ld	ra,56(sp)
    80002b1a:	7442                	ld	s0,48(sp)
    80002b1c:	74a2                	ld	s1,40(sp)
    80002b1e:	7902                	ld	s2,32(sp)
    80002b20:	69e2                	ld	s3,24(sp)
    80002b22:	6a42                	ld	s4,16(sp)
    80002b24:	6aa2                	ld	s5,8(sp)
    80002b26:	6121                	add	sp,sp,64
    80002b28:	8082                	ret

0000000080002b2a <swtch>:
    80002b2a:	00153023          	sd	ra,0(a0)
    80002b2e:	00253423          	sd	sp,8(a0)
    80002b32:	e900                	sd	s0,16(a0)
    80002b34:	ed04                	sd	s1,24(a0)
    80002b36:	03253023          	sd	s2,32(a0)
    80002b3a:	03353423          	sd	s3,40(a0)
    80002b3e:	03453823          	sd	s4,48(a0)
    80002b42:	03553c23          	sd	s5,56(a0)
    80002b46:	05653023          	sd	s6,64(a0)
    80002b4a:	05753423          	sd	s7,72(a0)
    80002b4e:	05853823          	sd	s8,80(a0)
    80002b52:	05953c23          	sd	s9,88(a0)
    80002b56:	07a53023          	sd	s10,96(a0)
    80002b5a:	07b53423          	sd	s11,104(a0)
    80002b5e:	0005b083          	ld	ra,0(a1)
    80002b62:	0085b103          	ld	sp,8(a1)
    80002b66:	6980                	ld	s0,16(a1)
    80002b68:	6d84                	ld	s1,24(a1)
    80002b6a:	0205b903          	ld	s2,32(a1)
    80002b6e:	0285b983          	ld	s3,40(a1)
    80002b72:	0305ba03          	ld	s4,48(a1)
    80002b76:	0385ba83          	ld	s5,56(a1)
    80002b7a:	0405bb03          	ld	s6,64(a1)
    80002b7e:	0485bb83          	ld	s7,72(a1)
    80002b82:	0505bc03          	ld	s8,80(a1)
    80002b86:	0585bc83          	ld	s9,88(a1)
    80002b8a:	0605bd03          	ld	s10,96(a1)
    80002b8e:	0685bd83          	ld	s11,104(a1)
    80002b92:	8082                	ret

0000000080002b94 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b94:	1141                	add	sp,sp,-16
    80002b96:	e406                	sd	ra,8(sp)
    80002b98:	e022                	sd	s0,0(sp)
    80002b9a:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002b9c:	00005597          	auipc	a1,0x5
    80002ba0:	76c58593          	add	a1,a1,1900 # 80008308 <states.0+0x30>
    80002ba4:	00235517          	auipc	a0,0x235
    80002ba8:	a0450513          	add	a0,a0,-1532 # 802375a8 <tickslock>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	09e080e7          	jalr	158(ra) # 80000c4a <initlock>
}
    80002bb4:	60a2                	ld	ra,8(sp)
    80002bb6:	6402                	ld	s0,0(sp)
    80002bb8:	0141                	add	sp,sp,16
    80002bba:	8082                	ret

0000000080002bbc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bbc:	1141                	add	sp,sp,-16
    80002bbe:	e422                	sd	s0,8(sp)
    80002bc0:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc2:	00003797          	auipc	a5,0x3
    80002bc6:	66e78793          	add	a5,a5,1646 # 80006230 <kernelvec>
    80002bca:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bce:	6422                	ld	s0,8(sp)
    80002bd0:	0141                	add	sp,sp,16
    80002bd2:	8082                	ret

0000000080002bd4 <handel_page_fault>:

int handel_page_fault(pagetable_t pagetable, void *v)
{
    80002bd4:	7179                	add	sp,sp,-48
    80002bd6:	f406                	sd	ra,40(sp)
    80002bd8:	f022                	sd	s0,32(sp)
    80002bda:	ec26                	sd	s1,24(sp)
    80002bdc:	e84a                	sd	s2,16(sp)
    80002bde:	e44e                	sd	s3,8(sp)
    80002be0:	1800                	add	s0,sp,48
    80002be2:	892a                	mv	s2,a0
    80002be4:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	f2e080e7          	jalr	-210(ra) # 80001b14 <myproc>
  uint64 a = PGROUNDDOWN(p->trapframe->sp);
  if ((uint64)v >= MAXVA)
    80002bee:	57fd                	li	a5,-1
    80002bf0:	83e9                	srl	a5,a5,0x1a
    80002bf2:	0897e363          	bltu	a5,s1,80002c78 <handel_page_fault+0xa4>
  uint64 a = PGROUNDDOWN(p->trapframe->sp);
    80002bf6:	6d3c                	ld	a5,88(a0)
    80002bf8:	7b94                	ld	a3,48(a5)
    80002bfa:	77fd                	lui	a5,0xfffff
    80002bfc:	8ff5                	and	a5,a5,a3
  {
    return 0;
  }
  else if (((uint64)v <= a) && ((uint64)v >= a - PGSIZE))
    80002bfe:	0097e763          	bltu	a5,s1,80002c0c <handel_page_fault+0x38>
    80002c02:	76fd                	lui	a3,0xfffff
    80002c04:	97b6                	add	a5,a5,a3
  {
    return 0;
    80002c06:	4501                	li	a0,0
  else if (((uint64)v <= a) && ((uint64)v >= a - PGSIZE))
    80002c08:	06f4f963          	bgeu	s1,a5,80002c7a <handel_page_fault+0xa6>
  }
  pte_t *pte = walk(pagetable, (uint64)v, 0);
    80002c0c:	4601                	li	a2,0
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	854a                	mv	a0,s2
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	4a6080e7          	jalr	1190(ra) # 800010b8 <walk>
    80002c1a:	84aa                	mv	s1,a0
  uint64 flags;
  v = (void *)PGROUNDDOWN((uint64)v);
  if (pte==0 || *pte == 0)
    80002c1c:	c535                	beqz	a0,80002c88 <handel_page_fault+0xb4>
    80002c1e:	00053983          	ld	s3,0(a0)
  {
    return 0;
    80002c22:	4501                	li	a0,0
  if (pte==0 || *pte == 0)
    80002c24:	04098b63          	beqz	s3,80002c7a <handel_page_fault+0xa6>
  }
  else
  {
    flags = PTE_FLAGS(*pte);
    if ((flags & PTE_C) == 0)
    80002c28:	0809f793          	and	a5,s3,128
    {
      return 1;
    80002c2c:	4505                	li	a0,1
    if ((flags & PTE_C) == 0)
    80002c2e:	c7b1                	beqz	a5,80002c7a <handel_page_fault+0xa6>
    }
    else
    {
      flags = flags & ~PTE_C;
      flags = flags | PTE_W;
      char *mem = (char *)kalloc();
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	f7e080e7          	jalr	-130(ra) # 80000bae <kalloc>
    80002c38:	892a                	mv	s2,a0
      if (mem == 0)
      {
        return 0;
    80002c3a:	4501                	li	a0,0
      if (mem == 0)
    80002c3c:	02090f63          	beqz	s2,80002c7a <handel_page_fault+0xa6>
      }
      else
      {
        memmove(mem, (char *)PTE2PA(*pte), PGSIZE);
    80002c40:	608c                	ld	a1,0(s1)
    80002c42:	81a9                	srl	a1,a1,0xa
    80002c44:	6605                	lui	a2,0x1
    80002c46:	05b2                	sll	a1,a1,0xc
    80002c48:	854a                	mv	a0,s2
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	1e8080e7          	jalr	488(ra) # 80000e32 <memmove>
        kfree((void *)PTE2PA(*pte));
    80002c52:	6088                	ld	a0,0(s1)
    80002c54:	8129                	srl	a0,a0,0xa
    80002c56:	0532                	sll	a0,a0,0xc
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	d8c080e7          	jalr	-628(ra) # 800009e4 <kfree>
        *pte = PA2PTE(mem) | flags;
    80002c60:	00c95793          	srl	a5,s2,0xc
    80002c64:	07aa                	sll	a5,a5,0xa
      flags = flags & ~PTE_C;
    80002c66:	37f9f993          	and	s3,s3,895
        *pte = PA2PTE(mem) | flags;
    80002c6a:	0137e7b3          	or	a5,a5,s3
    80002c6e:	0047e793          	or	a5,a5,4
    80002c72:	e09c                	sd	a5,0(s1)
      }
    }
  }
  return 1;
    80002c74:	4505                	li	a0,1
    80002c76:	a011                	j	80002c7a <handel_page_fault+0xa6>
    return 0;
    80002c78:	4501                	li	a0,0
}
    80002c7a:	70a2                	ld	ra,40(sp)
    80002c7c:	7402                	ld	s0,32(sp)
    80002c7e:	64e2                	ld	s1,24(sp)
    80002c80:	6942                	ld	s2,16(sp)
    80002c82:	69a2                	ld	s3,8(sp)
    80002c84:	6145                	add	sp,sp,48
    80002c86:	8082                	ret
    return 0;
    80002c88:	4501                	li	a0,0
    80002c8a:	bfc5                	j	80002c7a <handel_page_fault+0xa6>

0000000080002c8c <usertrapret>:
//
// return to user space
//

void usertrapret(void)
{
    80002c8c:	1141                	add	sp,sp,-16
    80002c8e:	e406                	sd	ra,8(sp)
    80002c90:	e022                	sd	s0,0(sp)
    80002c92:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	e80080e7          	jalr	-384(ra) # 80001b14 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ca0:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ca6:	00004697          	auipc	a3,0x4
    80002caa:	35a68693          	add	a3,a3,858 # 80007000 <_trampoline>
    80002cae:	00004717          	auipc	a4,0x4
    80002cb2:	35270713          	add	a4,a4,850 # 80007000 <_trampoline>
    80002cb6:	8f15                	sub	a4,a4,a3
    80002cb8:	040007b7          	lui	a5,0x4000
    80002cbc:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002cbe:	07b2                	sll	a5,a5,0xc
    80002cc0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cc2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cc6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cc8:	18002673          	csrr	a2,satp
    80002ccc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cce:	6d30                	ld	a2,88(a0)
    80002cd0:	6138                	ld	a4,64(a0)
    80002cd2:	6585                	lui	a1,0x1
    80002cd4:	972e                	add	a4,a4,a1
    80002cd6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cd8:	6d38                	ld	a4,88(a0)
    80002cda:	00000617          	auipc	a2,0x0
    80002cde:	14260613          	add	a2,a2,322 # 80002e1c <usertrap>
    80002ce2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ce4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ce6:	8612                	mv	a2,tp
    80002ce8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cea:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cee:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cf2:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cf6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cfa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cfc:	6f18                	ld	a4,24(a4)
    80002cfe:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d02:	6928                	ld	a0,80(a0)
    80002d04:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d06:	00004717          	auipc	a4,0x4
    80002d0a:	39670713          	add	a4,a4,918 # 8000709c <userret>
    80002d0e:	8f15                	sub	a4,a4,a3
    80002d10:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d12:	577d                	li	a4,-1
    80002d14:	177e                	sll	a4,a4,0x3f
    80002d16:	8d59                	or	a0,a0,a4
    80002d18:	9782                	jalr	a5
}
    80002d1a:	60a2                	ld	ra,8(sp)
    80002d1c:	6402                	ld	s0,0(sp)
    80002d1e:	0141                	add	sp,sp,16
    80002d20:	8082                	ret

0000000080002d22 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002d22:	1101                	add	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	e04a                	sd	s2,0(sp)
    80002d2c:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002d2e:	00235917          	auipc	s2,0x235
    80002d32:	87a90913          	add	s2,s2,-1926 # 802375a8 <tickslock>
    80002d36:	854a                	mv	a0,s2
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	fa2080e7          	jalr	-94(ra) # 80000cda <acquire>
  ticks++;
    80002d40:	00006497          	auipc	s1,0x6
    80002d44:	bb048493          	add	s1,s1,-1104 # 800088f0 <ticks>
    80002d48:	409c                	lw	a5,0(s1)
    80002d4a:	2785                	addw	a5,a5,1
    80002d4c:	c09c                	sw	a5,0(s1)
  update_time();
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	d3e080e7          	jalr	-706(ra) # 80002a8c <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002d56:	8526                	mv	a0,s1
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	6dc080e7          	jalr	1756(ra) # 80002434 <wakeup>
  release(&tickslock);
    80002d60:	854a                	mv	a0,s2
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	02c080e7          	jalr	44(ra) # 80000d8e <release>
}
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6902                	ld	s2,0(sp)
    80002d72:	6105                	add	sp,sp,32
    80002d74:	8082                	ret

0000000080002d76 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d76:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002d7a:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002d7c:	0807df63          	bgez	a5,80002e1a <devintr+0xa4>
{
    80002d80:	1101                	add	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	e426                	sd	s1,8(sp)
    80002d88:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002d8a:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002d8e:	46a5                	li	a3,9
    80002d90:	00d70d63          	beq	a4,a3,80002daa <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002d94:	577d                	li	a4,-1
    80002d96:	177e                	sll	a4,a4,0x3f
    80002d98:	0705                	add	a4,a4,1
    return 0;
    80002d9a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002d9c:	04e78e63          	beq	a5,a4,80002df8 <devintr+0x82>
  }
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6105                	add	sp,sp,32
    80002da8:	8082                	ret
    int irq = plic_claim();
    80002daa:	00003097          	auipc	ra,0x3
    80002dae:	58e080e7          	jalr	1422(ra) # 80006338 <plic_claim>
    80002db2:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002db4:	47a9                	li	a5,10
    80002db6:	02f50763          	beq	a0,a5,80002de4 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002dba:	4785                	li	a5,1
    80002dbc:	02f50963          	beq	a0,a5,80002dee <devintr+0x78>
    return 1;
    80002dc0:	4505                	li	a0,1
    else if (irq)
    80002dc2:	dcf9                	beqz	s1,80002da0 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002dc4:	85a6                	mv	a1,s1
    80002dc6:	00005517          	auipc	a0,0x5
    80002dca:	54a50513          	add	a0,a0,1354 # 80008310 <states.0+0x38>
    80002dce:	ffffd097          	auipc	ra,0xffffd
    80002dd2:	7b8080e7          	jalr	1976(ra) # 80000586 <printf>
      plic_complete(irq);
    80002dd6:	8526                	mv	a0,s1
    80002dd8:	00003097          	auipc	ra,0x3
    80002ddc:	584080e7          	jalr	1412(ra) # 8000635c <plic_complete>
    return 1;
    80002de0:	4505                	li	a0,1
    80002de2:	bf7d                	j	80002da0 <devintr+0x2a>
      uartintr();
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	bb0080e7          	jalr	-1104(ra) # 80000994 <uartintr>
    if (irq)
    80002dec:	b7ed                	j	80002dd6 <devintr+0x60>
      virtio_disk_intr();
    80002dee:	00004097          	auipc	ra,0x4
    80002df2:	a34080e7          	jalr	-1484(ra) # 80006822 <virtio_disk_intr>
    if (irq)
    80002df6:	b7c5                	j	80002dd6 <devintr+0x60>
    if (cpuid() == 0)
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	cf0080e7          	jalr	-784(ra) # 80001ae8 <cpuid>
    80002e00:	c901                	beqz	a0,80002e10 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e02:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e06:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e08:	14479073          	csrw	sip,a5
    return 2;
    80002e0c:	4509                	li	a0,2
    80002e0e:	bf49                	j	80002da0 <devintr+0x2a>
      clockintr();
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	f12080e7          	jalr	-238(ra) # 80002d22 <clockintr>
    80002e18:	b7ed                	j	80002e02 <devintr+0x8c>
}
    80002e1a:	8082                	ret

0000000080002e1c <usertrap>:
{
    80002e1c:	1101                	add	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	e04a                	sd	s2,0(sp)
    80002e26:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e28:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002e2c:	1007f793          	and	a5,a5,256
    80002e30:	e7b5                	bnez	a5,80002e9c <usertrap+0x80>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e32:	00003797          	auipc	a5,0x3
    80002e36:	3fe78793          	add	a5,a5,1022 # 80006230 <kernelvec>
    80002e3a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	cd6080e7          	jalr	-810(ra) # 80001b14 <myproc>
    80002e46:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e48:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e4a:	14102773          	csrr	a4,sepc
    80002e4e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e50:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e54:	47a1                	li	a5,8
    80002e56:	04f70b63          	beq	a4,a5,80002eac <usertrap+0x90>
  else if ((which_dev = devintr()) != 0)
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	f1c080e7          	jalr	-228(ra) # 80002d76 <devintr>
    80002e62:	892a                	mv	s2,a0
    80002e64:	e165                	bnez	a0,80002f44 <usertrap+0x128>
    80002e66:	14202773          	csrr	a4,scause
  else if (r_scause() == 15 || r_scause() == 13)
    80002e6a:	47bd                	li	a5,15
    80002e6c:	00f70763          	beq	a4,a5,80002e7a <usertrap+0x5e>
    80002e70:	14202773          	csrr	a4,scause
    80002e74:	47b5                	li	a5,13
    80002e76:	08f71a63          	bne	a4,a5,80002f0a <usertrap+0xee>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e7a:	143027f3          	csrr	a5,stval
    if (r_stval() == 0)
    80002e7e:	c3c1                	beqz	a5,80002efe <usertrap+0xe2>
    80002e80:	143025f3          	csrr	a1,stval
    int a = handel_page_fault(p->pagetable, (void *)r_stval());
    80002e84:	68a8                	ld	a0,80(s1)
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	d4e080e7          	jalr	-690(ra) # 80002bd4 <handel_page_fault>
    if (a == 0)
    80002e8e:	e131                	bnez	a0,80002ed2 <usertrap+0xb6>
      setkilled(p);
    80002e90:	8526                	mv	a0,s1
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	7c6080e7          	jalr	1990(ra) # 80002658 <setkilled>
    80002e9a:	a825                	j	80002ed2 <usertrap+0xb6>
    panic("usertrap: not from user mode");
    80002e9c:	00005517          	auipc	a0,0x5
    80002ea0:	49450513          	add	a0,a0,1172 # 80008330 <states.0+0x58>
    80002ea4:	ffffd097          	auipc	ra,0xffffd
    80002ea8:	698080e7          	jalr	1688(ra) # 8000053c <panic>
    if (killed(p))
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	7d8080e7          	jalr	2008(ra) # 80002684 <killed>
    80002eb4:	ed1d                	bnez	a0,80002ef2 <usertrap+0xd6>
    p->trapframe->epc += 4;
    80002eb6:	6cb8                	ld	a4,88(s1)
    80002eb8:	6f1c                	ld	a5,24(a4)
    80002eba:	0791                	add	a5,a5,4
    80002ebc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ebe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ec2:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ec6:	10079073          	csrw	sstatus,a5
    syscall();
    80002eca:	00000097          	auipc	ra,0x0
    80002ece:	2ee080e7          	jalr	750(ra) # 800031b8 <syscall>
  if (killed(p))
    80002ed2:	8526                	mv	a0,s1
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	7b0080e7          	jalr	1968(ra) # 80002684 <killed>
    80002edc:	e93d                	bnez	a0,80002f52 <usertrap+0x136>
  usertrapret();
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	dae080e7          	jalr	-594(ra) # 80002c8c <usertrapret>
}
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	64a2                	ld	s1,8(sp)
    80002eec:	6902                	ld	s2,0(sp)
    80002eee:	6105                	add	sp,sp,32
    80002ef0:	8082                	ret
      exit(-1);
    80002ef2:	557d                	li	a0,-1
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	610080e7          	jalr	1552(ra) # 80002504 <exit>
    80002efc:	bf6d                	j	80002eb6 <usertrap+0x9a>
      setkilled(p);
    80002efe:	8526                	mv	a0,s1
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	758080e7          	jalr	1880(ra) # 80002658 <setkilled>
    80002f08:	bfa5                	j	80002e80 <usertrap+0x64>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f0a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f0e:	5890                	lw	a2,48(s1)
    80002f10:	00005517          	auipc	a0,0x5
    80002f14:	44050513          	add	a0,a0,1088 # 80008350 <states.0+0x78>
    80002f18:	ffffd097          	auipc	ra,0xffffd
    80002f1c:	66e080e7          	jalr	1646(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f24:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	45850513          	add	a0,a0,1112 # 80008380 <states.0+0xa8>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	656080e7          	jalr	1622(ra) # 80000586 <printf>
    setkilled(p);
    80002f38:	8526                	mv	a0,s1
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	71e080e7          	jalr	1822(ra) # 80002658 <setkilled>
    80002f42:	bf41                	j	80002ed2 <usertrap+0xb6>
  if (killed(p))
    80002f44:	8526                	mv	a0,s1
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	73e080e7          	jalr	1854(ra) # 80002684 <killed>
    80002f4e:	c901                	beqz	a0,80002f5e <usertrap+0x142>
    80002f50:	a011                	j	80002f54 <usertrap+0x138>
    80002f52:	4901                	li	s2,0
    exit(-1);
    80002f54:	557d                	li	a0,-1
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	5ae080e7          	jalr	1454(ra) # 80002504 <exit>
  if (which_dev == 2)
    80002f5e:	4789                	li	a5,2
    80002f60:	f6f91fe3          	bne	s2,a5,80002ede <usertrap+0xc2>
    yield();
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	388080e7          	jalr	904(ra) # 800022ec <yield>
    80002f6c:	bf8d                	j	80002ede <usertrap+0xc2>

0000000080002f6e <kerneltrap>:
{
    80002f6e:	7179                	add	sp,sp,-48
    80002f70:	f406                	sd	ra,40(sp)
    80002f72:	f022                	sd	s0,32(sp)
    80002f74:	ec26                	sd	s1,24(sp)
    80002f76:	e84a                	sd	s2,16(sp)
    80002f78:	e44e                	sd	s3,8(sp)
    80002f7a:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f7c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f80:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f84:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f88:	1004f793          	and	a5,s1,256
    80002f8c:	cb85                	beqz	a5,80002fbc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f8e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f92:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002f94:	ef85                	bnez	a5,80002fcc <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f96:	00000097          	auipc	ra,0x0
    80002f9a:	de0080e7          	jalr	-544(ra) # 80002d76 <devintr>
    80002f9e:	cd1d                	beqz	a0,80002fdc <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fa0:	4789                	li	a5,2
    80002fa2:	06f50a63          	beq	a0,a5,80003016 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fa6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002faa:	10049073          	csrw	sstatus,s1
}
    80002fae:	70a2                	ld	ra,40(sp)
    80002fb0:	7402                	ld	s0,32(sp)
    80002fb2:	64e2                	ld	s1,24(sp)
    80002fb4:	6942                	ld	s2,16(sp)
    80002fb6:	69a2                	ld	s3,8(sp)
    80002fb8:	6145                	add	sp,sp,48
    80002fba:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	3e450513          	add	a0,a0,996 # 800083a0 <states.0+0xc8>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	578080e7          	jalr	1400(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	3fc50513          	add	a0,a0,1020 # 800083c8 <states.0+0xf0>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	568080e7          	jalr	1384(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002fdc:	85ce                	mv	a1,s3
    80002fde:	00005517          	auipc	a0,0x5
    80002fe2:	40a50513          	add	a0,a0,1034 # 800083e8 <states.0+0x110>
    80002fe6:	ffffd097          	auipc	ra,0xffffd
    80002fea:	5a0080e7          	jalr	1440(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ff2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ff6:	00005517          	auipc	a0,0x5
    80002ffa:	40250513          	add	a0,a0,1026 # 800083f8 <states.0+0x120>
    80002ffe:	ffffd097          	auipc	ra,0xffffd
    80003002:	588080e7          	jalr	1416(ra) # 80000586 <printf>
    panic("kerneltrap");
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	40a50513          	add	a0,a0,1034 # 80008410 <states.0+0x138>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	52e080e7          	jalr	1326(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	afe080e7          	jalr	-1282(ra) # 80001b14 <myproc>
    8000301e:	d541                	beqz	a0,80002fa6 <kerneltrap+0x38>
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	af4080e7          	jalr	-1292(ra) # 80001b14 <myproc>
    80003028:	4d18                	lw	a4,24(a0)
    8000302a:	4791                	li	a5,4
    8000302c:	f6f71de3          	bne	a4,a5,80002fa6 <kerneltrap+0x38>
    yield();
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	2bc080e7          	jalr	700(ra) # 800022ec <yield>
    80003038:	b7bd                	j	80002fa6 <kerneltrap+0x38>

000000008000303a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000303a:	1101                	add	sp,sp,-32
    8000303c:	ec06                	sd	ra,24(sp)
    8000303e:	e822                	sd	s0,16(sp)
    80003040:	e426                	sd	s1,8(sp)
    80003042:	1000                	add	s0,sp,32
    80003044:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	ace080e7          	jalr	-1330(ra) # 80001b14 <myproc>
  switch (n) {
    8000304e:	4795                	li	a5,5
    80003050:	0497e163          	bltu	a5,s1,80003092 <argraw+0x58>
    80003054:	048a                	sll	s1,s1,0x2
    80003056:	00005717          	auipc	a4,0x5
    8000305a:	3f270713          	add	a4,a4,1010 # 80008448 <states.0+0x170>
    8000305e:	94ba                	add	s1,s1,a4
    80003060:	409c                	lw	a5,0(s1)
    80003062:	97ba                	add	a5,a5,a4
    80003064:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003066:	6d3c                	ld	a5,88(a0)
    80003068:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6105                	add	sp,sp,32
    80003072:	8082                	ret
    return p->trapframe->a1;
    80003074:	6d3c                	ld	a5,88(a0)
    80003076:	7fa8                	ld	a0,120(a5)
    80003078:	bfcd                	j	8000306a <argraw+0x30>
    return p->trapframe->a2;
    8000307a:	6d3c                	ld	a5,88(a0)
    8000307c:	63c8                	ld	a0,128(a5)
    8000307e:	b7f5                	j	8000306a <argraw+0x30>
    return p->trapframe->a3;
    80003080:	6d3c                	ld	a5,88(a0)
    80003082:	67c8                	ld	a0,136(a5)
    80003084:	b7dd                	j	8000306a <argraw+0x30>
    return p->trapframe->a4;
    80003086:	6d3c                	ld	a5,88(a0)
    80003088:	6bc8                	ld	a0,144(a5)
    8000308a:	b7c5                	j	8000306a <argraw+0x30>
    return p->trapframe->a5;
    8000308c:	6d3c                	ld	a5,88(a0)
    8000308e:	6fc8                	ld	a0,152(a5)
    80003090:	bfe9                	j	8000306a <argraw+0x30>
  panic("argraw");
    80003092:	00005517          	auipc	a0,0x5
    80003096:	38e50513          	add	a0,a0,910 # 80008420 <states.0+0x148>
    8000309a:	ffffd097          	auipc	ra,0xffffd
    8000309e:	4a2080e7          	jalr	1186(ra) # 8000053c <panic>

00000000800030a2 <fetchaddr>:
{
    800030a2:	1101                	add	sp,sp,-32
    800030a4:	ec06                	sd	ra,24(sp)
    800030a6:	e822                	sd	s0,16(sp)
    800030a8:	e426                	sd	s1,8(sp)
    800030aa:	e04a                	sd	s2,0(sp)
    800030ac:	1000                	add	s0,sp,32
    800030ae:	84aa                	mv	s1,a0
    800030b0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	a62080e7          	jalr	-1438(ra) # 80001b14 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030ba:	653c                	ld	a5,72(a0)
    800030bc:	02f4f863          	bgeu	s1,a5,800030ec <fetchaddr+0x4a>
    800030c0:	00848713          	add	a4,s1,8
    800030c4:	02e7e663          	bltu	a5,a4,800030f0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030c8:	46a1                	li	a3,8
    800030ca:	8626                	mv	a2,s1
    800030cc:	85ca                	mv	a1,s2
    800030ce:	6928                	ld	a0,80(a0)
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	790080e7          	jalr	1936(ra) # 80001860 <copyin>
    800030d8:	00a03533          	snez	a0,a0
    800030dc:	40a00533          	neg	a0,a0
}
    800030e0:	60e2                	ld	ra,24(sp)
    800030e2:	6442                	ld	s0,16(sp)
    800030e4:	64a2                	ld	s1,8(sp)
    800030e6:	6902                	ld	s2,0(sp)
    800030e8:	6105                	add	sp,sp,32
    800030ea:	8082                	ret
    return -1;
    800030ec:	557d                	li	a0,-1
    800030ee:	bfcd                	j	800030e0 <fetchaddr+0x3e>
    800030f0:	557d                	li	a0,-1
    800030f2:	b7fd                	j	800030e0 <fetchaddr+0x3e>

00000000800030f4 <fetchstr>:
{
    800030f4:	7179                	add	sp,sp,-48
    800030f6:	f406                	sd	ra,40(sp)
    800030f8:	f022                	sd	s0,32(sp)
    800030fa:	ec26                	sd	s1,24(sp)
    800030fc:	e84a                	sd	s2,16(sp)
    800030fe:	e44e                	sd	s3,8(sp)
    80003100:	1800                	add	s0,sp,48
    80003102:	892a                	mv	s2,a0
    80003104:	84ae                	mv	s1,a1
    80003106:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	a0c080e7          	jalr	-1524(ra) # 80001b14 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003110:	86ce                	mv	a3,s3
    80003112:	864a                	mv	a2,s2
    80003114:	85a6                	mv	a1,s1
    80003116:	6928                	ld	a0,80(a0)
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	7d6080e7          	jalr	2006(ra) # 800018ee <copyinstr>
    80003120:	00054e63          	bltz	a0,8000313c <fetchstr+0x48>
  return strlen(buf);
    80003124:	8526                	mv	a0,s1
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	e2a080e7          	jalr	-470(ra) # 80000f50 <strlen>
}
    8000312e:	70a2                	ld	ra,40(sp)
    80003130:	7402                	ld	s0,32(sp)
    80003132:	64e2                	ld	s1,24(sp)
    80003134:	6942                	ld	s2,16(sp)
    80003136:	69a2                	ld	s3,8(sp)
    80003138:	6145                	add	sp,sp,48
    8000313a:	8082                	ret
    return -1;
    8000313c:	557d                	li	a0,-1
    8000313e:	bfc5                	j	8000312e <fetchstr+0x3a>

0000000080003140 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003140:	1101                	add	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	1000                	add	s0,sp,32
    8000314a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	eee080e7          	jalr	-274(ra) # 8000303a <argraw>
    80003154:	c088                	sw	a0,0(s1)
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	64a2                	ld	s1,8(sp)
    8000315c:	6105                	add	sp,sp,32
    8000315e:	8082                	ret

0000000080003160 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003160:	1101                	add	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	add	s0,sp,32
    8000316a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	ece080e7          	jalr	-306(ra) # 8000303a <argraw>
    80003174:	e088                	sd	a0,0(s1)
}
    80003176:	60e2                	ld	ra,24(sp)
    80003178:	6442                	ld	s0,16(sp)
    8000317a:	64a2                	ld	s1,8(sp)
    8000317c:	6105                	add	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003180:	7179                	add	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	e84a                	sd	s2,16(sp)
    8000318a:	1800                	add	s0,sp,48
    8000318c:	84ae                	mv	s1,a1
    8000318e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003190:	fd840593          	add	a1,s0,-40
    80003194:	00000097          	auipc	ra,0x0
    80003198:	fcc080e7          	jalr	-52(ra) # 80003160 <argaddr>
  return fetchstr(addr, buf, max);
    8000319c:	864a                	mv	a2,s2
    8000319e:	85a6                	mv	a1,s1
    800031a0:	fd843503          	ld	a0,-40(s0)
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	f50080e7          	jalr	-176(ra) # 800030f4 <fetchstr>
}
    800031ac:	70a2                	ld	ra,40(sp)
    800031ae:	7402                	ld	s0,32(sp)
    800031b0:	64e2                	ld	s1,24(sp)
    800031b2:	6942                	ld	s2,16(sp)
    800031b4:	6145                	add	sp,sp,48
    800031b6:	8082                	ret

00000000800031b8 <syscall>:
[SYS_set_priority] sys_set_priority,
};

void
syscall(void)
{
    800031b8:	1101                	add	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	e426                	sd	s1,8(sp)
    800031c0:	e04a                	sd	s2,0(sp)
    800031c2:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	950080e7          	jalr	-1712(ra) # 80001b14 <myproc>
    800031cc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031ce:	05853903          	ld	s2,88(a0)
    800031d2:	0a893783          	ld	a5,168(s2)
    800031d6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031da:	37fd                	addw	a5,a5,-1
    800031dc:	475d                	li	a4,23
    800031de:	00f76f63          	bltu	a4,a5,800031fc <syscall+0x44>
    800031e2:	00369713          	sll	a4,a3,0x3
    800031e6:	00005797          	auipc	a5,0x5
    800031ea:	27a78793          	add	a5,a5,634 # 80008460 <syscalls>
    800031ee:	97ba                	add	a5,a5,a4
    800031f0:	639c                	ld	a5,0(a5)
    800031f2:	c789                	beqz	a5,800031fc <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800031f4:	9782                	jalr	a5
    800031f6:	06a93823          	sd	a0,112(s2)
    800031fa:	a839                	j	80003218 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031fc:	15848613          	add	a2,s1,344
    80003200:	588c                	lw	a1,48(s1)
    80003202:	00005517          	auipc	a0,0x5
    80003206:	22650513          	add	a0,a0,550 # 80008428 <states.0+0x150>
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	37c080e7          	jalr	892(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003212:	6cbc                	ld	a5,88(s1)
    80003214:	577d                	li	a4,-1
    80003216:	fbb8                	sd	a4,112(a5)
  }
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6902                	ld	s2,0(sp)
    80003220:	6105                	add	sp,sp,32
    80003222:	8082                	ret

0000000080003224 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003224:	1101                	add	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    8000322c:	fec40593          	add	a1,s0,-20
    80003230:	4501                	li	a0,0
    80003232:	00000097          	auipc	ra,0x0
    80003236:	f0e080e7          	jalr	-242(ra) # 80003140 <argint>
  exit(n);
    8000323a:	fec42503          	lw	a0,-20(s0)
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	2c6080e7          	jalr	710(ra) # 80002504 <exit>
  return 0; // not reached
}
    80003246:	4501                	li	a0,0
    80003248:	60e2                	ld	ra,24(sp)
    8000324a:	6442                	ld	s0,16(sp)
    8000324c:	6105                	add	sp,sp,32
    8000324e:	8082                	ret

0000000080003250 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003250:	1141                	add	sp,sp,-16
    80003252:	e406                	sd	ra,8(sp)
    80003254:	e022                	sd	s0,0(sp)
    80003256:	0800                	add	s0,sp,16
  return myproc()->pid;
    80003258:	fffff097          	auipc	ra,0xfffff
    8000325c:	8bc080e7          	jalr	-1860(ra) # 80001b14 <myproc>
}
    80003260:	5908                	lw	a0,48(a0)
    80003262:	60a2                	ld	ra,8(sp)
    80003264:	6402                	ld	s0,0(sp)
    80003266:	0141                	add	sp,sp,16
    80003268:	8082                	ret

000000008000326a <sys_fork>:

uint64
sys_fork(void)
{
    8000326a:	1141                	add	sp,sp,-16
    8000326c:	e406                	sd	ra,8(sp)
    8000326e:	e022                	sd	s0,0(sp)
    80003270:	0800                	add	s0,sp,16
  return fork();
    80003272:	fffff097          	auipc	ra,0xfffff
    80003276:	c98080e7          	jalr	-872(ra) # 80001f0a <fork>
}
    8000327a:	60a2                	ld	ra,8(sp)
    8000327c:	6402                	ld	s0,0(sp)
    8000327e:	0141                	add	sp,sp,16
    80003280:	8082                	ret

0000000080003282 <sys_wait>:

uint64
sys_wait(void)
{
    80003282:	1101                	add	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000328a:	fe840593          	add	a1,s0,-24
    8000328e:	4501                	li	a0,0
    80003290:	00000097          	auipc	ra,0x0
    80003294:	ed0080e7          	jalr	-304(ra) # 80003160 <argaddr>
  return wait(p);
    80003298:	fe843503          	ld	a0,-24(s0)
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	41a080e7          	jalr	1050(ra) # 800026b6 <wait>
}
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	6105                	add	sp,sp,32
    800032aa:	8082                	ret

00000000800032ac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032ac:	7179                	add	sp,sp,-48
    800032ae:	f406                	sd	ra,40(sp)
    800032b0:	f022                	sd	s0,32(sp)
    800032b2:	ec26                	sd	s1,24(sp)
    800032b4:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800032b6:	fdc40593          	add	a1,s0,-36
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e84080e7          	jalr	-380(ra) # 80003140 <argint>
  addr = myproc()->sz;
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	850080e7          	jalr	-1968(ra) # 80001b14 <myproc>
    800032cc:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800032ce:	fdc42503          	lw	a0,-36(s0)
    800032d2:	fffff097          	auipc	ra,0xfffff
    800032d6:	bdc080e7          	jalr	-1060(ra) # 80001eae <growproc>
    800032da:	00054863          	bltz	a0,800032ea <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032de:	8526                	mv	a0,s1
    800032e0:	70a2                	ld	ra,40(sp)
    800032e2:	7402                	ld	s0,32(sp)
    800032e4:	64e2                	ld	s1,24(sp)
    800032e6:	6145                	add	sp,sp,48
    800032e8:	8082                	ret
    return -1;
    800032ea:	54fd                	li	s1,-1
    800032ec:	bfcd                	j	800032de <sys_sbrk+0x32>

00000000800032ee <sys_sleep>:

uint64
sys_sleep(void)
{
    800032ee:	7139                	add	sp,sp,-64
    800032f0:	fc06                	sd	ra,56(sp)
    800032f2:	f822                	sd	s0,48(sp)
    800032f4:	f426                	sd	s1,40(sp)
    800032f6:	f04a                	sd	s2,32(sp)
    800032f8:	ec4e                	sd	s3,24(sp)
    800032fa:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032fc:	fcc40593          	add	a1,s0,-52
    80003300:	4501                	li	a0,0
    80003302:	00000097          	auipc	ra,0x0
    80003306:	e3e080e7          	jalr	-450(ra) # 80003140 <argint>
  acquire(&tickslock);
    8000330a:	00234517          	auipc	a0,0x234
    8000330e:	29e50513          	add	a0,a0,670 # 802375a8 <tickslock>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	9c8080e7          	jalr	-1592(ra) # 80000cda <acquire>
  ticks0 = ticks;
    8000331a:	00005917          	auipc	s2,0x5
    8000331e:	5d692903          	lw	s2,1494(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    80003322:	fcc42783          	lw	a5,-52(s0)
    80003326:	cf9d                	beqz	a5,80003364 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003328:	00234997          	auipc	s3,0x234
    8000332c:	28098993          	add	s3,s3,640 # 802375a8 <tickslock>
    80003330:	00005497          	auipc	s1,0x5
    80003334:	5c048493          	add	s1,s1,1472 # 800088f0 <ticks>
    if (killed(myproc()))
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	7dc080e7          	jalr	2012(ra) # 80001b14 <myproc>
    80003340:	fffff097          	auipc	ra,0xfffff
    80003344:	344080e7          	jalr	836(ra) # 80002684 <killed>
    80003348:	ed15                	bnez	a0,80003384 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000334a:	85ce                	mv	a1,s3
    8000334c:	8526                	mv	a0,s1
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	082080e7          	jalr	130(ra) # 800023d0 <sleep>
  while (ticks - ticks0 < n)
    80003356:	409c                	lw	a5,0(s1)
    80003358:	412787bb          	subw	a5,a5,s2
    8000335c:	fcc42703          	lw	a4,-52(s0)
    80003360:	fce7ece3          	bltu	a5,a4,80003338 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003364:	00234517          	auipc	a0,0x234
    80003368:	24450513          	add	a0,a0,580 # 802375a8 <tickslock>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	a22080e7          	jalr	-1502(ra) # 80000d8e <release>
  return 0;
    80003374:	4501                	li	a0,0
}
    80003376:	70e2                	ld	ra,56(sp)
    80003378:	7442                	ld	s0,48(sp)
    8000337a:	74a2                	ld	s1,40(sp)
    8000337c:	7902                	ld	s2,32(sp)
    8000337e:	69e2                	ld	s3,24(sp)
    80003380:	6121                	add	sp,sp,64
    80003382:	8082                	ret
      release(&tickslock);
    80003384:	00234517          	auipc	a0,0x234
    80003388:	22450513          	add	a0,a0,548 # 802375a8 <tickslock>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	a02080e7          	jalr	-1534(ra) # 80000d8e <release>
      return -1;
    80003394:	557d                	li	a0,-1
    80003396:	b7c5                	j	80003376 <sys_sleep+0x88>

0000000080003398 <sys_kill>:

uint64
sys_kill(void)
{
    80003398:	1101                	add	sp,sp,-32
    8000339a:	ec06                	sd	ra,24(sp)
    8000339c:	e822                	sd	s0,16(sp)
    8000339e:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    800033a0:	fec40593          	add	a1,s0,-20
    800033a4:	4501                	li	a0,0
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	d9a080e7          	jalr	-614(ra) # 80003140 <argint>
  return kill(pid);
    800033ae:	fec42503          	lw	a0,-20(s0)
    800033b2:	fffff097          	auipc	ra,0xfffff
    800033b6:	234080e7          	jalr	564(ra) # 800025e6 <kill>
}
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	6105                	add	sp,sp,32
    800033c0:	8082                	ret

00000000800033c2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033c2:	1101                	add	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	e426                	sd	s1,8(sp)
    800033ca:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033cc:	00234517          	auipc	a0,0x234
    800033d0:	1dc50513          	add	a0,a0,476 # 802375a8 <tickslock>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	906080e7          	jalr	-1786(ra) # 80000cda <acquire>
  xticks = ticks;
    800033dc:	00005497          	auipc	s1,0x5
    800033e0:	5144a483          	lw	s1,1300(s1) # 800088f0 <ticks>
  release(&tickslock);
    800033e4:	00234517          	auipc	a0,0x234
    800033e8:	1c450513          	add	a0,a0,452 # 802375a8 <tickslock>
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	9a2080e7          	jalr	-1630(ra) # 80000d8e <release>
  return xticks;
}
    800033f4:	02049513          	sll	a0,s1,0x20
    800033f8:	9101                	srl	a0,a0,0x20
    800033fa:	60e2                	ld	ra,24(sp)
    800033fc:	6442                	ld	s0,16(sp)
    800033fe:	64a2                	ld	s1,8(sp)
    80003400:	6105                	add	sp,sp,32
    80003402:	8082                	ret

0000000080003404 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003404:	7139                	add	sp,sp,-64
    80003406:	fc06                	sd	ra,56(sp)
    80003408:	f822                	sd	s0,48(sp)
    8000340a:	f426                	sd	s1,40(sp)
    8000340c:	f04a                	sd	s2,32(sp)
    8000340e:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003410:	fd840593          	add	a1,s0,-40
    80003414:	4501                	li	a0,0
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	d4a080e7          	jalr	-694(ra) # 80003160 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000341e:	fd040593          	add	a1,s0,-48
    80003422:	4505                	li	a0,1
    80003424:	00000097          	auipc	ra,0x0
    80003428:	d3c080e7          	jalr	-708(ra) # 80003160 <argaddr>
  argaddr(2, &addr2);
    8000342c:	fc840593          	add	a1,s0,-56
    80003430:	4509                	li	a0,2
    80003432:	00000097          	auipc	ra,0x0
    80003436:	d2e080e7          	jalr	-722(ra) # 80003160 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000343a:	fc040613          	add	a2,s0,-64
    8000343e:	fc440593          	add	a1,s0,-60
    80003442:	fd843503          	ld	a0,-40(s0)
    80003446:	fffff097          	auipc	ra,0xfffff
    8000344a:	4fa080e7          	jalr	1274(ra) # 80002940 <waitx>
    8000344e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003450:	ffffe097          	auipc	ra,0xffffe
    80003454:	6c4080e7          	jalr	1732(ra) # 80001b14 <myproc>
    80003458:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000345a:	4691                	li	a3,4
    8000345c:	fc440613          	add	a2,s0,-60
    80003460:	fd043583          	ld	a1,-48(s0)
    80003464:	6928                	ld	a0,80(a0)
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	336080e7          	jalr	822(ra) # 8000179c <copyout>
    return -1;
    8000346e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003470:	00054f63          	bltz	a0,8000348e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003474:	4691                	li	a3,4
    80003476:	fc040613          	add	a2,s0,-64
    8000347a:	fc843583          	ld	a1,-56(s0)
    8000347e:	68a8                	ld	a0,80(s1)
    80003480:	ffffe097          	auipc	ra,0xffffe
    80003484:	31c080e7          	jalr	796(ra) # 8000179c <copyout>
    80003488:	00054a63          	bltz	a0,8000349c <sys_waitx+0x98>
    return -1;
  return ret;
    8000348c:	87ca                	mv	a5,s2
}
    8000348e:	853e                	mv	a0,a5
    80003490:	70e2                	ld	ra,56(sp)
    80003492:	7442                	ld	s0,48(sp)
    80003494:	74a2                	ld	s1,40(sp)
    80003496:	7902                	ld	s2,32(sp)
    80003498:	6121                	add	sp,sp,64
    8000349a:	8082                	ret
    return -1;
    8000349c:	57fd                	li	a5,-1
    8000349e:	bfc5                	j	8000348e <sys_waitx+0x8a>

00000000800034a0 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800034a0:	1101                	add	sp,sp,-32
    800034a2:	ec06                	sd	ra,24(sp)
    800034a4:	e822                	sd	s0,16(sp)
    800034a6:	1000                	add	s0,sp,32
  int pid, priority;
  argint(0, &pid);
    800034a8:	fec40593          	add	a1,s0,-20
    800034ac:	4501                	li	a0,0
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	c92080e7          	jalr	-878(ra) # 80003140 <argint>
  argint(1, &priority);
    800034b6:	fe840593          	add	a1,s0,-24
    800034ba:	4505                	li	a0,1
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	c84080e7          	jalr	-892(ra) # 80003140 <argint>
  return set_priority(pid, priority);
    800034c4:	fe842583          	lw	a1,-24(s0)
    800034c8:	fec42503          	lw	a0,-20(s0)
    800034cc:	fffff097          	auipc	ra,0xfffff
    800034d0:	e5c080e7          	jalr	-420(ra) # 80002328 <set_priority>
    800034d4:	60e2                	ld	ra,24(sp)
    800034d6:	6442                	ld	s0,16(sp)
    800034d8:	6105                	add	sp,sp,32
    800034da:	8082                	ret

00000000800034dc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034dc:	7179                	add	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	e052                	sd	s4,0(sp)
    800034ea:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034ec:	00005597          	auipc	a1,0x5
    800034f0:	03c58593          	add	a1,a1,60 # 80008528 <syscalls+0xc8>
    800034f4:	00234517          	auipc	a0,0x234
    800034f8:	0cc50513          	add	a0,a0,204 # 802375c0 <bcache>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	74e080e7          	jalr	1870(ra) # 80000c4a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003504:	0023c797          	auipc	a5,0x23c
    80003508:	0bc78793          	add	a5,a5,188 # 8023f5c0 <bcache+0x8000>
    8000350c:	0023c717          	auipc	a4,0x23c
    80003510:	31c70713          	add	a4,a4,796 # 8023f828 <bcache+0x8268>
    80003514:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003518:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000351c:	00234497          	auipc	s1,0x234
    80003520:	0bc48493          	add	s1,s1,188 # 802375d8 <bcache+0x18>
    b->next = bcache.head.next;
    80003524:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003526:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003528:	00005a17          	auipc	s4,0x5
    8000352c:	008a0a13          	add	s4,s4,8 # 80008530 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003530:	2b893783          	ld	a5,696(s2)
    80003534:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003536:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000353a:	85d2                	mv	a1,s4
    8000353c:	01048513          	add	a0,s1,16
    80003540:	00001097          	auipc	ra,0x1
    80003544:	496080e7          	jalr	1174(ra) # 800049d6 <initsleeplock>
    bcache.head.next->prev = b;
    80003548:	2b893783          	ld	a5,696(s2)
    8000354c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000354e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003552:	45848493          	add	s1,s1,1112
    80003556:	fd349de3          	bne	s1,s3,80003530 <binit+0x54>
  }
}
    8000355a:	70a2                	ld	ra,40(sp)
    8000355c:	7402                	ld	s0,32(sp)
    8000355e:	64e2                	ld	s1,24(sp)
    80003560:	6942                	ld	s2,16(sp)
    80003562:	69a2                	ld	s3,8(sp)
    80003564:	6a02                	ld	s4,0(sp)
    80003566:	6145                	add	sp,sp,48
    80003568:	8082                	ret

000000008000356a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000356a:	7179                	add	sp,sp,-48
    8000356c:	f406                	sd	ra,40(sp)
    8000356e:	f022                	sd	s0,32(sp)
    80003570:	ec26                	sd	s1,24(sp)
    80003572:	e84a                	sd	s2,16(sp)
    80003574:	e44e                	sd	s3,8(sp)
    80003576:	1800                	add	s0,sp,48
    80003578:	892a                	mv	s2,a0
    8000357a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000357c:	00234517          	auipc	a0,0x234
    80003580:	04450513          	add	a0,a0,68 # 802375c0 <bcache>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	756080e7          	jalr	1878(ra) # 80000cda <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000358c:	0023c497          	auipc	s1,0x23c
    80003590:	2ec4b483          	ld	s1,748(s1) # 8023f878 <bcache+0x82b8>
    80003594:	0023c797          	auipc	a5,0x23c
    80003598:	29478793          	add	a5,a5,660 # 8023f828 <bcache+0x8268>
    8000359c:	02f48f63          	beq	s1,a5,800035da <bread+0x70>
    800035a0:	873e                	mv	a4,a5
    800035a2:	a021                	j	800035aa <bread+0x40>
    800035a4:	68a4                	ld	s1,80(s1)
    800035a6:	02e48a63          	beq	s1,a4,800035da <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035aa:	449c                	lw	a5,8(s1)
    800035ac:	ff279ce3          	bne	a5,s2,800035a4 <bread+0x3a>
    800035b0:	44dc                	lw	a5,12(s1)
    800035b2:	ff3799e3          	bne	a5,s3,800035a4 <bread+0x3a>
      b->refcnt++;
    800035b6:	40bc                	lw	a5,64(s1)
    800035b8:	2785                	addw	a5,a5,1
    800035ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035bc:	00234517          	auipc	a0,0x234
    800035c0:	00450513          	add	a0,a0,4 # 802375c0 <bcache>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	7ca080e7          	jalr	1994(ra) # 80000d8e <release>
      acquiresleep(&b->lock);
    800035cc:	01048513          	add	a0,s1,16
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	440080e7          	jalr	1088(ra) # 80004a10 <acquiresleep>
      return b;
    800035d8:	a8b9                	j	80003636 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035da:	0023c497          	auipc	s1,0x23c
    800035de:	2964b483          	ld	s1,662(s1) # 8023f870 <bcache+0x82b0>
    800035e2:	0023c797          	auipc	a5,0x23c
    800035e6:	24678793          	add	a5,a5,582 # 8023f828 <bcache+0x8268>
    800035ea:	00f48863          	beq	s1,a5,800035fa <bread+0x90>
    800035ee:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035f0:	40bc                	lw	a5,64(s1)
    800035f2:	cf81                	beqz	a5,8000360a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035f4:	64a4                	ld	s1,72(s1)
    800035f6:	fee49de3          	bne	s1,a4,800035f0 <bread+0x86>
  panic("bget: no buffers");
    800035fa:	00005517          	auipc	a0,0x5
    800035fe:	f3e50513          	add	a0,a0,-194 # 80008538 <syscalls+0xd8>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	f3a080e7          	jalr	-198(ra) # 8000053c <panic>
      b->dev = dev;
    8000360a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000360e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003612:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003616:	4785                	li	a5,1
    80003618:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000361a:	00234517          	auipc	a0,0x234
    8000361e:	fa650513          	add	a0,a0,-90 # 802375c0 <bcache>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	76c080e7          	jalr	1900(ra) # 80000d8e <release>
      acquiresleep(&b->lock);
    8000362a:	01048513          	add	a0,s1,16
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	3e2080e7          	jalr	994(ra) # 80004a10 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003636:	409c                	lw	a5,0(s1)
    80003638:	cb89                	beqz	a5,8000364a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000363a:	8526                	mv	a0,s1
    8000363c:	70a2                	ld	ra,40(sp)
    8000363e:	7402                	ld	s0,32(sp)
    80003640:	64e2                	ld	s1,24(sp)
    80003642:	6942                	ld	s2,16(sp)
    80003644:	69a2                	ld	s3,8(sp)
    80003646:	6145                	add	sp,sp,48
    80003648:	8082                	ret
    virtio_disk_rw(b, 0);
    8000364a:	4581                	li	a1,0
    8000364c:	8526                	mv	a0,s1
    8000364e:	00003097          	auipc	ra,0x3
    80003652:	fa4080e7          	jalr	-92(ra) # 800065f2 <virtio_disk_rw>
    b->valid = 1;
    80003656:	4785                	li	a5,1
    80003658:	c09c                	sw	a5,0(s1)
  return b;
    8000365a:	b7c5                	j	8000363a <bread+0xd0>

000000008000365c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000365c:	1101                	add	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	1000                	add	s0,sp,32
    80003666:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003668:	0541                	add	a0,a0,16
    8000366a:	00001097          	auipc	ra,0x1
    8000366e:	440080e7          	jalr	1088(ra) # 80004aaa <holdingsleep>
    80003672:	cd01                	beqz	a0,8000368a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003674:	4585                	li	a1,1
    80003676:	8526                	mv	a0,s1
    80003678:	00003097          	auipc	ra,0x3
    8000367c:	f7a080e7          	jalr	-134(ra) # 800065f2 <virtio_disk_rw>
}
    80003680:	60e2                	ld	ra,24(sp)
    80003682:	6442                	ld	s0,16(sp)
    80003684:	64a2                	ld	s1,8(sp)
    80003686:	6105                	add	sp,sp,32
    80003688:	8082                	ret
    panic("bwrite");
    8000368a:	00005517          	auipc	a0,0x5
    8000368e:	ec650513          	add	a0,a0,-314 # 80008550 <syscalls+0xf0>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	eaa080e7          	jalr	-342(ra) # 8000053c <panic>

000000008000369a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000369a:	1101                	add	sp,sp,-32
    8000369c:	ec06                	sd	ra,24(sp)
    8000369e:	e822                	sd	s0,16(sp)
    800036a0:	e426                	sd	s1,8(sp)
    800036a2:	e04a                	sd	s2,0(sp)
    800036a4:	1000                	add	s0,sp,32
    800036a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036a8:	01050913          	add	s2,a0,16
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	3fc080e7          	jalr	1020(ra) # 80004aaa <holdingsleep>
    800036b6:	c925                	beqz	a0,80003726 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800036b8:	854a                	mv	a0,s2
    800036ba:	00001097          	auipc	ra,0x1
    800036be:	3ac080e7          	jalr	940(ra) # 80004a66 <releasesleep>

  acquire(&bcache.lock);
    800036c2:	00234517          	auipc	a0,0x234
    800036c6:	efe50513          	add	a0,a0,-258 # 802375c0 <bcache>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	610080e7          	jalr	1552(ra) # 80000cda <acquire>
  b->refcnt--;
    800036d2:	40bc                	lw	a5,64(s1)
    800036d4:	37fd                	addw	a5,a5,-1
    800036d6:	0007871b          	sext.w	a4,a5
    800036da:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036dc:	e71d                	bnez	a4,8000370a <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036de:	68b8                	ld	a4,80(s1)
    800036e0:	64bc                	ld	a5,72(s1)
    800036e2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800036e4:	68b8                	ld	a4,80(s1)
    800036e6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036e8:	0023c797          	auipc	a5,0x23c
    800036ec:	ed878793          	add	a5,a5,-296 # 8023f5c0 <bcache+0x8000>
    800036f0:	2b87b703          	ld	a4,696(a5)
    800036f4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036f6:	0023c717          	auipc	a4,0x23c
    800036fa:	13270713          	add	a4,a4,306 # 8023f828 <bcache+0x8268>
    800036fe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003700:	2b87b703          	ld	a4,696(a5)
    80003704:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003706:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000370a:	00234517          	auipc	a0,0x234
    8000370e:	eb650513          	add	a0,a0,-330 # 802375c0 <bcache>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	67c080e7          	jalr	1660(ra) # 80000d8e <release>
}
    8000371a:	60e2                	ld	ra,24(sp)
    8000371c:	6442                	ld	s0,16(sp)
    8000371e:	64a2                	ld	s1,8(sp)
    80003720:	6902                	ld	s2,0(sp)
    80003722:	6105                	add	sp,sp,32
    80003724:	8082                	ret
    panic("brelse");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	e3250513          	add	a0,a0,-462 # 80008558 <syscalls+0xf8>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e0e080e7          	jalr	-498(ra) # 8000053c <panic>

0000000080003736 <bpin>:

void
bpin(struct buf *b) {
    80003736:	1101                	add	sp,sp,-32
    80003738:	ec06                	sd	ra,24(sp)
    8000373a:	e822                	sd	s0,16(sp)
    8000373c:	e426                	sd	s1,8(sp)
    8000373e:	1000                	add	s0,sp,32
    80003740:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003742:	00234517          	auipc	a0,0x234
    80003746:	e7e50513          	add	a0,a0,-386 # 802375c0 <bcache>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	590080e7          	jalr	1424(ra) # 80000cda <acquire>
  b->refcnt++;
    80003752:	40bc                	lw	a5,64(s1)
    80003754:	2785                	addw	a5,a5,1
    80003756:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003758:	00234517          	auipc	a0,0x234
    8000375c:	e6850513          	add	a0,a0,-408 # 802375c0 <bcache>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	62e080e7          	jalr	1582(ra) # 80000d8e <release>
}
    80003768:	60e2                	ld	ra,24(sp)
    8000376a:	6442                	ld	s0,16(sp)
    8000376c:	64a2                	ld	s1,8(sp)
    8000376e:	6105                	add	sp,sp,32
    80003770:	8082                	ret

0000000080003772 <bunpin>:

void
bunpin(struct buf *b) {
    80003772:	1101                	add	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	e426                	sd	s1,8(sp)
    8000377a:	1000                	add	s0,sp,32
    8000377c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000377e:	00234517          	auipc	a0,0x234
    80003782:	e4250513          	add	a0,a0,-446 # 802375c0 <bcache>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	554080e7          	jalr	1364(ra) # 80000cda <acquire>
  b->refcnt--;
    8000378e:	40bc                	lw	a5,64(s1)
    80003790:	37fd                	addw	a5,a5,-1
    80003792:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003794:	00234517          	auipc	a0,0x234
    80003798:	e2c50513          	add	a0,a0,-468 # 802375c0 <bcache>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	5f2080e7          	jalr	1522(ra) # 80000d8e <release>
}
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	64a2                	ld	s1,8(sp)
    800037aa:	6105                	add	sp,sp,32
    800037ac:	8082                	ret

00000000800037ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037ae:	1101                	add	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	add	s0,sp,32
    800037ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037bc:	00d5d59b          	srlw	a1,a1,0xd
    800037c0:	0023c797          	auipc	a5,0x23c
    800037c4:	4dc7a783          	lw	a5,1244(a5) # 8023fc9c <sb+0x1c>
    800037c8:	9dbd                	addw	a1,a1,a5
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	da0080e7          	jalr	-608(ra) # 8000356a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037d2:	0074f713          	and	a4,s1,7
    800037d6:	4785                	li	a5,1
    800037d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037dc:	14ce                	sll	s1,s1,0x33
    800037de:	90d9                	srl	s1,s1,0x36
    800037e0:	00950733          	add	a4,a0,s1
    800037e4:	05874703          	lbu	a4,88(a4)
    800037e8:	00e7f6b3          	and	a3,a5,a4
    800037ec:	c69d                	beqz	a3,8000381a <bfree+0x6c>
    800037ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037f0:	94aa                	add	s1,s1,a0
    800037f2:	fff7c793          	not	a5,a5
    800037f6:	8f7d                	and	a4,a4,a5
    800037f8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	0f6080e7          	jalr	246(ra) # 800048f2 <log_write>
  brelse(bp);
    80003804:	854a                	mv	a0,s2
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	e94080e7          	jalr	-364(ra) # 8000369a <brelse>
}
    8000380e:	60e2                	ld	ra,24(sp)
    80003810:	6442                	ld	s0,16(sp)
    80003812:	64a2                	ld	s1,8(sp)
    80003814:	6902                	ld	s2,0(sp)
    80003816:	6105                	add	sp,sp,32
    80003818:	8082                	ret
    panic("freeing free block");
    8000381a:	00005517          	auipc	a0,0x5
    8000381e:	d4650513          	add	a0,a0,-698 # 80008560 <syscalls+0x100>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	d1a080e7          	jalr	-742(ra) # 8000053c <panic>

000000008000382a <balloc>:
{
    8000382a:	711d                	add	sp,sp,-96
    8000382c:	ec86                	sd	ra,88(sp)
    8000382e:	e8a2                	sd	s0,80(sp)
    80003830:	e4a6                	sd	s1,72(sp)
    80003832:	e0ca                	sd	s2,64(sp)
    80003834:	fc4e                	sd	s3,56(sp)
    80003836:	f852                	sd	s4,48(sp)
    80003838:	f456                	sd	s5,40(sp)
    8000383a:	f05a                	sd	s6,32(sp)
    8000383c:	ec5e                	sd	s7,24(sp)
    8000383e:	e862                	sd	s8,16(sp)
    80003840:	e466                	sd	s9,8(sp)
    80003842:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003844:	0023c797          	auipc	a5,0x23c
    80003848:	4407a783          	lw	a5,1088(a5) # 8023fc84 <sb+0x4>
    8000384c:	cff5                	beqz	a5,80003948 <balloc+0x11e>
    8000384e:	8baa                	mv	s7,a0
    80003850:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003852:	0023cb17          	auipc	s6,0x23c
    80003856:	42eb0b13          	add	s6,s6,1070 # 8023fc80 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000385a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000385c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000385e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003860:	6c89                	lui	s9,0x2
    80003862:	a061                	j	800038ea <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003864:	97ca                	add	a5,a5,s2
    80003866:	8e55                	or	a2,a2,a3
    80003868:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	084080e7          	jalr	132(ra) # 800048f2 <log_write>
        brelse(bp);
    80003876:	854a                	mv	a0,s2
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	e22080e7          	jalr	-478(ra) # 8000369a <brelse>
  bp = bread(dev, bno);
    80003880:	85a6                	mv	a1,s1
    80003882:	855e                	mv	a0,s7
    80003884:	00000097          	auipc	ra,0x0
    80003888:	ce6080e7          	jalr	-794(ra) # 8000356a <bread>
    8000388c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000388e:	40000613          	li	a2,1024
    80003892:	4581                	li	a1,0
    80003894:	05850513          	add	a0,a0,88
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	53e080e7          	jalr	1342(ra) # 80000dd6 <memset>
  log_write(bp);
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	050080e7          	jalr	80(ra) # 800048f2 <log_write>
  brelse(bp);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	dee080e7          	jalr	-530(ra) # 8000369a <brelse>
}
    800038b4:	8526                	mv	a0,s1
    800038b6:	60e6                	ld	ra,88(sp)
    800038b8:	6446                	ld	s0,80(sp)
    800038ba:	64a6                	ld	s1,72(sp)
    800038bc:	6906                	ld	s2,64(sp)
    800038be:	79e2                	ld	s3,56(sp)
    800038c0:	7a42                	ld	s4,48(sp)
    800038c2:	7aa2                	ld	s5,40(sp)
    800038c4:	7b02                	ld	s6,32(sp)
    800038c6:	6be2                	ld	s7,24(sp)
    800038c8:	6c42                	ld	s8,16(sp)
    800038ca:	6ca2                	ld	s9,8(sp)
    800038cc:	6125                	add	sp,sp,96
    800038ce:	8082                	ret
    brelse(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	dc8080e7          	jalr	-568(ra) # 8000369a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038da:	015c87bb          	addw	a5,s9,s5
    800038de:	00078a9b          	sext.w	s5,a5
    800038e2:	004b2703          	lw	a4,4(s6)
    800038e6:	06eaf163          	bgeu	s5,a4,80003948 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800038ea:	41fad79b          	sraw	a5,s5,0x1f
    800038ee:	0137d79b          	srlw	a5,a5,0x13
    800038f2:	015787bb          	addw	a5,a5,s5
    800038f6:	40d7d79b          	sraw	a5,a5,0xd
    800038fa:	01cb2583          	lw	a1,28(s6)
    800038fe:	9dbd                	addw	a1,a1,a5
    80003900:	855e                	mv	a0,s7
    80003902:	00000097          	auipc	ra,0x0
    80003906:	c68080e7          	jalr	-920(ra) # 8000356a <bread>
    8000390a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000390c:	004b2503          	lw	a0,4(s6)
    80003910:	000a849b          	sext.w	s1,s5
    80003914:	8762                	mv	a4,s8
    80003916:	faa4fde3          	bgeu	s1,a0,800038d0 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000391a:	00777693          	and	a3,a4,7
    8000391e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003922:	41f7579b          	sraw	a5,a4,0x1f
    80003926:	01d7d79b          	srlw	a5,a5,0x1d
    8000392a:	9fb9                	addw	a5,a5,a4
    8000392c:	4037d79b          	sraw	a5,a5,0x3
    80003930:	00f90633          	add	a2,s2,a5
    80003934:	05864603          	lbu	a2,88(a2)
    80003938:	00c6f5b3          	and	a1,a3,a2
    8000393c:	d585                	beqz	a1,80003864 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000393e:	2705                	addw	a4,a4,1
    80003940:	2485                	addw	s1,s1,1
    80003942:	fd471ae3          	bne	a4,s4,80003916 <balloc+0xec>
    80003946:	b769                	j	800038d0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003948:	00005517          	auipc	a0,0x5
    8000394c:	c3050513          	add	a0,a0,-976 # 80008578 <syscalls+0x118>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	c36080e7          	jalr	-970(ra) # 80000586 <printf>
  return 0;
    80003958:	4481                	li	s1,0
    8000395a:	bfa9                	j	800038b4 <balloc+0x8a>

000000008000395c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000395c:	7179                	add	sp,sp,-48
    8000395e:	f406                	sd	ra,40(sp)
    80003960:	f022                	sd	s0,32(sp)
    80003962:	ec26                	sd	s1,24(sp)
    80003964:	e84a                	sd	s2,16(sp)
    80003966:	e44e                	sd	s3,8(sp)
    80003968:	e052                	sd	s4,0(sp)
    8000396a:	1800                	add	s0,sp,48
    8000396c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000396e:	47ad                	li	a5,11
    80003970:	02b7e863          	bltu	a5,a1,800039a0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003974:	02059793          	sll	a5,a1,0x20
    80003978:	01e7d593          	srl	a1,a5,0x1e
    8000397c:	00b504b3          	add	s1,a0,a1
    80003980:	0504a903          	lw	s2,80(s1)
    80003984:	06091e63          	bnez	s2,80003a00 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003988:	4108                	lw	a0,0(a0)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	ea0080e7          	jalr	-352(ra) # 8000382a <balloc>
    80003992:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003996:	06090563          	beqz	s2,80003a00 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000399a:	0524a823          	sw	s2,80(s1)
    8000399e:	a08d                	j	80003a00 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039a0:	ff45849b          	addw	s1,a1,-12
    800039a4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039a8:	0ff00793          	li	a5,255
    800039ac:	08e7e563          	bltu	a5,a4,80003a36 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039b0:	08052903          	lw	s2,128(a0)
    800039b4:	00091d63          	bnez	s2,800039ce <bmap+0x72>
      addr = balloc(ip->dev);
    800039b8:	4108                	lw	a0,0(a0)
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	e70080e7          	jalr	-400(ra) # 8000382a <balloc>
    800039c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039c6:	02090d63          	beqz	s2,80003a00 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039ca:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800039ce:	85ca                	mv	a1,s2
    800039d0:	0009a503          	lw	a0,0(s3)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	b96080e7          	jalr	-1130(ra) # 8000356a <bread>
    800039dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039de:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800039e2:	02049713          	sll	a4,s1,0x20
    800039e6:	01e75593          	srl	a1,a4,0x1e
    800039ea:	00b784b3          	add	s1,a5,a1
    800039ee:	0004a903          	lw	s2,0(s1)
    800039f2:	02090063          	beqz	s2,80003a12 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039f6:	8552                	mv	a0,s4
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	ca2080e7          	jalr	-862(ra) # 8000369a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a00:	854a                	mv	a0,s2
    80003a02:	70a2                	ld	ra,40(sp)
    80003a04:	7402                	ld	s0,32(sp)
    80003a06:	64e2                	ld	s1,24(sp)
    80003a08:	6942                	ld	s2,16(sp)
    80003a0a:	69a2                	ld	s3,8(sp)
    80003a0c:	6a02                	ld	s4,0(sp)
    80003a0e:	6145                	add	sp,sp,48
    80003a10:	8082                	ret
      addr = balloc(ip->dev);
    80003a12:	0009a503          	lw	a0,0(s3)
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	e14080e7          	jalr	-492(ra) # 8000382a <balloc>
    80003a1e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a22:	fc090ae3          	beqz	s2,800039f6 <bmap+0x9a>
        a[bn] = addr;
    80003a26:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a2a:	8552                	mv	a0,s4
    80003a2c:	00001097          	auipc	ra,0x1
    80003a30:	ec6080e7          	jalr	-314(ra) # 800048f2 <log_write>
    80003a34:	b7c9                	j	800039f6 <bmap+0x9a>
  panic("bmap: out of range");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	b5a50513          	add	a0,a0,-1190 # 80008590 <syscalls+0x130>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	afe080e7          	jalr	-1282(ra) # 8000053c <panic>

0000000080003a46 <iget>:
{
    80003a46:	7179                	add	sp,sp,-48
    80003a48:	f406                	sd	ra,40(sp)
    80003a4a:	f022                	sd	s0,32(sp)
    80003a4c:	ec26                	sd	s1,24(sp)
    80003a4e:	e84a                	sd	s2,16(sp)
    80003a50:	e44e                	sd	s3,8(sp)
    80003a52:	e052                	sd	s4,0(sp)
    80003a54:	1800                	add	s0,sp,48
    80003a56:	89aa                	mv	s3,a0
    80003a58:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a5a:	0023c517          	auipc	a0,0x23c
    80003a5e:	24650513          	add	a0,a0,582 # 8023fca0 <itable>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	278080e7          	jalr	632(ra) # 80000cda <acquire>
  empty = 0;
    80003a6a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a6c:	0023c497          	auipc	s1,0x23c
    80003a70:	24c48493          	add	s1,s1,588 # 8023fcb8 <itable+0x18>
    80003a74:	0023e697          	auipc	a3,0x23e
    80003a78:	cd468693          	add	a3,a3,-812 # 80241748 <log>
    80003a7c:	a039                	j	80003a8a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a7e:	02090b63          	beqz	s2,80003ab4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a82:	08848493          	add	s1,s1,136
    80003a86:	02d48a63          	beq	s1,a3,80003aba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a8a:	449c                	lw	a5,8(s1)
    80003a8c:	fef059e3          	blez	a5,80003a7e <iget+0x38>
    80003a90:	4098                	lw	a4,0(s1)
    80003a92:	ff3716e3          	bne	a4,s3,80003a7e <iget+0x38>
    80003a96:	40d8                	lw	a4,4(s1)
    80003a98:	ff4713e3          	bne	a4,s4,80003a7e <iget+0x38>
      ip->ref++;
    80003a9c:	2785                	addw	a5,a5,1
    80003a9e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003aa0:	0023c517          	auipc	a0,0x23c
    80003aa4:	20050513          	add	a0,a0,512 # 8023fca0 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	2e6080e7          	jalr	742(ra) # 80000d8e <release>
      return ip;
    80003ab0:	8926                	mv	s2,s1
    80003ab2:	a03d                	j	80003ae0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ab4:	f7f9                	bnez	a5,80003a82 <iget+0x3c>
    80003ab6:	8926                	mv	s2,s1
    80003ab8:	b7e9                	j	80003a82 <iget+0x3c>
  if(empty == 0)
    80003aba:	02090c63          	beqz	s2,80003af2 <iget+0xac>
  ip->dev = dev;
    80003abe:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ac2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ac6:	4785                	li	a5,1
    80003ac8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003acc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ad0:	0023c517          	auipc	a0,0x23c
    80003ad4:	1d050513          	add	a0,a0,464 # 8023fca0 <itable>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	2b6080e7          	jalr	694(ra) # 80000d8e <release>
}
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	70a2                	ld	ra,40(sp)
    80003ae4:	7402                	ld	s0,32(sp)
    80003ae6:	64e2                	ld	s1,24(sp)
    80003ae8:	6942                	ld	s2,16(sp)
    80003aea:	69a2                	ld	s3,8(sp)
    80003aec:	6a02                	ld	s4,0(sp)
    80003aee:	6145                	add	sp,sp,48
    80003af0:	8082                	ret
    panic("iget: no inodes");
    80003af2:	00005517          	auipc	a0,0x5
    80003af6:	ab650513          	add	a0,a0,-1354 # 800085a8 <syscalls+0x148>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a42080e7          	jalr	-1470(ra) # 8000053c <panic>

0000000080003b02 <fsinit>:
fsinit(int dev) {
    80003b02:	7179                	add	sp,sp,-48
    80003b04:	f406                	sd	ra,40(sp)
    80003b06:	f022                	sd	s0,32(sp)
    80003b08:	ec26                	sd	s1,24(sp)
    80003b0a:	e84a                	sd	s2,16(sp)
    80003b0c:	e44e                	sd	s3,8(sp)
    80003b0e:	1800                	add	s0,sp,48
    80003b10:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b12:	4585                	li	a1,1
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	a56080e7          	jalr	-1450(ra) # 8000356a <bread>
    80003b1c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b1e:	0023c997          	auipc	s3,0x23c
    80003b22:	16298993          	add	s3,s3,354 # 8023fc80 <sb>
    80003b26:	02000613          	li	a2,32
    80003b2a:	05850593          	add	a1,a0,88
    80003b2e:	854e                	mv	a0,s3
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	302080e7          	jalr	770(ra) # 80000e32 <memmove>
  brelse(bp);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	b60080e7          	jalr	-1184(ra) # 8000369a <brelse>
  if(sb.magic != FSMAGIC)
    80003b42:	0009a703          	lw	a4,0(s3)
    80003b46:	102037b7          	lui	a5,0x10203
    80003b4a:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b4e:	02f71263          	bne	a4,a5,80003b72 <fsinit+0x70>
  initlog(dev, &sb);
    80003b52:	0023c597          	auipc	a1,0x23c
    80003b56:	12e58593          	add	a1,a1,302 # 8023fc80 <sb>
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	00001097          	auipc	ra,0x1
    80003b60:	b2c080e7          	jalr	-1236(ra) # 80004688 <initlog>
}
    80003b64:	70a2                	ld	ra,40(sp)
    80003b66:	7402                	ld	s0,32(sp)
    80003b68:	64e2                	ld	s1,24(sp)
    80003b6a:	6942                	ld	s2,16(sp)
    80003b6c:	69a2                	ld	s3,8(sp)
    80003b6e:	6145                	add	sp,sp,48
    80003b70:	8082                	ret
    panic("invalid file system");
    80003b72:	00005517          	auipc	a0,0x5
    80003b76:	a4650513          	add	a0,a0,-1466 # 800085b8 <syscalls+0x158>
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	9c2080e7          	jalr	-1598(ra) # 8000053c <panic>

0000000080003b82 <iinit>:
{
    80003b82:	7179                	add	sp,sp,-48
    80003b84:	f406                	sd	ra,40(sp)
    80003b86:	f022                	sd	s0,32(sp)
    80003b88:	ec26                	sd	s1,24(sp)
    80003b8a:	e84a                	sd	s2,16(sp)
    80003b8c:	e44e                	sd	s3,8(sp)
    80003b8e:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b90:	00005597          	auipc	a1,0x5
    80003b94:	a4058593          	add	a1,a1,-1472 # 800085d0 <syscalls+0x170>
    80003b98:	0023c517          	auipc	a0,0x23c
    80003b9c:	10850513          	add	a0,a0,264 # 8023fca0 <itable>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	0aa080e7          	jalr	170(ra) # 80000c4a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ba8:	0023c497          	auipc	s1,0x23c
    80003bac:	12048493          	add	s1,s1,288 # 8023fcc8 <itable+0x28>
    80003bb0:	0023e997          	auipc	s3,0x23e
    80003bb4:	ba898993          	add	s3,s3,-1112 # 80241758 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bb8:	00005917          	auipc	s2,0x5
    80003bbc:	a2090913          	add	s2,s2,-1504 # 800085d8 <syscalls+0x178>
    80003bc0:	85ca                	mv	a1,s2
    80003bc2:	8526                	mv	a0,s1
    80003bc4:	00001097          	auipc	ra,0x1
    80003bc8:	e12080e7          	jalr	-494(ra) # 800049d6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003bcc:	08848493          	add	s1,s1,136
    80003bd0:	ff3498e3          	bne	s1,s3,80003bc0 <iinit+0x3e>
}
    80003bd4:	70a2                	ld	ra,40(sp)
    80003bd6:	7402                	ld	s0,32(sp)
    80003bd8:	64e2                	ld	s1,24(sp)
    80003bda:	6942                	ld	s2,16(sp)
    80003bdc:	69a2                	ld	s3,8(sp)
    80003bde:	6145                	add	sp,sp,48
    80003be0:	8082                	ret

0000000080003be2 <ialloc>:
{
    80003be2:	7139                	add	sp,sp,-64
    80003be4:	fc06                	sd	ra,56(sp)
    80003be6:	f822                	sd	s0,48(sp)
    80003be8:	f426                	sd	s1,40(sp)
    80003bea:	f04a                	sd	s2,32(sp)
    80003bec:	ec4e                	sd	s3,24(sp)
    80003bee:	e852                	sd	s4,16(sp)
    80003bf0:	e456                	sd	s5,8(sp)
    80003bf2:	e05a                	sd	s6,0(sp)
    80003bf4:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bf6:	0023c717          	auipc	a4,0x23c
    80003bfa:	09672703          	lw	a4,150(a4) # 8023fc8c <sb+0xc>
    80003bfe:	4785                	li	a5,1
    80003c00:	04e7f863          	bgeu	a5,a4,80003c50 <ialloc+0x6e>
    80003c04:	8aaa                	mv	s5,a0
    80003c06:	8b2e                	mv	s6,a1
    80003c08:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c0a:	0023ca17          	auipc	s4,0x23c
    80003c0e:	076a0a13          	add	s4,s4,118 # 8023fc80 <sb>
    80003c12:	00495593          	srl	a1,s2,0x4
    80003c16:	018a2783          	lw	a5,24(s4)
    80003c1a:	9dbd                	addw	a1,a1,a5
    80003c1c:	8556                	mv	a0,s5
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	94c080e7          	jalr	-1716(ra) # 8000356a <bread>
    80003c26:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c28:	05850993          	add	s3,a0,88
    80003c2c:	00f97793          	and	a5,s2,15
    80003c30:	079a                	sll	a5,a5,0x6
    80003c32:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c34:	00099783          	lh	a5,0(s3)
    80003c38:	cf9d                	beqz	a5,80003c76 <ialloc+0x94>
    brelse(bp);
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	a60080e7          	jalr	-1440(ra) # 8000369a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c42:	0905                	add	s2,s2,1
    80003c44:	00ca2703          	lw	a4,12(s4)
    80003c48:	0009079b          	sext.w	a5,s2
    80003c4c:	fce7e3e3          	bltu	a5,a4,80003c12 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003c50:	00005517          	auipc	a0,0x5
    80003c54:	99050513          	add	a0,a0,-1648 # 800085e0 <syscalls+0x180>
    80003c58:	ffffd097          	auipc	ra,0xffffd
    80003c5c:	92e080e7          	jalr	-1746(ra) # 80000586 <printf>
  return 0;
    80003c60:	4501                	li	a0,0
}
    80003c62:	70e2                	ld	ra,56(sp)
    80003c64:	7442                	ld	s0,48(sp)
    80003c66:	74a2                	ld	s1,40(sp)
    80003c68:	7902                	ld	s2,32(sp)
    80003c6a:	69e2                	ld	s3,24(sp)
    80003c6c:	6a42                	ld	s4,16(sp)
    80003c6e:	6aa2                	ld	s5,8(sp)
    80003c70:	6b02                	ld	s6,0(sp)
    80003c72:	6121                	add	sp,sp,64
    80003c74:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c76:	04000613          	li	a2,64
    80003c7a:	4581                	li	a1,0
    80003c7c:	854e                	mv	a0,s3
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	158080e7          	jalr	344(ra) # 80000dd6 <memset>
      dip->type = type;
    80003c86:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c8a:	8526                	mv	a0,s1
    80003c8c:	00001097          	auipc	ra,0x1
    80003c90:	c66080e7          	jalr	-922(ra) # 800048f2 <log_write>
      brelse(bp);
    80003c94:	8526                	mv	a0,s1
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	a04080e7          	jalr	-1532(ra) # 8000369a <brelse>
      return iget(dev, inum);
    80003c9e:	0009059b          	sext.w	a1,s2
    80003ca2:	8556                	mv	a0,s5
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	da2080e7          	jalr	-606(ra) # 80003a46 <iget>
    80003cac:	bf5d                	j	80003c62 <ialloc+0x80>

0000000080003cae <iupdate>:
{
    80003cae:	1101                	add	sp,sp,-32
    80003cb0:	ec06                	sd	ra,24(sp)
    80003cb2:	e822                	sd	s0,16(sp)
    80003cb4:	e426                	sd	s1,8(sp)
    80003cb6:	e04a                	sd	s2,0(sp)
    80003cb8:	1000                	add	s0,sp,32
    80003cba:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cbc:	415c                	lw	a5,4(a0)
    80003cbe:	0047d79b          	srlw	a5,a5,0x4
    80003cc2:	0023c597          	auipc	a1,0x23c
    80003cc6:	fd65a583          	lw	a1,-42(a1) # 8023fc98 <sb+0x18>
    80003cca:	9dbd                	addw	a1,a1,a5
    80003ccc:	4108                	lw	a0,0(a0)
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	89c080e7          	jalr	-1892(ra) # 8000356a <bread>
    80003cd6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cd8:	05850793          	add	a5,a0,88
    80003cdc:	40d8                	lw	a4,4(s1)
    80003cde:	8b3d                	and	a4,a4,15
    80003ce0:	071a                	sll	a4,a4,0x6
    80003ce2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003ce4:	04449703          	lh	a4,68(s1)
    80003ce8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003cec:	04649703          	lh	a4,70(s1)
    80003cf0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003cf4:	04849703          	lh	a4,72(s1)
    80003cf8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003cfc:	04a49703          	lh	a4,74(s1)
    80003d00:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d04:	44f8                	lw	a4,76(s1)
    80003d06:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d08:	03400613          	li	a2,52
    80003d0c:	05048593          	add	a1,s1,80
    80003d10:	00c78513          	add	a0,a5,12
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	11e080e7          	jalr	286(ra) # 80000e32 <memmove>
  log_write(bp);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00001097          	auipc	ra,0x1
    80003d22:	bd4080e7          	jalr	-1068(ra) # 800048f2 <log_write>
  brelse(bp);
    80003d26:	854a                	mv	a0,s2
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	972080e7          	jalr	-1678(ra) # 8000369a <brelse>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6902                	ld	s2,0(sp)
    80003d38:	6105                	add	sp,sp,32
    80003d3a:	8082                	ret

0000000080003d3c <idup>:
{
    80003d3c:	1101                	add	sp,sp,-32
    80003d3e:	ec06                	sd	ra,24(sp)
    80003d40:	e822                	sd	s0,16(sp)
    80003d42:	e426                	sd	s1,8(sp)
    80003d44:	1000                	add	s0,sp,32
    80003d46:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d48:	0023c517          	auipc	a0,0x23c
    80003d4c:	f5850513          	add	a0,a0,-168 # 8023fca0 <itable>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	f8a080e7          	jalr	-118(ra) # 80000cda <acquire>
  ip->ref++;
    80003d58:	449c                	lw	a5,8(s1)
    80003d5a:	2785                	addw	a5,a5,1
    80003d5c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d5e:	0023c517          	auipc	a0,0x23c
    80003d62:	f4250513          	add	a0,a0,-190 # 8023fca0 <itable>
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	028080e7          	jalr	40(ra) # 80000d8e <release>
}
    80003d6e:	8526                	mv	a0,s1
    80003d70:	60e2                	ld	ra,24(sp)
    80003d72:	6442                	ld	s0,16(sp)
    80003d74:	64a2                	ld	s1,8(sp)
    80003d76:	6105                	add	sp,sp,32
    80003d78:	8082                	ret

0000000080003d7a <ilock>:
{
    80003d7a:	1101                	add	sp,sp,-32
    80003d7c:	ec06                	sd	ra,24(sp)
    80003d7e:	e822                	sd	s0,16(sp)
    80003d80:	e426                	sd	s1,8(sp)
    80003d82:	e04a                	sd	s2,0(sp)
    80003d84:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d86:	c115                	beqz	a0,80003daa <ilock+0x30>
    80003d88:	84aa                	mv	s1,a0
    80003d8a:	451c                	lw	a5,8(a0)
    80003d8c:	00f05f63          	blez	a5,80003daa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d90:	0541                	add	a0,a0,16
    80003d92:	00001097          	auipc	ra,0x1
    80003d96:	c7e080e7          	jalr	-898(ra) # 80004a10 <acquiresleep>
  if(ip->valid == 0){
    80003d9a:	40bc                	lw	a5,64(s1)
    80003d9c:	cf99                	beqz	a5,80003dba <ilock+0x40>
}
    80003d9e:	60e2                	ld	ra,24(sp)
    80003da0:	6442                	ld	s0,16(sp)
    80003da2:	64a2                	ld	s1,8(sp)
    80003da4:	6902                	ld	s2,0(sp)
    80003da6:	6105                	add	sp,sp,32
    80003da8:	8082                	ret
    panic("ilock");
    80003daa:	00005517          	auipc	a0,0x5
    80003dae:	84e50513          	add	a0,a0,-1970 # 800085f8 <syscalls+0x198>
    80003db2:	ffffc097          	auipc	ra,0xffffc
    80003db6:	78a080e7          	jalr	1930(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dba:	40dc                	lw	a5,4(s1)
    80003dbc:	0047d79b          	srlw	a5,a5,0x4
    80003dc0:	0023c597          	auipc	a1,0x23c
    80003dc4:	ed85a583          	lw	a1,-296(a1) # 8023fc98 <sb+0x18>
    80003dc8:	9dbd                	addw	a1,a1,a5
    80003dca:	4088                	lw	a0,0(s1)
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	79e080e7          	jalr	1950(ra) # 8000356a <bread>
    80003dd4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dd6:	05850593          	add	a1,a0,88
    80003dda:	40dc                	lw	a5,4(s1)
    80003ddc:	8bbd                	and	a5,a5,15
    80003dde:	079a                	sll	a5,a5,0x6
    80003de0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003de2:	00059783          	lh	a5,0(a1)
    80003de6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dea:	00259783          	lh	a5,2(a1)
    80003dee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003df2:	00459783          	lh	a5,4(a1)
    80003df6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dfa:	00659783          	lh	a5,6(a1)
    80003dfe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e02:	459c                	lw	a5,8(a1)
    80003e04:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e06:	03400613          	li	a2,52
    80003e0a:	05b1                	add	a1,a1,12
    80003e0c:	05048513          	add	a0,s1,80
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	022080e7          	jalr	34(ra) # 80000e32 <memmove>
    brelse(bp);
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	880080e7          	jalr	-1920(ra) # 8000369a <brelse>
    ip->valid = 1;
    80003e22:	4785                	li	a5,1
    80003e24:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e26:	04449783          	lh	a5,68(s1)
    80003e2a:	fbb5                	bnez	a5,80003d9e <ilock+0x24>
      panic("ilock: no type");
    80003e2c:	00004517          	auipc	a0,0x4
    80003e30:	7d450513          	add	a0,a0,2004 # 80008600 <syscalls+0x1a0>
    80003e34:	ffffc097          	auipc	ra,0xffffc
    80003e38:	708080e7          	jalr	1800(ra) # 8000053c <panic>

0000000080003e3c <iunlock>:
{
    80003e3c:	1101                	add	sp,sp,-32
    80003e3e:	ec06                	sd	ra,24(sp)
    80003e40:	e822                	sd	s0,16(sp)
    80003e42:	e426                	sd	s1,8(sp)
    80003e44:	e04a                	sd	s2,0(sp)
    80003e46:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e48:	c905                	beqz	a0,80003e78 <iunlock+0x3c>
    80003e4a:	84aa                	mv	s1,a0
    80003e4c:	01050913          	add	s2,a0,16
    80003e50:	854a                	mv	a0,s2
    80003e52:	00001097          	auipc	ra,0x1
    80003e56:	c58080e7          	jalr	-936(ra) # 80004aaa <holdingsleep>
    80003e5a:	cd19                	beqz	a0,80003e78 <iunlock+0x3c>
    80003e5c:	449c                	lw	a5,8(s1)
    80003e5e:	00f05d63          	blez	a5,80003e78 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e62:	854a                	mv	a0,s2
    80003e64:	00001097          	auipc	ra,0x1
    80003e68:	c02080e7          	jalr	-1022(ra) # 80004a66 <releasesleep>
}
    80003e6c:	60e2                	ld	ra,24(sp)
    80003e6e:	6442                	ld	s0,16(sp)
    80003e70:	64a2                	ld	s1,8(sp)
    80003e72:	6902                	ld	s2,0(sp)
    80003e74:	6105                	add	sp,sp,32
    80003e76:	8082                	ret
    panic("iunlock");
    80003e78:	00004517          	auipc	a0,0x4
    80003e7c:	79850513          	add	a0,a0,1944 # 80008610 <syscalls+0x1b0>
    80003e80:	ffffc097          	auipc	ra,0xffffc
    80003e84:	6bc080e7          	jalr	1724(ra) # 8000053c <panic>

0000000080003e88 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e88:	7179                	add	sp,sp,-48
    80003e8a:	f406                	sd	ra,40(sp)
    80003e8c:	f022                	sd	s0,32(sp)
    80003e8e:	ec26                	sd	s1,24(sp)
    80003e90:	e84a                	sd	s2,16(sp)
    80003e92:	e44e                	sd	s3,8(sp)
    80003e94:	e052                	sd	s4,0(sp)
    80003e96:	1800                	add	s0,sp,48
    80003e98:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e9a:	05050493          	add	s1,a0,80
    80003e9e:	08050913          	add	s2,a0,128
    80003ea2:	a021                	j	80003eaa <itrunc+0x22>
    80003ea4:	0491                	add	s1,s1,4
    80003ea6:	01248d63          	beq	s1,s2,80003ec0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003eaa:	408c                	lw	a1,0(s1)
    80003eac:	dde5                	beqz	a1,80003ea4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003eae:	0009a503          	lw	a0,0(s3)
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	8fc080e7          	jalr	-1796(ra) # 800037ae <bfree>
      ip->addrs[i] = 0;
    80003eba:	0004a023          	sw	zero,0(s1)
    80003ebe:	b7dd                	j	80003ea4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ec0:	0809a583          	lw	a1,128(s3)
    80003ec4:	e185                	bnez	a1,80003ee4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ec6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003eca:	854e                	mv	a0,s3
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	de2080e7          	jalr	-542(ra) # 80003cae <iupdate>
}
    80003ed4:	70a2                	ld	ra,40(sp)
    80003ed6:	7402                	ld	s0,32(sp)
    80003ed8:	64e2                	ld	s1,24(sp)
    80003eda:	6942                	ld	s2,16(sp)
    80003edc:	69a2                	ld	s3,8(sp)
    80003ede:	6a02                	ld	s4,0(sp)
    80003ee0:	6145                	add	sp,sp,48
    80003ee2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ee4:	0009a503          	lw	a0,0(s3)
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	682080e7          	jalr	1666(ra) # 8000356a <bread>
    80003ef0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ef2:	05850493          	add	s1,a0,88
    80003ef6:	45850913          	add	s2,a0,1112
    80003efa:	a021                	j	80003f02 <itrunc+0x7a>
    80003efc:	0491                	add	s1,s1,4
    80003efe:	01248b63          	beq	s1,s2,80003f14 <itrunc+0x8c>
      if(a[j])
    80003f02:	408c                	lw	a1,0(s1)
    80003f04:	dde5                	beqz	a1,80003efc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f06:	0009a503          	lw	a0,0(s3)
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	8a4080e7          	jalr	-1884(ra) # 800037ae <bfree>
    80003f12:	b7ed                	j	80003efc <itrunc+0x74>
    brelse(bp);
    80003f14:	8552                	mv	a0,s4
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	784080e7          	jalr	1924(ra) # 8000369a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f1e:	0809a583          	lw	a1,128(s3)
    80003f22:	0009a503          	lw	a0,0(s3)
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	888080e7          	jalr	-1912(ra) # 800037ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f2e:	0809a023          	sw	zero,128(s3)
    80003f32:	bf51                	j	80003ec6 <itrunc+0x3e>

0000000080003f34 <iput>:
{
    80003f34:	1101                	add	sp,sp,-32
    80003f36:	ec06                	sd	ra,24(sp)
    80003f38:	e822                	sd	s0,16(sp)
    80003f3a:	e426                	sd	s1,8(sp)
    80003f3c:	e04a                	sd	s2,0(sp)
    80003f3e:	1000                	add	s0,sp,32
    80003f40:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f42:	0023c517          	auipc	a0,0x23c
    80003f46:	d5e50513          	add	a0,a0,-674 # 8023fca0 <itable>
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	d90080e7          	jalr	-624(ra) # 80000cda <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f52:	4498                	lw	a4,8(s1)
    80003f54:	4785                	li	a5,1
    80003f56:	02f70363          	beq	a4,a5,80003f7c <iput+0x48>
  ip->ref--;
    80003f5a:	449c                	lw	a5,8(s1)
    80003f5c:	37fd                	addw	a5,a5,-1
    80003f5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f60:	0023c517          	auipc	a0,0x23c
    80003f64:	d4050513          	add	a0,a0,-704 # 8023fca0 <itable>
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	e26080e7          	jalr	-474(ra) # 80000d8e <release>
}
    80003f70:	60e2                	ld	ra,24(sp)
    80003f72:	6442                	ld	s0,16(sp)
    80003f74:	64a2                	ld	s1,8(sp)
    80003f76:	6902                	ld	s2,0(sp)
    80003f78:	6105                	add	sp,sp,32
    80003f7a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f7c:	40bc                	lw	a5,64(s1)
    80003f7e:	dff1                	beqz	a5,80003f5a <iput+0x26>
    80003f80:	04a49783          	lh	a5,74(s1)
    80003f84:	fbf9                	bnez	a5,80003f5a <iput+0x26>
    acquiresleep(&ip->lock);
    80003f86:	01048913          	add	s2,s1,16
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	00001097          	auipc	ra,0x1
    80003f90:	a84080e7          	jalr	-1404(ra) # 80004a10 <acquiresleep>
    release(&itable.lock);
    80003f94:	0023c517          	auipc	a0,0x23c
    80003f98:	d0c50513          	add	a0,a0,-756 # 8023fca0 <itable>
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	df2080e7          	jalr	-526(ra) # 80000d8e <release>
    itrunc(ip);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	ee2080e7          	jalr	-286(ra) # 80003e88 <itrunc>
    ip->type = 0;
    80003fae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	cfa080e7          	jalr	-774(ra) # 80003cae <iupdate>
    ip->valid = 0;
    80003fbc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fc0:	854a                	mv	a0,s2
    80003fc2:	00001097          	auipc	ra,0x1
    80003fc6:	aa4080e7          	jalr	-1372(ra) # 80004a66 <releasesleep>
    acquire(&itable.lock);
    80003fca:	0023c517          	auipc	a0,0x23c
    80003fce:	cd650513          	add	a0,a0,-810 # 8023fca0 <itable>
    80003fd2:	ffffd097          	auipc	ra,0xffffd
    80003fd6:	d08080e7          	jalr	-760(ra) # 80000cda <acquire>
    80003fda:	b741                	j	80003f5a <iput+0x26>

0000000080003fdc <iunlockput>:
{
    80003fdc:	1101                	add	sp,sp,-32
    80003fde:	ec06                	sd	ra,24(sp)
    80003fe0:	e822                	sd	s0,16(sp)
    80003fe2:	e426                	sd	s1,8(sp)
    80003fe4:	1000                	add	s0,sp,32
    80003fe6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	e54080e7          	jalr	-428(ra) # 80003e3c <iunlock>
  iput(ip);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	f42080e7          	jalr	-190(ra) # 80003f34 <iput>
}
    80003ffa:	60e2                	ld	ra,24(sp)
    80003ffc:	6442                	ld	s0,16(sp)
    80003ffe:	64a2                	ld	s1,8(sp)
    80004000:	6105                	add	sp,sp,32
    80004002:	8082                	ret

0000000080004004 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004004:	1141                	add	sp,sp,-16
    80004006:	e422                	sd	s0,8(sp)
    80004008:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    8000400a:	411c                	lw	a5,0(a0)
    8000400c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000400e:	415c                	lw	a5,4(a0)
    80004010:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004012:	04451783          	lh	a5,68(a0)
    80004016:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000401a:	04a51783          	lh	a5,74(a0)
    8000401e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004022:	04c56783          	lwu	a5,76(a0)
    80004026:	e99c                	sd	a5,16(a1)
}
    80004028:	6422                	ld	s0,8(sp)
    8000402a:	0141                	add	sp,sp,16
    8000402c:	8082                	ret

000000008000402e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000402e:	457c                	lw	a5,76(a0)
    80004030:	0ed7e963          	bltu	a5,a3,80004122 <readi+0xf4>
{
    80004034:	7159                	add	sp,sp,-112
    80004036:	f486                	sd	ra,104(sp)
    80004038:	f0a2                	sd	s0,96(sp)
    8000403a:	eca6                	sd	s1,88(sp)
    8000403c:	e8ca                	sd	s2,80(sp)
    8000403e:	e4ce                	sd	s3,72(sp)
    80004040:	e0d2                	sd	s4,64(sp)
    80004042:	fc56                	sd	s5,56(sp)
    80004044:	f85a                	sd	s6,48(sp)
    80004046:	f45e                	sd	s7,40(sp)
    80004048:	f062                	sd	s8,32(sp)
    8000404a:	ec66                	sd	s9,24(sp)
    8000404c:	e86a                	sd	s10,16(sp)
    8000404e:	e46e                	sd	s11,8(sp)
    80004050:	1880                	add	s0,sp,112
    80004052:	8b2a                	mv	s6,a0
    80004054:	8bae                	mv	s7,a1
    80004056:	8a32                	mv	s4,a2
    80004058:	84b6                	mv	s1,a3
    8000405a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000405c:	9f35                	addw	a4,a4,a3
    return 0;
    8000405e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004060:	0ad76063          	bltu	a4,a3,80004100 <readi+0xd2>
  if(off + n > ip->size)
    80004064:	00e7f463          	bgeu	a5,a4,8000406c <readi+0x3e>
    n = ip->size - off;
    80004068:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000406c:	0a0a8963          	beqz	s5,8000411e <readi+0xf0>
    80004070:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004072:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004076:	5c7d                	li	s8,-1
    80004078:	a82d                	j	800040b2 <readi+0x84>
    8000407a:	020d1d93          	sll	s11,s10,0x20
    8000407e:	020ddd93          	srl	s11,s11,0x20
    80004082:	05890613          	add	a2,s2,88
    80004086:	86ee                	mv	a3,s11
    80004088:	963a                	add	a2,a2,a4
    8000408a:	85d2                	mv	a1,s4
    8000408c:	855e                	mv	a0,s7
    8000408e:	ffffe097          	auipc	ra,0xffffe
    80004092:	756080e7          	jalr	1878(ra) # 800027e4 <either_copyout>
    80004096:	05850d63          	beq	a0,s8,800040f0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000409a:	854a                	mv	a0,s2
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	5fe080e7          	jalr	1534(ra) # 8000369a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040a4:	013d09bb          	addw	s3,s10,s3
    800040a8:	009d04bb          	addw	s1,s10,s1
    800040ac:	9a6e                	add	s4,s4,s11
    800040ae:	0559f763          	bgeu	s3,s5,800040fc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040b2:	00a4d59b          	srlw	a1,s1,0xa
    800040b6:	855a                	mv	a0,s6
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	8a4080e7          	jalr	-1884(ra) # 8000395c <bmap>
    800040c0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040c4:	cd85                	beqz	a1,800040fc <readi+0xce>
    bp = bread(ip->dev, addr);
    800040c6:	000b2503          	lw	a0,0(s6)
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	4a0080e7          	jalr	1184(ra) # 8000356a <bread>
    800040d2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040d4:	3ff4f713          	and	a4,s1,1023
    800040d8:	40ec87bb          	subw	a5,s9,a4
    800040dc:	413a86bb          	subw	a3,s5,s3
    800040e0:	8d3e                	mv	s10,a5
    800040e2:	2781                	sext.w	a5,a5
    800040e4:	0006861b          	sext.w	a2,a3
    800040e8:	f8f679e3          	bgeu	a2,a5,8000407a <readi+0x4c>
    800040ec:	8d36                	mv	s10,a3
    800040ee:	b771                	j	8000407a <readi+0x4c>
      brelse(bp);
    800040f0:	854a                	mv	a0,s2
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	5a8080e7          	jalr	1448(ra) # 8000369a <brelse>
      tot = -1;
    800040fa:	59fd                	li	s3,-1
  }
  return tot;
    800040fc:	0009851b          	sext.w	a0,s3
}
    80004100:	70a6                	ld	ra,104(sp)
    80004102:	7406                	ld	s0,96(sp)
    80004104:	64e6                	ld	s1,88(sp)
    80004106:	6946                	ld	s2,80(sp)
    80004108:	69a6                	ld	s3,72(sp)
    8000410a:	6a06                	ld	s4,64(sp)
    8000410c:	7ae2                	ld	s5,56(sp)
    8000410e:	7b42                	ld	s6,48(sp)
    80004110:	7ba2                	ld	s7,40(sp)
    80004112:	7c02                	ld	s8,32(sp)
    80004114:	6ce2                	ld	s9,24(sp)
    80004116:	6d42                	ld	s10,16(sp)
    80004118:	6da2                	ld	s11,8(sp)
    8000411a:	6165                	add	sp,sp,112
    8000411c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000411e:	89d6                	mv	s3,s5
    80004120:	bff1                	j	800040fc <readi+0xce>
    return 0;
    80004122:	4501                	li	a0,0
}
    80004124:	8082                	ret

0000000080004126 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004126:	457c                	lw	a5,76(a0)
    80004128:	10d7e863          	bltu	a5,a3,80004238 <writei+0x112>
{
    8000412c:	7159                	add	sp,sp,-112
    8000412e:	f486                	sd	ra,104(sp)
    80004130:	f0a2                	sd	s0,96(sp)
    80004132:	eca6                	sd	s1,88(sp)
    80004134:	e8ca                	sd	s2,80(sp)
    80004136:	e4ce                	sd	s3,72(sp)
    80004138:	e0d2                	sd	s4,64(sp)
    8000413a:	fc56                	sd	s5,56(sp)
    8000413c:	f85a                	sd	s6,48(sp)
    8000413e:	f45e                	sd	s7,40(sp)
    80004140:	f062                	sd	s8,32(sp)
    80004142:	ec66                	sd	s9,24(sp)
    80004144:	e86a                	sd	s10,16(sp)
    80004146:	e46e                	sd	s11,8(sp)
    80004148:	1880                	add	s0,sp,112
    8000414a:	8aaa                	mv	s5,a0
    8000414c:	8bae                	mv	s7,a1
    8000414e:	8a32                	mv	s4,a2
    80004150:	8936                	mv	s2,a3
    80004152:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004154:	00e687bb          	addw	a5,a3,a4
    80004158:	0ed7e263          	bltu	a5,a3,8000423c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000415c:	00043737          	lui	a4,0x43
    80004160:	0ef76063          	bltu	a4,a5,80004240 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004164:	0c0b0863          	beqz	s6,80004234 <writei+0x10e>
    80004168:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000416a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000416e:	5c7d                	li	s8,-1
    80004170:	a091                	j	800041b4 <writei+0x8e>
    80004172:	020d1d93          	sll	s11,s10,0x20
    80004176:	020ddd93          	srl	s11,s11,0x20
    8000417a:	05848513          	add	a0,s1,88
    8000417e:	86ee                	mv	a3,s11
    80004180:	8652                	mv	a2,s4
    80004182:	85de                	mv	a1,s7
    80004184:	953a                	add	a0,a0,a4
    80004186:	ffffe097          	auipc	ra,0xffffe
    8000418a:	6b4080e7          	jalr	1716(ra) # 8000283a <either_copyin>
    8000418e:	07850263          	beq	a0,s8,800041f2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004192:	8526                	mv	a0,s1
    80004194:	00000097          	auipc	ra,0x0
    80004198:	75e080e7          	jalr	1886(ra) # 800048f2 <log_write>
    brelse(bp);
    8000419c:	8526                	mv	a0,s1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	4fc080e7          	jalr	1276(ra) # 8000369a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a6:	013d09bb          	addw	s3,s10,s3
    800041aa:	012d093b          	addw	s2,s10,s2
    800041ae:	9a6e                	add	s4,s4,s11
    800041b0:	0569f663          	bgeu	s3,s6,800041fc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041b4:	00a9559b          	srlw	a1,s2,0xa
    800041b8:	8556                	mv	a0,s5
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	7a2080e7          	jalr	1954(ra) # 8000395c <bmap>
    800041c2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041c6:	c99d                	beqz	a1,800041fc <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041c8:	000aa503          	lw	a0,0(s5)
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	39e080e7          	jalr	926(ra) # 8000356a <bread>
    800041d4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d6:	3ff97713          	and	a4,s2,1023
    800041da:	40ec87bb          	subw	a5,s9,a4
    800041de:	413b06bb          	subw	a3,s6,s3
    800041e2:	8d3e                	mv	s10,a5
    800041e4:	2781                	sext.w	a5,a5
    800041e6:	0006861b          	sext.w	a2,a3
    800041ea:	f8f674e3          	bgeu	a2,a5,80004172 <writei+0x4c>
    800041ee:	8d36                	mv	s10,a3
    800041f0:	b749                	j	80004172 <writei+0x4c>
      brelse(bp);
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	4a6080e7          	jalr	1190(ra) # 8000369a <brelse>
  }

  if(off > ip->size)
    800041fc:	04caa783          	lw	a5,76(s5)
    80004200:	0127f463          	bgeu	a5,s2,80004208 <writei+0xe2>
    ip->size = off;
    80004204:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004208:	8556                	mv	a0,s5
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	aa4080e7          	jalr	-1372(ra) # 80003cae <iupdate>

  return tot;
    80004212:	0009851b          	sext.w	a0,s3
}
    80004216:	70a6                	ld	ra,104(sp)
    80004218:	7406                	ld	s0,96(sp)
    8000421a:	64e6                	ld	s1,88(sp)
    8000421c:	6946                	ld	s2,80(sp)
    8000421e:	69a6                	ld	s3,72(sp)
    80004220:	6a06                	ld	s4,64(sp)
    80004222:	7ae2                	ld	s5,56(sp)
    80004224:	7b42                	ld	s6,48(sp)
    80004226:	7ba2                	ld	s7,40(sp)
    80004228:	7c02                	ld	s8,32(sp)
    8000422a:	6ce2                	ld	s9,24(sp)
    8000422c:	6d42                	ld	s10,16(sp)
    8000422e:	6da2                	ld	s11,8(sp)
    80004230:	6165                	add	sp,sp,112
    80004232:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004234:	89da                	mv	s3,s6
    80004236:	bfc9                	j	80004208 <writei+0xe2>
    return -1;
    80004238:	557d                	li	a0,-1
}
    8000423a:	8082                	ret
    return -1;
    8000423c:	557d                	li	a0,-1
    8000423e:	bfe1                	j	80004216 <writei+0xf0>
    return -1;
    80004240:	557d                	li	a0,-1
    80004242:	bfd1                	j	80004216 <writei+0xf0>

0000000080004244 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004244:	1141                	add	sp,sp,-16
    80004246:	e406                	sd	ra,8(sp)
    80004248:	e022                	sd	s0,0(sp)
    8000424a:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000424c:	4639                	li	a2,14
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	c58080e7          	jalr	-936(ra) # 80000ea6 <strncmp>
}
    80004256:	60a2                	ld	ra,8(sp)
    80004258:	6402                	ld	s0,0(sp)
    8000425a:	0141                	add	sp,sp,16
    8000425c:	8082                	ret

000000008000425e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000425e:	7139                	add	sp,sp,-64
    80004260:	fc06                	sd	ra,56(sp)
    80004262:	f822                	sd	s0,48(sp)
    80004264:	f426                	sd	s1,40(sp)
    80004266:	f04a                	sd	s2,32(sp)
    80004268:	ec4e                	sd	s3,24(sp)
    8000426a:	e852                	sd	s4,16(sp)
    8000426c:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000426e:	04451703          	lh	a4,68(a0)
    80004272:	4785                	li	a5,1
    80004274:	00f71a63          	bne	a4,a5,80004288 <dirlookup+0x2a>
    80004278:	892a                	mv	s2,a0
    8000427a:	89ae                	mv	s3,a1
    8000427c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000427e:	457c                	lw	a5,76(a0)
    80004280:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004282:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004284:	e79d                	bnez	a5,800042b2 <dirlookup+0x54>
    80004286:	a8a5                	j	800042fe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004288:	00004517          	auipc	a0,0x4
    8000428c:	39050513          	add	a0,a0,912 # 80008618 <syscalls+0x1b8>
    80004290:	ffffc097          	auipc	ra,0xffffc
    80004294:	2ac080e7          	jalr	684(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004298:	00004517          	auipc	a0,0x4
    8000429c:	39850513          	add	a0,a0,920 # 80008630 <syscalls+0x1d0>
    800042a0:	ffffc097          	auipc	ra,0xffffc
    800042a4:	29c080e7          	jalr	668(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a8:	24c1                	addw	s1,s1,16
    800042aa:	04c92783          	lw	a5,76(s2)
    800042ae:	04f4f763          	bgeu	s1,a5,800042fc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b2:	4741                	li	a4,16
    800042b4:	86a6                	mv	a3,s1
    800042b6:	fc040613          	add	a2,s0,-64
    800042ba:	4581                	li	a1,0
    800042bc:	854a                	mv	a0,s2
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	d70080e7          	jalr	-656(ra) # 8000402e <readi>
    800042c6:	47c1                	li	a5,16
    800042c8:	fcf518e3          	bne	a0,a5,80004298 <dirlookup+0x3a>
    if(de.inum == 0)
    800042cc:	fc045783          	lhu	a5,-64(s0)
    800042d0:	dfe1                	beqz	a5,800042a8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042d2:	fc240593          	add	a1,s0,-62
    800042d6:	854e                	mv	a0,s3
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	f6c080e7          	jalr	-148(ra) # 80004244 <namecmp>
    800042e0:	f561                	bnez	a0,800042a8 <dirlookup+0x4a>
      if(poff)
    800042e2:	000a0463          	beqz	s4,800042ea <dirlookup+0x8c>
        *poff = off;
    800042e6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042ea:	fc045583          	lhu	a1,-64(s0)
    800042ee:	00092503          	lw	a0,0(s2)
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	754080e7          	jalr	1876(ra) # 80003a46 <iget>
    800042fa:	a011                	j	800042fe <dirlookup+0xa0>
  return 0;
    800042fc:	4501                	li	a0,0
}
    800042fe:	70e2                	ld	ra,56(sp)
    80004300:	7442                	ld	s0,48(sp)
    80004302:	74a2                	ld	s1,40(sp)
    80004304:	7902                	ld	s2,32(sp)
    80004306:	69e2                	ld	s3,24(sp)
    80004308:	6a42                	ld	s4,16(sp)
    8000430a:	6121                	add	sp,sp,64
    8000430c:	8082                	ret

000000008000430e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000430e:	711d                	add	sp,sp,-96
    80004310:	ec86                	sd	ra,88(sp)
    80004312:	e8a2                	sd	s0,80(sp)
    80004314:	e4a6                	sd	s1,72(sp)
    80004316:	e0ca                	sd	s2,64(sp)
    80004318:	fc4e                	sd	s3,56(sp)
    8000431a:	f852                	sd	s4,48(sp)
    8000431c:	f456                	sd	s5,40(sp)
    8000431e:	f05a                	sd	s6,32(sp)
    80004320:	ec5e                	sd	s7,24(sp)
    80004322:	e862                	sd	s8,16(sp)
    80004324:	e466                	sd	s9,8(sp)
    80004326:	1080                	add	s0,sp,96
    80004328:	84aa                	mv	s1,a0
    8000432a:	8b2e                	mv	s6,a1
    8000432c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000432e:	00054703          	lbu	a4,0(a0)
    80004332:	02f00793          	li	a5,47
    80004336:	02f70263          	beq	a4,a5,8000435a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	7da080e7          	jalr	2010(ra) # 80001b14 <myproc>
    80004342:	15053503          	ld	a0,336(a0)
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	9f6080e7          	jalr	-1546(ra) # 80003d3c <idup>
    8000434e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004350:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004354:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004356:	4b85                	li	s7,1
    80004358:	a875                	j	80004414 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000435a:	4585                	li	a1,1
    8000435c:	4505                	li	a0,1
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	6e8080e7          	jalr	1768(ra) # 80003a46 <iget>
    80004366:	8a2a                	mv	s4,a0
    80004368:	b7e5                	j	80004350 <namex+0x42>
      iunlockput(ip);
    8000436a:	8552                	mv	a0,s4
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	c70080e7          	jalr	-912(ra) # 80003fdc <iunlockput>
      return 0;
    80004374:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004376:	8552                	mv	a0,s4
    80004378:	60e6                	ld	ra,88(sp)
    8000437a:	6446                	ld	s0,80(sp)
    8000437c:	64a6                	ld	s1,72(sp)
    8000437e:	6906                	ld	s2,64(sp)
    80004380:	79e2                	ld	s3,56(sp)
    80004382:	7a42                	ld	s4,48(sp)
    80004384:	7aa2                	ld	s5,40(sp)
    80004386:	7b02                	ld	s6,32(sp)
    80004388:	6be2                	ld	s7,24(sp)
    8000438a:	6c42                	ld	s8,16(sp)
    8000438c:	6ca2                	ld	s9,8(sp)
    8000438e:	6125                	add	sp,sp,96
    80004390:	8082                	ret
      iunlock(ip);
    80004392:	8552                	mv	a0,s4
    80004394:	00000097          	auipc	ra,0x0
    80004398:	aa8080e7          	jalr	-1368(ra) # 80003e3c <iunlock>
      return ip;
    8000439c:	bfe9                	j	80004376 <namex+0x68>
      iunlockput(ip);
    8000439e:	8552                	mv	a0,s4
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	c3c080e7          	jalr	-964(ra) # 80003fdc <iunlockput>
      return 0;
    800043a8:	8a4e                	mv	s4,s3
    800043aa:	b7f1                	j	80004376 <namex+0x68>
  len = path - s;
    800043ac:	40998633          	sub	a2,s3,s1
    800043b0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043b4:	099c5863          	bge	s8,s9,80004444 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800043b8:	4639                	li	a2,14
    800043ba:	85a6                	mv	a1,s1
    800043bc:	8556                	mv	a0,s5
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	a74080e7          	jalr	-1420(ra) # 80000e32 <memmove>
    800043c6:	84ce                	mv	s1,s3
  while(*path == '/')
    800043c8:	0004c783          	lbu	a5,0(s1)
    800043cc:	01279763          	bne	a5,s2,800043da <namex+0xcc>
    path++;
    800043d0:	0485                	add	s1,s1,1
  while(*path == '/')
    800043d2:	0004c783          	lbu	a5,0(s1)
    800043d6:	ff278de3          	beq	a5,s2,800043d0 <namex+0xc2>
    ilock(ip);
    800043da:	8552                	mv	a0,s4
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	99e080e7          	jalr	-1634(ra) # 80003d7a <ilock>
    if(ip->type != T_DIR){
    800043e4:	044a1783          	lh	a5,68(s4)
    800043e8:	f97791e3          	bne	a5,s7,8000436a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800043ec:	000b0563          	beqz	s6,800043f6 <namex+0xe8>
    800043f0:	0004c783          	lbu	a5,0(s1)
    800043f4:	dfd9                	beqz	a5,80004392 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043f6:	4601                	li	a2,0
    800043f8:	85d6                	mv	a1,s5
    800043fa:	8552                	mv	a0,s4
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	e62080e7          	jalr	-414(ra) # 8000425e <dirlookup>
    80004404:	89aa                	mv	s3,a0
    80004406:	dd41                	beqz	a0,8000439e <namex+0x90>
    iunlockput(ip);
    80004408:	8552                	mv	a0,s4
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	bd2080e7          	jalr	-1070(ra) # 80003fdc <iunlockput>
    ip = next;
    80004412:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004414:	0004c783          	lbu	a5,0(s1)
    80004418:	01279763          	bne	a5,s2,80004426 <namex+0x118>
    path++;
    8000441c:	0485                	add	s1,s1,1
  while(*path == '/')
    8000441e:	0004c783          	lbu	a5,0(s1)
    80004422:	ff278de3          	beq	a5,s2,8000441c <namex+0x10e>
  if(*path == 0)
    80004426:	cb9d                	beqz	a5,8000445c <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004428:	0004c783          	lbu	a5,0(s1)
    8000442c:	89a6                	mv	s3,s1
  len = path - s;
    8000442e:	4c81                	li	s9,0
    80004430:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004432:	01278963          	beq	a5,s2,80004444 <namex+0x136>
    80004436:	dbbd                	beqz	a5,800043ac <namex+0x9e>
    path++;
    80004438:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    8000443a:	0009c783          	lbu	a5,0(s3)
    8000443e:	ff279ce3          	bne	a5,s2,80004436 <namex+0x128>
    80004442:	b7ad                	j	800043ac <namex+0x9e>
    memmove(name, s, len);
    80004444:	2601                	sext.w	a2,a2
    80004446:	85a6                	mv	a1,s1
    80004448:	8556                	mv	a0,s5
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	9e8080e7          	jalr	-1560(ra) # 80000e32 <memmove>
    name[len] = 0;
    80004452:	9cd6                	add	s9,s9,s5
    80004454:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004458:	84ce                	mv	s1,s3
    8000445a:	b7bd                	j	800043c8 <namex+0xba>
  if(nameiparent){
    8000445c:	f00b0de3          	beqz	s6,80004376 <namex+0x68>
    iput(ip);
    80004460:	8552                	mv	a0,s4
    80004462:	00000097          	auipc	ra,0x0
    80004466:	ad2080e7          	jalr	-1326(ra) # 80003f34 <iput>
    return 0;
    8000446a:	4a01                	li	s4,0
    8000446c:	b729                	j	80004376 <namex+0x68>

000000008000446e <dirlink>:
{
    8000446e:	7139                	add	sp,sp,-64
    80004470:	fc06                	sd	ra,56(sp)
    80004472:	f822                	sd	s0,48(sp)
    80004474:	f426                	sd	s1,40(sp)
    80004476:	f04a                	sd	s2,32(sp)
    80004478:	ec4e                	sd	s3,24(sp)
    8000447a:	e852                	sd	s4,16(sp)
    8000447c:	0080                	add	s0,sp,64
    8000447e:	892a                	mv	s2,a0
    80004480:	8a2e                	mv	s4,a1
    80004482:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004484:	4601                	li	a2,0
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	dd8080e7          	jalr	-552(ra) # 8000425e <dirlookup>
    8000448e:	e93d                	bnez	a0,80004504 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004490:	04c92483          	lw	s1,76(s2)
    80004494:	c49d                	beqz	s1,800044c2 <dirlink+0x54>
    80004496:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004498:	4741                	li	a4,16
    8000449a:	86a6                	mv	a3,s1
    8000449c:	fc040613          	add	a2,s0,-64
    800044a0:	4581                	li	a1,0
    800044a2:	854a                	mv	a0,s2
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	b8a080e7          	jalr	-1142(ra) # 8000402e <readi>
    800044ac:	47c1                	li	a5,16
    800044ae:	06f51163          	bne	a0,a5,80004510 <dirlink+0xa2>
    if(de.inum == 0)
    800044b2:	fc045783          	lhu	a5,-64(s0)
    800044b6:	c791                	beqz	a5,800044c2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044b8:	24c1                	addw	s1,s1,16
    800044ba:	04c92783          	lw	a5,76(s2)
    800044be:	fcf4ede3          	bltu	s1,a5,80004498 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044c2:	4639                	li	a2,14
    800044c4:	85d2                	mv	a1,s4
    800044c6:	fc240513          	add	a0,s0,-62
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	a18080e7          	jalr	-1512(ra) # 80000ee2 <strncpy>
  de.inum = inum;
    800044d2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044d6:	4741                	li	a4,16
    800044d8:	86a6                	mv	a3,s1
    800044da:	fc040613          	add	a2,s0,-64
    800044de:	4581                	li	a1,0
    800044e0:	854a                	mv	a0,s2
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	c44080e7          	jalr	-956(ra) # 80004126 <writei>
    800044ea:	1541                	add	a0,a0,-16
    800044ec:	00a03533          	snez	a0,a0
    800044f0:	40a00533          	neg	a0,a0
}
    800044f4:	70e2                	ld	ra,56(sp)
    800044f6:	7442                	ld	s0,48(sp)
    800044f8:	74a2                	ld	s1,40(sp)
    800044fa:	7902                	ld	s2,32(sp)
    800044fc:	69e2                	ld	s3,24(sp)
    800044fe:	6a42                	ld	s4,16(sp)
    80004500:	6121                	add	sp,sp,64
    80004502:	8082                	ret
    iput(ip);
    80004504:	00000097          	auipc	ra,0x0
    80004508:	a30080e7          	jalr	-1488(ra) # 80003f34 <iput>
    return -1;
    8000450c:	557d                	li	a0,-1
    8000450e:	b7dd                	j	800044f4 <dirlink+0x86>
      panic("dirlink read");
    80004510:	00004517          	auipc	a0,0x4
    80004514:	13050513          	add	a0,a0,304 # 80008640 <syscalls+0x1e0>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	024080e7          	jalr	36(ra) # 8000053c <panic>

0000000080004520 <namei>:

struct inode*
namei(char *path)
{
    80004520:	1101                	add	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004528:	fe040613          	add	a2,s0,-32
    8000452c:	4581                	li	a1,0
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	de0080e7          	jalr	-544(ra) # 8000430e <namex>
}
    80004536:	60e2                	ld	ra,24(sp)
    80004538:	6442                	ld	s0,16(sp)
    8000453a:	6105                	add	sp,sp,32
    8000453c:	8082                	ret

000000008000453e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000453e:	1141                	add	sp,sp,-16
    80004540:	e406                	sd	ra,8(sp)
    80004542:	e022                	sd	s0,0(sp)
    80004544:	0800                	add	s0,sp,16
    80004546:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004548:	4585                	li	a1,1
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	dc4080e7          	jalr	-572(ra) # 8000430e <namex>
}
    80004552:	60a2                	ld	ra,8(sp)
    80004554:	6402                	ld	s0,0(sp)
    80004556:	0141                	add	sp,sp,16
    80004558:	8082                	ret

000000008000455a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000455a:	1101                	add	sp,sp,-32
    8000455c:	ec06                	sd	ra,24(sp)
    8000455e:	e822                	sd	s0,16(sp)
    80004560:	e426                	sd	s1,8(sp)
    80004562:	e04a                	sd	s2,0(sp)
    80004564:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004566:	0023d917          	auipc	s2,0x23d
    8000456a:	1e290913          	add	s2,s2,482 # 80241748 <log>
    8000456e:	01892583          	lw	a1,24(s2)
    80004572:	02892503          	lw	a0,40(s2)
    80004576:	fffff097          	auipc	ra,0xfffff
    8000457a:	ff4080e7          	jalr	-12(ra) # 8000356a <bread>
    8000457e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004580:	02c92603          	lw	a2,44(s2)
    80004584:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004586:	00c05f63          	blez	a2,800045a4 <write_head+0x4a>
    8000458a:	0023d717          	auipc	a4,0x23d
    8000458e:	1ee70713          	add	a4,a4,494 # 80241778 <log+0x30>
    80004592:	87aa                	mv	a5,a0
    80004594:	060a                	sll	a2,a2,0x2
    80004596:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004598:	4314                	lw	a3,0(a4)
    8000459a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000459c:	0711                	add	a4,a4,4
    8000459e:	0791                	add	a5,a5,4
    800045a0:	fec79ce3          	bne	a5,a2,80004598 <write_head+0x3e>
  }
  bwrite(buf);
    800045a4:	8526                	mv	a0,s1
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	0b6080e7          	jalr	182(ra) # 8000365c <bwrite>
  brelse(buf);
    800045ae:	8526                	mv	a0,s1
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	0ea080e7          	jalr	234(ra) # 8000369a <brelse>
}
    800045b8:	60e2                	ld	ra,24(sp)
    800045ba:	6442                	ld	s0,16(sp)
    800045bc:	64a2                	ld	s1,8(sp)
    800045be:	6902                	ld	s2,0(sp)
    800045c0:	6105                	add	sp,sp,32
    800045c2:	8082                	ret

00000000800045c4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c4:	0023d797          	auipc	a5,0x23d
    800045c8:	1b07a783          	lw	a5,432(a5) # 80241774 <log+0x2c>
    800045cc:	0af05d63          	blez	a5,80004686 <install_trans+0xc2>
{
    800045d0:	7139                	add	sp,sp,-64
    800045d2:	fc06                	sd	ra,56(sp)
    800045d4:	f822                	sd	s0,48(sp)
    800045d6:	f426                	sd	s1,40(sp)
    800045d8:	f04a                	sd	s2,32(sp)
    800045da:	ec4e                	sd	s3,24(sp)
    800045dc:	e852                	sd	s4,16(sp)
    800045de:	e456                	sd	s5,8(sp)
    800045e0:	e05a                	sd	s6,0(sp)
    800045e2:	0080                	add	s0,sp,64
    800045e4:	8b2a                	mv	s6,a0
    800045e6:	0023da97          	auipc	s5,0x23d
    800045ea:	192a8a93          	add	s5,s5,402 # 80241778 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ee:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045f0:	0023d997          	auipc	s3,0x23d
    800045f4:	15898993          	add	s3,s3,344 # 80241748 <log>
    800045f8:	a00d                	j	8000461a <install_trans+0x56>
    brelse(lbuf);
    800045fa:	854a                	mv	a0,s2
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	09e080e7          	jalr	158(ra) # 8000369a <brelse>
    brelse(dbuf);
    80004604:	8526                	mv	a0,s1
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	094080e7          	jalr	148(ra) # 8000369a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000460e:	2a05                	addw	s4,s4,1
    80004610:	0a91                	add	s5,s5,4
    80004612:	02c9a783          	lw	a5,44(s3)
    80004616:	04fa5e63          	bge	s4,a5,80004672 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000461a:	0189a583          	lw	a1,24(s3)
    8000461e:	014585bb          	addw	a1,a1,s4
    80004622:	2585                	addw	a1,a1,1
    80004624:	0289a503          	lw	a0,40(s3)
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	f42080e7          	jalr	-190(ra) # 8000356a <bread>
    80004630:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004632:	000aa583          	lw	a1,0(s5)
    80004636:	0289a503          	lw	a0,40(s3)
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	f30080e7          	jalr	-208(ra) # 8000356a <bread>
    80004642:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004644:	40000613          	li	a2,1024
    80004648:	05890593          	add	a1,s2,88
    8000464c:	05850513          	add	a0,a0,88
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	7e2080e7          	jalr	2018(ra) # 80000e32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004658:	8526                	mv	a0,s1
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	002080e7          	jalr	2(ra) # 8000365c <bwrite>
    if(recovering == 0)
    80004662:	f80b1ce3          	bnez	s6,800045fa <install_trans+0x36>
      bunpin(dbuf);
    80004666:	8526                	mv	a0,s1
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	10a080e7          	jalr	266(ra) # 80003772 <bunpin>
    80004670:	b769                	j	800045fa <install_trans+0x36>
}
    80004672:	70e2                	ld	ra,56(sp)
    80004674:	7442                	ld	s0,48(sp)
    80004676:	74a2                	ld	s1,40(sp)
    80004678:	7902                	ld	s2,32(sp)
    8000467a:	69e2                	ld	s3,24(sp)
    8000467c:	6a42                	ld	s4,16(sp)
    8000467e:	6aa2                	ld	s5,8(sp)
    80004680:	6b02                	ld	s6,0(sp)
    80004682:	6121                	add	sp,sp,64
    80004684:	8082                	ret
    80004686:	8082                	ret

0000000080004688 <initlog>:
{
    80004688:	7179                	add	sp,sp,-48
    8000468a:	f406                	sd	ra,40(sp)
    8000468c:	f022                	sd	s0,32(sp)
    8000468e:	ec26                	sd	s1,24(sp)
    80004690:	e84a                	sd	s2,16(sp)
    80004692:	e44e                	sd	s3,8(sp)
    80004694:	1800                	add	s0,sp,48
    80004696:	892a                	mv	s2,a0
    80004698:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000469a:	0023d497          	auipc	s1,0x23d
    8000469e:	0ae48493          	add	s1,s1,174 # 80241748 <log>
    800046a2:	00004597          	auipc	a1,0x4
    800046a6:	fae58593          	add	a1,a1,-82 # 80008650 <syscalls+0x1f0>
    800046aa:	8526                	mv	a0,s1
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	59e080e7          	jalr	1438(ra) # 80000c4a <initlock>
  log.start = sb->logstart;
    800046b4:	0149a583          	lw	a1,20(s3)
    800046b8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046ba:	0109a783          	lw	a5,16(s3)
    800046be:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046c0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046c4:	854a                	mv	a0,s2
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	ea4080e7          	jalr	-348(ra) # 8000356a <bread>
  log.lh.n = lh->n;
    800046ce:	4d30                	lw	a2,88(a0)
    800046d0:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046d2:	00c05f63          	blez	a2,800046f0 <initlog+0x68>
    800046d6:	87aa                	mv	a5,a0
    800046d8:	0023d717          	auipc	a4,0x23d
    800046dc:	0a070713          	add	a4,a4,160 # 80241778 <log+0x30>
    800046e0:	060a                	sll	a2,a2,0x2
    800046e2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800046e4:	4ff4                	lw	a3,92(a5)
    800046e6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046e8:	0791                	add	a5,a5,4
    800046ea:	0711                	add	a4,a4,4
    800046ec:	fec79ce3          	bne	a5,a2,800046e4 <initlog+0x5c>
  brelse(buf);
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	faa080e7          	jalr	-86(ra) # 8000369a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046f8:	4505                	li	a0,1
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	eca080e7          	jalr	-310(ra) # 800045c4 <install_trans>
  log.lh.n = 0;
    80004702:	0023d797          	auipc	a5,0x23d
    80004706:	0607a923          	sw	zero,114(a5) # 80241774 <log+0x2c>
  write_head(); // clear the log
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	e50080e7          	jalr	-432(ra) # 8000455a <write_head>
}
    80004712:	70a2                	ld	ra,40(sp)
    80004714:	7402                	ld	s0,32(sp)
    80004716:	64e2                	ld	s1,24(sp)
    80004718:	6942                	ld	s2,16(sp)
    8000471a:	69a2                	ld	s3,8(sp)
    8000471c:	6145                	add	sp,sp,48
    8000471e:	8082                	ret

0000000080004720 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004720:	1101                	add	sp,sp,-32
    80004722:	ec06                	sd	ra,24(sp)
    80004724:	e822                	sd	s0,16(sp)
    80004726:	e426                	sd	s1,8(sp)
    80004728:	e04a                	sd	s2,0(sp)
    8000472a:	1000                	add	s0,sp,32
  acquire(&log.lock);
    8000472c:	0023d517          	auipc	a0,0x23d
    80004730:	01c50513          	add	a0,a0,28 # 80241748 <log>
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	5a6080e7          	jalr	1446(ra) # 80000cda <acquire>
  while(1){
    if(log.committing){
    8000473c:	0023d497          	auipc	s1,0x23d
    80004740:	00c48493          	add	s1,s1,12 # 80241748 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004744:	4979                	li	s2,30
    80004746:	a039                	j	80004754 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004748:	85a6                	mv	a1,s1
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffe097          	auipc	ra,0xffffe
    80004750:	c84080e7          	jalr	-892(ra) # 800023d0 <sleep>
    if(log.committing){
    80004754:	50dc                	lw	a5,36(s1)
    80004756:	fbed                	bnez	a5,80004748 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004758:	5098                	lw	a4,32(s1)
    8000475a:	2705                	addw	a4,a4,1
    8000475c:	0027179b          	sllw	a5,a4,0x2
    80004760:	9fb9                	addw	a5,a5,a4
    80004762:	0017979b          	sllw	a5,a5,0x1
    80004766:	54d4                	lw	a3,44(s1)
    80004768:	9fb5                	addw	a5,a5,a3
    8000476a:	00f95963          	bge	s2,a5,8000477c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000476e:	85a6                	mv	a1,s1
    80004770:	8526                	mv	a0,s1
    80004772:	ffffe097          	auipc	ra,0xffffe
    80004776:	c5e080e7          	jalr	-930(ra) # 800023d0 <sleep>
    8000477a:	bfe9                	j	80004754 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000477c:	0023d517          	auipc	a0,0x23d
    80004780:	fcc50513          	add	a0,a0,-52 # 80241748 <log>
    80004784:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	608080e7          	jalr	1544(ra) # 80000d8e <release>
      break;
    }
  }
}
    8000478e:	60e2                	ld	ra,24(sp)
    80004790:	6442                	ld	s0,16(sp)
    80004792:	64a2                	ld	s1,8(sp)
    80004794:	6902                	ld	s2,0(sp)
    80004796:	6105                	add	sp,sp,32
    80004798:	8082                	ret

000000008000479a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000479a:	7139                	add	sp,sp,-64
    8000479c:	fc06                	sd	ra,56(sp)
    8000479e:	f822                	sd	s0,48(sp)
    800047a0:	f426                	sd	s1,40(sp)
    800047a2:	f04a                	sd	s2,32(sp)
    800047a4:	ec4e                	sd	s3,24(sp)
    800047a6:	e852                	sd	s4,16(sp)
    800047a8:	e456                	sd	s5,8(sp)
    800047aa:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047ac:	0023d497          	auipc	s1,0x23d
    800047b0:	f9c48493          	add	s1,s1,-100 # 80241748 <log>
    800047b4:	8526                	mv	a0,s1
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	524080e7          	jalr	1316(ra) # 80000cda <acquire>
  log.outstanding -= 1;
    800047be:	509c                	lw	a5,32(s1)
    800047c0:	37fd                	addw	a5,a5,-1
    800047c2:	0007891b          	sext.w	s2,a5
    800047c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047c8:	50dc                	lw	a5,36(s1)
    800047ca:	e7b9                	bnez	a5,80004818 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047cc:	04091e63          	bnez	s2,80004828 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047d0:	0023d497          	auipc	s1,0x23d
    800047d4:	f7848493          	add	s1,s1,-136 # 80241748 <log>
    800047d8:	4785                	li	a5,1
    800047da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047dc:	8526                	mv	a0,s1
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	5b0080e7          	jalr	1456(ra) # 80000d8e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047e6:	54dc                	lw	a5,44(s1)
    800047e8:	06f04763          	bgtz	a5,80004856 <end_op+0xbc>
    acquire(&log.lock);
    800047ec:	0023d497          	auipc	s1,0x23d
    800047f0:	f5c48493          	add	s1,s1,-164 # 80241748 <log>
    800047f4:	8526                	mv	a0,s1
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4e4080e7          	jalr	1252(ra) # 80000cda <acquire>
    log.committing = 0;
    800047fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004802:	8526                	mv	a0,s1
    80004804:	ffffe097          	auipc	ra,0xffffe
    80004808:	c30080e7          	jalr	-976(ra) # 80002434 <wakeup>
    release(&log.lock);
    8000480c:	8526                	mv	a0,s1
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	580080e7          	jalr	1408(ra) # 80000d8e <release>
}
    80004816:	a03d                	j	80004844 <end_op+0xaa>
    panic("log.committing");
    80004818:	00004517          	auipc	a0,0x4
    8000481c:	e4050513          	add	a0,a0,-448 # 80008658 <syscalls+0x1f8>
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	d1c080e7          	jalr	-740(ra) # 8000053c <panic>
    wakeup(&log);
    80004828:	0023d497          	auipc	s1,0x23d
    8000482c:	f2048493          	add	s1,s1,-224 # 80241748 <log>
    80004830:	8526                	mv	a0,s1
    80004832:	ffffe097          	auipc	ra,0xffffe
    80004836:	c02080e7          	jalr	-1022(ra) # 80002434 <wakeup>
  release(&log.lock);
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	552080e7          	jalr	1362(ra) # 80000d8e <release>
}
    80004844:	70e2                	ld	ra,56(sp)
    80004846:	7442                	ld	s0,48(sp)
    80004848:	74a2                	ld	s1,40(sp)
    8000484a:	7902                	ld	s2,32(sp)
    8000484c:	69e2                	ld	s3,24(sp)
    8000484e:	6a42                	ld	s4,16(sp)
    80004850:	6aa2                	ld	s5,8(sp)
    80004852:	6121                	add	sp,sp,64
    80004854:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004856:	0023da97          	auipc	s5,0x23d
    8000485a:	f22a8a93          	add	s5,s5,-222 # 80241778 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000485e:	0023da17          	auipc	s4,0x23d
    80004862:	eeaa0a13          	add	s4,s4,-278 # 80241748 <log>
    80004866:	018a2583          	lw	a1,24(s4)
    8000486a:	012585bb          	addw	a1,a1,s2
    8000486e:	2585                	addw	a1,a1,1
    80004870:	028a2503          	lw	a0,40(s4)
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	cf6080e7          	jalr	-778(ra) # 8000356a <bread>
    8000487c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000487e:	000aa583          	lw	a1,0(s5)
    80004882:	028a2503          	lw	a0,40(s4)
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	ce4080e7          	jalr	-796(ra) # 8000356a <bread>
    8000488e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004890:	40000613          	li	a2,1024
    80004894:	05850593          	add	a1,a0,88
    80004898:	05848513          	add	a0,s1,88
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	596080e7          	jalr	1430(ra) # 80000e32 <memmove>
    bwrite(to);  // write the log
    800048a4:	8526                	mv	a0,s1
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	db6080e7          	jalr	-586(ra) # 8000365c <bwrite>
    brelse(from);
    800048ae:	854e                	mv	a0,s3
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	dea080e7          	jalr	-534(ra) # 8000369a <brelse>
    brelse(to);
    800048b8:	8526                	mv	a0,s1
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	de0080e7          	jalr	-544(ra) # 8000369a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048c2:	2905                	addw	s2,s2,1
    800048c4:	0a91                	add	s5,s5,4
    800048c6:	02ca2783          	lw	a5,44(s4)
    800048ca:	f8f94ee3          	blt	s2,a5,80004866 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	c8c080e7          	jalr	-884(ra) # 8000455a <write_head>
    install_trans(0); // Now install writes to home locations
    800048d6:	4501                	li	a0,0
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	cec080e7          	jalr	-788(ra) # 800045c4 <install_trans>
    log.lh.n = 0;
    800048e0:	0023d797          	auipc	a5,0x23d
    800048e4:	e807aa23          	sw	zero,-364(a5) # 80241774 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	c72080e7          	jalr	-910(ra) # 8000455a <write_head>
    800048f0:	bdf5                	j	800047ec <end_op+0x52>

00000000800048f2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048f2:	1101                	add	sp,sp,-32
    800048f4:	ec06                	sd	ra,24(sp)
    800048f6:	e822                	sd	s0,16(sp)
    800048f8:	e426                	sd	s1,8(sp)
    800048fa:	e04a                	sd	s2,0(sp)
    800048fc:	1000                	add	s0,sp,32
    800048fe:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004900:	0023d917          	auipc	s2,0x23d
    80004904:	e4890913          	add	s2,s2,-440 # 80241748 <log>
    80004908:	854a                	mv	a0,s2
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	3d0080e7          	jalr	976(ra) # 80000cda <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004912:	02c92603          	lw	a2,44(s2)
    80004916:	47f5                	li	a5,29
    80004918:	06c7c563          	blt	a5,a2,80004982 <log_write+0x90>
    8000491c:	0023d797          	auipc	a5,0x23d
    80004920:	e487a783          	lw	a5,-440(a5) # 80241764 <log+0x1c>
    80004924:	37fd                	addw	a5,a5,-1
    80004926:	04f65e63          	bge	a2,a5,80004982 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000492a:	0023d797          	auipc	a5,0x23d
    8000492e:	e3e7a783          	lw	a5,-450(a5) # 80241768 <log+0x20>
    80004932:	06f05063          	blez	a5,80004992 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004936:	4781                	li	a5,0
    80004938:	06c05563          	blez	a2,800049a2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000493c:	44cc                	lw	a1,12(s1)
    8000493e:	0023d717          	auipc	a4,0x23d
    80004942:	e3a70713          	add	a4,a4,-454 # 80241778 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004946:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004948:	4314                	lw	a3,0(a4)
    8000494a:	04b68c63          	beq	a3,a1,800049a2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000494e:	2785                	addw	a5,a5,1
    80004950:	0711                	add	a4,a4,4
    80004952:	fef61be3          	bne	a2,a5,80004948 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004956:	0621                	add	a2,a2,8
    80004958:	060a                	sll	a2,a2,0x2
    8000495a:	0023d797          	auipc	a5,0x23d
    8000495e:	dee78793          	add	a5,a5,-530 # 80241748 <log>
    80004962:	97b2                	add	a5,a5,a2
    80004964:	44d8                	lw	a4,12(s1)
    80004966:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004968:	8526                	mv	a0,s1
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	dcc080e7          	jalr	-564(ra) # 80003736 <bpin>
    log.lh.n++;
    80004972:	0023d717          	auipc	a4,0x23d
    80004976:	dd670713          	add	a4,a4,-554 # 80241748 <log>
    8000497a:	575c                	lw	a5,44(a4)
    8000497c:	2785                	addw	a5,a5,1
    8000497e:	d75c                	sw	a5,44(a4)
    80004980:	a82d                	j	800049ba <log_write+0xc8>
    panic("too big a transaction");
    80004982:	00004517          	auipc	a0,0x4
    80004986:	ce650513          	add	a0,a0,-794 # 80008668 <syscalls+0x208>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	bb2080e7          	jalr	-1102(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004992:	00004517          	auipc	a0,0x4
    80004996:	cee50513          	add	a0,a0,-786 # 80008680 <syscalls+0x220>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	ba2080e7          	jalr	-1118(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800049a2:	00878693          	add	a3,a5,8
    800049a6:	068a                	sll	a3,a3,0x2
    800049a8:	0023d717          	auipc	a4,0x23d
    800049ac:	da070713          	add	a4,a4,-608 # 80241748 <log>
    800049b0:	9736                	add	a4,a4,a3
    800049b2:	44d4                	lw	a3,12(s1)
    800049b4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049b6:	faf609e3          	beq	a2,a5,80004968 <log_write+0x76>
  }
  release(&log.lock);
    800049ba:	0023d517          	auipc	a0,0x23d
    800049be:	d8e50513          	add	a0,a0,-626 # 80241748 <log>
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	3cc080e7          	jalr	972(ra) # 80000d8e <release>
}
    800049ca:	60e2                	ld	ra,24(sp)
    800049cc:	6442                	ld	s0,16(sp)
    800049ce:	64a2                	ld	s1,8(sp)
    800049d0:	6902                	ld	s2,0(sp)
    800049d2:	6105                	add	sp,sp,32
    800049d4:	8082                	ret

00000000800049d6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049d6:	1101                	add	sp,sp,-32
    800049d8:	ec06                	sd	ra,24(sp)
    800049da:	e822                	sd	s0,16(sp)
    800049dc:	e426                	sd	s1,8(sp)
    800049de:	e04a                	sd	s2,0(sp)
    800049e0:	1000                	add	s0,sp,32
    800049e2:	84aa                	mv	s1,a0
    800049e4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049e6:	00004597          	auipc	a1,0x4
    800049ea:	cba58593          	add	a1,a1,-838 # 800086a0 <syscalls+0x240>
    800049ee:	0521                	add	a0,a0,8
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	25a080e7          	jalr	602(ra) # 80000c4a <initlock>
  lk->name = name;
    800049f8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a00:	0204a423          	sw	zero,40(s1)
}
    80004a04:	60e2                	ld	ra,24(sp)
    80004a06:	6442                	ld	s0,16(sp)
    80004a08:	64a2                	ld	s1,8(sp)
    80004a0a:	6902                	ld	s2,0(sp)
    80004a0c:	6105                	add	sp,sp,32
    80004a0e:	8082                	ret

0000000080004a10 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a10:	1101                	add	sp,sp,-32
    80004a12:	ec06                	sd	ra,24(sp)
    80004a14:	e822                	sd	s0,16(sp)
    80004a16:	e426                	sd	s1,8(sp)
    80004a18:	e04a                	sd	s2,0(sp)
    80004a1a:	1000                	add	s0,sp,32
    80004a1c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a1e:	00850913          	add	s2,a0,8
    80004a22:	854a                	mv	a0,s2
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	2b6080e7          	jalr	694(ra) # 80000cda <acquire>
  while (lk->locked) {
    80004a2c:	409c                	lw	a5,0(s1)
    80004a2e:	cb89                	beqz	a5,80004a40 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a30:	85ca                	mv	a1,s2
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffe097          	auipc	ra,0xffffe
    80004a38:	99c080e7          	jalr	-1636(ra) # 800023d0 <sleep>
  while (lk->locked) {
    80004a3c:	409c                	lw	a5,0(s1)
    80004a3e:	fbed                	bnez	a5,80004a30 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a40:	4785                	li	a5,1
    80004a42:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a44:	ffffd097          	auipc	ra,0xffffd
    80004a48:	0d0080e7          	jalr	208(ra) # 80001b14 <myproc>
    80004a4c:	591c                	lw	a5,48(a0)
    80004a4e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a50:	854a                	mv	a0,s2
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	33c080e7          	jalr	828(ra) # 80000d8e <release>
}
    80004a5a:	60e2                	ld	ra,24(sp)
    80004a5c:	6442                	ld	s0,16(sp)
    80004a5e:	64a2                	ld	s1,8(sp)
    80004a60:	6902                	ld	s2,0(sp)
    80004a62:	6105                	add	sp,sp,32
    80004a64:	8082                	ret

0000000080004a66 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a66:	1101                	add	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	e04a                	sd	s2,0(sp)
    80004a70:	1000                	add	s0,sp,32
    80004a72:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a74:	00850913          	add	s2,a0,8
    80004a78:	854a                	mv	a0,s2
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	260080e7          	jalr	608(ra) # 80000cda <acquire>
  lk->locked = 0;
    80004a82:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a86:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffe097          	auipc	ra,0xffffe
    80004a90:	9a8080e7          	jalr	-1624(ra) # 80002434 <wakeup>
  release(&lk->lk);
    80004a94:	854a                	mv	a0,s2
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	2f8080e7          	jalr	760(ra) # 80000d8e <release>
}
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6902                	ld	s2,0(sp)
    80004aa6:	6105                	add	sp,sp,32
    80004aa8:	8082                	ret

0000000080004aaa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004aaa:	7179                	add	sp,sp,-48
    80004aac:	f406                	sd	ra,40(sp)
    80004aae:	f022                	sd	s0,32(sp)
    80004ab0:	ec26                	sd	s1,24(sp)
    80004ab2:	e84a                	sd	s2,16(sp)
    80004ab4:	e44e                	sd	s3,8(sp)
    80004ab6:	1800                	add	s0,sp,48
    80004ab8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004aba:	00850913          	add	s2,a0,8
    80004abe:	854a                	mv	a0,s2
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	21a080e7          	jalr	538(ra) # 80000cda <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ac8:	409c                	lw	a5,0(s1)
    80004aca:	ef99                	bnez	a5,80004ae8 <holdingsleep+0x3e>
    80004acc:	4481                	li	s1,0
  release(&lk->lk);
    80004ace:	854a                	mv	a0,s2
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	2be080e7          	jalr	702(ra) # 80000d8e <release>
  return r;
}
    80004ad8:	8526                	mv	a0,s1
    80004ada:	70a2                	ld	ra,40(sp)
    80004adc:	7402                	ld	s0,32(sp)
    80004ade:	64e2                	ld	s1,24(sp)
    80004ae0:	6942                	ld	s2,16(sp)
    80004ae2:	69a2                	ld	s3,8(sp)
    80004ae4:	6145                	add	sp,sp,48
    80004ae6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ae8:	0284a983          	lw	s3,40(s1)
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	028080e7          	jalr	40(ra) # 80001b14 <myproc>
    80004af4:	5904                	lw	s1,48(a0)
    80004af6:	413484b3          	sub	s1,s1,s3
    80004afa:	0014b493          	seqz	s1,s1
    80004afe:	bfc1                	j	80004ace <holdingsleep+0x24>

0000000080004b00 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b00:	1141                	add	sp,sp,-16
    80004b02:	e406                	sd	ra,8(sp)
    80004b04:	e022                	sd	s0,0(sp)
    80004b06:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b08:	00004597          	auipc	a1,0x4
    80004b0c:	ba858593          	add	a1,a1,-1112 # 800086b0 <syscalls+0x250>
    80004b10:	0023d517          	auipc	a0,0x23d
    80004b14:	d8050513          	add	a0,a0,-640 # 80241890 <ftable>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	132080e7          	jalr	306(ra) # 80000c4a <initlock>
}
    80004b20:	60a2                	ld	ra,8(sp)
    80004b22:	6402                	ld	s0,0(sp)
    80004b24:	0141                	add	sp,sp,16
    80004b26:	8082                	ret

0000000080004b28 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b28:	1101                	add	sp,sp,-32
    80004b2a:	ec06                	sd	ra,24(sp)
    80004b2c:	e822                	sd	s0,16(sp)
    80004b2e:	e426                	sd	s1,8(sp)
    80004b30:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b32:	0023d517          	auipc	a0,0x23d
    80004b36:	d5e50513          	add	a0,a0,-674 # 80241890 <ftable>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	1a0080e7          	jalr	416(ra) # 80000cda <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b42:	0023d497          	auipc	s1,0x23d
    80004b46:	d6648493          	add	s1,s1,-666 # 802418a8 <ftable+0x18>
    80004b4a:	0023e717          	auipc	a4,0x23e
    80004b4e:	cfe70713          	add	a4,a4,-770 # 80242848 <disk>
    if(f->ref == 0){
    80004b52:	40dc                	lw	a5,4(s1)
    80004b54:	cf99                	beqz	a5,80004b72 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b56:	02848493          	add	s1,s1,40
    80004b5a:	fee49ce3          	bne	s1,a4,80004b52 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b5e:	0023d517          	auipc	a0,0x23d
    80004b62:	d3250513          	add	a0,a0,-718 # 80241890 <ftable>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	228080e7          	jalr	552(ra) # 80000d8e <release>
  return 0;
    80004b6e:	4481                	li	s1,0
    80004b70:	a819                	j	80004b86 <filealloc+0x5e>
      f->ref = 1;
    80004b72:	4785                	li	a5,1
    80004b74:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b76:	0023d517          	auipc	a0,0x23d
    80004b7a:	d1a50513          	add	a0,a0,-742 # 80241890 <ftable>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	210080e7          	jalr	528(ra) # 80000d8e <release>
}
    80004b86:	8526                	mv	a0,s1
    80004b88:	60e2                	ld	ra,24(sp)
    80004b8a:	6442                	ld	s0,16(sp)
    80004b8c:	64a2                	ld	s1,8(sp)
    80004b8e:	6105                	add	sp,sp,32
    80004b90:	8082                	ret

0000000080004b92 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b92:	1101                	add	sp,sp,-32
    80004b94:	ec06                	sd	ra,24(sp)
    80004b96:	e822                	sd	s0,16(sp)
    80004b98:	e426                	sd	s1,8(sp)
    80004b9a:	1000                	add	s0,sp,32
    80004b9c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b9e:	0023d517          	auipc	a0,0x23d
    80004ba2:	cf250513          	add	a0,a0,-782 # 80241890 <ftable>
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	134080e7          	jalr	308(ra) # 80000cda <acquire>
  if(f->ref < 1)
    80004bae:	40dc                	lw	a5,4(s1)
    80004bb0:	02f05263          	blez	a5,80004bd4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bb4:	2785                	addw	a5,a5,1
    80004bb6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bb8:	0023d517          	auipc	a0,0x23d
    80004bbc:	cd850513          	add	a0,a0,-808 # 80241890 <ftable>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	1ce080e7          	jalr	462(ra) # 80000d8e <release>
  return f;
}
    80004bc8:	8526                	mv	a0,s1
    80004bca:	60e2                	ld	ra,24(sp)
    80004bcc:	6442                	ld	s0,16(sp)
    80004bce:	64a2                	ld	s1,8(sp)
    80004bd0:	6105                	add	sp,sp,32
    80004bd2:	8082                	ret
    panic("filedup");
    80004bd4:	00004517          	auipc	a0,0x4
    80004bd8:	ae450513          	add	a0,a0,-1308 # 800086b8 <syscalls+0x258>
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	960080e7          	jalr	-1696(ra) # 8000053c <panic>

0000000080004be4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004be4:	7139                	add	sp,sp,-64
    80004be6:	fc06                	sd	ra,56(sp)
    80004be8:	f822                	sd	s0,48(sp)
    80004bea:	f426                	sd	s1,40(sp)
    80004bec:	f04a                	sd	s2,32(sp)
    80004bee:	ec4e                	sd	s3,24(sp)
    80004bf0:	e852                	sd	s4,16(sp)
    80004bf2:	e456                	sd	s5,8(sp)
    80004bf4:	0080                	add	s0,sp,64
    80004bf6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bf8:	0023d517          	auipc	a0,0x23d
    80004bfc:	c9850513          	add	a0,a0,-872 # 80241890 <ftable>
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	0da080e7          	jalr	218(ra) # 80000cda <acquire>
  if(f->ref < 1)
    80004c08:	40dc                	lw	a5,4(s1)
    80004c0a:	06f05163          	blez	a5,80004c6c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c0e:	37fd                	addw	a5,a5,-1
    80004c10:	0007871b          	sext.w	a4,a5
    80004c14:	c0dc                	sw	a5,4(s1)
    80004c16:	06e04363          	bgtz	a4,80004c7c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c1a:	0004a903          	lw	s2,0(s1)
    80004c1e:	0094ca83          	lbu	s5,9(s1)
    80004c22:	0104ba03          	ld	s4,16(s1)
    80004c26:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c2a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c2e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c32:	0023d517          	auipc	a0,0x23d
    80004c36:	c5e50513          	add	a0,a0,-930 # 80241890 <ftable>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	154080e7          	jalr	340(ra) # 80000d8e <release>

  if(ff.type == FD_PIPE){
    80004c42:	4785                	li	a5,1
    80004c44:	04f90d63          	beq	s2,a5,80004c9e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c48:	3979                	addw	s2,s2,-2
    80004c4a:	4785                	li	a5,1
    80004c4c:	0527e063          	bltu	a5,s2,80004c8c <fileclose+0xa8>
    begin_op();
    80004c50:	00000097          	auipc	ra,0x0
    80004c54:	ad0080e7          	jalr	-1328(ra) # 80004720 <begin_op>
    iput(ff.ip);
    80004c58:	854e                	mv	a0,s3
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	2da080e7          	jalr	730(ra) # 80003f34 <iput>
    end_op();
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	b38080e7          	jalr	-1224(ra) # 8000479a <end_op>
    80004c6a:	a00d                	j	80004c8c <fileclose+0xa8>
    panic("fileclose");
    80004c6c:	00004517          	auipc	a0,0x4
    80004c70:	a5450513          	add	a0,a0,-1452 # 800086c0 <syscalls+0x260>
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	8c8080e7          	jalr	-1848(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004c7c:	0023d517          	auipc	a0,0x23d
    80004c80:	c1450513          	add	a0,a0,-1004 # 80241890 <ftable>
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	10a080e7          	jalr	266(ra) # 80000d8e <release>
  }
}
    80004c8c:	70e2                	ld	ra,56(sp)
    80004c8e:	7442                	ld	s0,48(sp)
    80004c90:	74a2                	ld	s1,40(sp)
    80004c92:	7902                	ld	s2,32(sp)
    80004c94:	69e2                	ld	s3,24(sp)
    80004c96:	6a42                	ld	s4,16(sp)
    80004c98:	6aa2                	ld	s5,8(sp)
    80004c9a:	6121                	add	sp,sp,64
    80004c9c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c9e:	85d6                	mv	a1,s5
    80004ca0:	8552                	mv	a0,s4
    80004ca2:	00000097          	auipc	ra,0x0
    80004ca6:	348080e7          	jalr	840(ra) # 80004fea <pipeclose>
    80004caa:	b7cd                	j	80004c8c <fileclose+0xa8>

0000000080004cac <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004cac:	715d                	add	sp,sp,-80
    80004cae:	e486                	sd	ra,72(sp)
    80004cb0:	e0a2                	sd	s0,64(sp)
    80004cb2:	fc26                	sd	s1,56(sp)
    80004cb4:	f84a                	sd	s2,48(sp)
    80004cb6:	f44e                	sd	s3,40(sp)
    80004cb8:	0880                	add	s0,sp,80
    80004cba:	84aa                	mv	s1,a0
    80004cbc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	e56080e7          	jalr	-426(ra) # 80001b14 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cc6:	409c                	lw	a5,0(s1)
    80004cc8:	37f9                	addw	a5,a5,-2
    80004cca:	4705                	li	a4,1
    80004ccc:	04f76763          	bltu	a4,a5,80004d1a <filestat+0x6e>
    80004cd0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cd2:	6c88                	ld	a0,24(s1)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	0a6080e7          	jalr	166(ra) # 80003d7a <ilock>
    stati(f->ip, &st);
    80004cdc:	fb840593          	add	a1,s0,-72
    80004ce0:	6c88                	ld	a0,24(s1)
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	322080e7          	jalr	802(ra) # 80004004 <stati>
    iunlock(f->ip);
    80004cea:	6c88                	ld	a0,24(s1)
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	150080e7          	jalr	336(ra) # 80003e3c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cf4:	46e1                	li	a3,24
    80004cf6:	fb840613          	add	a2,s0,-72
    80004cfa:	85ce                	mv	a1,s3
    80004cfc:	05093503          	ld	a0,80(s2)
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	a9c080e7          	jalr	-1380(ra) # 8000179c <copyout>
    80004d08:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d0c:	60a6                	ld	ra,72(sp)
    80004d0e:	6406                	ld	s0,64(sp)
    80004d10:	74e2                	ld	s1,56(sp)
    80004d12:	7942                	ld	s2,48(sp)
    80004d14:	79a2                	ld	s3,40(sp)
    80004d16:	6161                	add	sp,sp,80
    80004d18:	8082                	ret
  return -1;
    80004d1a:	557d                	li	a0,-1
    80004d1c:	bfc5                	j	80004d0c <filestat+0x60>

0000000080004d1e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d1e:	7179                	add	sp,sp,-48
    80004d20:	f406                	sd	ra,40(sp)
    80004d22:	f022                	sd	s0,32(sp)
    80004d24:	ec26                	sd	s1,24(sp)
    80004d26:	e84a                	sd	s2,16(sp)
    80004d28:	e44e                	sd	s3,8(sp)
    80004d2a:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d2c:	00854783          	lbu	a5,8(a0)
    80004d30:	c3d5                	beqz	a5,80004dd4 <fileread+0xb6>
    80004d32:	84aa                	mv	s1,a0
    80004d34:	89ae                	mv	s3,a1
    80004d36:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d38:	411c                	lw	a5,0(a0)
    80004d3a:	4705                	li	a4,1
    80004d3c:	04e78963          	beq	a5,a4,80004d8e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d40:	470d                	li	a4,3
    80004d42:	04e78d63          	beq	a5,a4,80004d9c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d46:	4709                	li	a4,2
    80004d48:	06e79e63          	bne	a5,a4,80004dc4 <fileread+0xa6>
    ilock(f->ip);
    80004d4c:	6d08                	ld	a0,24(a0)
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	02c080e7          	jalr	44(ra) # 80003d7a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d56:	874a                	mv	a4,s2
    80004d58:	5094                	lw	a3,32(s1)
    80004d5a:	864e                	mv	a2,s3
    80004d5c:	4585                	li	a1,1
    80004d5e:	6c88                	ld	a0,24(s1)
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	2ce080e7          	jalr	718(ra) # 8000402e <readi>
    80004d68:	892a                	mv	s2,a0
    80004d6a:	00a05563          	blez	a0,80004d74 <fileread+0x56>
      f->off += r;
    80004d6e:	509c                	lw	a5,32(s1)
    80004d70:	9fa9                	addw	a5,a5,a0
    80004d72:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d74:	6c88                	ld	a0,24(s1)
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	0c6080e7          	jalr	198(ra) # 80003e3c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d7e:	854a                	mv	a0,s2
    80004d80:	70a2                	ld	ra,40(sp)
    80004d82:	7402                	ld	s0,32(sp)
    80004d84:	64e2                	ld	s1,24(sp)
    80004d86:	6942                	ld	s2,16(sp)
    80004d88:	69a2                	ld	s3,8(sp)
    80004d8a:	6145                	add	sp,sp,48
    80004d8c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d8e:	6908                	ld	a0,16(a0)
    80004d90:	00000097          	auipc	ra,0x0
    80004d94:	3c2080e7          	jalr	962(ra) # 80005152 <piperead>
    80004d98:	892a                	mv	s2,a0
    80004d9a:	b7d5                	j	80004d7e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d9c:	02451783          	lh	a5,36(a0)
    80004da0:	03079693          	sll	a3,a5,0x30
    80004da4:	92c1                	srl	a3,a3,0x30
    80004da6:	4725                	li	a4,9
    80004da8:	02d76863          	bltu	a4,a3,80004dd8 <fileread+0xba>
    80004dac:	0792                	sll	a5,a5,0x4
    80004dae:	0023d717          	auipc	a4,0x23d
    80004db2:	a4270713          	add	a4,a4,-1470 # 802417f0 <devsw>
    80004db6:	97ba                	add	a5,a5,a4
    80004db8:	639c                	ld	a5,0(a5)
    80004dba:	c38d                	beqz	a5,80004ddc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004dbc:	4505                	li	a0,1
    80004dbe:	9782                	jalr	a5
    80004dc0:	892a                	mv	s2,a0
    80004dc2:	bf75                	j	80004d7e <fileread+0x60>
    panic("fileread");
    80004dc4:	00004517          	auipc	a0,0x4
    80004dc8:	90c50513          	add	a0,a0,-1780 # 800086d0 <syscalls+0x270>
    80004dcc:	ffffb097          	auipc	ra,0xffffb
    80004dd0:	770080e7          	jalr	1904(ra) # 8000053c <panic>
    return -1;
    80004dd4:	597d                	li	s2,-1
    80004dd6:	b765                	j	80004d7e <fileread+0x60>
      return -1;
    80004dd8:	597d                	li	s2,-1
    80004dda:	b755                	j	80004d7e <fileread+0x60>
    80004ddc:	597d                	li	s2,-1
    80004dde:	b745                	j	80004d7e <fileread+0x60>

0000000080004de0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004de0:	00954783          	lbu	a5,9(a0)
    80004de4:	10078e63          	beqz	a5,80004f00 <filewrite+0x120>
{
    80004de8:	715d                	add	sp,sp,-80
    80004dea:	e486                	sd	ra,72(sp)
    80004dec:	e0a2                	sd	s0,64(sp)
    80004dee:	fc26                	sd	s1,56(sp)
    80004df0:	f84a                	sd	s2,48(sp)
    80004df2:	f44e                	sd	s3,40(sp)
    80004df4:	f052                	sd	s4,32(sp)
    80004df6:	ec56                	sd	s5,24(sp)
    80004df8:	e85a                	sd	s6,16(sp)
    80004dfa:	e45e                	sd	s7,8(sp)
    80004dfc:	e062                	sd	s8,0(sp)
    80004dfe:	0880                	add	s0,sp,80
    80004e00:	892a                	mv	s2,a0
    80004e02:	8b2e                	mv	s6,a1
    80004e04:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e06:	411c                	lw	a5,0(a0)
    80004e08:	4705                	li	a4,1
    80004e0a:	02e78263          	beq	a5,a4,80004e2e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e0e:	470d                	li	a4,3
    80004e10:	02e78563          	beq	a5,a4,80004e3a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e14:	4709                	li	a4,2
    80004e16:	0ce79d63          	bne	a5,a4,80004ef0 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e1a:	0ac05b63          	blez	a2,80004ed0 <filewrite+0xf0>
    int i = 0;
    80004e1e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e20:	6b85                	lui	s7,0x1
    80004e22:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e26:	6c05                	lui	s8,0x1
    80004e28:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e2c:	a851                	j	80004ec0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e2e:	6908                	ld	a0,16(a0)
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	22a080e7          	jalr	554(ra) # 8000505a <pipewrite>
    80004e38:	a045                	j	80004ed8 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e3a:	02451783          	lh	a5,36(a0)
    80004e3e:	03079693          	sll	a3,a5,0x30
    80004e42:	92c1                	srl	a3,a3,0x30
    80004e44:	4725                	li	a4,9
    80004e46:	0ad76f63          	bltu	a4,a3,80004f04 <filewrite+0x124>
    80004e4a:	0792                	sll	a5,a5,0x4
    80004e4c:	0023d717          	auipc	a4,0x23d
    80004e50:	9a470713          	add	a4,a4,-1628 # 802417f0 <devsw>
    80004e54:	97ba                	add	a5,a5,a4
    80004e56:	679c                	ld	a5,8(a5)
    80004e58:	cbc5                	beqz	a5,80004f08 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004e5a:	4505                	li	a0,1
    80004e5c:	9782                	jalr	a5
    80004e5e:	a8ad                	j	80004ed8 <filewrite+0xf8>
      if(n1 > max)
    80004e60:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004e64:	00000097          	auipc	ra,0x0
    80004e68:	8bc080e7          	jalr	-1860(ra) # 80004720 <begin_op>
      ilock(f->ip);
    80004e6c:	01893503          	ld	a0,24(s2)
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	f0a080e7          	jalr	-246(ra) # 80003d7a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e78:	8756                	mv	a4,s5
    80004e7a:	02092683          	lw	a3,32(s2)
    80004e7e:	01698633          	add	a2,s3,s6
    80004e82:	4585                	li	a1,1
    80004e84:	01893503          	ld	a0,24(s2)
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	29e080e7          	jalr	670(ra) # 80004126 <writei>
    80004e90:	84aa                	mv	s1,a0
    80004e92:	00a05763          	blez	a0,80004ea0 <filewrite+0xc0>
        f->off += r;
    80004e96:	02092783          	lw	a5,32(s2)
    80004e9a:	9fa9                	addw	a5,a5,a0
    80004e9c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ea0:	01893503          	ld	a0,24(s2)
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	f98080e7          	jalr	-104(ra) # 80003e3c <iunlock>
      end_op();
    80004eac:	00000097          	auipc	ra,0x0
    80004eb0:	8ee080e7          	jalr	-1810(ra) # 8000479a <end_op>

      if(r != n1){
    80004eb4:	009a9f63          	bne	s5,s1,80004ed2 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004eb8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ebc:	0149db63          	bge	s3,s4,80004ed2 <filewrite+0xf2>
      int n1 = n - i;
    80004ec0:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004ec4:	0004879b          	sext.w	a5,s1
    80004ec8:	f8fbdce3          	bge	s7,a5,80004e60 <filewrite+0x80>
    80004ecc:	84e2                	mv	s1,s8
    80004ece:	bf49                	j	80004e60 <filewrite+0x80>
    int i = 0;
    80004ed0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ed2:	033a1d63          	bne	s4,s3,80004f0c <filewrite+0x12c>
    80004ed6:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ed8:	60a6                	ld	ra,72(sp)
    80004eda:	6406                	ld	s0,64(sp)
    80004edc:	74e2                	ld	s1,56(sp)
    80004ede:	7942                	ld	s2,48(sp)
    80004ee0:	79a2                	ld	s3,40(sp)
    80004ee2:	7a02                	ld	s4,32(sp)
    80004ee4:	6ae2                	ld	s5,24(sp)
    80004ee6:	6b42                	ld	s6,16(sp)
    80004ee8:	6ba2                	ld	s7,8(sp)
    80004eea:	6c02                	ld	s8,0(sp)
    80004eec:	6161                	add	sp,sp,80
    80004eee:	8082                	ret
    panic("filewrite");
    80004ef0:	00003517          	auipc	a0,0x3
    80004ef4:	7f050513          	add	a0,a0,2032 # 800086e0 <syscalls+0x280>
    80004ef8:	ffffb097          	auipc	ra,0xffffb
    80004efc:	644080e7          	jalr	1604(ra) # 8000053c <panic>
    return -1;
    80004f00:	557d                	li	a0,-1
}
    80004f02:	8082                	ret
      return -1;
    80004f04:	557d                	li	a0,-1
    80004f06:	bfc9                	j	80004ed8 <filewrite+0xf8>
    80004f08:	557d                	li	a0,-1
    80004f0a:	b7f9                	j	80004ed8 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004f0c:	557d                	li	a0,-1
    80004f0e:	b7e9                	j	80004ed8 <filewrite+0xf8>

0000000080004f10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f10:	7179                	add	sp,sp,-48
    80004f12:	f406                	sd	ra,40(sp)
    80004f14:	f022                	sd	s0,32(sp)
    80004f16:	ec26                	sd	s1,24(sp)
    80004f18:	e84a                	sd	s2,16(sp)
    80004f1a:	e44e                	sd	s3,8(sp)
    80004f1c:	e052                	sd	s4,0(sp)
    80004f1e:	1800                	add	s0,sp,48
    80004f20:	84aa                	mv	s1,a0
    80004f22:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f24:	0005b023          	sd	zero,0(a1)
    80004f28:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f2c:	00000097          	auipc	ra,0x0
    80004f30:	bfc080e7          	jalr	-1028(ra) # 80004b28 <filealloc>
    80004f34:	e088                	sd	a0,0(s1)
    80004f36:	c551                	beqz	a0,80004fc2 <pipealloc+0xb2>
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	bf0080e7          	jalr	-1040(ra) # 80004b28 <filealloc>
    80004f40:	00aa3023          	sd	a0,0(s4)
    80004f44:	c92d                	beqz	a0,80004fb6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	c68080e7          	jalr	-920(ra) # 80000bae <kalloc>
    80004f4e:	892a                	mv	s2,a0
    80004f50:	c125                	beqz	a0,80004fb0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f52:	4985                	li	s3,1
    80004f54:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f58:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f5c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f60:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f64:	00003597          	auipc	a1,0x3
    80004f68:	78c58593          	add	a1,a1,1932 # 800086f0 <syscalls+0x290>
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	cde080e7          	jalr	-802(ra) # 80000c4a <initlock>
  (*f0)->type = FD_PIPE;
    80004f74:	609c                	ld	a5,0(s1)
    80004f76:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f7a:	609c                	ld	a5,0(s1)
    80004f7c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f80:	609c                	ld	a5,0(s1)
    80004f82:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f86:	609c                	ld	a5,0(s1)
    80004f88:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f8c:	000a3783          	ld	a5,0(s4)
    80004f90:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f94:	000a3783          	ld	a5,0(s4)
    80004f98:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f9c:	000a3783          	ld	a5,0(s4)
    80004fa0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fa4:	000a3783          	ld	a5,0(s4)
    80004fa8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fac:	4501                	li	a0,0
    80004fae:	a025                	j	80004fd6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fb0:	6088                	ld	a0,0(s1)
    80004fb2:	e501                	bnez	a0,80004fba <pipealloc+0xaa>
    80004fb4:	a039                	j	80004fc2 <pipealloc+0xb2>
    80004fb6:	6088                	ld	a0,0(s1)
    80004fb8:	c51d                	beqz	a0,80004fe6 <pipealloc+0xd6>
    fileclose(*f0);
    80004fba:	00000097          	auipc	ra,0x0
    80004fbe:	c2a080e7          	jalr	-982(ra) # 80004be4 <fileclose>
  if(*f1)
    80004fc2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fc6:	557d                	li	a0,-1
  if(*f1)
    80004fc8:	c799                	beqz	a5,80004fd6 <pipealloc+0xc6>
    fileclose(*f1);
    80004fca:	853e                	mv	a0,a5
    80004fcc:	00000097          	auipc	ra,0x0
    80004fd0:	c18080e7          	jalr	-1000(ra) # 80004be4 <fileclose>
  return -1;
    80004fd4:	557d                	li	a0,-1
}
    80004fd6:	70a2                	ld	ra,40(sp)
    80004fd8:	7402                	ld	s0,32(sp)
    80004fda:	64e2                	ld	s1,24(sp)
    80004fdc:	6942                	ld	s2,16(sp)
    80004fde:	69a2                	ld	s3,8(sp)
    80004fe0:	6a02                	ld	s4,0(sp)
    80004fe2:	6145                	add	sp,sp,48
    80004fe4:	8082                	ret
  return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	b7fd                	j	80004fd6 <pipealloc+0xc6>

0000000080004fea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fea:	1101                	add	sp,sp,-32
    80004fec:	ec06                	sd	ra,24(sp)
    80004fee:	e822                	sd	s0,16(sp)
    80004ff0:	e426                	sd	s1,8(sp)
    80004ff2:	e04a                	sd	s2,0(sp)
    80004ff4:	1000                	add	s0,sp,32
    80004ff6:	84aa                	mv	s1,a0
    80004ff8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	ce0080e7          	jalr	-800(ra) # 80000cda <acquire>
  if(writable){
    80005002:	02090d63          	beqz	s2,8000503c <pipeclose+0x52>
    pi->writeopen = 0;
    80005006:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000500a:	21848513          	add	a0,s1,536
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	426080e7          	jalr	1062(ra) # 80002434 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005016:	2204b783          	ld	a5,544(s1)
    8000501a:	eb95                	bnez	a5,8000504e <pipeclose+0x64>
    release(&pi->lock);
    8000501c:	8526                	mv	a0,s1
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	d70080e7          	jalr	-656(ra) # 80000d8e <release>
    kfree((char*)pi);
    80005026:	8526                	mv	a0,s1
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	9bc080e7          	jalr	-1604(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80005030:	60e2                	ld	ra,24(sp)
    80005032:	6442                	ld	s0,16(sp)
    80005034:	64a2                	ld	s1,8(sp)
    80005036:	6902                	ld	s2,0(sp)
    80005038:	6105                	add	sp,sp,32
    8000503a:	8082                	ret
    pi->readopen = 0;
    8000503c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005040:	21c48513          	add	a0,s1,540
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	3f0080e7          	jalr	1008(ra) # 80002434 <wakeup>
    8000504c:	b7e9                	j	80005016 <pipeclose+0x2c>
    release(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	d3e080e7          	jalr	-706(ra) # 80000d8e <release>
}
    80005058:	bfe1                	j	80005030 <pipeclose+0x46>

000000008000505a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000505a:	711d                	add	sp,sp,-96
    8000505c:	ec86                	sd	ra,88(sp)
    8000505e:	e8a2                	sd	s0,80(sp)
    80005060:	e4a6                	sd	s1,72(sp)
    80005062:	e0ca                	sd	s2,64(sp)
    80005064:	fc4e                	sd	s3,56(sp)
    80005066:	f852                	sd	s4,48(sp)
    80005068:	f456                	sd	s5,40(sp)
    8000506a:	f05a                	sd	s6,32(sp)
    8000506c:	ec5e                	sd	s7,24(sp)
    8000506e:	e862                	sd	s8,16(sp)
    80005070:	1080                	add	s0,sp,96
    80005072:	84aa                	mv	s1,a0
    80005074:	8aae                	mv	s5,a1
    80005076:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	a9c080e7          	jalr	-1380(ra) # 80001b14 <myproc>
    80005080:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005082:	8526                	mv	a0,s1
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	c56080e7          	jalr	-938(ra) # 80000cda <acquire>
  while(i < n){
    8000508c:	0b405663          	blez	s4,80005138 <pipewrite+0xde>
  int i = 0;
    80005090:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005092:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005094:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005098:	21c48b93          	add	s7,s1,540
    8000509c:	a089                	j	800050de <pipewrite+0x84>
      release(&pi->lock);
    8000509e:	8526                	mv	a0,s1
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	cee080e7          	jalr	-786(ra) # 80000d8e <release>
      return -1;
    800050a8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050aa:	854a                	mv	a0,s2
    800050ac:	60e6                	ld	ra,88(sp)
    800050ae:	6446                	ld	s0,80(sp)
    800050b0:	64a6                	ld	s1,72(sp)
    800050b2:	6906                	ld	s2,64(sp)
    800050b4:	79e2                	ld	s3,56(sp)
    800050b6:	7a42                	ld	s4,48(sp)
    800050b8:	7aa2                	ld	s5,40(sp)
    800050ba:	7b02                	ld	s6,32(sp)
    800050bc:	6be2                	ld	s7,24(sp)
    800050be:	6c42                	ld	s8,16(sp)
    800050c0:	6125                	add	sp,sp,96
    800050c2:	8082                	ret
      wakeup(&pi->nread);
    800050c4:	8562                	mv	a0,s8
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	36e080e7          	jalr	878(ra) # 80002434 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050ce:	85a6                	mv	a1,s1
    800050d0:	855e                	mv	a0,s7
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	2fe080e7          	jalr	766(ra) # 800023d0 <sleep>
  while(i < n){
    800050da:	07495063          	bge	s2,s4,8000513a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800050de:	2204a783          	lw	a5,544(s1)
    800050e2:	dfd5                	beqz	a5,8000509e <pipewrite+0x44>
    800050e4:	854e                	mv	a0,s3
    800050e6:	ffffd097          	auipc	ra,0xffffd
    800050ea:	59e080e7          	jalr	1438(ra) # 80002684 <killed>
    800050ee:	f945                	bnez	a0,8000509e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050f0:	2184a783          	lw	a5,536(s1)
    800050f4:	21c4a703          	lw	a4,540(s1)
    800050f8:	2007879b          	addw	a5,a5,512
    800050fc:	fcf704e3          	beq	a4,a5,800050c4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005100:	4685                	li	a3,1
    80005102:	01590633          	add	a2,s2,s5
    80005106:	faf40593          	add	a1,s0,-81
    8000510a:	0509b503          	ld	a0,80(s3)
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	752080e7          	jalr	1874(ra) # 80001860 <copyin>
    80005116:	03650263          	beq	a0,s6,8000513a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000511a:	21c4a783          	lw	a5,540(s1)
    8000511e:	0017871b          	addw	a4,a5,1
    80005122:	20e4ae23          	sw	a4,540(s1)
    80005126:	1ff7f793          	and	a5,a5,511
    8000512a:	97a6                	add	a5,a5,s1
    8000512c:	faf44703          	lbu	a4,-81(s0)
    80005130:	00e78c23          	sb	a4,24(a5)
      i++;
    80005134:	2905                	addw	s2,s2,1
    80005136:	b755                	j	800050da <pipewrite+0x80>
  int i = 0;
    80005138:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000513a:	21848513          	add	a0,s1,536
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	2f6080e7          	jalr	758(ra) # 80002434 <wakeup>
  release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	c46080e7          	jalr	-954(ra) # 80000d8e <release>
  return i;
    80005150:	bfa9                	j	800050aa <pipewrite+0x50>

0000000080005152 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005152:	715d                	add	sp,sp,-80
    80005154:	e486                	sd	ra,72(sp)
    80005156:	e0a2                	sd	s0,64(sp)
    80005158:	fc26                	sd	s1,56(sp)
    8000515a:	f84a                	sd	s2,48(sp)
    8000515c:	f44e                	sd	s3,40(sp)
    8000515e:	f052                	sd	s4,32(sp)
    80005160:	ec56                	sd	s5,24(sp)
    80005162:	e85a                	sd	s6,16(sp)
    80005164:	0880                	add	s0,sp,80
    80005166:	84aa                	mv	s1,a0
    80005168:	892e                	mv	s2,a1
    8000516a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	9a8080e7          	jalr	-1624(ra) # 80001b14 <myproc>
    80005174:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005176:	8526                	mv	a0,s1
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	b62080e7          	jalr	-1182(ra) # 80000cda <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005180:	2184a703          	lw	a4,536(s1)
    80005184:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005188:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000518c:	02f71763          	bne	a4,a5,800051ba <piperead+0x68>
    80005190:	2244a783          	lw	a5,548(s1)
    80005194:	c39d                	beqz	a5,800051ba <piperead+0x68>
    if(killed(pr)){
    80005196:	8552                	mv	a0,s4
    80005198:	ffffd097          	auipc	ra,0xffffd
    8000519c:	4ec080e7          	jalr	1260(ra) # 80002684 <killed>
    800051a0:	e949                	bnez	a0,80005232 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051a2:	85a6                	mv	a1,s1
    800051a4:	854e                	mv	a0,s3
    800051a6:	ffffd097          	auipc	ra,0xffffd
    800051aa:	22a080e7          	jalr	554(ra) # 800023d0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051ae:	2184a703          	lw	a4,536(s1)
    800051b2:	21c4a783          	lw	a5,540(s1)
    800051b6:	fcf70de3          	beq	a4,a5,80005190 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051ba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051bc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051be:	05505463          	blez	s5,80005206 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800051c2:	2184a783          	lw	a5,536(s1)
    800051c6:	21c4a703          	lw	a4,540(s1)
    800051ca:	02f70e63          	beq	a4,a5,80005206 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051ce:	0017871b          	addw	a4,a5,1
    800051d2:	20e4ac23          	sw	a4,536(s1)
    800051d6:	1ff7f793          	and	a5,a5,511
    800051da:	97a6                	add	a5,a5,s1
    800051dc:	0187c783          	lbu	a5,24(a5)
    800051e0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051e4:	4685                	li	a3,1
    800051e6:	fbf40613          	add	a2,s0,-65
    800051ea:	85ca                	mv	a1,s2
    800051ec:	050a3503          	ld	a0,80(s4)
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	5ac080e7          	jalr	1452(ra) # 8000179c <copyout>
    800051f8:	01650763          	beq	a0,s6,80005206 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fc:	2985                	addw	s3,s3,1
    800051fe:	0905                	add	s2,s2,1
    80005200:	fd3a91e3          	bne	s5,s3,800051c2 <piperead+0x70>
    80005204:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005206:	21c48513          	add	a0,s1,540
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	22a080e7          	jalr	554(ra) # 80002434 <wakeup>
  release(&pi->lock);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	b7a080e7          	jalr	-1158(ra) # 80000d8e <release>
  return i;
}
    8000521c:	854e                	mv	a0,s3
    8000521e:	60a6                	ld	ra,72(sp)
    80005220:	6406                	ld	s0,64(sp)
    80005222:	74e2                	ld	s1,56(sp)
    80005224:	7942                	ld	s2,48(sp)
    80005226:	79a2                	ld	s3,40(sp)
    80005228:	7a02                	ld	s4,32(sp)
    8000522a:	6ae2                	ld	s5,24(sp)
    8000522c:	6b42                	ld	s6,16(sp)
    8000522e:	6161                	add	sp,sp,80
    80005230:	8082                	ret
      release(&pi->lock);
    80005232:	8526                	mv	a0,s1
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	b5a080e7          	jalr	-1190(ra) # 80000d8e <release>
      return -1;
    8000523c:	59fd                	li	s3,-1
    8000523e:	bff9                	j	8000521c <piperead+0xca>

0000000080005240 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005240:	1141                	add	sp,sp,-16
    80005242:	e422                	sd	s0,8(sp)
    80005244:	0800                	add	s0,sp,16
    80005246:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005248:	8905                	and	a0,a0,1
    8000524a:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000524c:	8b89                	and	a5,a5,2
    8000524e:	c399                	beqz	a5,80005254 <flags2perm+0x14>
      perm |= PTE_W;
    80005250:	00456513          	or	a0,a0,4
    return perm;
}
    80005254:	6422                	ld	s0,8(sp)
    80005256:	0141                	add	sp,sp,16
    80005258:	8082                	ret

000000008000525a <exec>:

int
exec(char *path, char **argv)
{
    8000525a:	df010113          	add	sp,sp,-528
    8000525e:	20113423          	sd	ra,520(sp)
    80005262:	20813023          	sd	s0,512(sp)
    80005266:	ffa6                	sd	s1,504(sp)
    80005268:	fbca                	sd	s2,496(sp)
    8000526a:	f7ce                	sd	s3,488(sp)
    8000526c:	f3d2                	sd	s4,480(sp)
    8000526e:	efd6                	sd	s5,472(sp)
    80005270:	ebda                	sd	s6,464(sp)
    80005272:	e7de                	sd	s7,456(sp)
    80005274:	e3e2                	sd	s8,448(sp)
    80005276:	ff66                	sd	s9,440(sp)
    80005278:	fb6a                	sd	s10,432(sp)
    8000527a:	f76e                	sd	s11,424(sp)
    8000527c:	0c00                	add	s0,sp,528
    8000527e:	892a                	mv	s2,a0
    80005280:	dea43c23          	sd	a0,-520(s0)
    80005284:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	88c080e7          	jalr	-1908(ra) # 80001b14 <myproc>
    80005290:	84aa                	mv	s1,a0

  begin_op();
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	48e080e7          	jalr	1166(ra) # 80004720 <begin_op>

  if((ip = namei(path)) == 0){
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	284080e7          	jalr	644(ra) # 80004520 <namei>
    800052a4:	c92d                	beqz	a0,80005316 <exec+0xbc>
    800052a6:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	ad2080e7          	jalr	-1326(ra) # 80003d7a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052b0:	04000713          	li	a4,64
    800052b4:	4681                	li	a3,0
    800052b6:	e5040613          	add	a2,s0,-432
    800052ba:	4581                	li	a1,0
    800052bc:	8552                	mv	a0,s4
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	d70080e7          	jalr	-656(ra) # 8000402e <readi>
    800052c6:	04000793          	li	a5,64
    800052ca:	00f51a63          	bne	a0,a5,800052de <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052ce:	e5042703          	lw	a4,-432(s0)
    800052d2:	464c47b7          	lui	a5,0x464c4
    800052d6:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052da:	04f70463          	beq	a4,a5,80005322 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052de:	8552                	mv	a0,s4
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	cfc080e7          	jalr	-772(ra) # 80003fdc <iunlockput>
    end_op();
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	4b2080e7          	jalr	1202(ra) # 8000479a <end_op>
  }
  return -1;
    800052f0:	557d                	li	a0,-1
}
    800052f2:	20813083          	ld	ra,520(sp)
    800052f6:	20013403          	ld	s0,512(sp)
    800052fa:	74fe                	ld	s1,504(sp)
    800052fc:	795e                	ld	s2,496(sp)
    800052fe:	79be                	ld	s3,488(sp)
    80005300:	7a1e                	ld	s4,480(sp)
    80005302:	6afe                	ld	s5,472(sp)
    80005304:	6b5e                	ld	s6,464(sp)
    80005306:	6bbe                	ld	s7,456(sp)
    80005308:	6c1e                	ld	s8,448(sp)
    8000530a:	7cfa                	ld	s9,440(sp)
    8000530c:	7d5a                	ld	s10,432(sp)
    8000530e:	7dba                	ld	s11,424(sp)
    80005310:	21010113          	add	sp,sp,528
    80005314:	8082                	ret
    end_op();
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	484080e7          	jalr	1156(ra) # 8000479a <end_op>
    return -1;
    8000531e:	557d                	li	a0,-1
    80005320:	bfc9                	j	800052f2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005322:	8526                	mv	a0,s1
    80005324:	ffffd097          	auipc	ra,0xffffd
    80005328:	8b4080e7          	jalr	-1868(ra) # 80001bd8 <proc_pagetable>
    8000532c:	8b2a                	mv	s6,a0
    8000532e:	d945                	beqz	a0,800052de <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005330:	e7042d03          	lw	s10,-400(s0)
    80005334:	e8845783          	lhu	a5,-376(s0)
    80005338:	10078463          	beqz	a5,80005440 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000533c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000533e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005340:	6c85                	lui	s9,0x1
    80005342:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005346:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000534a:	6a85                	lui	s5,0x1
    8000534c:	a0b5                	j	800053b8 <exec+0x15e>
      panic("loadseg: address should exist");
    8000534e:	00003517          	auipc	a0,0x3
    80005352:	3aa50513          	add	a0,a0,938 # 800086f8 <syscalls+0x298>
    80005356:	ffffb097          	auipc	ra,0xffffb
    8000535a:	1e6080e7          	jalr	486(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000535e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005360:	8726                	mv	a4,s1
    80005362:	012c06bb          	addw	a3,s8,s2
    80005366:	4581                	li	a1,0
    80005368:	8552                	mv	a0,s4
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	cc4080e7          	jalr	-828(ra) # 8000402e <readi>
    80005372:	2501                	sext.w	a0,a0
    80005374:	24a49863          	bne	s1,a0,800055c4 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005378:	012a893b          	addw	s2,s5,s2
    8000537c:	03397563          	bgeu	s2,s3,800053a6 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005380:	02091593          	sll	a1,s2,0x20
    80005384:	9181                	srl	a1,a1,0x20
    80005386:	95de                	add	a1,a1,s7
    80005388:	855a                	mv	a0,s6
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	dd4080e7          	jalr	-556(ra) # 8000115e <walkaddr>
    80005392:	862a                	mv	a2,a0
    if(pa == 0)
    80005394:	dd4d                	beqz	a0,8000534e <exec+0xf4>
    if(sz - i < PGSIZE)
    80005396:	412984bb          	subw	s1,s3,s2
    8000539a:	0004879b          	sext.w	a5,s1
    8000539e:	fcfcf0e3          	bgeu	s9,a5,8000535e <exec+0x104>
    800053a2:	84d6                	mv	s1,s5
    800053a4:	bf6d                	j	8000535e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053a6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053aa:	2d85                	addw	s11,s11,1
    800053ac:	038d0d1b          	addw	s10,s10,56
    800053b0:	e8845783          	lhu	a5,-376(s0)
    800053b4:	08fdd763          	bge	s11,a5,80005442 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053b8:	2d01                	sext.w	s10,s10
    800053ba:	03800713          	li	a4,56
    800053be:	86ea                	mv	a3,s10
    800053c0:	e1840613          	add	a2,s0,-488
    800053c4:	4581                	li	a1,0
    800053c6:	8552                	mv	a0,s4
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	c66080e7          	jalr	-922(ra) # 8000402e <readi>
    800053d0:	03800793          	li	a5,56
    800053d4:	1ef51663          	bne	a0,a5,800055c0 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800053d8:	e1842783          	lw	a5,-488(s0)
    800053dc:	4705                	li	a4,1
    800053de:	fce796e3          	bne	a5,a4,800053aa <exec+0x150>
    if(ph.memsz < ph.filesz)
    800053e2:	e4043483          	ld	s1,-448(s0)
    800053e6:	e3843783          	ld	a5,-456(s0)
    800053ea:	1ef4e863          	bltu	s1,a5,800055da <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053ee:	e2843783          	ld	a5,-472(s0)
    800053f2:	94be                	add	s1,s1,a5
    800053f4:	1ef4e663          	bltu	s1,a5,800055e0 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800053f8:	df043703          	ld	a4,-528(s0)
    800053fc:	8ff9                	and	a5,a5,a4
    800053fe:	1e079463          	bnez	a5,800055e6 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005402:	e1c42503          	lw	a0,-484(s0)
    80005406:	00000097          	auipc	ra,0x0
    8000540a:	e3a080e7          	jalr	-454(ra) # 80005240 <flags2perm>
    8000540e:	86aa                	mv	a3,a0
    80005410:	8626                	mv	a2,s1
    80005412:	85ca                	mv	a1,s2
    80005414:	855a                	mv	a0,s6
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	0fc080e7          	jalr	252(ra) # 80001512 <uvmalloc>
    8000541e:	e0a43423          	sd	a0,-504(s0)
    80005422:	1c050563          	beqz	a0,800055ec <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005426:	e2843b83          	ld	s7,-472(s0)
    8000542a:	e2042c03          	lw	s8,-480(s0)
    8000542e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005432:	00098463          	beqz	s3,8000543a <exec+0x1e0>
    80005436:	4901                	li	s2,0
    80005438:	b7a1                	j	80005380 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000543a:	e0843903          	ld	s2,-504(s0)
    8000543e:	b7b5                	j	800053aa <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005440:	4901                	li	s2,0
  iunlockput(ip);
    80005442:	8552                	mv	a0,s4
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	b98080e7          	jalr	-1128(ra) # 80003fdc <iunlockput>
  end_op();
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	34e080e7          	jalr	846(ra) # 8000479a <end_op>
  p = myproc();
    80005454:	ffffc097          	auipc	ra,0xffffc
    80005458:	6c0080e7          	jalr	1728(ra) # 80001b14 <myproc>
    8000545c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000545e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005462:	6985                	lui	s3,0x1
    80005464:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005466:	99ca                	add	s3,s3,s2
    80005468:	77fd                	lui	a5,0xfffff
    8000546a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000546e:	4691                	li	a3,4
    80005470:	6609                	lui	a2,0x2
    80005472:	964e                	add	a2,a2,s3
    80005474:	85ce                	mv	a1,s3
    80005476:	855a                	mv	a0,s6
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	09a080e7          	jalr	154(ra) # 80001512 <uvmalloc>
    80005480:	892a                	mv	s2,a0
    80005482:	e0a43423          	sd	a0,-504(s0)
    80005486:	e509                	bnez	a0,80005490 <exec+0x236>
  if(pagetable)
    80005488:	e1343423          	sd	s3,-504(s0)
    8000548c:	4a01                	li	s4,0
    8000548e:	aa1d                	j	800055c4 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005490:	75f9                	lui	a1,0xffffe
    80005492:	95aa                	add	a1,a1,a0
    80005494:	855a                	mv	a0,s6
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	2d4080e7          	jalr	724(ra) # 8000176a <uvmclear>
  stackbase = sp - PGSIZE;
    8000549e:	7bfd                	lui	s7,0xfffff
    800054a0:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800054a2:	e0043783          	ld	a5,-512(s0)
    800054a6:	6388                	ld	a0,0(a5)
    800054a8:	c52d                	beqz	a0,80005512 <exec+0x2b8>
    800054aa:	e9040993          	add	s3,s0,-368
    800054ae:	f9040c13          	add	s8,s0,-112
    800054b2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054b4:	ffffc097          	auipc	ra,0xffffc
    800054b8:	a9c080e7          	jalr	-1380(ra) # 80000f50 <strlen>
    800054bc:	0015079b          	addw	a5,a0,1
    800054c0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054c4:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800054c8:	13796563          	bltu	s2,s7,800055f2 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054cc:	e0043d03          	ld	s10,-512(s0)
    800054d0:	000d3a03          	ld	s4,0(s10)
    800054d4:	8552                	mv	a0,s4
    800054d6:	ffffc097          	auipc	ra,0xffffc
    800054da:	a7a080e7          	jalr	-1414(ra) # 80000f50 <strlen>
    800054de:	0015069b          	addw	a3,a0,1
    800054e2:	8652                	mv	a2,s4
    800054e4:	85ca                	mv	a1,s2
    800054e6:	855a                	mv	a0,s6
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	2b4080e7          	jalr	692(ra) # 8000179c <copyout>
    800054f0:	10054363          	bltz	a0,800055f6 <exec+0x39c>
    ustack[argc] = sp;
    800054f4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054f8:	0485                	add	s1,s1,1
    800054fa:	008d0793          	add	a5,s10,8
    800054fe:	e0f43023          	sd	a5,-512(s0)
    80005502:	008d3503          	ld	a0,8(s10)
    80005506:	c909                	beqz	a0,80005518 <exec+0x2be>
    if(argc >= MAXARG)
    80005508:	09a1                	add	s3,s3,8
    8000550a:	fb8995e3          	bne	s3,s8,800054b4 <exec+0x25a>
  ip = 0;
    8000550e:	4a01                	li	s4,0
    80005510:	a855                	j	800055c4 <exec+0x36a>
  sp = sz;
    80005512:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005516:	4481                	li	s1,0
  ustack[argc] = 0;
    80005518:	00349793          	sll	a5,s1,0x3
    8000551c:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbc608>
    80005520:	97a2                	add	a5,a5,s0
    80005522:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005526:	00148693          	add	a3,s1,1
    8000552a:	068e                	sll	a3,a3,0x3
    8000552c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005530:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005534:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005538:	f57968e3          	bltu	s2,s7,80005488 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000553c:	e9040613          	add	a2,s0,-368
    80005540:	85ca                	mv	a1,s2
    80005542:	855a                	mv	a0,s6
    80005544:	ffffc097          	auipc	ra,0xffffc
    80005548:	258080e7          	jalr	600(ra) # 8000179c <copyout>
    8000554c:	0a054763          	bltz	a0,800055fa <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005550:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005554:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005558:	df843783          	ld	a5,-520(s0)
    8000555c:	0007c703          	lbu	a4,0(a5)
    80005560:	cf11                	beqz	a4,8000557c <exec+0x322>
    80005562:	0785                	add	a5,a5,1
    if(*s == '/')
    80005564:	02f00693          	li	a3,47
    80005568:	a039                	j	80005576 <exec+0x31c>
      last = s+1;
    8000556a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000556e:	0785                	add	a5,a5,1
    80005570:	fff7c703          	lbu	a4,-1(a5)
    80005574:	c701                	beqz	a4,8000557c <exec+0x322>
    if(*s == '/')
    80005576:	fed71ce3          	bne	a4,a3,8000556e <exec+0x314>
    8000557a:	bfc5                	j	8000556a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000557c:	4641                	li	a2,16
    8000557e:	df843583          	ld	a1,-520(s0)
    80005582:	158a8513          	add	a0,s5,344
    80005586:	ffffc097          	auipc	ra,0xffffc
    8000558a:	998080e7          	jalr	-1640(ra) # 80000f1e <safestrcpy>
  oldpagetable = p->pagetable;
    8000558e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005592:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005596:	e0843783          	ld	a5,-504(s0)
    8000559a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000559e:	058ab783          	ld	a5,88(s5)
    800055a2:	e6843703          	ld	a4,-408(s0)
    800055a6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055a8:	058ab783          	ld	a5,88(s5)
    800055ac:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055b0:	85e6                	mv	a1,s9
    800055b2:	ffffc097          	auipc	ra,0xffffc
    800055b6:	6c2080e7          	jalr	1730(ra) # 80001c74 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055ba:	0004851b          	sext.w	a0,s1
    800055be:	bb15                	j	800052f2 <exec+0x98>
    800055c0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055c4:	e0843583          	ld	a1,-504(s0)
    800055c8:	855a                	mv	a0,s6
    800055ca:	ffffc097          	auipc	ra,0xffffc
    800055ce:	6aa080e7          	jalr	1706(ra) # 80001c74 <proc_freepagetable>
  return -1;
    800055d2:	557d                	li	a0,-1
  if(ip){
    800055d4:	d00a0fe3          	beqz	s4,800052f2 <exec+0x98>
    800055d8:	b319                	j	800052de <exec+0x84>
    800055da:	e1243423          	sd	s2,-504(s0)
    800055de:	b7dd                	j	800055c4 <exec+0x36a>
    800055e0:	e1243423          	sd	s2,-504(s0)
    800055e4:	b7c5                	j	800055c4 <exec+0x36a>
    800055e6:	e1243423          	sd	s2,-504(s0)
    800055ea:	bfe9                	j	800055c4 <exec+0x36a>
    800055ec:	e1243423          	sd	s2,-504(s0)
    800055f0:	bfd1                	j	800055c4 <exec+0x36a>
  ip = 0;
    800055f2:	4a01                	li	s4,0
    800055f4:	bfc1                	j	800055c4 <exec+0x36a>
    800055f6:	4a01                	li	s4,0
  if(pagetable)
    800055f8:	b7f1                	j	800055c4 <exec+0x36a>
  sz = sz1;
    800055fa:	e0843983          	ld	s3,-504(s0)
    800055fe:	b569                	j	80005488 <exec+0x22e>

0000000080005600 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005600:	7179                	add	sp,sp,-48
    80005602:	f406                	sd	ra,40(sp)
    80005604:	f022                	sd	s0,32(sp)
    80005606:	ec26                	sd	s1,24(sp)
    80005608:	e84a                	sd	s2,16(sp)
    8000560a:	1800                	add	s0,sp,48
    8000560c:	892e                	mv	s2,a1
    8000560e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005610:	fdc40593          	add	a1,s0,-36
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	b2c080e7          	jalr	-1236(ra) # 80003140 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000561c:	fdc42703          	lw	a4,-36(s0)
    80005620:	47bd                	li	a5,15
    80005622:	02e7eb63          	bltu	a5,a4,80005658 <argfd+0x58>
    80005626:	ffffc097          	auipc	ra,0xffffc
    8000562a:	4ee080e7          	jalr	1262(ra) # 80001b14 <myproc>
    8000562e:	fdc42703          	lw	a4,-36(s0)
    80005632:	01a70793          	add	a5,a4,26
    80005636:	078e                	sll	a5,a5,0x3
    80005638:	953e                	add	a0,a0,a5
    8000563a:	611c                	ld	a5,0(a0)
    8000563c:	c385                	beqz	a5,8000565c <argfd+0x5c>
    return -1;
  if(pfd)
    8000563e:	00090463          	beqz	s2,80005646 <argfd+0x46>
    *pfd = fd;
    80005642:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005646:	4501                	li	a0,0
  if(pf)
    80005648:	c091                	beqz	s1,8000564c <argfd+0x4c>
    *pf = f;
    8000564a:	e09c                	sd	a5,0(s1)
}
    8000564c:	70a2                	ld	ra,40(sp)
    8000564e:	7402                	ld	s0,32(sp)
    80005650:	64e2                	ld	s1,24(sp)
    80005652:	6942                	ld	s2,16(sp)
    80005654:	6145                	add	sp,sp,48
    80005656:	8082                	ret
    return -1;
    80005658:	557d                	li	a0,-1
    8000565a:	bfcd                	j	8000564c <argfd+0x4c>
    8000565c:	557d                	li	a0,-1
    8000565e:	b7fd                	j	8000564c <argfd+0x4c>

0000000080005660 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005660:	1101                	add	sp,sp,-32
    80005662:	ec06                	sd	ra,24(sp)
    80005664:	e822                	sd	s0,16(sp)
    80005666:	e426                	sd	s1,8(sp)
    80005668:	1000                	add	s0,sp,32
    8000566a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000566c:	ffffc097          	auipc	ra,0xffffc
    80005670:	4a8080e7          	jalr	1192(ra) # 80001b14 <myproc>
    80005674:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005676:	0d050793          	add	a5,a0,208
    8000567a:	4501                	li	a0,0
    8000567c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000567e:	6398                	ld	a4,0(a5)
    80005680:	cb19                	beqz	a4,80005696 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005682:	2505                	addw	a0,a0,1
    80005684:	07a1                	add	a5,a5,8
    80005686:	fed51ce3          	bne	a0,a3,8000567e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000568a:	557d                	li	a0,-1
}
    8000568c:	60e2                	ld	ra,24(sp)
    8000568e:	6442                	ld	s0,16(sp)
    80005690:	64a2                	ld	s1,8(sp)
    80005692:	6105                	add	sp,sp,32
    80005694:	8082                	ret
      p->ofile[fd] = f;
    80005696:	01a50793          	add	a5,a0,26
    8000569a:	078e                	sll	a5,a5,0x3
    8000569c:	963e                	add	a2,a2,a5
    8000569e:	e204                	sd	s1,0(a2)
      return fd;
    800056a0:	b7f5                	j	8000568c <fdalloc+0x2c>

00000000800056a2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056a2:	715d                	add	sp,sp,-80
    800056a4:	e486                	sd	ra,72(sp)
    800056a6:	e0a2                	sd	s0,64(sp)
    800056a8:	fc26                	sd	s1,56(sp)
    800056aa:	f84a                	sd	s2,48(sp)
    800056ac:	f44e                	sd	s3,40(sp)
    800056ae:	f052                	sd	s4,32(sp)
    800056b0:	ec56                	sd	s5,24(sp)
    800056b2:	e85a                	sd	s6,16(sp)
    800056b4:	0880                	add	s0,sp,80
    800056b6:	8b2e                	mv	s6,a1
    800056b8:	89b2                	mv	s3,a2
    800056ba:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056bc:	fb040593          	add	a1,s0,-80
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	e7e080e7          	jalr	-386(ra) # 8000453e <nameiparent>
    800056c8:	84aa                	mv	s1,a0
    800056ca:	14050b63          	beqz	a0,80005820 <create+0x17e>
    return 0;

  ilock(dp);
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	6ac080e7          	jalr	1708(ra) # 80003d7a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056d6:	4601                	li	a2,0
    800056d8:	fb040593          	add	a1,s0,-80
    800056dc:	8526                	mv	a0,s1
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	b80080e7          	jalr	-1152(ra) # 8000425e <dirlookup>
    800056e6:	8aaa                	mv	s5,a0
    800056e8:	c921                	beqz	a0,80005738 <create+0x96>
    iunlockput(dp);
    800056ea:	8526                	mv	a0,s1
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	8f0080e7          	jalr	-1808(ra) # 80003fdc <iunlockput>
    ilock(ip);
    800056f4:	8556                	mv	a0,s5
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	684080e7          	jalr	1668(ra) # 80003d7a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056fe:	4789                	li	a5,2
    80005700:	02fb1563          	bne	s6,a5,8000572a <create+0x88>
    80005704:	044ad783          	lhu	a5,68(s5)
    80005708:	37f9                	addw	a5,a5,-2
    8000570a:	17c2                	sll	a5,a5,0x30
    8000570c:	93c1                	srl	a5,a5,0x30
    8000570e:	4705                	li	a4,1
    80005710:	00f76d63          	bltu	a4,a5,8000572a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005714:	8556                	mv	a0,s5
    80005716:	60a6                	ld	ra,72(sp)
    80005718:	6406                	ld	s0,64(sp)
    8000571a:	74e2                	ld	s1,56(sp)
    8000571c:	7942                	ld	s2,48(sp)
    8000571e:	79a2                	ld	s3,40(sp)
    80005720:	7a02                	ld	s4,32(sp)
    80005722:	6ae2                	ld	s5,24(sp)
    80005724:	6b42                	ld	s6,16(sp)
    80005726:	6161                	add	sp,sp,80
    80005728:	8082                	ret
    iunlockput(ip);
    8000572a:	8556                	mv	a0,s5
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	8b0080e7          	jalr	-1872(ra) # 80003fdc <iunlockput>
    return 0;
    80005734:	4a81                	li	s5,0
    80005736:	bff9                	j	80005714 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005738:	85da                	mv	a1,s6
    8000573a:	4088                	lw	a0,0(s1)
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	4a6080e7          	jalr	1190(ra) # 80003be2 <ialloc>
    80005744:	8a2a                	mv	s4,a0
    80005746:	c529                	beqz	a0,80005790 <create+0xee>
  ilock(ip);
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	632080e7          	jalr	1586(ra) # 80003d7a <ilock>
  ip->major = major;
    80005750:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005754:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005758:	4905                	li	s2,1
    8000575a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000575e:	8552                	mv	a0,s4
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	54e080e7          	jalr	1358(ra) # 80003cae <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005768:	032b0b63          	beq	s6,s2,8000579e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000576c:	004a2603          	lw	a2,4(s4)
    80005770:	fb040593          	add	a1,s0,-80
    80005774:	8526                	mv	a0,s1
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	cf8080e7          	jalr	-776(ra) # 8000446e <dirlink>
    8000577e:	06054f63          	bltz	a0,800057fc <create+0x15a>
  iunlockput(dp);
    80005782:	8526                	mv	a0,s1
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	858080e7          	jalr	-1960(ra) # 80003fdc <iunlockput>
  return ip;
    8000578c:	8ad2                	mv	s5,s4
    8000578e:	b759                	j	80005714 <create+0x72>
    iunlockput(dp);
    80005790:	8526                	mv	a0,s1
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	84a080e7          	jalr	-1974(ra) # 80003fdc <iunlockput>
    return 0;
    8000579a:	8ad2                	mv	s5,s4
    8000579c:	bfa5                	j	80005714 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000579e:	004a2603          	lw	a2,4(s4)
    800057a2:	00003597          	auipc	a1,0x3
    800057a6:	f7658593          	add	a1,a1,-138 # 80008718 <syscalls+0x2b8>
    800057aa:	8552                	mv	a0,s4
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	cc2080e7          	jalr	-830(ra) # 8000446e <dirlink>
    800057b4:	04054463          	bltz	a0,800057fc <create+0x15a>
    800057b8:	40d0                	lw	a2,4(s1)
    800057ba:	00003597          	auipc	a1,0x3
    800057be:	f6658593          	add	a1,a1,-154 # 80008720 <syscalls+0x2c0>
    800057c2:	8552                	mv	a0,s4
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	caa080e7          	jalr	-854(ra) # 8000446e <dirlink>
    800057cc:	02054863          	bltz	a0,800057fc <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800057d0:	004a2603          	lw	a2,4(s4)
    800057d4:	fb040593          	add	a1,s0,-80
    800057d8:	8526                	mv	a0,s1
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	c94080e7          	jalr	-876(ra) # 8000446e <dirlink>
    800057e2:	00054d63          	bltz	a0,800057fc <create+0x15a>
    dp->nlink++;  // for ".."
    800057e6:	04a4d783          	lhu	a5,74(s1)
    800057ea:	2785                	addw	a5,a5,1
    800057ec:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	4bc080e7          	jalr	1212(ra) # 80003cae <iupdate>
    800057fa:	b761                	j	80005782 <create+0xe0>
  ip->nlink = 0;
    800057fc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005800:	8552                	mv	a0,s4
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	4ac080e7          	jalr	1196(ra) # 80003cae <iupdate>
  iunlockput(ip);
    8000580a:	8552                	mv	a0,s4
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	7d0080e7          	jalr	2000(ra) # 80003fdc <iunlockput>
  iunlockput(dp);
    80005814:	8526                	mv	a0,s1
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	7c6080e7          	jalr	1990(ra) # 80003fdc <iunlockput>
  return 0;
    8000581e:	bddd                	j	80005714 <create+0x72>
    return 0;
    80005820:	8aaa                	mv	s5,a0
    80005822:	bdcd                	j	80005714 <create+0x72>

0000000080005824 <sys_dup>:
{
    80005824:	7179                	add	sp,sp,-48
    80005826:	f406                	sd	ra,40(sp)
    80005828:	f022                	sd	s0,32(sp)
    8000582a:	ec26                	sd	s1,24(sp)
    8000582c:	e84a                	sd	s2,16(sp)
    8000582e:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005830:	fd840613          	add	a2,s0,-40
    80005834:	4581                	li	a1,0
    80005836:	4501                	li	a0,0
    80005838:	00000097          	auipc	ra,0x0
    8000583c:	dc8080e7          	jalr	-568(ra) # 80005600 <argfd>
    return -1;
    80005840:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005842:	02054363          	bltz	a0,80005868 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005846:	fd843903          	ld	s2,-40(s0)
    8000584a:	854a                	mv	a0,s2
    8000584c:	00000097          	auipc	ra,0x0
    80005850:	e14080e7          	jalr	-492(ra) # 80005660 <fdalloc>
    80005854:	84aa                	mv	s1,a0
    return -1;
    80005856:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005858:	00054863          	bltz	a0,80005868 <sys_dup+0x44>
  filedup(f);
    8000585c:	854a                	mv	a0,s2
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	334080e7          	jalr	820(ra) # 80004b92 <filedup>
  return fd;
    80005866:	87a6                	mv	a5,s1
}
    80005868:	853e                	mv	a0,a5
    8000586a:	70a2                	ld	ra,40(sp)
    8000586c:	7402                	ld	s0,32(sp)
    8000586e:	64e2                	ld	s1,24(sp)
    80005870:	6942                	ld	s2,16(sp)
    80005872:	6145                	add	sp,sp,48
    80005874:	8082                	ret

0000000080005876 <sys_getreadcount>:
{
    80005876:	1141                	add	sp,sp,-16
    80005878:	e422                	sd	s0,8(sp)
    8000587a:	0800                	add	s0,sp,16
}
    8000587c:	00003517          	auipc	a0,0x3
    80005880:	07852503          	lw	a0,120(a0) # 800088f4 <readCount>
    80005884:	6422                	ld	s0,8(sp)
    80005886:	0141                	add	sp,sp,16
    80005888:	8082                	ret

000000008000588a <sys_read>:
{
    8000588a:	7179                	add	sp,sp,-48
    8000588c:	f406                	sd	ra,40(sp)
    8000588e:	f022                	sd	s0,32(sp)
    80005890:	1800                	add	s0,sp,48
  readCount++;
    80005892:	00003717          	auipc	a4,0x3
    80005896:	06270713          	add	a4,a4,98 # 800088f4 <readCount>
    8000589a:	431c                	lw	a5,0(a4)
    8000589c:	2785                	addw	a5,a5,1
    8000589e:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    800058a0:	fd840593          	add	a1,s0,-40
    800058a4:	4505                	li	a0,1
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	8ba080e7          	jalr	-1862(ra) # 80003160 <argaddr>
  argint(2, &n);
    800058ae:	fe440593          	add	a1,s0,-28
    800058b2:	4509                	li	a0,2
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	88c080e7          	jalr	-1908(ra) # 80003140 <argint>
  if(argfd(0, 0, &f) < 0)
    800058bc:	fe840613          	add	a2,s0,-24
    800058c0:	4581                	li	a1,0
    800058c2:	4501                	li	a0,0
    800058c4:	00000097          	auipc	ra,0x0
    800058c8:	d3c080e7          	jalr	-708(ra) # 80005600 <argfd>
    800058cc:	87aa                	mv	a5,a0
    return -1;
    800058ce:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058d0:	0007cc63          	bltz	a5,800058e8 <sys_read+0x5e>
  return fileread(f, p, n);
    800058d4:	fe442603          	lw	a2,-28(s0)
    800058d8:	fd843583          	ld	a1,-40(s0)
    800058dc:	fe843503          	ld	a0,-24(s0)
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	43e080e7          	jalr	1086(ra) # 80004d1e <fileread>
}
    800058e8:	70a2                	ld	ra,40(sp)
    800058ea:	7402                	ld	s0,32(sp)
    800058ec:	6145                	add	sp,sp,48
    800058ee:	8082                	ret

00000000800058f0 <sys_write>:
{
    800058f0:	7179                	add	sp,sp,-48
    800058f2:	f406                	sd	ra,40(sp)
    800058f4:	f022                	sd	s0,32(sp)
    800058f6:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800058f8:	fd840593          	add	a1,s0,-40
    800058fc:	4505                	li	a0,1
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	862080e7          	jalr	-1950(ra) # 80003160 <argaddr>
  argint(2, &n);
    80005906:	fe440593          	add	a1,s0,-28
    8000590a:	4509                	li	a0,2
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	834080e7          	jalr	-1996(ra) # 80003140 <argint>
  if(argfd(0, 0, &f) < 0)
    80005914:	fe840613          	add	a2,s0,-24
    80005918:	4581                	li	a1,0
    8000591a:	4501                	li	a0,0
    8000591c:	00000097          	auipc	ra,0x0
    80005920:	ce4080e7          	jalr	-796(ra) # 80005600 <argfd>
    80005924:	87aa                	mv	a5,a0
    return -1;
    80005926:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005928:	0007cc63          	bltz	a5,80005940 <sys_write+0x50>
  return filewrite(f, p, n);
    8000592c:	fe442603          	lw	a2,-28(s0)
    80005930:	fd843583          	ld	a1,-40(s0)
    80005934:	fe843503          	ld	a0,-24(s0)
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	4a8080e7          	jalr	1192(ra) # 80004de0 <filewrite>
}
    80005940:	70a2                	ld	ra,40(sp)
    80005942:	7402                	ld	s0,32(sp)
    80005944:	6145                	add	sp,sp,48
    80005946:	8082                	ret

0000000080005948 <sys_close>:
{
    80005948:	1101                	add	sp,sp,-32
    8000594a:	ec06                	sd	ra,24(sp)
    8000594c:	e822                	sd	s0,16(sp)
    8000594e:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005950:	fe040613          	add	a2,s0,-32
    80005954:	fec40593          	add	a1,s0,-20
    80005958:	4501                	li	a0,0
    8000595a:	00000097          	auipc	ra,0x0
    8000595e:	ca6080e7          	jalr	-858(ra) # 80005600 <argfd>
    return -1;
    80005962:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005964:	02054463          	bltz	a0,8000598c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005968:	ffffc097          	auipc	ra,0xffffc
    8000596c:	1ac080e7          	jalr	428(ra) # 80001b14 <myproc>
    80005970:	fec42783          	lw	a5,-20(s0)
    80005974:	07e9                	add	a5,a5,26
    80005976:	078e                	sll	a5,a5,0x3
    80005978:	953e                	add	a0,a0,a5
    8000597a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000597e:	fe043503          	ld	a0,-32(s0)
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	262080e7          	jalr	610(ra) # 80004be4 <fileclose>
  return 0;
    8000598a:	4781                	li	a5,0
}
    8000598c:	853e                	mv	a0,a5
    8000598e:	60e2                	ld	ra,24(sp)
    80005990:	6442                	ld	s0,16(sp)
    80005992:	6105                	add	sp,sp,32
    80005994:	8082                	ret

0000000080005996 <sys_fstat>:
{
    80005996:	1101                	add	sp,sp,-32
    80005998:	ec06                	sd	ra,24(sp)
    8000599a:	e822                	sd	s0,16(sp)
    8000599c:	1000                	add	s0,sp,32
  argaddr(1, &st);
    8000599e:	fe040593          	add	a1,s0,-32
    800059a2:	4505                	li	a0,1
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	7bc080e7          	jalr	1980(ra) # 80003160 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059ac:	fe840613          	add	a2,s0,-24
    800059b0:	4581                	li	a1,0
    800059b2:	4501                	li	a0,0
    800059b4:	00000097          	auipc	ra,0x0
    800059b8:	c4c080e7          	jalr	-948(ra) # 80005600 <argfd>
    800059bc:	87aa                	mv	a5,a0
    return -1;
    800059be:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059c0:	0007ca63          	bltz	a5,800059d4 <sys_fstat+0x3e>
  return filestat(f, st);
    800059c4:	fe043583          	ld	a1,-32(s0)
    800059c8:	fe843503          	ld	a0,-24(s0)
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	2e0080e7          	jalr	736(ra) # 80004cac <filestat>
}
    800059d4:	60e2                	ld	ra,24(sp)
    800059d6:	6442                	ld	s0,16(sp)
    800059d8:	6105                	add	sp,sp,32
    800059da:	8082                	ret

00000000800059dc <sys_link>:
{
    800059dc:	7169                	add	sp,sp,-304
    800059de:	f606                	sd	ra,296(sp)
    800059e0:	f222                	sd	s0,288(sp)
    800059e2:	ee26                	sd	s1,280(sp)
    800059e4:	ea4a                	sd	s2,272(sp)
    800059e6:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059e8:	08000613          	li	a2,128
    800059ec:	ed040593          	add	a1,s0,-304
    800059f0:	4501                	li	a0,0
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	78e080e7          	jalr	1934(ra) # 80003180 <argstr>
    return -1;
    800059fa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059fc:	10054e63          	bltz	a0,80005b18 <sys_link+0x13c>
    80005a00:	08000613          	li	a2,128
    80005a04:	f5040593          	add	a1,s0,-176
    80005a08:	4505                	li	a0,1
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	776080e7          	jalr	1910(ra) # 80003180 <argstr>
    return -1;
    80005a12:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a14:	10054263          	bltz	a0,80005b18 <sys_link+0x13c>
  begin_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	d08080e7          	jalr	-760(ra) # 80004720 <begin_op>
  if((ip = namei(old)) == 0){
    80005a20:	ed040513          	add	a0,s0,-304
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	afc080e7          	jalr	-1284(ra) # 80004520 <namei>
    80005a2c:	84aa                	mv	s1,a0
    80005a2e:	c551                	beqz	a0,80005aba <sys_link+0xde>
  ilock(ip);
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	34a080e7          	jalr	842(ra) # 80003d7a <ilock>
  if(ip->type == T_DIR){
    80005a38:	04449703          	lh	a4,68(s1)
    80005a3c:	4785                	li	a5,1
    80005a3e:	08f70463          	beq	a4,a5,80005ac6 <sys_link+0xea>
  ip->nlink++;
    80005a42:	04a4d783          	lhu	a5,74(s1)
    80005a46:	2785                	addw	a5,a5,1
    80005a48:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	260080e7          	jalr	608(ra) # 80003cae <iupdate>
  iunlock(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	3e4080e7          	jalr	996(ra) # 80003e3c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a60:	fd040593          	add	a1,s0,-48
    80005a64:	f5040513          	add	a0,s0,-176
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	ad6080e7          	jalr	-1322(ra) # 8000453e <nameiparent>
    80005a70:	892a                	mv	s2,a0
    80005a72:	c935                	beqz	a0,80005ae6 <sys_link+0x10a>
  ilock(dp);
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	306080e7          	jalr	774(ra) # 80003d7a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a7c:	00092703          	lw	a4,0(s2)
    80005a80:	409c                	lw	a5,0(s1)
    80005a82:	04f71d63          	bne	a4,a5,80005adc <sys_link+0x100>
    80005a86:	40d0                	lw	a2,4(s1)
    80005a88:	fd040593          	add	a1,s0,-48
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	9e0080e7          	jalr	-1568(ra) # 8000446e <dirlink>
    80005a96:	04054363          	bltz	a0,80005adc <sys_link+0x100>
  iunlockput(dp);
    80005a9a:	854a                	mv	a0,s2
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	540080e7          	jalr	1344(ra) # 80003fdc <iunlockput>
  iput(ip);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	48e080e7          	jalr	1166(ra) # 80003f34 <iput>
  end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	cec080e7          	jalr	-788(ra) # 8000479a <end_op>
  return 0;
    80005ab6:	4781                	li	a5,0
    80005ab8:	a085                	j	80005b18 <sys_link+0x13c>
    end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	ce0080e7          	jalr	-800(ra) # 8000479a <end_op>
    return -1;
    80005ac2:	57fd                	li	a5,-1
    80005ac4:	a891                	j	80005b18 <sys_link+0x13c>
    iunlockput(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	514080e7          	jalr	1300(ra) # 80003fdc <iunlockput>
    end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	cca080e7          	jalr	-822(ra) # 8000479a <end_op>
    return -1;
    80005ad8:	57fd                	li	a5,-1
    80005ada:	a83d                	j	80005b18 <sys_link+0x13c>
    iunlockput(dp);
    80005adc:	854a                	mv	a0,s2
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	4fe080e7          	jalr	1278(ra) # 80003fdc <iunlockput>
  ilock(ip);
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	292080e7          	jalr	658(ra) # 80003d7a <ilock>
  ip->nlink--;
    80005af0:	04a4d783          	lhu	a5,74(s1)
    80005af4:	37fd                	addw	a5,a5,-1
    80005af6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005afa:	8526                	mv	a0,s1
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	1b2080e7          	jalr	434(ra) # 80003cae <iupdate>
  iunlockput(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	4d6080e7          	jalr	1238(ra) # 80003fdc <iunlockput>
  end_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	c8c080e7          	jalr	-884(ra) # 8000479a <end_op>
  return -1;
    80005b16:	57fd                	li	a5,-1
}
    80005b18:	853e                	mv	a0,a5
    80005b1a:	70b2                	ld	ra,296(sp)
    80005b1c:	7412                	ld	s0,288(sp)
    80005b1e:	64f2                	ld	s1,280(sp)
    80005b20:	6952                	ld	s2,272(sp)
    80005b22:	6155                	add	sp,sp,304
    80005b24:	8082                	ret

0000000080005b26 <sys_unlink>:
{
    80005b26:	7151                	add	sp,sp,-240
    80005b28:	f586                	sd	ra,232(sp)
    80005b2a:	f1a2                	sd	s0,224(sp)
    80005b2c:	eda6                	sd	s1,216(sp)
    80005b2e:	e9ca                	sd	s2,208(sp)
    80005b30:	e5ce                	sd	s3,200(sp)
    80005b32:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b34:	08000613          	li	a2,128
    80005b38:	f3040593          	add	a1,s0,-208
    80005b3c:	4501                	li	a0,0
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	642080e7          	jalr	1602(ra) # 80003180 <argstr>
    80005b46:	18054163          	bltz	a0,80005cc8 <sys_unlink+0x1a2>
  begin_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	bd6080e7          	jalr	-1066(ra) # 80004720 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b52:	fb040593          	add	a1,s0,-80
    80005b56:	f3040513          	add	a0,s0,-208
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	9e4080e7          	jalr	-1564(ra) # 8000453e <nameiparent>
    80005b62:	84aa                	mv	s1,a0
    80005b64:	c979                	beqz	a0,80005c3a <sys_unlink+0x114>
  ilock(dp);
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	214080e7          	jalr	532(ra) # 80003d7a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b6e:	00003597          	auipc	a1,0x3
    80005b72:	baa58593          	add	a1,a1,-1110 # 80008718 <syscalls+0x2b8>
    80005b76:	fb040513          	add	a0,s0,-80
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	6ca080e7          	jalr	1738(ra) # 80004244 <namecmp>
    80005b82:	14050a63          	beqz	a0,80005cd6 <sys_unlink+0x1b0>
    80005b86:	00003597          	auipc	a1,0x3
    80005b8a:	b9a58593          	add	a1,a1,-1126 # 80008720 <syscalls+0x2c0>
    80005b8e:	fb040513          	add	a0,s0,-80
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	6b2080e7          	jalr	1714(ra) # 80004244 <namecmp>
    80005b9a:	12050e63          	beqz	a0,80005cd6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b9e:	f2c40613          	add	a2,s0,-212
    80005ba2:	fb040593          	add	a1,s0,-80
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	6b6080e7          	jalr	1718(ra) # 8000425e <dirlookup>
    80005bb0:	892a                	mv	s2,a0
    80005bb2:	12050263          	beqz	a0,80005cd6 <sys_unlink+0x1b0>
  ilock(ip);
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	1c4080e7          	jalr	452(ra) # 80003d7a <ilock>
  if(ip->nlink < 1)
    80005bbe:	04a91783          	lh	a5,74(s2)
    80005bc2:	08f05263          	blez	a5,80005c46 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bc6:	04491703          	lh	a4,68(s2)
    80005bca:	4785                	li	a5,1
    80005bcc:	08f70563          	beq	a4,a5,80005c56 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bd0:	4641                	li	a2,16
    80005bd2:	4581                	li	a1,0
    80005bd4:	fc040513          	add	a0,s0,-64
    80005bd8:	ffffb097          	auipc	ra,0xffffb
    80005bdc:	1fe080e7          	jalr	510(ra) # 80000dd6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005be0:	4741                	li	a4,16
    80005be2:	f2c42683          	lw	a3,-212(s0)
    80005be6:	fc040613          	add	a2,s0,-64
    80005bea:	4581                	li	a1,0
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	538080e7          	jalr	1336(ra) # 80004126 <writei>
    80005bf6:	47c1                	li	a5,16
    80005bf8:	0af51563          	bne	a0,a5,80005ca2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bfc:	04491703          	lh	a4,68(s2)
    80005c00:	4785                	li	a5,1
    80005c02:	0af70863          	beq	a4,a5,80005cb2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	3d4080e7          	jalr	980(ra) # 80003fdc <iunlockput>
  ip->nlink--;
    80005c10:	04a95783          	lhu	a5,74(s2)
    80005c14:	37fd                	addw	a5,a5,-1
    80005c16:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c1a:	854a                	mv	a0,s2
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	092080e7          	jalr	146(ra) # 80003cae <iupdate>
  iunlockput(ip);
    80005c24:	854a                	mv	a0,s2
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	3b6080e7          	jalr	950(ra) # 80003fdc <iunlockput>
  end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	b6c080e7          	jalr	-1172(ra) # 8000479a <end_op>
  return 0;
    80005c36:	4501                	li	a0,0
    80005c38:	a84d                	j	80005cea <sys_unlink+0x1c4>
    end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	b60080e7          	jalr	-1184(ra) # 8000479a <end_op>
    return -1;
    80005c42:	557d                	li	a0,-1
    80005c44:	a05d                	j	80005cea <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c46:	00003517          	auipc	a0,0x3
    80005c4a:	ae250513          	add	a0,a0,-1310 # 80008728 <syscalls+0x2c8>
    80005c4e:	ffffb097          	auipc	ra,0xffffb
    80005c52:	8ee080e7          	jalr	-1810(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c56:	04c92703          	lw	a4,76(s2)
    80005c5a:	02000793          	li	a5,32
    80005c5e:	f6e7f9e3          	bgeu	a5,a4,80005bd0 <sys_unlink+0xaa>
    80005c62:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c66:	4741                	li	a4,16
    80005c68:	86ce                	mv	a3,s3
    80005c6a:	f1840613          	add	a2,s0,-232
    80005c6e:	4581                	li	a1,0
    80005c70:	854a                	mv	a0,s2
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	3bc080e7          	jalr	956(ra) # 8000402e <readi>
    80005c7a:	47c1                	li	a5,16
    80005c7c:	00f51b63          	bne	a0,a5,80005c92 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c80:	f1845783          	lhu	a5,-232(s0)
    80005c84:	e7a1                	bnez	a5,80005ccc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c86:	29c1                	addw	s3,s3,16
    80005c88:	04c92783          	lw	a5,76(s2)
    80005c8c:	fcf9ede3          	bltu	s3,a5,80005c66 <sys_unlink+0x140>
    80005c90:	b781                	j	80005bd0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c92:	00003517          	auipc	a0,0x3
    80005c96:	aae50513          	add	a0,a0,-1362 # 80008740 <syscalls+0x2e0>
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	8a2080e7          	jalr	-1886(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005ca2:	00003517          	auipc	a0,0x3
    80005ca6:	ab650513          	add	a0,a0,-1354 # 80008758 <syscalls+0x2f8>
    80005caa:	ffffb097          	auipc	ra,0xffffb
    80005cae:	892080e7          	jalr	-1902(ra) # 8000053c <panic>
    dp->nlink--;
    80005cb2:	04a4d783          	lhu	a5,74(s1)
    80005cb6:	37fd                	addw	a5,a5,-1
    80005cb8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cbc:	8526                	mv	a0,s1
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	ff0080e7          	jalr	-16(ra) # 80003cae <iupdate>
    80005cc6:	b781                	j	80005c06 <sys_unlink+0xe0>
    return -1;
    80005cc8:	557d                	li	a0,-1
    80005cca:	a005                	j	80005cea <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ccc:	854a                	mv	a0,s2
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	30e080e7          	jalr	782(ra) # 80003fdc <iunlockput>
  iunlockput(dp);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	304080e7          	jalr	772(ra) # 80003fdc <iunlockput>
  end_op();
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	aba080e7          	jalr	-1350(ra) # 8000479a <end_op>
  return -1;
    80005ce8:	557d                	li	a0,-1
}
    80005cea:	70ae                	ld	ra,232(sp)
    80005cec:	740e                	ld	s0,224(sp)
    80005cee:	64ee                	ld	s1,216(sp)
    80005cf0:	694e                	ld	s2,208(sp)
    80005cf2:	69ae                	ld	s3,200(sp)
    80005cf4:	616d                	add	sp,sp,240
    80005cf6:	8082                	ret

0000000080005cf8 <sys_open>:

uint64
sys_open(void)
{
    80005cf8:	7131                	add	sp,sp,-192
    80005cfa:	fd06                	sd	ra,184(sp)
    80005cfc:	f922                	sd	s0,176(sp)
    80005cfe:	f526                	sd	s1,168(sp)
    80005d00:	f14a                	sd	s2,160(sp)
    80005d02:	ed4e                	sd	s3,152(sp)
    80005d04:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d06:	f4c40593          	add	a1,s0,-180
    80005d0a:	4505                	li	a0,1
    80005d0c:	ffffd097          	auipc	ra,0xffffd
    80005d10:	434080e7          	jalr	1076(ra) # 80003140 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d14:	08000613          	li	a2,128
    80005d18:	f5040593          	add	a1,s0,-176
    80005d1c:	4501                	li	a0,0
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	462080e7          	jalr	1122(ra) # 80003180 <argstr>
    80005d26:	87aa                	mv	a5,a0
    return -1;
    80005d28:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d2a:	0a07c863          	bltz	a5,80005dda <sys_open+0xe2>

  begin_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	9f2080e7          	jalr	-1550(ra) # 80004720 <begin_op>

  if(omode & O_CREATE){
    80005d36:	f4c42783          	lw	a5,-180(s0)
    80005d3a:	2007f793          	and	a5,a5,512
    80005d3e:	cbdd                	beqz	a5,80005df4 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005d40:	4681                	li	a3,0
    80005d42:	4601                	li	a2,0
    80005d44:	4589                	li	a1,2
    80005d46:	f5040513          	add	a0,s0,-176
    80005d4a:	00000097          	auipc	ra,0x0
    80005d4e:	958080e7          	jalr	-1704(ra) # 800056a2 <create>
    80005d52:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d54:	c951                	beqz	a0,80005de8 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d56:	04449703          	lh	a4,68(s1)
    80005d5a:	478d                	li	a5,3
    80005d5c:	00f71763          	bne	a4,a5,80005d6a <sys_open+0x72>
    80005d60:	0464d703          	lhu	a4,70(s1)
    80005d64:	47a5                	li	a5,9
    80005d66:	0ce7ec63          	bltu	a5,a4,80005e3e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	dbe080e7          	jalr	-578(ra) # 80004b28 <filealloc>
    80005d72:	892a                	mv	s2,a0
    80005d74:	c56d                	beqz	a0,80005e5e <sys_open+0x166>
    80005d76:	00000097          	auipc	ra,0x0
    80005d7a:	8ea080e7          	jalr	-1814(ra) # 80005660 <fdalloc>
    80005d7e:	89aa                	mv	s3,a0
    80005d80:	0c054a63          	bltz	a0,80005e54 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d84:	04449703          	lh	a4,68(s1)
    80005d88:	478d                	li	a5,3
    80005d8a:	0ef70563          	beq	a4,a5,80005e74 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d8e:	4789                	li	a5,2
    80005d90:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005d94:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005d98:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005d9c:	f4c42783          	lw	a5,-180(s0)
    80005da0:	0017c713          	xor	a4,a5,1
    80005da4:	8b05                	and	a4,a4,1
    80005da6:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005daa:	0037f713          	and	a4,a5,3
    80005dae:	00e03733          	snez	a4,a4
    80005db2:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005db6:	4007f793          	and	a5,a5,1024
    80005dba:	c791                	beqz	a5,80005dc6 <sys_open+0xce>
    80005dbc:	04449703          	lh	a4,68(s1)
    80005dc0:	4789                	li	a5,2
    80005dc2:	0cf70063          	beq	a4,a5,80005e82 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	074080e7          	jalr	116(ra) # 80003e3c <iunlock>
  end_op();
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	9ca080e7          	jalr	-1590(ra) # 8000479a <end_op>

  return fd;
    80005dd8:	854e                	mv	a0,s3
}
    80005dda:	70ea                	ld	ra,184(sp)
    80005ddc:	744a                	ld	s0,176(sp)
    80005dde:	74aa                	ld	s1,168(sp)
    80005de0:	790a                	ld	s2,160(sp)
    80005de2:	69ea                	ld	s3,152(sp)
    80005de4:	6129                	add	sp,sp,192
    80005de6:	8082                	ret
      end_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	9b2080e7          	jalr	-1614(ra) # 8000479a <end_op>
      return -1;
    80005df0:	557d                	li	a0,-1
    80005df2:	b7e5                	j	80005dda <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005df4:	f5040513          	add	a0,s0,-176
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	728080e7          	jalr	1832(ra) # 80004520 <namei>
    80005e00:	84aa                	mv	s1,a0
    80005e02:	c905                	beqz	a0,80005e32 <sys_open+0x13a>
    ilock(ip);
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	f76080e7          	jalr	-138(ra) # 80003d7a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e0c:	04449703          	lh	a4,68(s1)
    80005e10:	4785                	li	a5,1
    80005e12:	f4f712e3          	bne	a4,a5,80005d56 <sys_open+0x5e>
    80005e16:	f4c42783          	lw	a5,-180(s0)
    80005e1a:	dba1                	beqz	a5,80005d6a <sys_open+0x72>
      iunlockput(ip);
    80005e1c:	8526                	mv	a0,s1
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	1be080e7          	jalr	446(ra) # 80003fdc <iunlockput>
      end_op();
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	974080e7          	jalr	-1676(ra) # 8000479a <end_op>
      return -1;
    80005e2e:	557d                	li	a0,-1
    80005e30:	b76d                	j	80005dda <sys_open+0xe2>
      end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	968080e7          	jalr	-1688(ra) # 8000479a <end_op>
      return -1;
    80005e3a:	557d                	li	a0,-1
    80005e3c:	bf79                	j	80005dda <sys_open+0xe2>
    iunlockput(ip);
    80005e3e:	8526                	mv	a0,s1
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	19c080e7          	jalr	412(ra) # 80003fdc <iunlockput>
    end_op();
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	952080e7          	jalr	-1710(ra) # 8000479a <end_op>
    return -1;
    80005e50:	557d                	li	a0,-1
    80005e52:	b761                	j	80005dda <sys_open+0xe2>
      fileclose(f);
    80005e54:	854a                	mv	a0,s2
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	d8e080e7          	jalr	-626(ra) # 80004be4 <fileclose>
    iunlockput(ip);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	17c080e7          	jalr	380(ra) # 80003fdc <iunlockput>
    end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	932080e7          	jalr	-1742(ra) # 8000479a <end_op>
    return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	b7a5                	j	80005dda <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005e74:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005e78:	04649783          	lh	a5,70(s1)
    80005e7c:	02f91223          	sh	a5,36(s2)
    80005e80:	bf21                	j	80005d98 <sys_open+0xa0>
    itrunc(ip);
    80005e82:	8526                	mv	a0,s1
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	004080e7          	jalr	4(ra) # 80003e88 <itrunc>
    80005e8c:	bf2d                	j	80005dc6 <sys_open+0xce>

0000000080005e8e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e8e:	7175                	add	sp,sp,-144
    80005e90:	e506                	sd	ra,136(sp)
    80005e92:	e122                	sd	s0,128(sp)
    80005e94:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	88a080e7          	jalr	-1910(ra) # 80004720 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e9e:	08000613          	li	a2,128
    80005ea2:	f7040593          	add	a1,s0,-144
    80005ea6:	4501                	li	a0,0
    80005ea8:	ffffd097          	auipc	ra,0xffffd
    80005eac:	2d8080e7          	jalr	728(ra) # 80003180 <argstr>
    80005eb0:	02054963          	bltz	a0,80005ee2 <sys_mkdir+0x54>
    80005eb4:	4681                	li	a3,0
    80005eb6:	4601                	li	a2,0
    80005eb8:	4585                	li	a1,1
    80005eba:	f7040513          	add	a0,s0,-144
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	7e4080e7          	jalr	2020(ra) # 800056a2 <create>
    80005ec6:	cd11                	beqz	a0,80005ee2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	114080e7          	jalr	276(ra) # 80003fdc <iunlockput>
  end_op();
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	8ca080e7          	jalr	-1846(ra) # 8000479a <end_op>
  return 0;
    80005ed8:	4501                	li	a0,0
}
    80005eda:	60aa                	ld	ra,136(sp)
    80005edc:	640a                	ld	s0,128(sp)
    80005ede:	6149                	add	sp,sp,144
    80005ee0:	8082                	ret
    end_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	8b8080e7          	jalr	-1864(ra) # 8000479a <end_op>
    return -1;
    80005eea:	557d                	li	a0,-1
    80005eec:	b7fd                	j	80005eda <sys_mkdir+0x4c>

0000000080005eee <sys_mknod>:

uint64
sys_mknod(void)
{
    80005eee:	7135                	add	sp,sp,-160
    80005ef0:	ed06                	sd	ra,152(sp)
    80005ef2:	e922                	sd	s0,144(sp)
    80005ef4:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	82a080e7          	jalr	-2006(ra) # 80004720 <begin_op>
  argint(1, &major);
    80005efe:	f6c40593          	add	a1,s0,-148
    80005f02:	4505                	li	a0,1
    80005f04:	ffffd097          	auipc	ra,0xffffd
    80005f08:	23c080e7          	jalr	572(ra) # 80003140 <argint>
  argint(2, &minor);
    80005f0c:	f6840593          	add	a1,s0,-152
    80005f10:	4509                	li	a0,2
    80005f12:	ffffd097          	auipc	ra,0xffffd
    80005f16:	22e080e7          	jalr	558(ra) # 80003140 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f1a:	08000613          	li	a2,128
    80005f1e:	f7040593          	add	a1,s0,-144
    80005f22:	4501                	li	a0,0
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	25c080e7          	jalr	604(ra) # 80003180 <argstr>
    80005f2c:	02054b63          	bltz	a0,80005f62 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f30:	f6841683          	lh	a3,-152(s0)
    80005f34:	f6c41603          	lh	a2,-148(s0)
    80005f38:	458d                	li	a1,3
    80005f3a:	f7040513          	add	a0,s0,-144
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	764080e7          	jalr	1892(ra) # 800056a2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f46:	cd11                	beqz	a0,80005f62 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f48:	ffffe097          	auipc	ra,0xffffe
    80005f4c:	094080e7          	jalr	148(ra) # 80003fdc <iunlockput>
  end_op();
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	84a080e7          	jalr	-1974(ra) # 8000479a <end_op>
  return 0;
    80005f58:	4501                	li	a0,0
}
    80005f5a:	60ea                	ld	ra,152(sp)
    80005f5c:	644a                	ld	s0,144(sp)
    80005f5e:	610d                	add	sp,sp,160
    80005f60:	8082                	ret
    end_op();
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	838080e7          	jalr	-1992(ra) # 8000479a <end_op>
    return -1;
    80005f6a:	557d                	li	a0,-1
    80005f6c:	b7fd                	j	80005f5a <sys_mknod+0x6c>

0000000080005f6e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f6e:	7135                	add	sp,sp,-160
    80005f70:	ed06                	sd	ra,152(sp)
    80005f72:	e922                	sd	s0,144(sp)
    80005f74:	e526                	sd	s1,136(sp)
    80005f76:	e14a                	sd	s2,128(sp)
    80005f78:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f7a:	ffffc097          	auipc	ra,0xffffc
    80005f7e:	b9a080e7          	jalr	-1126(ra) # 80001b14 <myproc>
    80005f82:	892a                	mv	s2,a0
  
  begin_op();
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	79c080e7          	jalr	1948(ra) # 80004720 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f8c:	08000613          	li	a2,128
    80005f90:	f6040593          	add	a1,s0,-160
    80005f94:	4501                	li	a0,0
    80005f96:	ffffd097          	auipc	ra,0xffffd
    80005f9a:	1ea080e7          	jalr	490(ra) # 80003180 <argstr>
    80005f9e:	04054b63          	bltz	a0,80005ff4 <sys_chdir+0x86>
    80005fa2:	f6040513          	add	a0,s0,-160
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	57a080e7          	jalr	1402(ra) # 80004520 <namei>
    80005fae:	84aa                	mv	s1,a0
    80005fb0:	c131                	beqz	a0,80005ff4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	dc8080e7          	jalr	-568(ra) # 80003d7a <ilock>
  if(ip->type != T_DIR){
    80005fba:	04449703          	lh	a4,68(s1)
    80005fbe:	4785                	li	a5,1
    80005fc0:	04f71063          	bne	a4,a5,80006000 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fc4:	8526                	mv	a0,s1
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	e76080e7          	jalr	-394(ra) # 80003e3c <iunlock>
  iput(p->cwd);
    80005fce:	15093503          	ld	a0,336(s2)
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	f62080e7          	jalr	-158(ra) # 80003f34 <iput>
  end_op();
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	7c0080e7          	jalr	1984(ra) # 8000479a <end_op>
  p->cwd = ip;
    80005fe2:	14993823          	sd	s1,336(s2)
  return 0;
    80005fe6:	4501                	li	a0,0
}
    80005fe8:	60ea                	ld	ra,152(sp)
    80005fea:	644a                	ld	s0,144(sp)
    80005fec:	64aa                	ld	s1,136(sp)
    80005fee:	690a                	ld	s2,128(sp)
    80005ff0:	610d                	add	sp,sp,160
    80005ff2:	8082                	ret
    end_op();
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	7a6080e7          	jalr	1958(ra) # 8000479a <end_op>
    return -1;
    80005ffc:	557d                	li	a0,-1
    80005ffe:	b7ed                	j	80005fe8 <sys_chdir+0x7a>
    iunlockput(ip);
    80006000:	8526                	mv	a0,s1
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	fda080e7          	jalr	-38(ra) # 80003fdc <iunlockput>
    end_op();
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	790080e7          	jalr	1936(ra) # 8000479a <end_op>
    return -1;
    80006012:	557d                	li	a0,-1
    80006014:	bfd1                	j	80005fe8 <sys_chdir+0x7a>

0000000080006016 <sys_exec>:

uint64
sys_exec(void)
{
    80006016:	7121                	add	sp,sp,-448
    80006018:	ff06                	sd	ra,440(sp)
    8000601a:	fb22                	sd	s0,432(sp)
    8000601c:	f726                	sd	s1,424(sp)
    8000601e:	f34a                	sd	s2,416(sp)
    80006020:	ef4e                	sd	s3,408(sp)
    80006022:	eb52                	sd	s4,400(sp)
    80006024:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006026:	e4840593          	add	a1,s0,-440
    8000602a:	4505                	li	a0,1
    8000602c:	ffffd097          	auipc	ra,0xffffd
    80006030:	134080e7          	jalr	308(ra) # 80003160 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006034:	08000613          	li	a2,128
    80006038:	f5040593          	add	a1,s0,-176
    8000603c:	4501                	li	a0,0
    8000603e:	ffffd097          	auipc	ra,0xffffd
    80006042:	142080e7          	jalr	322(ra) # 80003180 <argstr>
    80006046:	87aa                	mv	a5,a0
    return -1;
    80006048:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000604a:	0c07c263          	bltz	a5,8000610e <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    8000604e:	10000613          	li	a2,256
    80006052:	4581                	li	a1,0
    80006054:	e5040513          	add	a0,s0,-432
    80006058:	ffffb097          	auipc	ra,0xffffb
    8000605c:	d7e080e7          	jalr	-642(ra) # 80000dd6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006060:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006064:	89a6                	mv	s3,s1
    80006066:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006068:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000606c:	00391513          	sll	a0,s2,0x3
    80006070:	e4040593          	add	a1,s0,-448
    80006074:	e4843783          	ld	a5,-440(s0)
    80006078:	953e                	add	a0,a0,a5
    8000607a:	ffffd097          	auipc	ra,0xffffd
    8000607e:	028080e7          	jalr	40(ra) # 800030a2 <fetchaddr>
    80006082:	02054a63          	bltz	a0,800060b6 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006086:	e4043783          	ld	a5,-448(s0)
    8000608a:	c3b9                	beqz	a5,800060d0 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	b22080e7          	jalr	-1246(ra) # 80000bae <kalloc>
    80006094:	85aa                	mv	a1,a0
    80006096:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000609a:	cd11                	beqz	a0,800060b6 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000609c:	6605                	lui	a2,0x1
    8000609e:	e4043503          	ld	a0,-448(s0)
    800060a2:	ffffd097          	auipc	ra,0xffffd
    800060a6:	052080e7          	jalr	82(ra) # 800030f4 <fetchstr>
    800060aa:	00054663          	bltz	a0,800060b6 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800060ae:	0905                	add	s2,s2,1
    800060b0:	09a1                	add	s3,s3,8
    800060b2:	fb491de3          	bne	s2,s4,8000606c <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060b6:	f5040913          	add	s2,s0,-176
    800060ba:	6088                	ld	a0,0(s1)
    800060bc:	c921                	beqz	a0,8000610c <sys_exec+0xf6>
    kfree(argv[i]);
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	926080e7          	jalr	-1754(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c6:	04a1                	add	s1,s1,8
    800060c8:	ff2499e3          	bne	s1,s2,800060ba <sys_exec+0xa4>
  return -1;
    800060cc:	557d                	li	a0,-1
    800060ce:	a081                	j	8000610e <sys_exec+0xf8>
      argv[i] = 0;
    800060d0:	0009079b          	sext.w	a5,s2
    800060d4:	078e                	sll	a5,a5,0x3
    800060d6:	fd078793          	add	a5,a5,-48
    800060da:	97a2                	add	a5,a5,s0
    800060dc:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800060e0:	e5040593          	add	a1,s0,-432
    800060e4:	f5040513          	add	a0,s0,-176
    800060e8:	fffff097          	auipc	ra,0xfffff
    800060ec:	172080e7          	jalr	370(ra) # 8000525a <exec>
    800060f0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060f2:	f5040993          	add	s3,s0,-176
    800060f6:	6088                	ld	a0,0(s1)
    800060f8:	c901                	beqz	a0,80006108 <sys_exec+0xf2>
    kfree(argv[i]);
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	8ea080e7          	jalr	-1814(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006102:	04a1                	add	s1,s1,8
    80006104:	ff3499e3          	bne	s1,s3,800060f6 <sys_exec+0xe0>
  return ret;
    80006108:	854a                	mv	a0,s2
    8000610a:	a011                	j	8000610e <sys_exec+0xf8>
  return -1;
    8000610c:	557d                	li	a0,-1
}
    8000610e:	70fa                	ld	ra,440(sp)
    80006110:	745a                	ld	s0,432(sp)
    80006112:	74ba                	ld	s1,424(sp)
    80006114:	791a                	ld	s2,416(sp)
    80006116:	69fa                	ld	s3,408(sp)
    80006118:	6a5a                	ld	s4,400(sp)
    8000611a:	6139                	add	sp,sp,448
    8000611c:	8082                	ret

000000008000611e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000611e:	7139                	add	sp,sp,-64
    80006120:	fc06                	sd	ra,56(sp)
    80006122:	f822                	sd	s0,48(sp)
    80006124:	f426                	sd	s1,40(sp)
    80006126:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006128:	ffffc097          	auipc	ra,0xffffc
    8000612c:	9ec080e7          	jalr	-1556(ra) # 80001b14 <myproc>
    80006130:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006132:	fd840593          	add	a1,s0,-40
    80006136:	4501                	li	a0,0
    80006138:	ffffd097          	auipc	ra,0xffffd
    8000613c:	028080e7          	jalr	40(ra) # 80003160 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006140:	fc840593          	add	a1,s0,-56
    80006144:	fd040513          	add	a0,s0,-48
    80006148:	fffff097          	auipc	ra,0xfffff
    8000614c:	dc8080e7          	jalr	-568(ra) # 80004f10 <pipealloc>
    return -1;
    80006150:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006152:	0c054463          	bltz	a0,8000621a <sys_pipe+0xfc>
  fd0 = -1;
    80006156:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000615a:	fd043503          	ld	a0,-48(s0)
    8000615e:	fffff097          	auipc	ra,0xfffff
    80006162:	502080e7          	jalr	1282(ra) # 80005660 <fdalloc>
    80006166:	fca42223          	sw	a0,-60(s0)
    8000616a:	08054b63          	bltz	a0,80006200 <sys_pipe+0xe2>
    8000616e:	fc843503          	ld	a0,-56(s0)
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	4ee080e7          	jalr	1262(ra) # 80005660 <fdalloc>
    8000617a:	fca42023          	sw	a0,-64(s0)
    8000617e:	06054863          	bltz	a0,800061ee <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006182:	4691                	li	a3,4
    80006184:	fc440613          	add	a2,s0,-60
    80006188:	fd843583          	ld	a1,-40(s0)
    8000618c:	68a8                	ld	a0,80(s1)
    8000618e:	ffffb097          	auipc	ra,0xffffb
    80006192:	60e080e7          	jalr	1550(ra) # 8000179c <copyout>
    80006196:	02054063          	bltz	a0,800061b6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000619a:	4691                	li	a3,4
    8000619c:	fc040613          	add	a2,s0,-64
    800061a0:	fd843583          	ld	a1,-40(s0)
    800061a4:	0591                	add	a1,a1,4
    800061a6:	68a8                	ld	a0,80(s1)
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	5f4080e7          	jalr	1524(ra) # 8000179c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061b0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061b2:	06055463          	bgez	a0,8000621a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061b6:	fc442783          	lw	a5,-60(s0)
    800061ba:	07e9                	add	a5,a5,26
    800061bc:	078e                	sll	a5,a5,0x3
    800061be:	97a6                	add	a5,a5,s1
    800061c0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061c4:	fc042783          	lw	a5,-64(s0)
    800061c8:	07e9                	add	a5,a5,26
    800061ca:	078e                	sll	a5,a5,0x3
    800061cc:	94be                	add	s1,s1,a5
    800061ce:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061d2:	fd043503          	ld	a0,-48(s0)
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	a0e080e7          	jalr	-1522(ra) # 80004be4 <fileclose>
    fileclose(wf);
    800061de:	fc843503          	ld	a0,-56(s0)
    800061e2:	fffff097          	auipc	ra,0xfffff
    800061e6:	a02080e7          	jalr	-1534(ra) # 80004be4 <fileclose>
    return -1;
    800061ea:	57fd                	li	a5,-1
    800061ec:	a03d                	j	8000621a <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061ee:	fc442783          	lw	a5,-60(s0)
    800061f2:	0007c763          	bltz	a5,80006200 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061f6:	07e9                	add	a5,a5,26
    800061f8:	078e                	sll	a5,a5,0x3
    800061fa:	97a6                	add	a5,a5,s1
    800061fc:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006200:	fd043503          	ld	a0,-48(s0)
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	9e0080e7          	jalr	-1568(ra) # 80004be4 <fileclose>
    fileclose(wf);
    8000620c:	fc843503          	ld	a0,-56(s0)
    80006210:	fffff097          	auipc	ra,0xfffff
    80006214:	9d4080e7          	jalr	-1580(ra) # 80004be4 <fileclose>
    return -1;
    80006218:	57fd                	li	a5,-1
}
    8000621a:	853e                	mv	a0,a5
    8000621c:	70e2                	ld	ra,56(sp)
    8000621e:	7442                	ld	s0,48(sp)
    80006220:	74a2                	ld	s1,40(sp)
    80006222:	6121                	add	sp,sp,64
    80006224:	8082                	ret
	...

0000000080006230 <kernelvec>:
    80006230:	7111                	add	sp,sp,-256
    80006232:	e006                	sd	ra,0(sp)
    80006234:	e40a                	sd	sp,8(sp)
    80006236:	e80e                	sd	gp,16(sp)
    80006238:	ec12                	sd	tp,24(sp)
    8000623a:	f016                	sd	t0,32(sp)
    8000623c:	f41a                	sd	t1,40(sp)
    8000623e:	f81e                	sd	t2,48(sp)
    80006240:	fc22                	sd	s0,56(sp)
    80006242:	e0a6                	sd	s1,64(sp)
    80006244:	e4aa                	sd	a0,72(sp)
    80006246:	e8ae                	sd	a1,80(sp)
    80006248:	ecb2                	sd	a2,88(sp)
    8000624a:	f0b6                	sd	a3,96(sp)
    8000624c:	f4ba                	sd	a4,104(sp)
    8000624e:	f8be                	sd	a5,112(sp)
    80006250:	fcc2                	sd	a6,120(sp)
    80006252:	e146                	sd	a7,128(sp)
    80006254:	e54a                	sd	s2,136(sp)
    80006256:	e94e                	sd	s3,144(sp)
    80006258:	ed52                	sd	s4,152(sp)
    8000625a:	f156                	sd	s5,160(sp)
    8000625c:	f55a                	sd	s6,168(sp)
    8000625e:	f95e                	sd	s7,176(sp)
    80006260:	fd62                	sd	s8,184(sp)
    80006262:	e1e6                	sd	s9,192(sp)
    80006264:	e5ea                	sd	s10,200(sp)
    80006266:	e9ee                	sd	s11,208(sp)
    80006268:	edf2                	sd	t3,216(sp)
    8000626a:	f1f6                	sd	t4,224(sp)
    8000626c:	f5fa                	sd	t5,232(sp)
    8000626e:	f9fe                	sd	t6,240(sp)
    80006270:	cfffc0ef          	jal	80002f6e <kerneltrap>
    80006274:	6082                	ld	ra,0(sp)
    80006276:	6122                	ld	sp,8(sp)
    80006278:	61c2                	ld	gp,16(sp)
    8000627a:	7282                	ld	t0,32(sp)
    8000627c:	7322                	ld	t1,40(sp)
    8000627e:	73c2                	ld	t2,48(sp)
    80006280:	7462                	ld	s0,56(sp)
    80006282:	6486                	ld	s1,64(sp)
    80006284:	6526                	ld	a0,72(sp)
    80006286:	65c6                	ld	a1,80(sp)
    80006288:	6666                	ld	a2,88(sp)
    8000628a:	7686                	ld	a3,96(sp)
    8000628c:	7726                	ld	a4,104(sp)
    8000628e:	77c6                	ld	a5,112(sp)
    80006290:	7866                	ld	a6,120(sp)
    80006292:	688a                	ld	a7,128(sp)
    80006294:	692a                	ld	s2,136(sp)
    80006296:	69ca                	ld	s3,144(sp)
    80006298:	6a6a                	ld	s4,152(sp)
    8000629a:	7a8a                	ld	s5,160(sp)
    8000629c:	7b2a                	ld	s6,168(sp)
    8000629e:	7bca                	ld	s7,176(sp)
    800062a0:	7c6a                	ld	s8,184(sp)
    800062a2:	6c8e                	ld	s9,192(sp)
    800062a4:	6d2e                	ld	s10,200(sp)
    800062a6:	6dce                	ld	s11,208(sp)
    800062a8:	6e6e                	ld	t3,216(sp)
    800062aa:	7e8e                	ld	t4,224(sp)
    800062ac:	7f2e                	ld	t5,232(sp)
    800062ae:	7fce                	ld	t6,240(sp)
    800062b0:	6111                	add	sp,sp,256
    800062b2:	10200073          	sret
    800062b6:	00000013          	nop
    800062ba:	00000013          	nop
    800062be:	0001                	nop

00000000800062c0 <timervec>:
    800062c0:	34051573          	csrrw	a0,mscratch,a0
    800062c4:	e10c                	sd	a1,0(a0)
    800062c6:	e510                	sd	a2,8(a0)
    800062c8:	e914                	sd	a3,16(a0)
    800062ca:	6d0c                	ld	a1,24(a0)
    800062cc:	7110                	ld	a2,32(a0)
    800062ce:	6194                	ld	a3,0(a1)
    800062d0:	96b2                	add	a3,a3,a2
    800062d2:	e194                	sd	a3,0(a1)
    800062d4:	4589                	li	a1,2
    800062d6:	14459073          	csrw	sip,a1
    800062da:	6914                	ld	a3,16(a0)
    800062dc:	6510                	ld	a2,8(a0)
    800062de:	610c                	ld	a1,0(a0)
    800062e0:	34051573          	csrrw	a0,mscratch,a0
    800062e4:	30200073          	mret
	...

00000000800062ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ea:	1141                	add	sp,sp,-16
    800062ec:	e422                	sd	s0,8(sp)
    800062ee:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062f0:	0c0007b7          	lui	a5,0xc000
    800062f4:	4705                	li	a4,1
    800062f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062f8:	c3d8                	sw	a4,4(a5)
}
    800062fa:	6422                	ld	s0,8(sp)
    800062fc:	0141                	add	sp,sp,16
    800062fe:	8082                	ret

0000000080006300 <plicinithart>:

void
plicinithart(void)
{
    80006300:	1141                	add	sp,sp,-16
    80006302:	e406                	sd	ra,8(sp)
    80006304:	e022                	sd	s0,0(sp)
    80006306:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006308:	ffffb097          	auipc	ra,0xffffb
    8000630c:	7e0080e7          	jalr	2016(ra) # 80001ae8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006310:	0085171b          	sllw	a4,a0,0x8
    80006314:	0c0027b7          	lui	a5,0xc002
    80006318:	97ba                	add	a5,a5,a4
    8000631a:	40200713          	li	a4,1026
    8000631e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006322:	00d5151b          	sllw	a0,a0,0xd
    80006326:	0c2017b7          	lui	a5,0xc201
    8000632a:	97aa                	add	a5,a5,a0
    8000632c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006330:	60a2                	ld	ra,8(sp)
    80006332:	6402                	ld	s0,0(sp)
    80006334:	0141                	add	sp,sp,16
    80006336:	8082                	ret

0000000080006338 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006338:	1141                	add	sp,sp,-16
    8000633a:	e406                	sd	ra,8(sp)
    8000633c:	e022                	sd	s0,0(sp)
    8000633e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006340:	ffffb097          	auipc	ra,0xffffb
    80006344:	7a8080e7          	jalr	1960(ra) # 80001ae8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006348:	00d5151b          	sllw	a0,a0,0xd
    8000634c:	0c2017b7          	lui	a5,0xc201
    80006350:	97aa                	add	a5,a5,a0
  return irq;
}
    80006352:	43c8                	lw	a0,4(a5)
    80006354:	60a2                	ld	ra,8(sp)
    80006356:	6402                	ld	s0,0(sp)
    80006358:	0141                	add	sp,sp,16
    8000635a:	8082                	ret

000000008000635c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000635c:	1101                	add	sp,sp,-32
    8000635e:	ec06                	sd	ra,24(sp)
    80006360:	e822                	sd	s0,16(sp)
    80006362:	e426                	sd	s1,8(sp)
    80006364:	1000                	add	s0,sp,32
    80006366:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006368:	ffffb097          	auipc	ra,0xffffb
    8000636c:	780080e7          	jalr	1920(ra) # 80001ae8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006370:	00d5151b          	sllw	a0,a0,0xd
    80006374:	0c2017b7          	lui	a5,0xc201
    80006378:	97aa                	add	a5,a5,a0
    8000637a:	c3c4                	sw	s1,4(a5)
}
    8000637c:	60e2                	ld	ra,24(sp)
    8000637e:	6442                	ld	s0,16(sp)
    80006380:	64a2                	ld	s1,8(sp)
    80006382:	6105                	add	sp,sp,32
    80006384:	8082                	ret

0000000080006386 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006386:	1141                	add	sp,sp,-16
    80006388:	e406                	sd	ra,8(sp)
    8000638a:	e022                	sd	s0,0(sp)
    8000638c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000638e:	479d                	li	a5,7
    80006390:	04a7cc63          	blt	a5,a0,800063e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006394:	0023c797          	auipc	a5,0x23c
    80006398:	4b478793          	add	a5,a5,1204 # 80242848 <disk>
    8000639c:	97aa                	add	a5,a5,a0
    8000639e:	0187c783          	lbu	a5,24(a5)
    800063a2:	ebb9                	bnez	a5,800063f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063a4:	00451693          	sll	a3,a0,0x4
    800063a8:	0023c797          	auipc	a5,0x23c
    800063ac:	4a078793          	add	a5,a5,1184 # 80242848 <disk>
    800063b0:	6398                	ld	a4,0(a5)
    800063b2:	9736                	add	a4,a4,a3
    800063b4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800063b8:	6398                	ld	a4,0(a5)
    800063ba:	9736                	add	a4,a4,a3
    800063bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063c8:	97aa                	add	a5,a5,a0
    800063ca:	4705                	li	a4,1
    800063cc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063d0:	0023c517          	auipc	a0,0x23c
    800063d4:	49050513          	add	a0,a0,1168 # 80242860 <disk+0x18>
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	05c080e7          	jalr	92(ra) # 80002434 <wakeup>
}
    800063e0:	60a2                	ld	ra,8(sp)
    800063e2:	6402                	ld	s0,0(sp)
    800063e4:	0141                	add	sp,sp,16
    800063e6:	8082                	ret
    panic("free_desc 1");
    800063e8:	00002517          	auipc	a0,0x2
    800063ec:	38050513          	add	a0,a0,896 # 80008768 <syscalls+0x308>
    800063f0:	ffffa097          	auipc	ra,0xffffa
    800063f4:	14c080e7          	jalr	332(ra) # 8000053c <panic>
    panic("free_desc 2");
    800063f8:	00002517          	auipc	a0,0x2
    800063fc:	38050513          	add	a0,a0,896 # 80008778 <syscalls+0x318>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	13c080e7          	jalr	316(ra) # 8000053c <panic>

0000000080006408 <virtio_disk_init>:
{
    80006408:	1101                	add	sp,sp,-32
    8000640a:	ec06                	sd	ra,24(sp)
    8000640c:	e822                	sd	s0,16(sp)
    8000640e:	e426                	sd	s1,8(sp)
    80006410:	e04a                	sd	s2,0(sp)
    80006412:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006414:	00002597          	auipc	a1,0x2
    80006418:	37458593          	add	a1,a1,884 # 80008788 <syscalls+0x328>
    8000641c:	0023c517          	auipc	a0,0x23c
    80006420:	55450513          	add	a0,a0,1364 # 80242970 <disk+0x128>
    80006424:	ffffb097          	auipc	ra,0xffffb
    80006428:	826080e7          	jalr	-2010(ra) # 80000c4a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000642c:	100017b7          	lui	a5,0x10001
    80006430:	4398                	lw	a4,0(a5)
    80006432:	2701                	sext.w	a4,a4
    80006434:	747277b7          	lui	a5,0x74727
    80006438:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000643c:	14f71b63          	bne	a4,a5,80006592 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006440:	100017b7          	lui	a5,0x10001
    80006444:	43dc                	lw	a5,4(a5)
    80006446:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006448:	4709                	li	a4,2
    8000644a:	14e79463          	bne	a5,a4,80006592 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000644e:	100017b7          	lui	a5,0x10001
    80006452:	479c                	lw	a5,8(a5)
    80006454:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006456:	12e79e63          	bne	a5,a4,80006592 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000645a:	100017b7          	lui	a5,0x10001
    8000645e:	47d8                	lw	a4,12(a5)
    80006460:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006462:	554d47b7          	lui	a5,0x554d4
    80006466:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000646a:	12f71463          	bne	a4,a5,80006592 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000646e:	100017b7          	lui	a5,0x10001
    80006472:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006476:	4705                	li	a4,1
    80006478:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000647a:	470d                	li	a4,3
    8000647c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000647e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006480:	c7ffe6b7          	lui	a3,0xc7ffe
    80006484:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbbdd7>
    80006488:	8f75                	and	a4,a4,a3
    8000648a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000648c:	472d                	li	a4,11
    8000648e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006490:	5bbc                	lw	a5,112(a5)
    80006492:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006496:	8ba1                	and	a5,a5,8
    80006498:	10078563          	beqz	a5,800065a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000649c:	100017b7          	lui	a5,0x10001
    800064a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064a4:	43fc                	lw	a5,68(a5)
    800064a6:	2781                	sext.w	a5,a5
    800064a8:	10079563          	bnez	a5,800065b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064ac:	100017b7          	lui	a5,0x10001
    800064b0:	5bdc                	lw	a5,52(a5)
    800064b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800064b4:	10078763          	beqz	a5,800065c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800064b8:	471d                	li	a4,7
    800064ba:	10f77c63          	bgeu	a4,a5,800065d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	6f0080e7          	jalr	1776(ra) # 80000bae <kalloc>
    800064c6:	0023c497          	auipc	s1,0x23c
    800064ca:	38248493          	add	s1,s1,898 # 80242848 <disk>
    800064ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	6de080e7          	jalr	1758(ra) # 80000bae <kalloc>
    800064d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	6d4080e7          	jalr	1748(ra) # 80000bae <kalloc>
    800064e2:	87aa                	mv	a5,a0
    800064e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064e6:	6088                	ld	a0,0(s1)
    800064e8:	cd6d                	beqz	a0,800065e2 <virtio_disk_init+0x1da>
    800064ea:	0023c717          	auipc	a4,0x23c
    800064ee:	36673703          	ld	a4,870(a4) # 80242850 <disk+0x8>
    800064f2:	cb65                	beqz	a4,800065e2 <virtio_disk_init+0x1da>
    800064f4:	c7fd                	beqz	a5,800065e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800064f6:	6605                	lui	a2,0x1
    800064f8:	4581                	li	a1,0
    800064fa:	ffffb097          	auipc	ra,0xffffb
    800064fe:	8dc080e7          	jalr	-1828(ra) # 80000dd6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006502:	0023c497          	auipc	s1,0x23c
    80006506:	34648493          	add	s1,s1,838 # 80242848 <disk>
    8000650a:	6605                	lui	a2,0x1
    8000650c:	4581                	li	a1,0
    8000650e:	6488                	ld	a0,8(s1)
    80006510:	ffffb097          	auipc	ra,0xffffb
    80006514:	8c6080e7          	jalr	-1850(ra) # 80000dd6 <memset>
  memset(disk.used, 0, PGSIZE);
    80006518:	6605                	lui	a2,0x1
    8000651a:	4581                	li	a1,0
    8000651c:	6888                	ld	a0,16(s1)
    8000651e:	ffffb097          	auipc	ra,0xffffb
    80006522:	8b8080e7          	jalr	-1864(ra) # 80000dd6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006526:	100017b7          	lui	a5,0x10001
    8000652a:	4721                	li	a4,8
    8000652c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000652e:	4098                	lw	a4,0(s1)
    80006530:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006534:	40d8                	lw	a4,4(s1)
    80006536:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000653a:	6498                	ld	a4,8(s1)
    8000653c:	0007069b          	sext.w	a3,a4
    80006540:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006544:	9701                	sra	a4,a4,0x20
    80006546:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000654a:	6898                	ld	a4,16(s1)
    8000654c:	0007069b          	sext.w	a3,a4
    80006550:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006554:	9701                	sra	a4,a4,0x20
    80006556:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000655a:	4705                	li	a4,1
    8000655c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000655e:	00e48c23          	sb	a4,24(s1)
    80006562:	00e48ca3          	sb	a4,25(s1)
    80006566:	00e48d23          	sb	a4,26(s1)
    8000656a:	00e48da3          	sb	a4,27(s1)
    8000656e:	00e48e23          	sb	a4,28(s1)
    80006572:	00e48ea3          	sb	a4,29(s1)
    80006576:	00e48f23          	sb	a4,30(s1)
    8000657a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000657e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006582:	0727a823          	sw	s2,112(a5)
}
    80006586:	60e2                	ld	ra,24(sp)
    80006588:	6442                	ld	s0,16(sp)
    8000658a:	64a2                	ld	s1,8(sp)
    8000658c:	6902                	ld	s2,0(sp)
    8000658e:	6105                	add	sp,sp,32
    80006590:	8082                	ret
    panic("could not find virtio disk");
    80006592:	00002517          	auipc	a0,0x2
    80006596:	20650513          	add	a0,a0,518 # 80008798 <syscalls+0x338>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	fa2080e7          	jalr	-94(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	21650513          	add	a0,a0,534 # 800087b8 <syscalls+0x358>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f92080e7          	jalr	-110(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	22650513          	add	a0,a0,550 # 800087d8 <syscalls+0x378>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	23650513          	add	a0,a0,566 # 800087f8 <syscalls+0x398>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f72080e7          	jalr	-142(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800065d2:	00002517          	auipc	a0,0x2
    800065d6:	24650513          	add	a0,a0,582 # 80008818 <syscalls+0x3b8>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f62080e7          	jalr	-158(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	25650513          	add	a0,a0,598 # 80008838 <syscalls+0x3d8>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f52080e7          	jalr	-174(ra) # 8000053c <panic>

00000000800065f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065f2:	7159                	add	sp,sp,-112
    800065f4:	f486                	sd	ra,104(sp)
    800065f6:	f0a2                	sd	s0,96(sp)
    800065f8:	eca6                	sd	s1,88(sp)
    800065fa:	e8ca                	sd	s2,80(sp)
    800065fc:	e4ce                	sd	s3,72(sp)
    800065fe:	e0d2                	sd	s4,64(sp)
    80006600:	fc56                	sd	s5,56(sp)
    80006602:	f85a                	sd	s6,48(sp)
    80006604:	f45e                	sd	s7,40(sp)
    80006606:	f062                	sd	s8,32(sp)
    80006608:	ec66                	sd	s9,24(sp)
    8000660a:	e86a                	sd	s10,16(sp)
    8000660c:	1880                	add	s0,sp,112
    8000660e:	8a2a                	mv	s4,a0
    80006610:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006612:	00c52c83          	lw	s9,12(a0)
    80006616:	001c9c9b          	sllw	s9,s9,0x1
    8000661a:	1c82                	sll	s9,s9,0x20
    8000661c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006620:	0023c517          	auipc	a0,0x23c
    80006624:	35050513          	add	a0,a0,848 # 80242970 <disk+0x128>
    80006628:	ffffa097          	auipc	ra,0xffffa
    8000662c:	6b2080e7          	jalr	1714(ra) # 80000cda <acquire>
  for(int i = 0; i < 3; i++){
    80006630:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006632:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006634:	0023cb17          	auipc	s6,0x23c
    80006638:	214b0b13          	add	s6,s6,532 # 80242848 <disk>
  for(int i = 0; i < 3; i++){
    8000663c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000663e:	0023cc17          	auipc	s8,0x23c
    80006642:	332c0c13          	add	s8,s8,818 # 80242970 <disk+0x128>
    80006646:	a095                	j	800066aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006648:	00fb0733          	add	a4,s6,a5
    8000664c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006650:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006652:	0207c563          	bltz	a5,8000667c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006656:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006658:	0591                	add	a1,a1,4
    8000665a:	05560d63          	beq	a2,s5,800066b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000665e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006660:	0023c717          	auipc	a4,0x23c
    80006664:	1e870713          	add	a4,a4,488 # 80242848 <disk>
    80006668:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000666a:	01874683          	lbu	a3,24(a4)
    8000666e:	fee9                	bnez	a3,80006648 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006670:	2785                	addw	a5,a5,1
    80006672:	0705                	add	a4,a4,1
    80006674:	fe979be3          	bne	a5,s1,8000666a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006678:	57fd                	li	a5,-1
    8000667a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000667c:	00c05e63          	blez	a2,80006698 <virtio_disk_rw+0xa6>
    80006680:	060a                	sll	a2,a2,0x2
    80006682:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006686:	0009a503          	lw	a0,0(s3)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	cfc080e7          	jalr	-772(ra) # 80006386 <free_desc>
      for(int j = 0; j < i; j++)
    80006692:	0991                	add	s3,s3,4
    80006694:	ffa999e3          	bne	s3,s10,80006686 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006698:	85e2                	mv	a1,s8
    8000669a:	0023c517          	auipc	a0,0x23c
    8000669e:	1c650513          	add	a0,a0,454 # 80242860 <disk+0x18>
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	d2e080e7          	jalr	-722(ra) # 800023d0 <sleep>
  for(int i = 0; i < 3; i++){
    800066aa:	f9040993          	add	s3,s0,-112
{
    800066ae:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800066b0:	864a                	mv	a2,s2
    800066b2:	b775                	j	8000665e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066b4:	f9042503          	lw	a0,-112(s0)
    800066b8:	00a50713          	add	a4,a0,10
    800066bc:	0712                	sll	a4,a4,0x4

  if(write)
    800066be:	0023c797          	auipc	a5,0x23c
    800066c2:	18a78793          	add	a5,a5,394 # 80242848 <disk>
    800066c6:	00e786b3          	add	a3,a5,a4
    800066ca:	01703633          	snez	a2,s7
    800066ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066d4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066d8:	f6070613          	add	a2,a4,-160
    800066dc:	6394                	ld	a3,0(a5)
    800066de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066e0:	00870593          	add	a1,a4,8
    800066e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066e8:	0007b803          	ld	a6,0(a5)
    800066ec:	9642                	add	a2,a2,a6
    800066ee:	46c1                	li	a3,16
    800066f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066f2:	4585                	li	a1,1
    800066f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800066f8:	f9442683          	lw	a3,-108(s0)
    800066fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006700:	0692                	sll	a3,a3,0x4
    80006702:	9836                	add	a6,a6,a3
    80006704:	058a0613          	add	a2,s4,88
    80006708:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000670c:	0007b803          	ld	a6,0(a5)
    80006710:	96c2                	add	a3,a3,a6
    80006712:	40000613          	li	a2,1024
    80006716:	c690                	sw	a2,8(a3)
  if(write)
    80006718:	001bb613          	seqz	a2,s7
    8000671c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006720:	00166613          	or	a2,a2,1
    80006724:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006728:	f9842603          	lw	a2,-104(s0)
    8000672c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006730:	00250693          	add	a3,a0,2
    80006734:	0692                	sll	a3,a3,0x4
    80006736:	96be                	add	a3,a3,a5
    80006738:	58fd                	li	a7,-1
    8000673a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000673e:	0612                	sll	a2,a2,0x4
    80006740:	9832                	add	a6,a6,a2
    80006742:	f9070713          	add	a4,a4,-112
    80006746:	973e                	add	a4,a4,a5
    80006748:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000674c:	6398                	ld	a4,0(a5)
    8000674e:	9732                	add	a4,a4,a2
    80006750:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006752:	4609                	li	a2,2
    80006754:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006758:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000675c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006760:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006764:	6794                	ld	a3,8(a5)
    80006766:	0026d703          	lhu	a4,2(a3)
    8000676a:	8b1d                	and	a4,a4,7
    8000676c:	0706                	sll	a4,a4,0x1
    8000676e:	96ba                	add	a3,a3,a4
    80006770:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006774:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006778:	6798                	ld	a4,8(a5)
    8000677a:	00275783          	lhu	a5,2(a4)
    8000677e:	2785                	addw	a5,a5,1
    80006780:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006784:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006788:	100017b7          	lui	a5,0x10001
    8000678c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006790:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006794:	0023c917          	auipc	s2,0x23c
    80006798:	1dc90913          	add	s2,s2,476 # 80242970 <disk+0x128>
  while(b->disk == 1) {
    8000679c:	4485                	li	s1,1
    8000679e:	00b79c63          	bne	a5,a1,800067b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067a2:	85ca                	mv	a1,s2
    800067a4:	8552                	mv	a0,s4
    800067a6:	ffffc097          	auipc	ra,0xffffc
    800067aa:	c2a080e7          	jalr	-982(ra) # 800023d0 <sleep>
  while(b->disk == 1) {
    800067ae:	004a2783          	lw	a5,4(s4)
    800067b2:	fe9788e3          	beq	a5,s1,800067a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067b6:	f9042903          	lw	s2,-112(s0)
    800067ba:	00290713          	add	a4,s2,2
    800067be:	0712                	sll	a4,a4,0x4
    800067c0:	0023c797          	auipc	a5,0x23c
    800067c4:	08878793          	add	a5,a5,136 # 80242848 <disk>
    800067c8:	97ba                	add	a5,a5,a4
    800067ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067ce:	0023c997          	auipc	s3,0x23c
    800067d2:	07a98993          	add	s3,s3,122 # 80242848 <disk>
    800067d6:	00491713          	sll	a4,s2,0x4
    800067da:	0009b783          	ld	a5,0(s3)
    800067de:	97ba                	add	a5,a5,a4
    800067e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067e4:	854a                	mv	a0,s2
    800067e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ea:	00000097          	auipc	ra,0x0
    800067ee:	b9c080e7          	jalr	-1124(ra) # 80006386 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067f2:	8885                	and	s1,s1,1
    800067f4:	f0ed                	bnez	s1,800067d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067f6:	0023c517          	auipc	a0,0x23c
    800067fa:	17a50513          	add	a0,a0,378 # 80242970 <disk+0x128>
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	590080e7          	jalr	1424(ra) # 80000d8e <release>
}
    80006806:	70a6                	ld	ra,104(sp)
    80006808:	7406                	ld	s0,96(sp)
    8000680a:	64e6                	ld	s1,88(sp)
    8000680c:	6946                	ld	s2,80(sp)
    8000680e:	69a6                	ld	s3,72(sp)
    80006810:	6a06                	ld	s4,64(sp)
    80006812:	7ae2                	ld	s5,56(sp)
    80006814:	7b42                	ld	s6,48(sp)
    80006816:	7ba2                	ld	s7,40(sp)
    80006818:	7c02                	ld	s8,32(sp)
    8000681a:	6ce2                	ld	s9,24(sp)
    8000681c:	6d42                	ld	s10,16(sp)
    8000681e:	6165                	add	sp,sp,112
    80006820:	8082                	ret

0000000080006822 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006822:	1101                	add	sp,sp,-32
    80006824:	ec06                	sd	ra,24(sp)
    80006826:	e822                	sd	s0,16(sp)
    80006828:	e426                	sd	s1,8(sp)
    8000682a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000682c:	0023c497          	auipc	s1,0x23c
    80006830:	01c48493          	add	s1,s1,28 # 80242848 <disk>
    80006834:	0023c517          	auipc	a0,0x23c
    80006838:	13c50513          	add	a0,a0,316 # 80242970 <disk+0x128>
    8000683c:	ffffa097          	auipc	ra,0xffffa
    80006840:	49e080e7          	jalr	1182(ra) # 80000cda <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006844:	10001737          	lui	a4,0x10001
    80006848:	533c                	lw	a5,96(a4)
    8000684a:	8b8d                	and	a5,a5,3
    8000684c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000684e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006852:	689c                	ld	a5,16(s1)
    80006854:	0204d703          	lhu	a4,32(s1)
    80006858:	0027d783          	lhu	a5,2(a5)
    8000685c:	04f70863          	beq	a4,a5,800068ac <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006860:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006864:	6898                	ld	a4,16(s1)
    80006866:	0204d783          	lhu	a5,32(s1)
    8000686a:	8b9d                	and	a5,a5,7
    8000686c:	078e                	sll	a5,a5,0x3
    8000686e:	97ba                	add	a5,a5,a4
    80006870:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006872:	00278713          	add	a4,a5,2
    80006876:	0712                	sll	a4,a4,0x4
    80006878:	9726                	add	a4,a4,s1
    8000687a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000687e:	e721                	bnez	a4,800068c6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006880:	0789                	add	a5,a5,2
    80006882:	0792                	sll	a5,a5,0x4
    80006884:	97a6                	add	a5,a5,s1
    80006886:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006888:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000688c:	ffffc097          	auipc	ra,0xffffc
    80006890:	ba8080e7          	jalr	-1112(ra) # 80002434 <wakeup>

    disk.used_idx += 1;
    80006894:	0204d783          	lhu	a5,32(s1)
    80006898:	2785                	addw	a5,a5,1
    8000689a:	17c2                	sll	a5,a5,0x30
    8000689c:	93c1                	srl	a5,a5,0x30
    8000689e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068a2:	6898                	ld	a4,16(s1)
    800068a4:	00275703          	lhu	a4,2(a4)
    800068a8:	faf71ce3          	bne	a4,a5,80006860 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068ac:	0023c517          	auipc	a0,0x23c
    800068b0:	0c450513          	add	a0,a0,196 # 80242970 <disk+0x128>
    800068b4:	ffffa097          	auipc	ra,0xffffa
    800068b8:	4da080e7          	jalr	1242(ra) # 80000d8e <release>
}
    800068bc:	60e2                	ld	ra,24(sp)
    800068be:	6442                	ld	s0,16(sp)
    800068c0:	64a2                	ld	s1,8(sp)
    800068c2:	6105                	add	sp,sp,32
    800068c4:	8082                	ret
      panic("virtio_disk_intr status");
    800068c6:	00002517          	auipc	a0,0x2
    800068ca:	f8a50513          	add	a0,a0,-118 # 80008850 <syscalls+0x3f0>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	c6e080e7          	jalr	-914(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
