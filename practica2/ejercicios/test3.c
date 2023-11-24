#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    int i;
    pid_t father_pid, child_pid;

    // El padre inicial
    father_pid = getpid();

    // Crear la cadena de 4 procesos
    for (i = 0; i < 4; i++) {
        child_pid = fork();

        // Verificar errores al crear el proceso hijo
        if (child_pid < 0) {
            perror("Error al crear el proceso hijo");
            exit(EXIT_FAILURE);
        }

        // Verificar si es el proceso hijo
        if (child_pid == 0) {
            printf("Proceso hijo %d con ID %d, padre ID %d\n", i + 1, getpid(), father_pid);
            // Aquí puedes realizar las acciones específicas para cada proceso hijo
            exit(EXIT_SUCCESS);
        } else {
            // Esperar al proceso hijo actual antes de crear el siguiente
            wait(NULL);
        }
    }

    return 0;
}
