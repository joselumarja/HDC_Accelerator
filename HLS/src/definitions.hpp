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

typedef ap_uint<NUMBER_QUEUES_SIZE> id_queue_t;
typedef ap_uint<2> op_t;
typedef ap_uint<DATA_SIZE> data_t;
typedef ap_uint<BLOCK_SIZE> block_data_t;

struct Command_t{
	id_queue_t id_queue;
	bool last;
	block_data_t data_block;
};

#endif
