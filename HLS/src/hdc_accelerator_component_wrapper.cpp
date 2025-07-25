#include "hdc_accelerator_component_wrapper.hpp"

block_data_t read_data(unsigned int V[VECTOR_SIZE], block_data_t number_elements, unsigned int &counter);
void write_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> block, unsigned int &counter);

void hdc_accelerator_component_wrapper(const unsigned int vector_size, const op_t sel_op, unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE]){

	unsigned int a_counter = 0, b_counter = 0, c_counter = 0;

	bool finish_flag = false;

	Command_t request, response;

	id_queue_t fifo_id;
	block_data_t vector_data, vector_data_response;

#ifdef __SYNTHESIS__

#pragma HLS DATAFLOW
	hls::stream<Command_t, FIFO_SIZE> command_request;
	hls::stream<Command_t, FIFO_SIZE> command_response;

	hls::stream<data_t, FIFO_SIZE> fifo_A("fifo A");
	hls::stream<data_t, FIFO_SIZE> fifo_B("fifo B");
	hls::stream<data_t, FIFO_SIZE> fifo_C("fifo C");

	hls::stream<bool> fifo_accelerator_finish("accelerator finish signal");
	hls::stream<bool> fifo_data_mover_finish("data mover finish signal");

	hdc_accelerator_component(vector_size, sel_op, fifo_A, fifo_B, fifo_C, fifo_accelerator_finish, fifo_data_mover_finish);

	data_mover(fifo_A, fifo_B, fifo_C, fifo_accelerator_finish, fifo_data_mover_finish, command_request, command_response);

#else
	hls::stream<Command_t, FIFO_SIZE> command_request;
	hls::stream<Command_t, FIFO_SIZE> command_response;

	hls::stream<data_t, FIFO_SIZE> fifo_A("fifo A");
	hls::stream<data_t, FIFO_SIZE> fifo_B("fifo B");
	hls::stream<data_t, FIFO_SIZE> fifo_C("fifo C");

	hls::stream<bool> fifo_accelerator_finish("accelerator finish signal");
	hls::stream<bool> fifo_data_mover_finish("data mover finish signal");

	std::thread t_accelerator_component(hdc_accelerator_component, vector_size, sel_op, std::ref(fifo_A), std::ref(fifo_B), std::ref(fifo_C), std::ref(fifo_accelerator_finish), std::ref(fifo_data_mover_finish));

	std::thread t_data_mover(data_mover, std::ref(fifo_A), std::ref(fifo_B), std::ref(fifo_C), std::ref(fifo_accelerator_finish), std::ref(fifo_data_mover_finish), std::ref(command_request), std::ref(command_response));
#endif

	MemoryControllerLoop: while(!finish_flag){

		request = command_request.read();

		finish_flag = request.last;

		if(!finish_flag){
			fifo_id = request.id_queue;
			vector_data = request.data_block;

			switch(fifo_id){
			case 0:
				PRINT(("Peticion de lectura de: %d,  cantidad: %d\n", (int) fifo_id, (int) vector_data));

				vector_data_response = read_data(A, vector_data, a_counter);

				response.last = a_counter>=VECTOR_SIZE;
				response.id_queue = fifo_id;
				response.data_block = vector_data_response;

				command_response.write(response);
				break;

			case 1:
				PRINT(("Peticion de lectura de: %d,  cantidad: %d\n", (int) fifo_id, (int) vector_data));

				vector_data_response = read_data(B, vector_data, b_counter);

				response.last = b_counter>=VECTOR_SIZE;
				response.id_queue = fifo_id;
				response.data_block = vector_data_response;

				command_response.write(response);
				break;

			case 2:
				PRINT(("Peticion de escritura de: %d,  valor: %d\n", (int) fifo_id, (int) vector_data));

				write_data(C, vector_data, c_counter);
				break;
			}
		}
	}

#ifndef __SYNTHESIS__
	t_accelerator_component.join();
	t_data_mover.join();
#endif

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
