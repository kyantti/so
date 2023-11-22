#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>

void print_message(const char* role, pid_t pid, pid_t parent_pid) {
    printf("I'm the %s (PID: %d), Parent PID: %d\n", role, pid, parent_pid);
}

int main() {
    pid_t great_grandfather_pid, grandfather_pid, father_pid, son_pid;

    // Great Grandfather
    great_grandfather_pid = getpid();
    print_message("Great Grandfather", great_grandfather_pid, getppid());

    // Grandfather
    grandfather_pid = fork();

    if (grandfather_pid < 0) {
        // Fork failed
        perror("Fork failed");
        exit(EXIT_FAILURE);
    } else if (grandfather_pid == 0) {
        // Child process (grandfather)
        print_message("Grandfather", getpid(), getppid());

        // Father
        father_pid = fork();

        if (father_pid < 0) {
            // Fork failed
            perror("Fork failed");
            exit(EXIT_FAILURE);
        } else if (father_pid == 0) {
            // Child process (father)
            print_message("Father", getpid(), getppid());

            // Son
            son_pid = fork();

            if (son_pid < 0) {
                // Fork failed
                perror("Fork failed");
                exit(EXIT_FAILURE);
            } else if (son_pid == 0) {
                // Child process (son)
                print_message("Son", getpid(), getppid());
            } else {
                // Father process
                printf("Father (PID: %d) is going to have a son called Son (PID: %d)\n", getpid(), son_pid);
                wait(NULL); // Wait for the son to finish
            }
        } else {
            // Grandfather process
            printf("Grandfather (PID: %d) is going to have a son called Father (PID: %d)\n", getpid(), father_pid);
            wait(NULL); // Wait for the father to finish
        }
    } else {
        // Great Grandfather process
        printf("Great Grandfather (PID: %d) is going to have a son called Grandfather (PID: %d)\n", getpid(), grandfather_pid);
        wait(NULL); // Wait for the grandfather to finish
    }

    return 0;
}
