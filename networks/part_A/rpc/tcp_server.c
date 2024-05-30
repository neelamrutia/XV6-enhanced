#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{

    char *ip = "127.0.0.1";
    int port1 = 5561;
    int port2 = 5562;

    int server_sock, client_sock;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    int server_sock1, client_sock1;
    struct sockaddr_in server_addr1, client_addr1;
    socklen_t addr_size1;
    char buffer1[1024];
    int n1;

    server_sock1 = socket(AF_INET, SOCK_STREAM, 0);
    server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    if (server_sock < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP server socket created.\n");

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = port1;
    server_addr.sin_addr.s_addr = inet_addr(ip);

    memset(&server_addr1, '\0', sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = port2;
    server_addr1.sin_addr.s_addr = inet_addr(ip);

    n = bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
    n1 = bind(server_sock1, (struct sockaddr *)&server_addr1, sizeof(server_addr1));
    if (n < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }
    if (n1 < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }
    printf("[+]Bind to the port numbers: %d %d\n", port1, port2);

    int gg = listen(server_sock, 5);
    int gg1 = listen(server_sock1, 5);
    if (gg < 0)
    {
        perror("[-]Listen error");
        exit(1);
    }
    if (gg1 < 0)
    {
        perror("[-]Listen error");
        exit(1);
    }
    printf("Listening...\n");
    while (1)
    {
        addr_size = sizeof(client_addr);
        addr_size1 = sizeof(client_addr1);
        client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &addr_size);
        client_sock1 = accept(server_sock1, (struct sockaddr *)&client_addr1, &addr_size1);
        if (client_sock < 0)
        {
            perror("[-]Accept error in a");
            exit(1);
        }
        if (client_sock1 < 0)
        {
            perror("[-]Accept error in b");
            exit(1);
        }
        printf("[+]Clients connected.\n");
        bzero(buffer, 1024);
        bzero(buffer1, 1024);
        strcpy(buffer, "HI, THIS IS SERVER. HAVE A NICE DAY!!!");
        strcpy(buffer1, "HI, THIS IS SERVER. HAVE A NICE DAY!!!");
        printf("Server: %s\n", buffer);
        printf("Server: %s\n", buffer1);
        // send(client_sock, buffer, strlen(buffer), 0);
        while (1)
        {
            bzero(buffer, 1024);
            bzero(buffer1, 1024);
            int aa = recv(client_sock, buffer, sizeof(buffer), 0);
            int bb = recv(client_sock1, buffer1, sizeof(buffer1), 0);
            if (bb <= 0)
            {
                perror("[-]Error in receiving data.");
                exit(1);
            }
            if (aa <= 0)
            {
                perror("[-]Error in receiving data.");
                exit(1);
            }
            printf("Client: %s", buffer);
            printf("Client: %s", buffer1);
            // play rock paper scissors
            if (strncmp(buffer, "rock", 4) == 0 && strncmp(buffer1, "rock", 4) == 0)
            {
                send(client_sock, "Draw\n", 5, 0);
                send(client_sock1, "Draw\n", 5, 0);
            }
            else if (strncmp(buffer, "rock", 4) == 0 && strncmp(buffer1, "paper", 5) == 0)
            {
                send(client_sock, "Lose\n", 14, 0);
                send(client_sock1, "Win\n", 14, 0);
            }
            else if (strncmp(buffer, "rock", 4) == 0 && strncmp(buffer1, "scissors", 8) == 0)
            {
                send(client_sock, "Win\n", 14, 0);
                send(client_sock1, "Lose\n", 14, 0);
            }
            else if (strncmp(buffer, "paper", 5) == 0 && strncmp(buffer1, "rock", 4) == 0)
            {
                send(client_sock, "Win\n", 14, 0);
                send(client_sock1, "Lose\n", 14, 0);
            }
            else if (strncmp(buffer, "paper", 5) == 0 && strncmp(buffer1, "paper", 5) == 0)
            {
                send(client_sock, "Draw\n", 14, 0);
                send(client_sock1, "Draw\n", 14, 0);
            }
            else if (strncmp(buffer, "paper", 5) == 0 && strncmp(buffer1, "scissors", 8) == 0)
            {
                send(client_sock, "Lose\n", 14, 0);
                send(client_sock1, "Win\n", 14, 0);
            }
            else if (strncmp(buffer, "scissors", 8) == 0 && strncmp(buffer1, "rock", 4) == 0)
            {
                send(client_sock, "Lose\n", 14, 0);
                send(client_sock1, "Win\n", 14, 0);
            }
            else if (strncmp(buffer, "scissors", 8) == 0 && strncmp(buffer1, "paper", 5) == 0)
            {
                send(client_sock, "Win\n", 14, 0);
                send(client_sock1, "Lose\n", 14, 0);
            }
            else if (strncmp(buffer, "scissors", 8) == 0 && strncmp(buffer1, "scissors", 8) == 0)
            {
                send(client_sock, "Draw\n", 14, 0);
                send(client_sock1, "Draw\n", 14, 0);
            }
            else
            {
                printf("Invalid input\n");
            }
            if (strncmp(buffer, "exit", 4) == 0)
            {
                printf("[-]Disconnected from %s:%d\n", inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
                break;
            }
            if (strncmp(buffer1, "exit", 4) == 0)
            {
                printf("[-]Disconnected from %s:%d\n", inet_ntoa(client_addr1.sin_addr), ntohs(client_addr1.sin_port));
                break;
            }
            // printf("1\n");
        }
        close(client_sock);
        close(client_sock1);
        printf("[+]Client disconnected.\n\n");
    }
    return 0;
}