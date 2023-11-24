#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>

void manejador_senial_sigint(int);

int main(void)
{
    // armar señal SIGINT
    signal(SIGINT, manejador_senial_sigint);
    while (1)
    {
        printf("Mensaje cuando se pulsa Ctrl-C \n"); 
        sleep(2);
    }
}
void manejador_senial_sigint(int senial)
{
    printf("Senial recibida: %d \n", senial);
    exit(0);
}