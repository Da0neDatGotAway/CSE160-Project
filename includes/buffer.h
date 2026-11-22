#ifndef BUFFER_H
#define BUFFER_H

enum{
    BUFFER_SIZE = 2048,
};

typedef struct buffer_t{
    uint8_t socket;
    uint8_t buffer[BUFFER_SIZE];
    uint16_t bufferlen;
    uint16_t buffpos;
} buffer_t;

#endif