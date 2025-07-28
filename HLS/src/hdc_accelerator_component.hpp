#ifndef _HDC_ACCELERATOR_COMPONENT_
#define _HDC_ACCELERATOR_COMPONENT_

#include <hls_stream.h>

#include "definitions.hpp"
#include "data_controller.hpp"

#define BINDING 0
#define BUNDLING 1
#define PERMUTATION 2
#define SIMILARITY 3

#define FIFO_SIZE 64
#define BLOCK_SIZE 16

#define DATA_SIZE 8
typedef ap_uint<DATA_SIZE> data_t;


void hdc_accelerator_component(const unsigned int vector_size, const op_t sel_op, hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C);

#endif
