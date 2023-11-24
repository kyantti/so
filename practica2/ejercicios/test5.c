#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>

void finalizar(){
    printf("Finalizando programa con pid %d cuyo padres es %d\n", getpid(), getppid());
}


int main(int argc, char const *argv[])
{
    if (atexit(finalizar) != 0)
    {
        perror("Error al registrar la funcion finalizar");
        exit(EXIT_FAILURE);
    }
    printf("Se esta ejecutando el programa con pid %d cuyo padre es %d\n", getpid(), getppid());
    printf("Antes de llamar a exit \n");
    exit(EXIT_SUCCESS);
    
    return 0;
}
