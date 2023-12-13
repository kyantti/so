/* Programa que crea un proceso hijo; El padre realiza le envía 5 datos generados aletoriamente al hijo;
 el hijo al recibirlo lo muestra en pantalla. El hijo no finaliza hasta que el proceso padre no le envía la señal SIGTERM. */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <time.h>
#include <sys/wait.h>
#include <sys/types.h>

void manejador_senial_sigterm(int);
void manejador_senial_sigint(int);
int descriptores[2];

int main(int argc, char *argv[])
{
	// Las variables declaradas antes de la creación de un proceso, la heredan los hijos con el valor
	// que tengan en ese momento

	struct sigaction a;
	pid_t p;
	int aleatorio, estado;

	if (pipe(descriptores) == -1)
	{
		printf("Error\n");
	}
	

	// creación de la tuberia
	pipe(descriptores);

	// creación proceso nuevo
	p = fork();
	switch (p)
	{
	case -1:
		printf("Error al crear el proceso\n");
		break;
	case 0:
		// armado de las señales en el hijo. Armar señales es lo primero que debe hacer un proceso
		// armado señal SIGTERM para finalizar
		
		a.sa_handler = manejador_senial_sigterm;
		sigemptyset(&a.sa_mask);
		a.sa_flags = 0;
		sigaction(SIGTERM, &a, NULL);

		// armado señal SIGINT para leer de la tuberia
		a.sa_handler = manejador_senial_sigint;
		sigemptyset(&a.sa_mask);
		a.sa_flags = 0;
		sigaction(SIGINT, &a, NULL);

		printf("Proceso hijo: %d ejecutandose \n", getpid());
		sleep(1);
		while (1)
		{
			printf("Hijo:realizando tareas hasta recibir datos del padre\n");
			pause();
		}
		break;
	default:
		srand(getpid()); // inicializar semillas para generar números aleatorios
		printf("Proceso padre: %d va a comenzar a enviar datos al hijo: %d \n", getpid(), p);
		for (int i = 0; i < 5; i++)
		{
			aleatorio = rand() % 1000; // genera número aleatorio entre 0 y 999
			printf("Enviando el dato %d al proceso nuevo %d \n", aleatorio, p);
			write(descriptores[1], &aleatorio, sizeof(aleatorio)); // lo escribe en la tubería
			kill(p, SIGINT);									   // Envío de la señal para sincronizar lectura
			usleep(300);
		}
		printf("Proceso padre: %d ha terminado de enviar datos y envía señao de finalización al hijo: %d \n", getpid(), p);
		sleep(1);
		kill(p, SIGTERM);
		wait(&estado);
		exit(0);
	}
}
void manejador_senial_sigint(int senial)
{
	int dato;
	pid_t pid;
	pid = getpid();
	read(descriptores[0], &dato, sizeof(dato));
	printf("Proceso hijo: %d leyendo el dato %d enviado por el padre\n", pid, dato);
}

void manejador_senial_sigterm(int senial)
{
	int dato;
	pid_t pid, ppid;
	pid = getpid();
	ppid = getppid();
	printf("Proceso hijo: %d recibida señal de finalización de mi padre: %d \n", pid, ppid);
	exit(0);
}
