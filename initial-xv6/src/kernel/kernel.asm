
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6010113          	add	sp,sp,-1440 # 80008a60 <stack0>
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
    80000054:	8d070713          	add	a4,a4,-1840 # 80008920 <timer_scratch>
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
    80000066:	22e78793          	add	a5,a5,558 # 80006290 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb22f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	add	a5,a5,-570 # 80000e72 <main>
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
    8000012e:	660080e7          	jalr	1632(ra) # 8000278a <either_copyin>
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
    80000188:	8dc50513          	add	a0,a0,-1828 # 80010a60 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8cc48493          	add	s1,s1,-1844 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	95c90913          	add	s2,s2,-1700 # 80010af8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	84a080e7          	jalr	-1974(ra) # 800019fe <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	418080e7          	jalr	1048(ra) # 800025d4 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	124080e7          	jalr	292(ra) # 800022ee <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	88270713          	add	a4,a4,-1918 # 80010a60 <cons>
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
    80000214:	524080e7          	jalr	1316(ra) # 80002734 <either_copyout>
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
    8000022c:	83850513          	add	a0,a0,-1992 # 80010a60 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	82250513          	add	a0,a0,-2014 # 80010a60 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
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
    80000272:	88f72523          	sw	a5,-1910(a4) # 80010af8 <cons+0x98>
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
    800002cc:	79850513          	add	a0,a0,1944 # 80010a60 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

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
    800002f2:	4f2080e7          	jalr	1266(ra) # 800027e0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	76a50513          	add	a0,a0,1898 # 80010a60 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
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
    8000031e:	74670713          	add	a4,a4,1862 # 80010a60 <cons>
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
    80000348:	71c78793          	add	a5,a5,1820 # 80010a60 <cons>
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
    80000376:	7867a783          	lw	a5,1926(a5) # 80010af8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6da70713          	add	a4,a4,1754 # 80010a60 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6ca48493          	add	s1,s1,1738 # 80010a60 <cons>
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
    800003d6:	68e70713          	add	a4,a4,1678 # 80010a60 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	70f72c23          	sw	a5,1816(a4) # 80010b00 <cons+0xa0>
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
    80000412:	65278793          	add	a5,a5,1618 # 80010a60 <cons>
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
    80000436:	6cc7a523          	sw	a2,1738(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6be50513          	add	a0,a0,1726 # 80010af8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	f10080e7          	jalr	-240(ra) # 80002352 <wakeup>
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
    80000460:	60450513          	add	a0,a0,1540 # 80010a60 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00022797          	auipc	a5,0x22
    80000478:	fc478793          	add	a5,a5,-60 # 80022438 <devsw>
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
    8000054c:	5c07ac23          	sw	zero,1496(a5) # 80010b20 <pr+0x18>
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
    8000056e:	d4e50513          	add	a0,a0,-690 # 800082b8 <digits+0x278>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	36f72223          	sw	a5,868(a4) # 800088e0 <panicked>
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
    800005bc:	568dad83          	lw	s11,1384(s11) # 80010b20 <pr+0x18>
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
    800005fa:	51250513          	add	a0,a0,1298 # 80010b08 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
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
    80000758:	3b450513          	add	a0,a0,948 # 80010b08 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
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
    80000774:	39848493          	add	s1,s1,920 # 80010b08 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
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
    800007d4:	35850513          	add	a0,a0,856 # 80010b28 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
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
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0e47a783          	lw	a5,228(a5) # 800088e0 <panicked>
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
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
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
    80000838:	0b47b783          	ld	a5,180(a5) # 800088e8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0b473703          	ld	a4,180(a4) # 800088f0 <uart_tx_w>
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
    80000862:	2caa0a13          	add	s4,s4,714 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	08248493          	add	s1,s1,130 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	08298993          	add	s3,s3,130 # 800088f0 <uart_tx_w>
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
    80000894:	ac2080e7          	jalr	-1342(ra) # 80002352 <wakeup>
    
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
    800008d0:	25c50513          	add	a0,a0,604 # 80010b28 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0047a783          	lw	a5,4(a5) # 800088e0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	00a73703          	ld	a4,10(a4) # 800088f0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	ffa7b783          	ld	a5,-6(a5) # 800088e8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	22e98993          	add	s3,s3,558 # 80010b28 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fe648493          	add	s1,s1,-26 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fe690913          	add	s2,s2,-26 # 800088f0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	9d4080e7          	jalr	-1580(ra) # 800022ee <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1f848493          	add	s1,s1,504 # 80010b28 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fae7b623          	sd	a4,-84(a5) # 800088f0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
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
    800009ba:	17248493          	add	s1,s1,370 # 80010b28 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	add	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	sll	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00023797          	auipc	a5,0x23
    800009fc:	bd878793          	add	a5,a5,-1064 # 800235d0 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	sll	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	14890913          	add	s2,s2,328 # 80010b60 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	add	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	add	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	add	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	add	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	add	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	add	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	0aa50513          	add	a0,a0,170 # 80010b60 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00023517          	auipc	a0,0x23
    80000ace:	b0650513          	add	a0,a0,-1274 # 800235d0 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	add	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	add	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	07448493          	add	s1,s1,116 # 80010b60 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	05c50513          	add	a0,a0,92 # 80010b60 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	add	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	03050513          	add	a0,a0,48 # 80010b60 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	add	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	add	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	add	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	e76080e7          	jalr	-394(ra) # 800019e2 <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	add	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	add	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	e44080e7          	jalr	-444(ra) # 800019e2 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e38080e7          	jalr	-456(ra) # 800019e2 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	add	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	e20080e7          	jalr	-480(ra) # 800019e2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srl	s1,s1,0x1
    80000bcc:	8885                	and	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	add	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	add	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	de0080e7          	jalr	-544(ra) # 800019e2 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	add	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	add	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	add	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	db4080e7          	jalr	-588(ra) # 800019e2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	add	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	add	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	add	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	add	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	add	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	add	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	add	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	add	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	sll	a2,a2,0x20
    80000cda:	9201                	srl	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	add	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	add	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	add	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	sll	a3,a3,0x20
    80000cfe:	9281                	srl	a3,a3,0x20
    80000d00:	0685                	add	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	add	a0,a0,1
    80000d12:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	add	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	add	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	sll	a2,a2,0x20
    80000d38:	9201                	srl	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	add	a1,a1,1
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdba31>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	add	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	sll	a3,a2,0x20
    80000d5a:	9281                	srl	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addw	a5,a2,-1
    80000d6a:	1782                	sll	a5,a5,0x20
    80000d6c:	9381                	srl	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	add	a4,a4,-1
    80000d76:	16fd                	add	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	add	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	add	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	add	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addw	a2,a2,-1
    80000db6:	0505                	add	a0,a0,1
    80000db8:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	add	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	add	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	add	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	add	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	add	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	add	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	add	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addw	a3,a2,-1
    80000e24:	1682                	sll	a3,a3,0x20
    80000e26:	9281                	srl	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	add	a1,a1,1
    80000e32:	0785                	add	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	add	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	add	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	add	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	add	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:

volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void main()
{
    80000e72:	1141                	add	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	add	s0,sp,16
  if (cpuid() == 0)
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b58080e7          	jalr	-1192(ra) # 800019d2 <cpuid>
    __sync_synchronize();
    started = 1;
  }
  else
  {
    while (started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	a7670713          	add	a4,a4,-1418 # 800088f8 <started>
  if (cpuid() == 0)
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while (started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b3c080e7          	jalr	-1220(ra) # 800019d2 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	add	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();  // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart(); // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	d02080e7          	jalr	-766(ra) # 80002bba <trapinithart>
    plicinithart(); // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	410080e7          	jalr	1040(ra) # 800062d0 <plicinithart>
  }

  scheduler();
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	09c080e7          	jalr	156(ra) # 80001f64 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	3d850513          	add	a0,a0,984 # 800082b8 <digits+0x278>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	3b850513          	add	a0,a0,952 # 800082b8 <digits+0x278>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();            // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();          // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();      // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();         // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();         // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	c62080e7          	jalr	-926(ra) # 80002b92 <trapinit>
    trapinithart();     // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	c82080e7          	jalr	-894(ra) # 80002bba <trapinithart>
    plicinit();         // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	37a080e7          	jalr	890(ra) # 800062ba <plicinit>
    plicinithart();     // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	388080e7          	jalr	904(ra) # 800062d0 <plicinithart>
    binit();            // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	570080e7          	jalr	1392(ra) # 800034c0 <binit>
    iinit();            // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	c0e080e7          	jalr	-1010(ra) # 80003b66 <iinit>
    fileinit();         // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	b84080e7          	jalr	-1148(ra) # 80004ae4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	470080e7          	jalr	1136(ra) # 800063d8 <virtio_disk_init>
    userinit();         // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	dd6080e7          	jalr	-554(ra) # 80001d46 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	96f72d23          	sw	a5,-1670(a4) # 800088f8 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	add	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	96e7b783          	ld	a5,-1682(a5) # 80008900 <kernel_pagetable>
    80000f9a:	83b1                	srl	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	sll	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	add	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	add	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	add	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srl	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	add	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srl	a5,s1,0xc
    80001006:	07aa                	sll	a5,a5,0xa
    80001008:	0017e793          	or	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdba27>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	and	s2,s2,511
    8000101e:	090e                	sll	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	and	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srl	s1,s1,0xa
    8000102e:	04b2                	sll	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srl	a0,s3,0xc
    80001036:	1ff57513          	and	a0,a0,511
    8000103a:	050e                	sll	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	add	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srl	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	add	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	and	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	add	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srl	a5,a5,0xa
    8000108e:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	add	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	add	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	and	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srl	s1,s1,0xc
    800010e8:	04aa                	sll	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	or	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	add	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	add	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	add	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	add	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	add	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	add	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	add	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	add	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	add	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	add	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	sll	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	sll	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	add	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	sll	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	608080e7          	jalr	1544(ra) # 80001830 <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	add	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	add	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	6aa7b923          	sd	a0,1714(a5) # 80008900 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	add	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	add	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	sll	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	sll	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	add	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	add	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	add	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	add	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	add	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	and	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	and	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	sll	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	add	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	add	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	add	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	add	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	add	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	add	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	add	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	add	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	add	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	add	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	add	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	add	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	sll	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	add	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	and	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	and	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	add	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	add	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	add	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	add	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	add	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srl	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	add	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	add	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	and	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srl	a1,a4,0xa
    8000159e:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	add	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	add	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srl	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	add	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	add	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	and	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	add	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	add	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	add	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	add	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	add	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	add	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	add	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	add	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	add	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	add	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	add	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdba30>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	add	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	add	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001830:	7139                	add	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	add	s0,sp,64
    80001844:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	76a48493          	add	s1,s1,1898 # 80010fb0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	add	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001860:	00016a17          	auipc	s4,0x16
    80001864:	150a0a13          	add	s4,s4,336 # 800179b0 <mlfq>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if (pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	858d                	sra	a1,a1,0x3
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addw	a1,a1,1
    80001884:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8a6080e7          	jalr	-1882(ra) # 80001138 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000189a:	1a848493          	add	s1,s1,424
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	add	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	add	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>

00000000800018c6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018c6:	7139                	add	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	add	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	29e50513          	add	a0,a0,670 # 80010b80 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	29e50513          	add	a0,a0,670 # 80010b98 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	6a648493          	add	s1,s1,1702 # 80010fb0 <proc>
  {
    initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8e6b0b13          	add	s6,s6,-1818 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	add	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000192a:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000192c:	00016997          	auipc	s3,0x16
    80001930:	08498993          	add	s3,s3,132 # 800179b0 <mlfq>
    initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	sra	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addw	a5,a5,1
    80001954:	00d7979b          	sllw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	1a848493          	add	s1,s1,424
    80001962:	fd3499e3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
  for (int i = 0; i < 4; i++)
  {
    mlfq[i].head = 0;
    80001966:	00016797          	auipc	a5,0x16
    8000196a:	04a78793          	add	a5,a5,74 # 800179b0 <mlfq>
    8000196e:	0007a023          	sw	zero,0(a5)
    mlfq[i].tail = 0;
    80001972:	0007a223          	sw	zero,4(a5)
    mlfq[i].size = 0;
    80001976:	2007a423          	sw	zero,520(a5)
    mlfq[i].head = 0;
    8000197a:	2007a823          	sw	zero,528(a5)
    mlfq[i].tail = 0;
    8000197e:	2007aa23          	sw	zero,532(a5)
    mlfq[i].size = 0;
    80001982:	4007ac23          	sw	zero,1048(a5)
    {
      mlfq[i].ticks_time = 1;
    }
    else if (i == 1)
    {
      mlfq[i].ticks_time = 3;
    80001986:	470d                	li	a4,3
    80001988:	40e7ae23          	sw	a4,1052(a5)
    mlfq[i].head = 0;
    8000198c:	4207a023          	sw	zero,1056(a5)
    mlfq[i].tail = 0;
    80001990:	4207a223          	sw	zero,1060(a5)
    mlfq[i].size = 0;
    80001994:	6207a423          	sw	zero,1576(a5)
    }
    else if (i == 2)
    {
      mlfq[i].ticks_time = 9;
    80001998:	4725                	li	a4,9
    8000199a:	62e7a623          	sw	a4,1580(a5)
    mlfq[i].head = 0;
    8000199e:	6207a823          	sw	zero,1584(a5)
    mlfq[i].tail = 0;
    800019a2:	6207aa23          	sw	zero,1588(a5)
    mlfq[i].size = 0;
    800019a6:	00017717          	auipc	a4,0x17
    800019aa:	00a70713          	add	a4,a4,10 # 800189b0 <bcache+0x7a8>
    800019ae:	82072c23          	sw	zero,-1992(a4)
    }
    else if (i == 3)
    800019b2:	4685                	li	a3,1
    800019b4:	20d7a623          	sw	a3,524(a5)
    {
      mlfq[i].ticks_time = 15;
    800019b8:	47bd                	li	a5,15
    800019ba:	82f72e23          	sw	a5,-1988(a4)
    }
  }
}
    800019be:	70e2                	ld	ra,56(sp)
    800019c0:	7442                	ld	s0,48(sp)
    800019c2:	74a2                	ld	s1,40(sp)
    800019c4:	7902                	ld	s2,32(sp)
    800019c6:	69e2                	ld	s3,24(sp)
    800019c8:	6a42                	ld	s4,16(sp)
    800019ca:	6aa2                	ld	s5,8(sp)
    800019cc:	6b02                	ld	s6,0(sp)
    800019ce:	6121                	add	sp,sp,64
    800019d0:	8082                	ret

00000000800019d2 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019d2:	1141                	add	sp,sp,-16
    800019d4:	e422                	sd	s0,8(sp)
    800019d6:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019da:	2501                	sext.w	a0,a0
    800019dc:	6422                	ld	s0,8(sp)
    800019de:	0141                	add	sp,sp,16
    800019e0:	8082                	ret

00000000800019e2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019e2:	1141                	add	sp,sp,-16
    800019e4:	e422                	sd	s0,8(sp)
    800019e6:	0800                	add	s0,sp,16
    800019e8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ea:	2781                	sext.w	a5,a5
    800019ec:	079e                	sll	a5,a5,0x7
  return c;
}
    800019ee:	0000f517          	auipc	a0,0xf
    800019f2:	1c250513          	add	a0,a0,450 # 80010bb0 <cpus>
    800019f6:	953e                	add	a0,a0,a5
    800019f8:	6422                	ld	s0,8(sp)
    800019fa:	0141                	add	sp,sp,16
    800019fc:	8082                	ret

00000000800019fe <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019fe:	1101                	add	sp,sp,-32
    80001a00:	ec06                	sd	ra,24(sp)
    80001a02:	e822                	sd	s0,16(sp)
    80001a04:	e426                	sd	s1,8(sp)
    80001a06:	1000                	add	s0,sp,32
  push_off();
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	17e080e7          	jalr	382(ra) # 80000b86 <push_off>
    80001a10:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a12:	2781                	sext.w	a5,a5
    80001a14:	079e                	sll	a5,a5,0x7
    80001a16:	0000f717          	auipc	a4,0xf
    80001a1a:	16a70713          	add	a4,a4,362 # 80010b80 <pid_lock>
    80001a1e:	97ba                	add	a5,a5,a4
    80001a20:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	204080e7          	jalr	516(ra) # 80000c26 <pop_off>
  return p;
}
    80001a2a:	8526                	mv	a0,s1
    80001a2c:	60e2                	ld	ra,24(sp)
    80001a2e:	6442                	ld	s0,16(sp)
    80001a30:	64a2                	ld	s1,8(sp)
    80001a32:	6105                	add	sp,sp,32
    80001a34:	8082                	ret

0000000080001a36 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a36:	1141                	add	sp,sp,-16
    80001a38:	e406                	sd	ra,8(sp)
    80001a3a:	e022                	sd	s0,0(sp)
    80001a3c:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a3e:	00000097          	auipc	ra,0x0
    80001a42:	fc0080e7          	jalr	-64(ra) # 800019fe <myproc>
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	240080e7          	jalr	576(ra) # 80000c86 <release>

  if (first)
    80001a4e:	00007797          	auipc	a5,0x7
    80001a52:	e427a783          	lw	a5,-446(a5) # 80008890 <first.1>
    80001a56:	eb89                	bnez	a5,80001a68 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a58:	00001097          	auipc	ra,0x1
    80001a5c:	17a080e7          	jalr	378(ra) # 80002bd2 <usertrapret>
}
    80001a60:	60a2                	ld	ra,8(sp)
    80001a62:	6402                	ld	s0,0(sp)
    80001a64:	0141                	add	sp,sp,16
    80001a66:	8082                	ret
    first = 0;
    80001a68:	00007797          	auipc	a5,0x7
    80001a6c:	e207a423          	sw	zero,-472(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001a70:	4505                	li	a0,1
    80001a72:	00002097          	auipc	ra,0x2
    80001a76:	074080e7          	jalr	116(ra) # 80003ae6 <fsinit>
    80001a7a:	bff9                	j	80001a58 <forkret+0x22>

0000000080001a7c <allocpid>:
{
    80001a7c:	1101                	add	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	e04a                	sd	s2,0(sp)
    80001a86:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001a88:	0000f917          	auipc	s2,0xf
    80001a8c:	0f890913          	add	s2,s2,248 # 80010b80 <pid_lock>
    80001a90:	854a                	mv	a0,s2
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	140080e7          	jalr	320(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	dfa78793          	add	a5,a5,-518 # 80008894 <nextpid>
    80001aa2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa4:	0014871b          	addw	a4,s1,1
    80001aa8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aaa:	854a                	mv	a0,s2
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	1da080e7          	jalr	474(ra) # 80000c86 <release>
}
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	60e2                	ld	ra,24(sp)
    80001ab8:	6442                	ld	s0,16(sp)
    80001aba:	64a2                	ld	s1,8(sp)
    80001abc:	6902                	ld	s2,0(sp)
    80001abe:	6105                	add	sp,sp,32
    80001ac0:	8082                	ret

0000000080001ac2 <proc_pagetable>:
{
    80001ac2:	1101                	add	sp,sp,-32
    80001ac4:	ec06                	sd	ra,24(sp)
    80001ac6:	e822                	sd	s0,16(sp)
    80001ac8:	e426                	sd	s1,8(sp)
    80001aca:	e04a                	sd	s2,0(sp)
    80001acc:	1000                	add	s0,sp,32
    80001ace:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad0:	00000097          	auipc	ra,0x0
    80001ad4:	852080e7          	jalr	-1966(ra) # 80001322 <uvmcreate>
    80001ad8:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ada:	c121                	beqz	a0,80001b1a <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001adc:	4729                	li	a4,10
    80001ade:	00005697          	auipc	a3,0x5
    80001ae2:	52268693          	add	a3,a3,1314 # 80007000 <_trampoline>
    80001ae6:	6605                	lui	a2,0x1
    80001ae8:	040005b7          	lui	a1,0x4000
    80001aec:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aee:	05b2                	sll	a1,a1,0xc
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	5a8080e7          	jalr	1448(ra) # 80001098 <mappages>
    80001af8:	02054863          	bltz	a0,80001b28 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001afc:	4719                	li	a4,6
    80001afe:	05893683          	ld	a3,88(s2)
    80001b02:	6605                	lui	a2,0x1
    80001b04:	020005b7          	lui	a1,0x2000
    80001b08:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b0a:	05b6                	sll	a1,a1,0xd
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	58a080e7          	jalr	1418(ra) # 80001098 <mappages>
    80001b16:	02054163          	bltz	a0,80001b38 <proc_pagetable+0x76>
}
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	60e2                	ld	ra,24(sp)
    80001b1e:	6442                	ld	s0,16(sp)
    80001b20:	64a2                	ld	s1,8(sp)
    80001b22:	6902                	ld	s2,0(sp)
    80001b24:	6105                	add	sp,sp,32
    80001b26:	8082                	ret
    uvmfree(pagetable, 0);
    80001b28:	4581                	li	a1,0
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	00000097          	auipc	ra,0x0
    80001b30:	9fc080e7          	jalr	-1540(ra) # 80001528 <uvmfree>
    return 0;
    80001b34:	4481                	li	s1,0
    80001b36:	b7d5                	j	80001b1a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b42:	05b2                	sll	a1,a1,0xc
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	718080e7          	jalr	1816(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9d6080e7          	jalr	-1578(ra) # 80001528 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	bf7d                	j	80001b1a <proc_pagetable+0x58>

0000000080001b5e <proc_freepagetable>:
{
    80001b5e:	1101                	add	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	e04a                	sd	s2,0(sp)
    80001b68:	1000                	add	s0,sp,32
    80001b6a:	84aa                	mv	s1,a0
    80001b6c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b6e:	4681                	li	a3,0
    80001b70:	4605                	li	a2,1
    80001b72:	040005b7          	lui	a1,0x4000
    80001b76:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b78:	05b2                	sll	a1,a1,0xc
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	6e4080e7          	jalr	1764(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b82:	4681                	li	a3,0
    80001b84:	4605                	li	a2,1
    80001b86:	020005b7          	lui	a1,0x2000
    80001b8a:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b8c:	05b6                	sll	a1,a1,0xd
    80001b8e:	8526                	mv	a0,s1
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	6ce080e7          	jalr	1742(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b98:	85ca                	mv	a1,s2
    80001b9a:	8526                	mv	a0,s1
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	98c080e7          	jalr	-1652(ra) # 80001528 <uvmfree>
}
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	64a2                	ld	s1,8(sp)
    80001baa:	6902                	ld	s2,0(sp)
    80001bac:	6105                	add	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <freeproc>:
{
    80001bb0:	1101                	add	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	1000                	add	s0,sp,32
    80001bba:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001bbc:	6d28                	ld	a0,88(a0)
    80001bbe:	c509                	beqz	a0,80001bc8 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	e24080e7          	jalr	-476(ra) # 800009e4 <kfree>
  if (p->trapframe_copy)
    80001bc8:	1884b503          	ld	a0,392(s1)
    80001bcc:	c509                	beqz	a0,80001bd6 <freeproc+0x26>
    kfree((void *)p->trapframe_copy);
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	e16080e7          	jalr	-490(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001bd6:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001bda:	68a8                	ld	a0,80(s1)
    80001bdc:	c511                	beqz	a0,80001be8 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80001bde:	64ac                	ld	a1,72(s1)
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	f7e080e7          	jalr	-130(ra) # 80001b5e <proc_freepagetable>
  p->pagetable = 0;
    80001be8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bec:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bf0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bf8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bfc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c00:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c04:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c08:	0004ac23          	sw	zero,24(s1)
}
    80001c0c:	60e2                	ld	ra,24(sp)
    80001c0e:	6442                	ld	s0,16(sp)
    80001c10:	64a2                	ld	s1,8(sp)
    80001c12:	6105                	add	sp,sp,32
    80001c14:	8082                	ret

0000000080001c16 <allocproc>:
{
    80001c16:	1101                	add	sp,sp,-32
    80001c18:	ec06                	sd	ra,24(sp)
    80001c1a:	e822                	sd	s0,16(sp)
    80001c1c:	e426                	sd	s1,8(sp)
    80001c1e:	e04a                	sd	s2,0(sp)
    80001c20:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c22:	0000f497          	auipc	s1,0xf
    80001c26:	38e48493          	add	s1,s1,910 # 80010fb0 <proc>
    80001c2a:	00016917          	auipc	s2,0x16
    80001c2e:	d8690913          	add	s2,s2,-634 # 800179b0 <mlfq>
    acquire(&p->lock);
    80001c32:	8526                	mv	a0,s1
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	f9e080e7          	jalr	-98(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001c3c:	4c9c                	lw	a5,24(s1)
    80001c3e:	cf81                	beqz	a5,80001c56 <allocproc+0x40>
      release(&p->lock);
    80001c40:	8526                	mv	a0,s1
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	044080e7          	jalr	68(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c4a:	1a848493          	add	s1,s1,424
    80001c4e:	ff2492e3          	bne	s1,s2,80001c32 <allocproc+0x1c>
  return 0;
    80001c52:	4481                	li	s1,0
    80001c54:	a871                	j	80001cf0 <allocproc+0xda>
  p->pid = allocpid();
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	e26080e7          	jalr	-474(ra) # 80001a7c <allocpid>
    80001c5e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c60:	4785                	li	a5,1
    80001c62:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	e7e080e7          	jalr	-386(ra) # 80000ae2 <kalloc>
    80001c6c:	892a                	mv	s2,a0
    80001c6e:	eca8                	sd	a0,88(s1)
    80001c70:	c559                	beqz	a0,80001cfe <allocproc+0xe8>
  if ((p->trapframe_copy = (struct trapframe *)kalloc()) == 0)
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	e70080e7          	jalr	-400(ra) # 80000ae2 <kalloc>
    80001c7a:	892a                	mv	s2,a0
    80001c7c:	18a4b423          	sd	a0,392(s1)
    80001c80:	c959                	beqz	a0,80001d16 <allocproc+0x100>
  p->pagetable = proc_pagetable(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	e3e080e7          	jalr	-450(ra) # 80001ac2 <proc_pagetable>
    80001c8c:	892a                	mv	s2,a0
    80001c8e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c90:	cd59                	beqz	a0,80001d2e <allocproc+0x118>
  memset(&p->context, 0, sizeof(p->context));
    80001c92:	07000613          	li	a2,112
    80001c96:	4581                	li	a1,0
    80001c98:	06048513          	add	a0,s1,96
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	032080e7          	jalr	50(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001ca4:	00000797          	auipc	a5,0x0
    80001ca8:	d9278793          	add	a5,a5,-622 # 80001a36 <forkret>
    80001cac:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cae:	60bc                	ld	a5,64(s1)
    80001cb0:	6705                	lui	a4,0x1
    80001cb2:	97ba                	add	a5,a5,a4
    80001cb4:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001cb6:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001cba:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	c527a783          	lw	a5,-942(a5) # 80008910 <ticks>
    80001cc6:	16f4a623          	sw	a5,364(s1)
  p->is_sigalarm = 0;
    80001cca:	1604aa23          	sw	zero,372(s1)
  p->ticks = 0;
    80001cce:	1604ac23          	sw	zero,376(s1)
  p->now_ticks = 0;
    80001cd2:	1604ae23          	sw	zero,380(s1)
  p->handler = 0;
    80001cd6:	1804b023          	sd	zero,384(s1)
  p->q_no = 0;
    80001cda:	1804a823          	sw	zero,400(s1)
  p->wtime = 0;
    80001cde:	1804aa23          	sw	zero,404(s1)
  p->present_q = -1;
    80001ce2:	57fd                	li	a5,-1
    80001ce4:	18f4ac23          	sw	a5,408(s1)
  p->q_ticks = 0;
    80001ce8:	1804ae23          	sw	zero,412(s1)
  p->q_time = 0;
    80001cec:	1a04a023          	sw	zero,416(s1)
}
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6902                	ld	s2,0(sp)
    80001cfa:	6105                	add	sp,sp,32
    80001cfc:	8082                	ret
    freeproc(p);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	eb0080e7          	jalr	-336(ra) # 80001bb0 <freeproc>
    release(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	f7c080e7          	jalr	-132(ra) # 80000c86 <release>
    return 0;
    80001d12:	84ca                	mv	s1,s2
    80001d14:	bff1                	j	80001cf0 <allocproc+0xda>
    freeproc(p);
    80001d16:	8526                	mv	a0,s1
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	e98080e7          	jalr	-360(ra) # 80001bb0 <freeproc>
    release(&p->lock);
    80001d20:	8526                	mv	a0,s1
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	f64080e7          	jalr	-156(ra) # 80000c86 <release>
    return 0;
    80001d2a:	84ca                	mv	s1,s2
    80001d2c:	b7d1                	j	80001cf0 <allocproc+0xda>
    freeproc(p);
    80001d2e:	8526                	mv	a0,s1
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	e80080e7          	jalr	-384(ra) # 80001bb0 <freeproc>
    release(&p->lock);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	f4c080e7          	jalr	-180(ra) # 80000c86 <release>
    return 0;
    80001d42:	84ca                	mv	s1,s2
    80001d44:	b775                	j	80001cf0 <allocproc+0xda>

0000000080001d46 <userinit>:
{
    80001d46:	1101                	add	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	1000                	add	s0,sp,32
  p = allocproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	ec6080e7          	jalr	-314(ra) # 80001c16 <allocproc>
    80001d58:	84aa                	mv	s1,a0
  initproc = p;
    80001d5a:	00007797          	auipc	a5,0x7
    80001d5e:	baa7b723          	sd	a0,-1106(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d62:	03400613          	li	a2,52
    80001d66:	00007597          	auipc	a1,0x7
    80001d6a:	b3a58593          	add	a1,a1,-1222 # 800088a0 <initcode>
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	5e0080e7          	jalr	1504(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001d78:	6785                	lui	a5,0x1
    80001d7a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d7c:	6cb8                	ld	a4,88(s1)
    80001d7e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d82:	6cb8                	ld	a4,88(s1)
    80001d84:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d86:	4641                	li	a2,16
    80001d88:	00006597          	auipc	a1,0x6
    80001d8c:	47858593          	add	a1,a1,1144 # 80008200 <digits+0x1c0>
    80001d90:	15848513          	add	a0,s1,344
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	082080e7          	jalr	130(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d9c:	00006517          	auipc	a0,0x6
    80001da0:	47450513          	add	a0,a0,1140 # 80008210 <digits+0x1d0>
    80001da4:	00002097          	auipc	ra,0x2
    80001da8:	760080e7          	jalr	1888(ra) # 80004504 <namei>
    80001dac:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001db0:	478d                	li	a5,3
    80001db2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001db4:	8526                	mv	a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	ed0080e7          	jalr	-304(ra) # 80000c86 <release>
}
    80001dbe:	60e2                	ld	ra,24(sp)
    80001dc0:	6442                	ld	s0,16(sp)
    80001dc2:	64a2                	ld	s1,8(sp)
    80001dc4:	6105                	add	sp,sp,32
    80001dc6:	8082                	ret

0000000080001dc8 <growproc>:
{
    80001dc8:	1101                	add	sp,sp,-32
    80001dca:	ec06                	sd	ra,24(sp)
    80001dcc:	e822                	sd	s0,16(sp)
    80001dce:	e426                	sd	s1,8(sp)
    80001dd0:	e04a                	sd	s2,0(sp)
    80001dd2:	1000                	add	s0,sp,32
    80001dd4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	c28080e7          	jalr	-984(ra) # 800019fe <myproc>
    80001dde:	84aa                	mv	s1,a0
  sz = p->sz;
    80001de0:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001de2:	01204c63          	bgtz	s2,80001dfa <growproc+0x32>
  else if (n < 0)
    80001de6:	02094663          	bltz	s2,80001e12 <growproc+0x4a>
  p->sz = sz;
    80001dea:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dec:	4501                	li	a0,0
}
    80001dee:	60e2                	ld	ra,24(sp)
    80001df0:	6442                	ld	s0,16(sp)
    80001df2:	64a2                	ld	s1,8(sp)
    80001df4:	6902                	ld	s2,0(sp)
    80001df6:	6105                	add	sp,sp,32
    80001df8:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001dfa:	4691                	li	a3,4
    80001dfc:	00b90633          	add	a2,s2,a1
    80001e00:	6928                	ld	a0,80(a0)
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	608080e7          	jalr	1544(ra) # 8000140a <uvmalloc>
    80001e0a:	85aa                	mv	a1,a0
    80001e0c:	fd79                	bnez	a0,80001dea <growproc+0x22>
      return -1;
    80001e0e:	557d                	li	a0,-1
    80001e10:	bff9                	j	80001dee <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e12:	00b90633          	add	a2,s2,a1
    80001e16:	6928                	ld	a0,80(a0)
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	5aa080e7          	jalr	1450(ra) # 800013c2 <uvmdealloc>
    80001e20:	85aa                	mv	a1,a0
    80001e22:	b7e1                	j	80001dea <growproc+0x22>

0000000080001e24 <fork>:
{
    80001e24:	7139                	add	sp,sp,-64
    80001e26:	fc06                	sd	ra,56(sp)
    80001e28:	f822                	sd	s0,48(sp)
    80001e2a:	f426                	sd	s1,40(sp)
    80001e2c:	f04a                	sd	s2,32(sp)
    80001e2e:	ec4e                	sd	s3,24(sp)
    80001e30:	e852                	sd	s4,16(sp)
    80001e32:	e456                	sd	s5,8(sp)
    80001e34:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	bc8080e7          	jalr	-1080(ra) # 800019fe <myproc>
    80001e3e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	dd6080e7          	jalr	-554(ra) # 80001c16 <allocproc>
    80001e48:	10050c63          	beqz	a0,80001f60 <fork+0x13c>
    80001e4c:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e4e:	048ab603          	ld	a2,72(s5)
    80001e52:	692c                	ld	a1,80(a0)
    80001e54:	050ab503          	ld	a0,80(s5)
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	70a080e7          	jalr	1802(ra) # 80001562 <uvmcopy>
    80001e60:	04054863          	bltz	a0,80001eb0 <fork+0x8c>
  np->sz = p->sz;
    80001e64:	048ab783          	ld	a5,72(s5)
    80001e68:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e6c:	058ab683          	ld	a3,88(s5)
    80001e70:	87b6                	mv	a5,a3
    80001e72:	058a3703          	ld	a4,88(s4)
    80001e76:	12068693          	add	a3,a3,288
    80001e7a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7e:	6788                	ld	a0,8(a5)
    80001e80:	6b8c                	ld	a1,16(a5)
    80001e82:	6f90                	ld	a2,24(a5)
    80001e84:	01073023          	sd	a6,0(a4)
    80001e88:	e708                	sd	a0,8(a4)
    80001e8a:	eb0c                	sd	a1,16(a4)
    80001e8c:	ef10                	sd	a2,24(a4)
    80001e8e:	02078793          	add	a5,a5,32
    80001e92:	02070713          	add	a4,a4,32
    80001e96:	fed792e3          	bne	a5,a3,80001e7a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e9a:	058a3783          	ld	a5,88(s4)
    80001e9e:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001ea2:	0d0a8493          	add	s1,s5,208
    80001ea6:	0d0a0913          	add	s2,s4,208
    80001eaa:	150a8993          	add	s3,s5,336
    80001eae:	a00d                	j	80001ed0 <fork+0xac>
    freeproc(np);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	cfe080e7          	jalr	-770(ra) # 80001bb0 <freeproc>
    release(&np->lock);
    80001eba:	8552                	mv	a0,s4
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	dca080e7          	jalr	-566(ra) # 80000c86 <release>
    return -1;
    80001ec4:	597d                	li	s2,-1
    80001ec6:	a059                	j	80001f4c <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001ec8:	04a1                	add	s1,s1,8
    80001eca:	0921                	add	s2,s2,8
    80001ecc:	01348b63          	beq	s1,s3,80001ee2 <fork+0xbe>
    if (p->ofile[i])
    80001ed0:	6088                	ld	a0,0(s1)
    80001ed2:	d97d                	beqz	a0,80001ec8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed4:	00003097          	auipc	ra,0x3
    80001ed8:	ca2080e7          	jalr	-862(ra) # 80004b76 <filedup>
    80001edc:	00a93023          	sd	a0,0(s2)
    80001ee0:	b7e5                	j	80001ec8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ee2:	150ab503          	ld	a0,336(s5)
    80001ee6:	00002097          	auipc	ra,0x2
    80001eea:	e3a080e7          	jalr	-454(ra) # 80003d20 <idup>
    80001eee:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef2:	4641                	li	a2,16
    80001ef4:	158a8593          	add	a1,s5,344
    80001ef8:	158a0513          	add	a0,s4,344
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	f1a080e7          	jalr	-230(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001f04:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f08:	8552                	mv	a0,s4
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	d7c080e7          	jalr	-644(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001f12:	0000f497          	auipc	s1,0xf
    80001f16:	c8648493          	add	s1,s1,-890 # 80010b98 <wait_lock>
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	cb6080e7          	jalr	-842(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001f24:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	d5c080e7          	jalr	-676(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001f32:	8552                	mv	a0,s4
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	c9e080e7          	jalr	-866(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001f3c:	478d                	li	a5,3
    80001f3e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f42:	8552                	mv	a0,s4
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	d42080e7          	jalr	-702(ra) # 80000c86 <release>
}
    80001f4c:	854a                	mv	a0,s2
    80001f4e:	70e2                	ld	ra,56(sp)
    80001f50:	7442                	ld	s0,48(sp)
    80001f52:	74a2                	ld	s1,40(sp)
    80001f54:	7902                	ld	s2,32(sp)
    80001f56:	69e2                	ld	s3,24(sp)
    80001f58:	6a42                	ld	s4,16(sp)
    80001f5a:	6aa2                	ld	s5,8(sp)
    80001f5c:	6121                	add	sp,sp,64
    80001f5e:	8082                	ret
    return -1;
    80001f60:	597d                	li	s2,-1
    80001f62:	b7ed                	j	80001f4c <fork+0x128>

0000000080001f64 <scheduler>:
{
    80001f64:	715d                	add	sp,sp,-80
    80001f66:	e486                	sd	ra,72(sp)
    80001f68:	e0a2                	sd	s0,64(sp)
    80001f6a:	fc26                	sd	s1,56(sp)
    80001f6c:	f84a                	sd	s2,48(sp)
    80001f6e:	f44e                	sd	s3,40(sp)
    80001f70:	f052                	sd	s4,32(sp)
    80001f72:	ec56                	sd	s5,24(sp)
    80001f74:	e85a                	sd	s6,16(sp)
    80001f76:	e45e                	sd	s7,8(sp)
    80001f78:	0880                	add	s0,sp,80
    80001f7a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f7e:	00779693          	sll	a3,a5,0x7
    80001f82:	0000f717          	auipc	a4,0xf
    80001f86:	bfe70713          	add	a4,a4,-1026 # 80010b80 <pid_lock>
    80001f8a:	9736                	add	a4,a4,a3
    80001f8c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &minimum_p->context);
    80001f90:	0000f717          	auipc	a4,0xf
    80001f94:	c2870713          	add	a4,a4,-984 # 80010bb8 <cpus+0x8>
    80001f98:	00e68bb3          	add	s7,a3,a4
    struct proc *minimum_p = 0;
    80001f9c:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    80001f9e:	490d                	li	s2,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001fa0:	00016997          	auipc	s3,0x16
    80001fa4:	a1098993          	add	s3,s3,-1520 # 800179b0 <mlfq>
        c->proc = minimum_p;
    80001fa8:	0000fb17          	auipc	s6,0xf
    80001fac:	bd8b0b13          	add	s6,s6,-1064 # 80010b80 <pid_lock>
    80001fb0:	9b36                	add	s6,s6,a3
    80001fb2:	a0a9                	j	80001ffc <scheduler+0x98>
        if (minimum_p == 0)
    80001fb4:	080a0e63          	beqz	s4,80002050 <scheduler+0xec>
        else if (p->ctime < minimum_p->ctime)
    80001fb8:	16c4a703          	lw	a4,364(s1)
    80001fbc:	16ca2783          	lw	a5,364(s4)
    80001fc0:	08f76a63          	bltu	a4,a5,80002054 <scheduler+0xf0>
      release(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	cc0080e7          	jalr	-832(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fce:	1a848493          	add	s1,s1,424
    80001fd2:	05348163          	beq	s1,s3,80002014 <scheduler+0xb0>
      acquire(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	bfa080e7          	jalr	-1030(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001fe0:	4c9c                	lw	a5,24(s1)
    80001fe2:	fd2789e3          	beq	a5,s2,80001fb4 <scheduler+0x50>
      release(&p->lock);
    80001fe6:	8526                	mv	a0,s1
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	c9e080e7          	jalr	-866(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ff0:	1a848493          	add	s1,s1,424
    80001ff4:	ff3491e3          	bne	s1,s3,80001fd6 <scheduler+0x72>
    if (minimum_p != 0)
    80001ff8:	000a1e63          	bnez	s4,80002014 <scheduler+0xb0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002000:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002004:	10079073          	csrw	sstatus,a5
    struct proc *minimum_p = 0;
    80002008:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    8000200a:	0000f497          	auipc	s1,0xf
    8000200e:	fa648493          	add	s1,s1,-90 # 80010fb0 <proc>
    80002012:	b7d1                	j	80001fd6 <scheduler+0x72>
      acquire(&minimum_p->lock);
    80002014:	84d2                	mv	s1,s4
    80002016:	8552                	mv	a0,s4
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	bba080e7          	jalr	-1094(ra) # 80000bd2 <acquire>
      if (minimum_p->state == RUNNABLE)
    80002020:	018a2783          	lw	a5,24(s4)
    80002024:	03279063          	bne	a5,s2,80002044 <scheduler+0xe0>
        minimum_p->state = RUNNING;
    80002028:	4791                	li	a5,4
    8000202a:	00fa2c23          	sw	a5,24(s4)
        c->proc = minimum_p;
    8000202e:	034b3823          	sd	s4,48(s6)
        swtch(&c->context, &minimum_p->context);
    80002032:	060a0593          	add	a1,s4,96
    80002036:	855e                	mv	a0,s7
    80002038:	00001097          	auipc	ra,0x1
    8000203c:	af0080e7          	jalr	-1296(ra) # 80002b28 <swtch>
        c->proc = 0;
    80002040:	020b3823          	sd	zero,48(s6)
      release(&minimum_p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c40080e7          	jalr	-960(ra) # 80000c86 <release>
    8000204e:	b77d                	j	80001ffc <scheduler+0x98>
    80002050:	8a26                	mv	s4,s1
    80002052:	bf8d                	j	80001fc4 <scheduler+0x60>
    80002054:	8a26                	mv	s4,s1
    80002056:	b7bd                	j	80001fc4 <scheduler+0x60>

0000000080002058 <push_front>:
{
    80002058:	1141                	add	sp,sp,-16
    8000205a:	e422                	sd	s0,8(sp)
    8000205c:	0800                	add	s0,sp,16
  p->q_no = qn;
    8000205e:	18c5a823          	sw	a2,400(a1)
  p->wtime = 0;
    80002062:	1805aa23          	sw	zero,404(a1)
  p->present_q = qn;
    80002066:	18c5ac23          	sw	a2,408(a1)
  p->q_time = q->ticks_time;
    8000206a:	20c52783          	lw	a5,524(a0)
    8000206e:	1af5a023          	sw	a5,416(a1)
  if (q->size == 0)
    80002072:	20852703          	lw	a4,520(a0)
    80002076:	e715                	bnez	a4,800020a2 <push_front+0x4a>
    q->head = 0;
    80002078:	00052023          	sw	zero,0(a0)
    q->process[q->tail] = p;
    8000207c:	e50c                	sd	a1,8(a0)
    q->tail++;
    8000207e:	4785                	li	a5,1
    80002080:	c15c                	sw	a5,4(a0)
    q->size++;
    80002082:	4705                	li	a4,1
    80002084:	20e52423          	sw	a4,520(a0)
  q->head = q->head % NPROC;
    80002088:	411c                	lw	a5,0(a0)
    8000208a:	41f7d71b          	sraw	a4,a5,0x1f
    8000208e:	01a7571b          	srlw	a4,a4,0x1a
    80002092:	9fb9                	addw	a5,a5,a4
    80002094:	03f7f793          	and	a5,a5,63
    80002098:	9f99                	subw	a5,a5,a4
    8000209a:	c11c                	sw	a5,0(a0)
}
    8000209c:	6422                	ld	s0,8(sp)
    8000209e:	0141                	add	sp,sp,16
    800020a0:	8082                	ret
    q->head--;
    800020a2:	411c                	lw	a5,0(a0)
    800020a4:	37fd                	addw	a5,a5,-1
    if (q->head < 0)
    800020a6:	0007c863          	bltz	a5,800020b6 <push_front+0x5e>
    800020aa:	c11c                	sw	a5,0(a0)
    q->process[q->head] = p;
    800020ac:	078e                	sll	a5,a5,0x3
    800020ae:	97aa                	add	a5,a5,a0
    800020b0:	e78c                	sd	a1,8(a5)
    q->size++;
    800020b2:	2705                	addw	a4,a4,1
    800020b4:	bfc1                	j	80002084 <push_front+0x2c>
      q->head = NPROC - 1;
    800020b6:	03f00793          	li	a5,63
    800020ba:	bfc5                	j	800020aa <push_front+0x52>

00000000800020bc <push>:
{
    800020bc:	1141                	add	sp,sp,-16
    800020be:	e422                	sd	s0,8(sp)
    800020c0:	0800                	add	s0,sp,16
  p->q_no = qn;
    800020c2:	18c5a823          	sw	a2,400(a1)
  p->wtime = 0;
    800020c6:	1805aa23          	sw	zero,404(a1)
  p->q_ticks_time = ticks;
    800020ca:	00007797          	auipc	a5,0x7
    800020ce:	8467a783          	lw	a5,-1978(a5) # 80008910 <ticks>
    800020d2:	1af5a223          	sw	a5,420(a1)
  p->present_q = qn;
    800020d6:	18c5ac23          	sw	a2,408(a1)
  p->q_time = q->ticks_time;
    800020da:	20c52783          	lw	a5,524(a0)
    800020de:	1af5a023          	sw	a5,416(a1)
  if (q->size == 0)
    800020e2:	20852703          	lw	a4,520(a0)
    800020e6:	e705                	bnez	a4,8000210e <push+0x52>
    q->head = 0;
    800020e8:	00052023          	sw	zero,0(a0)
    q->process[q->tail] = p;
    800020ec:	e50c                	sd	a1,8(a0)
    q->size++;
    800020ee:	4785                	li	a5,1
    800020f0:	4705                	li	a4,1
    800020f2:	20e52423          	sw	a4,520(a0)
  q->tail = q->tail % NPROC;
    800020f6:	41f7d71b          	sraw	a4,a5,0x1f
    800020fa:	01a7571b          	srlw	a4,a4,0x1a
    800020fe:	9fb9                	addw	a5,a5,a4
    80002100:	03f7f793          	and	a5,a5,63
    80002104:	9f99                	subw	a5,a5,a4
    80002106:	c15c                	sw	a5,4(a0)
}
    80002108:	6422                	ld	s0,8(sp)
    8000210a:	0141                	add	sp,sp,16
    8000210c:	8082                	ret
    q->process[q->tail] = p;
    8000210e:	415c                	lw	a5,4(a0)
    80002110:	00379693          	sll	a3,a5,0x3
    80002114:	96aa                	add	a3,a3,a0
    80002116:	e68c                	sd	a1,8(a3)
    q->tail++;
    80002118:	2785                	addw	a5,a5,1
    q->size++;
    8000211a:	2705                	addw	a4,a4,1
    8000211c:	bfd9                	j	800020f2 <push+0x36>

000000008000211e <pop>:
{
    8000211e:	1141                	add	sp,sp,-16
    80002120:	e422                	sd	s0,8(sp)
    80002122:	0800                	add	s0,sp,16
  if (q->size == 0)
    80002124:	20852703          	lw	a4,520(a0)
    80002128:	cf19                	beqz	a4,80002146 <pop+0x28>
    q->head++;
    8000212a:	411c                	lw	a5,0(a0)
    8000212c:	2785                	addw	a5,a5,1
    q->size--;
    8000212e:	377d                	addw	a4,a4,-1
    80002130:	20e52423          	sw	a4,520(a0)
  q->head = q->head % NPROC;
    80002134:	41f7d71b          	sraw	a4,a5,0x1f
    80002138:	01a7571b          	srlw	a4,a4,0x1a
    8000213c:	9fb9                	addw	a5,a5,a4
    8000213e:	03f7f793          	and	a5,a5,63
    80002142:	9f99                	subw	a5,a5,a4
    80002144:	c11c                	sw	a5,0(a0)
}
    80002146:	6422                	ld	s0,8(sp)
    80002148:	0141                	add	sp,sp,16
    8000214a:	8082                	ret

000000008000214c <pop_mid>:
{
    8000214c:	1141                	add	sp,sp,-16
    8000214e:	e422                	sd	s0,8(sp)
    80002150:	0800                	add	s0,sp,16
  if (q->size == 0)
    80002152:	20852803          	lw	a6,520(a0)
    80002156:	04080863          	beqz	a6,800021a6 <pop_mid+0x5a>
    for (i = q->head; i < q->tail; i++)
    8000215a:	411c                	lw	a5,0(a0)
    8000215c:	4154                	lw	a3,4(a0)
    8000215e:	02d7d563          	bge	a5,a3,80002188 <pop_mid+0x3c>
      if (q->process[i]->pid == p->pid)
    80002162:	5990                	lw	a2,48(a1)
    80002164:	00379713          	sll	a4,a5,0x3
    80002168:	972a                	add	a4,a4,a0
    8000216a:	6718                	ld	a4,8(a4)
    8000216c:	5b18                	lw	a4,48(a4)
    8000216e:	02c70f63          	beq	a4,a2,800021ac <pop_mid+0x60>
      i = i % NPROC;
    80002172:	41f7d71b          	sraw	a4,a5,0x1f
    80002176:	01a7571b          	srlw	a4,a4,0x1a
    8000217a:	9fb9                	addw	a5,a5,a4
    8000217c:	03f7f793          	and	a5,a5,63
    80002180:	9f99                	subw	a5,a5,a4
    for (i = q->head; i < q->tail; i++)
    80002182:	2785                	addw	a5,a5,1
    80002184:	fed7c0e3          	blt	a5,a3,80002164 <pop_mid+0x18>
    q->tail--;
    80002188:	36fd                	addw	a3,a3,-1
    if (q->tail < 0)
    8000218a:	0406c663          	bltz	a3,800021d6 <pop_mid+0x8a>
    q->size--;
    8000218e:	387d                	addw	a6,a6,-1
    80002190:	21052423          	sw	a6,520(a0)
  q->tail = q->tail % NPROC;
    80002194:	41f6d79b          	sraw	a5,a3,0x1f
    80002198:	01a7d79b          	srlw	a5,a5,0x1a
    8000219c:	9ebd                	addw	a3,a3,a5
    8000219e:	03f6f693          	and	a3,a3,63
    800021a2:	9e9d                	subw	a3,a3,a5
    800021a4:	c154                	sw	a3,4(a0)
}
    800021a6:	6422                	ld	s0,8(sp)
    800021a8:	0141                	add	sp,sp,16
    800021aa:	8082                	ret
        for (j = i; j < q->tail - 1; j++)
    800021ac:	fff6859b          	addw	a1,a3,-1
    800021b0:	fcb7dce3          	bge	a5,a1,80002188 <pop_mid+0x3c>
          q->process[j] = q->process[j + 1];
    800021b4:	00379713          	sll	a4,a5,0x3
    800021b8:	972a                	add	a4,a4,a0
    800021ba:	6b10                	ld	a2,16(a4)
    800021bc:	e710                	sd	a2,8(a4)
          j = j % NPROC;
    800021be:	41f7d71b          	sraw	a4,a5,0x1f
    800021c2:	01a7571b          	srlw	a4,a4,0x1a
    800021c6:	9fb9                	addw	a5,a5,a4
    800021c8:	03f7f793          	and	a5,a5,63
    800021cc:	9f99                	subw	a5,a5,a4
        for (j = i; j < q->tail - 1; j++)
    800021ce:	2785                	addw	a5,a5,1
    800021d0:	feb7c2e3          	blt	a5,a1,800021b4 <pop_mid+0x68>
    800021d4:	bf55                	j	80002188 <pop_mid+0x3c>
      q->tail = NPROC - 1;
    800021d6:	03f00693          	li	a3,63
    800021da:	bf55                	j	8000218e <pop_mid+0x42>

00000000800021dc <sched>:
{
    800021dc:	7179                	add	sp,sp,-48
    800021de:	f406                	sd	ra,40(sp)
    800021e0:	f022                	sd	s0,32(sp)
    800021e2:	ec26                	sd	s1,24(sp)
    800021e4:	e84a                	sd	s2,16(sp)
    800021e6:	e44e                	sd	s3,8(sp)
    800021e8:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	814080e7          	jalr	-2028(ra) # 800019fe <myproc>
    800021f2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	964080e7          	jalr	-1692(ra) # 80000b58 <holding>
    800021fc:	c93d                	beqz	a0,80002272 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021fe:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002200:	2781                	sext.w	a5,a5
    80002202:	079e                	sll	a5,a5,0x7
    80002204:	0000f717          	auipc	a4,0xf
    80002208:	97c70713          	add	a4,a4,-1668 # 80010b80 <pid_lock>
    8000220c:	97ba                	add	a5,a5,a4
    8000220e:	0a87a703          	lw	a4,168(a5)
    80002212:	4785                	li	a5,1
    80002214:	06f71763          	bne	a4,a5,80002282 <sched+0xa6>
  if (p->state == RUNNING)
    80002218:	4c98                	lw	a4,24(s1)
    8000221a:	4791                	li	a5,4
    8000221c:	06f70b63          	beq	a4,a5,80002292 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002220:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002224:	8b89                	and	a5,a5,2
  if (intr_get())
    80002226:	efb5                	bnez	a5,800022a2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002228:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000222a:	0000f917          	auipc	s2,0xf
    8000222e:	95690913          	add	s2,s2,-1706 # 80010b80 <pid_lock>
    80002232:	2781                	sext.w	a5,a5
    80002234:	079e                	sll	a5,a5,0x7
    80002236:	97ca                	add	a5,a5,s2
    80002238:	0ac7a983          	lw	s3,172(a5)
    8000223c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000223e:	2781                	sext.w	a5,a5
    80002240:	079e                	sll	a5,a5,0x7
    80002242:	0000f597          	auipc	a1,0xf
    80002246:	97658593          	add	a1,a1,-1674 # 80010bb8 <cpus+0x8>
    8000224a:	95be                	add	a1,a1,a5
    8000224c:	06048513          	add	a0,s1,96
    80002250:	00001097          	auipc	ra,0x1
    80002254:	8d8080e7          	jalr	-1832(ra) # 80002b28 <swtch>
    80002258:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000225a:	2781                	sext.w	a5,a5
    8000225c:	079e                	sll	a5,a5,0x7
    8000225e:	993e                	add	s2,s2,a5
    80002260:	0b392623          	sw	s3,172(s2)
}
    80002264:	70a2                	ld	ra,40(sp)
    80002266:	7402                	ld	s0,32(sp)
    80002268:	64e2                	ld	s1,24(sp)
    8000226a:	6942                	ld	s2,16(sp)
    8000226c:	69a2                	ld	s3,8(sp)
    8000226e:	6145                	add	sp,sp,48
    80002270:	8082                	ret
    panic("sched p->lock");
    80002272:	00006517          	auipc	a0,0x6
    80002276:	fa650513          	add	a0,a0,-90 # 80008218 <digits+0x1d8>
    8000227a:	ffffe097          	auipc	ra,0xffffe
    8000227e:	2c2080e7          	jalr	706(ra) # 8000053c <panic>
    panic("sched locks");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	fa650513          	add	a0,a0,-90 # 80008228 <digits+0x1e8>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2b2080e7          	jalr	690(ra) # 8000053c <panic>
    panic("sched running");
    80002292:	00006517          	auipc	a0,0x6
    80002296:	fa650513          	add	a0,a0,-90 # 80008238 <digits+0x1f8>
    8000229a:	ffffe097          	auipc	ra,0xffffe
    8000229e:	2a2080e7          	jalr	674(ra) # 8000053c <panic>
    panic("sched interruptible");
    800022a2:	00006517          	auipc	a0,0x6
    800022a6:	fa650513          	add	a0,a0,-90 # 80008248 <digits+0x208>
    800022aa:	ffffe097          	auipc	ra,0xffffe
    800022ae:	292080e7          	jalr	658(ra) # 8000053c <panic>

00000000800022b2 <yield>:
{
    800022b2:	1101                	add	sp,sp,-32
    800022b4:	ec06                	sd	ra,24(sp)
    800022b6:	e822                	sd	s0,16(sp)
    800022b8:	e426                	sd	s1,8(sp)
    800022ba:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	742080e7          	jalr	1858(ra) # 800019fe <myproc>
    800022c4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	90c080e7          	jalr	-1780(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    800022ce:	478d                	li	a5,3
    800022d0:	cc9c                	sw	a5,24(s1)
  sched();
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	f0a080e7          	jalr	-246(ra) # 800021dc <sched>
  release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9aa080e7          	jalr	-1622(ra) # 80000c86 <release>
}
    800022e4:	60e2                	ld	ra,24(sp)
    800022e6:	6442                	ld	s0,16(sp)
    800022e8:	64a2                	ld	s1,8(sp)
    800022ea:	6105                	add	sp,sp,32
    800022ec:	8082                	ret

00000000800022ee <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022ee:	7179                	add	sp,sp,-48
    800022f0:	f406                	sd	ra,40(sp)
    800022f2:	f022                	sd	s0,32(sp)
    800022f4:	ec26                	sd	s1,24(sp)
    800022f6:	e84a                	sd	s2,16(sp)
    800022f8:	e44e                	sd	s3,8(sp)
    800022fa:	1800                	add	s0,sp,48
    800022fc:	89aa                	mv	s3,a0
    800022fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	6fe080e7          	jalr	1790(ra) # 800019fe <myproc>
    80002308:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8c8080e7          	jalr	-1848(ra) # 80000bd2 <acquire>
  release(lk);
    80002312:	854a                	mv	a0,s2
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	972080e7          	jalr	-1678(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    8000231c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002320:	4789                	li	a5,2
    80002322:	cc9c                	sw	a5,24(s1)

  sched();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	eb8080e7          	jalr	-328(ra) # 800021dc <sched>

  // Tidy up.
  p->chan = 0;
    8000232c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	954080e7          	jalr	-1708(ra) # 80000c86 <release>
  acquire(lk);
    8000233a:	854a                	mv	a0,s2
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	896080e7          	jalr	-1898(ra) # 80000bd2 <acquire>
}
    80002344:	70a2                	ld	ra,40(sp)
    80002346:	7402                	ld	s0,32(sp)
    80002348:	64e2                	ld	s1,24(sp)
    8000234a:	6942                	ld	s2,16(sp)
    8000234c:	69a2                	ld	s3,8(sp)
    8000234e:	6145                	add	sp,sp,48
    80002350:	8082                	ret

0000000080002352 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002352:	7139                	add	sp,sp,-64
    80002354:	fc06                	sd	ra,56(sp)
    80002356:	f822                	sd	s0,48(sp)
    80002358:	f426                	sd	s1,40(sp)
    8000235a:	f04a                	sd	s2,32(sp)
    8000235c:	ec4e                	sd	s3,24(sp)
    8000235e:	e852                	sd	s4,16(sp)
    80002360:	e456                	sd	s5,8(sp)
    80002362:	e05a                	sd	s6,0(sp)
    80002364:	0080                	add	s0,sp,64
    80002366:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002368:	0000f497          	auipc	s1,0xf
    8000236c:	c4848493          	add	s1,s1,-952 # 80010fb0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002370:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002372:	4b0d                	li	s6,3
        if (p->present_q == -1)
    80002374:	5afd                	li	s5,-1
  for (p = proc; p < &proc[NPROC]; p++)
    80002376:	00015917          	auipc	s2,0x15
    8000237a:	63a90913          	add	s2,s2,1594 # 800179b0 <mlfq>
    8000237e:	a811                	j	80002392 <wakeup+0x40>
        {
          p->present_q = 0;
          push(&mlfq[p->q_no], p, p->q_no);
        }
      }
      release(&p->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	904080e7          	jalr	-1788(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000238a:	1a848493          	add	s1,s1,424
    8000238e:	05248c63          	beq	s1,s2,800023e6 <wakeup+0x94>
    if (p != myproc())
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	66c080e7          	jalr	1644(ra) # 800019fe <myproc>
    8000239a:	fea488e3          	beq	s1,a0,8000238a <wakeup+0x38>
      acquire(&p->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	832080e7          	jalr	-1998(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800023a8:	4c9c                	lw	a5,24(s1)
    800023aa:	fd379be3          	bne	a5,s3,80002380 <wakeup+0x2e>
    800023ae:	709c                	ld	a5,32(s1)
    800023b0:	fd4798e3          	bne	a5,s4,80002380 <wakeup+0x2e>
        p->state = RUNNABLE;
    800023b4:	0164ac23          	sw	s6,24(s1)
        if (p->present_q == -1)
    800023b8:	1984a783          	lw	a5,408(s1)
    800023bc:	fd5792e3          	bne	a5,s5,80002380 <wakeup+0x2e>
          p->present_q = 0;
    800023c0:	1804ac23          	sw	zero,408(s1)
          push(&mlfq[p->q_no], p, p->q_no);
    800023c4:	1904a603          	lw	a2,400(s1)
    800023c8:	00561793          	sll	a5,a2,0x5
    800023cc:	97b2                	add	a5,a5,a2
    800023ce:	0792                	sll	a5,a5,0x4
    800023d0:	85a6                	mv	a1,s1
    800023d2:	00015517          	auipc	a0,0x15
    800023d6:	5de50513          	add	a0,a0,1502 # 800179b0 <mlfq>
    800023da:	953e                	add	a0,a0,a5
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	ce0080e7          	jalr	-800(ra) # 800020bc <push>
    800023e4:	bf71                	j	80002380 <wakeup+0x2e>
    }
  }
}
    800023e6:	70e2                	ld	ra,56(sp)
    800023e8:	7442                	ld	s0,48(sp)
    800023ea:	74a2                	ld	s1,40(sp)
    800023ec:	7902                	ld	s2,32(sp)
    800023ee:	69e2                	ld	s3,24(sp)
    800023f0:	6a42                	ld	s4,16(sp)
    800023f2:	6aa2                	ld	s5,8(sp)
    800023f4:	6b02                	ld	s6,0(sp)
    800023f6:	6121                	add	sp,sp,64
    800023f8:	8082                	ret

00000000800023fa <reparent>:
{
    800023fa:	7179                	add	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	add	s0,sp,48
    8000240a:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000240c:	0000f497          	auipc	s1,0xf
    80002410:	ba448493          	add	s1,s1,-1116 # 80010fb0 <proc>
      pp->parent = initproc;
    80002414:	00006a17          	auipc	s4,0x6
    80002418:	4f4a0a13          	add	s4,s4,1268 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	59498993          	add	s3,s3,1428 # 800179b0 <mlfq>
    80002424:	a029                	j	8000242e <reparent+0x34>
    80002426:	1a848493          	add	s1,s1,424
    8000242a:	01348d63          	beq	s1,s3,80002444 <reparent+0x4a>
    if (pp->parent == p)
    8000242e:	7c9c                	ld	a5,56(s1)
    80002430:	ff279be3          	bne	a5,s2,80002426 <reparent+0x2c>
      pp->parent = initproc;
    80002434:	000a3503          	ld	a0,0(s4)
    80002438:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	f18080e7          	jalr	-232(ra) # 80002352 <wakeup>
    80002442:	b7d5                	j	80002426 <reparent+0x2c>
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6a02                	ld	s4,0(sp)
    80002450:	6145                	add	sp,sp,48
    80002452:	8082                	ret

0000000080002454 <exit>:
{
    80002454:	7179                	add	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	add	s0,sp,48
    80002464:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	598080e7          	jalr	1432(ra) # 800019fe <myproc>
    8000246e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002470:	00006797          	auipc	a5,0x6
    80002474:	4987b783          	ld	a5,1176(a5) # 80008908 <initproc>
    80002478:	0d050493          	add	s1,a0,208
    8000247c:	15050913          	add	s2,a0,336
    80002480:	02a79363          	bne	a5,a0,800024a6 <exit+0x52>
    panic("init exiting");
    80002484:	00006517          	auipc	a0,0x6
    80002488:	ddc50513          	add	a0,a0,-548 # 80008260 <digits+0x220>
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	0b0080e7          	jalr	176(ra) # 8000053c <panic>
      fileclose(f);
    80002494:	00002097          	auipc	ra,0x2
    80002498:	734080e7          	jalr	1844(ra) # 80004bc8 <fileclose>
      p->ofile[fd] = 0;
    8000249c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800024a0:	04a1                	add	s1,s1,8
    800024a2:	01248563          	beq	s1,s2,800024ac <exit+0x58>
    if (p->ofile[fd])
    800024a6:	6088                	ld	a0,0(s1)
    800024a8:	f575                	bnez	a0,80002494 <exit+0x40>
    800024aa:	bfdd                	j	800024a0 <exit+0x4c>
  begin_op();
    800024ac:	00002097          	auipc	ra,0x2
    800024b0:	258080e7          	jalr	600(ra) # 80004704 <begin_op>
  iput(p->cwd);
    800024b4:	1509b503          	ld	a0,336(s3)
    800024b8:	00002097          	auipc	ra,0x2
    800024bc:	a60080e7          	jalr	-1440(ra) # 80003f18 <iput>
  end_op();
    800024c0:	00002097          	auipc	ra,0x2
    800024c4:	2be080e7          	jalr	702(ra) # 8000477e <end_op>
  p->cwd = 0;
    800024c8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024cc:	0000e497          	auipc	s1,0xe
    800024d0:	6cc48493          	add	s1,s1,1740 # 80010b98 <wait_lock>
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	6fc080e7          	jalr	1788(ra) # 80000bd2 <acquire>
  reparent(p);
    800024de:	854e                	mv	a0,s3
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	f1a080e7          	jalr	-230(ra) # 800023fa <reparent>
  wakeup(p->parent);
    800024e8:	0389b503          	ld	a0,56(s3)
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	e66080e7          	jalr	-410(ra) # 80002352 <wakeup>
  acquire(&p->lock);
    800024f4:	854e                	mv	a0,s3
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	6dc080e7          	jalr	1756(ra) # 80000bd2 <acquire>
  p->xstate = status;
    800024fe:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002502:	4795                	li	a5,5
    80002504:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002508:	00006797          	auipc	a5,0x6
    8000250c:	4087a783          	lw	a5,1032(a5) # 80008910 <ticks>
    80002510:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002514:	8526                	mv	a0,s1
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	770080e7          	jalr	1904(ra) # 80000c86 <release>
  sched();
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	cbe080e7          	jalr	-834(ra) # 800021dc <sched>
  panic("zombie exit");
    80002526:	00006517          	auipc	a0,0x6
    8000252a:	d4a50513          	add	a0,a0,-694 # 80008270 <digits+0x230>
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	00e080e7          	jalr	14(ra) # 8000053c <panic>

0000000080002536 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002536:	7179                	add	sp,sp,-48
    80002538:	f406                	sd	ra,40(sp)
    8000253a:	f022                	sd	s0,32(sp)
    8000253c:	ec26                	sd	s1,24(sp)
    8000253e:	e84a                	sd	s2,16(sp)
    80002540:	e44e                	sd	s3,8(sp)
    80002542:	1800                	add	s0,sp,48
    80002544:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002546:	0000f497          	auipc	s1,0xf
    8000254a:	a6a48493          	add	s1,s1,-1430 # 80010fb0 <proc>
    8000254e:	00015997          	auipc	s3,0x15
    80002552:	46298993          	add	s3,s3,1122 # 800179b0 <mlfq>
  {
    acquire(&p->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	67a080e7          	jalr	1658(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002560:	589c                	lw	a5,48(s1)
    80002562:	01278d63          	beq	a5,s2,8000257c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	71e080e7          	jalr	1822(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002570:	1a848493          	add	s1,s1,424
    80002574:	ff3491e3          	bne	s1,s3,80002556 <kill+0x20>
  }
  return -1;
    80002578:	557d                	li	a0,-1
    8000257a:	a829                	j	80002594 <kill+0x5e>
      p->killed = 1;
    8000257c:	4785                	li	a5,1
    8000257e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002580:	4c98                	lw	a4,24(s1)
    80002582:	4789                	li	a5,2
    80002584:	00f70f63          	beq	a4,a5,800025a2 <kill+0x6c>
      release(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	6fc080e7          	jalr	1788(ra) # 80000c86 <release>
      return 0;
    80002592:	4501                	li	a0,0
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6145                	add	sp,sp,48
    800025a0:	8082                	ret
        p->state = RUNNABLE;
    800025a2:	478d                	li	a5,3
    800025a4:	cc9c                	sw	a5,24(s1)
    800025a6:	b7cd                	j	80002588 <kill+0x52>

00000000800025a8 <setkilled>:

void setkilled(struct proc *p)
{
    800025a8:	1101                	add	sp,sp,-32
    800025aa:	ec06                	sd	ra,24(sp)
    800025ac:	e822                	sd	s0,16(sp)
    800025ae:	e426                	sd	s1,8(sp)
    800025b0:	1000                	add	s0,sp,32
    800025b2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	61e080e7          	jalr	1566(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800025bc:	4785                	li	a5,1
    800025be:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	6c4080e7          	jalr	1732(ra) # 80000c86 <release>
}
    800025ca:	60e2                	ld	ra,24(sp)
    800025cc:	6442                	ld	s0,16(sp)
    800025ce:	64a2                	ld	s1,8(sp)
    800025d0:	6105                	add	sp,sp,32
    800025d2:	8082                	ret

00000000800025d4 <killed>:

int killed(struct proc *p)
{
    800025d4:	1101                	add	sp,sp,-32
    800025d6:	ec06                	sd	ra,24(sp)
    800025d8:	e822                	sd	s0,16(sp)
    800025da:	e426                	sd	s1,8(sp)
    800025dc:	e04a                	sd	s2,0(sp)
    800025de:	1000                	add	s0,sp,32
    800025e0:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	5f0080e7          	jalr	1520(ra) # 80000bd2 <acquire>
  k = p->killed;
    800025ea:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	696080e7          	jalr	1686(ra) # 80000c86 <release>
  return k;
}
    800025f8:	854a                	mv	a0,s2
    800025fa:	60e2                	ld	ra,24(sp)
    800025fc:	6442                	ld	s0,16(sp)
    800025fe:	64a2                	ld	s1,8(sp)
    80002600:	6902                	ld	s2,0(sp)
    80002602:	6105                	add	sp,sp,32
    80002604:	8082                	ret

0000000080002606 <wait>:
{
    80002606:	715d                	add	sp,sp,-80
    80002608:	e486                	sd	ra,72(sp)
    8000260a:	e0a2                	sd	s0,64(sp)
    8000260c:	fc26                	sd	s1,56(sp)
    8000260e:	f84a                	sd	s2,48(sp)
    80002610:	f44e                	sd	s3,40(sp)
    80002612:	f052                	sd	s4,32(sp)
    80002614:	ec56                	sd	s5,24(sp)
    80002616:	e85a                	sd	s6,16(sp)
    80002618:	e45e                	sd	s7,8(sp)
    8000261a:	e062                	sd	s8,0(sp)
    8000261c:	0880                	add	s0,sp,80
    8000261e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	3de080e7          	jalr	990(ra) # 800019fe <myproc>
    80002628:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000262a:	0000e517          	auipc	a0,0xe
    8000262e:	56e50513          	add	a0,a0,1390 # 80010b98 <wait_lock>
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	5a0080e7          	jalr	1440(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000263a:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000263c:	4a15                	li	s4,5
        havekids = 1;
    8000263e:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002640:	00015997          	auipc	s3,0x15
    80002644:	37098993          	add	s3,s3,880 # 800179b0 <mlfq>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002648:	0000ec17          	auipc	s8,0xe
    8000264c:	550c0c13          	add	s8,s8,1360 # 80010b98 <wait_lock>
    80002650:	a0d1                	j	80002714 <wait+0x10e>
          pid = pp->pid;
    80002652:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002656:	000b0e63          	beqz	s6,80002672 <wait+0x6c>
    8000265a:	4691                	li	a3,4
    8000265c:	02c48613          	add	a2,s1,44
    80002660:	85da                	mv	a1,s6
    80002662:	05093503          	ld	a0,80(s2)
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	000080e7          	jalr	ra # 80001666 <copyout>
    8000266e:	04054163          	bltz	a0,800026b0 <wait+0xaa>
          freeproc(pp);
    80002672:	8526                	mv	a0,s1
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	53c080e7          	jalr	1340(ra) # 80001bb0 <freeproc>
          release(&pp->lock);
    8000267c:	8526                	mv	a0,s1
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	608080e7          	jalr	1544(ra) # 80000c86 <release>
          release(&wait_lock);
    80002686:	0000e517          	auipc	a0,0xe
    8000268a:	51250513          	add	a0,a0,1298 # 80010b98 <wait_lock>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	5f8080e7          	jalr	1528(ra) # 80000c86 <release>
}
    80002696:	854e                	mv	a0,s3
    80002698:	60a6                	ld	ra,72(sp)
    8000269a:	6406                	ld	s0,64(sp)
    8000269c:	74e2                	ld	s1,56(sp)
    8000269e:	7942                	ld	s2,48(sp)
    800026a0:	79a2                	ld	s3,40(sp)
    800026a2:	7a02                	ld	s4,32(sp)
    800026a4:	6ae2                	ld	s5,24(sp)
    800026a6:	6b42                	ld	s6,16(sp)
    800026a8:	6ba2                	ld	s7,8(sp)
    800026aa:	6c02                	ld	s8,0(sp)
    800026ac:	6161                	add	sp,sp,80
    800026ae:	8082                	ret
            release(&pp->lock);
    800026b0:	8526                	mv	a0,s1
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	5d4080e7          	jalr	1492(ra) # 80000c86 <release>
            release(&wait_lock);
    800026ba:	0000e517          	auipc	a0,0xe
    800026be:	4de50513          	add	a0,a0,1246 # 80010b98 <wait_lock>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5c4080e7          	jalr	1476(ra) # 80000c86 <release>
            return -1;
    800026ca:	59fd                	li	s3,-1
    800026cc:	b7e9                	j	80002696 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026ce:	1a848493          	add	s1,s1,424
    800026d2:	03348463          	beq	s1,s3,800026fa <wait+0xf4>
      if (pp->parent == p)
    800026d6:	7c9c                	ld	a5,56(s1)
    800026d8:	ff279be3          	bne	a5,s2,800026ce <wait+0xc8>
        acquire(&pp->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	4f4080e7          	jalr	1268(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    800026e6:	4c9c                	lw	a5,24(s1)
    800026e8:	f74785e3          	beq	a5,s4,80002652 <wait+0x4c>
        release(&pp->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	598080e7          	jalr	1432(ra) # 80000c86 <release>
        havekids = 1;
    800026f6:	8756                	mv	a4,s5
    800026f8:	bfd9                	j	800026ce <wait+0xc8>
    if (!havekids || killed(p))
    800026fa:	c31d                	beqz	a4,80002720 <wait+0x11a>
    800026fc:	854a                	mv	a0,s2
    800026fe:	00000097          	auipc	ra,0x0
    80002702:	ed6080e7          	jalr	-298(ra) # 800025d4 <killed>
    80002706:	ed09                	bnez	a0,80002720 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002708:	85e2                	mv	a1,s8
    8000270a:	854a                	mv	a0,s2
    8000270c:	00000097          	auipc	ra,0x0
    80002710:	be2080e7          	jalr	-1054(ra) # 800022ee <sleep>
    havekids = 0;
    80002714:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002716:	0000f497          	auipc	s1,0xf
    8000271a:	89a48493          	add	s1,s1,-1894 # 80010fb0 <proc>
    8000271e:	bf65                	j	800026d6 <wait+0xd0>
      release(&wait_lock);
    80002720:	0000e517          	auipc	a0,0xe
    80002724:	47850513          	add	a0,a0,1144 # 80010b98 <wait_lock>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	55e080e7          	jalr	1374(ra) # 80000c86 <release>
      return -1;
    80002730:	59fd                	li	s3,-1
    80002732:	b795                	j	80002696 <wait+0x90>

0000000080002734 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002734:	7179                	add	sp,sp,-48
    80002736:	f406                	sd	ra,40(sp)
    80002738:	f022                	sd	s0,32(sp)
    8000273a:	ec26                	sd	s1,24(sp)
    8000273c:	e84a                	sd	s2,16(sp)
    8000273e:	e44e                	sd	s3,8(sp)
    80002740:	e052                	sd	s4,0(sp)
    80002742:	1800                	add	s0,sp,48
    80002744:	84aa                	mv	s1,a0
    80002746:	892e                	mv	s2,a1
    80002748:	89b2                	mv	s3,a2
    8000274a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	2b2080e7          	jalr	690(ra) # 800019fe <myproc>
  if (user_dst)
    80002754:	c08d                	beqz	s1,80002776 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002756:	86d2                	mv	a3,s4
    80002758:	864e                	mv	a2,s3
    8000275a:	85ca                	mv	a1,s2
    8000275c:	6928                	ld	a0,80(a0)
    8000275e:	fffff097          	auipc	ra,0xfffff
    80002762:	f08080e7          	jalr	-248(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	69a2                	ld	s3,8(sp)
    80002770:	6a02                	ld	s4,0(sp)
    80002772:	6145                	add	sp,sp,48
    80002774:	8082                	ret
    memmove((char *)dst, src, len);
    80002776:	000a061b          	sext.w	a2,s4
    8000277a:	85ce                	mv	a1,s3
    8000277c:	854a                	mv	a0,s2
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	5ac080e7          	jalr	1452(ra) # 80000d2a <memmove>
    return 0;
    80002786:	8526                	mv	a0,s1
    80002788:	bff9                	j	80002766 <either_copyout+0x32>

000000008000278a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000278a:	7179                	add	sp,sp,-48
    8000278c:	f406                	sd	ra,40(sp)
    8000278e:	f022                	sd	s0,32(sp)
    80002790:	ec26                	sd	s1,24(sp)
    80002792:	e84a                	sd	s2,16(sp)
    80002794:	e44e                	sd	s3,8(sp)
    80002796:	e052                	sd	s4,0(sp)
    80002798:	1800                	add	s0,sp,48
    8000279a:	892a                	mv	s2,a0
    8000279c:	84ae                	mv	s1,a1
    8000279e:	89b2                	mv	s3,a2
    800027a0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027a2:	fffff097          	auipc	ra,0xfffff
    800027a6:	25c080e7          	jalr	604(ra) # 800019fe <myproc>
  if (user_src)
    800027aa:	c08d                	beqz	s1,800027cc <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027ac:	86d2                	mv	a3,s4
    800027ae:	864e                	mv	a2,s3
    800027b0:	85ca                	mv	a1,s2
    800027b2:	6928                	ld	a0,80(a0)
    800027b4:	fffff097          	auipc	ra,0xfffff
    800027b8:	f3e080e7          	jalr	-194(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027bc:	70a2                	ld	ra,40(sp)
    800027be:	7402                	ld	s0,32(sp)
    800027c0:	64e2                	ld	s1,24(sp)
    800027c2:	6942                	ld	s2,16(sp)
    800027c4:	69a2                	ld	s3,8(sp)
    800027c6:	6a02                	ld	s4,0(sp)
    800027c8:	6145                	add	sp,sp,48
    800027ca:	8082                	ret
    memmove(dst, (char *)src, len);
    800027cc:	000a061b          	sext.w	a2,s4
    800027d0:	85ce                	mv	a1,s3
    800027d2:	854a                	mv	a0,s2
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	556080e7          	jalr	1366(ra) # 80000d2a <memmove>
    return 0;
    800027dc:	8526                	mv	a0,s1
    800027de:	bff9                	j	800027bc <either_copyin+0x32>

00000000800027e0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027e0:	7159                	add	sp,sp,-112
    800027e2:	f486                	sd	ra,104(sp)
    800027e4:	f0a2                	sd	s0,96(sp)
    800027e6:	eca6                	sd	s1,88(sp)
    800027e8:	e8ca                	sd	s2,80(sp)
    800027ea:	e4ce                	sd	s3,72(sp)
    800027ec:	e0d2                	sd	s4,64(sp)
    800027ee:	fc56                	sd	s5,56(sp)
    800027f0:	f85a                	sd	s6,48(sp)
    800027f2:	f45e                	sd	s7,40(sp)
    800027f4:	f062                	sd	s8,32(sp)
    800027f6:	ec66                	sd	s9,24(sp)
    800027f8:	e86a                	sd	s10,16(sp)
    800027fa:	e46e                	sd	s11,8(sp)
    800027fc:	1880                	add	s0,sp,112
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027fe:	00006517          	auipc	a0,0x6
    80002802:	aba50513          	add	a0,a0,-1350 # 800082b8 <digits+0x278>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	d80080e7          	jalr	-640(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000280e:	0000f497          	auipc	s1,0xf
    80002812:	8fa48493          	add	s1,s1,-1798 # 80011108 <proc+0x158>
    80002816:	00015917          	auipc	s2,0x15
    8000281a:	2f290913          	add	s2,s2,754 # 80017b08 <mlfq+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002820:	00006997          	auipc	s3,0x6
    80002824:	a6098993          	add	s3,s3,-1440 # 80008280 <digits+0x240>
#ifdef MLFQ
    printf("%d %s %s %d %d", p->pid, state, p->name, p->q_no, ticks);
#endif
#ifndef MLFQ
    printf("%d %s %s", p->pid, state, p->name);
    80002828:	00006a97          	auipc	s5,0x6
    8000282c:	a60a8a93          	add	s5,s5,-1440 # 80008288 <digits+0x248>
#endif
    printf("\n");
    80002830:	00006a17          	auipc	s4,0x6
    80002834:	a88a0a13          	add	s4,s4,-1400 # 800082b8 <digits+0x278>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002838:	00006b97          	auipc	s7,0x6
    8000283c:	ab8b8b93          	add	s7,s7,-1352 # 800082f0 <states.0>
    80002840:	a00d                	j	80002862 <procdump+0x82>
    printf("%d %s %s", p->pid, state, p->name);
    80002842:	ed86a583          	lw	a1,-296(a3)
    80002846:	8556                	mv	a0,s5
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d3e080e7          	jalr	-706(ra) # 80000586 <printf>
    printf("\n");
    80002850:	8552                	mv	a0,s4
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	d34080e7          	jalr	-716(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000285a:	1a848493          	add	s1,s1,424
    8000285e:	03248263          	beq	s1,s2,80002882 <procdump+0xa2>
    if (p->state == UNUSED)
    80002862:	86a6                	mv	a3,s1
    80002864:	ec04a783          	lw	a5,-320(s1)
    80002868:	dbed                	beqz	a5,8000285a <procdump+0x7a>
      state = "???";
    8000286a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000286c:	fcfb6be3          	bltu	s6,a5,80002842 <procdump+0x62>
    80002870:	02079713          	sll	a4,a5,0x20
    80002874:	01d75793          	srl	a5,a4,0x1d
    80002878:	97de                	add	a5,a5,s7
    8000287a:	6390                	ld	a2,0(a5)
    8000287c:	f279                	bnez	a2,80002842 <procdump+0x62>
      state = "???";
    8000287e:	864e                	mv	a2,s3
    80002880:	b7c9                	j	80002842 <procdump+0x62>
    80002882:	00015a97          	auipc	s5,0x15
    80002886:	12ea8a93          	add	s5,s5,302 # 800179b0 <mlfq>
  for (p = proc; p < &proc[NPROC]; p++)
    8000288a:	4b81                	li	s7,0
  }
  for (int i = 0; i < 4; i++)
    8000288c:	4b01                	li	s6,0
  {
    printf("que %d -", i);
    8000288e:	00006d17          	auipc	s10,0x6
    80002892:	a0ad0d13          	add	s10,s10,-1526 # 80008298 <digits+0x258>
    80002896:	8dd6                	mv	s11,s5
    int j = mlfq[i].head;
    while (j < mlfq[i].tail)
    {
      printf("%d |", mlfq[i].process[j]->pid);
    80002898:	00006a17          	auipc	s4,0x6
    8000289c:	a10a0a13          	add	s4,s4,-1520 # 800082a8 <digits+0x268>
      j++;
    }
    printf("\n");
    800028a0:	00006c97          	auipc	s9,0x6
    800028a4:	a18c8c93          	add	s9,s9,-1512 # 800082b8 <digits+0x278>
  for (int i = 0; i < 4; i++)
    800028a8:	4c11                	li	s8,4
    printf("que %d -", i);
    800028aa:	85da                	mv	a1,s6
    800028ac:	856a                	mv	a0,s10
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	cd8080e7          	jalr	-808(ra) # 80000586 <printf>
    int j = mlfq[i].head;
    800028b6:	89d6                	mv	s3,s5
    800028b8:	000aa903          	lw	s2,0(s5)
    while (j < mlfq[i].tail)
    800028bc:	004aa783          	lw	a5,4(s5)
    800028c0:	02f95463          	bge	s2,a5,800028e8 <procdump+0x108>
    800028c4:	001b8493          	add	s1,s7,1
    800028c8:	94ca                	add	s1,s1,s2
    800028ca:	048e                	sll	s1,s1,0x3
    800028cc:	94ee                	add	s1,s1,s11
      printf("%d |", mlfq[i].process[j]->pid);
    800028ce:	609c                	ld	a5,0(s1)
    800028d0:	5b8c                	lw	a1,48(a5)
    800028d2:	8552                	mv	a0,s4
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	cb2080e7          	jalr	-846(ra) # 80000586 <printf>
      j++;
    800028dc:	2905                	addw	s2,s2,1
    while (j < mlfq[i].tail)
    800028de:	04a1                	add	s1,s1,8
    800028e0:	0049a783          	lw	a5,4(s3)
    800028e4:	fef945e3          	blt	s2,a5,800028ce <procdump+0xee>
    printf("\n");
    800028e8:	8566                	mv	a0,s9
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c9c080e7          	jalr	-868(ra) # 80000586 <printf>
  for (int i = 0; i < 4; i++)
    800028f2:	2b05                	addw	s6,s6,1
    800028f4:	210a8a93          	add	s5,s5,528
    800028f8:	042b8b93          	add	s7,s7,66
    800028fc:	fb8b17e3          	bne	s6,s8,800028aa <procdump+0xca>
  }
}
    80002900:	70a6                	ld	ra,104(sp)
    80002902:	7406                	ld	s0,96(sp)
    80002904:	64e6                	ld	s1,88(sp)
    80002906:	6946                	ld	s2,80(sp)
    80002908:	69a6                	ld	s3,72(sp)
    8000290a:	6a06                	ld	s4,64(sp)
    8000290c:	7ae2                	ld	s5,56(sp)
    8000290e:	7b42                	ld	s6,48(sp)
    80002910:	7ba2                	ld	s7,40(sp)
    80002912:	7c02                	ld	s8,32(sp)
    80002914:	6ce2                	ld	s9,24(sp)
    80002916:	6d42                	ld	s10,16(sp)
    80002918:	6da2                	ld	s11,8(sp)
    8000291a:	6165                	add	sp,sp,112
    8000291c:	8082                	ret

000000008000291e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000291e:	711d                	add	sp,sp,-96
    80002920:	ec86                	sd	ra,88(sp)
    80002922:	e8a2                	sd	s0,80(sp)
    80002924:	e4a6                	sd	s1,72(sp)
    80002926:	e0ca                	sd	s2,64(sp)
    80002928:	fc4e                	sd	s3,56(sp)
    8000292a:	f852                	sd	s4,48(sp)
    8000292c:	f456                	sd	s5,40(sp)
    8000292e:	f05a                	sd	s6,32(sp)
    80002930:	ec5e                	sd	s7,24(sp)
    80002932:	e862                	sd	s8,16(sp)
    80002934:	e466                	sd	s9,8(sp)
    80002936:	e06a                	sd	s10,0(sp)
    80002938:	1080                	add	s0,sp,96
    8000293a:	8b2a                	mv	s6,a0
    8000293c:	8bae                	mv	s7,a1
    8000293e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	0be080e7          	jalr	190(ra) # 800019fe <myproc>
    80002948:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000294a:	0000e517          	auipc	a0,0xe
    8000294e:	24e50513          	add	a0,a0,590 # 80010b98 <wait_lock>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	280080e7          	jalr	640(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000295a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000295c:	4a15                	li	s4,5
        havekids = 1;
    8000295e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002960:	00015997          	auipc	s3,0x15
    80002964:	05098993          	add	s3,s3,80 # 800179b0 <mlfq>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002968:	0000ed17          	auipc	s10,0xe
    8000296c:	230d0d13          	add	s10,s10,560 # 80010b98 <wait_lock>
    80002970:	a8e9                	j	80002a4a <waitx+0x12c>
          pid = np->pid;
    80002972:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002976:	1684a783          	lw	a5,360(s1)
    8000297a:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000297e:	16c4a703          	lw	a4,364(s1)
    80002982:	9f3d                	addw	a4,a4,a5
    80002984:	1704a783          	lw	a5,368(s1)
    80002988:	9f99                	subw	a5,a5,a4
    8000298a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000298e:	000b0e63          	beqz	s6,800029aa <waitx+0x8c>
    80002992:	4691                	li	a3,4
    80002994:	02c48613          	add	a2,s1,44
    80002998:	85da                	mv	a1,s6
    8000299a:	05093503          	ld	a0,80(s2)
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	cc8080e7          	jalr	-824(ra) # 80001666 <copyout>
    800029a6:	04054363          	bltz	a0,800029ec <waitx+0xce>
          freeproc(np);
    800029aa:	8526                	mv	a0,s1
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	204080e7          	jalr	516(ra) # 80001bb0 <freeproc>
          release(&np->lock);
    800029b4:	8526                	mv	a0,s1
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	2d0080e7          	jalr	720(ra) # 80000c86 <release>
          release(&wait_lock);
    800029be:	0000e517          	auipc	a0,0xe
    800029c2:	1da50513          	add	a0,a0,474 # 80010b98 <wait_lock>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	2c0080e7          	jalr	704(ra) # 80000c86 <release>
  }
}
    800029ce:	854e                	mv	a0,s3
    800029d0:	60e6                	ld	ra,88(sp)
    800029d2:	6446                	ld	s0,80(sp)
    800029d4:	64a6                	ld	s1,72(sp)
    800029d6:	6906                	ld	s2,64(sp)
    800029d8:	79e2                	ld	s3,56(sp)
    800029da:	7a42                	ld	s4,48(sp)
    800029dc:	7aa2                	ld	s5,40(sp)
    800029de:	7b02                	ld	s6,32(sp)
    800029e0:	6be2                	ld	s7,24(sp)
    800029e2:	6c42                	ld	s8,16(sp)
    800029e4:	6ca2                	ld	s9,8(sp)
    800029e6:	6d02                	ld	s10,0(sp)
    800029e8:	6125                	add	sp,sp,96
    800029ea:	8082                	ret
            release(&np->lock);
    800029ec:	8526                	mv	a0,s1
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	298080e7          	jalr	664(ra) # 80000c86 <release>
            release(&wait_lock);
    800029f6:	0000e517          	auipc	a0,0xe
    800029fa:	1a250513          	add	a0,a0,418 # 80010b98 <wait_lock>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	288080e7          	jalr	648(ra) # 80000c86 <release>
            return -1;
    80002a06:	59fd                	li	s3,-1
    80002a08:	b7d9                	j	800029ce <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a0a:	1a848493          	add	s1,s1,424
    80002a0e:	03348463          	beq	s1,s3,80002a36 <waitx+0x118>
      if (np->parent == p)
    80002a12:	7c9c                	ld	a5,56(s1)
    80002a14:	ff279be3          	bne	a5,s2,80002a0a <waitx+0xec>
        acquire(&np->lock);
    80002a18:	8526                	mv	a0,s1
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	1b8080e7          	jalr	440(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002a22:	4c9c                	lw	a5,24(s1)
    80002a24:	f54787e3          	beq	a5,s4,80002972 <waitx+0x54>
        release(&np->lock);
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	25c080e7          	jalr	604(ra) # 80000c86 <release>
        havekids = 1;
    80002a32:	8756                	mv	a4,s5
    80002a34:	bfd9                	j	80002a0a <waitx+0xec>
    if (!havekids || p->killed)
    80002a36:	c305                	beqz	a4,80002a56 <waitx+0x138>
    80002a38:	02892783          	lw	a5,40(s2)
    80002a3c:	ef89                	bnez	a5,80002a56 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a3e:	85ea                	mv	a1,s10
    80002a40:	854a                	mv	a0,s2
    80002a42:	00000097          	auipc	ra,0x0
    80002a46:	8ac080e7          	jalr	-1876(ra) # 800022ee <sleep>
    havekids = 0;
    80002a4a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002a4c:	0000e497          	auipc	s1,0xe
    80002a50:	56448493          	add	s1,s1,1380 # 80010fb0 <proc>
    80002a54:	bf7d                	j	80002a12 <waitx+0xf4>
      release(&wait_lock);
    80002a56:	0000e517          	auipc	a0,0xe
    80002a5a:	14250513          	add	a0,a0,322 # 80010b98 <wait_lock>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	228080e7          	jalr	552(ra) # 80000c86 <release>
      return -1;
    80002a66:	59fd                	li	s3,-1
    80002a68:	b79d                	j	800029ce <waitx+0xb0>

0000000080002a6a <update_time>:

void update_time()
{
    80002a6a:	7139                	add	sp,sp,-64
    80002a6c:	fc06                	sd	ra,56(sp)
    80002a6e:	f822                	sd	s0,48(sp)
    80002a70:	f426                	sd	s1,40(sp)
    80002a72:	f04a                	sd	s2,32(sp)
    80002a74:	ec4e                	sd	s3,24(sp)
    80002a76:	e852                	sd	s4,16(sp)
    80002a78:	e456                	sd	s5,8(sp)
    80002a7a:	e05a                	sd	s6,0(sp)
    80002a7c:	0080                	add	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a7e:	0000e497          	auipc	s1,0xe
    80002a82:	53248493          	add	s1,s1,1330 # 80010fb0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a86:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002a88:	00015917          	auipc	s2,0x15
    80002a8c:	f2890913          	add	s2,s2,-216 # 800179b0 <mlfq>
    80002a90:	a811                	j	80002aa4 <update_time+0x3a>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002a92:	8526                	mv	a0,s1
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	1f2080e7          	jalr	498(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a9c:	1a848493          	add	s1,s1,424
    80002aa0:	03248063          	beq	s1,s2,80002ac0 <update_time+0x56>
    acquire(&p->lock);
    80002aa4:	8526                	mv	a0,s1
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	12c080e7          	jalr	300(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002aae:	4c9c                	lw	a5,24(s1)
    80002ab0:	ff3791e3          	bne	a5,s3,80002a92 <update_time+0x28>
      p->rtime++;
    80002ab4:	1684a783          	lw	a5,360(s1)
    80002ab8:	2785                	addw	a5,a5,1
    80002aba:	16f4a423          	sw	a5,360(s1)
    80002abe:	bfd1                	j	80002a92 <update_time+0x28>
  }
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac0:	0000e497          	auipc	s1,0xe
    80002ac4:	4f048493          	add	s1,s1,1264 # 80010fb0 <proc>
  {
    if (p->pid >= 9 && p->pid <= 13)
    80002ac8:	4991                	li	s3,4
    {
      if (p->state == RUNNABLE || p->state == RUNNING)
    80002aca:	4a05                	li	s4,1
      {
        printf("%d %d %d\n", p->pid, ticks, p->q_no);
    80002acc:	00006b17          	auipc	s6,0x6
    80002ad0:	e44b0b13          	add	s6,s6,-444 # 80008910 <ticks>
    80002ad4:	00005a97          	auipc	s5,0x5
    80002ad8:	7dca8a93          	add	s5,s5,2012 # 800082b0 <digits+0x270>
  for (p = proc; p < &proc[NPROC]; p++)
    80002adc:	00015917          	auipc	s2,0x15
    80002ae0:	ed490913          	add	s2,s2,-300 # 800179b0 <mlfq>
    80002ae4:	a029                	j	80002aee <update_time+0x84>
    80002ae6:	1a848493          	add	s1,s1,424
    80002aea:	03248563          	beq	s1,s2,80002b14 <update_time+0xaa>
    if (p->pid >= 9 && p->pid <= 13)
    80002aee:	588c                	lw	a1,48(s1)
    80002af0:	ff75879b          	addw	a5,a1,-9
    80002af4:	fef9e9e3          	bltu	s3,a5,80002ae6 <update_time+0x7c>
      if (p->state == RUNNABLE || p->state == RUNNING)
    80002af8:	4c9c                	lw	a5,24(s1)
    80002afa:	37f5                	addw	a5,a5,-3
    80002afc:	fefa65e3          	bltu	s4,a5,80002ae6 <update_time+0x7c>
        printf("%d %d %d\n", p->pid, ticks, p->q_no);
    80002b00:	1904a683          	lw	a3,400(s1)
    80002b04:	000b2603          	lw	a2,0(s6)
    80002b08:	8556                	mv	a0,s5
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a7c080e7          	jalr	-1412(ra) # 80000586 <printf>
    80002b12:	bfd1                	j	80002ae6 <update_time+0x7c>
      }
    }
  }
}
    80002b14:	70e2                	ld	ra,56(sp)
    80002b16:	7442                	ld	s0,48(sp)
    80002b18:	74a2                	ld	s1,40(sp)
    80002b1a:	7902                	ld	s2,32(sp)
    80002b1c:	69e2                	ld	s3,24(sp)
    80002b1e:	6a42                	ld	s4,16(sp)
    80002b20:	6aa2                	ld	s5,8(sp)
    80002b22:	6b02                	ld	s6,0(sp)
    80002b24:	6121                	add	sp,sp,64
    80002b26:	8082                	ret

0000000080002b28 <swtch>:
    80002b28:	00153023          	sd	ra,0(a0)
    80002b2c:	00253423          	sd	sp,8(a0)
    80002b30:	e900                	sd	s0,16(a0)
    80002b32:	ed04                	sd	s1,24(a0)
    80002b34:	03253023          	sd	s2,32(a0)
    80002b38:	03353423          	sd	s3,40(a0)
    80002b3c:	03453823          	sd	s4,48(a0)
    80002b40:	03553c23          	sd	s5,56(a0)
    80002b44:	05653023          	sd	s6,64(a0)
    80002b48:	05753423          	sd	s7,72(a0)
    80002b4c:	05853823          	sd	s8,80(a0)
    80002b50:	05953c23          	sd	s9,88(a0)
    80002b54:	07a53023          	sd	s10,96(a0)
    80002b58:	07b53423          	sd	s11,104(a0)
    80002b5c:	0005b083          	ld	ra,0(a1)
    80002b60:	0085b103          	ld	sp,8(a1)
    80002b64:	6980                	ld	s0,16(a1)
    80002b66:	6d84                	ld	s1,24(a1)
    80002b68:	0205b903          	ld	s2,32(a1)
    80002b6c:	0285b983          	ld	s3,40(a1)
    80002b70:	0305ba03          	ld	s4,48(a1)
    80002b74:	0385ba83          	ld	s5,56(a1)
    80002b78:	0405bb03          	ld	s6,64(a1)
    80002b7c:	0485bb83          	ld	s7,72(a1)
    80002b80:	0505bc03          	ld	s8,80(a1)
    80002b84:	0585bc83          	ld	s9,88(a1)
    80002b88:	0605bd03          	ld	s10,96(a1)
    80002b8c:	0685bd83          	ld	s11,104(a1)
    80002b90:	8082                	ret

0000000080002b92 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b92:	1141                	add	sp,sp,-16
    80002b94:	e406                	sd	ra,8(sp)
    80002b96:	e022                	sd	s0,0(sp)
    80002b98:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002b9a:	00005597          	auipc	a1,0x5
    80002b9e:	78658593          	add	a1,a1,1926 # 80008320 <states.0+0x30>
    80002ba2:	00015517          	auipc	a0,0x15
    80002ba6:	64e50513          	add	a0,a0,1614 # 800181f0 <tickslock>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	f98080e7          	jalr	-104(ra) # 80000b42 <initlock>
}
    80002bb2:	60a2                	ld	ra,8(sp)
    80002bb4:	6402                	ld	s0,0(sp)
    80002bb6:	0141                	add	sp,sp,16
    80002bb8:	8082                	ret

0000000080002bba <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bba:	1141                	add	sp,sp,-16
    80002bbc:	e422                	sd	s0,8(sp)
    80002bbe:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc0:	00003797          	auipc	a5,0x3
    80002bc4:	64078793          	add	a5,a5,1600 # 80006200 <kernelvec>
    80002bc8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bcc:	6422                	ld	s0,8(sp)
    80002bce:	0141                	add	sp,sp,16
    80002bd0:	8082                	ret

0000000080002bd2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002bd2:	1141                	add	sp,sp,-16
    80002bd4:	e406                	sd	ra,8(sp)
    80002bd6:	e022                	sd	s0,0(sp)
    80002bd8:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002bda:	fffff097          	auipc	ra,0xfffff
    80002bde:	e24080e7          	jalr	-476(ra) # 800019fe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002be6:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bec:	00004697          	auipc	a3,0x4
    80002bf0:	41468693          	add	a3,a3,1044 # 80007000 <_trampoline>
    80002bf4:	00004717          	auipc	a4,0x4
    80002bf8:	40c70713          	add	a4,a4,1036 # 80007000 <_trampoline>
    80002bfc:	8f15                	sub	a4,a4,a3
    80002bfe:	040007b7          	lui	a5,0x4000
    80002c02:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c04:	07b2                	sll	a5,a5,0xc
    80002c06:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c08:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c0c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c0e:	18002673          	csrr	a2,satp
    80002c12:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c14:	6d30                	ld	a2,88(a0)
    80002c16:	6138                	ld	a4,64(a0)
    80002c18:	6585                	lui	a1,0x1
    80002c1a:	972e                	add	a4,a4,a1
    80002c1c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c1e:	6d38                	ld	a4,88(a0)
    80002c20:	00000617          	auipc	a2,0x0
    80002c24:	14260613          	add	a2,a2,322 # 80002d62 <usertrap>
    80002c28:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c2a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c2c:	8612                	mv	a2,tp
    80002c2e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c30:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c34:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c38:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c40:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c42:	6f18                	ld	a4,24(a4)
    80002c44:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c48:	6928                	ld	a0,80(a0)
    80002c4a:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c4c:	00004717          	auipc	a4,0x4
    80002c50:	45070713          	add	a4,a4,1104 # 8000709c <userret>
    80002c54:	8f15                	sub	a4,a4,a3
    80002c56:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c58:	577d                	li	a4,-1
    80002c5a:	177e                	sll	a4,a4,0x3f
    80002c5c:	8d59                	or	a0,a0,a4
    80002c5e:	9782                	jalr	a5
}
    80002c60:	60a2                	ld	ra,8(sp)
    80002c62:	6402                	ld	s0,0(sp)
    80002c64:	0141                	add	sp,sp,16
    80002c66:	8082                	ret

0000000080002c68 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c68:	1101                	add	sp,sp,-32
    80002c6a:	ec06                	sd	ra,24(sp)
    80002c6c:	e822                	sd	s0,16(sp)
    80002c6e:	e426                	sd	s1,8(sp)
    80002c70:	e04a                	sd	s2,0(sp)
    80002c72:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002c74:	00015917          	auipc	s2,0x15
    80002c78:	57c90913          	add	s2,s2,1404 # 800181f0 <tickslock>
    80002c7c:	854a                	mv	a0,s2
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	f54080e7          	jalr	-172(ra) # 80000bd2 <acquire>
  ticks++;
    80002c86:	00006497          	auipc	s1,0x6
    80002c8a:	c8a48493          	add	s1,s1,-886 # 80008910 <ticks>
    80002c8e:	409c                	lw	a5,0(s1)
    80002c90:	2785                	addw	a5,a5,1
    80002c92:	c09c                	sw	a5,0(s1)
  update_time();
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	dd6080e7          	jalr	-554(ra) # 80002a6a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	6b4080e7          	jalr	1716(ra) # 80002352 <wakeup>
  release(&tickslock);
    80002ca6:	854a                	mv	a0,s2
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	fde080e7          	jalr	-34(ra) # 80000c86 <release>
}
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	64a2                	ld	s1,8(sp)
    80002cb6:	6902                	ld	s2,0(sp)
    80002cb8:	6105                	add	sp,sp,32
    80002cba:	8082                	ret

0000000080002cbc <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cbc:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002cc0:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002cc2:	0807df63          	bgez	a5,80002d60 <devintr+0xa4>
{
    80002cc6:	1101                	add	sp,sp,-32
    80002cc8:	ec06                	sd	ra,24(sp)
    80002cca:	e822                	sd	s0,16(sp)
    80002ccc:	e426                	sd	s1,8(sp)
    80002cce:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002cd0:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002cd4:	46a5                	li	a3,9
    80002cd6:	00d70d63          	beq	a4,a3,80002cf0 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002cda:	577d                	li	a4,-1
    80002cdc:	177e                	sll	a4,a4,0x3f
    80002cde:	0705                	add	a4,a4,1
    return 0;
    80002ce0:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002ce2:	04e78e63          	beq	a5,a4,80002d3e <devintr+0x82>
  }
}
    80002ce6:	60e2                	ld	ra,24(sp)
    80002ce8:	6442                	ld	s0,16(sp)
    80002cea:	64a2                	ld	s1,8(sp)
    80002cec:	6105                	add	sp,sp,32
    80002cee:	8082                	ret
    int irq = plic_claim();
    80002cf0:	00003097          	auipc	ra,0x3
    80002cf4:	618080e7          	jalr	1560(ra) # 80006308 <plic_claim>
    80002cf8:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002cfa:	47a9                	li	a5,10
    80002cfc:	02f50763          	beq	a0,a5,80002d2a <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002d00:	4785                	li	a5,1
    80002d02:	02f50963          	beq	a0,a5,80002d34 <devintr+0x78>
    return 1;
    80002d06:	4505                	li	a0,1
    else if (irq)
    80002d08:	dcf9                	beqz	s1,80002ce6 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d0a:	85a6                	mv	a1,s1
    80002d0c:	00005517          	auipc	a0,0x5
    80002d10:	61c50513          	add	a0,a0,1564 # 80008328 <states.0+0x38>
    80002d14:	ffffe097          	auipc	ra,0xffffe
    80002d18:	872080e7          	jalr	-1934(ra) # 80000586 <printf>
      plic_complete(irq);
    80002d1c:	8526                	mv	a0,s1
    80002d1e:	00003097          	auipc	ra,0x3
    80002d22:	60e080e7          	jalr	1550(ra) # 8000632c <plic_complete>
    return 1;
    80002d26:	4505                	li	a0,1
    80002d28:	bf7d                	j	80002ce6 <devintr+0x2a>
      uartintr();
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	c6a080e7          	jalr	-918(ra) # 80000994 <uartintr>
    if (irq)
    80002d32:	b7ed                	j	80002d1c <devintr+0x60>
      virtio_disk_intr();
    80002d34:	00004097          	auipc	ra,0x4
    80002d38:	abe080e7          	jalr	-1346(ra) # 800067f2 <virtio_disk_intr>
    if (irq)
    80002d3c:	b7c5                	j	80002d1c <devintr+0x60>
    if (cpuid() == 0)
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	c94080e7          	jalr	-876(ra) # 800019d2 <cpuid>
    80002d46:	c901                	beqz	a0,80002d56 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d48:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d4c:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d4e:	14479073          	csrw	sip,a5
    return 2;
    80002d52:	4509                	li	a0,2
    80002d54:	bf49                	j	80002ce6 <devintr+0x2a>
      clockintr();
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	f12080e7          	jalr	-238(ra) # 80002c68 <clockintr>
    80002d5e:	b7ed                	j	80002d48 <devintr+0x8c>
}
    80002d60:	8082                	ret

0000000080002d62 <usertrap>:
{
    80002d62:	1101                	add	sp,sp,-32
    80002d64:	ec06                	sd	ra,24(sp)
    80002d66:	e822                	sd	s0,16(sp)
    80002d68:	e426                	sd	s1,8(sp)
    80002d6a:	e04a                	sd	s2,0(sp)
    80002d6c:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6e:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d72:	1007f793          	and	a5,a5,256
    80002d76:	e3b1                	bnez	a5,80002dba <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d78:	00003797          	auipc	a5,0x3
    80002d7c:	48878793          	add	a5,a5,1160 # 80006200 <kernelvec>
    80002d80:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	c7a080e7          	jalr	-902(ra) # 800019fe <myproc>
    80002d8c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d8e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d90:	14102773          	csrr	a4,sepc
    80002d94:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d96:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d9a:	47a1                	li	a5,8
    80002d9c:	02f70763          	beq	a4,a5,80002dca <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	f1c080e7          	jalr	-228(ra) # 80002cbc <devintr>
    80002da8:	892a                	mv	s2,a0
    80002daa:	c92d                	beqz	a0,80002e1c <usertrap+0xba>
  if (killed(p))
    80002dac:	8526                	mv	a0,s1
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	826080e7          	jalr	-2010(ra) # 800025d4 <killed>
    80002db6:	c555                	beqz	a0,80002e62 <usertrap+0x100>
    80002db8:	a045                	j	80002e58 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002dba:	00005517          	auipc	a0,0x5
    80002dbe:	58e50513          	add	a0,a0,1422 # 80008348 <states.0+0x58>
    80002dc2:	ffffd097          	auipc	ra,0xffffd
    80002dc6:	77a080e7          	jalr	1914(ra) # 8000053c <panic>
    if (killed(p))
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	80a080e7          	jalr	-2038(ra) # 800025d4 <killed>
    80002dd2:	ed1d                	bnez	a0,80002e10 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002dd4:	6cb8                	ld	a4,88(s1)
    80002dd6:	6f1c                	ld	a5,24(a4)
    80002dd8:	0791                	add	a5,a5,4
    80002dda:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ddc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002de0:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002de4:	10079073          	csrw	sstatus,a5
    syscall();
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	33c080e7          	jalr	828(ra) # 80003124 <syscall>
  if (killed(p))
    80002df0:	8526                	mv	a0,s1
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	7e2080e7          	jalr	2018(ra) # 800025d4 <killed>
    80002dfa:	ed31                	bnez	a0,80002e56 <usertrap+0xf4>
  usertrapret();
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	dd6080e7          	jalr	-554(ra) # 80002bd2 <usertrapret>
}
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6902                	ld	s2,0(sp)
    80002e0c:	6105                	add	sp,sp,32
    80002e0e:	8082                	ret
      exit(-1);
    80002e10:	557d                	li	a0,-1
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	642080e7          	jalr	1602(ra) # 80002454 <exit>
    80002e1a:	bf6d                	j	80002dd4 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e20:	5890                	lw	a2,48(s1)
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	54650513          	add	a0,a0,1350 # 80008368 <states.0+0x78>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	75c080e7          	jalr	1884(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e36:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e3a:	00005517          	auipc	a0,0x5
    80002e3e:	55e50513          	add	a0,a0,1374 # 80008398 <states.0+0xa8>
    80002e42:	ffffd097          	auipc	ra,0xffffd
    80002e46:	744080e7          	jalr	1860(ra) # 80000586 <printf>
    setkilled(p);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	75c080e7          	jalr	1884(ra) # 800025a8 <setkilled>
    80002e54:	bf71                	j	80002df0 <usertrap+0x8e>
  if (killed(p))
    80002e56:	4901                	li	s2,0
    exit(-1);
    80002e58:	557d                	li	a0,-1
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	5fa080e7          	jalr	1530(ra) # 80002454 <exit>
  if (which_dev == 2)
    80002e62:	4789                	li	a5,2
    80002e64:	f8f91ce3          	bne	s2,a5,80002dfc <usertrap+0x9a>
      p->now_ticks += 1;
    80002e68:	17c4a783          	lw	a5,380(s1)
    80002e6c:	2785                	addw	a5,a5,1
    80002e6e:	0007871b          	sext.w	a4,a5
    80002e72:	16f4ae23          	sw	a5,380(s1)
      if (p->ticks > 0 && !p->is_sigalarm)
    80002e76:	1784a783          	lw	a5,376(s1)
    80002e7a:	04f05663          	blez	a5,80002ec6 <usertrap+0x164>
    80002e7e:	1744a683          	lw	a3,372(s1)
    80002e82:	e2b1                	bnez	a3,80002ec6 <usertrap+0x164>
        if (p->now_ticks >= p->ticks)
    80002e84:	04f74163          	blt	a4,a5,80002ec6 <usertrap+0x164>
          p->now_ticks = 0;
    80002e88:	1604ae23          	sw	zero,380(s1)
          p->is_sigalarm = 1;
    80002e8c:	4785                	li	a5,1
    80002e8e:	16f4aa23          	sw	a5,372(s1)
          *(p->trapframe_copy) = *(p->trapframe);
    80002e92:	6cb4                	ld	a3,88(s1)
    80002e94:	87b6                	mv	a5,a3
    80002e96:	1884b703          	ld	a4,392(s1)
    80002e9a:	12068693          	add	a3,a3,288
    80002e9e:	0007b803          	ld	a6,0(a5)
    80002ea2:	6788                	ld	a0,8(a5)
    80002ea4:	6b8c                	ld	a1,16(a5)
    80002ea6:	6f90                	ld	a2,24(a5)
    80002ea8:	01073023          	sd	a6,0(a4)
    80002eac:	e708                	sd	a0,8(a4)
    80002eae:	eb0c                	sd	a1,16(a4)
    80002eb0:	ef10                	sd	a2,24(a4)
    80002eb2:	02078793          	add	a5,a5,32
    80002eb6:	02070713          	add	a4,a4,32
    80002eba:	fed792e3          	bne	a5,a3,80002e9e <usertrap+0x13c>
          p->trapframe->epc = p->handler;
    80002ebe:	6cbc                	ld	a5,88(s1)
    80002ec0:	1804b703          	ld	a4,384(s1)
    80002ec4:	ef98                	sd	a4,24(a5)
    if (myproc() != 0 && myproc()->state == RUNNING)
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	b38080e7          	jalr	-1224(ra) # 800019fe <myproc>
    80002ece:	d51d                	beqz	a0,80002dfc <usertrap+0x9a>
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	b2e080e7          	jalr	-1234(ra) # 800019fe <myproc>
    80002ed8:	b715                	j	80002dfc <usertrap+0x9a>

0000000080002eda <kerneltrap>:
{
    80002eda:	7179                	add	sp,sp,-48
    80002edc:	f406                	sd	ra,40(sp)
    80002ede:	f022                	sd	s0,32(sp)
    80002ee0:	ec26                	sd	s1,24(sp)
    80002ee2:	e84a                	sd	s2,16(sp)
    80002ee4:	e44e                	sd	s3,8(sp)
    80002ee6:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eec:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ef4:	1004f793          	and	a5,s1,256
    80002ef8:	cb85                	beqz	a5,80002f28 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002efa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002efe:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002f00:	ef85                	bnez	a5,80002f38 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	dba080e7          	jalr	-582(ra) # 80002cbc <devintr>
    80002f0a:	cd1d                	beqz	a0,80002f48 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f0c:	4789                	li	a5,2
    80002f0e:	06f50a63          	beq	a0,a5,80002f82 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f12:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f16:	10049073          	csrw	sstatus,s1
}
    80002f1a:	70a2                	ld	ra,40(sp)
    80002f1c:	7402                	ld	s0,32(sp)
    80002f1e:	64e2                	ld	s1,24(sp)
    80002f20:	6942                	ld	s2,16(sp)
    80002f22:	69a2                	ld	s3,8(sp)
    80002f24:	6145                	add	sp,sp,48
    80002f26:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	49050513          	add	a0,a0,1168 # 800083b8 <states.0+0xc8>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	60c080e7          	jalr	1548(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	4a850513          	add	a0,a0,1192 # 800083e0 <states.0+0xf0>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5fc080e7          	jalr	1532(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002f48:	85ce                	mv	a1,s3
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	4b650513          	add	a0,a0,1206 # 80008400 <states.0+0x110>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	634080e7          	jalr	1588(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f5a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f5e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f62:	00005517          	auipc	a0,0x5
    80002f66:	4ae50513          	add	a0,a0,1198 # 80008410 <states.0+0x120>
    80002f6a:	ffffd097          	auipc	ra,0xffffd
    80002f6e:	61c080e7          	jalr	1564(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	4b650513          	add	a0,a0,1206 # 80008428 <states.0+0x138>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	5c2080e7          	jalr	1474(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	a7c080e7          	jalr	-1412(ra) # 800019fe <myproc>
    80002f8a:	d541                	beqz	a0,80002f12 <kerneltrap+0x38>
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	a72080e7          	jalr	-1422(ra) # 800019fe <myproc>
    80002f94:	4d18                	lw	a4,24(a0)
    80002f96:	4791                	li	a5,4
    80002f98:	f6f71de3          	bne	a4,a5,80002f12 <kerneltrap+0x38>
    yield();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	316080e7          	jalr	790(ra) # 800022b2 <yield>
    80002fa4:	b7bd                	j	80002f12 <kerneltrap+0x38>

0000000080002fa6 <argraw>:
}


static uint64
argraw(int n)
{
    80002fa6:	1101                	add	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	1000                	add	s0,sp,32
    80002fb0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	a4c080e7          	jalr	-1460(ra) # 800019fe <myproc>
  switch (n) {
    80002fba:	4795                	li	a5,5
    80002fbc:	0497e163          	bltu	a5,s1,80002ffe <argraw+0x58>
    80002fc0:	048a                	sll	s1,s1,0x2
    80002fc2:	00005717          	auipc	a4,0x5
    80002fc6:	49e70713          	add	a4,a4,1182 # 80008460 <states.0+0x170>
    80002fca:	94ba                	add	s1,s1,a4
    80002fcc:	409c                	lw	a5,0(s1)
    80002fce:	97ba                	add	a5,a5,a4
    80002fd0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fd2:	6d3c                	ld	a5,88(a0)
    80002fd4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fd6:	60e2                	ld	ra,24(sp)
    80002fd8:	6442                	ld	s0,16(sp)
    80002fda:	64a2                	ld	s1,8(sp)
    80002fdc:	6105                	add	sp,sp,32
    80002fde:	8082                	ret
    return p->trapframe->a1;
    80002fe0:	6d3c                	ld	a5,88(a0)
    80002fe2:	7fa8                	ld	a0,120(a5)
    80002fe4:	bfcd                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a2;
    80002fe6:	6d3c                	ld	a5,88(a0)
    80002fe8:	63c8                	ld	a0,128(a5)
    80002fea:	b7f5                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a3;
    80002fec:	6d3c                	ld	a5,88(a0)
    80002fee:	67c8                	ld	a0,136(a5)
    80002ff0:	b7dd                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a4;
    80002ff2:	6d3c                	ld	a5,88(a0)
    80002ff4:	6bc8                	ld	a0,144(a5)
    80002ff6:	b7c5                	j	80002fd6 <argraw+0x30>
    return p->trapframe->a5;
    80002ff8:	6d3c                	ld	a5,88(a0)
    80002ffa:	6fc8                	ld	a0,152(a5)
    80002ffc:	bfe9                	j	80002fd6 <argraw+0x30>
  panic("argraw");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	43a50513          	add	a0,a0,1082 # 80008438 <states.0+0x148>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	536080e7          	jalr	1334(ra) # 8000053c <panic>

000000008000300e <fetchaddr>:
{
    8000300e:	1101                	add	sp,sp,-32
    80003010:	ec06                	sd	ra,24(sp)
    80003012:	e822                	sd	s0,16(sp)
    80003014:	e426                	sd	s1,8(sp)
    80003016:	e04a                	sd	s2,0(sp)
    80003018:	1000                	add	s0,sp,32
    8000301a:	84aa                	mv	s1,a0
    8000301c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	9e0080e7          	jalr	-1568(ra) # 800019fe <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003026:	653c                	ld	a5,72(a0)
    80003028:	02f4f863          	bgeu	s1,a5,80003058 <fetchaddr+0x4a>
    8000302c:	00848713          	add	a4,s1,8
    80003030:	02e7e663          	bltu	a5,a4,8000305c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003034:	46a1                	li	a3,8
    80003036:	8626                	mv	a2,s1
    80003038:	85ca                	mv	a1,s2
    8000303a:	6928                	ld	a0,80(a0)
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	6b6080e7          	jalr	1718(ra) # 800016f2 <copyin>
    80003044:	00a03533          	snez	a0,a0
    80003048:	40a00533          	neg	a0,a0
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6902                	ld	s2,0(sp)
    80003054:	6105                	add	sp,sp,32
    80003056:	8082                	ret
    return -1;
    80003058:	557d                	li	a0,-1
    8000305a:	bfcd                	j	8000304c <fetchaddr+0x3e>
    8000305c:	557d                	li	a0,-1
    8000305e:	b7fd                	j	8000304c <fetchaddr+0x3e>

0000000080003060 <fetchstr>:
{
    80003060:	7179                	add	sp,sp,-48
    80003062:	f406                	sd	ra,40(sp)
    80003064:	f022                	sd	s0,32(sp)
    80003066:	ec26                	sd	s1,24(sp)
    80003068:	e84a                	sd	s2,16(sp)
    8000306a:	e44e                	sd	s3,8(sp)
    8000306c:	1800                	add	s0,sp,48
    8000306e:	892a                	mv	s2,a0
    80003070:	84ae                	mv	s1,a1
    80003072:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	98a080e7          	jalr	-1654(ra) # 800019fe <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000307c:	86ce                	mv	a3,s3
    8000307e:	864a                	mv	a2,s2
    80003080:	85a6                	mv	a1,s1
    80003082:	6928                	ld	a0,80(a0)
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	6fc080e7          	jalr	1788(ra) # 80001780 <copyinstr>
    8000308c:	00054e63          	bltz	a0,800030a8 <fetchstr+0x48>
  return strlen(buf);
    80003090:	8526                	mv	a0,s1
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	db6080e7          	jalr	-586(ra) # 80000e48 <strlen>
}
    8000309a:	70a2                	ld	ra,40(sp)
    8000309c:	7402                	ld	s0,32(sp)
    8000309e:	64e2                	ld	s1,24(sp)
    800030a0:	6942                	ld	s2,16(sp)
    800030a2:	69a2                	ld	s3,8(sp)
    800030a4:	6145                	add	sp,sp,48
    800030a6:	8082                	ret
    return -1;
    800030a8:	557d                	li	a0,-1
    800030aa:	bfc5                	j	8000309a <fetchstr+0x3a>

00000000800030ac <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800030ac:	1101                	add	sp,sp,-32
    800030ae:	ec06                	sd	ra,24(sp)
    800030b0:	e822                	sd	s0,16(sp)
    800030b2:	e426                	sd	s1,8(sp)
    800030b4:	1000                	add	s0,sp,32
    800030b6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030b8:	00000097          	auipc	ra,0x0
    800030bc:	eee080e7          	jalr	-274(ra) # 80002fa6 <argraw>
    800030c0:	c088                	sw	a0,0(s1)
}
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6105                	add	sp,sp,32
    800030ca:	8082                	ret

00000000800030cc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800030cc:	1101                	add	sp,sp,-32
    800030ce:	ec06                	sd	ra,24(sp)
    800030d0:	e822                	sd	s0,16(sp)
    800030d2:	e426                	sd	s1,8(sp)
    800030d4:	1000                	add	s0,sp,32
    800030d6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	ece080e7          	jalr	-306(ra) # 80002fa6 <argraw>
    800030e0:	e088                	sd	a0,0(s1)
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6105                	add	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030ec:	7179                	add	sp,sp,-48
    800030ee:	f406                	sd	ra,40(sp)
    800030f0:	f022                	sd	s0,32(sp)
    800030f2:	ec26                	sd	s1,24(sp)
    800030f4:	e84a                	sd	s2,16(sp)
    800030f6:	1800                	add	s0,sp,48
    800030f8:	84ae                	mv	s1,a1
    800030fa:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030fc:	fd840593          	add	a1,s0,-40
    80003100:	00000097          	auipc	ra,0x0
    80003104:	fcc080e7          	jalr	-52(ra) # 800030cc <argaddr>
  return fetchstr(addr, buf, max);
    80003108:	864a                	mv	a2,s2
    8000310a:	85a6                	mv	a1,s1
    8000310c:	fd843503          	ld	a0,-40(s0)
    80003110:	00000097          	auipc	ra,0x0
    80003114:	f50080e7          	jalr	-176(ra) # 80003060 <fetchstr>
}
    80003118:	70a2                	ld	ra,40(sp)
    8000311a:	7402                	ld	s0,32(sp)
    8000311c:	64e2                	ld	s1,24(sp)
    8000311e:	6942                	ld	s2,16(sp)
    80003120:	6145                	add	sp,sp,48
    80003122:	8082                	ret

0000000080003124 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80003124:	1101                	add	sp,sp,-32
    80003126:	ec06                	sd	ra,24(sp)
    80003128:	e822                	sd	s0,16(sp)
    8000312a:	e426                	sd	s1,8(sp)
    8000312c:	e04a                	sd	s2,0(sp)
    8000312e:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	8ce080e7          	jalr	-1842(ra) # 800019fe <myproc>
    80003138:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000313a:	05853903          	ld	s2,88(a0)
    8000313e:	0a893783          	ld	a5,168(s2)
    80003142:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003146:	37fd                	addw	a5,a5,-1
    80003148:	4761                	li	a4,24
    8000314a:	00f76f63          	bltu	a4,a5,80003168 <syscall+0x44>
    8000314e:	00369713          	sll	a4,a3,0x3
    80003152:	00005797          	auipc	a5,0x5
    80003156:	32678793          	add	a5,a5,806 # 80008478 <syscalls>
    8000315a:	97ba                	add	a5,a5,a4
    8000315c:	639c                	ld	a5,0(a5)
    8000315e:	c789                	beqz	a5,80003168 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003160:	9782                	jalr	a5
    80003162:	06a93823          	sd	a0,112(s2)
    80003166:	a839                	j	80003184 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003168:	15848613          	add	a2,s1,344
    8000316c:	588c                	lw	a1,48(s1)
    8000316e:	00005517          	auipc	a0,0x5
    80003172:	2d250513          	add	a0,a0,722 # 80008440 <states.0+0x150>
    80003176:	ffffd097          	auipc	ra,0xffffd
    8000317a:	410080e7          	jalr	1040(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000317e:	6cbc                	ld	a5,88(s1)
    80003180:	577d                	li	a4,-1
    80003182:	fbb8                	sd	a4,112(a5)
  }
}
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	64a2                	ld	s1,8(sp)
    8000318a:	6902                	ld	s2,0(sp)
    8000318c:	6105                	add	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <sys_exit>:

extern int read_counter;

uint64
sys_exit(void)
{
    80003190:	1101                	add	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003198:	fec40593          	add	a1,s0,-20
    8000319c:	4501                	li	a0,0
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	f0e080e7          	jalr	-242(ra) # 800030ac <argint>
  exit(n);
    800031a6:	fec42503          	lw	a0,-20(s0)
    800031aa:	fffff097          	auipc	ra,0xfffff
    800031ae:	2aa080e7          	jalr	682(ra) # 80002454 <exit>
  return 0; // not reached
}
    800031b2:	4501                	li	a0,0
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	6105                	add	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <sys_getpid>:

uint64
sys_getpid(void)
{
    800031bc:	1141                	add	sp,sp,-16
    800031be:	e406                	sd	ra,8(sp)
    800031c0:	e022                	sd	s0,0(sp)
    800031c2:	0800                	add	s0,sp,16
  return myproc()->pid;
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	83a080e7          	jalr	-1990(ra) # 800019fe <myproc>
}
    800031cc:	5908                	lw	a0,48(a0)
    800031ce:	60a2                	ld	ra,8(sp)
    800031d0:	6402                	ld	s0,0(sp)
    800031d2:	0141                	add	sp,sp,16
    800031d4:	8082                	ret

00000000800031d6 <sys_fork>:

uint64
sys_fork(void)
{
    800031d6:	1141                	add	sp,sp,-16
    800031d8:	e406                	sd	ra,8(sp)
    800031da:	e022                	sd	s0,0(sp)
    800031dc:	0800                	add	s0,sp,16
  return fork();
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	c46080e7          	jalr	-954(ra) # 80001e24 <fork>
}
    800031e6:	60a2                	ld	ra,8(sp)
    800031e8:	6402                	ld	s0,0(sp)
    800031ea:	0141                	add	sp,sp,16
    800031ec:	8082                	ret

00000000800031ee <sys_wait>:

uint64
sys_wait(void)
{
    800031ee:	1101                	add	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800031f6:	fe840593          	add	a1,s0,-24
    800031fa:	4501                	li	a0,0
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	ed0080e7          	jalr	-304(ra) # 800030cc <argaddr>
  return wait(p);
    80003204:	fe843503          	ld	a0,-24(s0)
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	3fe080e7          	jalr	1022(ra) # 80002606 <wait>
}
    80003210:	60e2                	ld	ra,24(sp)
    80003212:	6442                	ld	s0,16(sp)
    80003214:	6105                	add	sp,sp,32
    80003216:	8082                	ret

0000000080003218 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003218:	7179                	add	sp,sp,-48
    8000321a:	f406                	sd	ra,40(sp)
    8000321c:	f022                	sd	s0,32(sp)
    8000321e:	ec26                	sd	s1,24(sp)
    80003220:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003222:	fdc40593          	add	a1,s0,-36
    80003226:	4501                	li	a0,0
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	e84080e7          	jalr	-380(ra) # 800030ac <argint>
  addr = myproc()->sz;
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	7ce080e7          	jalr	1998(ra) # 800019fe <myproc>
    80003238:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000323a:	fdc42503          	lw	a0,-36(s0)
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	b8a080e7          	jalr	-1142(ra) # 80001dc8 <growproc>
    80003246:	00054863          	bltz	a0,80003256 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000324a:	8526                	mv	a0,s1
    8000324c:	70a2                	ld	ra,40(sp)
    8000324e:	7402                	ld	s0,32(sp)
    80003250:	64e2                	ld	s1,24(sp)
    80003252:	6145                	add	sp,sp,48
    80003254:	8082                	ret
    return -1;
    80003256:	54fd                	li	s1,-1
    80003258:	bfcd                	j	8000324a <sys_sbrk+0x32>

000000008000325a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000325a:	7139                	add	sp,sp,-64
    8000325c:	fc06                	sd	ra,56(sp)
    8000325e:	f822                	sd	s0,48(sp)
    80003260:	f426                	sd	s1,40(sp)
    80003262:	f04a                	sd	s2,32(sp)
    80003264:	ec4e                	sd	s3,24(sp)
    80003266:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003268:	fcc40593          	add	a1,s0,-52
    8000326c:	4501                	li	a0,0
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	e3e080e7          	jalr	-450(ra) # 800030ac <argint>
  acquire(&tickslock);
    80003276:	00015517          	auipc	a0,0x15
    8000327a:	f7a50513          	add	a0,a0,-134 # 800181f0 <tickslock>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	954080e7          	jalr	-1708(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003286:	00005917          	auipc	s2,0x5
    8000328a:	68a92903          	lw	s2,1674(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    8000328e:	fcc42783          	lw	a5,-52(s0)
    80003292:	cf9d                	beqz	a5,800032d0 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003294:	00015997          	auipc	s3,0x15
    80003298:	f5c98993          	add	s3,s3,-164 # 800181f0 <tickslock>
    8000329c:	00005497          	auipc	s1,0x5
    800032a0:	67448493          	add	s1,s1,1652 # 80008910 <ticks>
    if (killed(myproc()))
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	75a080e7          	jalr	1882(ra) # 800019fe <myproc>
    800032ac:	fffff097          	auipc	ra,0xfffff
    800032b0:	328080e7          	jalr	808(ra) # 800025d4 <killed>
    800032b4:	ed15                	bnez	a0,800032f0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800032b6:	85ce                	mv	a1,s3
    800032b8:	8526                	mv	a0,s1
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	034080e7          	jalr	52(ra) # 800022ee <sleep>
  while (ticks - ticks0 < n)
    800032c2:	409c                	lw	a5,0(s1)
    800032c4:	412787bb          	subw	a5,a5,s2
    800032c8:	fcc42703          	lw	a4,-52(s0)
    800032cc:	fce7ece3          	bltu	a5,a4,800032a4 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800032d0:	00015517          	auipc	a0,0x15
    800032d4:	f2050513          	add	a0,a0,-224 # 800181f0 <tickslock>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	9ae080e7          	jalr	-1618(ra) # 80000c86 <release>
  return 0;
    800032e0:	4501                	li	a0,0
}
    800032e2:	70e2                	ld	ra,56(sp)
    800032e4:	7442                	ld	s0,48(sp)
    800032e6:	74a2                	ld	s1,40(sp)
    800032e8:	7902                	ld	s2,32(sp)
    800032ea:	69e2                	ld	s3,24(sp)
    800032ec:	6121                	add	sp,sp,64
    800032ee:	8082                	ret
      release(&tickslock);
    800032f0:	00015517          	auipc	a0,0x15
    800032f4:	f0050513          	add	a0,a0,-256 # 800181f0 <tickslock>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	98e080e7          	jalr	-1650(ra) # 80000c86 <release>
      return -1;
    80003300:	557d                	li	a0,-1
    80003302:	b7c5                	j	800032e2 <sys_sleep+0x88>

0000000080003304 <sys_kill>:

uint64
sys_kill(void)
{
    80003304:	1101                	add	sp,sp,-32
    80003306:	ec06                	sd	ra,24(sp)
    80003308:	e822                	sd	s0,16(sp)
    8000330a:	1000                	add	s0,sp,32
  int pid;
  argint(0, &pid);
    8000330c:	fec40593          	add	a1,s0,-20
    80003310:	4501                	li	a0,0
    80003312:	00000097          	auipc	ra,0x0
    80003316:	d9a080e7          	jalr	-614(ra) # 800030ac <argint>
  return kill(pid);
    8000331a:	fec42503          	lw	a0,-20(s0)
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	218080e7          	jalr	536(ra) # 80002536 <kill>
}
    80003326:	60e2                	ld	ra,24(sp)
    80003328:	6442                	ld	s0,16(sp)
    8000332a:	6105                	add	sp,sp,32
    8000332c:	8082                	ret

000000008000332e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000332e:	1101                	add	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003338:	00015517          	auipc	a0,0x15
    8000333c:	eb850513          	add	a0,a0,-328 # 800181f0 <tickslock>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	892080e7          	jalr	-1902(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003348:	00005497          	auipc	s1,0x5
    8000334c:	5c84a483          	lw	s1,1480(s1) # 80008910 <ticks>
  release(&tickslock);
    80003350:	00015517          	auipc	a0,0x15
    80003354:	ea050513          	add	a0,a0,-352 # 800181f0 <tickslock>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	92e080e7          	jalr	-1746(ra) # 80000c86 <release>
  return xticks;
}
    80003360:	02049513          	sll	a0,s1,0x20
    80003364:	9101                	srl	a0,a0,0x20
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6105                	add	sp,sp,32
    8000336e:	8082                	ret

0000000080003370 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003370:	7139                	add	sp,sp,-64
    80003372:	fc06                	sd	ra,56(sp)
    80003374:	f822                	sd	s0,48(sp)
    80003376:	f426                	sd	s1,40(sp)
    80003378:	f04a                	sd	s2,32(sp)
    8000337a:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000337c:	fd840593          	add	a1,s0,-40
    80003380:	4501                	li	a0,0
    80003382:	00000097          	auipc	ra,0x0
    80003386:	d4a080e7          	jalr	-694(ra) # 800030cc <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000338a:	fd040593          	add	a1,s0,-48
    8000338e:	4505                	li	a0,1
    80003390:	00000097          	auipc	ra,0x0
    80003394:	d3c080e7          	jalr	-708(ra) # 800030cc <argaddr>
  argaddr(2, &addr2);
    80003398:	fc840593          	add	a1,s0,-56
    8000339c:	4509                	li	a0,2
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	d2e080e7          	jalr	-722(ra) # 800030cc <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800033a6:	fc040613          	add	a2,s0,-64
    800033aa:	fc440593          	add	a1,s0,-60
    800033ae:	fd843503          	ld	a0,-40(s0)
    800033b2:	fffff097          	auipc	ra,0xfffff
    800033b6:	56c080e7          	jalr	1388(ra) # 8000291e <waitx>
    800033ba:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	642080e7          	jalr	1602(ra) # 800019fe <myproc>
    800033c4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033c6:	4691                	li	a3,4
    800033c8:	fc440613          	add	a2,s0,-60
    800033cc:	fd043583          	ld	a1,-48(s0)
    800033d0:	6928                	ld	a0,80(a0)
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	294080e7          	jalr	660(ra) # 80001666 <copyout>
    return -1;
    800033da:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033dc:	00054f63          	bltz	a0,800033fa <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800033e0:	4691                	li	a3,4
    800033e2:	fc040613          	add	a2,s0,-64
    800033e6:	fc843583          	ld	a1,-56(s0)
    800033ea:	68a8                	ld	a0,80(s1)
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	27a080e7          	jalr	634(ra) # 80001666 <copyout>
    800033f4:	00054a63          	bltz	a0,80003408 <sys_waitx+0x98>
    return -1;
  return ret;
    800033f8:	87ca                	mv	a5,s2
}
    800033fa:	853e                	mv	a0,a5
    800033fc:	70e2                	ld	ra,56(sp)
    800033fe:	7442                	ld	s0,48(sp)
    80003400:	74a2                	ld	s1,40(sp)
    80003402:	7902                	ld	s2,32(sp)
    80003404:	6121                	add	sp,sp,64
    80003406:	8082                	ret
    return -1;
    80003408:	57fd                	li	a5,-1
    8000340a:	bfc5                	j	800033fa <sys_waitx+0x8a>

000000008000340c <sys_getreadcount>:

uint64 sys_getreadcount(void)
{
    8000340c:	1141                	add	sp,sp,-16
    8000340e:	e422                	sd	s0,8(sp)
    80003410:	0800                	add	s0,sp,16
  return read_counter;
}
    80003412:	00005517          	auipc	a0,0x5
    80003416:	4ea52503          	lw	a0,1258(a0) # 800088fc <read_counter>
    8000341a:	6422                	ld	s0,8(sp)
    8000341c:	0141                	add	sp,sp,16
    8000341e:	8082                	ret

0000000080003420 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80003420:	1101                	add	sp,sp,-32
    80003422:	ec06                	sd	ra,24(sp)
    80003424:	e822                	sd	s0,16(sp)
    80003426:	1000                	add	s0,sp,32
  int ticks;
  int handler;
  argint(0, &ticks);
    80003428:	fec40593          	add	a1,s0,-20
    8000342c:	4501                	li	a0,0
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	c7e080e7          	jalr	-898(ra) # 800030ac <argint>
  argint(1, &handler);
    80003436:	fe840593          	add	a1,s0,-24
    8000343a:	4505                	li	a0,1
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	c70080e7          	jalr	-912(ra) # 800030ac <argint>
  struct proc *p = myproc();
    80003444:	ffffe097          	auipc	ra,0xffffe
    80003448:	5ba080e7          	jalr	1466(ra) # 800019fe <myproc>
  p->handler = handler;
    8000344c:	fe842783          	lw	a5,-24(s0)
    80003450:	18f53023          	sd	a5,384(a0)
  p->ticks = ticks;
    80003454:	fec42783          	lw	a5,-20(s0)
    80003458:	16f52c23          	sw	a5,376(a0)
  p->is_sigalarm = 0;
    8000345c:	16052a23          	sw	zero,372(a0)
  p->now_ticks = 0;
    80003460:	16052e23          	sw	zero,380(a0)
  return 0;
}
    80003464:	4501                	li	a0,0
    80003466:	60e2                	ld	ra,24(sp)
    80003468:	6442                	ld	s0,16(sp)
    8000346a:	6105                	add	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    8000346e:	1141                	add	sp,sp,-16
    80003470:	e406                	sd	ra,8(sp)
    80003472:	e022                	sd	s0,0(sp)
    80003474:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80003476:	ffffe097          	auipc	ra,0xffffe
    8000347a:	588080e7          	jalr	1416(ra) # 800019fe <myproc>
  p->is_sigalarm = 0;
    8000347e:	16052a23          	sw	zero,372(a0)
  *(p->trapframe) = *(p->trapframe_copy);
    80003482:	18853683          	ld	a3,392(a0)
    80003486:	87b6                	mv	a5,a3
    80003488:	6d38                	ld	a4,88(a0)
    8000348a:	12068693          	add	a3,a3,288
    8000348e:	0007b803          	ld	a6,0(a5)
    80003492:	6788                	ld	a0,8(a5)
    80003494:	6b8c                	ld	a1,16(a5)
    80003496:	6f90                	ld	a2,24(a5)
    80003498:	01073023          	sd	a6,0(a4)
    8000349c:	e708                	sd	a0,8(a4)
    8000349e:	eb0c                	sd	a1,16(a4)
    800034a0:	ef10                	sd	a2,24(a4)
    800034a2:	02078793          	add	a5,a5,32
    800034a6:	02070713          	add	a4,a4,32
    800034aa:	fed792e3          	bne	a5,a3,8000348e <sys_sigreturn+0x20>
  //kfree(p->trapframe_copy);
  usertrapret();
    800034ae:	fffff097          	auipc	ra,0xfffff
    800034b2:	724080e7          	jalr	1828(ra) # 80002bd2 <usertrapret>
  return 0;
}
    800034b6:	4501                	li	a0,0
    800034b8:	60a2                	ld	ra,8(sp)
    800034ba:	6402                	ld	s0,0(sp)
    800034bc:	0141                	add	sp,sp,16
    800034be:	8082                	ret

00000000800034c0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034c0:	7179                	add	sp,sp,-48
    800034c2:	f406                	sd	ra,40(sp)
    800034c4:	f022                	sd	s0,32(sp)
    800034c6:	ec26                	sd	s1,24(sp)
    800034c8:	e84a                	sd	s2,16(sp)
    800034ca:	e44e                	sd	s3,8(sp)
    800034cc:	e052                	sd	s4,0(sp)
    800034ce:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034d0:	00005597          	auipc	a1,0x5
    800034d4:	07858593          	add	a1,a1,120 # 80008548 <syscalls+0xd0>
    800034d8:	00015517          	auipc	a0,0x15
    800034dc:	d3050513          	add	a0,a0,-720 # 80018208 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	662080e7          	jalr	1634(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034e8:	0001d797          	auipc	a5,0x1d
    800034ec:	d2078793          	add	a5,a5,-736 # 80020208 <bcache+0x8000>
    800034f0:	0001d717          	auipc	a4,0x1d
    800034f4:	f8070713          	add	a4,a4,-128 # 80020470 <bcache+0x8268>
    800034f8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034fc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003500:	00015497          	auipc	s1,0x15
    80003504:	d2048493          	add	s1,s1,-736 # 80018220 <bcache+0x18>
    b->next = bcache.head.next;
    80003508:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000350a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000350c:	00005a17          	auipc	s4,0x5
    80003510:	044a0a13          	add	s4,s4,68 # 80008550 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003514:	2b893783          	ld	a5,696(s2)
    80003518:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000351a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000351e:	85d2                	mv	a1,s4
    80003520:	01048513          	add	a0,s1,16
    80003524:	00001097          	auipc	ra,0x1
    80003528:	496080e7          	jalr	1174(ra) # 800049ba <initsleeplock>
    bcache.head.next->prev = b;
    8000352c:	2b893783          	ld	a5,696(s2)
    80003530:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003532:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003536:	45848493          	add	s1,s1,1112
    8000353a:	fd349de3          	bne	s1,s3,80003514 <binit+0x54>
  }
}
    8000353e:	70a2                	ld	ra,40(sp)
    80003540:	7402                	ld	s0,32(sp)
    80003542:	64e2                	ld	s1,24(sp)
    80003544:	6942                	ld	s2,16(sp)
    80003546:	69a2                	ld	s3,8(sp)
    80003548:	6a02                	ld	s4,0(sp)
    8000354a:	6145                	add	sp,sp,48
    8000354c:	8082                	ret

000000008000354e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000354e:	7179                	add	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	e84a                	sd	s2,16(sp)
    80003558:	e44e                	sd	s3,8(sp)
    8000355a:	1800                	add	s0,sp,48
    8000355c:	892a                	mv	s2,a0
    8000355e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003560:	00015517          	auipc	a0,0x15
    80003564:	ca850513          	add	a0,a0,-856 # 80018208 <bcache>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	66a080e7          	jalr	1642(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003570:	0001d497          	auipc	s1,0x1d
    80003574:	f504b483          	ld	s1,-176(s1) # 800204c0 <bcache+0x82b8>
    80003578:	0001d797          	auipc	a5,0x1d
    8000357c:	ef878793          	add	a5,a5,-264 # 80020470 <bcache+0x8268>
    80003580:	02f48f63          	beq	s1,a5,800035be <bread+0x70>
    80003584:	873e                	mv	a4,a5
    80003586:	a021                	j	8000358e <bread+0x40>
    80003588:	68a4                	ld	s1,80(s1)
    8000358a:	02e48a63          	beq	s1,a4,800035be <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000358e:	449c                	lw	a5,8(s1)
    80003590:	ff279ce3          	bne	a5,s2,80003588 <bread+0x3a>
    80003594:	44dc                	lw	a5,12(s1)
    80003596:	ff3799e3          	bne	a5,s3,80003588 <bread+0x3a>
      b->refcnt++;
    8000359a:	40bc                	lw	a5,64(s1)
    8000359c:	2785                	addw	a5,a5,1
    8000359e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035a0:	00015517          	auipc	a0,0x15
    800035a4:	c6850513          	add	a0,a0,-920 # 80018208 <bcache>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	6de080e7          	jalr	1758(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800035b0:	01048513          	add	a0,s1,16
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	440080e7          	jalr	1088(ra) # 800049f4 <acquiresleep>
      return b;
    800035bc:	a8b9                	j	8000361a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035be:	0001d497          	auipc	s1,0x1d
    800035c2:	efa4b483          	ld	s1,-262(s1) # 800204b8 <bcache+0x82b0>
    800035c6:	0001d797          	auipc	a5,0x1d
    800035ca:	eaa78793          	add	a5,a5,-342 # 80020470 <bcache+0x8268>
    800035ce:	00f48863          	beq	s1,a5,800035de <bread+0x90>
    800035d2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035d4:	40bc                	lw	a5,64(s1)
    800035d6:	cf81                	beqz	a5,800035ee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035d8:	64a4                	ld	s1,72(s1)
    800035da:	fee49de3          	bne	s1,a4,800035d4 <bread+0x86>
  panic("bget: no buffers");
    800035de:	00005517          	auipc	a0,0x5
    800035e2:	f7a50513          	add	a0,a0,-134 # 80008558 <syscalls+0xe0>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f56080e7          	jalr	-170(ra) # 8000053c <panic>
      b->dev = dev;
    800035ee:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035f2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035f6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035fa:	4785                	li	a5,1
    800035fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035fe:	00015517          	auipc	a0,0x15
    80003602:	c0a50513          	add	a0,a0,-1014 # 80018208 <bcache>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	680080e7          	jalr	1664(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000360e:	01048513          	add	a0,s1,16
    80003612:	00001097          	auipc	ra,0x1
    80003616:	3e2080e7          	jalr	994(ra) # 800049f4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000361a:	409c                	lw	a5,0(s1)
    8000361c:	cb89                	beqz	a5,8000362e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000361e:	8526                	mv	a0,s1
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6942                	ld	s2,16(sp)
    80003628:	69a2                	ld	s3,8(sp)
    8000362a:	6145                	add	sp,sp,48
    8000362c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000362e:	4581                	li	a1,0
    80003630:	8526                	mv	a0,s1
    80003632:	00003097          	auipc	ra,0x3
    80003636:	f90080e7          	jalr	-112(ra) # 800065c2 <virtio_disk_rw>
    b->valid = 1;
    8000363a:	4785                	li	a5,1
    8000363c:	c09c                	sw	a5,0(s1)
  return b;
    8000363e:	b7c5                	j	8000361e <bread+0xd0>

0000000080003640 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003640:	1101                	add	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	1000                	add	s0,sp,32
    8000364a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000364c:	0541                	add	a0,a0,16
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	440080e7          	jalr	1088(ra) # 80004a8e <holdingsleep>
    80003656:	cd01                	beqz	a0,8000366e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003658:	4585                	li	a1,1
    8000365a:	8526                	mv	a0,s1
    8000365c:	00003097          	auipc	ra,0x3
    80003660:	f66080e7          	jalr	-154(ra) # 800065c2 <virtio_disk_rw>
}
    80003664:	60e2                	ld	ra,24(sp)
    80003666:	6442                	ld	s0,16(sp)
    80003668:	64a2                	ld	s1,8(sp)
    8000366a:	6105                	add	sp,sp,32
    8000366c:	8082                	ret
    panic("bwrite");
    8000366e:	00005517          	auipc	a0,0x5
    80003672:	f0250513          	add	a0,a0,-254 # 80008570 <syscalls+0xf8>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	ec6080e7          	jalr	-314(ra) # 8000053c <panic>

000000008000367e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000367e:	1101                	add	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	e04a                	sd	s2,0(sp)
    80003688:	1000                	add	s0,sp,32
    8000368a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000368c:	01050913          	add	s2,a0,16
    80003690:	854a                	mv	a0,s2
    80003692:	00001097          	auipc	ra,0x1
    80003696:	3fc080e7          	jalr	1020(ra) # 80004a8e <holdingsleep>
    8000369a:	c925                	beqz	a0,8000370a <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000369c:	854a                	mv	a0,s2
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	3ac080e7          	jalr	940(ra) # 80004a4a <releasesleep>

  acquire(&bcache.lock);
    800036a6:	00015517          	auipc	a0,0x15
    800036aa:	b6250513          	add	a0,a0,-1182 # 80018208 <bcache>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	524080e7          	jalr	1316(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800036b6:	40bc                	lw	a5,64(s1)
    800036b8:	37fd                	addw	a5,a5,-1
    800036ba:	0007871b          	sext.w	a4,a5
    800036be:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036c0:	e71d                	bnez	a4,800036ee <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036c2:	68b8                	ld	a4,80(s1)
    800036c4:	64bc                	ld	a5,72(s1)
    800036c6:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800036c8:	68b8                	ld	a4,80(s1)
    800036ca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036cc:	0001d797          	auipc	a5,0x1d
    800036d0:	b3c78793          	add	a5,a5,-1220 # 80020208 <bcache+0x8000>
    800036d4:	2b87b703          	ld	a4,696(a5)
    800036d8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036da:	0001d717          	auipc	a4,0x1d
    800036de:	d9670713          	add	a4,a4,-618 # 80020470 <bcache+0x8268>
    800036e2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036e4:	2b87b703          	ld	a4,696(a5)
    800036e8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036ee:	00015517          	auipc	a0,0x15
    800036f2:	b1a50513          	add	a0,a0,-1254 # 80018208 <bcache>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	590080e7          	jalr	1424(ra) # 80000c86 <release>
}
    800036fe:	60e2                	ld	ra,24(sp)
    80003700:	6442                	ld	s0,16(sp)
    80003702:	64a2                	ld	s1,8(sp)
    80003704:	6902                	ld	s2,0(sp)
    80003706:	6105                	add	sp,sp,32
    80003708:	8082                	ret
    panic("brelse");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	e6e50513          	add	a0,a0,-402 # 80008578 <syscalls+0x100>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e2a080e7          	jalr	-470(ra) # 8000053c <panic>

000000008000371a <bpin>:

void
bpin(struct buf *b) {
    8000371a:	1101                	add	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	1000                	add	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003726:	00015517          	auipc	a0,0x15
    8000372a:	ae250513          	add	a0,a0,-1310 # 80018208 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	4a4080e7          	jalr	1188(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003736:	40bc                	lw	a5,64(s1)
    80003738:	2785                	addw	a5,a5,1
    8000373a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000373c:	00015517          	auipc	a0,0x15
    80003740:	acc50513          	add	a0,a0,-1332 # 80018208 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	542080e7          	jalr	1346(ra) # 80000c86 <release>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6105                	add	sp,sp,32
    80003754:	8082                	ret

0000000080003756 <bunpin>:

void
bunpin(struct buf *b) {
    80003756:	1101                	add	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	1000                	add	s0,sp,32
    80003760:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003762:	00015517          	auipc	a0,0x15
    80003766:	aa650513          	add	a0,a0,-1370 # 80018208 <bcache>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	468080e7          	jalr	1128(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003772:	40bc                	lw	a5,64(s1)
    80003774:	37fd                	addw	a5,a5,-1
    80003776:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003778:	00015517          	auipc	a0,0x15
    8000377c:	a9050513          	add	a0,a0,-1392 # 80018208 <bcache>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	506080e7          	jalr	1286(ra) # 80000c86 <release>
}
    80003788:	60e2                	ld	ra,24(sp)
    8000378a:	6442                	ld	s0,16(sp)
    8000378c:	64a2                	ld	s1,8(sp)
    8000378e:	6105                	add	sp,sp,32
    80003790:	8082                	ret

0000000080003792 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003792:	1101                	add	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	e04a                	sd	s2,0(sp)
    8000379c:	1000                	add	s0,sp,32
    8000379e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037a0:	00d5d59b          	srlw	a1,a1,0xd
    800037a4:	0001d797          	auipc	a5,0x1d
    800037a8:	1407a783          	lw	a5,320(a5) # 800208e4 <sb+0x1c>
    800037ac:	9dbd                	addw	a1,a1,a5
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	da0080e7          	jalr	-608(ra) # 8000354e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037b6:	0074f713          	and	a4,s1,7
    800037ba:	4785                	li	a5,1
    800037bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037c0:	14ce                	sll	s1,s1,0x33
    800037c2:	90d9                	srl	s1,s1,0x36
    800037c4:	00950733          	add	a4,a0,s1
    800037c8:	05874703          	lbu	a4,88(a4)
    800037cc:	00e7f6b3          	and	a3,a5,a4
    800037d0:	c69d                	beqz	a3,800037fe <bfree+0x6c>
    800037d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037d4:	94aa                	add	s1,s1,a0
    800037d6:	fff7c793          	not	a5,a5
    800037da:	8f7d                	and	a4,a4,a5
    800037dc:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800037e0:	00001097          	auipc	ra,0x1
    800037e4:	0f6080e7          	jalr	246(ra) # 800048d6 <log_write>
  brelse(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	e94080e7          	jalr	-364(ra) # 8000367e <brelse>
}
    800037f2:	60e2                	ld	ra,24(sp)
    800037f4:	6442                	ld	s0,16(sp)
    800037f6:	64a2                	ld	s1,8(sp)
    800037f8:	6902                	ld	s2,0(sp)
    800037fa:	6105                	add	sp,sp,32
    800037fc:	8082                	ret
    panic("freeing free block");
    800037fe:	00005517          	auipc	a0,0x5
    80003802:	d8250513          	add	a0,a0,-638 # 80008580 <syscalls+0x108>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d36080e7          	jalr	-714(ra) # 8000053c <panic>

000000008000380e <balloc>:
{
    8000380e:	711d                	add	sp,sp,-96
    80003810:	ec86                	sd	ra,88(sp)
    80003812:	e8a2                	sd	s0,80(sp)
    80003814:	e4a6                	sd	s1,72(sp)
    80003816:	e0ca                	sd	s2,64(sp)
    80003818:	fc4e                	sd	s3,56(sp)
    8000381a:	f852                	sd	s4,48(sp)
    8000381c:	f456                	sd	s5,40(sp)
    8000381e:	f05a                	sd	s6,32(sp)
    80003820:	ec5e                	sd	s7,24(sp)
    80003822:	e862                	sd	s8,16(sp)
    80003824:	e466                	sd	s9,8(sp)
    80003826:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003828:	0001d797          	auipc	a5,0x1d
    8000382c:	0a47a783          	lw	a5,164(a5) # 800208cc <sb+0x4>
    80003830:	cff5                	beqz	a5,8000392c <balloc+0x11e>
    80003832:	8baa                	mv	s7,a0
    80003834:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003836:	0001db17          	auipc	s6,0x1d
    8000383a:	092b0b13          	add	s6,s6,146 # 800208c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000383e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003840:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003842:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003844:	6c89                	lui	s9,0x2
    80003846:	a061                	j	800038ce <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003848:	97ca                	add	a5,a5,s2
    8000384a:	8e55                	or	a2,a2,a3
    8000384c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	084080e7          	jalr	132(ra) # 800048d6 <log_write>
        brelse(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	e22080e7          	jalr	-478(ra) # 8000367e <brelse>
  bp = bread(dev, bno);
    80003864:	85a6                	mv	a1,s1
    80003866:	855e                	mv	a0,s7
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	ce6080e7          	jalr	-794(ra) # 8000354e <bread>
    80003870:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003872:	40000613          	li	a2,1024
    80003876:	4581                	li	a1,0
    80003878:	05850513          	add	a0,a0,88
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	452080e7          	jalr	1106(ra) # 80000cce <memset>
  log_write(bp);
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	050080e7          	jalr	80(ra) # 800048d6 <log_write>
  brelse(bp);
    8000388e:	854a                	mv	a0,s2
    80003890:	00000097          	auipc	ra,0x0
    80003894:	dee080e7          	jalr	-530(ra) # 8000367e <brelse>
}
    80003898:	8526                	mv	a0,s1
    8000389a:	60e6                	ld	ra,88(sp)
    8000389c:	6446                	ld	s0,80(sp)
    8000389e:	64a6                	ld	s1,72(sp)
    800038a0:	6906                	ld	s2,64(sp)
    800038a2:	79e2                	ld	s3,56(sp)
    800038a4:	7a42                	ld	s4,48(sp)
    800038a6:	7aa2                	ld	s5,40(sp)
    800038a8:	7b02                	ld	s6,32(sp)
    800038aa:	6be2                	ld	s7,24(sp)
    800038ac:	6c42                	ld	s8,16(sp)
    800038ae:	6ca2                	ld	s9,8(sp)
    800038b0:	6125                	add	sp,sp,96
    800038b2:	8082                	ret
    brelse(bp);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	dc8080e7          	jalr	-568(ra) # 8000367e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038be:	015c87bb          	addw	a5,s9,s5
    800038c2:	00078a9b          	sext.w	s5,a5
    800038c6:	004b2703          	lw	a4,4(s6)
    800038ca:	06eaf163          	bgeu	s5,a4,8000392c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800038ce:	41fad79b          	sraw	a5,s5,0x1f
    800038d2:	0137d79b          	srlw	a5,a5,0x13
    800038d6:	015787bb          	addw	a5,a5,s5
    800038da:	40d7d79b          	sraw	a5,a5,0xd
    800038de:	01cb2583          	lw	a1,28(s6)
    800038e2:	9dbd                	addw	a1,a1,a5
    800038e4:	855e                	mv	a0,s7
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	c68080e7          	jalr	-920(ra) # 8000354e <bread>
    800038ee:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038f0:	004b2503          	lw	a0,4(s6)
    800038f4:	000a849b          	sext.w	s1,s5
    800038f8:	8762                	mv	a4,s8
    800038fa:	faa4fde3          	bgeu	s1,a0,800038b4 <balloc+0xa6>
      m = 1 << (bi % 8);
    800038fe:	00777693          	and	a3,a4,7
    80003902:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003906:	41f7579b          	sraw	a5,a4,0x1f
    8000390a:	01d7d79b          	srlw	a5,a5,0x1d
    8000390e:	9fb9                	addw	a5,a5,a4
    80003910:	4037d79b          	sraw	a5,a5,0x3
    80003914:	00f90633          	add	a2,s2,a5
    80003918:	05864603          	lbu	a2,88(a2)
    8000391c:	00c6f5b3          	and	a1,a3,a2
    80003920:	d585                	beqz	a1,80003848 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003922:	2705                	addw	a4,a4,1
    80003924:	2485                	addw	s1,s1,1
    80003926:	fd471ae3          	bne	a4,s4,800038fa <balloc+0xec>
    8000392a:	b769                	j	800038b4 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000392c:	00005517          	auipc	a0,0x5
    80003930:	c6c50513          	add	a0,a0,-916 # 80008598 <syscalls+0x120>
    80003934:	ffffd097          	auipc	ra,0xffffd
    80003938:	c52080e7          	jalr	-942(ra) # 80000586 <printf>
  return 0;
    8000393c:	4481                	li	s1,0
    8000393e:	bfa9                	j	80003898 <balloc+0x8a>

0000000080003940 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003940:	7179                	add	sp,sp,-48
    80003942:	f406                	sd	ra,40(sp)
    80003944:	f022                	sd	s0,32(sp)
    80003946:	ec26                	sd	s1,24(sp)
    80003948:	e84a                	sd	s2,16(sp)
    8000394a:	e44e                	sd	s3,8(sp)
    8000394c:	e052                	sd	s4,0(sp)
    8000394e:	1800                	add	s0,sp,48
    80003950:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003952:	47ad                	li	a5,11
    80003954:	02b7e863          	bltu	a5,a1,80003984 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003958:	02059793          	sll	a5,a1,0x20
    8000395c:	01e7d593          	srl	a1,a5,0x1e
    80003960:	00b504b3          	add	s1,a0,a1
    80003964:	0504a903          	lw	s2,80(s1)
    80003968:	06091e63          	bnez	s2,800039e4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000396c:	4108                	lw	a0,0(a0)
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	ea0080e7          	jalr	-352(ra) # 8000380e <balloc>
    80003976:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000397a:	06090563          	beqz	s2,800039e4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000397e:	0524a823          	sw	s2,80(s1)
    80003982:	a08d                	j	800039e4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003984:	ff45849b          	addw	s1,a1,-12
    80003988:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000398c:	0ff00793          	li	a5,255
    80003990:	08e7e563          	bltu	a5,a4,80003a1a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003994:	08052903          	lw	s2,128(a0)
    80003998:	00091d63          	bnez	s2,800039b2 <bmap+0x72>
      addr = balloc(ip->dev);
    8000399c:	4108                	lw	a0,0(a0)
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	e70080e7          	jalr	-400(ra) # 8000380e <balloc>
    800039a6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039aa:	02090d63          	beqz	s2,800039e4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039ae:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800039b2:	85ca                	mv	a1,s2
    800039b4:	0009a503          	lw	a0,0(s3)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	b96080e7          	jalr	-1130(ra) # 8000354e <bread>
    800039c0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039c2:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800039c6:	02049713          	sll	a4,s1,0x20
    800039ca:	01e75593          	srl	a1,a4,0x1e
    800039ce:	00b784b3          	add	s1,a5,a1
    800039d2:	0004a903          	lw	s2,0(s1)
    800039d6:	02090063          	beqz	s2,800039f6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039da:	8552                	mv	a0,s4
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	ca2080e7          	jalr	-862(ra) # 8000367e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039e4:	854a                	mv	a0,s2
    800039e6:	70a2                	ld	ra,40(sp)
    800039e8:	7402                	ld	s0,32(sp)
    800039ea:	64e2                	ld	s1,24(sp)
    800039ec:	6942                	ld	s2,16(sp)
    800039ee:	69a2                	ld	s3,8(sp)
    800039f0:	6a02                	ld	s4,0(sp)
    800039f2:	6145                	add	sp,sp,48
    800039f4:	8082                	ret
      addr = balloc(ip->dev);
    800039f6:	0009a503          	lw	a0,0(s3)
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	e14080e7          	jalr	-492(ra) # 8000380e <balloc>
    80003a02:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a06:	fc090ae3          	beqz	s2,800039da <bmap+0x9a>
        a[bn] = addr;
    80003a0a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a0e:	8552                	mv	a0,s4
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	ec6080e7          	jalr	-314(ra) # 800048d6 <log_write>
    80003a18:	b7c9                	j	800039da <bmap+0x9a>
  panic("bmap: out of range");
    80003a1a:	00005517          	auipc	a0,0x5
    80003a1e:	b9650513          	add	a0,a0,-1130 # 800085b0 <syscalls+0x138>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	b1a080e7          	jalr	-1254(ra) # 8000053c <panic>

0000000080003a2a <iget>:
{
    80003a2a:	7179                	add	sp,sp,-48
    80003a2c:	f406                	sd	ra,40(sp)
    80003a2e:	f022                	sd	s0,32(sp)
    80003a30:	ec26                	sd	s1,24(sp)
    80003a32:	e84a                	sd	s2,16(sp)
    80003a34:	e44e                	sd	s3,8(sp)
    80003a36:	e052                	sd	s4,0(sp)
    80003a38:	1800                	add	s0,sp,48
    80003a3a:	89aa                	mv	s3,a0
    80003a3c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a3e:	0001d517          	auipc	a0,0x1d
    80003a42:	eaa50513          	add	a0,a0,-342 # 800208e8 <itable>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	18c080e7          	jalr	396(ra) # 80000bd2 <acquire>
  empty = 0;
    80003a4e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a50:	0001d497          	auipc	s1,0x1d
    80003a54:	eb048493          	add	s1,s1,-336 # 80020900 <itable+0x18>
    80003a58:	0001f697          	auipc	a3,0x1f
    80003a5c:	93868693          	add	a3,a3,-1736 # 80022390 <log>
    80003a60:	a039                	j	80003a6e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a62:	02090b63          	beqz	s2,80003a98 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a66:	08848493          	add	s1,s1,136
    80003a6a:	02d48a63          	beq	s1,a3,80003a9e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a6e:	449c                	lw	a5,8(s1)
    80003a70:	fef059e3          	blez	a5,80003a62 <iget+0x38>
    80003a74:	4098                	lw	a4,0(s1)
    80003a76:	ff3716e3          	bne	a4,s3,80003a62 <iget+0x38>
    80003a7a:	40d8                	lw	a4,4(s1)
    80003a7c:	ff4713e3          	bne	a4,s4,80003a62 <iget+0x38>
      ip->ref++;
    80003a80:	2785                	addw	a5,a5,1
    80003a82:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a84:	0001d517          	auipc	a0,0x1d
    80003a88:	e6450513          	add	a0,a0,-412 # 800208e8 <itable>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	1fa080e7          	jalr	506(ra) # 80000c86 <release>
      return ip;
    80003a94:	8926                	mv	s2,s1
    80003a96:	a03d                	j	80003ac4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a98:	f7f9                	bnez	a5,80003a66 <iget+0x3c>
    80003a9a:	8926                	mv	s2,s1
    80003a9c:	b7e9                	j	80003a66 <iget+0x3c>
  if(empty == 0)
    80003a9e:	02090c63          	beqz	s2,80003ad6 <iget+0xac>
  ip->dev = dev;
    80003aa2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003aa6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003aaa:	4785                	li	a5,1
    80003aac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ab0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ab4:	0001d517          	auipc	a0,0x1d
    80003ab8:	e3450513          	add	a0,a0,-460 # 800208e8 <itable>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	1ca080e7          	jalr	458(ra) # 80000c86 <release>
}
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	70a2                	ld	ra,40(sp)
    80003ac8:	7402                	ld	s0,32(sp)
    80003aca:	64e2                	ld	s1,24(sp)
    80003acc:	6942                	ld	s2,16(sp)
    80003ace:	69a2                	ld	s3,8(sp)
    80003ad0:	6a02                	ld	s4,0(sp)
    80003ad2:	6145                	add	sp,sp,48
    80003ad4:	8082                	ret
    panic("iget: no inodes");
    80003ad6:	00005517          	auipc	a0,0x5
    80003ada:	af250513          	add	a0,a0,-1294 # 800085c8 <syscalls+0x150>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	a5e080e7          	jalr	-1442(ra) # 8000053c <panic>

0000000080003ae6 <fsinit>:
fsinit(int dev) {
    80003ae6:	7179                	add	sp,sp,-48
    80003ae8:	f406                	sd	ra,40(sp)
    80003aea:	f022                	sd	s0,32(sp)
    80003aec:	ec26                	sd	s1,24(sp)
    80003aee:	e84a                	sd	s2,16(sp)
    80003af0:	e44e                	sd	s3,8(sp)
    80003af2:	1800                	add	s0,sp,48
    80003af4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003af6:	4585                	li	a1,1
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	a56080e7          	jalr	-1450(ra) # 8000354e <bread>
    80003b00:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b02:	0001d997          	auipc	s3,0x1d
    80003b06:	dc698993          	add	s3,s3,-570 # 800208c8 <sb>
    80003b0a:	02000613          	li	a2,32
    80003b0e:	05850593          	add	a1,a0,88
    80003b12:	854e                	mv	a0,s3
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	216080e7          	jalr	534(ra) # 80000d2a <memmove>
  brelse(bp);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	b60080e7          	jalr	-1184(ra) # 8000367e <brelse>
  if(sb.magic != FSMAGIC)
    80003b26:	0009a703          	lw	a4,0(s3)
    80003b2a:	102037b7          	lui	a5,0x10203
    80003b2e:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b32:	02f71263          	bne	a4,a5,80003b56 <fsinit+0x70>
  initlog(dev, &sb);
    80003b36:	0001d597          	auipc	a1,0x1d
    80003b3a:	d9258593          	add	a1,a1,-622 # 800208c8 <sb>
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	b2c080e7          	jalr	-1236(ra) # 8000466c <initlog>
}
    80003b48:	70a2                	ld	ra,40(sp)
    80003b4a:	7402                	ld	s0,32(sp)
    80003b4c:	64e2                	ld	s1,24(sp)
    80003b4e:	6942                	ld	s2,16(sp)
    80003b50:	69a2                	ld	s3,8(sp)
    80003b52:	6145                	add	sp,sp,48
    80003b54:	8082                	ret
    panic("invalid file system");
    80003b56:	00005517          	auipc	a0,0x5
    80003b5a:	a8250513          	add	a0,a0,-1406 # 800085d8 <syscalls+0x160>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	9de080e7          	jalr	-1570(ra) # 8000053c <panic>

0000000080003b66 <iinit>:
{
    80003b66:	7179                	add	sp,sp,-48
    80003b68:	f406                	sd	ra,40(sp)
    80003b6a:	f022                	sd	s0,32(sp)
    80003b6c:	ec26                	sd	s1,24(sp)
    80003b6e:	e84a                	sd	s2,16(sp)
    80003b70:	e44e                	sd	s3,8(sp)
    80003b72:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b74:	00005597          	auipc	a1,0x5
    80003b78:	a7c58593          	add	a1,a1,-1412 # 800085f0 <syscalls+0x178>
    80003b7c:	0001d517          	auipc	a0,0x1d
    80003b80:	d6c50513          	add	a0,a0,-660 # 800208e8 <itable>
    80003b84:	ffffd097          	auipc	ra,0xffffd
    80003b88:	fbe080e7          	jalr	-66(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b8c:	0001d497          	auipc	s1,0x1d
    80003b90:	d8448493          	add	s1,s1,-636 # 80020910 <itable+0x28>
    80003b94:	0001f997          	auipc	s3,0x1f
    80003b98:	80c98993          	add	s3,s3,-2036 # 800223a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b9c:	00005917          	auipc	s2,0x5
    80003ba0:	a5c90913          	add	s2,s2,-1444 # 800085f8 <syscalls+0x180>
    80003ba4:	85ca                	mv	a1,s2
    80003ba6:	8526                	mv	a0,s1
    80003ba8:	00001097          	auipc	ra,0x1
    80003bac:	e12080e7          	jalr	-494(ra) # 800049ba <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003bb0:	08848493          	add	s1,s1,136
    80003bb4:	ff3498e3          	bne	s1,s3,80003ba4 <iinit+0x3e>
}
    80003bb8:	70a2                	ld	ra,40(sp)
    80003bba:	7402                	ld	s0,32(sp)
    80003bbc:	64e2                	ld	s1,24(sp)
    80003bbe:	6942                	ld	s2,16(sp)
    80003bc0:	69a2                	ld	s3,8(sp)
    80003bc2:	6145                	add	sp,sp,48
    80003bc4:	8082                	ret

0000000080003bc6 <ialloc>:
{
    80003bc6:	7139                	add	sp,sp,-64
    80003bc8:	fc06                	sd	ra,56(sp)
    80003bca:	f822                	sd	s0,48(sp)
    80003bcc:	f426                	sd	s1,40(sp)
    80003bce:	f04a                	sd	s2,32(sp)
    80003bd0:	ec4e                	sd	s3,24(sp)
    80003bd2:	e852                	sd	s4,16(sp)
    80003bd4:	e456                	sd	s5,8(sp)
    80003bd6:	e05a                	sd	s6,0(sp)
    80003bd8:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bda:	0001d717          	auipc	a4,0x1d
    80003bde:	cfa72703          	lw	a4,-774(a4) # 800208d4 <sb+0xc>
    80003be2:	4785                	li	a5,1
    80003be4:	04e7f863          	bgeu	a5,a4,80003c34 <ialloc+0x6e>
    80003be8:	8aaa                	mv	s5,a0
    80003bea:	8b2e                	mv	s6,a1
    80003bec:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bee:	0001da17          	auipc	s4,0x1d
    80003bf2:	cdaa0a13          	add	s4,s4,-806 # 800208c8 <sb>
    80003bf6:	00495593          	srl	a1,s2,0x4
    80003bfa:	018a2783          	lw	a5,24(s4)
    80003bfe:	9dbd                	addw	a1,a1,a5
    80003c00:	8556                	mv	a0,s5
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	94c080e7          	jalr	-1716(ra) # 8000354e <bread>
    80003c0a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c0c:	05850993          	add	s3,a0,88
    80003c10:	00f97793          	and	a5,s2,15
    80003c14:	079a                	sll	a5,a5,0x6
    80003c16:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c18:	00099783          	lh	a5,0(s3)
    80003c1c:	cf9d                	beqz	a5,80003c5a <ialloc+0x94>
    brelse(bp);
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	a60080e7          	jalr	-1440(ra) # 8000367e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c26:	0905                	add	s2,s2,1
    80003c28:	00ca2703          	lw	a4,12(s4)
    80003c2c:	0009079b          	sext.w	a5,s2
    80003c30:	fce7e3e3          	bltu	a5,a4,80003bf6 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003c34:	00005517          	auipc	a0,0x5
    80003c38:	9cc50513          	add	a0,a0,-1588 # 80008600 <syscalls+0x188>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	94a080e7          	jalr	-1718(ra) # 80000586 <printf>
  return 0;
    80003c44:	4501                	li	a0,0
}
    80003c46:	70e2                	ld	ra,56(sp)
    80003c48:	7442                	ld	s0,48(sp)
    80003c4a:	74a2                	ld	s1,40(sp)
    80003c4c:	7902                	ld	s2,32(sp)
    80003c4e:	69e2                	ld	s3,24(sp)
    80003c50:	6a42                	ld	s4,16(sp)
    80003c52:	6aa2                	ld	s5,8(sp)
    80003c54:	6b02                	ld	s6,0(sp)
    80003c56:	6121                	add	sp,sp,64
    80003c58:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c5a:	04000613          	li	a2,64
    80003c5e:	4581                	li	a1,0
    80003c60:	854e                	mv	a0,s3
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	06c080e7          	jalr	108(ra) # 80000cce <memset>
      dip->type = type;
    80003c6a:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c6e:	8526                	mv	a0,s1
    80003c70:	00001097          	auipc	ra,0x1
    80003c74:	c66080e7          	jalr	-922(ra) # 800048d6 <log_write>
      brelse(bp);
    80003c78:	8526                	mv	a0,s1
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	a04080e7          	jalr	-1532(ra) # 8000367e <brelse>
      return iget(dev, inum);
    80003c82:	0009059b          	sext.w	a1,s2
    80003c86:	8556                	mv	a0,s5
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	da2080e7          	jalr	-606(ra) # 80003a2a <iget>
    80003c90:	bf5d                	j	80003c46 <ialloc+0x80>

0000000080003c92 <iupdate>:
{
    80003c92:	1101                	add	sp,sp,-32
    80003c94:	ec06                	sd	ra,24(sp)
    80003c96:	e822                	sd	s0,16(sp)
    80003c98:	e426                	sd	s1,8(sp)
    80003c9a:	e04a                	sd	s2,0(sp)
    80003c9c:	1000                	add	s0,sp,32
    80003c9e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ca0:	415c                	lw	a5,4(a0)
    80003ca2:	0047d79b          	srlw	a5,a5,0x4
    80003ca6:	0001d597          	auipc	a1,0x1d
    80003caa:	c3a5a583          	lw	a1,-966(a1) # 800208e0 <sb+0x18>
    80003cae:	9dbd                	addw	a1,a1,a5
    80003cb0:	4108                	lw	a0,0(a0)
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	89c080e7          	jalr	-1892(ra) # 8000354e <bread>
    80003cba:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cbc:	05850793          	add	a5,a0,88
    80003cc0:	40d8                	lw	a4,4(s1)
    80003cc2:	8b3d                	and	a4,a4,15
    80003cc4:	071a                	sll	a4,a4,0x6
    80003cc6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003cc8:	04449703          	lh	a4,68(s1)
    80003ccc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003cd0:	04649703          	lh	a4,70(s1)
    80003cd4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003cd8:	04849703          	lh	a4,72(s1)
    80003cdc:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003ce0:	04a49703          	lh	a4,74(s1)
    80003ce4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ce8:	44f8                	lw	a4,76(s1)
    80003cea:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cec:	03400613          	li	a2,52
    80003cf0:	05048593          	add	a1,s1,80
    80003cf4:	00c78513          	add	a0,a5,12
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	032080e7          	jalr	50(ra) # 80000d2a <memmove>
  log_write(bp);
    80003d00:	854a                	mv	a0,s2
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	bd4080e7          	jalr	-1068(ra) # 800048d6 <log_write>
  brelse(bp);
    80003d0a:	854a                	mv	a0,s2
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	972080e7          	jalr	-1678(ra) # 8000367e <brelse>
}
    80003d14:	60e2                	ld	ra,24(sp)
    80003d16:	6442                	ld	s0,16(sp)
    80003d18:	64a2                	ld	s1,8(sp)
    80003d1a:	6902                	ld	s2,0(sp)
    80003d1c:	6105                	add	sp,sp,32
    80003d1e:	8082                	ret

0000000080003d20 <idup>:
{
    80003d20:	1101                	add	sp,sp,-32
    80003d22:	ec06                	sd	ra,24(sp)
    80003d24:	e822                	sd	s0,16(sp)
    80003d26:	e426                	sd	s1,8(sp)
    80003d28:	1000                	add	s0,sp,32
    80003d2a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d2c:	0001d517          	auipc	a0,0x1d
    80003d30:	bbc50513          	add	a0,a0,-1092 # 800208e8 <itable>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	e9e080e7          	jalr	-354(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003d3c:	449c                	lw	a5,8(s1)
    80003d3e:	2785                	addw	a5,a5,1
    80003d40:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d42:	0001d517          	auipc	a0,0x1d
    80003d46:	ba650513          	add	a0,a0,-1114 # 800208e8 <itable>
    80003d4a:	ffffd097          	auipc	ra,0xffffd
    80003d4e:	f3c080e7          	jalr	-196(ra) # 80000c86 <release>
}
    80003d52:	8526                	mv	a0,s1
    80003d54:	60e2                	ld	ra,24(sp)
    80003d56:	6442                	ld	s0,16(sp)
    80003d58:	64a2                	ld	s1,8(sp)
    80003d5a:	6105                	add	sp,sp,32
    80003d5c:	8082                	ret

0000000080003d5e <ilock>:
{
    80003d5e:	1101                	add	sp,sp,-32
    80003d60:	ec06                	sd	ra,24(sp)
    80003d62:	e822                	sd	s0,16(sp)
    80003d64:	e426                	sd	s1,8(sp)
    80003d66:	e04a                	sd	s2,0(sp)
    80003d68:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d6a:	c115                	beqz	a0,80003d8e <ilock+0x30>
    80003d6c:	84aa                	mv	s1,a0
    80003d6e:	451c                	lw	a5,8(a0)
    80003d70:	00f05f63          	blez	a5,80003d8e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d74:	0541                	add	a0,a0,16
    80003d76:	00001097          	auipc	ra,0x1
    80003d7a:	c7e080e7          	jalr	-898(ra) # 800049f4 <acquiresleep>
  if(ip->valid == 0){
    80003d7e:	40bc                	lw	a5,64(s1)
    80003d80:	cf99                	beqz	a5,80003d9e <ilock+0x40>
}
    80003d82:	60e2                	ld	ra,24(sp)
    80003d84:	6442                	ld	s0,16(sp)
    80003d86:	64a2                	ld	s1,8(sp)
    80003d88:	6902                	ld	s2,0(sp)
    80003d8a:	6105                	add	sp,sp,32
    80003d8c:	8082                	ret
    panic("ilock");
    80003d8e:	00005517          	auipc	a0,0x5
    80003d92:	88a50513          	add	a0,a0,-1910 # 80008618 <syscalls+0x1a0>
    80003d96:	ffffc097          	auipc	ra,0xffffc
    80003d9a:	7a6080e7          	jalr	1958(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d9e:	40dc                	lw	a5,4(s1)
    80003da0:	0047d79b          	srlw	a5,a5,0x4
    80003da4:	0001d597          	auipc	a1,0x1d
    80003da8:	b3c5a583          	lw	a1,-1220(a1) # 800208e0 <sb+0x18>
    80003dac:	9dbd                	addw	a1,a1,a5
    80003dae:	4088                	lw	a0,0(s1)
    80003db0:	fffff097          	auipc	ra,0xfffff
    80003db4:	79e080e7          	jalr	1950(ra) # 8000354e <bread>
    80003db8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dba:	05850593          	add	a1,a0,88
    80003dbe:	40dc                	lw	a5,4(s1)
    80003dc0:	8bbd                	and	a5,a5,15
    80003dc2:	079a                	sll	a5,a5,0x6
    80003dc4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003dc6:	00059783          	lh	a5,0(a1)
    80003dca:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dce:	00259783          	lh	a5,2(a1)
    80003dd2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003dd6:	00459783          	lh	a5,4(a1)
    80003dda:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dde:	00659783          	lh	a5,6(a1)
    80003de2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003de6:	459c                	lw	a5,8(a1)
    80003de8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dea:	03400613          	li	a2,52
    80003dee:	05b1                	add	a1,a1,12
    80003df0:	05048513          	add	a0,s1,80
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	f36080e7          	jalr	-202(ra) # 80000d2a <memmove>
    brelse(bp);
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	880080e7          	jalr	-1920(ra) # 8000367e <brelse>
    ip->valid = 1;
    80003e06:	4785                	li	a5,1
    80003e08:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e0a:	04449783          	lh	a5,68(s1)
    80003e0e:	fbb5                	bnez	a5,80003d82 <ilock+0x24>
      panic("ilock: no type");
    80003e10:	00005517          	auipc	a0,0x5
    80003e14:	81050513          	add	a0,a0,-2032 # 80008620 <syscalls+0x1a8>
    80003e18:	ffffc097          	auipc	ra,0xffffc
    80003e1c:	724080e7          	jalr	1828(ra) # 8000053c <panic>

0000000080003e20 <iunlock>:
{
    80003e20:	1101                	add	sp,sp,-32
    80003e22:	ec06                	sd	ra,24(sp)
    80003e24:	e822                	sd	s0,16(sp)
    80003e26:	e426                	sd	s1,8(sp)
    80003e28:	e04a                	sd	s2,0(sp)
    80003e2a:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e2c:	c905                	beqz	a0,80003e5c <iunlock+0x3c>
    80003e2e:	84aa                	mv	s1,a0
    80003e30:	01050913          	add	s2,a0,16
    80003e34:	854a                	mv	a0,s2
    80003e36:	00001097          	auipc	ra,0x1
    80003e3a:	c58080e7          	jalr	-936(ra) # 80004a8e <holdingsleep>
    80003e3e:	cd19                	beqz	a0,80003e5c <iunlock+0x3c>
    80003e40:	449c                	lw	a5,8(s1)
    80003e42:	00f05d63          	blez	a5,80003e5c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e46:	854a                	mv	a0,s2
    80003e48:	00001097          	auipc	ra,0x1
    80003e4c:	c02080e7          	jalr	-1022(ra) # 80004a4a <releasesleep>
}
    80003e50:	60e2                	ld	ra,24(sp)
    80003e52:	6442                	ld	s0,16(sp)
    80003e54:	64a2                	ld	s1,8(sp)
    80003e56:	6902                	ld	s2,0(sp)
    80003e58:	6105                	add	sp,sp,32
    80003e5a:	8082                	ret
    panic("iunlock");
    80003e5c:	00004517          	auipc	a0,0x4
    80003e60:	7d450513          	add	a0,a0,2004 # 80008630 <syscalls+0x1b8>
    80003e64:	ffffc097          	auipc	ra,0xffffc
    80003e68:	6d8080e7          	jalr	1752(ra) # 8000053c <panic>

0000000080003e6c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e6c:	7179                	add	sp,sp,-48
    80003e6e:	f406                	sd	ra,40(sp)
    80003e70:	f022                	sd	s0,32(sp)
    80003e72:	ec26                	sd	s1,24(sp)
    80003e74:	e84a                	sd	s2,16(sp)
    80003e76:	e44e                	sd	s3,8(sp)
    80003e78:	e052                	sd	s4,0(sp)
    80003e7a:	1800                	add	s0,sp,48
    80003e7c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e7e:	05050493          	add	s1,a0,80
    80003e82:	08050913          	add	s2,a0,128
    80003e86:	a021                	j	80003e8e <itrunc+0x22>
    80003e88:	0491                	add	s1,s1,4
    80003e8a:	01248d63          	beq	s1,s2,80003ea4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e8e:	408c                	lw	a1,0(s1)
    80003e90:	dde5                	beqz	a1,80003e88 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e92:	0009a503          	lw	a0,0(s3)
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	8fc080e7          	jalr	-1796(ra) # 80003792 <bfree>
      ip->addrs[i] = 0;
    80003e9e:	0004a023          	sw	zero,0(s1)
    80003ea2:	b7dd                	j	80003e88 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ea4:	0809a583          	lw	a1,128(s3)
    80003ea8:	e185                	bnez	a1,80003ec8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003eaa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	de2080e7          	jalr	-542(ra) # 80003c92 <iupdate>
}
    80003eb8:	70a2                	ld	ra,40(sp)
    80003eba:	7402                	ld	s0,32(sp)
    80003ebc:	64e2                	ld	s1,24(sp)
    80003ebe:	6942                	ld	s2,16(sp)
    80003ec0:	69a2                	ld	s3,8(sp)
    80003ec2:	6a02                	ld	s4,0(sp)
    80003ec4:	6145                	add	sp,sp,48
    80003ec6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ec8:	0009a503          	lw	a0,0(s3)
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	682080e7          	jalr	1666(ra) # 8000354e <bread>
    80003ed4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ed6:	05850493          	add	s1,a0,88
    80003eda:	45850913          	add	s2,a0,1112
    80003ede:	a021                	j	80003ee6 <itrunc+0x7a>
    80003ee0:	0491                	add	s1,s1,4
    80003ee2:	01248b63          	beq	s1,s2,80003ef8 <itrunc+0x8c>
      if(a[j])
    80003ee6:	408c                	lw	a1,0(s1)
    80003ee8:	dde5                	beqz	a1,80003ee0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003eea:	0009a503          	lw	a0,0(s3)
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	8a4080e7          	jalr	-1884(ra) # 80003792 <bfree>
    80003ef6:	b7ed                	j	80003ee0 <itrunc+0x74>
    brelse(bp);
    80003ef8:	8552                	mv	a0,s4
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	784080e7          	jalr	1924(ra) # 8000367e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f02:	0809a583          	lw	a1,128(s3)
    80003f06:	0009a503          	lw	a0,0(s3)
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	888080e7          	jalr	-1912(ra) # 80003792 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f12:	0809a023          	sw	zero,128(s3)
    80003f16:	bf51                	j	80003eaa <itrunc+0x3e>

0000000080003f18 <iput>:
{
    80003f18:	1101                	add	sp,sp,-32
    80003f1a:	ec06                	sd	ra,24(sp)
    80003f1c:	e822                	sd	s0,16(sp)
    80003f1e:	e426                	sd	s1,8(sp)
    80003f20:	e04a                	sd	s2,0(sp)
    80003f22:	1000                	add	s0,sp,32
    80003f24:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f26:	0001d517          	auipc	a0,0x1d
    80003f2a:	9c250513          	add	a0,a0,-1598 # 800208e8 <itable>
    80003f2e:	ffffd097          	auipc	ra,0xffffd
    80003f32:	ca4080e7          	jalr	-860(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f36:	4498                	lw	a4,8(s1)
    80003f38:	4785                	li	a5,1
    80003f3a:	02f70363          	beq	a4,a5,80003f60 <iput+0x48>
  ip->ref--;
    80003f3e:	449c                	lw	a5,8(s1)
    80003f40:	37fd                	addw	a5,a5,-1
    80003f42:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f44:	0001d517          	auipc	a0,0x1d
    80003f48:	9a450513          	add	a0,a0,-1628 # 800208e8 <itable>
    80003f4c:	ffffd097          	auipc	ra,0xffffd
    80003f50:	d3a080e7          	jalr	-710(ra) # 80000c86 <release>
}
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	64a2                	ld	s1,8(sp)
    80003f5a:	6902                	ld	s2,0(sp)
    80003f5c:	6105                	add	sp,sp,32
    80003f5e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f60:	40bc                	lw	a5,64(s1)
    80003f62:	dff1                	beqz	a5,80003f3e <iput+0x26>
    80003f64:	04a49783          	lh	a5,74(s1)
    80003f68:	fbf9                	bnez	a5,80003f3e <iput+0x26>
    acquiresleep(&ip->lock);
    80003f6a:	01048913          	add	s2,s1,16
    80003f6e:	854a                	mv	a0,s2
    80003f70:	00001097          	auipc	ra,0x1
    80003f74:	a84080e7          	jalr	-1404(ra) # 800049f4 <acquiresleep>
    release(&itable.lock);
    80003f78:	0001d517          	auipc	a0,0x1d
    80003f7c:	97050513          	add	a0,a0,-1680 # 800208e8 <itable>
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	d06080e7          	jalr	-762(ra) # 80000c86 <release>
    itrunc(ip);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	ee2080e7          	jalr	-286(ra) # 80003e6c <itrunc>
    ip->type = 0;
    80003f92:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f96:	8526                	mv	a0,s1
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	cfa080e7          	jalr	-774(ra) # 80003c92 <iupdate>
    ip->valid = 0;
    80003fa0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	00001097          	auipc	ra,0x1
    80003faa:	aa4080e7          	jalr	-1372(ra) # 80004a4a <releasesleep>
    acquire(&itable.lock);
    80003fae:	0001d517          	auipc	a0,0x1d
    80003fb2:	93a50513          	add	a0,a0,-1734 # 800208e8 <itable>
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	c1c080e7          	jalr	-996(ra) # 80000bd2 <acquire>
    80003fbe:	b741                	j	80003f3e <iput+0x26>

0000000080003fc0 <iunlockput>:
{
    80003fc0:	1101                	add	sp,sp,-32
    80003fc2:	ec06                	sd	ra,24(sp)
    80003fc4:	e822                	sd	s0,16(sp)
    80003fc6:	e426                	sd	s1,8(sp)
    80003fc8:	1000                	add	s0,sp,32
    80003fca:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	e54080e7          	jalr	-428(ra) # 80003e20 <iunlock>
  iput(ip);
    80003fd4:	8526                	mv	a0,s1
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	f42080e7          	jalr	-190(ra) # 80003f18 <iput>
}
    80003fde:	60e2                	ld	ra,24(sp)
    80003fe0:	6442                	ld	s0,16(sp)
    80003fe2:	64a2                	ld	s1,8(sp)
    80003fe4:	6105                	add	sp,sp,32
    80003fe6:	8082                	ret

0000000080003fe8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fe8:	1141                	add	sp,sp,-16
    80003fea:	e422                	sd	s0,8(sp)
    80003fec:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003fee:	411c                	lw	a5,0(a0)
    80003ff0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ff2:	415c                	lw	a5,4(a0)
    80003ff4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ff6:	04451783          	lh	a5,68(a0)
    80003ffa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ffe:	04a51783          	lh	a5,74(a0)
    80004002:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004006:	04c56783          	lwu	a5,76(a0)
    8000400a:	e99c                	sd	a5,16(a1)
}
    8000400c:	6422                	ld	s0,8(sp)
    8000400e:	0141                	add	sp,sp,16
    80004010:	8082                	ret

0000000080004012 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004012:	457c                	lw	a5,76(a0)
    80004014:	0ed7e963          	bltu	a5,a3,80004106 <readi+0xf4>
{
    80004018:	7159                	add	sp,sp,-112
    8000401a:	f486                	sd	ra,104(sp)
    8000401c:	f0a2                	sd	s0,96(sp)
    8000401e:	eca6                	sd	s1,88(sp)
    80004020:	e8ca                	sd	s2,80(sp)
    80004022:	e4ce                	sd	s3,72(sp)
    80004024:	e0d2                	sd	s4,64(sp)
    80004026:	fc56                	sd	s5,56(sp)
    80004028:	f85a                	sd	s6,48(sp)
    8000402a:	f45e                	sd	s7,40(sp)
    8000402c:	f062                	sd	s8,32(sp)
    8000402e:	ec66                	sd	s9,24(sp)
    80004030:	e86a                	sd	s10,16(sp)
    80004032:	e46e                	sd	s11,8(sp)
    80004034:	1880                	add	s0,sp,112
    80004036:	8b2a                	mv	s6,a0
    80004038:	8bae                	mv	s7,a1
    8000403a:	8a32                	mv	s4,a2
    8000403c:	84b6                	mv	s1,a3
    8000403e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004040:	9f35                	addw	a4,a4,a3
    return 0;
    80004042:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004044:	0ad76063          	bltu	a4,a3,800040e4 <readi+0xd2>
  if(off + n > ip->size)
    80004048:	00e7f463          	bgeu	a5,a4,80004050 <readi+0x3e>
    n = ip->size - off;
    8000404c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004050:	0a0a8963          	beqz	s5,80004102 <readi+0xf0>
    80004054:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004056:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000405a:	5c7d                	li	s8,-1
    8000405c:	a82d                	j	80004096 <readi+0x84>
    8000405e:	020d1d93          	sll	s11,s10,0x20
    80004062:	020ddd93          	srl	s11,s11,0x20
    80004066:	05890613          	add	a2,s2,88
    8000406a:	86ee                	mv	a3,s11
    8000406c:	963a                	add	a2,a2,a4
    8000406e:	85d2                	mv	a1,s4
    80004070:	855e                	mv	a0,s7
    80004072:	ffffe097          	auipc	ra,0xffffe
    80004076:	6c2080e7          	jalr	1730(ra) # 80002734 <either_copyout>
    8000407a:	05850d63          	beq	a0,s8,800040d4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000407e:	854a                	mv	a0,s2
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	5fe080e7          	jalr	1534(ra) # 8000367e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004088:	013d09bb          	addw	s3,s10,s3
    8000408c:	009d04bb          	addw	s1,s10,s1
    80004090:	9a6e                	add	s4,s4,s11
    80004092:	0559f763          	bgeu	s3,s5,800040e0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004096:	00a4d59b          	srlw	a1,s1,0xa
    8000409a:	855a                	mv	a0,s6
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	8a4080e7          	jalr	-1884(ra) # 80003940 <bmap>
    800040a4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040a8:	cd85                	beqz	a1,800040e0 <readi+0xce>
    bp = bread(ip->dev, addr);
    800040aa:	000b2503          	lw	a0,0(s6)
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	4a0080e7          	jalr	1184(ra) # 8000354e <bread>
    800040b6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b8:	3ff4f713          	and	a4,s1,1023
    800040bc:	40ec87bb          	subw	a5,s9,a4
    800040c0:	413a86bb          	subw	a3,s5,s3
    800040c4:	8d3e                	mv	s10,a5
    800040c6:	2781                	sext.w	a5,a5
    800040c8:	0006861b          	sext.w	a2,a3
    800040cc:	f8f679e3          	bgeu	a2,a5,8000405e <readi+0x4c>
    800040d0:	8d36                	mv	s10,a3
    800040d2:	b771                	j	8000405e <readi+0x4c>
      brelse(bp);
    800040d4:	854a                	mv	a0,s2
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	5a8080e7          	jalr	1448(ra) # 8000367e <brelse>
      tot = -1;
    800040de:	59fd                	li	s3,-1
  }
  return tot;
    800040e0:	0009851b          	sext.w	a0,s3
}
    800040e4:	70a6                	ld	ra,104(sp)
    800040e6:	7406                	ld	s0,96(sp)
    800040e8:	64e6                	ld	s1,88(sp)
    800040ea:	6946                	ld	s2,80(sp)
    800040ec:	69a6                	ld	s3,72(sp)
    800040ee:	6a06                	ld	s4,64(sp)
    800040f0:	7ae2                	ld	s5,56(sp)
    800040f2:	7b42                	ld	s6,48(sp)
    800040f4:	7ba2                	ld	s7,40(sp)
    800040f6:	7c02                	ld	s8,32(sp)
    800040f8:	6ce2                	ld	s9,24(sp)
    800040fa:	6d42                	ld	s10,16(sp)
    800040fc:	6da2                	ld	s11,8(sp)
    800040fe:	6165                	add	sp,sp,112
    80004100:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004102:	89d6                	mv	s3,s5
    80004104:	bff1                	j	800040e0 <readi+0xce>
    return 0;
    80004106:	4501                	li	a0,0
}
    80004108:	8082                	ret

000000008000410a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000410a:	457c                	lw	a5,76(a0)
    8000410c:	10d7e863          	bltu	a5,a3,8000421c <writei+0x112>
{
    80004110:	7159                	add	sp,sp,-112
    80004112:	f486                	sd	ra,104(sp)
    80004114:	f0a2                	sd	s0,96(sp)
    80004116:	eca6                	sd	s1,88(sp)
    80004118:	e8ca                	sd	s2,80(sp)
    8000411a:	e4ce                	sd	s3,72(sp)
    8000411c:	e0d2                	sd	s4,64(sp)
    8000411e:	fc56                	sd	s5,56(sp)
    80004120:	f85a                	sd	s6,48(sp)
    80004122:	f45e                	sd	s7,40(sp)
    80004124:	f062                	sd	s8,32(sp)
    80004126:	ec66                	sd	s9,24(sp)
    80004128:	e86a                	sd	s10,16(sp)
    8000412a:	e46e                	sd	s11,8(sp)
    8000412c:	1880                	add	s0,sp,112
    8000412e:	8aaa                	mv	s5,a0
    80004130:	8bae                	mv	s7,a1
    80004132:	8a32                	mv	s4,a2
    80004134:	8936                	mv	s2,a3
    80004136:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004138:	00e687bb          	addw	a5,a3,a4
    8000413c:	0ed7e263          	bltu	a5,a3,80004220 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004140:	00043737          	lui	a4,0x43
    80004144:	0ef76063          	bltu	a4,a5,80004224 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004148:	0c0b0863          	beqz	s6,80004218 <writei+0x10e>
    8000414c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000414e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004152:	5c7d                	li	s8,-1
    80004154:	a091                	j	80004198 <writei+0x8e>
    80004156:	020d1d93          	sll	s11,s10,0x20
    8000415a:	020ddd93          	srl	s11,s11,0x20
    8000415e:	05848513          	add	a0,s1,88
    80004162:	86ee                	mv	a3,s11
    80004164:	8652                	mv	a2,s4
    80004166:	85de                	mv	a1,s7
    80004168:	953a                	add	a0,a0,a4
    8000416a:	ffffe097          	auipc	ra,0xffffe
    8000416e:	620080e7          	jalr	1568(ra) # 8000278a <either_copyin>
    80004172:	07850263          	beq	a0,s8,800041d6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004176:	8526                	mv	a0,s1
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	75e080e7          	jalr	1886(ra) # 800048d6 <log_write>
    brelse(bp);
    80004180:	8526                	mv	a0,s1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	4fc080e7          	jalr	1276(ra) # 8000367e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000418a:	013d09bb          	addw	s3,s10,s3
    8000418e:	012d093b          	addw	s2,s10,s2
    80004192:	9a6e                	add	s4,s4,s11
    80004194:	0569f663          	bgeu	s3,s6,800041e0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004198:	00a9559b          	srlw	a1,s2,0xa
    8000419c:	8556                	mv	a0,s5
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	7a2080e7          	jalr	1954(ra) # 80003940 <bmap>
    800041a6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041aa:	c99d                	beqz	a1,800041e0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041ac:	000aa503          	lw	a0,0(s5)
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	39e080e7          	jalr	926(ra) # 8000354e <bread>
    800041b8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ba:	3ff97713          	and	a4,s2,1023
    800041be:	40ec87bb          	subw	a5,s9,a4
    800041c2:	413b06bb          	subw	a3,s6,s3
    800041c6:	8d3e                	mv	s10,a5
    800041c8:	2781                	sext.w	a5,a5
    800041ca:	0006861b          	sext.w	a2,a3
    800041ce:	f8f674e3          	bgeu	a2,a5,80004156 <writei+0x4c>
    800041d2:	8d36                	mv	s10,a3
    800041d4:	b749                	j	80004156 <writei+0x4c>
      brelse(bp);
    800041d6:	8526                	mv	a0,s1
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	4a6080e7          	jalr	1190(ra) # 8000367e <brelse>
  }

  if(off > ip->size)
    800041e0:	04caa783          	lw	a5,76(s5)
    800041e4:	0127f463          	bgeu	a5,s2,800041ec <writei+0xe2>
    ip->size = off;
    800041e8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041ec:	8556                	mv	a0,s5
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	aa4080e7          	jalr	-1372(ra) # 80003c92 <iupdate>

  return tot;
    800041f6:	0009851b          	sext.w	a0,s3
}
    800041fa:	70a6                	ld	ra,104(sp)
    800041fc:	7406                	ld	s0,96(sp)
    800041fe:	64e6                	ld	s1,88(sp)
    80004200:	6946                	ld	s2,80(sp)
    80004202:	69a6                	ld	s3,72(sp)
    80004204:	6a06                	ld	s4,64(sp)
    80004206:	7ae2                	ld	s5,56(sp)
    80004208:	7b42                	ld	s6,48(sp)
    8000420a:	7ba2                	ld	s7,40(sp)
    8000420c:	7c02                	ld	s8,32(sp)
    8000420e:	6ce2                	ld	s9,24(sp)
    80004210:	6d42                	ld	s10,16(sp)
    80004212:	6da2                	ld	s11,8(sp)
    80004214:	6165                	add	sp,sp,112
    80004216:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004218:	89da                	mv	s3,s6
    8000421a:	bfc9                	j	800041ec <writei+0xe2>
    return -1;
    8000421c:	557d                	li	a0,-1
}
    8000421e:	8082                	ret
    return -1;
    80004220:	557d                	li	a0,-1
    80004222:	bfe1                	j	800041fa <writei+0xf0>
    return -1;
    80004224:	557d                	li	a0,-1
    80004226:	bfd1                	j	800041fa <writei+0xf0>

0000000080004228 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004228:	1141                	add	sp,sp,-16
    8000422a:	e406                	sd	ra,8(sp)
    8000422c:	e022                	sd	s0,0(sp)
    8000422e:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004230:	4639                	li	a2,14
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	b6c080e7          	jalr	-1172(ra) # 80000d9e <strncmp>
}
    8000423a:	60a2                	ld	ra,8(sp)
    8000423c:	6402                	ld	s0,0(sp)
    8000423e:	0141                	add	sp,sp,16
    80004240:	8082                	ret

0000000080004242 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004242:	7139                	add	sp,sp,-64
    80004244:	fc06                	sd	ra,56(sp)
    80004246:	f822                	sd	s0,48(sp)
    80004248:	f426                	sd	s1,40(sp)
    8000424a:	f04a                	sd	s2,32(sp)
    8000424c:	ec4e                	sd	s3,24(sp)
    8000424e:	e852                	sd	s4,16(sp)
    80004250:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004252:	04451703          	lh	a4,68(a0)
    80004256:	4785                	li	a5,1
    80004258:	00f71a63          	bne	a4,a5,8000426c <dirlookup+0x2a>
    8000425c:	892a                	mv	s2,a0
    8000425e:	89ae                	mv	s3,a1
    80004260:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004262:	457c                	lw	a5,76(a0)
    80004264:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004266:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004268:	e79d                	bnez	a5,80004296 <dirlookup+0x54>
    8000426a:	a8a5                	j	800042e2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000426c:	00004517          	auipc	a0,0x4
    80004270:	3cc50513          	add	a0,a0,972 # 80008638 <syscalls+0x1c0>
    80004274:	ffffc097          	auipc	ra,0xffffc
    80004278:	2c8080e7          	jalr	712(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000427c:	00004517          	auipc	a0,0x4
    80004280:	3d450513          	add	a0,a0,980 # 80008650 <syscalls+0x1d8>
    80004284:	ffffc097          	auipc	ra,0xffffc
    80004288:	2b8080e7          	jalr	696(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000428c:	24c1                	addw	s1,s1,16
    8000428e:	04c92783          	lw	a5,76(s2)
    80004292:	04f4f763          	bgeu	s1,a5,800042e0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004296:	4741                	li	a4,16
    80004298:	86a6                	mv	a3,s1
    8000429a:	fc040613          	add	a2,s0,-64
    8000429e:	4581                	li	a1,0
    800042a0:	854a                	mv	a0,s2
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	d70080e7          	jalr	-656(ra) # 80004012 <readi>
    800042aa:	47c1                	li	a5,16
    800042ac:	fcf518e3          	bne	a0,a5,8000427c <dirlookup+0x3a>
    if(de.inum == 0)
    800042b0:	fc045783          	lhu	a5,-64(s0)
    800042b4:	dfe1                	beqz	a5,8000428c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042b6:	fc240593          	add	a1,s0,-62
    800042ba:	854e                	mv	a0,s3
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	f6c080e7          	jalr	-148(ra) # 80004228 <namecmp>
    800042c4:	f561                	bnez	a0,8000428c <dirlookup+0x4a>
      if(poff)
    800042c6:	000a0463          	beqz	s4,800042ce <dirlookup+0x8c>
        *poff = off;
    800042ca:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042ce:	fc045583          	lhu	a1,-64(s0)
    800042d2:	00092503          	lw	a0,0(s2)
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	754080e7          	jalr	1876(ra) # 80003a2a <iget>
    800042de:	a011                	j	800042e2 <dirlookup+0xa0>
  return 0;
    800042e0:	4501                	li	a0,0
}
    800042e2:	70e2                	ld	ra,56(sp)
    800042e4:	7442                	ld	s0,48(sp)
    800042e6:	74a2                	ld	s1,40(sp)
    800042e8:	7902                	ld	s2,32(sp)
    800042ea:	69e2                	ld	s3,24(sp)
    800042ec:	6a42                	ld	s4,16(sp)
    800042ee:	6121                	add	sp,sp,64
    800042f0:	8082                	ret

00000000800042f2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042f2:	711d                	add	sp,sp,-96
    800042f4:	ec86                	sd	ra,88(sp)
    800042f6:	e8a2                	sd	s0,80(sp)
    800042f8:	e4a6                	sd	s1,72(sp)
    800042fa:	e0ca                	sd	s2,64(sp)
    800042fc:	fc4e                	sd	s3,56(sp)
    800042fe:	f852                	sd	s4,48(sp)
    80004300:	f456                	sd	s5,40(sp)
    80004302:	f05a                	sd	s6,32(sp)
    80004304:	ec5e                	sd	s7,24(sp)
    80004306:	e862                	sd	s8,16(sp)
    80004308:	e466                	sd	s9,8(sp)
    8000430a:	1080                	add	s0,sp,96
    8000430c:	84aa                	mv	s1,a0
    8000430e:	8b2e                	mv	s6,a1
    80004310:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004312:	00054703          	lbu	a4,0(a0)
    80004316:	02f00793          	li	a5,47
    8000431a:	02f70263          	beq	a4,a5,8000433e <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	6e0080e7          	jalr	1760(ra) # 800019fe <myproc>
    80004326:	15053503          	ld	a0,336(a0)
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	9f6080e7          	jalr	-1546(ra) # 80003d20 <idup>
    80004332:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004334:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004338:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000433a:	4b85                	li	s7,1
    8000433c:	a875                	j	800043f8 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000433e:	4585                	li	a1,1
    80004340:	4505                	li	a0,1
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	6e8080e7          	jalr	1768(ra) # 80003a2a <iget>
    8000434a:	8a2a                	mv	s4,a0
    8000434c:	b7e5                	j	80004334 <namex+0x42>
      iunlockput(ip);
    8000434e:	8552                	mv	a0,s4
    80004350:	00000097          	auipc	ra,0x0
    80004354:	c70080e7          	jalr	-912(ra) # 80003fc0 <iunlockput>
      return 0;
    80004358:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000435a:	8552                	mv	a0,s4
    8000435c:	60e6                	ld	ra,88(sp)
    8000435e:	6446                	ld	s0,80(sp)
    80004360:	64a6                	ld	s1,72(sp)
    80004362:	6906                	ld	s2,64(sp)
    80004364:	79e2                	ld	s3,56(sp)
    80004366:	7a42                	ld	s4,48(sp)
    80004368:	7aa2                	ld	s5,40(sp)
    8000436a:	7b02                	ld	s6,32(sp)
    8000436c:	6be2                	ld	s7,24(sp)
    8000436e:	6c42                	ld	s8,16(sp)
    80004370:	6ca2                	ld	s9,8(sp)
    80004372:	6125                	add	sp,sp,96
    80004374:	8082                	ret
      iunlock(ip);
    80004376:	8552                	mv	a0,s4
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	aa8080e7          	jalr	-1368(ra) # 80003e20 <iunlock>
      return ip;
    80004380:	bfe9                	j	8000435a <namex+0x68>
      iunlockput(ip);
    80004382:	8552                	mv	a0,s4
    80004384:	00000097          	auipc	ra,0x0
    80004388:	c3c080e7          	jalr	-964(ra) # 80003fc0 <iunlockput>
      return 0;
    8000438c:	8a4e                	mv	s4,s3
    8000438e:	b7f1                	j	8000435a <namex+0x68>
  len = path - s;
    80004390:	40998633          	sub	a2,s3,s1
    80004394:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004398:	099c5863          	bge	s8,s9,80004428 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000439c:	4639                	li	a2,14
    8000439e:	85a6                	mv	a1,s1
    800043a0:	8556                	mv	a0,s5
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	988080e7          	jalr	-1656(ra) # 80000d2a <memmove>
    800043aa:	84ce                	mv	s1,s3
  while(*path == '/')
    800043ac:	0004c783          	lbu	a5,0(s1)
    800043b0:	01279763          	bne	a5,s2,800043be <namex+0xcc>
    path++;
    800043b4:	0485                	add	s1,s1,1
  while(*path == '/')
    800043b6:	0004c783          	lbu	a5,0(s1)
    800043ba:	ff278de3          	beq	a5,s2,800043b4 <namex+0xc2>
    ilock(ip);
    800043be:	8552                	mv	a0,s4
    800043c0:	00000097          	auipc	ra,0x0
    800043c4:	99e080e7          	jalr	-1634(ra) # 80003d5e <ilock>
    if(ip->type != T_DIR){
    800043c8:	044a1783          	lh	a5,68(s4)
    800043cc:	f97791e3          	bne	a5,s7,8000434e <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800043d0:	000b0563          	beqz	s6,800043da <namex+0xe8>
    800043d4:	0004c783          	lbu	a5,0(s1)
    800043d8:	dfd9                	beqz	a5,80004376 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043da:	4601                	li	a2,0
    800043dc:	85d6                	mv	a1,s5
    800043de:	8552                	mv	a0,s4
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	e62080e7          	jalr	-414(ra) # 80004242 <dirlookup>
    800043e8:	89aa                	mv	s3,a0
    800043ea:	dd41                	beqz	a0,80004382 <namex+0x90>
    iunlockput(ip);
    800043ec:	8552                	mv	a0,s4
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	bd2080e7          	jalr	-1070(ra) # 80003fc0 <iunlockput>
    ip = next;
    800043f6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800043f8:	0004c783          	lbu	a5,0(s1)
    800043fc:	01279763          	bne	a5,s2,8000440a <namex+0x118>
    path++;
    80004400:	0485                	add	s1,s1,1
  while(*path == '/')
    80004402:	0004c783          	lbu	a5,0(s1)
    80004406:	ff278de3          	beq	a5,s2,80004400 <namex+0x10e>
  if(*path == 0)
    8000440a:	cb9d                	beqz	a5,80004440 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000440c:	0004c783          	lbu	a5,0(s1)
    80004410:	89a6                	mv	s3,s1
  len = path - s;
    80004412:	4c81                	li	s9,0
    80004414:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004416:	01278963          	beq	a5,s2,80004428 <namex+0x136>
    8000441a:	dbbd                	beqz	a5,80004390 <namex+0x9e>
    path++;
    8000441c:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    8000441e:	0009c783          	lbu	a5,0(s3)
    80004422:	ff279ce3          	bne	a5,s2,8000441a <namex+0x128>
    80004426:	b7ad                	j	80004390 <namex+0x9e>
    memmove(name, s, len);
    80004428:	2601                	sext.w	a2,a2
    8000442a:	85a6                	mv	a1,s1
    8000442c:	8556                	mv	a0,s5
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	8fc080e7          	jalr	-1796(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004436:	9cd6                	add	s9,s9,s5
    80004438:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000443c:	84ce                	mv	s1,s3
    8000443e:	b7bd                	j	800043ac <namex+0xba>
  if(nameiparent){
    80004440:	f00b0de3          	beqz	s6,8000435a <namex+0x68>
    iput(ip);
    80004444:	8552                	mv	a0,s4
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	ad2080e7          	jalr	-1326(ra) # 80003f18 <iput>
    return 0;
    8000444e:	4a01                	li	s4,0
    80004450:	b729                	j	8000435a <namex+0x68>

0000000080004452 <dirlink>:
{
    80004452:	7139                	add	sp,sp,-64
    80004454:	fc06                	sd	ra,56(sp)
    80004456:	f822                	sd	s0,48(sp)
    80004458:	f426                	sd	s1,40(sp)
    8000445a:	f04a                	sd	s2,32(sp)
    8000445c:	ec4e                	sd	s3,24(sp)
    8000445e:	e852                	sd	s4,16(sp)
    80004460:	0080                	add	s0,sp,64
    80004462:	892a                	mv	s2,a0
    80004464:	8a2e                	mv	s4,a1
    80004466:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004468:	4601                	li	a2,0
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	dd8080e7          	jalr	-552(ra) # 80004242 <dirlookup>
    80004472:	e93d                	bnez	a0,800044e8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004474:	04c92483          	lw	s1,76(s2)
    80004478:	c49d                	beqz	s1,800044a6 <dirlink+0x54>
    8000447a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000447c:	4741                	li	a4,16
    8000447e:	86a6                	mv	a3,s1
    80004480:	fc040613          	add	a2,s0,-64
    80004484:	4581                	li	a1,0
    80004486:	854a                	mv	a0,s2
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	b8a080e7          	jalr	-1142(ra) # 80004012 <readi>
    80004490:	47c1                	li	a5,16
    80004492:	06f51163          	bne	a0,a5,800044f4 <dirlink+0xa2>
    if(de.inum == 0)
    80004496:	fc045783          	lhu	a5,-64(s0)
    8000449a:	c791                	beqz	a5,800044a6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000449c:	24c1                	addw	s1,s1,16
    8000449e:	04c92783          	lw	a5,76(s2)
    800044a2:	fcf4ede3          	bltu	s1,a5,8000447c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044a6:	4639                	li	a2,14
    800044a8:	85d2                	mv	a1,s4
    800044aa:	fc240513          	add	a0,s0,-62
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	92c080e7          	jalr	-1748(ra) # 80000dda <strncpy>
  de.inum = inum;
    800044b6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ba:	4741                	li	a4,16
    800044bc:	86a6                	mv	a3,s1
    800044be:	fc040613          	add	a2,s0,-64
    800044c2:	4581                	li	a1,0
    800044c4:	854a                	mv	a0,s2
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	c44080e7          	jalr	-956(ra) # 8000410a <writei>
    800044ce:	1541                	add	a0,a0,-16
    800044d0:	00a03533          	snez	a0,a0
    800044d4:	40a00533          	neg	a0,a0
}
    800044d8:	70e2                	ld	ra,56(sp)
    800044da:	7442                	ld	s0,48(sp)
    800044dc:	74a2                	ld	s1,40(sp)
    800044de:	7902                	ld	s2,32(sp)
    800044e0:	69e2                	ld	s3,24(sp)
    800044e2:	6a42                	ld	s4,16(sp)
    800044e4:	6121                	add	sp,sp,64
    800044e6:	8082                	ret
    iput(ip);
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	a30080e7          	jalr	-1488(ra) # 80003f18 <iput>
    return -1;
    800044f0:	557d                	li	a0,-1
    800044f2:	b7dd                	j	800044d8 <dirlink+0x86>
      panic("dirlink read");
    800044f4:	00004517          	auipc	a0,0x4
    800044f8:	16c50513          	add	a0,a0,364 # 80008660 <syscalls+0x1e8>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	040080e7          	jalr	64(ra) # 8000053c <panic>

0000000080004504 <namei>:

struct inode*
namei(char *path)
{
    80004504:	1101                	add	sp,sp,-32
    80004506:	ec06                	sd	ra,24(sp)
    80004508:	e822                	sd	s0,16(sp)
    8000450a:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000450c:	fe040613          	add	a2,s0,-32
    80004510:	4581                	li	a1,0
    80004512:	00000097          	auipc	ra,0x0
    80004516:	de0080e7          	jalr	-544(ra) # 800042f2 <namex>
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	6105                	add	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004522:	1141                	add	sp,sp,-16
    80004524:	e406                	sd	ra,8(sp)
    80004526:	e022                	sd	s0,0(sp)
    80004528:	0800                	add	s0,sp,16
    8000452a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000452c:	4585                	li	a1,1
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	dc4080e7          	jalr	-572(ra) # 800042f2 <namex>
}
    80004536:	60a2                	ld	ra,8(sp)
    80004538:	6402                	ld	s0,0(sp)
    8000453a:	0141                	add	sp,sp,16
    8000453c:	8082                	ret

000000008000453e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000453e:	1101                	add	sp,sp,-32
    80004540:	ec06                	sd	ra,24(sp)
    80004542:	e822                	sd	s0,16(sp)
    80004544:	e426                	sd	s1,8(sp)
    80004546:	e04a                	sd	s2,0(sp)
    80004548:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000454a:	0001e917          	auipc	s2,0x1e
    8000454e:	e4690913          	add	s2,s2,-442 # 80022390 <log>
    80004552:	01892583          	lw	a1,24(s2)
    80004556:	02892503          	lw	a0,40(s2)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	ff4080e7          	jalr	-12(ra) # 8000354e <bread>
    80004562:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004564:	02c92603          	lw	a2,44(s2)
    80004568:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	00c05f63          	blez	a2,80004588 <write_head+0x4a>
    8000456e:	0001e717          	auipc	a4,0x1e
    80004572:	e5270713          	add	a4,a4,-430 # 800223c0 <log+0x30>
    80004576:	87aa                	mv	a5,a0
    80004578:	060a                	sll	a2,a2,0x2
    8000457a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000457c:	4314                	lw	a3,0(a4)
    8000457e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004580:	0711                	add	a4,a4,4
    80004582:	0791                	add	a5,a5,4
    80004584:	fec79ce3          	bne	a5,a2,8000457c <write_head+0x3e>
  }
  bwrite(buf);
    80004588:	8526                	mv	a0,s1
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	0b6080e7          	jalr	182(ra) # 80003640 <bwrite>
  brelse(buf);
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	0ea080e7          	jalr	234(ra) # 8000367e <brelse>
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6902                	ld	s2,0(sp)
    800045a4:	6105                	add	sp,sp,32
    800045a6:	8082                	ret

00000000800045a8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a8:	0001e797          	auipc	a5,0x1e
    800045ac:	e147a783          	lw	a5,-492(a5) # 800223bc <log+0x2c>
    800045b0:	0af05d63          	blez	a5,8000466a <install_trans+0xc2>
{
    800045b4:	7139                	add	sp,sp,-64
    800045b6:	fc06                	sd	ra,56(sp)
    800045b8:	f822                	sd	s0,48(sp)
    800045ba:	f426                	sd	s1,40(sp)
    800045bc:	f04a                	sd	s2,32(sp)
    800045be:	ec4e                	sd	s3,24(sp)
    800045c0:	e852                	sd	s4,16(sp)
    800045c2:	e456                	sd	s5,8(sp)
    800045c4:	e05a                	sd	s6,0(sp)
    800045c6:	0080                	add	s0,sp,64
    800045c8:	8b2a                	mv	s6,a0
    800045ca:	0001ea97          	auipc	s5,0x1e
    800045ce:	df6a8a93          	add	s5,s5,-522 # 800223c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d4:	0001e997          	auipc	s3,0x1e
    800045d8:	dbc98993          	add	s3,s3,-580 # 80022390 <log>
    800045dc:	a00d                	j	800045fe <install_trans+0x56>
    brelse(lbuf);
    800045de:	854a                	mv	a0,s2
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	09e080e7          	jalr	158(ra) # 8000367e <brelse>
    brelse(dbuf);
    800045e8:	8526                	mv	a0,s1
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	094080e7          	jalr	148(ra) # 8000367e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045f2:	2a05                	addw	s4,s4,1
    800045f4:	0a91                	add	s5,s5,4
    800045f6:	02c9a783          	lw	a5,44(s3)
    800045fa:	04fa5e63          	bge	s4,a5,80004656 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045fe:	0189a583          	lw	a1,24(s3)
    80004602:	014585bb          	addw	a1,a1,s4
    80004606:	2585                	addw	a1,a1,1
    80004608:	0289a503          	lw	a0,40(s3)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	f42080e7          	jalr	-190(ra) # 8000354e <bread>
    80004614:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004616:	000aa583          	lw	a1,0(s5)
    8000461a:	0289a503          	lw	a0,40(s3)
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	f30080e7          	jalr	-208(ra) # 8000354e <bread>
    80004626:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004628:	40000613          	li	a2,1024
    8000462c:	05890593          	add	a1,s2,88
    80004630:	05850513          	add	a0,a0,88
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	6f6080e7          	jalr	1782(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000463c:	8526                	mv	a0,s1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	002080e7          	jalr	2(ra) # 80003640 <bwrite>
    if(recovering == 0)
    80004646:	f80b1ce3          	bnez	s6,800045de <install_trans+0x36>
      bunpin(dbuf);
    8000464a:	8526                	mv	a0,s1
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	10a080e7          	jalr	266(ra) # 80003756 <bunpin>
    80004654:	b769                	j	800045de <install_trans+0x36>
}
    80004656:	70e2                	ld	ra,56(sp)
    80004658:	7442                	ld	s0,48(sp)
    8000465a:	74a2                	ld	s1,40(sp)
    8000465c:	7902                	ld	s2,32(sp)
    8000465e:	69e2                	ld	s3,24(sp)
    80004660:	6a42                	ld	s4,16(sp)
    80004662:	6aa2                	ld	s5,8(sp)
    80004664:	6b02                	ld	s6,0(sp)
    80004666:	6121                	add	sp,sp,64
    80004668:	8082                	ret
    8000466a:	8082                	ret

000000008000466c <initlog>:
{
    8000466c:	7179                	add	sp,sp,-48
    8000466e:	f406                	sd	ra,40(sp)
    80004670:	f022                	sd	s0,32(sp)
    80004672:	ec26                	sd	s1,24(sp)
    80004674:	e84a                	sd	s2,16(sp)
    80004676:	e44e                	sd	s3,8(sp)
    80004678:	1800                	add	s0,sp,48
    8000467a:	892a                	mv	s2,a0
    8000467c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000467e:	0001e497          	auipc	s1,0x1e
    80004682:	d1248493          	add	s1,s1,-750 # 80022390 <log>
    80004686:	00004597          	auipc	a1,0x4
    8000468a:	fea58593          	add	a1,a1,-22 # 80008670 <syscalls+0x1f8>
    8000468e:	8526                	mv	a0,s1
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	4b2080e7          	jalr	1202(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004698:	0149a583          	lw	a1,20(s3)
    8000469c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000469e:	0109a783          	lw	a5,16(s3)
    800046a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046a8:	854a                	mv	a0,s2
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	ea4080e7          	jalr	-348(ra) # 8000354e <bread>
  log.lh.n = lh->n;
    800046b2:	4d30                	lw	a2,88(a0)
    800046b4:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046b6:	00c05f63          	blez	a2,800046d4 <initlog+0x68>
    800046ba:	87aa                	mv	a5,a0
    800046bc:	0001e717          	auipc	a4,0x1e
    800046c0:	d0470713          	add	a4,a4,-764 # 800223c0 <log+0x30>
    800046c4:	060a                	sll	a2,a2,0x2
    800046c6:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800046c8:	4ff4                	lw	a3,92(a5)
    800046ca:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046cc:	0791                	add	a5,a5,4
    800046ce:	0711                	add	a4,a4,4
    800046d0:	fec79ce3          	bne	a5,a2,800046c8 <initlog+0x5c>
  brelse(buf);
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	faa080e7          	jalr	-86(ra) # 8000367e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046dc:	4505                	li	a0,1
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	eca080e7          	jalr	-310(ra) # 800045a8 <install_trans>
  log.lh.n = 0;
    800046e6:	0001e797          	auipc	a5,0x1e
    800046ea:	cc07ab23          	sw	zero,-810(a5) # 800223bc <log+0x2c>
  write_head(); // clear the log
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	e50080e7          	jalr	-432(ra) # 8000453e <write_head>
}
    800046f6:	70a2                	ld	ra,40(sp)
    800046f8:	7402                	ld	s0,32(sp)
    800046fa:	64e2                	ld	s1,24(sp)
    800046fc:	6942                	ld	s2,16(sp)
    800046fe:	69a2                	ld	s3,8(sp)
    80004700:	6145                	add	sp,sp,48
    80004702:	8082                	ret

0000000080004704 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004704:	1101                	add	sp,sp,-32
    80004706:	ec06                	sd	ra,24(sp)
    80004708:	e822                	sd	s0,16(sp)
    8000470a:	e426                	sd	s1,8(sp)
    8000470c:	e04a                	sd	s2,0(sp)
    8000470e:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004710:	0001e517          	auipc	a0,0x1e
    80004714:	c8050513          	add	a0,a0,-896 # 80022390 <log>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	4ba080e7          	jalr	1210(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004720:	0001e497          	auipc	s1,0x1e
    80004724:	c7048493          	add	s1,s1,-912 # 80022390 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004728:	4979                	li	s2,30
    8000472a:	a039                	j	80004738 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000472c:	85a6                	mv	a1,s1
    8000472e:	8526                	mv	a0,s1
    80004730:	ffffe097          	auipc	ra,0xffffe
    80004734:	bbe080e7          	jalr	-1090(ra) # 800022ee <sleep>
    if(log.committing){
    80004738:	50dc                	lw	a5,36(s1)
    8000473a:	fbed                	bnez	a5,8000472c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000473c:	5098                	lw	a4,32(s1)
    8000473e:	2705                	addw	a4,a4,1
    80004740:	0027179b          	sllw	a5,a4,0x2
    80004744:	9fb9                	addw	a5,a5,a4
    80004746:	0017979b          	sllw	a5,a5,0x1
    8000474a:	54d4                	lw	a3,44(s1)
    8000474c:	9fb5                	addw	a5,a5,a3
    8000474e:	00f95963          	bge	s2,a5,80004760 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004752:	85a6                	mv	a1,s1
    80004754:	8526                	mv	a0,s1
    80004756:	ffffe097          	auipc	ra,0xffffe
    8000475a:	b98080e7          	jalr	-1128(ra) # 800022ee <sleep>
    8000475e:	bfe9                	j	80004738 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004760:	0001e517          	auipc	a0,0x1e
    80004764:	c3050513          	add	a0,a0,-976 # 80022390 <log>
    80004768:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	51c080e7          	jalr	1308(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004772:	60e2                	ld	ra,24(sp)
    80004774:	6442                	ld	s0,16(sp)
    80004776:	64a2                	ld	s1,8(sp)
    80004778:	6902                	ld	s2,0(sp)
    8000477a:	6105                	add	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000477e:	7139                	add	sp,sp,-64
    80004780:	fc06                	sd	ra,56(sp)
    80004782:	f822                	sd	s0,48(sp)
    80004784:	f426                	sd	s1,40(sp)
    80004786:	f04a                	sd	s2,32(sp)
    80004788:	ec4e                	sd	s3,24(sp)
    8000478a:	e852                	sd	s4,16(sp)
    8000478c:	e456                	sd	s5,8(sp)
    8000478e:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004790:	0001e497          	auipc	s1,0x1e
    80004794:	c0048493          	add	s1,s1,-1024 # 80022390 <log>
    80004798:	8526                	mv	a0,s1
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	438080e7          	jalr	1080(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800047a2:	509c                	lw	a5,32(s1)
    800047a4:	37fd                	addw	a5,a5,-1
    800047a6:	0007891b          	sext.w	s2,a5
    800047aa:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047ac:	50dc                	lw	a5,36(s1)
    800047ae:	e7b9                	bnez	a5,800047fc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047b0:	04091e63          	bnez	s2,8000480c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047b4:	0001e497          	auipc	s1,0x1e
    800047b8:	bdc48493          	add	s1,s1,-1060 # 80022390 <log>
    800047bc:	4785                	li	a5,1
    800047be:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4c4080e7          	jalr	1220(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047ca:	54dc                	lw	a5,44(s1)
    800047cc:	06f04763          	bgtz	a5,8000483a <end_op+0xbc>
    acquire(&log.lock);
    800047d0:	0001e497          	auipc	s1,0x1e
    800047d4:	bc048493          	add	s1,s1,-1088 # 80022390 <log>
    800047d8:	8526                	mv	a0,s1
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	3f8080e7          	jalr	1016(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800047e2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047e6:	8526                	mv	a0,s1
    800047e8:	ffffe097          	auipc	ra,0xffffe
    800047ec:	b6a080e7          	jalr	-1174(ra) # 80002352 <wakeup>
    release(&log.lock);
    800047f0:	8526                	mv	a0,s1
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	494080e7          	jalr	1172(ra) # 80000c86 <release>
}
    800047fa:	a03d                	j	80004828 <end_op+0xaa>
    panic("log.committing");
    800047fc:	00004517          	auipc	a0,0x4
    80004800:	e7c50513          	add	a0,a0,-388 # 80008678 <syscalls+0x200>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	d38080e7          	jalr	-712(ra) # 8000053c <panic>
    wakeup(&log);
    8000480c:	0001e497          	auipc	s1,0x1e
    80004810:	b8448493          	add	s1,s1,-1148 # 80022390 <log>
    80004814:	8526                	mv	a0,s1
    80004816:	ffffe097          	auipc	ra,0xffffe
    8000481a:	b3c080e7          	jalr	-1220(ra) # 80002352 <wakeup>
  release(&log.lock);
    8000481e:	8526                	mv	a0,s1
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	466080e7          	jalr	1126(ra) # 80000c86 <release>
}
    80004828:	70e2                	ld	ra,56(sp)
    8000482a:	7442                	ld	s0,48(sp)
    8000482c:	74a2                	ld	s1,40(sp)
    8000482e:	7902                	ld	s2,32(sp)
    80004830:	69e2                	ld	s3,24(sp)
    80004832:	6a42                	ld	s4,16(sp)
    80004834:	6aa2                	ld	s5,8(sp)
    80004836:	6121                	add	sp,sp,64
    80004838:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000483a:	0001ea97          	auipc	s5,0x1e
    8000483e:	b86a8a93          	add	s5,s5,-1146 # 800223c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004842:	0001ea17          	auipc	s4,0x1e
    80004846:	b4ea0a13          	add	s4,s4,-1202 # 80022390 <log>
    8000484a:	018a2583          	lw	a1,24(s4)
    8000484e:	012585bb          	addw	a1,a1,s2
    80004852:	2585                	addw	a1,a1,1
    80004854:	028a2503          	lw	a0,40(s4)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	cf6080e7          	jalr	-778(ra) # 8000354e <bread>
    80004860:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004862:	000aa583          	lw	a1,0(s5)
    80004866:	028a2503          	lw	a0,40(s4)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	ce4080e7          	jalr	-796(ra) # 8000354e <bread>
    80004872:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004874:	40000613          	li	a2,1024
    80004878:	05850593          	add	a1,a0,88
    8000487c:	05848513          	add	a0,s1,88
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	4aa080e7          	jalr	1194(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004888:	8526                	mv	a0,s1
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	db6080e7          	jalr	-586(ra) # 80003640 <bwrite>
    brelse(from);
    80004892:	854e                	mv	a0,s3
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	dea080e7          	jalr	-534(ra) # 8000367e <brelse>
    brelse(to);
    8000489c:	8526                	mv	a0,s1
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	de0080e7          	jalr	-544(ra) # 8000367e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048a6:	2905                	addw	s2,s2,1
    800048a8:	0a91                	add	s5,s5,4
    800048aa:	02ca2783          	lw	a5,44(s4)
    800048ae:	f8f94ee3          	blt	s2,a5,8000484a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	c8c080e7          	jalr	-884(ra) # 8000453e <write_head>
    install_trans(0); // Now install writes to home locations
    800048ba:	4501                	li	a0,0
    800048bc:	00000097          	auipc	ra,0x0
    800048c0:	cec080e7          	jalr	-788(ra) # 800045a8 <install_trans>
    log.lh.n = 0;
    800048c4:	0001e797          	auipc	a5,0x1e
    800048c8:	ae07ac23          	sw	zero,-1288(a5) # 800223bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	c72080e7          	jalr	-910(ra) # 8000453e <write_head>
    800048d4:	bdf5                	j	800047d0 <end_op+0x52>

00000000800048d6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048d6:	1101                	add	sp,sp,-32
    800048d8:	ec06                	sd	ra,24(sp)
    800048da:	e822                	sd	s0,16(sp)
    800048dc:	e426                	sd	s1,8(sp)
    800048de:	e04a                	sd	s2,0(sp)
    800048e0:	1000                	add	s0,sp,32
    800048e2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048e4:	0001e917          	auipc	s2,0x1e
    800048e8:	aac90913          	add	s2,s2,-1364 # 80022390 <log>
    800048ec:	854a                	mv	a0,s2
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	2e4080e7          	jalr	740(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048f6:	02c92603          	lw	a2,44(s2)
    800048fa:	47f5                	li	a5,29
    800048fc:	06c7c563          	blt	a5,a2,80004966 <log_write+0x90>
    80004900:	0001e797          	auipc	a5,0x1e
    80004904:	aac7a783          	lw	a5,-1364(a5) # 800223ac <log+0x1c>
    80004908:	37fd                	addw	a5,a5,-1
    8000490a:	04f65e63          	bge	a2,a5,80004966 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000490e:	0001e797          	auipc	a5,0x1e
    80004912:	aa27a783          	lw	a5,-1374(a5) # 800223b0 <log+0x20>
    80004916:	06f05063          	blez	a5,80004976 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000491a:	4781                	li	a5,0
    8000491c:	06c05563          	blez	a2,80004986 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004920:	44cc                	lw	a1,12(s1)
    80004922:	0001e717          	auipc	a4,0x1e
    80004926:	a9e70713          	add	a4,a4,-1378 # 800223c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000492a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000492c:	4314                	lw	a3,0(a4)
    8000492e:	04b68c63          	beq	a3,a1,80004986 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004932:	2785                	addw	a5,a5,1
    80004934:	0711                	add	a4,a4,4
    80004936:	fef61be3          	bne	a2,a5,8000492c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000493a:	0621                	add	a2,a2,8
    8000493c:	060a                	sll	a2,a2,0x2
    8000493e:	0001e797          	auipc	a5,0x1e
    80004942:	a5278793          	add	a5,a5,-1454 # 80022390 <log>
    80004946:	97b2                	add	a5,a5,a2
    80004948:	44d8                	lw	a4,12(s1)
    8000494a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000494c:	8526                	mv	a0,s1
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	dcc080e7          	jalr	-564(ra) # 8000371a <bpin>
    log.lh.n++;
    80004956:	0001e717          	auipc	a4,0x1e
    8000495a:	a3a70713          	add	a4,a4,-1478 # 80022390 <log>
    8000495e:	575c                	lw	a5,44(a4)
    80004960:	2785                	addw	a5,a5,1
    80004962:	d75c                	sw	a5,44(a4)
    80004964:	a82d                	j	8000499e <log_write+0xc8>
    panic("too big a transaction");
    80004966:	00004517          	auipc	a0,0x4
    8000496a:	d2250513          	add	a0,a0,-734 # 80008688 <syscalls+0x210>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	bce080e7          	jalr	-1074(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004976:	00004517          	auipc	a0,0x4
    8000497a:	d2a50513          	add	a0,a0,-726 # 800086a0 <syscalls+0x228>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	bbe080e7          	jalr	-1090(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004986:	00878693          	add	a3,a5,8
    8000498a:	068a                	sll	a3,a3,0x2
    8000498c:	0001e717          	auipc	a4,0x1e
    80004990:	a0470713          	add	a4,a4,-1532 # 80022390 <log>
    80004994:	9736                	add	a4,a4,a3
    80004996:	44d4                	lw	a3,12(s1)
    80004998:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000499a:	faf609e3          	beq	a2,a5,8000494c <log_write+0x76>
  }
  release(&log.lock);
    8000499e:	0001e517          	auipc	a0,0x1e
    800049a2:	9f250513          	add	a0,a0,-1550 # 80022390 <log>
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	2e0080e7          	jalr	736(ra) # 80000c86 <release>
}
    800049ae:	60e2                	ld	ra,24(sp)
    800049b0:	6442                	ld	s0,16(sp)
    800049b2:	64a2                	ld	s1,8(sp)
    800049b4:	6902                	ld	s2,0(sp)
    800049b6:	6105                	add	sp,sp,32
    800049b8:	8082                	ret

00000000800049ba <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049ba:	1101                	add	sp,sp,-32
    800049bc:	ec06                	sd	ra,24(sp)
    800049be:	e822                	sd	s0,16(sp)
    800049c0:	e426                	sd	s1,8(sp)
    800049c2:	e04a                	sd	s2,0(sp)
    800049c4:	1000                	add	s0,sp,32
    800049c6:	84aa                	mv	s1,a0
    800049c8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ca:	00004597          	auipc	a1,0x4
    800049ce:	cf658593          	add	a1,a1,-778 # 800086c0 <syscalls+0x248>
    800049d2:	0521                	add	a0,a0,8
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	16e080e7          	jalr	366(ra) # 80000b42 <initlock>
  lk->name = name;
    800049dc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049e4:	0204a423          	sw	zero,40(s1)
}
    800049e8:	60e2                	ld	ra,24(sp)
    800049ea:	6442                	ld	s0,16(sp)
    800049ec:	64a2                	ld	s1,8(sp)
    800049ee:	6902                	ld	s2,0(sp)
    800049f0:	6105                	add	sp,sp,32
    800049f2:	8082                	ret

00000000800049f4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049f4:	1101                	add	sp,sp,-32
    800049f6:	ec06                	sd	ra,24(sp)
    800049f8:	e822                	sd	s0,16(sp)
    800049fa:	e426                	sd	s1,8(sp)
    800049fc:	e04a                	sd	s2,0(sp)
    800049fe:	1000                	add	s0,sp,32
    80004a00:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a02:	00850913          	add	s2,a0,8
    80004a06:	854a                	mv	a0,s2
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	1ca080e7          	jalr	458(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004a10:	409c                	lw	a5,0(s1)
    80004a12:	cb89                	beqz	a5,80004a24 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a14:	85ca                	mv	a1,s2
    80004a16:	8526                	mv	a0,s1
    80004a18:	ffffe097          	auipc	ra,0xffffe
    80004a1c:	8d6080e7          	jalr	-1834(ra) # 800022ee <sleep>
  while (lk->locked) {
    80004a20:	409c                	lw	a5,0(s1)
    80004a22:	fbed                	bnez	a5,80004a14 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a24:	4785                	li	a5,1
    80004a26:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a28:	ffffd097          	auipc	ra,0xffffd
    80004a2c:	fd6080e7          	jalr	-42(ra) # 800019fe <myproc>
    80004a30:	591c                	lw	a5,48(a0)
    80004a32:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a34:	854a                	mv	a0,s2
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80004a3e:	60e2                	ld	ra,24(sp)
    80004a40:	6442                	ld	s0,16(sp)
    80004a42:	64a2                	ld	s1,8(sp)
    80004a44:	6902                	ld	s2,0(sp)
    80004a46:	6105                	add	sp,sp,32
    80004a48:	8082                	ret

0000000080004a4a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a4a:	1101                	add	sp,sp,-32
    80004a4c:	ec06                	sd	ra,24(sp)
    80004a4e:	e822                	sd	s0,16(sp)
    80004a50:	e426                	sd	s1,8(sp)
    80004a52:	e04a                	sd	s2,0(sp)
    80004a54:	1000                	add	s0,sp,32
    80004a56:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a58:	00850913          	add	s2,a0,8
    80004a5c:	854a                	mv	a0,s2
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	174080e7          	jalr	372(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004a66:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a6a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffe097          	auipc	ra,0xffffe
    80004a74:	8e2080e7          	jalr	-1822(ra) # 80002352 <wakeup>
  release(&lk->lk);
    80004a78:	854a                	mv	a0,s2
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	20c080e7          	jalr	524(ra) # 80000c86 <release>
}
    80004a82:	60e2                	ld	ra,24(sp)
    80004a84:	6442                	ld	s0,16(sp)
    80004a86:	64a2                	ld	s1,8(sp)
    80004a88:	6902                	ld	s2,0(sp)
    80004a8a:	6105                	add	sp,sp,32
    80004a8c:	8082                	ret

0000000080004a8e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a8e:	7179                	add	sp,sp,-48
    80004a90:	f406                	sd	ra,40(sp)
    80004a92:	f022                	sd	s0,32(sp)
    80004a94:	ec26                	sd	s1,24(sp)
    80004a96:	e84a                	sd	s2,16(sp)
    80004a98:	e44e                	sd	s3,8(sp)
    80004a9a:	1800                	add	s0,sp,48
    80004a9c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a9e:	00850913          	add	s2,a0,8
    80004aa2:	854a                	mv	a0,s2
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	12e080e7          	jalr	302(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aac:	409c                	lw	a5,0(s1)
    80004aae:	ef99                	bnez	a5,80004acc <holdingsleep+0x3e>
    80004ab0:	4481                	li	s1,0
  release(&lk->lk);
    80004ab2:	854a                	mv	a0,s2
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	1d2080e7          	jalr	466(ra) # 80000c86 <release>
  return r;
}
    80004abc:	8526                	mv	a0,s1
    80004abe:	70a2                	ld	ra,40(sp)
    80004ac0:	7402                	ld	s0,32(sp)
    80004ac2:	64e2                	ld	s1,24(sp)
    80004ac4:	6942                	ld	s2,16(sp)
    80004ac6:	69a2                	ld	s3,8(sp)
    80004ac8:	6145                	add	sp,sp,48
    80004aca:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004acc:	0284a983          	lw	s3,40(s1)
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	f2e080e7          	jalr	-210(ra) # 800019fe <myproc>
    80004ad8:	5904                	lw	s1,48(a0)
    80004ada:	413484b3          	sub	s1,s1,s3
    80004ade:	0014b493          	seqz	s1,s1
    80004ae2:	bfc1                	j	80004ab2 <holdingsleep+0x24>

0000000080004ae4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ae4:	1141                	add	sp,sp,-16
    80004ae6:	e406                	sd	ra,8(sp)
    80004ae8:	e022                	sd	s0,0(sp)
    80004aea:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004aec:	00004597          	auipc	a1,0x4
    80004af0:	be458593          	add	a1,a1,-1052 # 800086d0 <syscalls+0x258>
    80004af4:	0001e517          	auipc	a0,0x1e
    80004af8:	9e450513          	add	a0,a0,-1564 # 800224d8 <ftable>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	046080e7          	jalr	70(ra) # 80000b42 <initlock>
}
    80004b04:	60a2                	ld	ra,8(sp)
    80004b06:	6402                	ld	s0,0(sp)
    80004b08:	0141                	add	sp,sp,16
    80004b0a:	8082                	ret

0000000080004b0c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b0c:	1101                	add	sp,sp,-32
    80004b0e:	ec06                	sd	ra,24(sp)
    80004b10:	e822                	sd	s0,16(sp)
    80004b12:	e426                	sd	s1,8(sp)
    80004b14:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b16:	0001e517          	auipc	a0,0x1e
    80004b1a:	9c250513          	add	a0,a0,-1598 # 800224d8 <ftable>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0b4080e7          	jalr	180(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b26:	0001e497          	auipc	s1,0x1e
    80004b2a:	9ca48493          	add	s1,s1,-1590 # 800224f0 <ftable+0x18>
    80004b2e:	0001f717          	auipc	a4,0x1f
    80004b32:	96270713          	add	a4,a4,-1694 # 80023490 <disk>
    if(f->ref == 0){
    80004b36:	40dc                	lw	a5,4(s1)
    80004b38:	cf99                	beqz	a5,80004b56 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b3a:	02848493          	add	s1,s1,40
    80004b3e:	fee49ce3          	bne	s1,a4,80004b36 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b42:	0001e517          	auipc	a0,0x1e
    80004b46:	99650513          	add	a0,a0,-1642 # 800224d8 <ftable>
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	13c080e7          	jalr	316(ra) # 80000c86 <release>
  return 0;
    80004b52:	4481                	li	s1,0
    80004b54:	a819                	j	80004b6a <filealloc+0x5e>
      f->ref = 1;
    80004b56:	4785                	li	a5,1
    80004b58:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b5a:	0001e517          	auipc	a0,0x1e
    80004b5e:	97e50513          	add	a0,a0,-1666 # 800224d8 <ftable>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	124080e7          	jalr	292(ra) # 80000c86 <release>
}
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	60e2                	ld	ra,24(sp)
    80004b6e:	6442                	ld	s0,16(sp)
    80004b70:	64a2                	ld	s1,8(sp)
    80004b72:	6105                	add	sp,sp,32
    80004b74:	8082                	ret

0000000080004b76 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b76:	1101                	add	sp,sp,-32
    80004b78:	ec06                	sd	ra,24(sp)
    80004b7a:	e822                	sd	s0,16(sp)
    80004b7c:	e426                	sd	s1,8(sp)
    80004b7e:	1000                	add	s0,sp,32
    80004b80:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b82:	0001e517          	auipc	a0,0x1e
    80004b86:	95650513          	add	a0,a0,-1706 # 800224d8 <ftable>
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	048080e7          	jalr	72(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004b92:	40dc                	lw	a5,4(s1)
    80004b94:	02f05263          	blez	a5,80004bb8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b98:	2785                	addw	a5,a5,1
    80004b9a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b9c:	0001e517          	auipc	a0,0x1e
    80004ba0:	93c50513          	add	a0,a0,-1732 # 800224d8 <ftable>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	0e2080e7          	jalr	226(ra) # 80000c86 <release>
  return f;
}
    80004bac:	8526                	mv	a0,s1
    80004bae:	60e2                	ld	ra,24(sp)
    80004bb0:	6442                	ld	s0,16(sp)
    80004bb2:	64a2                	ld	s1,8(sp)
    80004bb4:	6105                	add	sp,sp,32
    80004bb6:	8082                	ret
    panic("filedup");
    80004bb8:	00004517          	auipc	a0,0x4
    80004bbc:	b2050513          	add	a0,a0,-1248 # 800086d8 <syscalls+0x260>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	97c080e7          	jalr	-1668(ra) # 8000053c <panic>

0000000080004bc8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bc8:	7139                	add	sp,sp,-64
    80004bca:	fc06                	sd	ra,56(sp)
    80004bcc:	f822                	sd	s0,48(sp)
    80004bce:	f426                	sd	s1,40(sp)
    80004bd0:	f04a                	sd	s2,32(sp)
    80004bd2:	ec4e                	sd	s3,24(sp)
    80004bd4:	e852                	sd	s4,16(sp)
    80004bd6:	e456                	sd	s5,8(sp)
    80004bd8:	0080                	add	s0,sp,64
    80004bda:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bdc:	0001e517          	auipc	a0,0x1e
    80004be0:	8fc50513          	add	a0,a0,-1796 # 800224d8 <ftable>
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	fee080e7          	jalr	-18(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004bec:	40dc                	lw	a5,4(s1)
    80004bee:	06f05163          	blez	a5,80004c50 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bf2:	37fd                	addw	a5,a5,-1
    80004bf4:	0007871b          	sext.w	a4,a5
    80004bf8:	c0dc                	sw	a5,4(s1)
    80004bfa:	06e04363          	bgtz	a4,80004c60 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bfe:	0004a903          	lw	s2,0(s1)
    80004c02:	0094ca83          	lbu	s5,9(s1)
    80004c06:	0104ba03          	ld	s4,16(s1)
    80004c0a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c0e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c12:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c16:	0001e517          	auipc	a0,0x1e
    80004c1a:	8c250513          	add	a0,a0,-1854 # 800224d8 <ftable>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	068080e7          	jalr	104(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004c26:	4785                	li	a5,1
    80004c28:	04f90d63          	beq	s2,a5,80004c82 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c2c:	3979                	addw	s2,s2,-2
    80004c2e:	4785                	li	a5,1
    80004c30:	0527e063          	bltu	a5,s2,80004c70 <fileclose+0xa8>
    begin_op();
    80004c34:	00000097          	auipc	ra,0x0
    80004c38:	ad0080e7          	jalr	-1328(ra) # 80004704 <begin_op>
    iput(ff.ip);
    80004c3c:	854e                	mv	a0,s3
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	2da080e7          	jalr	730(ra) # 80003f18 <iput>
    end_op();
    80004c46:	00000097          	auipc	ra,0x0
    80004c4a:	b38080e7          	jalr	-1224(ra) # 8000477e <end_op>
    80004c4e:	a00d                	j	80004c70 <fileclose+0xa8>
    panic("fileclose");
    80004c50:	00004517          	auipc	a0,0x4
    80004c54:	a9050513          	add	a0,a0,-1392 # 800086e0 <syscalls+0x268>
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	8e4080e7          	jalr	-1820(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004c60:	0001e517          	auipc	a0,0x1e
    80004c64:	87850513          	add	a0,a0,-1928 # 800224d8 <ftable>
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	01e080e7          	jalr	30(ra) # 80000c86 <release>
  }
}
    80004c70:	70e2                	ld	ra,56(sp)
    80004c72:	7442                	ld	s0,48(sp)
    80004c74:	74a2                	ld	s1,40(sp)
    80004c76:	7902                	ld	s2,32(sp)
    80004c78:	69e2                	ld	s3,24(sp)
    80004c7a:	6a42                	ld	s4,16(sp)
    80004c7c:	6aa2                	ld	s5,8(sp)
    80004c7e:	6121                	add	sp,sp,64
    80004c80:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c82:	85d6                	mv	a1,s5
    80004c84:	8552                	mv	a0,s4
    80004c86:	00000097          	auipc	ra,0x0
    80004c8a:	348080e7          	jalr	840(ra) # 80004fce <pipeclose>
    80004c8e:	b7cd                	j	80004c70 <fileclose+0xa8>

0000000080004c90 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c90:	715d                	add	sp,sp,-80
    80004c92:	e486                	sd	ra,72(sp)
    80004c94:	e0a2                	sd	s0,64(sp)
    80004c96:	fc26                	sd	s1,56(sp)
    80004c98:	f84a                	sd	s2,48(sp)
    80004c9a:	f44e                	sd	s3,40(sp)
    80004c9c:	0880                	add	s0,sp,80
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	d5c080e7          	jalr	-676(ra) # 800019fe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004caa:	409c                	lw	a5,0(s1)
    80004cac:	37f9                	addw	a5,a5,-2
    80004cae:	4705                	li	a4,1
    80004cb0:	04f76763          	bltu	a4,a5,80004cfe <filestat+0x6e>
    80004cb4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cb6:	6c88                	ld	a0,24(s1)
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	0a6080e7          	jalr	166(ra) # 80003d5e <ilock>
    stati(f->ip, &st);
    80004cc0:	fb840593          	add	a1,s0,-72
    80004cc4:	6c88                	ld	a0,24(s1)
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	322080e7          	jalr	802(ra) # 80003fe8 <stati>
    iunlock(f->ip);
    80004cce:	6c88                	ld	a0,24(s1)
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	150080e7          	jalr	336(ra) # 80003e20 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cd8:	46e1                	li	a3,24
    80004cda:	fb840613          	add	a2,s0,-72
    80004cde:	85ce                	mv	a1,s3
    80004ce0:	05093503          	ld	a0,80(s2)
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	982080e7          	jalr	-1662(ra) # 80001666 <copyout>
    80004cec:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cf0:	60a6                	ld	ra,72(sp)
    80004cf2:	6406                	ld	s0,64(sp)
    80004cf4:	74e2                	ld	s1,56(sp)
    80004cf6:	7942                	ld	s2,48(sp)
    80004cf8:	79a2                	ld	s3,40(sp)
    80004cfa:	6161                	add	sp,sp,80
    80004cfc:	8082                	ret
  return -1;
    80004cfe:	557d                	li	a0,-1
    80004d00:	bfc5                	j	80004cf0 <filestat+0x60>

0000000080004d02 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d02:	7179                	add	sp,sp,-48
    80004d04:	f406                	sd	ra,40(sp)
    80004d06:	f022                	sd	s0,32(sp)
    80004d08:	ec26                	sd	s1,24(sp)
    80004d0a:	e84a                	sd	s2,16(sp)
    80004d0c:	e44e                	sd	s3,8(sp)
    80004d0e:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d10:	00854783          	lbu	a5,8(a0)
    80004d14:	c3d5                	beqz	a5,80004db8 <fileread+0xb6>
    80004d16:	84aa                	mv	s1,a0
    80004d18:	89ae                	mv	s3,a1
    80004d1a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d1c:	411c                	lw	a5,0(a0)
    80004d1e:	4705                	li	a4,1
    80004d20:	04e78963          	beq	a5,a4,80004d72 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d24:	470d                	li	a4,3
    80004d26:	04e78d63          	beq	a5,a4,80004d80 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d2a:	4709                	li	a4,2
    80004d2c:	06e79e63          	bne	a5,a4,80004da8 <fileread+0xa6>
    ilock(f->ip);
    80004d30:	6d08                	ld	a0,24(a0)
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	02c080e7          	jalr	44(ra) # 80003d5e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d3a:	874a                	mv	a4,s2
    80004d3c:	5094                	lw	a3,32(s1)
    80004d3e:	864e                	mv	a2,s3
    80004d40:	4585                	li	a1,1
    80004d42:	6c88                	ld	a0,24(s1)
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	2ce080e7          	jalr	718(ra) # 80004012 <readi>
    80004d4c:	892a                	mv	s2,a0
    80004d4e:	00a05563          	blez	a0,80004d58 <fileread+0x56>
      f->off += r;
    80004d52:	509c                	lw	a5,32(s1)
    80004d54:	9fa9                	addw	a5,a5,a0
    80004d56:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d58:	6c88                	ld	a0,24(s1)
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	0c6080e7          	jalr	198(ra) # 80003e20 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d62:	854a                	mv	a0,s2
    80004d64:	70a2                	ld	ra,40(sp)
    80004d66:	7402                	ld	s0,32(sp)
    80004d68:	64e2                	ld	s1,24(sp)
    80004d6a:	6942                	ld	s2,16(sp)
    80004d6c:	69a2                	ld	s3,8(sp)
    80004d6e:	6145                	add	sp,sp,48
    80004d70:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d72:	6908                	ld	a0,16(a0)
    80004d74:	00000097          	auipc	ra,0x0
    80004d78:	3c2080e7          	jalr	962(ra) # 80005136 <piperead>
    80004d7c:	892a                	mv	s2,a0
    80004d7e:	b7d5                	j	80004d62 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d80:	02451783          	lh	a5,36(a0)
    80004d84:	03079693          	sll	a3,a5,0x30
    80004d88:	92c1                	srl	a3,a3,0x30
    80004d8a:	4725                	li	a4,9
    80004d8c:	02d76863          	bltu	a4,a3,80004dbc <fileread+0xba>
    80004d90:	0792                	sll	a5,a5,0x4
    80004d92:	0001d717          	auipc	a4,0x1d
    80004d96:	6a670713          	add	a4,a4,1702 # 80022438 <devsw>
    80004d9a:	97ba                	add	a5,a5,a4
    80004d9c:	639c                	ld	a5,0(a5)
    80004d9e:	c38d                	beqz	a5,80004dc0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004da0:	4505                	li	a0,1
    80004da2:	9782                	jalr	a5
    80004da4:	892a                	mv	s2,a0
    80004da6:	bf75                	j	80004d62 <fileread+0x60>
    panic("fileread");
    80004da8:	00004517          	auipc	a0,0x4
    80004dac:	94850513          	add	a0,a0,-1720 # 800086f0 <syscalls+0x278>
    80004db0:	ffffb097          	auipc	ra,0xffffb
    80004db4:	78c080e7          	jalr	1932(ra) # 8000053c <panic>
    return -1;
    80004db8:	597d                	li	s2,-1
    80004dba:	b765                	j	80004d62 <fileread+0x60>
      return -1;
    80004dbc:	597d                	li	s2,-1
    80004dbe:	b755                	j	80004d62 <fileread+0x60>
    80004dc0:	597d                	li	s2,-1
    80004dc2:	b745                	j	80004d62 <fileread+0x60>

0000000080004dc4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004dc4:	00954783          	lbu	a5,9(a0)
    80004dc8:	10078e63          	beqz	a5,80004ee4 <filewrite+0x120>
{
    80004dcc:	715d                	add	sp,sp,-80
    80004dce:	e486                	sd	ra,72(sp)
    80004dd0:	e0a2                	sd	s0,64(sp)
    80004dd2:	fc26                	sd	s1,56(sp)
    80004dd4:	f84a                	sd	s2,48(sp)
    80004dd6:	f44e                	sd	s3,40(sp)
    80004dd8:	f052                	sd	s4,32(sp)
    80004dda:	ec56                	sd	s5,24(sp)
    80004ddc:	e85a                	sd	s6,16(sp)
    80004dde:	e45e                	sd	s7,8(sp)
    80004de0:	e062                	sd	s8,0(sp)
    80004de2:	0880                	add	s0,sp,80
    80004de4:	892a                	mv	s2,a0
    80004de6:	8b2e                	mv	s6,a1
    80004de8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dea:	411c                	lw	a5,0(a0)
    80004dec:	4705                	li	a4,1
    80004dee:	02e78263          	beq	a5,a4,80004e12 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004df2:	470d                	li	a4,3
    80004df4:	02e78563          	beq	a5,a4,80004e1e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004df8:	4709                	li	a4,2
    80004dfa:	0ce79d63          	bne	a5,a4,80004ed4 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dfe:	0ac05b63          	blez	a2,80004eb4 <filewrite+0xf0>
    int i = 0;
    80004e02:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e04:	6b85                	lui	s7,0x1
    80004e06:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e0a:	6c05                	lui	s8,0x1
    80004e0c:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e10:	a851                	j	80004ea4 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e12:	6908                	ld	a0,16(a0)
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	22a080e7          	jalr	554(ra) # 8000503e <pipewrite>
    80004e1c:	a045                	j	80004ebc <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e1e:	02451783          	lh	a5,36(a0)
    80004e22:	03079693          	sll	a3,a5,0x30
    80004e26:	92c1                	srl	a3,a3,0x30
    80004e28:	4725                	li	a4,9
    80004e2a:	0ad76f63          	bltu	a4,a3,80004ee8 <filewrite+0x124>
    80004e2e:	0792                	sll	a5,a5,0x4
    80004e30:	0001d717          	auipc	a4,0x1d
    80004e34:	60870713          	add	a4,a4,1544 # 80022438 <devsw>
    80004e38:	97ba                	add	a5,a5,a4
    80004e3a:	679c                	ld	a5,8(a5)
    80004e3c:	cbc5                	beqz	a5,80004eec <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004e3e:	4505                	li	a0,1
    80004e40:	9782                	jalr	a5
    80004e42:	a8ad                	j	80004ebc <filewrite+0xf8>
      if(n1 > max)
    80004e44:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	8bc080e7          	jalr	-1860(ra) # 80004704 <begin_op>
      ilock(f->ip);
    80004e50:	01893503          	ld	a0,24(s2)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	f0a080e7          	jalr	-246(ra) # 80003d5e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e5c:	8756                	mv	a4,s5
    80004e5e:	02092683          	lw	a3,32(s2)
    80004e62:	01698633          	add	a2,s3,s6
    80004e66:	4585                	li	a1,1
    80004e68:	01893503          	ld	a0,24(s2)
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	29e080e7          	jalr	670(ra) # 8000410a <writei>
    80004e74:	84aa                	mv	s1,a0
    80004e76:	00a05763          	blez	a0,80004e84 <filewrite+0xc0>
        f->off += r;
    80004e7a:	02092783          	lw	a5,32(s2)
    80004e7e:	9fa9                	addw	a5,a5,a0
    80004e80:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e84:	01893503          	ld	a0,24(s2)
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	f98080e7          	jalr	-104(ra) # 80003e20 <iunlock>
      end_op();
    80004e90:	00000097          	auipc	ra,0x0
    80004e94:	8ee080e7          	jalr	-1810(ra) # 8000477e <end_op>

      if(r != n1){
    80004e98:	009a9f63          	bne	s5,s1,80004eb6 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004e9c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ea0:	0149db63          	bge	s3,s4,80004eb6 <filewrite+0xf2>
      int n1 = n - i;
    80004ea4:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004ea8:	0004879b          	sext.w	a5,s1
    80004eac:	f8fbdce3          	bge	s7,a5,80004e44 <filewrite+0x80>
    80004eb0:	84e2                	mv	s1,s8
    80004eb2:	bf49                	j	80004e44 <filewrite+0x80>
    int i = 0;
    80004eb4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004eb6:	033a1d63          	bne	s4,s3,80004ef0 <filewrite+0x12c>
    80004eba:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ebc:	60a6                	ld	ra,72(sp)
    80004ebe:	6406                	ld	s0,64(sp)
    80004ec0:	74e2                	ld	s1,56(sp)
    80004ec2:	7942                	ld	s2,48(sp)
    80004ec4:	79a2                	ld	s3,40(sp)
    80004ec6:	7a02                	ld	s4,32(sp)
    80004ec8:	6ae2                	ld	s5,24(sp)
    80004eca:	6b42                	ld	s6,16(sp)
    80004ecc:	6ba2                	ld	s7,8(sp)
    80004ece:	6c02                	ld	s8,0(sp)
    80004ed0:	6161                	add	sp,sp,80
    80004ed2:	8082                	ret
    panic("filewrite");
    80004ed4:	00004517          	auipc	a0,0x4
    80004ed8:	82c50513          	add	a0,a0,-2004 # 80008700 <syscalls+0x288>
    80004edc:	ffffb097          	auipc	ra,0xffffb
    80004ee0:	660080e7          	jalr	1632(ra) # 8000053c <panic>
    return -1;
    80004ee4:	557d                	li	a0,-1
}
    80004ee6:	8082                	ret
      return -1;
    80004ee8:	557d                	li	a0,-1
    80004eea:	bfc9                	j	80004ebc <filewrite+0xf8>
    80004eec:	557d                	li	a0,-1
    80004eee:	b7f9                	j	80004ebc <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004ef0:	557d                	li	a0,-1
    80004ef2:	b7e9                	j	80004ebc <filewrite+0xf8>

0000000080004ef4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ef4:	7179                	add	sp,sp,-48
    80004ef6:	f406                	sd	ra,40(sp)
    80004ef8:	f022                	sd	s0,32(sp)
    80004efa:	ec26                	sd	s1,24(sp)
    80004efc:	e84a                	sd	s2,16(sp)
    80004efe:	e44e                	sd	s3,8(sp)
    80004f00:	e052                	sd	s4,0(sp)
    80004f02:	1800                	add	s0,sp,48
    80004f04:	84aa                	mv	s1,a0
    80004f06:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f08:	0005b023          	sd	zero,0(a1)
    80004f0c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	bfc080e7          	jalr	-1028(ra) # 80004b0c <filealloc>
    80004f18:	e088                	sd	a0,0(s1)
    80004f1a:	c551                	beqz	a0,80004fa6 <pipealloc+0xb2>
    80004f1c:	00000097          	auipc	ra,0x0
    80004f20:	bf0080e7          	jalr	-1040(ra) # 80004b0c <filealloc>
    80004f24:	00aa3023          	sd	a0,0(s4)
    80004f28:	c92d                	beqz	a0,80004f9a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	bb8080e7          	jalr	-1096(ra) # 80000ae2 <kalloc>
    80004f32:	892a                	mv	s2,a0
    80004f34:	c125                	beqz	a0,80004f94 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f36:	4985                	li	s3,1
    80004f38:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f3c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f40:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f44:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f48:	00003597          	auipc	a1,0x3
    80004f4c:	7c858593          	add	a1,a1,1992 # 80008710 <syscalls+0x298>
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	bf2080e7          	jalr	-1038(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004f58:	609c                	ld	a5,0(s1)
    80004f5a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f5e:	609c                	ld	a5,0(s1)
    80004f60:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f64:	609c                	ld	a5,0(s1)
    80004f66:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f6a:	609c                	ld	a5,0(s1)
    80004f6c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f70:	000a3783          	ld	a5,0(s4)
    80004f74:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f78:	000a3783          	ld	a5,0(s4)
    80004f7c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f80:	000a3783          	ld	a5,0(s4)
    80004f84:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f88:	000a3783          	ld	a5,0(s4)
    80004f8c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f90:	4501                	li	a0,0
    80004f92:	a025                	j	80004fba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f94:	6088                	ld	a0,0(s1)
    80004f96:	e501                	bnez	a0,80004f9e <pipealloc+0xaa>
    80004f98:	a039                	j	80004fa6 <pipealloc+0xb2>
    80004f9a:	6088                	ld	a0,0(s1)
    80004f9c:	c51d                	beqz	a0,80004fca <pipealloc+0xd6>
    fileclose(*f0);
    80004f9e:	00000097          	auipc	ra,0x0
    80004fa2:	c2a080e7          	jalr	-982(ra) # 80004bc8 <fileclose>
  if(*f1)
    80004fa6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004faa:	557d                	li	a0,-1
  if(*f1)
    80004fac:	c799                	beqz	a5,80004fba <pipealloc+0xc6>
    fileclose(*f1);
    80004fae:	853e                	mv	a0,a5
    80004fb0:	00000097          	auipc	ra,0x0
    80004fb4:	c18080e7          	jalr	-1000(ra) # 80004bc8 <fileclose>
  return -1;
    80004fb8:	557d                	li	a0,-1
}
    80004fba:	70a2                	ld	ra,40(sp)
    80004fbc:	7402                	ld	s0,32(sp)
    80004fbe:	64e2                	ld	s1,24(sp)
    80004fc0:	6942                	ld	s2,16(sp)
    80004fc2:	69a2                	ld	s3,8(sp)
    80004fc4:	6a02                	ld	s4,0(sp)
    80004fc6:	6145                	add	sp,sp,48
    80004fc8:	8082                	ret
  return -1;
    80004fca:	557d                	li	a0,-1
    80004fcc:	b7fd                	j	80004fba <pipealloc+0xc6>

0000000080004fce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fce:	1101                	add	sp,sp,-32
    80004fd0:	ec06                	sd	ra,24(sp)
    80004fd2:	e822                	sd	s0,16(sp)
    80004fd4:	e426                	sd	s1,8(sp)
    80004fd6:	e04a                	sd	s2,0(sp)
    80004fd8:	1000                	add	s0,sp,32
    80004fda:	84aa                	mv	s1,a0
    80004fdc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	bf4080e7          	jalr	-1036(ra) # 80000bd2 <acquire>
  if(writable){
    80004fe6:	02090d63          	beqz	s2,80005020 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fee:	21848513          	add	a0,s1,536
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	360080e7          	jalr	864(ra) # 80002352 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ffa:	2204b783          	ld	a5,544(s1)
    80004ffe:	eb95                	bnez	a5,80005032 <pipeclose+0x64>
    release(&pi->lock);
    80005000:	8526                	mv	a0,s1
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c84080e7          	jalr	-892(ra) # 80000c86 <release>
    kfree((char*)pi);
    8000500a:	8526                	mv	a0,s1
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	9d8080e7          	jalr	-1576(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80005014:	60e2                	ld	ra,24(sp)
    80005016:	6442                	ld	s0,16(sp)
    80005018:	64a2                	ld	s1,8(sp)
    8000501a:	6902                	ld	s2,0(sp)
    8000501c:	6105                	add	sp,sp,32
    8000501e:	8082                	ret
    pi->readopen = 0;
    80005020:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005024:	21c48513          	add	a0,s1,540
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	32a080e7          	jalr	810(ra) # 80002352 <wakeup>
    80005030:	b7e9                	j	80004ffa <pipeclose+0x2c>
    release(&pi->lock);
    80005032:	8526                	mv	a0,s1
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	c52080e7          	jalr	-942(ra) # 80000c86 <release>
}
    8000503c:	bfe1                	j	80005014 <pipeclose+0x46>

000000008000503e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000503e:	711d                	add	sp,sp,-96
    80005040:	ec86                	sd	ra,88(sp)
    80005042:	e8a2                	sd	s0,80(sp)
    80005044:	e4a6                	sd	s1,72(sp)
    80005046:	e0ca                	sd	s2,64(sp)
    80005048:	fc4e                	sd	s3,56(sp)
    8000504a:	f852                	sd	s4,48(sp)
    8000504c:	f456                	sd	s5,40(sp)
    8000504e:	f05a                	sd	s6,32(sp)
    80005050:	ec5e                	sd	s7,24(sp)
    80005052:	e862                	sd	s8,16(sp)
    80005054:	1080                	add	s0,sp,96
    80005056:	84aa                	mv	s1,a0
    80005058:	8aae                	mv	s5,a1
    8000505a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000505c:	ffffd097          	auipc	ra,0xffffd
    80005060:	9a2080e7          	jalr	-1630(ra) # 800019fe <myproc>
    80005064:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	b6a080e7          	jalr	-1174(ra) # 80000bd2 <acquire>
  while(i < n){
    80005070:	0b405663          	blez	s4,8000511c <pipewrite+0xde>
  int i = 0;
    80005074:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005076:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005078:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000507c:	21c48b93          	add	s7,s1,540
    80005080:	a089                	j	800050c2 <pipewrite+0x84>
      release(&pi->lock);
    80005082:	8526                	mv	a0,s1
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	c02080e7          	jalr	-1022(ra) # 80000c86 <release>
      return -1;
    8000508c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000508e:	854a                	mv	a0,s2
    80005090:	60e6                	ld	ra,88(sp)
    80005092:	6446                	ld	s0,80(sp)
    80005094:	64a6                	ld	s1,72(sp)
    80005096:	6906                	ld	s2,64(sp)
    80005098:	79e2                	ld	s3,56(sp)
    8000509a:	7a42                	ld	s4,48(sp)
    8000509c:	7aa2                	ld	s5,40(sp)
    8000509e:	7b02                	ld	s6,32(sp)
    800050a0:	6be2                	ld	s7,24(sp)
    800050a2:	6c42                	ld	s8,16(sp)
    800050a4:	6125                	add	sp,sp,96
    800050a6:	8082                	ret
      wakeup(&pi->nread);
    800050a8:	8562                	mv	a0,s8
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	2a8080e7          	jalr	680(ra) # 80002352 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050b2:	85a6                	mv	a1,s1
    800050b4:	855e                	mv	a0,s7
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	238080e7          	jalr	568(ra) # 800022ee <sleep>
  while(i < n){
    800050be:	07495063          	bge	s2,s4,8000511e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800050c2:	2204a783          	lw	a5,544(s1)
    800050c6:	dfd5                	beqz	a5,80005082 <pipewrite+0x44>
    800050c8:	854e                	mv	a0,s3
    800050ca:	ffffd097          	auipc	ra,0xffffd
    800050ce:	50a080e7          	jalr	1290(ra) # 800025d4 <killed>
    800050d2:	f945                	bnez	a0,80005082 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050d4:	2184a783          	lw	a5,536(s1)
    800050d8:	21c4a703          	lw	a4,540(s1)
    800050dc:	2007879b          	addw	a5,a5,512
    800050e0:	fcf704e3          	beq	a4,a5,800050a8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050e4:	4685                	li	a3,1
    800050e6:	01590633          	add	a2,s2,s5
    800050ea:	faf40593          	add	a1,s0,-81
    800050ee:	0509b503          	ld	a0,80(s3)
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	600080e7          	jalr	1536(ra) # 800016f2 <copyin>
    800050fa:	03650263          	beq	a0,s6,8000511e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050fe:	21c4a783          	lw	a5,540(s1)
    80005102:	0017871b          	addw	a4,a5,1
    80005106:	20e4ae23          	sw	a4,540(s1)
    8000510a:	1ff7f793          	and	a5,a5,511
    8000510e:	97a6                	add	a5,a5,s1
    80005110:	faf44703          	lbu	a4,-81(s0)
    80005114:	00e78c23          	sb	a4,24(a5)
      i++;
    80005118:	2905                	addw	s2,s2,1
    8000511a:	b755                	j	800050be <pipewrite+0x80>
  int i = 0;
    8000511c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000511e:	21848513          	add	a0,s1,536
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	230080e7          	jalr	560(ra) # 80002352 <wakeup>
  release(&pi->lock);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	b5a080e7          	jalr	-1190(ra) # 80000c86 <release>
  return i;
    80005134:	bfa9                	j	8000508e <pipewrite+0x50>

0000000080005136 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005136:	715d                	add	sp,sp,-80
    80005138:	e486                	sd	ra,72(sp)
    8000513a:	e0a2                	sd	s0,64(sp)
    8000513c:	fc26                	sd	s1,56(sp)
    8000513e:	f84a                	sd	s2,48(sp)
    80005140:	f44e                	sd	s3,40(sp)
    80005142:	f052                	sd	s4,32(sp)
    80005144:	ec56                	sd	s5,24(sp)
    80005146:	e85a                	sd	s6,16(sp)
    80005148:	0880                	add	s0,sp,80
    8000514a:	84aa                	mv	s1,a0
    8000514c:	892e                	mv	s2,a1
    8000514e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	8ae080e7          	jalr	-1874(ra) # 800019fe <myproc>
    80005158:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000515a:	8526                	mv	a0,s1
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	a76080e7          	jalr	-1418(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005164:	2184a703          	lw	a4,536(s1)
    80005168:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000516c:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005170:	02f71763          	bne	a4,a5,8000519e <piperead+0x68>
    80005174:	2244a783          	lw	a5,548(s1)
    80005178:	c39d                	beqz	a5,8000519e <piperead+0x68>
    if(killed(pr)){
    8000517a:	8552                	mv	a0,s4
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	458080e7          	jalr	1112(ra) # 800025d4 <killed>
    80005184:	e949                	bnez	a0,80005216 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005186:	85a6                	mv	a1,s1
    80005188:	854e                	mv	a0,s3
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	164080e7          	jalr	356(ra) # 800022ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005192:	2184a703          	lw	a4,536(s1)
    80005196:	21c4a783          	lw	a5,540(s1)
    8000519a:	fcf70de3          	beq	a4,a5,80005174 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000519e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051a0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a2:	05505463          	blez	s5,800051ea <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800051a6:	2184a783          	lw	a5,536(s1)
    800051aa:	21c4a703          	lw	a4,540(s1)
    800051ae:	02f70e63          	beq	a4,a5,800051ea <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051b2:	0017871b          	addw	a4,a5,1
    800051b6:	20e4ac23          	sw	a4,536(s1)
    800051ba:	1ff7f793          	and	a5,a5,511
    800051be:	97a6                	add	a5,a5,s1
    800051c0:	0187c783          	lbu	a5,24(a5)
    800051c4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051c8:	4685                	li	a3,1
    800051ca:	fbf40613          	add	a2,s0,-65
    800051ce:	85ca                	mv	a1,s2
    800051d0:	050a3503          	ld	a0,80(s4)
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	492080e7          	jalr	1170(ra) # 80001666 <copyout>
    800051dc:	01650763          	beq	a0,s6,800051ea <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051e0:	2985                	addw	s3,s3,1
    800051e2:	0905                	add	s2,s2,1
    800051e4:	fd3a91e3          	bne	s5,s3,800051a6 <piperead+0x70>
    800051e8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051ea:	21c48513          	add	a0,s1,540
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	164080e7          	jalr	356(ra) # 80002352 <wakeup>
  release(&pi->lock);
    800051f6:	8526                	mv	a0,s1
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	a8e080e7          	jalr	-1394(ra) # 80000c86 <release>
  return i;
}
    80005200:	854e                	mv	a0,s3
    80005202:	60a6                	ld	ra,72(sp)
    80005204:	6406                	ld	s0,64(sp)
    80005206:	74e2                	ld	s1,56(sp)
    80005208:	7942                	ld	s2,48(sp)
    8000520a:	79a2                	ld	s3,40(sp)
    8000520c:	7a02                	ld	s4,32(sp)
    8000520e:	6ae2                	ld	s5,24(sp)
    80005210:	6b42                	ld	s6,16(sp)
    80005212:	6161                	add	sp,sp,80
    80005214:	8082                	ret
      release(&pi->lock);
    80005216:	8526                	mv	a0,s1
    80005218:	ffffc097          	auipc	ra,0xffffc
    8000521c:	a6e080e7          	jalr	-1426(ra) # 80000c86 <release>
      return -1;
    80005220:	59fd                	li	s3,-1
    80005222:	bff9                	j	80005200 <piperead+0xca>

0000000080005224 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005224:	1141                	add	sp,sp,-16
    80005226:	e422                	sd	s0,8(sp)
    80005228:	0800                	add	s0,sp,16
    8000522a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000522c:	8905                	and	a0,a0,1
    8000522e:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005230:	8b89                	and	a5,a5,2
    80005232:	c399                	beqz	a5,80005238 <flags2perm+0x14>
      perm |= PTE_W;
    80005234:	00456513          	or	a0,a0,4
    return perm;
}
    80005238:	6422                	ld	s0,8(sp)
    8000523a:	0141                	add	sp,sp,16
    8000523c:	8082                	ret

000000008000523e <exec>:

int
exec(char *path, char **argv)
{
    8000523e:	df010113          	add	sp,sp,-528
    80005242:	20113423          	sd	ra,520(sp)
    80005246:	20813023          	sd	s0,512(sp)
    8000524a:	ffa6                	sd	s1,504(sp)
    8000524c:	fbca                	sd	s2,496(sp)
    8000524e:	f7ce                	sd	s3,488(sp)
    80005250:	f3d2                	sd	s4,480(sp)
    80005252:	efd6                	sd	s5,472(sp)
    80005254:	ebda                	sd	s6,464(sp)
    80005256:	e7de                	sd	s7,456(sp)
    80005258:	e3e2                	sd	s8,448(sp)
    8000525a:	ff66                	sd	s9,440(sp)
    8000525c:	fb6a                	sd	s10,432(sp)
    8000525e:	f76e                	sd	s11,424(sp)
    80005260:	0c00                	add	s0,sp,528
    80005262:	892a                	mv	s2,a0
    80005264:	dea43c23          	sd	a0,-520(s0)
    80005268:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000526c:	ffffc097          	auipc	ra,0xffffc
    80005270:	792080e7          	jalr	1938(ra) # 800019fe <myproc>
    80005274:	84aa                	mv	s1,a0

  begin_op();
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	48e080e7          	jalr	1166(ra) # 80004704 <begin_op>

  if((ip = namei(path)) == 0){
    8000527e:	854a                	mv	a0,s2
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	284080e7          	jalr	644(ra) # 80004504 <namei>
    80005288:	c92d                	beqz	a0,800052fa <exec+0xbc>
    8000528a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	ad2080e7          	jalr	-1326(ra) # 80003d5e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005294:	04000713          	li	a4,64
    80005298:	4681                	li	a3,0
    8000529a:	e5040613          	add	a2,s0,-432
    8000529e:	4581                	li	a1,0
    800052a0:	8552                	mv	a0,s4
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	d70080e7          	jalr	-656(ra) # 80004012 <readi>
    800052aa:	04000793          	li	a5,64
    800052ae:	00f51a63          	bne	a0,a5,800052c2 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052b2:	e5042703          	lw	a4,-432(s0)
    800052b6:	464c47b7          	lui	a5,0x464c4
    800052ba:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052be:	04f70463          	beq	a4,a5,80005306 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052c2:	8552                	mv	a0,s4
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	cfc080e7          	jalr	-772(ra) # 80003fc0 <iunlockput>
    end_op();
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	4b2080e7          	jalr	1202(ra) # 8000477e <end_op>
  }
  return -1;
    800052d4:	557d                	li	a0,-1
}
    800052d6:	20813083          	ld	ra,520(sp)
    800052da:	20013403          	ld	s0,512(sp)
    800052de:	74fe                	ld	s1,504(sp)
    800052e0:	795e                	ld	s2,496(sp)
    800052e2:	79be                	ld	s3,488(sp)
    800052e4:	7a1e                	ld	s4,480(sp)
    800052e6:	6afe                	ld	s5,472(sp)
    800052e8:	6b5e                	ld	s6,464(sp)
    800052ea:	6bbe                	ld	s7,456(sp)
    800052ec:	6c1e                	ld	s8,448(sp)
    800052ee:	7cfa                	ld	s9,440(sp)
    800052f0:	7d5a                	ld	s10,432(sp)
    800052f2:	7dba                	ld	s11,424(sp)
    800052f4:	21010113          	add	sp,sp,528
    800052f8:	8082                	ret
    end_op();
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	484080e7          	jalr	1156(ra) # 8000477e <end_op>
    return -1;
    80005302:	557d                	li	a0,-1
    80005304:	bfc9                	j	800052d6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005306:	8526                	mv	a0,s1
    80005308:	ffffc097          	auipc	ra,0xffffc
    8000530c:	7ba080e7          	jalr	1978(ra) # 80001ac2 <proc_pagetable>
    80005310:	8b2a                	mv	s6,a0
    80005312:	d945                	beqz	a0,800052c2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005314:	e7042d03          	lw	s10,-400(s0)
    80005318:	e8845783          	lhu	a5,-376(s0)
    8000531c:	10078463          	beqz	a5,80005424 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005320:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005322:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005324:	6c85                	lui	s9,0x1
    80005326:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000532a:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000532e:	6a85                	lui	s5,0x1
    80005330:	a0b5                	j	8000539c <exec+0x15e>
      panic("loadseg: address should exist");
    80005332:	00003517          	auipc	a0,0x3
    80005336:	3e650513          	add	a0,a0,998 # 80008718 <syscalls+0x2a0>
    8000533a:	ffffb097          	auipc	ra,0xffffb
    8000533e:	202080e7          	jalr	514(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005342:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005344:	8726                	mv	a4,s1
    80005346:	012c06bb          	addw	a3,s8,s2
    8000534a:	4581                	li	a1,0
    8000534c:	8552                	mv	a0,s4
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	cc4080e7          	jalr	-828(ra) # 80004012 <readi>
    80005356:	2501                	sext.w	a0,a0
    80005358:	24a49863          	bne	s1,a0,800055a8 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000535c:	012a893b          	addw	s2,s5,s2
    80005360:	03397563          	bgeu	s2,s3,8000538a <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005364:	02091593          	sll	a1,s2,0x20
    80005368:	9181                	srl	a1,a1,0x20
    8000536a:	95de                	add	a1,a1,s7
    8000536c:	855a                	mv	a0,s6
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	ce8080e7          	jalr	-792(ra) # 80001056 <walkaddr>
    80005376:	862a                	mv	a2,a0
    if(pa == 0)
    80005378:	dd4d                	beqz	a0,80005332 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000537a:	412984bb          	subw	s1,s3,s2
    8000537e:	0004879b          	sext.w	a5,s1
    80005382:	fcfcf0e3          	bgeu	s9,a5,80005342 <exec+0x104>
    80005386:	84d6                	mv	s1,s5
    80005388:	bf6d                	j	80005342 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000538a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000538e:	2d85                	addw	s11,s11,1
    80005390:	038d0d1b          	addw	s10,s10,56
    80005394:	e8845783          	lhu	a5,-376(s0)
    80005398:	08fdd763          	bge	s11,a5,80005426 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000539c:	2d01                	sext.w	s10,s10
    8000539e:	03800713          	li	a4,56
    800053a2:	86ea                	mv	a3,s10
    800053a4:	e1840613          	add	a2,s0,-488
    800053a8:	4581                	li	a1,0
    800053aa:	8552                	mv	a0,s4
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	c66080e7          	jalr	-922(ra) # 80004012 <readi>
    800053b4:	03800793          	li	a5,56
    800053b8:	1ef51663          	bne	a0,a5,800055a4 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800053bc:	e1842783          	lw	a5,-488(s0)
    800053c0:	4705                	li	a4,1
    800053c2:	fce796e3          	bne	a5,a4,8000538e <exec+0x150>
    if(ph.memsz < ph.filesz)
    800053c6:	e4043483          	ld	s1,-448(s0)
    800053ca:	e3843783          	ld	a5,-456(s0)
    800053ce:	1ef4e863          	bltu	s1,a5,800055be <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053d2:	e2843783          	ld	a5,-472(s0)
    800053d6:	94be                	add	s1,s1,a5
    800053d8:	1ef4e663          	bltu	s1,a5,800055c4 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800053dc:	df043703          	ld	a4,-528(s0)
    800053e0:	8ff9                	and	a5,a5,a4
    800053e2:	1e079463          	bnez	a5,800055ca <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053e6:	e1c42503          	lw	a0,-484(s0)
    800053ea:	00000097          	auipc	ra,0x0
    800053ee:	e3a080e7          	jalr	-454(ra) # 80005224 <flags2perm>
    800053f2:	86aa                	mv	a3,a0
    800053f4:	8626                	mv	a2,s1
    800053f6:	85ca                	mv	a1,s2
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	010080e7          	jalr	16(ra) # 8000140a <uvmalloc>
    80005402:	e0a43423          	sd	a0,-504(s0)
    80005406:	1c050563          	beqz	a0,800055d0 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000540a:	e2843b83          	ld	s7,-472(s0)
    8000540e:	e2042c03          	lw	s8,-480(s0)
    80005412:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005416:	00098463          	beqz	s3,8000541e <exec+0x1e0>
    8000541a:	4901                	li	s2,0
    8000541c:	b7a1                	j	80005364 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000541e:	e0843903          	ld	s2,-504(s0)
    80005422:	b7b5                	j	8000538e <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005424:	4901                	li	s2,0
  iunlockput(ip);
    80005426:	8552                	mv	a0,s4
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	b98080e7          	jalr	-1128(ra) # 80003fc0 <iunlockput>
  end_op();
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	34e080e7          	jalr	846(ra) # 8000477e <end_op>
  p = myproc();
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	5c6080e7          	jalr	1478(ra) # 800019fe <myproc>
    80005440:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005442:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005446:	6985                	lui	s3,0x1
    80005448:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000544a:	99ca                	add	s3,s3,s2
    8000544c:	77fd                	lui	a5,0xfffff
    8000544e:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005452:	4691                	li	a3,4
    80005454:	6609                	lui	a2,0x2
    80005456:	964e                	add	a2,a2,s3
    80005458:	85ce                	mv	a1,s3
    8000545a:	855a                	mv	a0,s6
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	fae080e7          	jalr	-82(ra) # 8000140a <uvmalloc>
    80005464:	892a                	mv	s2,a0
    80005466:	e0a43423          	sd	a0,-504(s0)
    8000546a:	e509                	bnez	a0,80005474 <exec+0x236>
  if(pagetable)
    8000546c:	e1343423          	sd	s3,-504(s0)
    80005470:	4a01                	li	s4,0
    80005472:	aa1d                	j	800055a8 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005474:	75f9                	lui	a1,0xffffe
    80005476:	95aa                	add	a1,a1,a0
    80005478:	855a                	mv	a0,s6
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	1ba080e7          	jalr	442(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005482:	7bfd                	lui	s7,0xfffff
    80005484:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005486:	e0043783          	ld	a5,-512(s0)
    8000548a:	6388                	ld	a0,0(a5)
    8000548c:	c52d                	beqz	a0,800054f6 <exec+0x2b8>
    8000548e:	e9040993          	add	s3,s0,-368
    80005492:	f9040c13          	add	s8,s0,-112
    80005496:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005498:	ffffc097          	auipc	ra,0xffffc
    8000549c:	9b0080e7          	jalr	-1616(ra) # 80000e48 <strlen>
    800054a0:	0015079b          	addw	a5,a0,1
    800054a4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054a8:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800054ac:	13796563          	bltu	s2,s7,800055d6 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054b0:	e0043d03          	ld	s10,-512(s0)
    800054b4:	000d3a03          	ld	s4,0(s10)
    800054b8:	8552                	mv	a0,s4
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	98e080e7          	jalr	-1650(ra) # 80000e48 <strlen>
    800054c2:	0015069b          	addw	a3,a0,1
    800054c6:	8652                	mv	a2,s4
    800054c8:	85ca                	mv	a1,s2
    800054ca:	855a                	mv	a0,s6
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	19a080e7          	jalr	410(ra) # 80001666 <copyout>
    800054d4:	10054363          	bltz	a0,800055da <exec+0x39c>
    ustack[argc] = sp;
    800054d8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054dc:	0485                	add	s1,s1,1
    800054de:	008d0793          	add	a5,s10,8
    800054e2:	e0f43023          	sd	a5,-512(s0)
    800054e6:	008d3503          	ld	a0,8(s10)
    800054ea:	c909                	beqz	a0,800054fc <exec+0x2be>
    if(argc >= MAXARG)
    800054ec:	09a1                	add	s3,s3,8
    800054ee:	fb8995e3          	bne	s3,s8,80005498 <exec+0x25a>
  ip = 0;
    800054f2:	4a01                	li	s4,0
    800054f4:	a855                	j	800055a8 <exec+0x36a>
  sp = sz;
    800054f6:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800054fa:	4481                	li	s1,0
  ustack[argc] = 0;
    800054fc:	00349793          	sll	a5,s1,0x3
    80005500:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdb9c0>
    80005504:	97a2                	add	a5,a5,s0
    80005506:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000550a:	00148693          	add	a3,s1,1
    8000550e:	068e                	sll	a3,a3,0x3
    80005510:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005514:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005518:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000551c:	f57968e3          	bltu	s2,s7,8000546c <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005520:	e9040613          	add	a2,s0,-368
    80005524:	85ca                	mv	a1,s2
    80005526:	855a                	mv	a0,s6
    80005528:	ffffc097          	auipc	ra,0xffffc
    8000552c:	13e080e7          	jalr	318(ra) # 80001666 <copyout>
    80005530:	0a054763          	bltz	a0,800055de <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005534:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005538:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000553c:	df843783          	ld	a5,-520(s0)
    80005540:	0007c703          	lbu	a4,0(a5)
    80005544:	cf11                	beqz	a4,80005560 <exec+0x322>
    80005546:	0785                	add	a5,a5,1
    if(*s == '/')
    80005548:	02f00693          	li	a3,47
    8000554c:	a039                	j	8000555a <exec+0x31c>
      last = s+1;
    8000554e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005552:	0785                	add	a5,a5,1
    80005554:	fff7c703          	lbu	a4,-1(a5)
    80005558:	c701                	beqz	a4,80005560 <exec+0x322>
    if(*s == '/')
    8000555a:	fed71ce3          	bne	a4,a3,80005552 <exec+0x314>
    8000555e:	bfc5                	j	8000554e <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005560:	4641                	li	a2,16
    80005562:	df843583          	ld	a1,-520(s0)
    80005566:	158a8513          	add	a0,s5,344
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	8ac080e7          	jalr	-1876(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005572:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005576:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000557a:	e0843783          	ld	a5,-504(s0)
    8000557e:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005582:	058ab783          	ld	a5,88(s5)
    80005586:	e6843703          	ld	a4,-408(s0)
    8000558a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000558c:	058ab783          	ld	a5,88(s5)
    80005590:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005594:	85e6                	mv	a1,s9
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	5c8080e7          	jalr	1480(ra) # 80001b5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000559e:	0004851b          	sext.w	a0,s1
    800055a2:	bb15                	j	800052d6 <exec+0x98>
    800055a4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055a8:	e0843583          	ld	a1,-504(s0)
    800055ac:	855a                	mv	a0,s6
    800055ae:	ffffc097          	auipc	ra,0xffffc
    800055b2:	5b0080e7          	jalr	1456(ra) # 80001b5e <proc_freepagetable>
  return -1;
    800055b6:	557d                	li	a0,-1
  if(ip){
    800055b8:	d00a0fe3          	beqz	s4,800052d6 <exec+0x98>
    800055bc:	b319                	j	800052c2 <exec+0x84>
    800055be:	e1243423          	sd	s2,-504(s0)
    800055c2:	b7dd                	j	800055a8 <exec+0x36a>
    800055c4:	e1243423          	sd	s2,-504(s0)
    800055c8:	b7c5                	j	800055a8 <exec+0x36a>
    800055ca:	e1243423          	sd	s2,-504(s0)
    800055ce:	bfe9                	j	800055a8 <exec+0x36a>
    800055d0:	e1243423          	sd	s2,-504(s0)
    800055d4:	bfd1                	j	800055a8 <exec+0x36a>
  ip = 0;
    800055d6:	4a01                	li	s4,0
    800055d8:	bfc1                	j	800055a8 <exec+0x36a>
    800055da:	4a01                	li	s4,0
  if(pagetable)
    800055dc:	b7f1                	j	800055a8 <exec+0x36a>
  sz = sz1;
    800055de:	e0843983          	ld	s3,-504(s0)
    800055e2:	b569                	j	8000546c <exec+0x22e>

00000000800055e4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055e4:	7179                	add	sp,sp,-48
    800055e6:	f406                	sd	ra,40(sp)
    800055e8:	f022                	sd	s0,32(sp)
    800055ea:	ec26                	sd	s1,24(sp)
    800055ec:	e84a                	sd	s2,16(sp)
    800055ee:	1800                	add	s0,sp,48
    800055f0:	892e                	mv	s2,a1
    800055f2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055f4:	fdc40593          	add	a1,s0,-36
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	ab4080e7          	jalr	-1356(ra) # 800030ac <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005600:	fdc42703          	lw	a4,-36(s0)
    80005604:	47bd                	li	a5,15
    80005606:	02e7eb63          	bltu	a5,a4,8000563c <argfd+0x58>
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	3f4080e7          	jalr	1012(ra) # 800019fe <myproc>
    80005612:	fdc42703          	lw	a4,-36(s0)
    80005616:	01a70793          	add	a5,a4,26
    8000561a:	078e                	sll	a5,a5,0x3
    8000561c:	953e                	add	a0,a0,a5
    8000561e:	611c                	ld	a5,0(a0)
    80005620:	c385                	beqz	a5,80005640 <argfd+0x5c>
    return -1;
  if(pfd)
    80005622:	00090463          	beqz	s2,8000562a <argfd+0x46>
    *pfd = fd;
    80005626:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000562a:	4501                	li	a0,0
  if(pf)
    8000562c:	c091                	beqz	s1,80005630 <argfd+0x4c>
    *pf = f;
    8000562e:	e09c                	sd	a5,0(s1)
}
    80005630:	70a2                	ld	ra,40(sp)
    80005632:	7402                	ld	s0,32(sp)
    80005634:	64e2                	ld	s1,24(sp)
    80005636:	6942                	ld	s2,16(sp)
    80005638:	6145                	add	sp,sp,48
    8000563a:	8082                	ret
    return -1;
    8000563c:	557d                	li	a0,-1
    8000563e:	bfcd                	j	80005630 <argfd+0x4c>
    80005640:	557d                	li	a0,-1
    80005642:	b7fd                	j	80005630 <argfd+0x4c>

0000000080005644 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005644:	1101                	add	sp,sp,-32
    80005646:	ec06                	sd	ra,24(sp)
    80005648:	e822                	sd	s0,16(sp)
    8000564a:	e426                	sd	s1,8(sp)
    8000564c:	1000                	add	s0,sp,32
    8000564e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005650:	ffffc097          	auipc	ra,0xffffc
    80005654:	3ae080e7          	jalr	942(ra) # 800019fe <myproc>
    80005658:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000565a:	0d050793          	add	a5,a0,208
    8000565e:	4501                	li	a0,0
    80005660:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005662:	6398                	ld	a4,0(a5)
    80005664:	cb19                	beqz	a4,8000567a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005666:	2505                	addw	a0,a0,1
    80005668:	07a1                	add	a5,a5,8
    8000566a:	fed51ce3          	bne	a0,a3,80005662 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000566e:	557d                	li	a0,-1
}
    80005670:	60e2                	ld	ra,24(sp)
    80005672:	6442                	ld	s0,16(sp)
    80005674:	64a2                	ld	s1,8(sp)
    80005676:	6105                	add	sp,sp,32
    80005678:	8082                	ret
      p->ofile[fd] = f;
    8000567a:	01a50793          	add	a5,a0,26
    8000567e:	078e                	sll	a5,a5,0x3
    80005680:	963e                	add	a2,a2,a5
    80005682:	e204                	sd	s1,0(a2)
      return fd;
    80005684:	b7f5                	j	80005670 <fdalloc+0x2c>

0000000080005686 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005686:	715d                	add	sp,sp,-80
    80005688:	e486                	sd	ra,72(sp)
    8000568a:	e0a2                	sd	s0,64(sp)
    8000568c:	fc26                	sd	s1,56(sp)
    8000568e:	f84a                	sd	s2,48(sp)
    80005690:	f44e                	sd	s3,40(sp)
    80005692:	f052                	sd	s4,32(sp)
    80005694:	ec56                	sd	s5,24(sp)
    80005696:	e85a                	sd	s6,16(sp)
    80005698:	0880                	add	s0,sp,80
    8000569a:	8b2e                	mv	s6,a1
    8000569c:	89b2                	mv	s3,a2
    8000569e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056a0:	fb040593          	add	a1,s0,-80
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	e7e080e7          	jalr	-386(ra) # 80004522 <nameiparent>
    800056ac:	84aa                	mv	s1,a0
    800056ae:	14050b63          	beqz	a0,80005804 <create+0x17e>
    return 0;

  ilock(dp);
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	6ac080e7          	jalr	1708(ra) # 80003d5e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056ba:	4601                	li	a2,0
    800056bc:	fb040593          	add	a1,s0,-80
    800056c0:	8526                	mv	a0,s1
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	b80080e7          	jalr	-1152(ra) # 80004242 <dirlookup>
    800056ca:	8aaa                	mv	s5,a0
    800056cc:	c921                	beqz	a0,8000571c <create+0x96>
    iunlockput(dp);
    800056ce:	8526                	mv	a0,s1
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	8f0080e7          	jalr	-1808(ra) # 80003fc0 <iunlockput>
    ilock(ip);
    800056d8:	8556                	mv	a0,s5
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	684080e7          	jalr	1668(ra) # 80003d5e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056e2:	4789                	li	a5,2
    800056e4:	02fb1563          	bne	s6,a5,8000570e <create+0x88>
    800056e8:	044ad783          	lhu	a5,68(s5)
    800056ec:	37f9                	addw	a5,a5,-2
    800056ee:	17c2                	sll	a5,a5,0x30
    800056f0:	93c1                	srl	a5,a5,0x30
    800056f2:	4705                	li	a4,1
    800056f4:	00f76d63          	bltu	a4,a5,8000570e <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056f8:	8556                	mv	a0,s5
    800056fa:	60a6                	ld	ra,72(sp)
    800056fc:	6406                	ld	s0,64(sp)
    800056fe:	74e2                	ld	s1,56(sp)
    80005700:	7942                	ld	s2,48(sp)
    80005702:	79a2                	ld	s3,40(sp)
    80005704:	7a02                	ld	s4,32(sp)
    80005706:	6ae2                	ld	s5,24(sp)
    80005708:	6b42                	ld	s6,16(sp)
    8000570a:	6161                	add	sp,sp,80
    8000570c:	8082                	ret
    iunlockput(ip);
    8000570e:	8556                	mv	a0,s5
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	8b0080e7          	jalr	-1872(ra) # 80003fc0 <iunlockput>
    return 0;
    80005718:	4a81                	li	s5,0
    8000571a:	bff9                	j	800056f8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000571c:	85da                	mv	a1,s6
    8000571e:	4088                	lw	a0,0(s1)
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	4a6080e7          	jalr	1190(ra) # 80003bc6 <ialloc>
    80005728:	8a2a                	mv	s4,a0
    8000572a:	c529                	beqz	a0,80005774 <create+0xee>
  ilock(ip);
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	632080e7          	jalr	1586(ra) # 80003d5e <ilock>
  ip->major = major;
    80005734:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005738:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000573c:	4905                	li	s2,1
    8000573e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005742:	8552                	mv	a0,s4
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	54e080e7          	jalr	1358(ra) # 80003c92 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000574c:	032b0b63          	beq	s6,s2,80005782 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005750:	004a2603          	lw	a2,4(s4)
    80005754:	fb040593          	add	a1,s0,-80
    80005758:	8526                	mv	a0,s1
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	cf8080e7          	jalr	-776(ra) # 80004452 <dirlink>
    80005762:	06054f63          	bltz	a0,800057e0 <create+0x15a>
  iunlockput(dp);
    80005766:	8526                	mv	a0,s1
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	858080e7          	jalr	-1960(ra) # 80003fc0 <iunlockput>
  return ip;
    80005770:	8ad2                	mv	s5,s4
    80005772:	b759                	j	800056f8 <create+0x72>
    iunlockput(dp);
    80005774:	8526                	mv	a0,s1
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	84a080e7          	jalr	-1974(ra) # 80003fc0 <iunlockput>
    return 0;
    8000577e:	8ad2                	mv	s5,s4
    80005780:	bfa5                	j	800056f8 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005782:	004a2603          	lw	a2,4(s4)
    80005786:	00003597          	auipc	a1,0x3
    8000578a:	fb258593          	add	a1,a1,-78 # 80008738 <syscalls+0x2c0>
    8000578e:	8552                	mv	a0,s4
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	cc2080e7          	jalr	-830(ra) # 80004452 <dirlink>
    80005798:	04054463          	bltz	a0,800057e0 <create+0x15a>
    8000579c:	40d0                	lw	a2,4(s1)
    8000579e:	00003597          	auipc	a1,0x3
    800057a2:	fa258593          	add	a1,a1,-94 # 80008740 <syscalls+0x2c8>
    800057a6:	8552                	mv	a0,s4
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	caa080e7          	jalr	-854(ra) # 80004452 <dirlink>
    800057b0:	02054863          	bltz	a0,800057e0 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800057b4:	004a2603          	lw	a2,4(s4)
    800057b8:	fb040593          	add	a1,s0,-80
    800057bc:	8526                	mv	a0,s1
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	c94080e7          	jalr	-876(ra) # 80004452 <dirlink>
    800057c6:	00054d63          	bltz	a0,800057e0 <create+0x15a>
    dp->nlink++;  // for ".."
    800057ca:	04a4d783          	lhu	a5,74(s1)
    800057ce:	2785                	addw	a5,a5,1
    800057d0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	4bc080e7          	jalr	1212(ra) # 80003c92 <iupdate>
    800057de:	b761                	j	80005766 <create+0xe0>
  ip->nlink = 0;
    800057e0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057e4:	8552                	mv	a0,s4
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	4ac080e7          	jalr	1196(ra) # 80003c92 <iupdate>
  iunlockput(ip);
    800057ee:	8552                	mv	a0,s4
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	7d0080e7          	jalr	2000(ra) # 80003fc0 <iunlockput>
  iunlockput(dp);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	7c6080e7          	jalr	1990(ra) # 80003fc0 <iunlockput>
  return 0;
    80005802:	bddd                	j	800056f8 <create+0x72>
    return 0;
    80005804:	8aaa                	mv	s5,a0
    80005806:	bdcd                	j	800056f8 <create+0x72>

0000000080005808 <sys_dup>:
{
    80005808:	7179                	add	sp,sp,-48
    8000580a:	f406                	sd	ra,40(sp)
    8000580c:	f022                	sd	s0,32(sp)
    8000580e:	ec26                	sd	s1,24(sp)
    80005810:	e84a                	sd	s2,16(sp)
    80005812:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005814:	fd840613          	add	a2,s0,-40
    80005818:	4581                	li	a1,0
    8000581a:	4501                	li	a0,0
    8000581c:	00000097          	auipc	ra,0x0
    80005820:	dc8080e7          	jalr	-568(ra) # 800055e4 <argfd>
    return -1;
    80005824:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005826:	02054363          	bltz	a0,8000584c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000582a:	fd843903          	ld	s2,-40(s0)
    8000582e:	854a                	mv	a0,s2
    80005830:	00000097          	auipc	ra,0x0
    80005834:	e14080e7          	jalr	-492(ra) # 80005644 <fdalloc>
    80005838:	84aa                	mv	s1,a0
    return -1;
    8000583a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000583c:	00054863          	bltz	a0,8000584c <sys_dup+0x44>
  filedup(f);
    80005840:	854a                	mv	a0,s2
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	334080e7          	jalr	820(ra) # 80004b76 <filedup>
  return fd;
    8000584a:	87a6                	mv	a5,s1
}
    8000584c:	853e                	mv	a0,a5
    8000584e:	70a2                	ld	ra,40(sp)
    80005850:	7402                	ld	s0,32(sp)
    80005852:	64e2                	ld	s1,24(sp)
    80005854:	6942                	ld	s2,16(sp)
    80005856:	6145                	add	sp,sp,48
    80005858:	8082                	ret

000000008000585a <sys_read>:
{
    8000585a:	7179                	add	sp,sp,-48
    8000585c:	f406                	sd	ra,40(sp)
    8000585e:	f022                	sd	s0,32(sp)
    80005860:	1800                	add	s0,sp,48
  read_counter++;
    80005862:	00003717          	auipc	a4,0x3
    80005866:	09a70713          	add	a4,a4,154 # 800088fc <read_counter>
    8000586a:	431c                	lw	a5,0(a4)
    8000586c:	2785                	addw	a5,a5,1
    8000586e:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005870:	fd840593          	add	a1,s0,-40
    80005874:	4505                	li	a0,1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	856080e7          	jalr	-1962(ra) # 800030cc <argaddr>
  argint(2, &n);
    8000587e:	fe440593          	add	a1,s0,-28
    80005882:	4509                	li	a0,2
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	828080e7          	jalr	-2008(ra) # 800030ac <argint>
  if(argfd(0, 0, &f) < 0)
    8000588c:	fe840613          	add	a2,s0,-24
    80005890:	4581                	li	a1,0
    80005892:	4501                	li	a0,0
    80005894:	00000097          	auipc	ra,0x0
    80005898:	d50080e7          	jalr	-688(ra) # 800055e4 <argfd>
    8000589c:	87aa                	mv	a5,a0
    return -1;
    8000589e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058a0:	0007cc63          	bltz	a5,800058b8 <sys_read+0x5e>
  return fileread(f, p, n);
    800058a4:	fe442603          	lw	a2,-28(s0)
    800058a8:	fd843583          	ld	a1,-40(s0)
    800058ac:	fe843503          	ld	a0,-24(s0)
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	452080e7          	jalr	1106(ra) # 80004d02 <fileread>
}
    800058b8:	70a2                	ld	ra,40(sp)
    800058ba:	7402                	ld	s0,32(sp)
    800058bc:	6145                	add	sp,sp,48
    800058be:	8082                	ret

00000000800058c0 <sys_write>:
{
    800058c0:	7179                	add	sp,sp,-48
    800058c2:	f406                	sd	ra,40(sp)
    800058c4:	f022                	sd	s0,32(sp)
    800058c6:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800058c8:	fd840593          	add	a1,s0,-40
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	7fe080e7          	jalr	2046(ra) # 800030cc <argaddr>
  argint(2, &n);
    800058d6:	fe440593          	add	a1,s0,-28
    800058da:	4509                	li	a0,2
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	7d0080e7          	jalr	2000(ra) # 800030ac <argint>
  if(argfd(0, 0, &f) < 0)
    800058e4:	fe840613          	add	a2,s0,-24
    800058e8:	4581                	li	a1,0
    800058ea:	4501                	li	a0,0
    800058ec:	00000097          	auipc	ra,0x0
    800058f0:	cf8080e7          	jalr	-776(ra) # 800055e4 <argfd>
    800058f4:	87aa                	mv	a5,a0
    return -1;
    800058f6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058f8:	0007cc63          	bltz	a5,80005910 <sys_write+0x50>
  return filewrite(f, p, n);
    800058fc:	fe442603          	lw	a2,-28(s0)
    80005900:	fd843583          	ld	a1,-40(s0)
    80005904:	fe843503          	ld	a0,-24(s0)
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	4bc080e7          	jalr	1212(ra) # 80004dc4 <filewrite>
}
    80005910:	70a2                	ld	ra,40(sp)
    80005912:	7402                	ld	s0,32(sp)
    80005914:	6145                	add	sp,sp,48
    80005916:	8082                	ret

0000000080005918 <sys_close>:
{
    80005918:	1101                	add	sp,sp,-32
    8000591a:	ec06                	sd	ra,24(sp)
    8000591c:	e822                	sd	s0,16(sp)
    8000591e:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005920:	fe040613          	add	a2,s0,-32
    80005924:	fec40593          	add	a1,s0,-20
    80005928:	4501                	li	a0,0
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	cba080e7          	jalr	-838(ra) # 800055e4 <argfd>
    return -1;
    80005932:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005934:	02054463          	bltz	a0,8000595c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005938:	ffffc097          	auipc	ra,0xffffc
    8000593c:	0c6080e7          	jalr	198(ra) # 800019fe <myproc>
    80005940:	fec42783          	lw	a5,-20(s0)
    80005944:	07e9                	add	a5,a5,26
    80005946:	078e                	sll	a5,a5,0x3
    80005948:	953e                	add	a0,a0,a5
    8000594a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000594e:	fe043503          	ld	a0,-32(s0)
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	276080e7          	jalr	630(ra) # 80004bc8 <fileclose>
  return 0;
    8000595a:	4781                	li	a5,0
}
    8000595c:	853e                	mv	a0,a5
    8000595e:	60e2                	ld	ra,24(sp)
    80005960:	6442                	ld	s0,16(sp)
    80005962:	6105                	add	sp,sp,32
    80005964:	8082                	ret

0000000080005966 <sys_fstat>:
{
    80005966:	1101                	add	sp,sp,-32
    80005968:	ec06                	sd	ra,24(sp)
    8000596a:	e822                	sd	s0,16(sp)
    8000596c:	1000                	add	s0,sp,32
  argaddr(1, &st);
    8000596e:	fe040593          	add	a1,s0,-32
    80005972:	4505                	li	a0,1
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	758080e7          	jalr	1880(ra) # 800030cc <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000597c:	fe840613          	add	a2,s0,-24
    80005980:	4581                	li	a1,0
    80005982:	4501                	li	a0,0
    80005984:	00000097          	auipc	ra,0x0
    80005988:	c60080e7          	jalr	-928(ra) # 800055e4 <argfd>
    8000598c:	87aa                	mv	a5,a0
    return -1;
    8000598e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005990:	0007ca63          	bltz	a5,800059a4 <sys_fstat+0x3e>
  return filestat(f, st);
    80005994:	fe043583          	ld	a1,-32(s0)
    80005998:	fe843503          	ld	a0,-24(s0)
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	2f4080e7          	jalr	756(ra) # 80004c90 <filestat>
}
    800059a4:	60e2                	ld	ra,24(sp)
    800059a6:	6442                	ld	s0,16(sp)
    800059a8:	6105                	add	sp,sp,32
    800059aa:	8082                	ret

00000000800059ac <sys_link>:
{
    800059ac:	7169                	add	sp,sp,-304
    800059ae:	f606                	sd	ra,296(sp)
    800059b0:	f222                	sd	s0,288(sp)
    800059b2:	ee26                	sd	s1,280(sp)
    800059b4:	ea4a                	sd	s2,272(sp)
    800059b6:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b8:	08000613          	li	a2,128
    800059bc:	ed040593          	add	a1,s0,-304
    800059c0:	4501                	li	a0,0
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	72a080e7          	jalr	1834(ra) # 800030ec <argstr>
    return -1;
    800059ca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059cc:	10054e63          	bltz	a0,80005ae8 <sys_link+0x13c>
    800059d0:	08000613          	li	a2,128
    800059d4:	f5040593          	add	a1,s0,-176
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	712080e7          	jalr	1810(ra) # 800030ec <argstr>
    return -1;
    800059e2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059e4:	10054263          	bltz	a0,80005ae8 <sys_link+0x13c>
  begin_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	d1c080e7          	jalr	-740(ra) # 80004704 <begin_op>
  if((ip = namei(old)) == 0){
    800059f0:	ed040513          	add	a0,s0,-304
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	b10080e7          	jalr	-1264(ra) # 80004504 <namei>
    800059fc:	84aa                	mv	s1,a0
    800059fe:	c551                	beqz	a0,80005a8a <sys_link+0xde>
  ilock(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	35e080e7          	jalr	862(ra) # 80003d5e <ilock>
  if(ip->type == T_DIR){
    80005a08:	04449703          	lh	a4,68(s1)
    80005a0c:	4785                	li	a5,1
    80005a0e:	08f70463          	beq	a4,a5,80005a96 <sys_link+0xea>
  ip->nlink++;
    80005a12:	04a4d783          	lhu	a5,74(s1)
    80005a16:	2785                	addw	a5,a5,1
    80005a18:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	274080e7          	jalr	628(ra) # 80003c92 <iupdate>
  iunlock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	3f8080e7          	jalr	1016(ra) # 80003e20 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a30:	fd040593          	add	a1,s0,-48
    80005a34:	f5040513          	add	a0,s0,-176
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	aea080e7          	jalr	-1302(ra) # 80004522 <nameiparent>
    80005a40:	892a                	mv	s2,a0
    80005a42:	c935                	beqz	a0,80005ab6 <sys_link+0x10a>
  ilock(dp);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	31a080e7          	jalr	794(ra) # 80003d5e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a4c:	00092703          	lw	a4,0(s2)
    80005a50:	409c                	lw	a5,0(s1)
    80005a52:	04f71d63          	bne	a4,a5,80005aac <sys_link+0x100>
    80005a56:	40d0                	lw	a2,4(s1)
    80005a58:	fd040593          	add	a1,s0,-48
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	9f4080e7          	jalr	-1548(ra) # 80004452 <dirlink>
    80005a66:	04054363          	bltz	a0,80005aac <sys_link+0x100>
  iunlockput(dp);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	554080e7          	jalr	1364(ra) # 80003fc0 <iunlockput>
  iput(ip);
    80005a74:	8526                	mv	a0,s1
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	4a2080e7          	jalr	1186(ra) # 80003f18 <iput>
  end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	d00080e7          	jalr	-768(ra) # 8000477e <end_op>
  return 0;
    80005a86:	4781                	li	a5,0
    80005a88:	a085                	j	80005ae8 <sys_link+0x13c>
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	cf4080e7          	jalr	-780(ra) # 8000477e <end_op>
    return -1;
    80005a92:	57fd                	li	a5,-1
    80005a94:	a891                	j	80005ae8 <sys_link+0x13c>
    iunlockput(ip);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	528080e7          	jalr	1320(ra) # 80003fc0 <iunlockput>
    end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	cde080e7          	jalr	-802(ra) # 8000477e <end_op>
    return -1;
    80005aa8:	57fd                	li	a5,-1
    80005aaa:	a83d                	j	80005ae8 <sys_link+0x13c>
    iunlockput(dp);
    80005aac:	854a                	mv	a0,s2
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	512080e7          	jalr	1298(ra) # 80003fc0 <iunlockput>
  ilock(ip);
    80005ab6:	8526                	mv	a0,s1
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	2a6080e7          	jalr	678(ra) # 80003d5e <ilock>
  ip->nlink--;
    80005ac0:	04a4d783          	lhu	a5,74(s1)
    80005ac4:	37fd                	addw	a5,a5,-1
    80005ac6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aca:	8526                	mv	a0,s1
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	1c6080e7          	jalr	454(ra) # 80003c92 <iupdate>
  iunlockput(ip);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	4ea080e7          	jalr	1258(ra) # 80003fc0 <iunlockput>
  end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	ca0080e7          	jalr	-864(ra) # 8000477e <end_op>
  return -1;
    80005ae6:	57fd                	li	a5,-1
}
    80005ae8:	853e                	mv	a0,a5
    80005aea:	70b2                	ld	ra,296(sp)
    80005aec:	7412                	ld	s0,288(sp)
    80005aee:	64f2                	ld	s1,280(sp)
    80005af0:	6952                	ld	s2,272(sp)
    80005af2:	6155                	add	sp,sp,304
    80005af4:	8082                	ret

0000000080005af6 <sys_unlink>:
{
    80005af6:	7151                	add	sp,sp,-240
    80005af8:	f586                	sd	ra,232(sp)
    80005afa:	f1a2                	sd	s0,224(sp)
    80005afc:	eda6                	sd	s1,216(sp)
    80005afe:	e9ca                	sd	s2,208(sp)
    80005b00:	e5ce                	sd	s3,200(sp)
    80005b02:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b04:	08000613          	li	a2,128
    80005b08:	f3040593          	add	a1,s0,-208
    80005b0c:	4501                	li	a0,0
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	5de080e7          	jalr	1502(ra) # 800030ec <argstr>
    80005b16:	18054163          	bltz	a0,80005c98 <sys_unlink+0x1a2>
  begin_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	bea080e7          	jalr	-1046(ra) # 80004704 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b22:	fb040593          	add	a1,s0,-80
    80005b26:	f3040513          	add	a0,s0,-208
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	9f8080e7          	jalr	-1544(ra) # 80004522 <nameiparent>
    80005b32:	84aa                	mv	s1,a0
    80005b34:	c979                	beqz	a0,80005c0a <sys_unlink+0x114>
  ilock(dp);
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	228080e7          	jalr	552(ra) # 80003d5e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b3e:	00003597          	auipc	a1,0x3
    80005b42:	bfa58593          	add	a1,a1,-1030 # 80008738 <syscalls+0x2c0>
    80005b46:	fb040513          	add	a0,s0,-80
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	6de080e7          	jalr	1758(ra) # 80004228 <namecmp>
    80005b52:	14050a63          	beqz	a0,80005ca6 <sys_unlink+0x1b0>
    80005b56:	00003597          	auipc	a1,0x3
    80005b5a:	bea58593          	add	a1,a1,-1046 # 80008740 <syscalls+0x2c8>
    80005b5e:	fb040513          	add	a0,s0,-80
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	6c6080e7          	jalr	1734(ra) # 80004228 <namecmp>
    80005b6a:	12050e63          	beqz	a0,80005ca6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b6e:	f2c40613          	add	a2,s0,-212
    80005b72:	fb040593          	add	a1,s0,-80
    80005b76:	8526                	mv	a0,s1
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	6ca080e7          	jalr	1738(ra) # 80004242 <dirlookup>
    80005b80:	892a                	mv	s2,a0
    80005b82:	12050263          	beqz	a0,80005ca6 <sys_unlink+0x1b0>
  ilock(ip);
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	1d8080e7          	jalr	472(ra) # 80003d5e <ilock>
  if(ip->nlink < 1)
    80005b8e:	04a91783          	lh	a5,74(s2)
    80005b92:	08f05263          	blez	a5,80005c16 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b96:	04491703          	lh	a4,68(s2)
    80005b9a:	4785                	li	a5,1
    80005b9c:	08f70563          	beq	a4,a5,80005c26 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ba0:	4641                	li	a2,16
    80005ba2:	4581                	li	a1,0
    80005ba4:	fc040513          	add	a0,s0,-64
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	126080e7          	jalr	294(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bb0:	4741                	li	a4,16
    80005bb2:	f2c42683          	lw	a3,-212(s0)
    80005bb6:	fc040613          	add	a2,s0,-64
    80005bba:	4581                	li	a1,0
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	54c080e7          	jalr	1356(ra) # 8000410a <writei>
    80005bc6:	47c1                	li	a5,16
    80005bc8:	0af51563          	bne	a0,a5,80005c72 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bcc:	04491703          	lh	a4,68(s2)
    80005bd0:	4785                	li	a5,1
    80005bd2:	0af70863          	beq	a4,a5,80005c82 <sys_unlink+0x18c>
  iunlockput(dp);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	3e8080e7          	jalr	1000(ra) # 80003fc0 <iunlockput>
  ip->nlink--;
    80005be0:	04a95783          	lhu	a5,74(s2)
    80005be4:	37fd                	addw	a5,a5,-1
    80005be6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bea:	854a                	mv	a0,s2
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	0a6080e7          	jalr	166(ra) # 80003c92 <iupdate>
  iunlockput(ip);
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	3ca080e7          	jalr	970(ra) # 80003fc0 <iunlockput>
  end_op();
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	b80080e7          	jalr	-1152(ra) # 8000477e <end_op>
  return 0;
    80005c06:	4501                	li	a0,0
    80005c08:	a84d                	j	80005cba <sys_unlink+0x1c4>
    end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	b74080e7          	jalr	-1164(ra) # 8000477e <end_op>
    return -1;
    80005c12:	557d                	li	a0,-1
    80005c14:	a05d                	j	80005cba <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c16:	00003517          	auipc	a0,0x3
    80005c1a:	b3250513          	add	a0,a0,-1230 # 80008748 <syscalls+0x2d0>
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c26:	04c92703          	lw	a4,76(s2)
    80005c2a:	02000793          	li	a5,32
    80005c2e:	f6e7f9e3          	bgeu	a5,a4,80005ba0 <sys_unlink+0xaa>
    80005c32:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c36:	4741                	li	a4,16
    80005c38:	86ce                	mv	a3,s3
    80005c3a:	f1840613          	add	a2,s0,-232
    80005c3e:	4581                	li	a1,0
    80005c40:	854a                	mv	a0,s2
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	3d0080e7          	jalr	976(ra) # 80004012 <readi>
    80005c4a:	47c1                	li	a5,16
    80005c4c:	00f51b63          	bne	a0,a5,80005c62 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c50:	f1845783          	lhu	a5,-232(s0)
    80005c54:	e7a1                	bnez	a5,80005c9c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c56:	29c1                	addw	s3,s3,16
    80005c58:	04c92783          	lw	a5,76(s2)
    80005c5c:	fcf9ede3          	bltu	s3,a5,80005c36 <sys_unlink+0x140>
    80005c60:	b781                	j	80005ba0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c62:	00003517          	auipc	a0,0x3
    80005c66:	afe50513          	add	a0,a0,-1282 # 80008760 <syscalls+0x2e8>
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	8d2080e7          	jalr	-1838(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005c72:	00003517          	auipc	a0,0x3
    80005c76:	b0650513          	add	a0,a0,-1274 # 80008778 <syscalls+0x300>
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	8c2080e7          	jalr	-1854(ra) # 8000053c <panic>
    dp->nlink--;
    80005c82:	04a4d783          	lhu	a5,74(s1)
    80005c86:	37fd                	addw	a5,a5,-1
    80005c88:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c8c:	8526                	mv	a0,s1
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	004080e7          	jalr	4(ra) # 80003c92 <iupdate>
    80005c96:	b781                	j	80005bd6 <sys_unlink+0xe0>
    return -1;
    80005c98:	557d                	li	a0,-1
    80005c9a:	a005                	j	80005cba <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c9c:	854a                	mv	a0,s2
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	322080e7          	jalr	802(ra) # 80003fc0 <iunlockput>
  iunlockput(dp);
    80005ca6:	8526                	mv	a0,s1
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	318080e7          	jalr	792(ra) # 80003fc0 <iunlockput>
  end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	ace080e7          	jalr	-1330(ra) # 8000477e <end_op>
  return -1;
    80005cb8:	557d                	li	a0,-1
}
    80005cba:	70ae                	ld	ra,232(sp)
    80005cbc:	740e                	ld	s0,224(sp)
    80005cbe:	64ee                	ld	s1,216(sp)
    80005cc0:	694e                	ld	s2,208(sp)
    80005cc2:	69ae                	ld	s3,200(sp)
    80005cc4:	616d                	add	sp,sp,240
    80005cc6:	8082                	ret

0000000080005cc8 <sys_open>:

uint64
sys_open(void)
{
    80005cc8:	7131                	add	sp,sp,-192
    80005cca:	fd06                	sd	ra,184(sp)
    80005ccc:	f922                	sd	s0,176(sp)
    80005cce:	f526                	sd	s1,168(sp)
    80005cd0:	f14a                	sd	s2,160(sp)
    80005cd2:	ed4e                	sd	s3,152(sp)
    80005cd4:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005cd6:	f4c40593          	add	a1,s0,-180
    80005cda:	4505                	li	a0,1
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	3d0080e7          	jalr	976(ra) # 800030ac <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f5040593          	add	a1,s0,-176
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	3fe080e7          	jalr	1022(ra) # 800030ec <argstr>
    80005cf6:	87aa                	mv	a5,a0
    return -1;
    80005cf8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cfa:	0a07c863          	bltz	a5,80005daa <sys_open+0xe2>

  begin_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	a06080e7          	jalr	-1530(ra) # 80004704 <begin_op>

  if(omode & O_CREATE){
    80005d06:	f4c42783          	lw	a5,-180(s0)
    80005d0a:	2007f793          	and	a5,a5,512
    80005d0e:	cbdd                	beqz	a5,80005dc4 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005d10:	4681                	li	a3,0
    80005d12:	4601                	li	a2,0
    80005d14:	4589                	li	a1,2
    80005d16:	f5040513          	add	a0,s0,-176
    80005d1a:	00000097          	auipc	ra,0x0
    80005d1e:	96c080e7          	jalr	-1684(ra) # 80005686 <create>
    80005d22:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d24:	c951                	beqz	a0,80005db8 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d26:	04449703          	lh	a4,68(s1)
    80005d2a:	478d                	li	a5,3
    80005d2c:	00f71763          	bne	a4,a5,80005d3a <sys_open+0x72>
    80005d30:	0464d703          	lhu	a4,70(s1)
    80005d34:	47a5                	li	a5,9
    80005d36:	0ce7ec63          	bltu	a5,a4,80005e0e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	dd2080e7          	jalr	-558(ra) # 80004b0c <filealloc>
    80005d42:	892a                	mv	s2,a0
    80005d44:	c56d                	beqz	a0,80005e2e <sys_open+0x166>
    80005d46:	00000097          	auipc	ra,0x0
    80005d4a:	8fe080e7          	jalr	-1794(ra) # 80005644 <fdalloc>
    80005d4e:	89aa                	mv	s3,a0
    80005d50:	0c054a63          	bltz	a0,80005e24 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d54:	04449703          	lh	a4,68(s1)
    80005d58:	478d                	li	a5,3
    80005d5a:	0ef70563          	beq	a4,a5,80005e44 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d5e:	4789                	li	a5,2
    80005d60:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005d64:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005d68:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005d6c:	f4c42783          	lw	a5,-180(s0)
    80005d70:	0017c713          	xor	a4,a5,1
    80005d74:	8b05                	and	a4,a4,1
    80005d76:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d7a:	0037f713          	and	a4,a5,3
    80005d7e:	00e03733          	snez	a4,a4
    80005d82:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d86:	4007f793          	and	a5,a5,1024
    80005d8a:	c791                	beqz	a5,80005d96 <sys_open+0xce>
    80005d8c:	04449703          	lh	a4,68(s1)
    80005d90:	4789                	li	a5,2
    80005d92:	0cf70063          	beq	a4,a5,80005e52 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005d96:	8526                	mv	a0,s1
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	088080e7          	jalr	136(ra) # 80003e20 <iunlock>
  end_op();
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	9de080e7          	jalr	-1570(ra) # 8000477e <end_op>

  return fd;
    80005da8:	854e                	mv	a0,s3
}
    80005daa:	70ea                	ld	ra,184(sp)
    80005dac:	744a                	ld	s0,176(sp)
    80005dae:	74aa                	ld	s1,168(sp)
    80005db0:	790a                	ld	s2,160(sp)
    80005db2:	69ea                	ld	s3,152(sp)
    80005db4:	6129                	add	sp,sp,192
    80005db6:	8082                	ret
      end_op();
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	9c6080e7          	jalr	-1594(ra) # 8000477e <end_op>
      return -1;
    80005dc0:	557d                	li	a0,-1
    80005dc2:	b7e5                	j	80005daa <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005dc4:	f5040513          	add	a0,s0,-176
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	73c080e7          	jalr	1852(ra) # 80004504 <namei>
    80005dd0:	84aa                	mv	s1,a0
    80005dd2:	c905                	beqz	a0,80005e02 <sys_open+0x13a>
    ilock(ip);
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	f8a080e7          	jalr	-118(ra) # 80003d5e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ddc:	04449703          	lh	a4,68(s1)
    80005de0:	4785                	li	a5,1
    80005de2:	f4f712e3          	bne	a4,a5,80005d26 <sys_open+0x5e>
    80005de6:	f4c42783          	lw	a5,-180(s0)
    80005dea:	dba1                	beqz	a5,80005d3a <sys_open+0x72>
      iunlockput(ip);
    80005dec:	8526                	mv	a0,s1
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	1d2080e7          	jalr	466(ra) # 80003fc0 <iunlockput>
      end_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	988080e7          	jalr	-1656(ra) # 8000477e <end_op>
      return -1;
    80005dfe:	557d                	li	a0,-1
    80005e00:	b76d                	j	80005daa <sys_open+0xe2>
      end_op();
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	97c080e7          	jalr	-1668(ra) # 8000477e <end_op>
      return -1;
    80005e0a:	557d                	li	a0,-1
    80005e0c:	bf79                	j	80005daa <sys_open+0xe2>
    iunlockput(ip);
    80005e0e:	8526                	mv	a0,s1
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	1b0080e7          	jalr	432(ra) # 80003fc0 <iunlockput>
    end_op();
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	966080e7          	jalr	-1690(ra) # 8000477e <end_op>
    return -1;
    80005e20:	557d                	li	a0,-1
    80005e22:	b761                	j	80005daa <sys_open+0xe2>
      fileclose(f);
    80005e24:	854a                	mv	a0,s2
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	da2080e7          	jalr	-606(ra) # 80004bc8 <fileclose>
    iunlockput(ip);
    80005e2e:	8526                	mv	a0,s1
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	190080e7          	jalr	400(ra) # 80003fc0 <iunlockput>
    end_op();
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	946080e7          	jalr	-1722(ra) # 8000477e <end_op>
    return -1;
    80005e40:	557d                	li	a0,-1
    80005e42:	b7a5                	j	80005daa <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005e44:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005e48:	04649783          	lh	a5,70(s1)
    80005e4c:	02f91223          	sh	a5,36(s2)
    80005e50:	bf21                	j	80005d68 <sys_open+0xa0>
    itrunc(ip);
    80005e52:	8526                	mv	a0,s1
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	018080e7          	jalr	24(ra) # 80003e6c <itrunc>
    80005e5c:	bf2d                	j	80005d96 <sys_open+0xce>

0000000080005e5e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e5e:	7175                	add	sp,sp,-144
    80005e60:	e506                	sd	ra,136(sp)
    80005e62:	e122                	sd	s0,128(sp)
    80005e64:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	89e080e7          	jalr	-1890(ra) # 80004704 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e6e:	08000613          	li	a2,128
    80005e72:	f7040593          	add	a1,s0,-144
    80005e76:	4501                	li	a0,0
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	274080e7          	jalr	628(ra) # 800030ec <argstr>
    80005e80:	02054963          	bltz	a0,80005eb2 <sys_mkdir+0x54>
    80005e84:	4681                	li	a3,0
    80005e86:	4601                	li	a2,0
    80005e88:	4585                	li	a1,1
    80005e8a:	f7040513          	add	a0,s0,-144
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	7f8080e7          	jalr	2040(ra) # 80005686 <create>
    80005e96:	cd11                	beqz	a0,80005eb2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e98:	ffffe097          	auipc	ra,0xffffe
    80005e9c:	128080e7          	jalr	296(ra) # 80003fc0 <iunlockput>
  end_op();
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	8de080e7          	jalr	-1826(ra) # 8000477e <end_op>
  return 0;
    80005ea8:	4501                	li	a0,0
}
    80005eaa:	60aa                	ld	ra,136(sp)
    80005eac:	640a                	ld	s0,128(sp)
    80005eae:	6149                	add	sp,sp,144
    80005eb0:	8082                	ret
    end_op();
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	8cc080e7          	jalr	-1844(ra) # 8000477e <end_op>
    return -1;
    80005eba:	557d                	li	a0,-1
    80005ebc:	b7fd                	j	80005eaa <sys_mkdir+0x4c>

0000000080005ebe <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ebe:	7135                	add	sp,sp,-160
    80005ec0:	ed06                	sd	ra,152(sp)
    80005ec2:	e922                	sd	s0,144(sp)
    80005ec4:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ec6:	fffff097          	auipc	ra,0xfffff
    80005eca:	83e080e7          	jalr	-1986(ra) # 80004704 <begin_op>
  argint(1, &major);
    80005ece:	f6c40593          	add	a1,s0,-148
    80005ed2:	4505                	li	a0,1
    80005ed4:	ffffd097          	auipc	ra,0xffffd
    80005ed8:	1d8080e7          	jalr	472(ra) # 800030ac <argint>
  argint(2, &minor);
    80005edc:	f6840593          	add	a1,s0,-152
    80005ee0:	4509                	li	a0,2
    80005ee2:	ffffd097          	auipc	ra,0xffffd
    80005ee6:	1ca080e7          	jalr	458(ra) # 800030ac <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eea:	08000613          	li	a2,128
    80005eee:	f7040593          	add	a1,s0,-144
    80005ef2:	4501                	li	a0,0
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	1f8080e7          	jalr	504(ra) # 800030ec <argstr>
    80005efc:	02054b63          	bltz	a0,80005f32 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f00:	f6841683          	lh	a3,-152(s0)
    80005f04:	f6c41603          	lh	a2,-148(s0)
    80005f08:	458d                	li	a1,3
    80005f0a:	f7040513          	add	a0,s0,-144
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	778080e7          	jalr	1912(ra) # 80005686 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f16:	cd11                	beqz	a0,80005f32 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	0a8080e7          	jalr	168(ra) # 80003fc0 <iunlockput>
  end_op();
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	85e080e7          	jalr	-1954(ra) # 8000477e <end_op>
  return 0;
    80005f28:	4501                	li	a0,0
}
    80005f2a:	60ea                	ld	ra,152(sp)
    80005f2c:	644a                	ld	s0,144(sp)
    80005f2e:	610d                	add	sp,sp,160
    80005f30:	8082                	ret
    end_op();
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	84c080e7          	jalr	-1972(ra) # 8000477e <end_op>
    return -1;
    80005f3a:	557d                	li	a0,-1
    80005f3c:	b7fd                	j	80005f2a <sys_mknod+0x6c>

0000000080005f3e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f3e:	7135                	add	sp,sp,-160
    80005f40:	ed06                	sd	ra,152(sp)
    80005f42:	e922                	sd	s0,144(sp)
    80005f44:	e526                	sd	s1,136(sp)
    80005f46:	e14a                	sd	s2,128(sp)
    80005f48:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f4a:	ffffc097          	auipc	ra,0xffffc
    80005f4e:	ab4080e7          	jalr	-1356(ra) # 800019fe <myproc>
    80005f52:	892a                	mv	s2,a0
  
  begin_op();
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	7b0080e7          	jalr	1968(ra) # 80004704 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f5c:	08000613          	li	a2,128
    80005f60:	f6040593          	add	a1,s0,-160
    80005f64:	4501                	li	a0,0
    80005f66:	ffffd097          	auipc	ra,0xffffd
    80005f6a:	186080e7          	jalr	390(ra) # 800030ec <argstr>
    80005f6e:	04054b63          	bltz	a0,80005fc4 <sys_chdir+0x86>
    80005f72:	f6040513          	add	a0,s0,-160
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	58e080e7          	jalr	1422(ra) # 80004504 <namei>
    80005f7e:	84aa                	mv	s1,a0
    80005f80:	c131                	beqz	a0,80005fc4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	ddc080e7          	jalr	-548(ra) # 80003d5e <ilock>
  if(ip->type != T_DIR){
    80005f8a:	04449703          	lh	a4,68(s1)
    80005f8e:	4785                	li	a5,1
    80005f90:	04f71063          	bne	a4,a5,80005fd0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f94:	8526                	mv	a0,s1
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	e8a080e7          	jalr	-374(ra) # 80003e20 <iunlock>
  iput(p->cwd);
    80005f9e:	15093503          	ld	a0,336(s2)
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	f76080e7          	jalr	-138(ra) # 80003f18 <iput>
  end_op();
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	7d4080e7          	jalr	2004(ra) # 8000477e <end_op>
  p->cwd = ip;
    80005fb2:	14993823          	sd	s1,336(s2)
  return 0;
    80005fb6:	4501                	li	a0,0
}
    80005fb8:	60ea                	ld	ra,152(sp)
    80005fba:	644a                	ld	s0,144(sp)
    80005fbc:	64aa                	ld	s1,136(sp)
    80005fbe:	690a                	ld	s2,128(sp)
    80005fc0:	610d                	add	sp,sp,160
    80005fc2:	8082                	ret
    end_op();
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	7ba080e7          	jalr	1978(ra) # 8000477e <end_op>
    return -1;
    80005fcc:	557d                	li	a0,-1
    80005fce:	b7ed                	j	80005fb8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005fd0:	8526                	mv	a0,s1
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	fee080e7          	jalr	-18(ra) # 80003fc0 <iunlockput>
    end_op();
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	7a4080e7          	jalr	1956(ra) # 8000477e <end_op>
    return -1;
    80005fe2:	557d                	li	a0,-1
    80005fe4:	bfd1                	j	80005fb8 <sys_chdir+0x7a>

0000000080005fe6 <sys_exec>:

uint64
sys_exec(void)
{
    80005fe6:	7121                	add	sp,sp,-448
    80005fe8:	ff06                	sd	ra,440(sp)
    80005fea:	fb22                	sd	s0,432(sp)
    80005fec:	f726                	sd	s1,424(sp)
    80005fee:	f34a                	sd	s2,416(sp)
    80005ff0:	ef4e                	sd	s3,408(sp)
    80005ff2:	eb52                	sd	s4,400(sp)
    80005ff4:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ff6:	e4840593          	add	a1,s0,-440
    80005ffa:	4505                	li	a0,1
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	0d0080e7          	jalr	208(ra) # 800030cc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006004:	08000613          	li	a2,128
    80006008:	f5040593          	add	a1,s0,-176
    8000600c:	4501                	li	a0,0
    8000600e:	ffffd097          	auipc	ra,0xffffd
    80006012:	0de080e7          	jalr	222(ra) # 800030ec <argstr>
    80006016:	87aa                	mv	a5,a0
    return -1;
    80006018:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000601a:	0c07c263          	bltz	a5,800060de <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    8000601e:	10000613          	li	a2,256
    80006022:	4581                	li	a1,0
    80006024:	e5040513          	add	a0,s0,-432
    80006028:	ffffb097          	auipc	ra,0xffffb
    8000602c:	ca6080e7          	jalr	-858(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006030:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006034:	89a6                	mv	s3,s1
    80006036:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006038:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000603c:	00391513          	sll	a0,s2,0x3
    80006040:	e4040593          	add	a1,s0,-448
    80006044:	e4843783          	ld	a5,-440(s0)
    80006048:	953e                	add	a0,a0,a5
    8000604a:	ffffd097          	auipc	ra,0xffffd
    8000604e:	fc4080e7          	jalr	-60(ra) # 8000300e <fetchaddr>
    80006052:	02054a63          	bltz	a0,80006086 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006056:	e4043783          	ld	a5,-448(s0)
    8000605a:	c3b9                	beqz	a5,800060a0 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000605c:	ffffb097          	auipc	ra,0xffffb
    80006060:	a86080e7          	jalr	-1402(ra) # 80000ae2 <kalloc>
    80006064:	85aa                	mv	a1,a0
    80006066:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000606a:	cd11                	beqz	a0,80006086 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000606c:	6605                	lui	a2,0x1
    8000606e:	e4043503          	ld	a0,-448(s0)
    80006072:	ffffd097          	auipc	ra,0xffffd
    80006076:	fee080e7          	jalr	-18(ra) # 80003060 <fetchstr>
    8000607a:	00054663          	bltz	a0,80006086 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    8000607e:	0905                	add	s2,s2,1
    80006080:	09a1                	add	s3,s3,8
    80006082:	fb491de3          	bne	s2,s4,8000603c <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006086:	f5040913          	add	s2,s0,-176
    8000608a:	6088                	ld	a0,0(s1)
    8000608c:	c921                	beqz	a0,800060dc <sys_exec+0xf6>
    kfree(argv[i]);
    8000608e:	ffffb097          	auipc	ra,0xffffb
    80006092:	956080e7          	jalr	-1706(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006096:	04a1                	add	s1,s1,8
    80006098:	ff2499e3          	bne	s1,s2,8000608a <sys_exec+0xa4>
  return -1;
    8000609c:	557d                	li	a0,-1
    8000609e:	a081                	j	800060de <sys_exec+0xf8>
      argv[i] = 0;
    800060a0:	0009079b          	sext.w	a5,s2
    800060a4:	078e                	sll	a5,a5,0x3
    800060a6:	fd078793          	add	a5,a5,-48
    800060aa:	97a2                	add	a5,a5,s0
    800060ac:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800060b0:	e5040593          	add	a1,s0,-432
    800060b4:	f5040513          	add	a0,s0,-176
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	186080e7          	jalr	390(ra) # 8000523e <exec>
    800060c0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c2:	f5040993          	add	s3,s0,-176
    800060c6:	6088                	ld	a0,0(s1)
    800060c8:	c901                	beqz	a0,800060d8 <sys_exec+0xf2>
    kfree(argv[i]);
    800060ca:	ffffb097          	auipc	ra,0xffffb
    800060ce:	91a080e7          	jalr	-1766(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d2:	04a1                	add	s1,s1,8
    800060d4:	ff3499e3          	bne	s1,s3,800060c6 <sys_exec+0xe0>
  return ret;
    800060d8:	854a                	mv	a0,s2
    800060da:	a011                	j	800060de <sys_exec+0xf8>
  return -1;
    800060dc:	557d                	li	a0,-1
}
    800060de:	70fa                	ld	ra,440(sp)
    800060e0:	745a                	ld	s0,432(sp)
    800060e2:	74ba                	ld	s1,424(sp)
    800060e4:	791a                	ld	s2,416(sp)
    800060e6:	69fa                	ld	s3,408(sp)
    800060e8:	6a5a                	ld	s4,400(sp)
    800060ea:	6139                	add	sp,sp,448
    800060ec:	8082                	ret

00000000800060ee <sys_pipe>:

uint64
sys_pipe(void)
{
    800060ee:	7139                	add	sp,sp,-64
    800060f0:	fc06                	sd	ra,56(sp)
    800060f2:	f822                	sd	s0,48(sp)
    800060f4:	f426                	sd	s1,40(sp)
    800060f6:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	906080e7          	jalr	-1786(ra) # 800019fe <myproc>
    80006100:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006102:	fd840593          	add	a1,s0,-40
    80006106:	4501                	li	a0,0
    80006108:	ffffd097          	auipc	ra,0xffffd
    8000610c:	fc4080e7          	jalr	-60(ra) # 800030cc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006110:	fc840593          	add	a1,s0,-56
    80006114:	fd040513          	add	a0,s0,-48
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	ddc080e7          	jalr	-548(ra) # 80004ef4 <pipealloc>
    return -1;
    80006120:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006122:	0c054463          	bltz	a0,800061ea <sys_pipe+0xfc>
  fd0 = -1;
    80006126:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000612a:	fd043503          	ld	a0,-48(s0)
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	516080e7          	jalr	1302(ra) # 80005644 <fdalloc>
    80006136:	fca42223          	sw	a0,-60(s0)
    8000613a:	08054b63          	bltz	a0,800061d0 <sys_pipe+0xe2>
    8000613e:	fc843503          	ld	a0,-56(s0)
    80006142:	fffff097          	auipc	ra,0xfffff
    80006146:	502080e7          	jalr	1282(ra) # 80005644 <fdalloc>
    8000614a:	fca42023          	sw	a0,-64(s0)
    8000614e:	06054863          	bltz	a0,800061be <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006152:	4691                	li	a3,4
    80006154:	fc440613          	add	a2,s0,-60
    80006158:	fd843583          	ld	a1,-40(s0)
    8000615c:	68a8                	ld	a0,80(s1)
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	508080e7          	jalr	1288(ra) # 80001666 <copyout>
    80006166:	02054063          	bltz	a0,80006186 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000616a:	4691                	li	a3,4
    8000616c:	fc040613          	add	a2,s0,-64
    80006170:	fd843583          	ld	a1,-40(s0)
    80006174:	0591                	add	a1,a1,4
    80006176:	68a8                	ld	a0,80(s1)
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	4ee080e7          	jalr	1262(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006180:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006182:	06055463          	bgez	a0,800061ea <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006186:	fc442783          	lw	a5,-60(s0)
    8000618a:	07e9                	add	a5,a5,26
    8000618c:	078e                	sll	a5,a5,0x3
    8000618e:	97a6                	add	a5,a5,s1
    80006190:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006194:	fc042783          	lw	a5,-64(s0)
    80006198:	07e9                	add	a5,a5,26
    8000619a:	078e                	sll	a5,a5,0x3
    8000619c:	94be                	add	s1,s1,a5
    8000619e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061a2:	fd043503          	ld	a0,-48(s0)
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	a22080e7          	jalr	-1502(ra) # 80004bc8 <fileclose>
    fileclose(wf);
    800061ae:	fc843503          	ld	a0,-56(s0)
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	a16080e7          	jalr	-1514(ra) # 80004bc8 <fileclose>
    return -1;
    800061ba:	57fd                	li	a5,-1
    800061bc:	a03d                	j	800061ea <sys_pipe+0xfc>
    if(fd0 >= 0)
    800061be:	fc442783          	lw	a5,-60(s0)
    800061c2:	0007c763          	bltz	a5,800061d0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800061c6:	07e9                	add	a5,a5,26
    800061c8:	078e                	sll	a5,a5,0x3
    800061ca:	97a6                	add	a5,a5,s1
    800061cc:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800061d0:	fd043503          	ld	a0,-48(s0)
    800061d4:	fffff097          	auipc	ra,0xfffff
    800061d8:	9f4080e7          	jalr	-1548(ra) # 80004bc8 <fileclose>
    fileclose(wf);
    800061dc:	fc843503          	ld	a0,-56(s0)
    800061e0:	fffff097          	auipc	ra,0xfffff
    800061e4:	9e8080e7          	jalr	-1560(ra) # 80004bc8 <fileclose>
    return -1;
    800061e8:	57fd                	li	a5,-1
}
    800061ea:	853e                	mv	a0,a5
    800061ec:	70e2                	ld	ra,56(sp)
    800061ee:	7442                	ld	s0,48(sp)
    800061f0:	74a2                	ld	s1,40(sp)
    800061f2:	6121                	add	sp,sp,64
    800061f4:	8082                	ret
	...

0000000080006200 <kernelvec>:
    80006200:	7111                	add	sp,sp,-256
    80006202:	e006                	sd	ra,0(sp)
    80006204:	e40a                	sd	sp,8(sp)
    80006206:	e80e                	sd	gp,16(sp)
    80006208:	ec12                	sd	tp,24(sp)
    8000620a:	f016                	sd	t0,32(sp)
    8000620c:	f41a                	sd	t1,40(sp)
    8000620e:	f81e                	sd	t2,48(sp)
    80006210:	fc22                	sd	s0,56(sp)
    80006212:	e0a6                	sd	s1,64(sp)
    80006214:	e4aa                	sd	a0,72(sp)
    80006216:	e8ae                	sd	a1,80(sp)
    80006218:	ecb2                	sd	a2,88(sp)
    8000621a:	f0b6                	sd	a3,96(sp)
    8000621c:	f4ba                	sd	a4,104(sp)
    8000621e:	f8be                	sd	a5,112(sp)
    80006220:	fcc2                	sd	a6,120(sp)
    80006222:	e146                	sd	a7,128(sp)
    80006224:	e54a                	sd	s2,136(sp)
    80006226:	e94e                	sd	s3,144(sp)
    80006228:	ed52                	sd	s4,152(sp)
    8000622a:	f156                	sd	s5,160(sp)
    8000622c:	f55a                	sd	s6,168(sp)
    8000622e:	f95e                	sd	s7,176(sp)
    80006230:	fd62                	sd	s8,184(sp)
    80006232:	e1e6                	sd	s9,192(sp)
    80006234:	e5ea                	sd	s10,200(sp)
    80006236:	e9ee                	sd	s11,208(sp)
    80006238:	edf2                	sd	t3,216(sp)
    8000623a:	f1f6                	sd	t4,224(sp)
    8000623c:	f5fa                	sd	t5,232(sp)
    8000623e:	f9fe                	sd	t6,240(sp)
    80006240:	c9bfc0ef          	jal	80002eda <kerneltrap>
    80006244:	6082                	ld	ra,0(sp)
    80006246:	6122                	ld	sp,8(sp)
    80006248:	61c2                	ld	gp,16(sp)
    8000624a:	7282                	ld	t0,32(sp)
    8000624c:	7322                	ld	t1,40(sp)
    8000624e:	73c2                	ld	t2,48(sp)
    80006250:	7462                	ld	s0,56(sp)
    80006252:	6486                	ld	s1,64(sp)
    80006254:	6526                	ld	a0,72(sp)
    80006256:	65c6                	ld	a1,80(sp)
    80006258:	6666                	ld	a2,88(sp)
    8000625a:	7686                	ld	a3,96(sp)
    8000625c:	7726                	ld	a4,104(sp)
    8000625e:	77c6                	ld	a5,112(sp)
    80006260:	7866                	ld	a6,120(sp)
    80006262:	688a                	ld	a7,128(sp)
    80006264:	692a                	ld	s2,136(sp)
    80006266:	69ca                	ld	s3,144(sp)
    80006268:	6a6a                	ld	s4,152(sp)
    8000626a:	7a8a                	ld	s5,160(sp)
    8000626c:	7b2a                	ld	s6,168(sp)
    8000626e:	7bca                	ld	s7,176(sp)
    80006270:	7c6a                	ld	s8,184(sp)
    80006272:	6c8e                	ld	s9,192(sp)
    80006274:	6d2e                	ld	s10,200(sp)
    80006276:	6dce                	ld	s11,208(sp)
    80006278:	6e6e                	ld	t3,216(sp)
    8000627a:	7e8e                	ld	t4,224(sp)
    8000627c:	7f2e                	ld	t5,232(sp)
    8000627e:	7fce                	ld	t6,240(sp)
    80006280:	6111                	add	sp,sp,256
    80006282:	10200073          	sret
    80006286:	00000013          	nop
    8000628a:	00000013          	nop
    8000628e:	0001                	nop

0000000080006290 <timervec>:
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	e10c                	sd	a1,0(a0)
    80006296:	e510                	sd	a2,8(a0)
    80006298:	e914                	sd	a3,16(a0)
    8000629a:	6d0c                	ld	a1,24(a0)
    8000629c:	7110                	ld	a2,32(a0)
    8000629e:	6194                	ld	a3,0(a1)
    800062a0:	96b2                	add	a3,a3,a2
    800062a2:	e194                	sd	a3,0(a1)
    800062a4:	4589                	li	a1,2
    800062a6:	14459073          	csrw	sip,a1
    800062aa:	6914                	ld	a3,16(a0)
    800062ac:	6510                	ld	a2,8(a0)
    800062ae:	610c                	ld	a1,0(a0)
    800062b0:	34051573          	csrrw	a0,mscratch,a0
    800062b4:	30200073          	mret
	...

00000000800062ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ba:	1141                	add	sp,sp,-16
    800062bc:	e422                	sd	s0,8(sp)
    800062be:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062c0:	0c0007b7          	lui	a5,0xc000
    800062c4:	4705                	li	a4,1
    800062c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062c8:	c3d8                	sw	a4,4(a5)
}
    800062ca:	6422                	ld	s0,8(sp)
    800062cc:	0141                	add	sp,sp,16
    800062ce:	8082                	ret

00000000800062d0 <plicinithart>:

void
plicinithart(void)
{
    800062d0:	1141                	add	sp,sp,-16
    800062d2:	e406                	sd	ra,8(sp)
    800062d4:	e022                	sd	s0,0(sp)
    800062d6:	0800                	add	s0,sp,16
  int hart = cpuid();
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	6fa080e7          	jalr	1786(ra) # 800019d2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062e0:	0085171b          	sllw	a4,a0,0x8
    800062e4:	0c0027b7          	lui	a5,0xc002
    800062e8:	97ba                	add	a5,a5,a4
    800062ea:	40200713          	li	a4,1026
    800062ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062f2:	00d5151b          	sllw	a0,a0,0xd
    800062f6:	0c2017b7          	lui	a5,0xc201
    800062fa:	97aa                	add	a5,a5,a0
    800062fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006300:	60a2                	ld	ra,8(sp)
    80006302:	6402                	ld	s0,0(sp)
    80006304:	0141                	add	sp,sp,16
    80006306:	8082                	ret

0000000080006308 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006308:	1141                	add	sp,sp,-16
    8000630a:	e406                	sd	ra,8(sp)
    8000630c:	e022                	sd	s0,0(sp)
    8000630e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	6c2080e7          	jalr	1730(ra) # 800019d2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006318:	00d5151b          	sllw	a0,a0,0xd
    8000631c:	0c2017b7          	lui	a5,0xc201
    80006320:	97aa                	add	a5,a5,a0
  return irq;
}
    80006322:	43c8                	lw	a0,4(a5)
    80006324:	60a2                	ld	ra,8(sp)
    80006326:	6402                	ld	s0,0(sp)
    80006328:	0141                	add	sp,sp,16
    8000632a:	8082                	ret

000000008000632c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000632c:	1101                	add	sp,sp,-32
    8000632e:	ec06                	sd	ra,24(sp)
    80006330:	e822                	sd	s0,16(sp)
    80006332:	e426                	sd	s1,8(sp)
    80006334:	1000                	add	s0,sp,32
    80006336:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006338:	ffffb097          	auipc	ra,0xffffb
    8000633c:	69a080e7          	jalr	1690(ra) # 800019d2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006340:	00d5151b          	sllw	a0,a0,0xd
    80006344:	0c2017b7          	lui	a5,0xc201
    80006348:	97aa                	add	a5,a5,a0
    8000634a:	c3c4                	sw	s1,4(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6105                	add	sp,sp,32
    80006354:	8082                	ret

0000000080006356 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006356:	1141                	add	sp,sp,-16
    80006358:	e406                	sd	ra,8(sp)
    8000635a:	e022                	sd	s0,0(sp)
    8000635c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000635e:	479d                	li	a5,7
    80006360:	04a7cc63          	blt	a5,a0,800063b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006364:	0001d797          	auipc	a5,0x1d
    80006368:	12c78793          	add	a5,a5,300 # 80023490 <disk>
    8000636c:	97aa                	add	a5,a5,a0
    8000636e:	0187c783          	lbu	a5,24(a5)
    80006372:	ebb9                	bnez	a5,800063c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006374:	00451693          	sll	a3,a0,0x4
    80006378:	0001d797          	auipc	a5,0x1d
    8000637c:	11878793          	add	a5,a5,280 # 80023490 <disk>
    80006380:	6398                	ld	a4,0(a5)
    80006382:	9736                	add	a4,a4,a3
    80006384:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006388:	6398                	ld	a4,0(a5)
    8000638a:	9736                	add	a4,a4,a3
    8000638c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006390:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006394:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006398:	97aa                	add	a5,a5,a0
    8000639a:	4705                	li	a4,1
    8000639c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063a0:	0001d517          	auipc	a0,0x1d
    800063a4:	10850513          	add	a0,a0,264 # 800234a8 <disk+0x18>
    800063a8:	ffffc097          	auipc	ra,0xffffc
    800063ac:	faa080e7          	jalr	-86(ra) # 80002352 <wakeup>
}
    800063b0:	60a2                	ld	ra,8(sp)
    800063b2:	6402                	ld	s0,0(sp)
    800063b4:	0141                	add	sp,sp,16
    800063b6:	8082                	ret
    panic("free_desc 1");
    800063b8:	00002517          	auipc	a0,0x2
    800063bc:	3d050513          	add	a0,a0,976 # 80008788 <syscalls+0x310>
    800063c0:	ffffa097          	auipc	ra,0xffffa
    800063c4:	17c080e7          	jalr	380(ra) # 8000053c <panic>
    panic("free_desc 2");
    800063c8:	00002517          	auipc	a0,0x2
    800063cc:	3d050513          	add	a0,a0,976 # 80008798 <syscalls+0x320>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	16c080e7          	jalr	364(ra) # 8000053c <panic>

00000000800063d8 <virtio_disk_init>:
{
    800063d8:	1101                	add	sp,sp,-32
    800063da:	ec06                	sd	ra,24(sp)
    800063dc:	e822                	sd	s0,16(sp)
    800063de:	e426                	sd	s1,8(sp)
    800063e0:	e04a                	sd	s2,0(sp)
    800063e2:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063e4:	00002597          	auipc	a1,0x2
    800063e8:	3c458593          	add	a1,a1,964 # 800087a8 <syscalls+0x330>
    800063ec:	0001d517          	auipc	a0,0x1d
    800063f0:	1cc50513          	add	a0,a0,460 # 800235b8 <disk+0x128>
    800063f4:	ffffa097          	auipc	ra,0xffffa
    800063f8:	74e080e7          	jalr	1870(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063fc:	100017b7          	lui	a5,0x10001
    80006400:	4398                	lw	a4,0(a5)
    80006402:	2701                	sext.w	a4,a4
    80006404:	747277b7          	lui	a5,0x74727
    80006408:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000640c:	14f71b63          	bne	a4,a5,80006562 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006410:	100017b7          	lui	a5,0x10001
    80006414:	43dc                	lw	a5,4(a5)
    80006416:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006418:	4709                	li	a4,2
    8000641a:	14e79463          	bne	a5,a4,80006562 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000641e:	100017b7          	lui	a5,0x10001
    80006422:	479c                	lw	a5,8(a5)
    80006424:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006426:	12e79e63          	bne	a5,a4,80006562 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000642a:	100017b7          	lui	a5,0x10001
    8000642e:	47d8                	lw	a4,12(a5)
    80006430:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006432:	554d47b7          	lui	a5,0x554d4
    80006436:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000643a:	12f71463          	bne	a4,a5,80006562 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000643e:	100017b7          	lui	a5,0x10001
    80006442:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006446:	4705                	li	a4,1
    80006448:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000644a:	470d                	li	a4,3
    8000644c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000644e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006450:	c7ffe6b7          	lui	a3,0xc7ffe
    80006454:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb18f>
    80006458:	8f75                	and	a4,a4,a3
    8000645a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000645c:	472d                	li	a4,11
    8000645e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006460:	5bbc                	lw	a5,112(a5)
    80006462:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006466:	8ba1                	and	a5,a5,8
    80006468:	10078563          	beqz	a5,80006572 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000646c:	100017b7          	lui	a5,0x10001
    80006470:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006474:	43fc                	lw	a5,68(a5)
    80006476:	2781                	sext.w	a5,a5
    80006478:	10079563          	bnez	a5,80006582 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000647c:	100017b7          	lui	a5,0x10001
    80006480:	5bdc                	lw	a5,52(a5)
    80006482:	2781                	sext.w	a5,a5
  if(max == 0)
    80006484:	10078763          	beqz	a5,80006592 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006488:	471d                	li	a4,7
    8000648a:	10f77c63          	bgeu	a4,a5,800065a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	654080e7          	jalr	1620(ra) # 80000ae2 <kalloc>
    80006496:	0001d497          	auipc	s1,0x1d
    8000649a:	ffa48493          	add	s1,s1,-6 # 80023490 <disk>
    8000649e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064a0:	ffffa097          	auipc	ra,0xffffa
    800064a4:	642080e7          	jalr	1602(ra) # 80000ae2 <kalloc>
    800064a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	638080e7          	jalr	1592(ra) # 80000ae2 <kalloc>
    800064b2:	87aa                	mv	a5,a0
    800064b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064b6:	6088                	ld	a0,0(s1)
    800064b8:	cd6d                	beqz	a0,800065b2 <virtio_disk_init+0x1da>
    800064ba:	0001d717          	auipc	a4,0x1d
    800064be:	fde73703          	ld	a4,-34(a4) # 80023498 <disk+0x8>
    800064c2:	cb65                	beqz	a4,800065b2 <virtio_disk_init+0x1da>
    800064c4:	c7fd                	beqz	a5,800065b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800064c6:	6605                	lui	a2,0x1
    800064c8:	4581                	li	a1,0
    800064ca:	ffffb097          	auipc	ra,0xffffb
    800064ce:	804080e7          	jalr	-2044(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800064d2:	0001d497          	auipc	s1,0x1d
    800064d6:	fbe48493          	add	s1,s1,-66 # 80023490 <disk>
    800064da:	6605                	lui	a2,0x1
    800064dc:	4581                	li	a1,0
    800064de:	6488                	ld	a0,8(s1)
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	7ee080e7          	jalr	2030(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    800064e8:	6605                	lui	a2,0x1
    800064ea:	4581                	li	a1,0
    800064ec:	6888                	ld	a0,16(s1)
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	7e0080e7          	jalr	2016(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064f6:	100017b7          	lui	a5,0x10001
    800064fa:	4721                	li	a4,8
    800064fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064fe:	4098                	lw	a4,0(s1)
    80006500:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006504:	40d8                	lw	a4,4(s1)
    80006506:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000650a:	6498                	ld	a4,8(s1)
    8000650c:	0007069b          	sext.w	a3,a4
    80006510:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006514:	9701                	sra	a4,a4,0x20
    80006516:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000651a:	6898                	ld	a4,16(s1)
    8000651c:	0007069b          	sext.w	a3,a4
    80006520:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006524:	9701                	sra	a4,a4,0x20
    80006526:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000652a:	4705                	li	a4,1
    8000652c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000652e:	00e48c23          	sb	a4,24(s1)
    80006532:	00e48ca3          	sb	a4,25(s1)
    80006536:	00e48d23          	sb	a4,26(s1)
    8000653a:	00e48da3          	sb	a4,27(s1)
    8000653e:	00e48e23          	sb	a4,28(s1)
    80006542:	00e48ea3          	sb	a4,29(s1)
    80006546:	00e48f23          	sb	a4,30(s1)
    8000654a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000654e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006552:	0727a823          	sw	s2,112(a5)
}
    80006556:	60e2                	ld	ra,24(sp)
    80006558:	6442                	ld	s0,16(sp)
    8000655a:	64a2                	ld	s1,8(sp)
    8000655c:	6902                	ld	s2,0(sp)
    8000655e:	6105                	add	sp,sp,32
    80006560:	8082                	ret
    panic("could not find virtio disk");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	25650513          	add	a0,a0,598 # 800087b8 <syscalls+0x340>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd2080e7          	jalr	-46(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	26650513          	add	a0,a0,614 # 800087d8 <syscalls+0x360>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc2080e7          	jalr	-62(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	27650513          	add	a0,a0,630 # 800087f8 <syscalls+0x380>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb2080e7          	jalr	-78(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006592:	00002517          	auipc	a0,0x2
    80006596:	28650513          	add	a0,a0,646 # 80008818 <syscalls+0x3a0>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	fa2080e7          	jalr	-94(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	29650513          	add	a0,a0,662 # 80008838 <syscalls+0x3c0>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f92080e7          	jalr	-110(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	2a650513          	add	a0,a0,678 # 80008858 <syscalls+0x3e0>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>

00000000800065c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065c2:	7159                	add	sp,sp,-112
    800065c4:	f486                	sd	ra,104(sp)
    800065c6:	f0a2                	sd	s0,96(sp)
    800065c8:	eca6                	sd	s1,88(sp)
    800065ca:	e8ca                	sd	s2,80(sp)
    800065cc:	e4ce                	sd	s3,72(sp)
    800065ce:	e0d2                	sd	s4,64(sp)
    800065d0:	fc56                	sd	s5,56(sp)
    800065d2:	f85a                	sd	s6,48(sp)
    800065d4:	f45e                	sd	s7,40(sp)
    800065d6:	f062                	sd	s8,32(sp)
    800065d8:	ec66                	sd	s9,24(sp)
    800065da:	e86a                	sd	s10,16(sp)
    800065dc:	1880                	add	s0,sp,112
    800065de:	8a2a                	mv	s4,a0
    800065e0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065e2:	00c52c83          	lw	s9,12(a0)
    800065e6:	001c9c9b          	sllw	s9,s9,0x1
    800065ea:	1c82                	sll	s9,s9,0x20
    800065ec:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065f0:	0001d517          	auipc	a0,0x1d
    800065f4:	fc850513          	add	a0,a0,-56 # 800235b8 <disk+0x128>
    800065f8:	ffffa097          	auipc	ra,0xffffa
    800065fc:	5da080e7          	jalr	1498(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006600:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006602:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006604:	0001db17          	auipc	s6,0x1d
    80006608:	e8cb0b13          	add	s6,s6,-372 # 80023490 <disk>
  for(int i = 0; i < 3; i++){
    8000660c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000660e:	0001dc17          	auipc	s8,0x1d
    80006612:	faac0c13          	add	s8,s8,-86 # 800235b8 <disk+0x128>
    80006616:	a095                	j	8000667a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006618:	00fb0733          	add	a4,s6,a5
    8000661c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006620:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006622:	0207c563          	bltz	a5,8000664c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006626:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006628:	0591                	add	a1,a1,4
    8000662a:	05560d63          	beq	a2,s5,80006684 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000662e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006630:	0001d717          	auipc	a4,0x1d
    80006634:	e6070713          	add	a4,a4,-416 # 80023490 <disk>
    80006638:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000663a:	01874683          	lbu	a3,24(a4)
    8000663e:	fee9                	bnez	a3,80006618 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006640:	2785                	addw	a5,a5,1
    80006642:	0705                	add	a4,a4,1
    80006644:	fe979be3          	bne	a5,s1,8000663a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006648:	57fd                	li	a5,-1
    8000664a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000664c:	00c05e63          	blez	a2,80006668 <virtio_disk_rw+0xa6>
    80006650:	060a                	sll	a2,a2,0x2
    80006652:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006656:	0009a503          	lw	a0,0(s3)
    8000665a:	00000097          	auipc	ra,0x0
    8000665e:	cfc080e7          	jalr	-772(ra) # 80006356 <free_desc>
      for(int j = 0; j < i; j++)
    80006662:	0991                	add	s3,s3,4
    80006664:	ffa999e3          	bne	s3,s10,80006656 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006668:	85e2                	mv	a1,s8
    8000666a:	0001d517          	auipc	a0,0x1d
    8000666e:	e3e50513          	add	a0,a0,-450 # 800234a8 <disk+0x18>
    80006672:	ffffc097          	auipc	ra,0xffffc
    80006676:	c7c080e7          	jalr	-900(ra) # 800022ee <sleep>
  for(int i = 0; i < 3; i++){
    8000667a:	f9040993          	add	s3,s0,-112
{
    8000667e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006680:	864a                	mv	a2,s2
    80006682:	b775                	j	8000662e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006684:	f9042503          	lw	a0,-112(s0)
    80006688:	00a50713          	add	a4,a0,10
    8000668c:	0712                	sll	a4,a4,0x4

  if(write)
    8000668e:	0001d797          	auipc	a5,0x1d
    80006692:	e0278793          	add	a5,a5,-510 # 80023490 <disk>
    80006696:	00e786b3          	add	a3,a5,a4
    8000669a:	01703633          	snez	a2,s7
    8000669e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066a4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066a8:	f6070613          	add	a2,a4,-160
    800066ac:	6394                	ld	a3,0(a5)
    800066ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066b0:	00870593          	add	a1,a4,8
    800066b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066b8:	0007b803          	ld	a6,0(a5)
    800066bc:	9642                	add	a2,a2,a6
    800066be:	46c1                	li	a3,16
    800066c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066c2:	4585                	li	a1,1
    800066c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800066c8:	f9442683          	lw	a3,-108(s0)
    800066cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066d0:	0692                	sll	a3,a3,0x4
    800066d2:	9836                	add	a6,a6,a3
    800066d4:	058a0613          	add	a2,s4,88
    800066d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800066dc:	0007b803          	ld	a6,0(a5)
    800066e0:	96c2                	add	a3,a3,a6
    800066e2:	40000613          	li	a2,1024
    800066e6:	c690                	sw	a2,8(a3)
  if(write)
    800066e8:	001bb613          	seqz	a2,s7
    800066ec:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066f0:	00166613          	or	a2,a2,1
    800066f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066f8:	f9842603          	lw	a2,-104(s0)
    800066fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006700:	00250693          	add	a3,a0,2
    80006704:	0692                	sll	a3,a3,0x4
    80006706:	96be                	add	a3,a3,a5
    80006708:	58fd                	li	a7,-1
    8000670a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000670e:	0612                	sll	a2,a2,0x4
    80006710:	9832                	add	a6,a6,a2
    80006712:	f9070713          	add	a4,a4,-112
    80006716:	973e                	add	a4,a4,a5
    80006718:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000671c:	6398                	ld	a4,0(a5)
    8000671e:	9732                	add	a4,a4,a2
    80006720:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006722:	4609                	li	a2,2
    80006724:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006728:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000672c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006730:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006734:	6794                	ld	a3,8(a5)
    80006736:	0026d703          	lhu	a4,2(a3)
    8000673a:	8b1d                	and	a4,a4,7
    8000673c:	0706                	sll	a4,a4,0x1
    8000673e:	96ba                	add	a3,a3,a4
    80006740:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006744:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006748:	6798                	ld	a4,8(a5)
    8000674a:	00275783          	lhu	a5,2(a4)
    8000674e:	2785                	addw	a5,a5,1
    80006750:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006754:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006758:	100017b7          	lui	a5,0x10001
    8000675c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006760:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006764:	0001d917          	auipc	s2,0x1d
    80006768:	e5490913          	add	s2,s2,-428 # 800235b8 <disk+0x128>
  while(b->disk == 1) {
    8000676c:	4485                	li	s1,1
    8000676e:	00b79c63          	bne	a5,a1,80006786 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006772:	85ca                	mv	a1,s2
    80006774:	8552                	mv	a0,s4
    80006776:	ffffc097          	auipc	ra,0xffffc
    8000677a:	b78080e7          	jalr	-1160(ra) # 800022ee <sleep>
  while(b->disk == 1) {
    8000677e:	004a2783          	lw	a5,4(s4)
    80006782:	fe9788e3          	beq	a5,s1,80006772 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006786:	f9042903          	lw	s2,-112(s0)
    8000678a:	00290713          	add	a4,s2,2
    8000678e:	0712                	sll	a4,a4,0x4
    80006790:	0001d797          	auipc	a5,0x1d
    80006794:	d0078793          	add	a5,a5,-768 # 80023490 <disk>
    80006798:	97ba                	add	a5,a5,a4
    8000679a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000679e:	0001d997          	auipc	s3,0x1d
    800067a2:	cf298993          	add	s3,s3,-782 # 80023490 <disk>
    800067a6:	00491713          	sll	a4,s2,0x4
    800067aa:	0009b783          	ld	a5,0(s3)
    800067ae:	97ba                	add	a5,a5,a4
    800067b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067b4:	854a                	mv	a0,s2
    800067b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067ba:	00000097          	auipc	ra,0x0
    800067be:	b9c080e7          	jalr	-1124(ra) # 80006356 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800067c2:	8885                	and	s1,s1,1
    800067c4:	f0ed                	bnez	s1,800067a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067c6:	0001d517          	auipc	a0,0x1d
    800067ca:	df250513          	add	a0,a0,-526 # 800235b8 <disk+0x128>
    800067ce:	ffffa097          	auipc	ra,0xffffa
    800067d2:	4b8080e7          	jalr	1208(ra) # 80000c86 <release>
}
    800067d6:	70a6                	ld	ra,104(sp)
    800067d8:	7406                	ld	s0,96(sp)
    800067da:	64e6                	ld	s1,88(sp)
    800067dc:	6946                	ld	s2,80(sp)
    800067de:	69a6                	ld	s3,72(sp)
    800067e0:	6a06                	ld	s4,64(sp)
    800067e2:	7ae2                	ld	s5,56(sp)
    800067e4:	7b42                	ld	s6,48(sp)
    800067e6:	7ba2                	ld	s7,40(sp)
    800067e8:	7c02                	ld	s8,32(sp)
    800067ea:	6ce2                	ld	s9,24(sp)
    800067ec:	6d42                	ld	s10,16(sp)
    800067ee:	6165                	add	sp,sp,112
    800067f0:	8082                	ret

00000000800067f2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067f2:	1101                	add	sp,sp,-32
    800067f4:	ec06                	sd	ra,24(sp)
    800067f6:	e822                	sd	s0,16(sp)
    800067f8:	e426                	sd	s1,8(sp)
    800067fa:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067fc:	0001d497          	auipc	s1,0x1d
    80006800:	c9448493          	add	s1,s1,-876 # 80023490 <disk>
    80006804:	0001d517          	auipc	a0,0x1d
    80006808:	db450513          	add	a0,a0,-588 # 800235b8 <disk+0x128>
    8000680c:	ffffa097          	auipc	ra,0xffffa
    80006810:	3c6080e7          	jalr	966(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006814:	10001737          	lui	a4,0x10001
    80006818:	533c                	lw	a5,96(a4)
    8000681a:	8b8d                	and	a5,a5,3
    8000681c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000681e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006822:	689c                	ld	a5,16(s1)
    80006824:	0204d703          	lhu	a4,32(s1)
    80006828:	0027d783          	lhu	a5,2(a5)
    8000682c:	04f70863          	beq	a4,a5,8000687c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006830:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006834:	6898                	ld	a4,16(s1)
    80006836:	0204d783          	lhu	a5,32(s1)
    8000683a:	8b9d                	and	a5,a5,7
    8000683c:	078e                	sll	a5,a5,0x3
    8000683e:	97ba                	add	a5,a5,a4
    80006840:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006842:	00278713          	add	a4,a5,2
    80006846:	0712                	sll	a4,a4,0x4
    80006848:	9726                	add	a4,a4,s1
    8000684a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000684e:	e721                	bnez	a4,80006896 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006850:	0789                	add	a5,a5,2
    80006852:	0792                	sll	a5,a5,0x4
    80006854:	97a6                	add	a5,a5,s1
    80006856:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006858:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000685c:	ffffc097          	auipc	ra,0xffffc
    80006860:	af6080e7          	jalr	-1290(ra) # 80002352 <wakeup>

    disk.used_idx += 1;
    80006864:	0204d783          	lhu	a5,32(s1)
    80006868:	2785                	addw	a5,a5,1
    8000686a:	17c2                	sll	a5,a5,0x30
    8000686c:	93c1                	srl	a5,a5,0x30
    8000686e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006872:	6898                	ld	a4,16(s1)
    80006874:	00275703          	lhu	a4,2(a4)
    80006878:	faf71ce3          	bne	a4,a5,80006830 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000687c:	0001d517          	auipc	a0,0x1d
    80006880:	d3c50513          	add	a0,a0,-708 # 800235b8 <disk+0x128>
    80006884:	ffffa097          	auipc	ra,0xffffa
    80006888:	402080e7          	jalr	1026(ra) # 80000c86 <release>
}
    8000688c:	60e2                	ld	ra,24(sp)
    8000688e:	6442                	ld	s0,16(sp)
    80006890:	64a2                	ld	s1,8(sp)
    80006892:	6105                	add	sp,sp,32
    80006894:	8082                	ret
      panic("virtio_disk_intr status");
    80006896:	00002517          	auipc	a0,0x2
    8000689a:	fda50513          	add	a0,a0,-38 # 80008870 <syscalls+0x3f8>
    8000689e:	ffffa097          	auipc	ra,0xffffa
    800068a2:	c9e080e7          	jalr	-866(ra) # 8000053c <panic>
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
