#include <stdio.h>

#include "hdc_accelerator_component.hpp"

#define VECTOR_SIZE 128

int main(){

	unsigned int vector_size = VECTOR_SIZE/DATA_SIZE;
	op_t sel_op;

	hls::stream<data_t, FIFO_SIZE> fifo_A("fifo A");
	hls::stream<data_t, FIFO_SIZE> fifo_B("fifo B");
	hls::stream<data_t, FIFO_SIZE> fifo_C("fifo C");

	data_t A, B, C;
	block_data_t shift_value, similarity_counter;

	/*//BINDING TEST
	sel_op = 0;

	for(unsigned int i=0; i<vector_size; i++){
		A = 0x7;
		B = 0x7;

		fifo_A.write(A);
		fifo_B.write(B);

		printf("A: %d\n", (int) A);
		printf("B: %d\n", (int) B);
	}

	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C);

	for(unsigned int i=0; i<vector_size; i++){
		C = fifo_C.read();

		printf("C: %d\n", (int) C);
	}

	printf("BINDING TEST FINALIZADO\n");*/

	/*//BUNDLING TEST
	sel_op = 1;

	for(unsigned int i=0; i<vector_size; i++){
		A = 0x7;
		B = 0x7;

		fifo_A.write(A);
		fifo_B.write(B);

		printf("A: %d\n", (int) A);
		printf("B: %d\n", (int) B);
	}

	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C);

	for(unsigned int i=0; i<vector_size; i++){
		C = fifo_C.read();

		printf("C: %d\n", (int) C);
	}

	printf("BUNDLING TEST FINALIZADO\n");*/

	//PERMUTATION TEST
	/*sel_op = 2;
	shift_value = 4;

	for(unsigned int i=0; i<vector_size; i++){
		A = 0xF;

		fifo_A.write(A);
		
		printf("A: %d\n", (int) A);
	}

	printf("shift_value: %d\n", (int) shift_value);

	for( unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
		B = shift_value.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE);

		fifo_B.write(B);

		printf("B: %d\n", (int) B);
	}

	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C);

	for(unsigned int i=0; i<vector_size; i++){
		C = fifo_C.read();

		printf("C: %d\n", (int) C);
	}

	printf("PERMUTATION TEST FINALIZADO\n");*/

	//SIMILARITY TEST
	sel_op = 3;

	for(unsigned int i=0; i<vector_size; i++){
		A = 0x7;
		B = 0x7;

		fifo_A.write(A);
		fifo_B.write(B);

		printf("A: %d\n", (int) A);
		printf("B: %d\n", (int) B);
	}

	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C);

	for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
		C = fifo_C.read();

		similarity_counter.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE) = C;

		printf("C: %d\n", (int) C);
	}

	printf("similarity_counter: %d\n", (int) similarity_counter);

	printf("SIMILARITY TEST FINALIZADO\n");

    printf("Operación finalizada\n");

    return 0;
}

