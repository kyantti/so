/* Comunicación mediante memoria compartida. Crear un proceso, que guardará 10 valores aleatorios en memoria compartida, a los que el proceso padre también podrá acceder */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/shm.h>
#include <sys/wait.h>


int main(int argc, char *argv[])
{
  int pid,estado,i;
  int valor=5;               // Variable a modificar por el hijo 
  int valor_leido=0;
  srand(time(NULL));

  key_t key;       // Clave a obtener con ftok
  long int shmid;    // Identificador de memoria a obtener con shmget    
  int *puntero=NULL; // Puntero memoria compartida a obtener con shmat

  printf("Soy el proceso %d y voy a crear un proceso nuevo\n",getpid());

  // Crear memoria compartida para comunicar proceso padre e hijo, en este caso
  key=ftok("/bin/cat",121);					// Obtención de clave unica
  shmid=shmget(key,sizeof(int)*10,0777|IPC_CREAT); // Reserva de espacio 10 valores enteros y 
						   // devuelve un identificador
  puntero=(int *)shmat(shmid,(char *)0,0);	   // Obtiene el puntero a la 1ª posición
						  // cada posición puede ser accedida como puntero[i]
  pid=fork();  // Crear proceso nuevo
  switch (pid) {
   case -1:
           printf("Error\n");
           break;
   case 0: //Código que ejecuta sólo el proceso hijo
         printf("Proceso hijo: %d, con padre : %d y genero información para el\n",getpid(),getppid());
         for (i=0;i<10;i++)
           {
            puntero[i]=rand()%100;  
            printf("Generado %d: %d \n",i, puntero[i]);  
           } 
         shmdt((char *) puntero); // Antes de finaliza el hijo libera el puntero a memoria compartida  
         exit(220);
	 break;
   default: // Código que ejecuta solo el proceso padre
           wait(&estado);    // Espera a que finalice el primer proceso hijo que lo haga
           if (estado==0)
	      printf("Proceso hijo finalizado normalmente\n");  // Comprueba el motivo de finalización
	    else { 
              if (WIFEXITED(estado)) printf("Hijo finaliza con EXIT(%d)\n",WEXITSTATUS(estado));
	      if (WIFSIGNALED(estado)) printf("Hijo finaliza por señal %d recibida\n",WTERMSIG(estado));
	    }
           printf("Padre: %d, leo información enviada por mi hijo \n",getpid());
           for (i=0;i<10;i++)
              printf("Memoria[%d]: %d\n",i, puntero[i]);  
           printf("Padre: %d finalizo y devuelvo el control al sistema\n",getpid());
           break;
       }
 shmdt((char*)puntero); //Antes de terminar el padre libera el puntero a memoria compartida
 shmctl(shmid,IPC_RMID,0); //Elimina la zona de memoria compartida
 exit(0); //Finaliza el programa
}
