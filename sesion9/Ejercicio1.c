#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char const *argv[])
{
    pid_t pid;
    pid = fork();

    switch (pid)
    {
    case -1:
        printf("Error al crear el proceso\n");
        break;
    case 0:
        printf("Proceso hijo con id. de proceso: %d e id. del proceso padre %d\n", getpid(), getppid());
    default:
        printf("Proceso padre (invocador) con id. de proceso: %d e id. del proceso padre %d\n", getpid(), getppid());
        system("ps -o user,pid,ppid,cmd");
        break;
    }
    return 0;
}
