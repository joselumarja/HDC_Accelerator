#ifndef _DATA_CONTROLLER_
#define _DATA_CONTROLLER_

#include <hls_stream.h>
#include "definitions.hpp"

void data_mover(hls::stream<Data_t> &fifo_A, hls::stream<Data_t> &fifo_B, hls::stream<Data_t> &fifo_C, hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response);

#endif