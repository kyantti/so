#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#define PIPE_NAME "pipe"
#define MESSAGE_SIZE 100
#define NUM_MESSAGES 3

int main() {
    char message[MESSAGE_SIZE];
    int pipeDescriptor;

    // Generate a greeting message with the process ID
    sprintf(message, "Greetings from the writer process with pid= %d\n", getpid());

    // Open the pipe, retrying until successful
    while ((pipeDescriptor = open(PIPE_NAME, O_WRONLY)) == -1) {
        perror("Error opening the pipe. Retrying...");
        sleep(1);
    }

    // Write the message to the pipe multiple times with a delay
    for (int i = 0; i < NUM_MESSAGES; i++) {
        write(pipeDescriptor, message, MESSAGE_SIZE);
        printf("Message written to the pipe\n");
        sleep(1);
    }

    // Close the pipe and indicate the end of the writer process
    close(pipeDescriptor);
    printf("Writer process completed\n");

    return 0;
}
