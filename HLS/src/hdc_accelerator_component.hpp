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

void hdc_accelerator_component(const unsigned int vector_size, const Op_t sel_op, hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response);

#endif
