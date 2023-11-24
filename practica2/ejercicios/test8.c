//Un proceso que crea un proceso hijo. El proceso hijo no finaliza hasta que el proceso padre le envia una señal sigint.
//Cuando el proceso hijo recibe SIGINT, envia al padre la señal SIGUSR1

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <signal.h>

void manejador_senial_sigint(int);
void manejador_senial_sigusr1(int);

int main(int argc, char const *argv[])
{
    int pid;
    signal(SIGUSR1, manejador_senial_sigusr1);
    printf("Proceso padre ejecutandose, crea un proceso hijo\n");
    pid = fork();
    switch (pid)
    {
    case -1:
        printf("Error al crear proceso\n");
        break;
    case 0:
        signal(SIGINT, manejador_senial_sigint);
        printf("Proceso hijo: ejecutandose hasta recibir SIGINT del padre\n");
        while (1)
        {
            printf("Hijo %d: mensaje hasta recibir SIGINT\n", getpid());
            usleep(500);
        }
        exit(0);
    default:
        printf("Proceso padre: continua hasta recibir SIGUSR1 del hijo\n");
        for (int i = 0; i < 5; i++)
        {
            printf("Padre %d: ejecuta tarea\n", getpid());
            usleep(500);
        }
        kill(pid, SIGINT);
        while (1)
        {
            printf("Padre %d: mensaje hasta recibir SIGUSR1\n", getpid());
            usleep(300);
        }
        exit(0);
        break;
    }
    return 0;
}

void manejador_senial_sigint(int senial){
    int p = getpid();
    printf("Proceso hijo: %d recibe señal SIGINT (%d)\n", p, senial);
    printf("Proceso hijo: %d envia SIGUSR1 al padre\n", p);
    kill(getppid(), SIGUSR1);
    exit(0);
}
void manejador_senial_sigusr1(int senial){
    printf("Proceso padre: %d recibe SIGUSR1 (%d) enviada por el hijo\n", getpid(), senial);
    exit(0);
}