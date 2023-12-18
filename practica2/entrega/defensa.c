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
#include <time.h>

#define ROWS 15
#define COLS 1000
#define NUM_N2_CHILDS 3
#define N1_FILENAME "n1/N1_%d.primos"
#define N2_FILENAME "n2/N2_%d.primos"
#define N3_FILENAME "n3/N3_%d.primos"

int matrix[ROWS][COLS];
int pipe_fd[2];
char filename[50];

void level_two_process(int *total_primes, int start_row, int end_row);
int is_prime(int num);
void sigusr1_signal_handler(int signum);
void sigint_signal_handler(int signum);
void sigusr2_signal_handler(int signum);

int main()
{
    FILE *file;
    key_t key;
    int shmid;
    int *total_primes;
    struct sigaction sa;
    int start_row;
    int end_row;
    pid_t pid;
    pid_t child_pids[NUM_N2_CHILDS];
    int result;
    int i;
    
    // Si existen, elimino los directorios de salida y sus archivos
    system("rm -rf n1 n2 n3");
    system("mkdir n1 n2 n3");

    // Creo el archivo de salida y escribo la primera linea
    sprintf(filename, N1_FILENAME, getpid());
    file = fopen(filename, "a");
    fprintf(file, "Inicio de ejecucion\n");
    fclose(file);

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

    // Inicializar la semilla para la generación de números aleatorio
    srand((unsigned int)time(NULL));
    // Inicializo la matriz
    for (i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            matrix[i][j] = rand() % 30001;
        }
    }

    // Inicializo el total de primos de cada hijo a 0
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        total_primes[i] = 0;
    }

    // Creo 3 procesos de nivel 2
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        start_row = i * ROWS / NUM_N2_CHILDS;
        end_row = start_row + 4;

        pid = fork();
        if (pid < 0)
        {
            perror("Error creating level 2 child process");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            // Armado de señal SIGINT
            sa.sa_handler = sigint_signal_handler;
            sigemptyset(&sa.sa_mask);
            sa.sa_flags = 0;
            sigaction(SIGINT, &sa, NULL);

            sa.sa_handler = sigusr2_signal_handler;
            sigemptyset(&sa.sa_mask);
            sa.sa_flags = 0;
            sigaction(SIGUSR2, &sa, NULL);

            level_two_process(total_primes, start_row, end_row);
            sleep(1);
            exit(0);
        }
        else
        {
            child_pids[i] = pid;
            file = fopen(filename, "a");
            fprintf(file, "He creado el proceso hijo %d para encargarse de las filas %d a %d\n", pid, start_row, end_row);
            fclose(file);
        }
    }
    usleep(500);
    int p;
    wait(&p);
    wait(&p);
    wait(&p);

    // Calculo el total de primos
    result = 0;
    for (i = 0; i < NUM_N2_CHILDS; i++)
    {
        result += total_primes[i];
    }

    // Antes de terminar el padre libera el puntero a memoria compartida
    shmdt(total_primes);

    // Elimina la zona de memoria compartida
    shmctl(shmid, IPC_RMID, 0);

    file = fopen(filename, "a");
    fprintf(file, "Resultado total: %d\n", result);
    fclose(file);

    return 0;
}

// Cada proceso de nivel 2 se encarga de crear un proceso de nivel 3 para cada fila y esperar a que terminen de ejecutarse para obtener el total de primos y enviarlo al proceso padre.
void level_two_process(int *total_primes, int start_row, int end_row)
{
    int child_index;
    int i;
    FILE *file;
    int pid;
    int child_pids[ROWS];
    int child_status = 0;
    int ppid = getppid();
    int hijo;
    int N2 = getpid();

    // Calculo el indice del hijo para saber a que posicion del array de primos enviar el resultado
    child_index = start_row / (ROWS / NUM_N2_CHILDS);

    // Creo un proceso de nivel 3 para cada fila
    for (i = start_row; i <= end_row; i++)
    {
        pid = fork();
        if (pid < 0)
        {
            perror("Error creating level 3 child process");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            write(pipe_fd[1], &i, sizeof(int));
            usleep(100);
            kill(getppid(), SIGUSR2);

            int prime_count = 0;
            char filename1[50];
            FILE *file1;
            sprintf(filename1, N3_FILENAME, getpid());
            file1 = fopen(filename1, "a");

            for (int j = 0; j < COLS; j++)
            {
                if (is_prime(matrix[i][j]))
                {
                    prime_count++;
                    fprintf(file1, "Nivel: %d, ID de proceso:%d, Primos:%d\n", 3, getpid(), matrix[i][j]);
                }
            }
            fclose(file1);
            // Salgo con el número de primos encontrados
            exit(prime_count);
        }
        else
        {
            // Guardo el pid del hijo para luego escribirlo en el archivo de salida
            child_pids[i] = pid;
        }
    }

    // Espero a que los hijos de nivel 3 terminen de ejecutarse
    for (i = 0; i < 5; i++)
    {
        //  Espero a que el hijo termine de ejecutarse y obtengo su estado
        hijo = wait(&child_status);
        //  Verifico que el hijo haya terminado exitosamente
        if (WIFEXITED(child_status))
        {
            total_primes[child_index] += WEXITSTATUS(child_status);
        }
    }

    // Escribo en el archivo de salida
    sprintf(filename, N2_FILENAME, getpid());
    file = fopen(filename, "a");
    fprintf(file, "Inicio de ejecucion\n");
    for (i = start_row; i <= end_row; i++)
    {
        fprintf(file, "He creado el proceso hijo %d para encargarse de la fila %d\n", child_pids[i], i);
    }
    fprintf(file, "Resultado total enviado por sus hijos: %d\n", total_primes[child_index]);
    fclose(file);

    // Envio una comunicación por tuberia al padre con el pid del hijo para avisarle que se ha actualizado la memoria compartida
    write(pipe_fd[1], &N2, sizeof(int));
    usleep(100);

    // Envio la señal SIGUSR1 (indice del que leer) al padre notificando que ya puede leer de la tuberia
    kill(ppid, SIGUSR1);
    usleep(100);

    // Espero a que el padre lea los primos enviados
    while (1)
    {
        pause();
    }
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
    int child_pid;
    FILE *file;
    sprintf(filename, N1_FILENAME, getpid());
    read(pipe_fd[0], &child_pid, sizeof(int));
    printf("Leyendo el pid %d por la tuberia\n", child_pid);
    file = fopen(filename, "a");
    fprintf(file, "He recibido la señal SIGUSR1 del proceso hijo %d y se envia SIGINT.\n", child_pid);
    fclose(file);
    kill(child_pid, SIGINT);
    usleep(100);  

}

void sigint_signal_handler(int signum)
{
    usleep(100);
    exit(EXIT_SUCCESS);
}

void sigusr2_signal_handler(int signum)
{
    int i;
    read(pipe_fd[0], &i, sizeof(int));
    printf("Soy el proceso de nivel 2: %d y mi quinto hijo: %d ya esta trabajando\n", getpid(), i);
    usleep(100);  
}

