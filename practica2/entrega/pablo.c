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
#define NUM_CHILDS 3
#define N1_FILENAME "n1/N1_%d.primos"
#define N2_FILENAME "n2/N2_%d.primos"
#define N3_FILENAME "n3/N3_%d.primos"

int matrix[ROWS][COLS];
int pipe_fd[2];
char filename[50];

void level_two_process(int *total_primes, int start_row, int end_row);
void level_three_process(int row);
int is_prime(int num);
void sigusr1_signal_handler(int signum);
void sigint_signal_handler(int signum);

int main()
{
    int shmid;
    struct sigaction sa;
    pid_t pid;
    pid_t child_pids[NUM_CHILDS];
    int start_row;
    int end_row;
    int *total_primes;
    int result;
    key_t key;
//    char filename[50];
    FILE *file;

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

    // Inicializo la matriz
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            matrix[i][j] = i * COLS + j;
        }
    }

    // Inicializo el total de primos de cada hijo a 0
    for (int i = 0; i < NUM_CHILDS; i++)
    {
        total_primes[i] = 0;
    }

    // Creo 3 procesos de nivel 2
    for (int i = 0; i < NUM_CHILDS; i++)
    {
        start_row = i * ROWS/NUM_CHILDS;
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
           sigaction(SIGUSR2, &sa, NULL);

            printf("Proceso de nivel 2 antes %d\n", getpid());
            level_two_process(total_primes, start_row, end_row);
	    sleep(1);
            printf("Proceso de nivel 2 despues %d\n", getpid());
	    exit(0);
        }
        else
        {
            printf("Valor i %d, valor pid %d\n", i, pid);
            child_pids[i] = pid;
            printf("Child_pid %d\n", child_pids[i]);
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
    printf("Terminando\n");

    // Espero a que los hijos de nivel 2 hagan su tarea
    /*for (int i = 0; i < NUM_CHILDS; i++)
    {
        int p = wait(NULL);
        printf("Proceso %d ha acabado su tarea\n", p);
    }
*/
    // Calculo el total de primos
    result = 0;
    for (int i = 0; i < NUM_CHILDS; i++)
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
    struct sigaction sa;
    FILE *file;
    int pid;
    int child_pids[ROWS];
    int child_status = 0;
    char filename[50];
    int ppid=getppid();
    int hijo;
    int N2;

    printf("Soy el proceso de nivel 2 %d\n", getpid());
  
    // Armado de señal SIGINT
    /*sa.sa_handler = sigint_signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGUSR2, &sa, NULL);
    */
    N2=getpid();
    // Calculo el indice del hijo para saber a que posicion del array de primos enviar el resultado
    child_index = start_row / (ROWS / NUM_CHILDS);
    printf("start_row %d end_row %d \n",start_row,end_row);

    // Creo un proceso de nivel 3 para cada fila
    for (int k = start_row; k <= end_row; k++)
    {
        //printf("Indice N3: %d\n", k);
        pid = fork();
        if (pid < 0)
        {
            perror("Error creating level 3 child process");
            exit(EXIT_FAILURE);
        }
        else if (pid == 0)
        {
            // LLamo a la funcion que se encarga de calcular los primos de una fila,
            // no es necesario salir aquí, ya que la propia función manejará la salida
            //level_three_process(k);  

         int prime_count = 0;
         char filename1[50];
         FILE *file1;
         sprintf(filename1, N3_FILENAME, getpid());
         file1 = fopen(filename1, "a");

         for (int j = 0; j < COLS; j++)
          {
           if (is_prime(matrix[k][j]))
             {
               prime_count++;
               fprintf(file1, "Nivel: %d, ID de proceso:%d, Primos:%d\n", 3, getpid(), matrix[k][j]);    
              }
           }
           fclose(file1);
           // Salgo con el número de primos encontrados
           exit(prime_count);
        }
        else
        {
            // Guardo el pid del hijo para luego escribirlo en el archivo de salida
            child_pids[k] = pid;
        }
    }

    // Espero a que los hijos de nivel 3 terminen de ejecutarse
    for (int j = 0; j < 5; j++)
    {
        //  Espero a que el hijo termine de ejecutarse y obtengo su estado
        hijo=wait(&child_status);
	//printf("Termina hijo n3 %d \n", hijo);
        // Verifico que el hijo haya terminado exitosamente
        if (WIFEXITED(child_status))
        {
           total_primes[child_index] += WEXITSTATUS(child_status);
        }
    }

    // Escribo en el archivo de salida
    sprintf(filename, N2_FILENAME, getpid());
    file = fopen(filename, "a");
    fprintf(file, "Inicio de ejecucion\n");
    for (int i = start_row; i <= end_row; i++)
    {
        fprintf(file, "He creado el proceso hijo %d para encargarse de la fila %d\n", child_pids[i], i);
    }
    fprintf(file, "Resultado total enviado por sus hijos: %d\n", total_primes[child_index]);
    fclose(file);

    // Envio el total de primos al padre a través de la tuberia junto con el pid del proceso
    //pid = getpid();
    printf("Enviando el pid %d por la tuberia\n", N2);
    write(pipe_fd[1], &N2, sizeof(int));
    usleep(100);
      
    // Envio la señal SIGUSR1 (indice del que leer) al padre notificando que ya puede leer de la tuberia
    kill(ppid, SIGUSR1);
    usleep(100);

    printf("Proceso hijo de nivel 2 %d: He enviado el total de primos al padre %d y envio SIGUSR1.\n", pid, getppid());

    printf("Adios\n");
    // Espero a que el padre lea los primos enviados
    while (1)
	    pause();
}

// Cada proceso de nivel 3 se encarga de calcular los primos de una fila
void level_three_process(int row)
{
    int prime_count = 0;
    char filename[50];
    FILE *file;
    sprintf(filename, N3_FILENAME, getpid());
    file = fopen(filename, "a");

    for (int j = 0; j < COLS; j++)
    {
        if (is_prime(matrix[row][j]))
        {
            prime_count++;
            fprintf(file, "Nivel: %d, ID de proceso:%d, Primos:%d\n", 3, getpid(), matrix[row][j]);    
        }
    }
    fclose(file);
    // Salgo con el número de primos encontrados
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

void sigusr1_signal_handler(int signum)
{
    //char filename[50];
    char cadena[100];
    pid_t pid;
    int child_pid;
    //sprintf(filename, N1_FILENAME, getpid());
    pid = getpid();

    read(pipe_fd[0], &child_pid, sizeof(int));

    printf("Leyendo el pid %d por la tuberia\n", child_pid);
    
    //printf("Proceso padre %d: He recibido la señal SIGUSR1 del proceso hijo %d y se envia SIGINT.\n", pid, child_pid);
//    sprintf(cadena, "echo He recibido la señal SIGUSR1 del proceso hijo %d y se envia SIGINT. >> %s", child_pid, filename);
  //  system(cadena);
   // usleep(100);  
    kill(child_pid, SIGUSR2);
    usleep(100);  

}

void sigint_signal_handler(int signum)
{
    printf("Hola\n");
    int pid = getpid();
    //int ppid = getppid();
    printf("Proceso hijo de nivel 2 %d. Yo ya he acabado mi tarea\n", pid);
    usleep(100);
    exit(EXIT_SUCCESS);
}
