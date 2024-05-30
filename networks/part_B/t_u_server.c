#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

struct check
{
    int number;
};

struct packet
{
    int seq_no;
    int ack_no;
    char data[1024];
    // int flag;
};

struct node
{
    int ack_no;
    char data[1024];
    time_t start_time;
};

struct node *arr[100000];
int counter = 0;

int no_of_packets_recv = 0;

void *recv_ack(void *arg)
{
    pthread_detach(pthread_self());
    int sockfd = *((int *)arg);
    struct sockaddr_in addr;
    socklen_t addr_size;
    struct packet p;
    while (1)
    {
        int ff = 0;
        for (int i = 0; i < no_of_packets_recv; i++)
        {
            if (arr[i]->ack_no == -10)
            {
                ff = 1;
            }
        }
        if (ff == 0)
        {
            //printf("[-]Connection closed\n");
            break;
        }
        addr_size = sizeof(addr);
        ssize_t n11 = recvfrom(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, &addr_size);
        // printf("\n");
        //printf("[+]Data recv: %s\n", p.data);
        //printf("[+]Seq no: %d\n", p.seq_no);
        arr[p.seq_no]->ack_no = p.ack_no;
        // strcpy(arr[counter]->data, p.data);
        // counter++;
        bzero(p.data, 1024);
        if (ff == 0)
        {
            printf("[-]Connection closed\n");
            break;
        }
    }
    return NULL;
}

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
    struct sockaddr_in server_addr, client_addr;
    char buffer[1024];
    socklen_t addr_size;
    int n;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("[-]socket error");
        exit(1);
    }

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);

    // for (int i = 0; i < 100000; i++)
    // {
    //     arr[i] = (struct node *)malloc(sizeof(struct node));
    // }
    n = bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (n < 0)
    {
        perror("[-]bind error");
        exit(1);
    }
    printf("[+]Server started at port %d\n", port);
    // struct packet p;
    // struct packet no_of_packets;
    int i = 0;
    while (1)
    {
        struct packet p;
        struct packet no_of_packets;
        int seq_no = 0;
        int ack_no = 0;
        char total[1024];
        memset(total, '\0', sizeof(total));
        int p_ack = 0;
        addr_size = sizeof(client_addr);
        struct check c;
        recvfrom(sockfd, &c, sizeof(c), 0, (struct sockaddr *)&client_addr, &addr_size);
        int times = c.number;
        struct packet p2;
        // recvfrom(sockfd, &p2, sizeof(p2), 0, (struct sockaddr *)&client_addr, &addr_size);
        // int times = p2.seq_no;
        // int arr1[times];
        int counter_for_data = 0;
        int for_counter = 0;
        printf("\n");
        printf("[+]Connection established\n");
        printf("[+]No of packets: %d\n", times);
        printf("%d\n", p2.seq_no);
        while (1)
        {

            bzero(buffer, 1024);
            addr_size = sizeof(client_addr);
            ssize_t n11 = recvfrom(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&client_addr, &addr_size);
            if (counter_for_data < times)
            {
                // printf("[+]Data recv: %s\n", p.data);
                strcat(total, p.data);
                counter_for_data++;
            }
            if (n11 == -1)
            {
                printf("Error\n");
                bzero(buffer, 1024);
                continue;
            }
            if (for_counter % 3 == 0)
            {
                //printf("[-]Data packet lost %d\n", p.seq_no);
                //printf("[+]seq no: %d\n", p.seq_no);
                for_counter++;
                continue;
            }
            printf("[-]Data packet received %d\n", p.seq_no);
            // printf("[+]seq no: %d\n", p.seq_no);
            // printf("[+]ack no: %d\n", p.ack_no);
            // printf("[+]Data recv: %s\n", p.data);
            // strcat(total, p.data);
            //  printf("[+]ack no: %d\n", p.ack_no);
            p.ack_no = p.seq_no;
            sendto(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            bzero(buffer, 1024);
            p_ack++;
            if (times == p_ack)
            {
                printf("[-]Connection closed\n");
                break;
            }
            for_counter++;
        }
        printf("from client to server: %s\n", total);
        printf("\n");
        seq_no = 0;
        ack_no = 0;
        // pthread_t tid;
        // pthread_create(&tid, NULL, recv_ack, &sockfd);
        char buffer1[1024];
        bzero(buffer1, 1024);
        printf("Server: ");
        fgets(buffer1, 1024, stdin);
        int i = 0;
        counter = 0;
        for (int i = 0; i < 100000; i++)
        {
            arr[i] = (struct node *)malloc(sizeof(struct node));
            arr[i]->start_time = 0;
            memset(arr[i]->data, '\0', sizeof(arr[i]->data));
            arr[i]->ack_no = -10;
        }
        int len = strlen(buffer1);
        int times1;
        if (len % 10 == 1)
        {
            times1 = len / 10;
        }
        else
        {
            times1 = len / 10;
            times1++;
        }
        int pp = 0;
        // // struct node *arr[100000];
        // // int counter = 0;
        struct check c1;
        c1.number = times1;
        sendto(sockfd, &c1, sizeof(c1), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
        // no_of_packets.seq_no = times1;
        no_of_packets_recv = times1;
        // sendto(sockfd, &no_of_packets, sizeof(no_of_packets), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
        pthread_t tid;
        pthread_create(&tid, NULL, recv_ack, &sockfd);
        seq_no = 0;
        ack_no = 0;
        while (times1--)
        {
            int ff = 0;
            for (i = 0; i < 10; i++)
            {
                if (len == pp)
                {
                    ff = 1;
                    break;
                }
                p.data[i] = buffer1[pp];
                pp++;
            }
            p.data[i] = '\0';
            strcpy(arr[counter]->data, p.data);
            arr[counter]->start_time = time(NULL);
            p.seq_no = seq_no;
            p.ack_no = ack_no;
            printf("[+]Data packet send: %d\n", seq_no);
            sendto(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            // char buffer2[1024];
            // strcpy(buffer2, p.data);
            seq_no++;
            ack_no++;
            bzero(p.data, 1024);
            counter++;
        }
        int counter1 = counter;
        int flag = 0;
        // printf("from server to client: ");
        // for (int i = 0; i < counter; i++)
        // {
        //     printf("%d | %s\n", arr[i]->ack_no, arr[i]->data);
        // }
        struct packet p1;
        while (1)
        {
            flag = 0;
            time_t end_time = time(NULL);
            for (int i = 0; i < counter1; i++)
            {
                if (arr[i]->ack_no == -10 && ((end_time - arr[i]->start_time) > 0.1))
                {
                    //printf("time - %ld\n", arr[i]->start_time);
                    //printf("time diff - %ld\n", end_time - arr[i]->start_time);
                    //printf("Timeout\n");
                    printf("Resending data packet with seq no: %d\n", i);
                    strcpy(p1.data, arr[i]->data);
                    p1.seq_no = i;
                    p1.ack_no = i;
                    sendto(sockfd, &p1, sizeof(p1), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
                    arr[i]->start_time = time(NULL);
                    flag = 1;
                    // printf("a--- %d",i);
                    // printf("%d | %s\n", arr[i]->ack_no, arr[i]->data);
                }
                else if (arr[i]->ack_no == -10)
                {
                    flag = 1;
                }
                else
                {
                    // printf("%d | %s\n", arr[i]->ack_no, arr[i]->data);
                    //  printf("b--- %d",i);
                    //  printf("[-]Connection closed\n");
                    // flag = 1;
                }
            }
            if (flag == 0)
            {
                break;
            }
        }
        printf("from server to client: ");
        printf("%s\n", buffer1);
        // printf("\n");
        // for (int i = 0; i < counter1; i++)
        // {
        //     printf("%d | %s\n", arr[i]->ack_no, arr[i]->data);
        // }
        // pthread_detach(pthread_self());
    }
    return 0;
}

// while (1)
// {
//     bzero(buffer, 1024);
//     addr_size = sizeof(client_addr);
//     recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, &addr_size);
//     printf("[+]Data recv: %s", buffer);
//     bzero(buffer, 1024);
//     // printf("Server: ");
//     // fgets(buffer, 1024, stdin);
//     // sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
//     // strcpy(buffer, "Welcome to the UDP Server.");
//     // sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
//     // printf("[+]Data send: %s\n", buffer);
// }