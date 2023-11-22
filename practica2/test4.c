#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char *argv[])
{
    pid_t pid;
    int estado;
    pid = fork();
    switch (pid)
    {
    case -1:
        printf("Error al crear el proceso\n");
        break;
    case 0:
        execlp("ls", "ls", "-l", NULL);
        perror("Al ejecutar exec");
        return 1;
    default:
        printf("Proceso padre (invocador) con id. de proceso: %d e id. del proceso padre %d\n ", getpid(), getppid());
        break;
    }
    return 0;
}