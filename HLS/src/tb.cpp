#include <stdio.h>

#include "hdc_accelerator_component.hpp"

int main(){

	unsigned int vector_size = VECTOR_SIZE/DATA_SIZE;
	op_t sel_op = 0;

	hls::stream<data_t, FIFO_SIZE> fifo_A("fifo A");
	hls::stream<data_t, FIFO_SIZE> fifo_B("fifo B");
	hls::stream<data_t, FIFO_SIZE> fifo_C("fifo C");

	data_t A, B, C;

	bool finish_flag;

	for(unsigned int i=0; i<vector_size; i++){
		A = 0x7;
		B = 0x7;

		fifo_A.write(A);
		fifo_B.write(B);

	}


	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C);

	for(unsigned int i=0; i<vector_size; i++){
		C = fifo_C.read();
	}

    printf("Operación finalizada\n");

    return 0;
}
