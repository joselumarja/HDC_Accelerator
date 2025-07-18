#include "hdc_accelerator_component.hpp"

//void hdc_accelerator_component(const unsigned int vector_size, const op_t sel_op, hls::stream<Command_t, FIFO_SIZE> &command_request, hls::stream<Command_t, FIFO_SIZE> &command_response){
void hdc_accelerator_component(hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C, hls::stream<bool> &fifo_accelerator_finish, hls::stream<bool> &fifo_data_mover_finish){

	const unsigned int vector_size = VECTOR_SIZE/DATA_SIZE;
	const op_t sel_op = SEL_OP;

    unsigned int i = 0;
    data_t A, B, C, shifting_register, overflow_block_bits;
    block_data_t similarity_counter;

    switch(sel_op){
    case BINDING:

    	/*for(unsigned int i=0; i<vector_size; i++){
    		A = fifo_A.read();
    		B = fifo_B.read();

    		C = A ^ B;

    		fifo_C.write(C);
    	}*/

    	while (i < vector_size) {
    	    // Verifica que hay datos en A y B, y espacio en C
    	    if (!fifo_A.empty() && !fifo_B.empty() && !fifo_C.full()) {
    	        A = fifo_A.read();
    	        B = fifo_B.read();

    	        C = A ^ B;
    	        fifo_C.write(C);

    	        i++;
    	    }
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
    
    //Handshake in component termination
    fifo_accelerator_finish.write(true);
    fifo_data_mover_finish.read();

}
