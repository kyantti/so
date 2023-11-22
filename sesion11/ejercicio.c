#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>

// Variables para las tuberías
int pipefd[2];

// Variables para la recepción de datos en el primer proceso hijo
int receivedData[3];

// Función para manejar la señal SIGUSR1
void handler_SIGUSR1(int signo) {
    // Leer datos del segundo proceso hijo
    for (int i = 0; i < 3; ++i) {
        read(pipefd[0], &receivedData[i], sizeof(receivedData[i]));
        printf("Primer proceso hijo recibió datos del segundo proceso hijo: %d\n", receivedData[i]);
    }

    // Cerrar el extremo de lectura de la tubería
    close(pipefd[0]);

    // Salir del proceso hijo después de recibir todos los datos
    exit(EXIT_SUCCESS);
}

int main() {
    // Variables para almacenar los PID de los procesos hijos
    pid_t pid1, pid2;

    // Crear la tubería
    if (pipe(pipefd) == -1) {
        perror("Error al crear la tubería");
        exit(EXIT_FAILURE);
    }

    // Configurar el manejador de señales para SIGUSR1
    signal(SIGUSR1, handler_SIGUSR1);

    // Crear el primer proceso hijo
    switch ((pid1 = fork())) {
        case -1:
            perror("Error al crear el primer proceso hijo");
            exit(EXIT_FAILURE);
        case 0:  // Código del primer proceso hijo
            // Cerrar el extremo de escritura de la tubería
            close(pipefd[1]);

            // Configurar el manejador de señales para SIGUSR1
            signal(SIGUSR1, handler_SIGUSR1);

            // Esperar a que se reciba la señal SIGUSR1
            pause();

            // Salir del proceso hijo (esta línea nunca se ejecuta)
            exit(EXIT_SUCCESS);
    }

    // Código del proceso padre

    // Cerrar el extremo de lectura de la tubería en el proceso padre
    close(pipefd[0]);

    // Crear el segundo proceso hijo
    switch ((pid2 = fork())) {
        case -1:
            perror("Error al crear el segundo proceso hijo");
            exit(EXIT_FAILURE);
        case 0:  // Código del segundo proceso hijo
            // Cerrar el extremo de lectura de la tubería
            close(pipefd[0]);

            // Generar 3 números aleatorios
            int randomNumbers[3];
            for (int i = 0; i < 3; ++i) {
                randomNumbers[i] = rand();
                printf("Segundo proceso hijo generó un número aleatorio: %d\n", randomNumbers[i]);
            }

            // Enviar los números al primer proceso hijo
            write(pipefd[1], randomNumbers, sizeof(randomNumbers));

            // Cerrar el extremo de escritura de la tubería
            close(pipefd[1]);

            // Enviar la señal SIGUSR1 al primer proceso hijo
            kill(pid1, SIGUSR1);

            // Salir del segundo proceso hijo
            exit(EXIT_SUCCESS);
    }

    // Código del proceso padre

    // Esperar a que ambos procesos hijos terminen
    waitpid(pid1, NULL, 0);
    waitpid(pid2, NULL, 0);

    printf("Proceso padre esperó a que ambos procesos hijos terminaran.\n");

    return 0;
}
