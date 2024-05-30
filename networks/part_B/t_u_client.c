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
};

struct node
{
    int ack_no;
    char data[1024];
    time_t start_time;
};

int no_of_packets_recv = 0;

struct node *arr[100000];
struct node *arr1[100000];
int counter = 0;

void *recv_ack(void *arg)
{
    pthread_detach(pthread_self());
    int sockfd = *((int *)arg);
    struct sockaddr_in addr;
    socklen_t addr_size;
    struct packet p;
    while (1)
    {
        //printf("neel\n");
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
            // printf("[-]Connection closed\n");
            break;
        }
        addr_size = sizeof(addr);
        ssize_t n11 = recvfrom(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, &addr_size);
        // printf("\n");
        // printf("[+]Data recv: %s\n", p.data);
        // printf("[+]Seq no: %d\n", p.seq_no);
        //  printf("[+]Data ack number recv from thread: %d\n", p.ack_no);
        // arr[p.seq_no] = (struct node *)malloc(sizeof(struct node));
        arr[p.seq_no]->ack_no = p.ack_no;
        // strcpy(arr[p.seq_no]->data, p.data);
        //  counter++;
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
    struct sockaddr_in addr;
    char buffer[1024];
    socklen_t addr_size;
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    memset(&addr, '\0', sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);
    while (1)
    {
        struct packet p;
        struct packet no_of_packets;
        int seq_no = 0;
        int ack_no = 0;
        bzero(buffer, 1024);
        printf("Client: ");
        fgets(buffer, 1024, stdin);
        int i = 0;
        // struct node *arr[100000];
        // int counter = 0;
        counter = 0;
        for (int i = 0; i < 100000; i++)
        {
            arr[i] = (struct node *)malloc(sizeof(struct node));
            arr[i]->start_time = 0;
            memset(arr[i]->data, '\0', sizeof(arr[i]->data));
            arr[i]->ack_no = -10;
        }
        int len = strlen(buffer);
        int times;
        int oooo = 0;
        if (len % 10 == 1)
        {
            times = len / 10;
            oooo = times;
        }
        else
        {
            times = len / 10;
            oooo = times;
            times++;
            oooo++;
        }
        int pp = 0;
        no_of_packets.seq_no = oooo;
        struct check c;
        c.number = oooo;
        sendto(sockfd, &c, sizeof(c), 0, (struct sockaddr *)&addr, sizeof(addr));
        printf("No of packets: %d\n", no_of_packets.seq_no);
        no_of_packets_recv = times;
        // sendto(sockfd, &no_of_packets, sizeof(no_of_packets), 0, (struct sockaddr *)&addr, sizeof(addr));
        pthread_t tid;
        pthread_create(&tid, NULL, recv_ack, &sockfd);
        seq_no = 0;
        ack_no = 0;
        for (int i = 0; i < 100000; i++)
        {
            arr1[i] = (struct node *)malloc(sizeof(struct node));
            arr1[i]->start_time = 0;
            memset(arr1[i]->data, '\0', sizeof(arr1[i]->data));
            arr1[i]->ack_no = -10;
        }
        while (times--)
        {
            int ff = 0;
            for (i = 0; i < 10; i++)
            {
                if (len == pp)
                {
                    ff = 1;
                    break;
                }
                // printf("%c", buffer[pp]);
                p.data[i] = buffer[pp];
                pp++;
            }
            // printf("\n");
            p.data[i] = '\0';
            // arr[i] = (struct node *)malloc(sizeof(struct node));
            strcpy(arr[counter]->data, p.data);
            arr[counter]->start_time = time(NULL);
            // printf("time - %ld\n", arr[counter]->start_time);
            p.seq_no = seq_no;
            p.ack_no = ack_no;
            printf("[+]Data packet send: %d\n", p.seq_no);
            sendto(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, sizeof(addr));
            seq_no++;
            ack_no++;
            bzero(p.data, 1024);
            counter++;
        }
        // printf("%d\n", counter);
        // printf("%d\n", len);
        int counter1 = counter;
        int flag = 0;
        // struct packet p;
        while (1)
        {
            flag = 0;
            time_t end_time = time(NULL);
            for (int i = 0; i < counter1; i++)
            {
                if (arr[i]->ack_no == -10 && ((end_time - arr[i]->start_time) > 0.1))
                {
                    // printf("time - %ld\n", arr[i]->start_time);
                    // printf("time diff - %ld\n", end_time - arr[i]->start_time);
                    //  printf("Timeout\n");
                    printf("Resending Data packet with seq no: %d\n", i);
                    strcpy(p.data, arr[i]->data);
                    p.seq_no = i;
                    p.ack_no = i;
                    sendto(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, sizeof(addr));
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
            // printf("flag : %d\n", flag);
            if (flag == 0)
            {
                break;
            }
        }
        // printf("from client to server: ");
        // printf("\n");
        //  for (int i = 0; i < counter1; i++)
        //  {
        //      printf("aa -- %d | %s\n", arr[i]->ack_no, arr[i]->data);
        //  }
        printf("from client to server: %s\n", buffer);
        printf("\n");
        // pthread_detach(pthread_self());
        // printf("from server to client: ");
        char total[1024];
        memset(total, '\0', sizeof(total));
        int p_ack = 0;
        addr_size = sizeof(addr);
        struct check c1;
        recvfrom(sockfd, &c1, sizeof(c1), 0, (struct sockaddr *)&addr, &addr_size);
        int times1 = c1.number;
        // recvfrom(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, &addr_size);
        // int times1 = p.seq_no;
        seq_no = 0;
        ack_no = 0;
        int counter_for_data = 0;
        int for_counter = 0;
        while (1)
        {
            addr_size = sizeof(addr);
            ssize_t n11 = recvfrom(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, &addr_size);
            if (counter_for_data < times1)
            {
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
                //printf("[-]Data packet lost - %d\n", p.seq_no);
                // printf("[+]seq no: %d\n", p.seq_no);
                for_counter++;
                continue;
            }
            // printf("[+]Seq no: %d\n", p.seq_no);
            // printf("[+]Ack no: %d\n", p.ack_no);
            // printf("[+]Data recv: %s\n", p.data);
            // strcat(total, p.data);
            p.ack_no = p.seq_no;
            // if (p_ack == 2)
            // {
            //     p.ack_no = -1;
            // }
            // else
            // {
            //     p.ack_no = p_ack;
            // }
            printf("[-]Data packet received - %d\n", p.seq_no);
            // printf("[+]Ack no: %d\n", p.ack_no);
            sendto(sockfd, &p, sizeof(p), 0, (struct sockaddr *)&addr, sizeof(addr));
            bzero(buffer, 1024);
            p_ack++;
            if (times1 == p_ack)
            {
                printf("[-]Connection closed\n");
                break;
            }
            for_counter++;
        }
        printf("from server to client: %s\n", total);
        printf("\n");
    }

    // bzero(buffer, 1024);
    // addr_size = sizeof(addr);
    // recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size);
    // printf("[+]Data recv: %s\n", buffer);

    return 0;
}