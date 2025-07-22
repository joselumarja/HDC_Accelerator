#include <stdio.h>

#include "definitions.hpp"
#include "hdc_accelerator_component.hpp"

int main(){

	unsigned int vector_size = VECTOR_SIZE/DATA_SIZE;
	op_t sel_op = 0;

	hls::stream<data_t, FIFO_SIZE> fifo_A("fifo A");
	hls::stream<data_t, FIFO_SIZE> fifo_B("fifo B");
	hls::stream<data_t, FIFO_SIZE> fifo_C("fifo C");

	hls::stream<bool> fifo_accelerator_finish("accelerator finish signal");
	hls::stream<bool> fifo_data_mover_finish("data mover finish signal");

	data_t A, B, C;

	bool finish_flag;

	for(unsigned int i=0; i<vector_size; i++){
		A = 0x7;
		B = 0x7;

		fifo_A.write(A);
		fifo_B.write(B);

	}

	fifo_data_mover_finish.write(true);


	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C, fifo_accelerator_finish, fifo_data_mover_finish);

	for(unsigned int i=0; i<vector_size; i++){
		C = fifo_C.read();
	}

	while(!fifo_accelerator_finish.read_nb(finish_flag));

    //printf("Operación finalizada\n");

    //printf("A:%d B:%d C:%d\n", (int) fifo_A.size(), (int) fifo_B.size(), (int) fifo_C.size());

    return 0;
}
