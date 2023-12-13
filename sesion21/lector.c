#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

int main()
{
    int des;
    char cadena[100];

    mkfifo("tuberia", 0);
    chmod("tuberia", 460);
    do
    {
        des = open("tuberia", O_RDONLY);
        printf("Espero a poder abrir la tubería \n");
        if (des == -1)
            sleep(1);
    } while (des == -1);

    while (read(des, cadena, 100) > 0)
        printf("Leido: %s \n", cadena);

    close(des);
    printf("Finaliza lector\n");
    unlink("tuberia");
}
