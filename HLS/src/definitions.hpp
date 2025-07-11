#ifndef _DEFINITIONS_
#define _DEFINITIONS_

#include <ap_int.h>

#define DATA_SIZE 8

//Number queues is 2 ^ NUMBER_QUEUES_SIZE
#define NUMBER_QUEUES_SIZE 2
#define NUMBER_QUEUES 3

#define READ_MODE 0
#define WRITE_MODE 1

#define FIFO_SIZE 64
#define BLOCK_SIZE 16

#define COMMAND_SIZE NUMBER_QUEUES_SIZE+1+BLOCK_SIZE

#define TRANSMISSION_READ_THRESHOLD FIFO_SIZE/2
#define TRANSMISSION_WRITE_THRESHOLD BLOCK_SIZE

typedef ap_uint<2> Op_t;
typedef ap_uint<DATA_SIZE> Data_t;
typedef ap_uint<BLOCK_SIZE> Scalar_t;

typedef ap_uint<COMMAND_SIZE> Command_t;

#endif
