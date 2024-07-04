#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    int pid = atoi(argv[1]);
    int priority = atoi(argv[2]);
    int old_priority= set_priority(pid, priority);
    printf("Old priority is %d\n", old_priority);
    exit(0);
}