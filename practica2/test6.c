#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/times.h>
#include <sys/wait.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    pid_t pid;
    int estado;
    long suma;
    pid = fork();
    switch (pid)
    {
    case -1:
        printf("Error al crear el proceso\n");
        break;
    case 0:
        srand(getpid());
        printf("Proceso hijo con id. de proceso: %d e id. del proceso padre %d \n", getpid(), getppid());
        for (int i = 0; i < 1000; i++)
        {
            suma = suma + rand() % (1000 + 1);
            usleep(200);
        }
        printf("Hijo calculo = %ld \n", suma);
        exit(5);
    default:
        printf("Proceso padre (invocador) con id. de proceso: %d e id. del proceso padre %d \n", getpid(), getppid());
        wait(&estado);
        if (estado == 0)
            printf("Proceso hijo finalizado normalmente\n");
        else
            printf("Proceso hijo finalizado anormalmente\n");
        if (WIFEXITED(estado))
            printf("Proceso hijo finalizado por llamada a exit(%d) \n", WEXITSTATUS(estado));
        if (WIFSIGNALED(estado))
            printf("Proceso hijo finalizado por recepción de señal %d \n",WTERMSIG(estado));
        break;
    }
    return 0;
}