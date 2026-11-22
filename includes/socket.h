#ifndef __SOCKET_H__
#define __SOCKET_H__

enum{
    MAX_NUM_OF_SOCKETS = 10,
    ROOT_SOCKET_ADDR = 255,
    ROOT_SOCKET_PORT = 255,
    SOCKET_BUFFER_SIZE = 128,
    SOCKET_RESEND = 10000,
    DATA_SIZE = 13,
};

enum flag{
    SYN = 1,
    SYN_ACK = 2,
    DATA = 3,
    CLOSE = 4,
};

enum socket_state{
    CLOSED,
    LISTEN,
    ESTABLISHED,
    SYN_SENT,
    SYN_RCVD,
};

enum close_state{
    NO_CLOSE=0,
    LOCAL_CLOSE=1,
    RECEIVE_CLOSE=2,
    //Waits to close the connection until some time has passed and will respond if messaged in that time
    AWAIT_CLOSE=3,
};


typedef nx_uint8_t nx_socket_port_t;
typedef uint8_t socket_port_t;

// socket_addr_t is a simplified version of an IP connection.
typedef nx_struct socket_addr_t{
    nx_socket_port_t port;
    nx_uint16_t addr;
}socket_addr_t;


// File descripter id. Each id is associated with a socket_store_t
typedef uint8_t socket_t;

// State of a socket. 
typedef struct socket_store_t{
    uint8_t flag;
    enum socket_state state;
    socket_addr_t dest;

    // This is the sender portion.
    uint8_t sendBuff[SOCKET_BUFFER_SIZE];
    uint8_t lastWritten;
    uint8_t lastAck;
    uint8_t lastSent;

    // This is the receiver portion
    uint8_t rcvdBuff[SOCKET_BUFFER_SIZE];
    uint8_t maxRead;
    uint8_t lastByteRcvd;

    uint8_t recieveWindow;
    uint32_t lastRecievedTime;

    //It would be cool if this was a socket_state, but since everything relies on established state and multi state isn't a thing this is the best we got for now
    uint8_t closeState;
}socket_store_t;

#endif
