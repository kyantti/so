#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define ROWS 15
#define COLS 1000

int level_two_process(int, int);
int level_three_process(int);

int main()
{
    int matrix[ROWS][COLS];
    pid_t pid;

    // Create the matrix
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            matrix[i][j] = i * COLS + j;
        }
    }

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
            pid = level_two_process(i * 5, (i + 1) * 5);
            exit(EXIT_SUCCESS);
        }
        else
        {
            printf("Proceso padre con ID %d, padre ID %d\n", getpid(), getppid());
            wait(NULL);
        }
    }

    // Parent process

    // Add your parent process logic here

    return 0;
}

int level_two_process(int start_row, int end_row)
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
            pid = level_three_process(i);
            exit(EXIT_SUCCESS);
        }
        else
        {
            wait(NULL);
        }
    }
    return 0;
}

int level_three_process(int row)
{
    printf("Soy el proceso hijo de nivel 3 %d, mi padre es %d y me voy a encargar de la fila %d\n", getpid(), getppid(), row);

    // Add your level three process logic here

    return 0;
}