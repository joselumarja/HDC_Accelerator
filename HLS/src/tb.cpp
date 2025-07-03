#include <stdio.h>
#include <thread>
#include <functional>

#include "definitions.hpp"
#include "hdc_accelerator_component.hpp"

#define VECTOR_SIZE 1024
#define SEL_OP 3

ap_uint<BLOCK_SIZE> read_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> number_elements, unsigned int &counter);
void write_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> block, unsigned int &counter);
void memory_controller(unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE], hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response);

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
    Op_t sel_op = SEL_OP;

    hls::stream<Command_t> data_request;
    hls::stream<Command_t> data_response;

    std::thread t_memory_controller(memory_controller, std::ref(A), std::ref(B), std::ref(C), std::ref(data_request), std::ref(data_response));

    hdc_accelerator_component(vector_size, sel_op, data_request, data_response);

    t_memory_controller.join();

    printf("Operación finalizada\n");

    return 0;
}

ap_uint<BLOCK_SIZE> read_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> number_elements, unsigned int &counter){

	ap_uint<BLOCK_SIZE> block;

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

void memory_controller(unsigned int A[VECTOR_SIZE], unsigned int B[VECTOR_SIZE], unsigned int C[VECTOR_SIZE], hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response){

	unsigned int a_counter=0, b_counter=0, c_counter=0;

	Command_t request, response;

	bool remaining_data, mode;
	ap_uint<NUMBER_QUEUES_SIZE> fifo_id;
	ap_uint<BLOCK_SIZE> vector_data, vector_data_response;

	while(c_counter < VECTOR_SIZE){

		request = data_request.read();

		mode = request[0];
		fifo_id = request.range(NUMBER_QUEUES_SIZE, 1);
		vector_data = request.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1);


		if(mode == READ_MODE){

			printf("Peticion de lectura de: %d,  cantidad: %d\n", fifo_id, vector_data);

			switch(fifo_id){
			case 0:
				vector_data_response = read_data(A, vector_data, a_counter);
				remaining_data = a_counter<VECTOR_SIZE;
				break;
			case 1:
				vector_data_response = read_data(B, vector_data, b_counter);
				remaining_data = b_counter<VECTOR_SIZE;
				break;
			}

			response[0] = remaining_data;
			response.range(NUMBER_QUEUES_SIZE, 1) = fifo_id;
			response.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = vector_data_response;

			data_response.write(response);

		}else{
			printf("Peticion de escritura de: %d,  valor: %d\n", fifo_id, vector_data);

			write_data(C, vector_data, c_counter);
		}
	}
}
