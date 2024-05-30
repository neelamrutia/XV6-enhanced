#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

extern int read_counter;

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;
  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64 sys_getreadcount(void)
{
  return read_counter;
}

uint64 sys_sigalarm(void)
{
  int ticks;
  int handler;
  argint(0, &ticks);
  argint(1, &handler);
  struct proc *p = myproc();
  p->handler = handler;
  p->ticks = ticks;
  p->is_sigalarm = 0;
  p->now_ticks = 0;
  return 0;
}

uint64 sys_sigreturn(void)
{
  struct proc *p = myproc();
  p->is_sigalarm = 0;
  *(p->trapframe) = *(p->trapframe_copy);
  //kfree(p->trapframe_copy);
  usertrapret();
  return 0;
}

// void scheduler(void)
// {
//   struct cpu *c = mycpu();
//   c->proc = 0;
//   while (1)
//   {
// #ifdef FCFS
//     struct proc *p;
//     struct proc *minimum_p = 0;
//     for (p = proc; p < &proc[NPROC]; p++)
//     {
//       if (p->state == RUNNABLE)
//       {
//         if (minimum_p == 0)
//         {
//           minimum_p = p;
//         }
//         else if (p->ctime < minimum_p->ctime)
//         {
//           minimum_p = p;
//         }
//       }
//       p++;
//     }
//     if (minimum_p != 0)
//     {
//       c->proc = minimum_p;
//       minimum_p->state = RUNNING;
//       swtch(&c->context, &minimum_p->context);
//       c->proc = 0;
//     }
// #endif
//   }
// }
