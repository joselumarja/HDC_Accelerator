#include <hls_stream.h>
#include <hls_task.h>

#include "definitions.hpp"
#include "hdc_accelerator_component.hpp"

void hdc_accelerator_component_wrapper(const unsigned int vector_size, const op_t sel_op, unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE]);
