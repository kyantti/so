#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#define ROWS 15
#define COLS 10
#define NUM_SONS 3

// Define a struct to store matrix and total primes
struct SharedData {
    int matrix[ROWS][COLS];
    int total_primes[NUM_SONS];
};

// Function prototypes
void level_two_process(struct SharedData *shared_data, int start_row, int end_row, int son_index);
void level_three_process(struct SharedData *shared_data, int row, int process_id, int son_index);
int is_prime(int num);

int main()
{
    int shmid;
    struct SharedData *shared_data;
    pid_t pid;
    int start_row;
    int end_row;

    system("rm -r level_2_processes");
    system("rm -r level_3_processes");
    // Create the "level_3_processes" folder using a system command
    system("mkdir level_2_processes");
    system("mkdir level_3_processes");

    // Create shared memory segment for the matrix and total primes
    shmid = shmget(IPC_PRIVATE, sizeof(struct SharedData), IPC_CREAT | 0666);
    if (shmid == -1)
    {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    // Attach the shared memory segment
    shared_data = shmat(shmid, NULL, 0);
    if (shared_data == (struct SharedData *)-1)
    {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

    // Initialize the matrix in the main process
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            shared_data->matrix[i][j] = i * COLS + j;
        }
    }

    // Initialize total primes to zero
    for (int i = 0; i < NUM_SONS; i++)
    {
        shared_data->total_primes[i] = 0;
    }

    // Create 3 level two child processes
    for (int i = 0; i < NUM_SONS; i++)
    {
        start_row = i * (ROWS / NUM_SONS);
        end_row = (i + 1) * (ROWS / NUM_SONS) - 1;

        pid = fork();

        if (pid < 0)
        {
            printf("Fork failed.\n");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            level_two_process(shared_data, start_row, end_row, i);
            exit(EXIT_SUCCESS);
        }
        else
        {
            printf("Proceso padre con ID %d, padre ID %d\n", getpid(), getppid());
            wait(NULL);
        }
    }

    // Parent process

    // Print total primes computed by each son
    printf("Total primes computed by each son:\n");
    for (int i = 0; i < NUM_SONS; i++)
    {
        printf("Son %d: %d primes\n", i + 1, shared_data->total_primes[i]);
    }

    // Detach and remove the shared memory segment
    if (shmdt(shared_data) == -1)
    {
        perror("shmdt");
        exit(EXIT_FAILURE);
    }

    if (shmctl(shmid, IPC_RMID, NULL) == -1)
    {
        perror("shmctl");
        exit(EXIT_FAILURE);
    }

    return 0;
}

// Function definitions
void level_two_process(struct SharedData *shared_data, int start_row, int end_row, int son_index)
{
    pid_t pid;
    int child_status = 0;

    printf("Soy el proceso hijo de nivel 2 %d, mi padre es %d y me voy a encargar de las filas %d a %d\n", getpid(), getppid(), start_row, end_row);

    // Create a new process for each row
    for (int i = start_row; i <= end_row; i++)
    {
        pid = fork();

        if (pid < 0)
        {
            printf("Fork failed.\n");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            level_three_process(shared_data, i, getpid(), son_index);
            // No es necesario salir aquí, ya que level_three_process manejará la salida
        }
        else
        {
            // Espero a que el hijo termine de ejecutarse y obtengo su estado
            wait(&child_status);

            // Verifico que el hijo haya terminado exitosamente
            if (WIFEXITED(child_status))
            {
                shared_data->total_primes[son_index] += WEXITSTATUS(child_status);
            }
        }
    }

    printf("Soy el proceso hijo de nivel 2 %d. Mis 5 hijos han encontrado un total de %d numeros primos\n", getpid(), shared_data->total_primes[son_index]);

    // Write operations to the file "N2_pid.primos"
    char filename[50];
    sprintf(filename, "level_2_processes/N2_%d.primos", getpid());
    FILE *file = fopen(filename, "w");

    fprintf(file, "Inicio de ejecucion\n");
    fprintf(file, "Identificacion de procesos creados: %d, %d, %d, %d, %d\n",getpid() + 1, getpid() + 2, getpid() + 3, getpid() + 4, getpid() + 5);
    fprintf(file, "Resultado total enviado por sus hijos: %d\n", shared_data->total_primes[son_index]);
}

void level_three_process(struct SharedData *shared_data, int row, int process_id, int son_index)
{
    int prime_count = 0;
    char filename[50];

    // Access matrix[row] in level_three_process and count prime numbers
    for (int j = 0; j < COLS; j++)
    {
        if (is_prime(shared_data->matrix[row][j]))
        {
            prime_count++;

            // Store the prime number in the file
            sprintf(filename, "level_3_processes/N3_%d.cousins", getpid());
            FILE *file = fopen(filename, "a");
            fprintf(file, "level:%d:process_id:%d:cousin_num:%d\n", 3, process_id, shared_data->matrix[row][j]);
            fclose(file);
        }
    }

    // Inform the parent process of the number of primes found
    printf("Soy el proceso hijo de nivel 3 %d, mi padre es %d y me voy a encargar de la fila %d\n", getpid(), getppid(), row);
    printf("...\nHe encontrado %d numeros primos\n", prime_count);
    exit(prime_count);
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
