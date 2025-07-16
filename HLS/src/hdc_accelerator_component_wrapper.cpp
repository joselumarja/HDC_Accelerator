#include "hdc_accelerator_component_wrapper.hpp"

block_data_t read_data(unsigned int V[VECTOR_SIZE], block_data_t number_elements, unsigned int &counter);
void write_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> block, unsigned int &counter);

void hdc_accelerator_component_wrapper(const unsigned int vector_size, const op_t sel_op, unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE]){

#pragma HLS DATAFLOW

	unsigned int a_counter=0, b_counter=0, c_counter=0;

	bool finish_flag=false;

	Command_t request, response;

	id_queue_t fifo_id;
	block_data_t vector_data, vector_data_response;

    hls_thread_local hls::stream<Command_t, FIFO_SIZE> command_request;
    hls_thread_local hls::stream<Command_t, FIFO_SIZE> command_response;

    hls_thread_local hls::task t_accelerator_component(hdc_accelerator_component, command_request, command_response);

	MemoryControllerLoop: while(!finish_flag){

		request = command_request.read();

		finish_flag = request.last;

		if(!finish_flag){
			fifo_id = request.id_queue;
			vector_data = request.data_block;

			switch(fifo_id){
			case 0:
				//printf("Peticion de lectura de: %d,  cantidad: %d\n", (int) fifo_id, (int) vector_data);

				vector_data_response = read_data(A, vector_data, a_counter);

				response.last = a_counter>=VECTOR_SIZE;
				response.id_queue = fifo_id;
				response.data_block = vector_data_response;

				command_response.write(response);
				break;

			case 1:
				//printf("Peticion de lectura de: %d,  cantidad: %d\n", (int) fifo_id, (int) vector_data);

				vector_data_response = read_data(B, vector_data, b_counter);

				response.last = b_counter>=VECTOR_SIZE;
				response.id_queue = fifo_id;
				response.data_block = vector_data_response;

				command_response.write(response);
				break;

			case 2:
				//printf("Peticion de escritura de: %d,  valor: %d\n", (int) fifo_id, (int) vector_data);

				write_data(C, vector_data, c_counter);
				break;
			}
		}
	}


}

block_data_t read_data(unsigned int V[VECTOR_SIZE], block_data_t number_elements, unsigned int &counter){

	block_data_t block;

	for(unsigned int i = 0; i < number_elements; i++){
		block[i]=V[counter++];
	}

	return block;
}

void write_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> block, unsigned int &counter){

	for(unsigned int i = 0; i < BLOCK_SIZE; i++){
		V[counter++]=block[i];
	}
}
