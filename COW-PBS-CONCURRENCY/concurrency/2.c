#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <pthread.h>
#include <unistd.h>
#include <semaphore.h>
#define int long long

// n is no of icecream machines
// f is no of icecreams flavours
// t is topings
// k is no of customers

struct nn
{
    pthread_t id;
    int val;
};

time_t t1;
sem_t sem1;
int n, k, f, t;
int timer = 0;
int capacity = 0;
sem_t *sem_k;

struct customer *head_customer = NULL;
struct machine *head_machine = NULL;
struct topping *topings = NULL;
struct flavour *flavours = NULL;

struct customer
{
    int id;
    int t_arr;
    int order_taken;
    int no_of_icecreams;
    int start_thread;
    struct icecream **icecream_ordered;
    struct customer *next;
};

struct machine
{
    int id;
    int tm_start;
    int tm_end;
    int no_of_icecreams;
    int start_thread;
    int chec_order;
    int end_thread;
    int order_taken;
    struct icecream *icecream[1000];
    struct machine *next;
};

struct icecream
{
    int order_taken;
    int order_complete;
    int do_not_make;
    int id;
    char order[1000];
    char flavour[1000];
    int no_of_topings;
    char **topings;
    int total_time_prepartion;
};

struct topping
{
    int id;
    char name[1000];
    int q_t;
};

struct flavour
{
    int id;
    char name[1000];
    int t_f;
};

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

pthread_mutex_t lock1;

int check_for_toppings(struct icecream *icecream_ordered, struct topping *topings, int t)
{
    pthread_mutex_lock(&lock1);
    for (int i = 0; i < icecream_ordered->no_of_topings; i++)
    {
        for (int j = 0; j < t; j++)
        {
            if (strcmp(icecream_ordered->topings[i], topings[j].name) == 0)
            {
                if (topings[j].q_t <= 0)
                {
                    return 0;
                }
            }
        }
    }
    pthread_mutex_unlock(&lock1);
    return 1;
}

pthread_mutex_t lock7;

int check_all_orders(struct customer *temp)
{
    pthread_mutex_lock(&lock7);
    struct topping *topings_1 = (struct topping *)malloc(sizeof(struct topping) * t);
    for (int i = 0; i < t; i++)
    {
        strcpy(topings_1[i].name, topings[i].name);
        topings_1[i].q_t = 0;
    }
    for (int i = 0; i < t; i++)
    {
        int sum_toppings = 0;
        for (int j = 0; j < temp->no_of_icecreams; j++)
        {
            for (int k = 0; k < temp->icecream_ordered[j]->no_of_topings; k++)
            {
                if (strcmp(temp->icecream_ordered[j]->topings[k], topings[i].name) == 0)
                {
                    sum_toppings++;
                }
            }
        }
        topings_1[i].q_t = sum_toppings;
    }
    int check = 0;
    for (int i = 0; i < t; i++)
    {
        if (topings_1[i].q_t > topings[i].q_t)
        {
            check = 1;
            break;
        }
    }
    if (check == 1)
    {
        pthread_mutex_unlock(&lock7);
        return 1;
    }
    else
    {
        pthread_mutex_unlock(&lock7);
        return 0;
    }
}

