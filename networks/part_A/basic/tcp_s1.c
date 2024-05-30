#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{

  char *ip = "127.0.0.1";
  int port = 5561;

  int server_sock, client_sock;
  struct sockaddr_in server_addr, client_addr;
  socklen_t addr_size;
  char buffer[1024];
  int n;

  server_sock = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock < 0)
  {
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket created.\n");

  memset(&server_addr, '\0', sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_port = port;
  server_addr.sin_addr.s_addr = inet_addr(ip);

  n = bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
  if (n < 0)
  {
    perror("[-]Bind error");
    exit(1);
  }
  printf("[+]Bind to the port number: %d\n", port);
  int p = listen(server_sock, 5);
  if (p < 0)
  {
    perror("[-]Listen error");
    exit(1);
  }
  printf("Listening...\n");

  while (1)
  {
    addr_size = sizeof(client_addr);
    client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &addr_size);
    if (client_sock < 0)
    {
      perror("[-]Accept error");
      exit(1);
    }
    printf("[+]Client connected.\n");
    bzero(buffer, 1024);
    strcpy(buffer, "HI, THIS IS SERVER. HAVE A NICE DAY!!!");
    printf("Server: %s\n", buffer);
    // send(client_sock, buffer, strlen(buffer), 0);
    while (1)
    {
      bzero(buffer, 1024);
      int aa = recv(client_sock, buffer, sizeof(buffer), 0);
      if (aa <= 0)
      {
        perror("[-]Error in receiving data.");
        exit(1);
      }
      printf("Client: %s", buffer);
      if (strncmp(buffer, "exit", 4) == 0)
      {
        printf("[-]Disconnected from %s:%d\n", inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
        break;
      }
      // printf("1\n");
    }
    close(client_sock);
    printf("[+]Client disconnected.\n\n");
  }
  return 0;
}