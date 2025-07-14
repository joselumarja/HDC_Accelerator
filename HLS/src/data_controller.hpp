#ifndef _DATA_CONTROLLER_
#define _DATA_CONTROLLER_

#include <hls_stream.h>
#include "definitions.hpp"

#define WAITING_DATA 0
#define READ_0 1
#define READ_1 2
#define WRITE_2 3

void data_mover(hls::stream<data_t> &fifo_A, hls::stream<data_t> &fifo_B, hls::stream<data_t> &fifo_C, hls::stream<bool> &fifo_finish, hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response);

#endif
