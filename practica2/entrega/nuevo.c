#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <fcntl.h>
#include <sys/stat.h>

#define ROWS 15
#define COLS 10
#define NUM_N2_CHILDS 3
#define NUM_N3_CHILDS 15
#define N1_FILENAME "nuevo/n1/N1_%d.primos"
#define N2_FILENAME "nuevo/n2/N2_%d.primos"
#define N3_FILENAME "nuevo/n3/N3_%d.primos"

int pipe_fd[2];
char filename[50];

int is_prime(int num);
void sigusr1_signal_handler(int signum);
void sigint_signal_handler(int signum);

int main()
{
    char filename[50];
    FILE *file;
    key_t key;
    int shmid;
    int *total_primes;
    struct sigaction sa;
    size_t i;
    size_t j;
    int matrix[ROWS][COLS];
    int start_row;
    int end_row;
    pid_t p;
    pid_t p2;
    pid_t n1_pid = getpid();
    pid_t n2_pids[NUM_N2_CHILDS];
    size_t n2_index;
    pid_t n3_pids[NUM_N3_CHILDS];
    int result = 0;

    // Si existen, elimino los directorios de salida y sus archivos
    system("rm -rf n1 n2 n3");
    system("mkdir n1 n2 n3");

    // Creo el archivo de salida y escribo la primera linea
    sprintf(filename, N1_FILENAME, getpid());
    file = fopen(filename, "a");
    fprintf(file, "Inicio de ejecucion\n");

    // Obtencion de la clave unica
    key = ftok("/bin/cat", 250);

    // Reserva de espacio 3 valores enteros y devuelve un identificador
    shmid = shmget(key, sizeof(int) * 3, 0777 | IPC_CREAT);

    // Obtiene un puntero a la 1ª posición. Cada posición puede ser accedida como puntero[i]
    total_primes = (int *)shmat(shmid, (char *)0, 0);

    // Creo la tuberia
    pipe(pipe_fd);

    // Armado de señal SIGUSR1 para leer de la tuberia
    sa.sa_handler = sigusr1_signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGUSR1, &sa, NULL);

    // Inicializo la matriz
    for (i = 0; i < ROWS; i++)
    {
        for (j = 0; j < COLS; j++)
        {
            matrix[i][j] = i * COLS + j;
        }
    }

    // Inicializo el total de primos de cada hijo a 0
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        total_primes[i] = 0;
    }

    // Creo los hijos
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        start_row = i * ROWS / NUM_N2_CHILDS;
        end_row = start_row + 4;
        p = fork();
        if (p < 0)
        {
            perror("Error creating level 2 child process");
            exit(EXIT_FAILURE);
        }
        else if (p == 0)
        {
            pid_t hijo;
            int child_status;

            // Armado de señal SIGINT
            sa.sa_handler = sigint_signal_handler;
            sigemptyset(&sa.sa_mask);
            sa.sa_flags = 0;
            sigaction(SIGUSR2, &sa, NULL);

            n2_pids[i] = getpid();

            for (j = start_row; j < end_row; j++)
            {
                p2 = fork();
                if (p2 < 0)
                {
                    perror("Error creating level 3 child process");
                    exit(EXIT_FAILURE);
                }
                else if (p2 == 0)
                {
                    n3_pids[j] = getpid();
                    int prime_count = 0;
                    FILE *file3;
                    sprintf(filename, N3_FILENAME, getpid());
                    file3 = fopen(filename, "a");
                    for (size_t k = 0; k < COLS; k++)
                    {
                        if (is_prime(matrix[j][k]))
                        {
                            prime_count++;
                            fprintf(file3, "%d ", matrix[j][k]);
                        }
                    }
                    fclose(file3);
                    // Salgo con el numero de primos que he encontrado
                    exit(prime_count);
                }
            }
            // Espero a que los hijos de nivel 3 hagan su tarea
            for (j = start_row; j < end_row; j++)
            {
                //  Espero a que el hijo termine de ejecutarse y obtengo su estado
                hijo = wait(&child_status);
                //  Verifico que el hijo haya terminado exitosamente
                if (WIFEXITED(child_status))
                {
                    total_primes[i] += WEXITSTATUS(child_status);
                }
            }

            // Escribo en el archivo de salida
            sprintf(filename, N2_FILENAME, getpid());
            file = fopen(filename, "a");
            fprintf(file, "Inicio de ejecucion\n");
            for (j = start_row; j <= end_row; j++)
            {
                fprintf(file, "He creado el proceso hijo %d para encargarse de la fila %d\n", n3_pids[j], j);
            }
            fprintf(file, "Resultado total enviado por sus hijos: %d\n", total_primes[i]);
            fclose(file);

            // Envio el total de primos al padre a través de la tuberia junto con el pid del proceso
            write(pipe_fd[1], &n2_pids[i], sizeof(int));
            usleep(100);

            // Envio la señal SIGUSR1 (indice del que leer) al padre notificando que ya puede leer de la tuberia
            kill(n1_pid, SIGUSR1);
            usleep(100);

            while (1)
            {
                pause();
            }
        }
        else
        {
            fprintf(file, "He creado el proceso hijo %d para encargarse de las filas %d a %d\n", n2_pids[i], start_row, end_row);
        }
    }
    usleep(500);
    
    // Espero a que los hijos de nivel 2 terminen de ejecutarse
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        wait(NULL);
    }

    // Calculo el total de primos
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        result += total_primes[i];
    }

    // Antes de terminar el padre libera el puntero a memoria compartida
    shmdt(total_primes);

    // Elimina la zona de memoria compartida
    shmctl(shmid, IPC_RMID, 0);

    // Escribo en el archivo de salida
    fprintf(file, "Resultado total: %d\n", result);
    fclose(file);

    return 0;
}

int is_prime(int num)
{
    if (num < 2)
    {
        return 0;
    }
    for (int i = 2; i * i <= num; i++)
    {
        if (num % i == 0)
        {
            return 0;
        }
    }
    return 1;
}

void sigusr1_signal_handler(int signum)
{
    char cadena[100];
    pid_t child_pid;
    sprintf(filename, N1_FILENAME, getpid());

    read(pipe_fd[0], &child_pid, sizeof(int));

    sprintf(cadena, "echo He recibido la señal SIGUSR1 del proceso hijo %d y se envia SIGINT. >> %s", child_pid, filename);
    system(cadena);

    kill(child_pid, SIGUSR2);
    usleep(100);
}

void sigint_signal_handler(int signum)
{
    usleep(100);
    exit(EXIT_SUCCESS);
}