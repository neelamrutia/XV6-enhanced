# Implementing TCP using UDP

## Method
The Specifications : <br>
**Data Sequencing** : Where the user sends data in a sequence of packets, and the receiver receives them in the same order. <br>
There mmight be a case where the packets are received out of order, so we need to reorder them. <br>
**Retransmissions** : Where the sender sends the data, and the receiver sends an acknowledgement. If the sender doesn't receive the acknowledgement, it resends the data. <br>

### **Data Sequencing**
- first the sender read the data and split in the chunks of 10 bytes.
- each packet is sending with a sequence number and ack number and also data of 10 bytes.
- each packet is sent in a loop. and each data chunk is sent in a different packet with different sequence number.
- no of packets is calculated and sent to the receiver.
- then sender sends all the data packets to the receiver. and receiver sends ack for each packet.
- in ecah packet which receiver sends ack numebr is the sequence number of the packet which it received.

### **Retransmissions**

- there is case when the data packet is not received by the receiver.
- so in this case reveiver sends didnot send acknowledgement for that packet.
- so sender must resend that packet.
- so sender sends all the packets and then it starts a thread which listens for the acknowledgement for each packet.
- this thread runs in parallel to the main thread.
- if acknowledgement is received for a packet then it changes the status of that packet to received.
- if acknowledgement is not received for a packet then it resends that packet.
- the main thread keeps checking for the status of the packets.
- if status is not received and time waited is more than 0.1 sec then it resends that packet.
- this process is done until all the packets are received by the receiver.

### Code Implementation:
the code contains two files one is for server and other is for client.

1. It is assumed that the server starts listening before sending any data to the client.
2. the first communication is done by the client to the server by sending a data packet.
3. firstly client sendes the total number of packets that will be send in future to the server.
4. before sending the data client we make thread which listens for the acknowledgement for each packet.
5. then client sends the all the data packets to the server. and now server starts listening for the data packets.
6. in the parrallel the thread listens for the acknowledgement for each packet.
7. if acknowledgement is received for a packet then it changes the status of that packet to received.
8. if acknowledgement is not received for a packet then it resends that packet.
9. the main thread keeps checking for the status of the packets.
10. if status is not received and time waited is more than 0.1 sec then it resends that packet.
11. this process is done until all the packets are received by the receiver.
14. after receiving all the packets by the server client and server both reverse their roles.
15. now server sends the data to the client. and client starts listening for the data.
16. now above process is repeated for the server and client.
17. by above process we can implement tcp using udp. and we can send data reliably. and also make two way communication.

## How our implementation is different from traditional TCP

1. in tcp data is sent in the form of stream. but in our implementation data is sent in the form of packets. we read the data and split it into the chunks of 10 bytes. and resemble it at the receiver side by using sequence number.[https://www.freesoft.org/CIE/Topics/21.htm]
2. there is three way handshake in tcp. but in our implementation there is no three way handshake we just send the data.
3. in tcp there is flow control. but in our implementation there is no flow control.
4. in tcp there is congestion control. but in our implementation there is no congestion control.
5. in the tcp sender sends the data and wait for the acknowledgement. but in our implementation we send the data and also listen for the acknowledgement in parallel.

## flow control

1. ```Window size``` :The sender keeps track of the available window size and only sends chunks within the available window. the receiver sends the window size to the sender. the sender sends the data according to the window size and the receiver sends the window size according to the data received.

2. ```stop and wait``` : The sender sends a chunk of data and waits for the acknowledgement. if the acknowledgement is received then it sends the next chunk of data. if the acknowledgement is not received then it resends the same chunk of data. this process is repeated until the acknowledgement is received. this is called stop and wait. by this we ansure that the data is received by the receiver.

3. ```Dynamic window size``` : The sender sends the data and waits for the acknowledgement. if the acknowledgement is received then it increases the window size. if the acknowledgement is not received then it decreases the window size. this process is repeated until the acknowledgement is received. by this we ansure that the data is received by the receiver.
if the network is good then the window size is increased. if the network is bad then the window size is decreased.

4. ```ACK-based flow control```:  Have the sender and receiver exchange information about the current window size and the number of chunks they can handle. Adjust the sending rate accordingly. This is called ACK-based flow control.


I USED THE CODE FROM THE GIVEN LINKS FOR THE GIVEN TASKS IN THE PROJECT

