#include "hdc_accelerator_component.hpp"

void hdc_accelerator_component(const unsigned int vector_size, const op_t sel_op, hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C){

#pragma HLS DATAFLOW
//#pragma HLS PIPELINE II=1

    unsigned int i = 0;

    data_t A, B, C, shifting_register, overflow_block_bits;
    block_data_t similarity_counter;

    switch(sel_op){
    case BINDING:

#pragma HLS PIPELINE II=1
    	BindingOpControlLoop: for(i=0; i<vector_size; i++){
			A = fifo_A.read();
    	    B = fifo_B.read();

    	    C = A ^ B;
    	    fifo_C.write(C);
		}

    	break;

    case BUNDLING:

#pragma HLS PIPELINE II=1
    	BundlingOpControlLoop: for(i=0; i<vector_size; i++){
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

#pragma HLS PIPELINE II=1
    	PermutationOpControlLoop: for(i=0; i<vector_size-1; i++){

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

#pragma HLS PIPELINE II=1
    	SimilarityOpControlLoop: for(i=0; i<vector_size; i++){
			A = fifo_A.read();
			B = fifo_B.read();

			C = A ^ B;

			//Popcount
			PopCountOperationLoop: for(unsigned int j=0; j<DATA_SIZE; j++){
				if(C[j])
					similarity_counter ++;
			}
		}

    	SimilarityOpWriteLoop: for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
    		fifo_C.write(similarity_counter.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
    	}

		break;
    }

}
