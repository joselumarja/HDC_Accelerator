#ifndef _HDC_ACCELERATOR_COMPONENT_
#define _HDC_ACCELERATOR_COMPONENT_

#include <hls_stream.h>
#include <hls_task.h>

#include "definitions.hpp"
#include "data_controller.hpp"

#define BINDING 0
#define BUNDLING 1
#define PERMUTATION 2
#define SIMILARITY 3

void hdc_accelerator_component(hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C, hls::stream<bool> &fifo_accelerator_finish, hls::stream<bool> &fifo_data_mover_finish);

#endif
