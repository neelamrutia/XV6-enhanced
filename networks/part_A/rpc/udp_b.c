#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main(int argc, char **argv)
{

  if (argc != 2)
  {
    printf("Usage: %s <port>\n", argv[0]);
    exit(0);
  }

  char *ip = "127.0.0.1";
  int port = atoi(argv[1]);

  int sockfd;
  struct sockaddr_in addr;
  char buffer[1024];
  socklen_t addr_size;

  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  memset(&addr, '\0', sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = inet_addr(ip);

  // bzero(buffer, 1024);
  // strcpy(buffer, "Hello, World!");
  // sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, sizeof(addr));
  // printf("[+]Data send: %s\n", buffer);

  while (1)
  {
    bzero(buffer, 1024);
    printf("Client: ");
    fgets(buffer, 1024, stdin);
    int y = sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, sizeof(addr));
    if (y < 0)
    {
      perror("[-]sendto error");
      exit(1);
    }
    //printf("[+]Data send: %s\n", buffer);
    bzero(buffer, 1024);
    addr_size = sizeof(addr);
    ssize_t t3 = recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size);
    if (t3 <= 0)
    {
      perror("[-]Error in receiving data.");
      exit(1);
    }
    printf("[+]Data recv: %s", buffer);
  }

  bzero(buffer, 1024);
  addr_size = sizeof(addr);
  ssize_t t4 =recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size);
  if (t4 <= 0)
  {
    perror("[-]Error in receiving data.");
    exit(1);
  }
  printf("[+]Data recv: %s\n", buffer);
  
  return 0;
}