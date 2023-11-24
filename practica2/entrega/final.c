#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define ROWS 15
#define COLS 10

// Function prototypes
int level_two_process(int (*matrix)[COLS], int start_row, int end_row);
int level_three_process(int (*matrix)[COLS], int row);

int main()
{
    int matrix[ROWS][COLS];
    pid_t pid;

    /* Create the matrix
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            matrix[i][j] = i * COLS + j;
        }
    }*/

    // Create 3 level two child processes
    for (int i = 0; i < 3; i++)
    {
        pid = fork();

        if (pid < 0)
        {
            printf("Fork failed.\n");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            pid = level_two_process(matrix, i * 5, (i + 1) * 5);
            exit(EXIT_SUCCESS);
        }
        else
        {
            printf("Proceso padre con ID %d, padre ID %d\n", getpid(), getppid());
            wait(NULL);
        }
    }

    // Parent process

    // Print the final result
    printf("Final result in the main process:\n");
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            printf("%d ", matrix[i][j]);
        }
        printf("\n");
    }
    // Add your parent process logic here

    return 0;
}

// Function definitions
int level_two_process(int (*matrix)[COLS], int start_row, int end_row)
{
    pid_t pid;

    printf("Soy el proceso hijo de nivel 2 %d, mi padre es %d y me voy a encargar de las filas %d a %d\n", getpid(), getppid(), start_row, end_row);

    // Create a new process for each row
    for (int i = start_row; i < end_row; i++)
    {
        pid = fork();

        if (pid < 0)
        {
            printf("Fork failed.\n");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            pid = level_three_process(matrix, i);
            exit(EXIT_SUCCESS);
        }
        else
        {
            wait(NULL);
        }
    }
    return 0;
}

int level_three_process(int (*matrix)[COLS], int row)
{
    printf("Soy el proceso hijo de nivel 3 %d, mi padre es %d y me voy a encargar de la fila %d\n", getpid(), getppid(), row);

    // Access matrix[row] in level_three_process
    for (int j = 0; j < COLS; j++)
    {
        matrix[row][j] = row * COLS + j;
    }

    printf("Row %d: ", row);
    // Print the initialized row
    for (int j = 0; j < COLS; j++)
    {
        printf("%d ", matrix[row][j]);
    }
    printf("\n");

    // Add your level three process logic here

    return 0;
}
