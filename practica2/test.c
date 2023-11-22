#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char const *argv[])
{
    //Declaracion de variables
    pid_t pid = 0;
    int n = 0;

    //Creacion de proceso hijo
    pid = fork();

    if (pid == 0)
    {
        //proceso hijo
        printf("Soy el proceso hijo con id %d y mi padre es %d\n", getpid(), getppid());
        n = 1;
    }
    else
    {
        //Proceso padre
        printf("Soy el proceso padre con id %d y mi padre es %d\n", getpid(), getppid());
        printf("Mi hijo es %d\n", pid);
        n = 6;
        // Esperamos a que el hijo termine
        wait(NULL);
    }
    
    //Ambos procesos ejecutan este codigo
    for (int i = n; i < n + 5; i++)
    {
        printf("%d ", i);
    }

    // Solo el padre ejecuta este codigo
    if (pid > 0)
    {
        printf("\n");
    }
    
}
