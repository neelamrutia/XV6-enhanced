#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <pthread.h>
#include <unistd.h>
#include <semaphore.h>
#define int long long

time_t t;

sem_t sem1;

int total_wasted = 0;

int *time_avg;

int n, b, k;

struct node
{
    int priority;
    int arr_time;
    int burst_time;
    int go_to_thread;
    int present_order;
    int ready;
    int completed;
    int total_time;
    int leave;
    char order[10000];
    int time;
    struct node *next;
};

struct node1
{
    int present_order;
    int ber_id;
    int time;
    struct node1 *next;
};

struct node1 *head1 = NULL;
struct node *head = NULL;

pthread_mutex_t lock;

int timer = 0;

int check_all_cust = 0;
void *timer_thread(void *arg)
{
    while (1)
    {
        // printf("\x1b[38;5;33m------- %lld second(s) -----------\x1b[0m\n", timer);
        sleep(1);
        timer++;
    }
    return NULL;
}

void *barista_thread(void *arg)
{
    int barista_id = *((int *)arg);
    // printf("Barista %lld starts working\n", barista_id + 1);
    while (1)
    {
        sem_wait(&sem1);
        pthread_mutex_lock(&lock);
        struct node *temp1 = head;
        int ff = 0;
        while (temp1 != NULL)
        {
            int fl = 0;
            if (temp1->present_order == 0 && temp1->ready == 1 && temp1->completed == 0 && temp1->leave == 0)
            {
                struct node1 *temp2 = head1;
                while (temp2 != NULL)
                {
                    if (temp2->ber_id == barista_id)
                    {
                        break;
                    }
                    temp2 = temp2->next;
                }
                struct node1 *temp3 = head1;
                while (temp3 != temp2)
                {
                    if (temp3->present_order == 0)
                    {
                        fl = 1;
                        break;
                    }
                    temp3 = temp3->next;
                }
                if (fl == 0)
                {
                    struct node1 *temp4 = head1;
                    while (temp4 != NULL)
                    {
                        if (temp4->ber_id == barista_id)
                        {
                            break;
                        }
                        temp4 = temp4->next;
                    }
                    temp4->present_order = 1;
                    temp1->present_order = 1;
                    pthread_mutex_unlock(&lock);
                    temp1->time = timer;
                    while (timer < temp1->time + 1)
                    {
                    }
                    ff = 1;
                    time_avg[temp1->priority - 1] = timer - temp1->arr_time;
                    printf("\x1b[36mBarista %lld is preparing %s for customer %lld at %lld second(s)\x1b[0m\n", barista_id, temp1->order, temp1->priority, timer);
                    int t1 = timer;
                    temp1->time = t1 + temp1->total_time;
                    int fh = 0;
                    while (timer - t1 < temp1->total_time)
                    {
                        if (temp1->burst_time + temp1->arr_time < timer && fh == 0 && timer != t1 + temp1->total_time)
                        {
                            total_wasted++;
                            printf("\x1b[31mcustomer %lld is leaving without order at time %lld second(s)\x1b[0m\n", temp1->priority, timer);
                            fh = 1;
                        }
                    }
                    temp1->completed = 1;
                    printf("\x1b[34mBarista %lld finishes preparing %s for customer %lld at %lld second(s)\x1b[0m\n", barista_id, temp1->order, temp1->priority, timer);
                    if (temp1->leave == 0 && fh == 0 && (temp1->burst_time + temp1->arr_time + 1) != timer)
                    {
                        printf("\x1b[32mcustomer %lld leaves with their order at %lld second(s)\x1b[0m\n", temp1->priority, timer);
                    }
                    else if (temp1->leave == 0 && fh == 0 && temp1->burst_time + temp1->arr_time != timer)
                    {
                        total_wasted++;
                        printf("\x1b[31mcustomer %lld is leaving without order at time %lld second(s)\x1b[0m\n", temp1->priority, timer);
                    }
                    // sleep(1);
                    temp4->present_order = 0;
                    check_all_cust++;
                }
            }
            if (ff == 1)
            {
                break;
            }
            temp1 = temp1->next;
        }
        if (ff == 0)
        {
            pthread_mutex_unlock(&lock);
        }
        if (check_all_cust == n)
        {
            break;
        }
        sem_post(&sem1);
        usleep(10000);
    }
    return NULL;
}

pthread_mutex_t lock1;

void *customer_thread(void *arg)
{
    int customer_id = *((int *)arg);
    pthread_mutex_lock(&lock1);
    struct node *temp = head;
    while (temp != NULL)
    {
        if (temp->priority == customer_id)
        {
            break;
        }
        temp = temp->next;
    }
    pthread_mutex_unlock(&lock1);
    int t1 = timer;
    // printf("customer %lld arrives at time %lld\n", temp->priority, timer);
    // printf("customer %lld places order for %s\n", temp->priority, temp->order);
    while (1)
    {
        if (temp->completed == 1)
        {
            // printf("customer %lld receives the order at time %lld second(s)\n", temp->priority, timer);
            break;
        }
        if (timer > temp->arr_time + temp->burst_time && temp->leave == 0 && temp->present_order == 0)
        {
            // total_wasted++;
            time_avg[temp->priority - 1] = temp->burst_time;
            printf("\x1b[31mcustomer %lld is leaving without order at time %lld second(s)\x1b[0m\n", temp->priority, timer);
            temp->leave = 1;
            temp->completed = 1;
            check_all_cust++;
            temp->present_order = 1;
            break;
        }
        // sleep(1);
        t1++;
    }
    return NULL;
}

pthread_mutex_t lock2;

