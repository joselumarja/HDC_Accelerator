#include <stdio.h>

#include "definitions.hpp"
#include "hdc_accelerator_component_wrapper.hpp"

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
