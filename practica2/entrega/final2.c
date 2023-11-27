#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#define ROWS 15
#define COLS 10

// Function prototypes
void level_two_process(int shmid, int start_row, int end_row);
void level_three_process(int shmid, int row, int process_id);
int is_prime(int num);

int main()
{
    int shmid;
    int *matrix;
    pid_t pid;
    int start_row;
    int end_row;

    // Create shared memory segment for the matrix
    shmid = shmget(IPC_PRIVATE, sizeof(int) * ROWS * COLS, IPC_CREAT | 0666);
    if (shmid == -1)
    {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    // Attach the shared memory segment
    matrix = shmat(shmid, NULL, 0);
    if (matrix == (int *)-1)
    {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

    // Initialize the matrix in the main process
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            matrix[i * COLS + j] = i * COLS + j;
        }
    }

    // Create 3 level two child processes
    for (int i = 0; i < 3; i++)
    {
        start_row = i * 5;
        end_row = (i + 1) * 5 - 1;

        pid = fork();

        if (pid < 0)
        {
            printf("Fork failed.\n");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            level_two_process(shmid, start_row, end_row);
            exit(EXIT_SUCCESS);
        }
        else
        {
            printf("Proceso padre con ID %d, padre ID %d\n", getpid(), getppid());
            wait(NULL);
        }
    }

    // Parent process

    // Detach the shared memory segment
    if (shmdt(matrix) == -1)
    {
        perror("shmdt");
        exit(EXIT_FAILURE);
    }

    // Remove the shared memory segment
    if (shmctl(shmid, IPC_RMID, NULL) == -1)
    {
        perror("shmctl");
        exit(EXIT_FAILURE);
    }

    return 0;
}

// Function definitions
void level_two_process(int shmid, int start_row, int end_row)
{
    // Attach the shared memory segment
    int *matrix = shmat(shmid, NULL, 0);
    pid_t pid;
    int total_primes = 0;
    int child_status = 0;

    if (matrix == (int *)-1)
    {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

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
            level_three_process(shmid, i, getpid());
            // No es necesario salir aquí, ya que level_three_process manejará la salida
        }
        else
        {
            // Espero a que el hijo termine de ejecutarse y obtengo su estado
            wait(&child_status);

            // Verifico que el hijo haya terminado exitosamente
            if (WIFEXITED(child_status))
            {
                total_primes += WEXITSTATUS(child_status);
            }

        }
    }

    printf("Soy el proceso hijo de nivel 2 %d. Mis 5 hijos han encontrado un total de %d numeros primos\n", getpid(), total_primes);
}

void level_three_process(int shmid, int row, int process_id)
{
    // Attach the shared memory segment
    int *matrix = shmat(shmid, NULL, 0);
    int prime_count = 0;
    char filename[50];

    if (matrix == (int *)-1)
    {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

    // Access matrix[row] in level_three_process and count prime numbers
    for (int j = 0; j < COLS; j++)
    {
        if (is_prime(matrix[row * COLS + j]))
        {
            prime_count++;

            // Store the prime number in the file
            sprintf(filename, "N3_%d.cousins", getpid());
            FILE *file = fopen(filename, "a");
            fprintf(file, "level:%d:process_id:%d:cousin_num:%d\n", 3, process_id, matrix[row * COLS + j]);
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