signed main()
{
    sem_init(&sem1, 0, 1);
    pthread_mutex_init(&lock, NULL);
    pthread_mutex_init(&lock1, NULL);
    scanf("%lld %lld %lld", &b, &k, &n);
    time_avg = (int *)malloc(sizeof(int) * n);
    for (int i = 0; i < n; i++)
    {
        time_avg[i] = 0;
    }
    char **coff = (char **)malloc(sizeof(char *) * k);
    for (int i = 0; i < k; i++)
    {
        coff[i] = (char *)malloc(sizeof(char) * 10000);
    }
    int coff_time[k];
    for (int i = 0; i < k; i++)
    {
        scanf("%s %lld", coff[i], &coff_time[i]);
    }
    char customer_order[n][10000];
    int customer_arr_time[n];
    int customer_burst_time[n];
    int customer_priority[n];
    struct node *temp = head;
    for (int i = 0; i < n; i++)
    {
        char temp_c[10000];
        scanf("%lld %s %lld %lld", &customer_priority[i], temp_c, &customer_arr_time[i], &customer_burst_time[i]);
        // strcpy(temp_c, customer_order[i]);
        strcpy(customer_order[i], temp_c);
        int total_time_c = 0;
        // printf("%s\n", customer_order[i]);
        for (int ch = 0; ch < k; ch++)
        {
            // printf("%s %s\n", temp_c, coff[ch]);
            if (strcmp(temp_c, coff[ch]) == 0)
            {
                // printf("%s %s\n", temp_c, coff[ch]);
                total_time_c = coff_time[ch];
                break;
            }
            // printf("%s\n", temp_c);
        }
        struct node *new_node = (struct node *)malloc(sizeof(struct node));
        new_node->priority = customer_priority[i];
        new_node->arr_time = customer_arr_time[i];
        new_node->burst_time = customer_burst_time[i];
        new_node->total_time = total_time_c;
        new_node->completed = 0;
        new_node->leave = 0;
        new_node->go_to_thread = 0;
        new_node->ready = 0;
        new_node->present_order = 0;
        // printf("total time -- %lld\n", new_node->total_time);
        strcpy(new_node->order, customer_order[i]);
        new_node->time = 0;
        new_node->next = NULL;
        if (head == NULL)
        {
            head = new_node;
            temp = head;
        }
        else
        {
            temp->next = new_node;
            temp = temp->next;
        }
    }
    struct node1 *temp1 = head1;
    // printf("%lld\n", b);
    for (int i = 0; i < b; i++)
    {
        struct node1 *new_node1 = (struct node1 *)malloc(sizeof(struct node1));
        new_node1->present_order = 0;
        new_node1->ber_id = i + 1;
        new_node1->time = 0;
        new_node1->next = NULL;
        if (head1 == NULL)
        {
            head1 = new_node1;
            temp1 = head1;
        }
        else
        {
            temp1->next = new_node1;
            temp1 = temp1->next;
        }
    }

    int cust_id[n];
    int bar_id[b];
    for (int i = 0; i < n; i++)
    {
        cust_id[i] = i + 1;
    }
    for (int i = 0; i < b; i++)
    {
        bar_id[i] = i + 1;
    }
    // start timer thread
    pthread_t timer1;
    pthread_create(&timer1, NULL, timer_thread, NULL);
    // Start barista threads
    pthread_t barista[b + 1];
    for (int i = 0; i < b; i++)
    {
        int *barista_id = (int *)malloc(sizeof(int));
        *barista_id = i + 1;
        pthread_create(&barista[i], NULL, barista_thread, (void *)&bar_id[i]);
    }

    int check_all_cust = 0;
    struct node *temp2 = head;
    pthread_t customer[n + 1];
    while (1)
    {
        if (check_all_cust == n)
        {
            break;
        }
        temp2 = head;
        while (temp2 != NULL)
        {
            if (temp2->arr_time == timer && temp2->ready == 0)
            {
                struct node *temp3 = head;
                while (temp3 != NULL)
                {
                    if (temp3->priority == temp2->priority)
                    {
                        break;
                    }
                    temp3 = temp3->next;
                }
                struct node *temp4 = head;
                int gh = 0;
                while (temp4 != temp3)
                {
                    if (temp4->arr_time == timer && temp2->ready == 0 && temp4->go_to_thread == 0)
                    {
                        gh = 1;
                        break;
                    }
                    temp4 = temp4->next;
                }
                if (gh == 1)
                {
                    break;
                }
                temp2->go_to_thread = 1;
                printf("customer %lld arrives at time %lld\n", temp2->priority, timer);
                printf("\x1b[33mcustomer %lld places order for %s\x1b[0m\n", temp2->priority, temp2->order);
                temp2->ready = 1;
                check_all_cust++;
                int *customer_id = (int *)malloc(sizeof(int));
                *customer_id = temp2->priority;
                pthread_create(&customer[temp2->priority], NULL, customer_thread, (void *)&temp2->priority);
            }
            temp2 = temp2->next;
        }
    }

    // Wait for barista threads to finish
    for (int i = 0; i < b; i++)
    {
        pthread_join(barista[i], NULL);
    }

    for (int i = 0; i < n; i++)
    {
        pthread_join(customer[i], NULL);
    }

    printf("\n");
    float tt = 0;
    for (int i = 0; i < n; i++)
    {
        tt += time_avg[i];
        printf("\x1b[38;5;35mcustomer %lld waited for %lld second(s)\x1b[0m\n", i + 1, time_avg[i]);
    }
    printf("\x1b[38;5;35m%lld customer(s) waited for %lf second(s) on average\x1b[0m\n", n, tt / n);
    printf("\x1b[38;5;35m%lld coffee wasted\x1b[0m\n", total_wasted);
    return 0;
}