pthread_mutex_t lock8;
void *customer_thread(void *arg)
{
    int cust_id = *((int *)arg);
    struct customer *temp = head_customer;
    while (temp != NULL)
    {
        if (temp->id == cust_id)
        {
            break;
        }
        temp = temp->next;
    }
    if (temp->start_thread == -1)
    {
        for (int i = 0; i < temp->no_of_icecreams; i++)
        {
            temp->icecream_ordered[i]->do_not_make = 1;
            temp->icecream_ordered[i]->order_complete = -1;
            temp->icecream_ordered[i]->order_taken = 1;
        }
        return NULL;
    }
    temp->start_thread = 1;
    usleep(800000);
    // pthread_mutex_lock(&lock8);
    // int check_1 = check_all_orders(temp);
    // if (check_1 == 1)
    // {
    //     for (int i = 0; i < temp->no_of_icecreams; i++)
    //     {
    //         temp->icecream_ordered[i]->do_not_make = 1;
    //         temp->icecream_ordered[i]->order_complete = -1;
    //     }
    //     printf("customer %lld has left because of unavailability of all toppings at %lld\n", temp->id, timer);
    //     pthread_mutex_unlock(&lock8);
    //     // temp->start_thread = 1;
    //     return NULL;
    // }
    // pthread_mutex_unlock(&lock8);
    while (1)
    {
        int check = 0;
        int ff = 0;
        for (int i = 0; i < temp->no_of_icecreams; i++)
        {
            if (temp->icecream_ordered[i]->order_complete == 1)
            {
                check++;
            }
            if (temp->icecream_ordered[i]->order_complete == -1)
            {
                ff = 1;
                check++;
            }
        }
        if (check == temp->no_of_icecreams && ff == 0)
        {
            printf("\x1b[32mcustomer %lld has collected their order(s) and left at %lld second(s) \x1b[0m\n", temp->id, timer);
            break;
        }
        else if (ff == 1 && check == temp->no_of_icecreams)
        {
            printf("\x1b[31mcustomer %lld left at %lld second(s) with an unfulfilled order \x1b[0m\n", temp->id, timer);
            // printf("customer %lld has left because of unavailability of toppings at %lld second(s)\n", temp->id, timer);
            break;
        }
        struct machine *temp1 = head_machine;
        int c = 0;
        while (temp1 != NULL)
        {
            if (temp1->tm_end >= timer)
            {
                c = 1;
                break;
            }
            temp1 = temp1->next;
        }
        if (c == 0)
        {
            printf("\x1b[31mcustomer %lld was not serviced due to unavailability of machines \x1b[0m\n", temp->id);
            break;
        }
    }
    // st(sem_k);
    capacity--;
    return NULL;
}

int machine_check(struct machine *ptr)
{
    struct machine *ter = head_machine;
    while (ter != ptr)
    {
        if (ter->order_taken == 0)
        {
            return 1;
        }
        ter = ter->next;
    }
    return 0;
}

pthread_mutex_t lock;
pthread_mutex_t lock2;

