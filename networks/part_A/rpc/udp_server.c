#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main(int argc, char **argv)
{

    if (argc != 3)
    {
        printf("Usage: %s <port>\n", argv[0]);
        exit(0);
    }

    char *ip = "127.0.0.1";
    int port = atoi(argv[1]);
    int port1 = atoi(argv[2]);

    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    char buffer[1024];
    socklen_t addr_size;
    int n;

    int sockfd1;
    struct sockaddr_in server_addr1, client_addr1;
    char buffer1[1024];
    socklen_t addr_size1;
    int n1;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    sockfd1 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("[-]socket error");
        exit(1);
    }
    if (sockfd1 < 0)
    {
        perror("[-]socket error");
        exit(1);
    }

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    memset(&server_addr1, '\0', sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = htons(port1);
    server_addr1.sin_addr.s_addr = inet_addr(ip);

    n = bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
    n1 = bind(sockfd1, (struct sockaddr *)&server_addr1, sizeof(server_addr1));
    if (n < 0)
    {
        perror("[-]bind error");
        exit(1);
    }
    if (n1 < 0)
    {
        perror("[-]bind error");
        exit(1);
    }

    while (1)
    {
        bzero(buffer, 1024);
        bzero(buffer1, 1024);
        addr_size = sizeof(client_addr);
        addr_size1 = sizeof(client_addr1);
        int f =recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, &addr_size);
        int f1 = recvfrom(sockfd1, buffer1, 1024, 0, (struct sockaddr *)&client_addr1, &addr_size1);
        if (f <= 0)
        {
            perror("[-]Error in receiving data.");
            exit(1);
        }
        if (f1 <= 0)
        {
            perror("[-]Error in receiving data.");
            exit(1);
        }
        printf("[+]Data recv: %s", buffer);
        printf("[+]Data recv: %s", buffer1);
        // play rock paper scissors
        if (strncmp(buffer, "rock", 4) == 0 && strncmp(buffer1, "rock", 4) == 0)
        {
            sendto(sockfd, "Draw\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Draw\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "rock", 4) == 0 && strncmp(buffer1, "paper", 5) == 0)
        {
            sendto(sockfd, "Lose\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Win\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "rock", 4) == 0 && strncmp(buffer1, "scissors", 8) == 0)
        {
            sendto(sockfd, "Win\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Lose\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "paper", 5) == 0 && strncmp(buffer1, "rock", 4) == 0)
        {
            sendto(sockfd, "Win\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Lose\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "paper", 5) == 0 && strncmp(buffer1, "paper", 5) == 0)
        {
            sendto(sockfd, "Draw\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Draw\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "paper", 5) == 0 && strncmp(buffer1, "scissors", 8) == 0)
        {
            sendto(sockfd, "Lose\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Win\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "scissors", 8) == 0 && strncmp(buffer1, "rock", 4) == 0)
        {
            sendto(sockfd, "Lose\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Win\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "scissors", 8) == 0 && strncmp(buffer1, "paper", 5) == 0)
        {
            sendto(sockfd, "Win\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Lose\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        }
        else if (strncmp(buffer, "scissors", 8) == 0 && strncmp(buffer1, "scissors", 8) == 0)
        {
            sendto(sockfd, "Draw\n", 5, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            sendto(sockfd1, "Draw\n", 5, 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
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
    }
    return 0;
}