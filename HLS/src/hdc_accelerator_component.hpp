#ifndef _HDC_ACCELERATOR_COMPONENT_
#define _HDC_ACCELERATOR_COMPONENT_

#include <hls_stream.h>
#include <ap_int.h>


#define BINDING 0
#define BUNDLING 1
#define PERMUTATION 2
#define SIMILARITY 3

#define FIFO_SIZE 16
#define BLOCK_SIZE 32

#define DATA_SIZE 8

typedef ap_uint<DATA_SIZE> data_t;
typedef ap_uint<BLOCK_SIZE> block_data_t;
typedef ap_uint<2> op_t;

void hdc_accelerator_component(const unsigned int vector_size, const op_t sel_op, hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C);

#endif
