#include <stdio.h>
#include "definitions.hpp"
#include "hdc_accelerator_component.hpp"

#define VECTOR_SIZE 10000
#define SEL_OP 3

ap_uint<BLOCK_SIZE> read_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> number_elements, unsigned int &counter);
void write_data(unsigned int V[VECTOR_SIZE], ap_uint<BLOCK_SIZE> block, unsigned int &counter);

int main(){

    unsigned int A[VECTOR_SIZE];
    unsigned int B[VECTOR_SIZE];
    unsigned int C[VECTOR_SIZE];
    
    unsigned int a_counter=0, b_counter=0, c_counter=0;

    Command_t request, response;

    bool remaining_data, mode;
    ap_uint<NUMBER_QUEUES_SIZE> fifo_id;
    ap_uint<BLOCK_SIZE> vector_data, vector_data_response;


    for(unsigned int i=0; i<VECTOR_SIZE; i++){
    	A[i]=1;
    	B[i]=1;
    	C[i]=0;
    }

    hls::stream<unsigned int> vector_size_stream;
    hls::stream<Op_t> sel_op_stream;

    hls::stream<Command_t> data_request;
    hls::stream<Command_t> data_response;

    vector_size_stream.write(VECTOR_SIZE);
    sel_op_stream.write(SEL_OP);

    hls::task t_component(hdc_accelerator_component, vector_size_stream, sel_op_stream, data_request, data_response);

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
