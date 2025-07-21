#include <stdio.h>

#include "definitions.hpp"
#include "hdc_accelerator_component_wrapper.hpp"

block_data_t read_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> number_elements, unsigned int &counter);
void write_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> block, unsigned int &counter);
void memory_controller(unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE], hls::stream<Command_t, FIFO_SIZE> &command_request, hls::stream<Command_t, FIFO_SIZE> &command_response);

int main(){

	unsigned int A[VECTOR_SIZE];
	unsigned int B[VECTOR_SIZE];
	unsigned int C[VECTOR_SIZE];

	for(unsigned int i=0; i<VECTOR_SIZE; i++){
		A[i]=1;
		B[i]=1;
		C[i]=0;
	}

    unsigned int vector_size = VECTOR_SIZE/DATA_SIZE;
    op_t sel_op = SEL_OP;

    hdc_accelerator_component_wrapper(vector_size, sel_op, A, B, C);

    printf("Operación finalizada\n");

    return 0;
}
