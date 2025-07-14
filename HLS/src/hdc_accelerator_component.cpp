#include "hdc_accelerator_component.hpp"

void hdc_accelerator_component(const unsigned int vector_size, const op_t sel_op, hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response){

	#pragma HLS DATAFLOW

    hls_thread_local hls::stream<data_t> fifo_A("fifo A");
    hls_thread_local hls::stream<data_t> fifo_B("fifo B");
    hls_thread_local hls::stream<data_t> fifo_C("fifo C");

    hls_thread_local hls::stream<bool> fifo_finish("finish signal");

    data_t A, B, C, shifting_register, overflow_block_bits;
    block_data_t similarity_counter;

    hls_thread_local hls::task t_data_mover(data_mover, fifo_A, fifo_B, fifo_C, fifo_finish, data_request, data_response);

    switch(sel_op){
    case BINDING:

    	for(unsigned int i=0; i<vector_size; i++){
    		A = fifo_A.read();
    		B = fifo_B.read();

    		C = A ^ B;

    		fifo_C.write(C);
    	}
    	break;

    case BUNDLING:

    	for(unsigned int i=0; i<vector_size; i++){
    		A = fifo_A.read();
			B = fifo_B.read();

			C = A | B;

			fifo_C.write(C);
    	}
    	break;

    case PERMUTATION:

    	//Cantidad de shift a la izquierda (MAXIMO DATA_SIZE)
    	B = fifo_B.read();

    	A = fifo_A.read();

    	overflow_block_bits = A >> (DATA_SIZE - B);

    	shifting_register = A << B;

    	for(unsigned int i=1; i<vector_size; i++){
    		A = fifo_A.read();

    		//Curent block is shifted block plus next block overflow
    		C = shifting_register | A >> (DATA_SIZE-B);

    		shifting_register = A << B;

    		fifo_C.write(C);
    	}

    	C = shifting_register | overflow_block_bits;

    	fifo_C.write(C);

    	break;

    case SIMILARITY:

    	//Reset counter value
    	similarity_counter = 0;

    	for(unsigned int i=0; i<vector_size; i++){
			A = fifo_A.read();
			B = fifo_B.read();

			C = A ^ B;

			//Popcount
			for(unsigned int j=0; j<DATA_SIZE; j++){
				if(C[j])
					similarity_counter ++;
			}
		}

    	for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
    		fifo_C.write(similarity_counter.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
    	}

		break;
    }
    
    fifo_finish.read();

}