void *machine_thread(void *arg)
{
    int mach_id = *((int *)arg);
    struct machine *temp = head_machine;
    while (temp != NULL)
    {
        if (temp->id == mach_id)
        {
            break;
        }
        temp = temp->next;
    }
    while (1)
    {
        if (temp->tm_start == timer)
        {
            printf("\e[38;2;255;120;0mmachine %lld started working at %lld second(s) \x1b[0m\n", temp->id, timer);
            temp->start_thread = 1;
            break;
        }
    }
    usleep(100000);
    while (1)
    {
        if (temp->tm_end <= timer)
        {
            printf("\e[38;2;255;120;0mmachine %lld stopped working at %lld second(s) \x1b[0m\n", temp->id, timer);
            temp->end_thread = 1;
            break;
        }
        // sem_wait(&sem1);
        struct customer *temp1 = head_customer;
        while (temp1 != NULL)
        {
            int k = temp1->no_of_icecreams;
            int p_c = 0;
            int check_temp = 0;
            if (temp1->start_thread == 0)
            {
                temp1 = temp1->next;
                continue;
            }
            for (int i = 0; i < k; i++)
            {
                check_temp = 0;
                pthread_mutex_lock(&lock);
                if (temp->tm_end < timer + temp1->icecream_ordered[i]->total_time_prepartion)
                {
                    temp->chec_order = 1;
                    pthread_mutex_unlock(&lock);
                    continue;
                }
                // printf("aaa\n");
                if (temp1->icecream_ordered[i]->order_taken == 0 && temp1->icecream_ordered[i]->order_complete == 0 && temp1->start_thread == 1)
                {
                    // int check_temp = machine_check(temp);
                    struct machine *ter = head_machine;
                    while (ter != temp)
                    {
                        if (ter->order_taken == 0 && timer >= ter->tm_start && timer <= ter->tm_end && ter->chec_order == 0)
                        {
                            check_temp = 1;
                            // printf("machine %lld is waiting for machine %lld to be free\n", temp->id, ter->id);
                            break;
                        }
                        ter = ter->next;
                    }
                    if (check_temp == 1)
                    {
                        pthread_mutex_unlock(&lock);
                        break;
                    }
                    if (check_temp == 0)
                    {
                        temp1->icecream_ordered[i]->order_taken = 1;
                        temp1->order_taken = 1;
                        temp->order_taken = 1;
                        int check = check_for_toppings(temp1->icecream_ordered[i], topings, t);
                        if (check == 0)
                        {
                            for (int yu = 0; yu < temp1->no_of_icecreams; yu++)
                            {
                                temp1->icecream_ordered[yu]->do_not_make = 1;
                                temp1->icecream_ordered[yu]->order_complete = -1;
                            }
                            // printf("ter\n");
                            //  temp1->icecream_ordered[i]->do_not_make = 1;
                            //  temp1->icecream_ordered[i]->order_complete = -1;
                            usleep(100000);
                            pthread_mutex_unlock(&lock);
                            break;
                        }
                        p_c = 1;
                        while (timer <= temp1->t_arr)
                        {
                            continue;
                        }
                        // printf("-----toppings check-----\n");
                        // for (int i = 0; i < t; i++)
                        // {
                        //     printf("toping %lld -- %s -- %lld\n", i + 1, topings[i].name, topings[i].q_t);
                        // }
                        // printf("-----toppings check complete-----\n");
                        printf("\x1b[36mmachine %lld starts preparing ice cream %lld for customer %lld at %lld second(s) \x1b[0m\n", temp->id, temp1->icecream_ordered[i]->id, temp1->id, timer);
                        // pthread_mutex_lock(&lock2);
                        for (int j = 0; j < temp1->icecream_ordered[i]->no_of_topings; j++)
                        {
                            for (int k = 0; k < t; k++)
                            {
                                if (strcmp(temp1->icecream_ordered[i]->topings[j], topings[k].name) == 0)
                                {
                                    topings[k].q_t--;
                                }
                            }
                        }
                        pthread_mutex_unlock(&lock);
                        // pthread_mutex_unlock(&lock2);
                        int time = temp1->icecream_ordered[i]->total_time_prepartion;
                        int t = timer;
                        while (1)
                        {
                            if (timer == t + time)
                            {
                                printf("\x1b[34mmachine %lld completed making ice cream %lld for customer %lld at %lld second(s) \x1b[0m\n", temp->id, temp1->icecream_ordered[i]->id, temp1->id, timer);
                                temp->chec_order = 0;
                                temp->order_taken = 0;
                                temp1->icecream_ordered[i]->order_complete = 1;
                                temp->no_of_icecreams++;
                                break;
                            }
                        }
                    }
                }
                else if (check_temp == 1)
                {
                    break;
                }
                else
                {
                    pthread_mutex_unlock(&lock);
                }
                // printf("ccc\n");
            }
            if (check_temp == 1)
            {
                break;
            }
            temp1 = temp1->next;
            // pthread_mutex_unlock(&lock);
        }
        // sem_post(&sem1);
    }
    //printf("machine %lld is closing\n", temp->id);
    return NULL;
}

