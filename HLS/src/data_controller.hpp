#ifndef _DATA_CONTROLLER_
#define _DATA_CONTROLLER_

#include <hls_stream.h>
#include "definitions.hpp"

#define WAITING_DATA 0
#define READ_0 1
#define READ_1 2
#define WRITE_2 3

void data_mover(hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C, hls::stream<bool> &fifo_accelerator_finish, hls::stream<bool> &fifo_data_mover_finish, hls::stream<Command_t, FIFO_SIZE> &data_request, hls::stream<Command_t, FIFO_SIZE> &data_response);

#endif
