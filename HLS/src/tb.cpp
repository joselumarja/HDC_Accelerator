#include <stdio.h>
#include <thread>
#include <functional>

#include "definitions.hpp"
#include "hdc_accelerator_component.hpp"

#define VECTOR_SIZE 32
#define SEL_OP 3

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

    hls::stream<Command_t, FIFO_SIZE> command_request;
    hls::stream<Command_t, FIFO_SIZE> command_response;

    std::thread t_memory_controller(memory_controller, std::ref(A), std::ref(B), std::ref(C), std::ref(command_request), std::ref(command_response));

    hdc_accelerator_component(vector_size, sel_op, command_request, command_response);

    t_memory_controller.join();

    printf("Operación finalizada\n");

    printf("Command request: %d  Command response: %d\n", command_request.size(), command_response.size());

    int size = command_request.size();
    for(int i=0; i<size; i++){
    	Command_t request = command_request.read();

    	printf("Peticion de: %d,  valor: %d, ultimo:%d\n", (int) request.id_queue, (int) request.data_block, (int) request.last);
    }

    return 0;
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

void memory_controller(unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE], hls::stream<Command_t, FIFO_SIZE> &command_request, hls::stream<Command_t, FIFO_SIZE> &command_response){

	unsigned int a_counter=0, b_counter=0, c_counter=0;

	bool finish_flag=false;

	Command_t request, response;

	id_queue_t fifo_id;
	block_data_t vector_data, vector_data_response;

	while(!finish_flag){

		request = command_request.read();

		finish_flag = request.last;

		if(!finish_flag){
			fifo_id = request.id_queue;
			vector_data = request.data_block;

			switch(fifo_id){
			case 0:
				printf("Peticion de lectura de: %d,  cantidad: %d\n", (int) fifo_id, (int) vector_data);


				vector_data_response = read_data(A, vector_data, a_counter);

				response.last = a_counter>=VECTOR_SIZE;
				response.id_queue = fifo_id;
				response.data_block = vector_data_response;

				command_response.write(response);
				break;

			case 1:
				printf("Peticion de lectura de: %d,  cantidad: %d\n", (int) fifo_id, (int) vector_data);

				vector_data_response = read_data(B, vector_data, b_counter);

				response.last = b_counter>=VECTOR_SIZE;
				response.id_queue = fifo_id;
				response.data_block = vector_data_response;

				command_response.write(response);
				break;

			case 2:
				printf("Peticion de escritura de: %d,  valor: %d\n", (int) fifo_id, (int) vector_data);

				write_data(C, vector_data, c_counter);
				break;
			}
		}
	}
}