signed main()
{
    // sem_init(&sem1, 0, 1);
    pthread_mutex_init(&lock, NULL);
    scanf("%lld %lld %lld %lld", &n, &k, &f, &t);
    sem_k = (sem_t *)malloc(sizeof(sem_t) * 1);
    sem_init(sem_k, 0, k);
    topings = (struct topping *)malloc(sizeof(struct topping) * t);
    flavours = (struct flavour *)malloc(sizeof(struct flavour) * f);
    struct machine *temp = head_machine;
    for (int i = 0; i < n; i++)
    {
        struct machine *temp1 = (struct machine *)malloc(sizeof(struct machine));
        scanf("%lld %lld", &temp1->tm_start, &temp1->tm_end);
        temp1->id = i + 1;
        temp1->start_thread = 0;
        temp1->end_thread = 0;
        temp1->order_taken = 0;
        temp1->chec_order = 0;
        temp1->no_of_icecreams = 0;
        if (head_machine == NULL)
        {
            head_machine = temp1;
            temp = head_machine;
        }
        else
        {
            temp->next = temp1;
            temp = temp->next;
        }
    }
    temp->next = NULL;
    for (int i = 0; i < f; i++)
    {
        scanf("%s %lld", flavours[i].name, &flavours[i].t_f);
    }
    for (int i = 0; i < t; i++)
    {
        scanf("%s %lld", topings[i].name, &topings[i].q_t);
        if (topings[i].q_t == -1)
        {
            topings[i].q_t = 100000;
        }
    }
    struct customer *temp2 = head_customer;
    int kk = 0;
    int total_customers = k;
    while (1)
    {
        struct customer *temp3 = (struct customer *)malloc(sizeof(struct customer));
        char buffer1[10000];
        fgets(buffer1, 10000, stdin);
        // printf("buffer1 -- %s\n", buffer1);
        if (kk == 0)
        {
            kk++;
            continue;
        }
        kk++;
        if (buffer1[0] == '\n')
        {
            break;
        }
        buffer1[strlen(buffer1) - 1] = '\0';
        char *token1 = strtok(buffer1, " ");
        int first = 0;
        while (token1 != NULL)
        {
            if (first == 0)
            {
                first++;
                temp3->id = atoi(token1);
            }
            else if (first == 1)
            {
                first++;
                temp3->t_arr = atoi(token1);
            }
            else if (first == 2)
            {
                first++;
                temp3->no_of_icecreams = atoi(token1);
            }
            // printf("%s\n", token1);
            token1 = strtok(NULL, " ");
        }
        // printf("temp3->id -- %lld\n", temp3->id);
        // printf("temp3->t_arr -- %lld\n", temp3->t_arr);
        // printf("temp3->no_of_icecreams -- %lld\n", temp3->no_of_icecreams);
        temp3->order_taken = 0;
        temp3->start_thread = 0;
        total_customers++;
        temp3->icecream_ordered = (struct icecream **)malloc(sizeof(struct icecream *) * temp3->no_of_icecreams);
        for (int j = 0; j < temp3->no_of_icecreams; j++)
        {
            char buffer[10000];
            fgets(buffer, 10000, stdin);
            buffer[strlen(buffer) - 1] = '\0';

            // printf("buffer -- %s\n", buffer);
            char buffer_copy[10000];
            strcpy(buffer_copy, buffer);
            char *token = strtok(buffer, " ");
            int io = 0;
            while (token != NULL)
            {
                // printf("%s\n", token);
                io++;
                token = strtok(NULL, " ");
            }
            temp3->icecream_ordered[j] = (struct icecream *)malloc(sizeof(struct icecream));
            temp3->icecream_ordered[j]->order_taken = 0;
            temp3->icecream_ordered[j]->order_complete = 0;
            temp3->icecream_ordered[j]->do_not_make = 0;
            temp3->icecream_ordered[j]->no_of_topings = io - 1;
            temp3->icecream_ordered[j]->topings = (char **)malloc(sizeof(char *) * (io - 1));
            temp3->icecream_ordered[j]->id = j + 1;
            strcpy(temp3->icecream_ordered[j]->order, buffer_copy);
            char *token2 = strtok(buffer_copy, " ");
            int ff_fir = 0;
            while (token2 != NULL)
            {
                if (ff_fir == 0)
                {
                    ff_fir++;
                    strcpy(temp3->icecream_ordered[j]->flavour, token2);
                }
                else
                {
                    temp3->icecream_ordered[j]->topings[ff_fir - 1] = (char *)malloc(sizeof(char) * 100);
                    strcpy(temp3->icecream_ordered[j]->topings[ff_fir - 1], token2);
                    ff_fir++;
                }
                token2 = strtok(NULL, " ");
            }
            // printf("temp3->icecream_ordered[j]->flavour -- %s\n", temp3->icecream_ordered[j]->flavour);
            // for (int i = 0; i < temp3->icecream_ordered[j]->no_of_topings; i++)
            // {
            //     printf("temp3->icecream_ordered[j]->topings[%lld] -- %s\n", i, temp3->icecream_ordered[j]->topings[i]);
            // }
        }
        if (head_customer == NULL)
        {
            head_customer = temp3;
            temp2 = head_customer;
        }
        else
        {
            temp2->next = temp3;
            temp2 = temp2->next;
        }
    }
    temp2->next = NULL;
    struct customer *temp4 = head_customer;
    while (temp4 != NULL)
    {
        for (int i = 0; i < temp4->no_of_icecreams; i++)
        {
            char find_flavour[1000];
            strcpy(find_flavour, temp4->icecream_ordered[i]->flavour);
            int find_flavour_time = 0;
            for (int j = 0; j < f; j++)
            {
                if (strcmp(find_flavour, flavours[j].name) == 0)
                {
                    find_flavour_time = flavours[j].t_f;
                    break;
                }
            }
            temp4->icecream_ordered[i]->total_time_prepartion = find_flavour_time;
        }
        temp4 = temp4->next;
    }
    // struct customer *temp5 = head_customer;
    // while (temp5 != NULL)
    // {
    //     for (int i = 0; i < temp5->no_of_icecreams; i++)
    //     {
    //         printf("time for %lld icecream of customer %lld is %lld\n", i + 1, temp5->id, temp5->icecream_ordered[i]->total_time_prepartion);
    //     }
    //     temp5 = temp5->next;
    // }

    // start timer thread
    pthread_t timer_thread_id;
    pthread_create(&timer_thread_id, NULL, timer_thread, NULL);

    // start customer threads
    total_customers = kk - 2;
    // printf("total_customers -- %lld\n", total_customers);
    // printf("\n");

    int customer[total_customers + 1];

    for (int i = 0; i < total_customers + 1; i++)
    {
        customer[i] = i + 1;
    }

    int machine[n + 1];

    for (int i = 0; i < n + 1; i++)
    {
        machine[i] = i + 1;
    }

    // start machine threads

    struct machine *temp7 = head_machine;
    int ss_th1 = 0;
    pthread_t machine_thread_id[n + 1];
    // struct nn *nn1 = (struct nn *)malloc(sizeof(struct nn) * n);

    while (temp7 != NULL)
    {
        int mach_id = temp7->id;
        // printf("machine %lld is ready\n", mach_id);
        pthread_create(&machine_thread_id[mach_id], NULL, machine_thread, (void *)&temp7->id);
        temp7 = temp7->next;
    }

    // start customer threads

    struct customer *temp6 = head_customer;
    int ss_th = 0;
    pthread_t customer_thread_id[total_customers + 1];
    while (1)
    {
        temp6 = head_customer;
        while (temp6 != NULL)
        {
            if (temp6->start_thread == 0 && temp6->t_arr == timer)
            {
                // sem_wait(sem_k);
                int gg = 0;
                struct customer *temp7 = head_customer;
                while (temp7 != temp6)
                {
                    if (temp7->start_thread == 0)
                    {
                        gg = 1;
                        break;
                    }
                    temp7 = temp7->next;
                }
                if (gg == 1)
                {
                    break;
                }
                int cust_id = temp6->id;
                if (capacity >= k)
                {
                    printf("\x1b[31mcustomer %lld left because of capacity of parlor at %lld second(s) \x1b[0m\n", temp6->id, timer);
                    temp6->start_thread = -1;
                    ss_th++;
                    pthread_create(&customer_thread_id[cust_id], NULL, customer_thread, (void *)&temp6->id);
                    break;
                }
                ss_th++;
                temp6->start_thread = 1;
                printf("customer %lld  enters at %lld second(s)\n", temp6->id, timer);
                printf("\x1b[33mcustomer %lld orders %lld icecreams \x1b[0m\n", temp6->id, temp6->no_of_icecreams);
                for (int i = 0; i < temp6->no_of_icecreams; i++)
                {
                    printf("\x1b[33mIce cream %lld: %s \x1b[0m\n", i + 1, temp6->icecream_ordered[i]->order);
                }
                capacity++;
                pthread_create(&customer_thread_id[cust_id], NULL, customer_thread, (void *)&temp6->id);
                // usleep(100000);
            }
            temp6 = temp6->next;
        }
        if (ss_th == total_customers)
        {
            break;
        }
    }

    // wait for all customer threads to end by pthredjoin
    for (int i = 0; i < n; i++)
    {
        //printf("aabaa\n");
        pthread_join(machine_thread_id[i + 1], NULL);
    }

    //printf("aaaaa\n");

    for (int i = 0; i < total_customers; i++)
    {
        pthread_join(customer_thread_id[i + 1], NULL);
    }

    printf("\x1b[38;5;35mParlor closed\x1b[0m\n");
}