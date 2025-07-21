#include "hdc_accelerator_component.hpp"

void hdc_accelerator_component(const unsigned int vector_size, const op_t sel_op, hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C, hls::stream<bool> &fifo_accelerator_finish, hls::stream<bool> &fifo_data_mover_finish){
#pragma HLS INTERFACE mode=ap_ctrl_hs depth=FIFO_SIZE port=fifo_A
#pragma HLS INTERFACE mode=ap_ctrl_hs depth=FIFO_SIZE port=fifo_B
#pragma HLS INTERFACE mode=ap_ctrl_hs depth=FIFO_SIZE port=fifo_C

    unsigned int i = 0;
    data_t A, B, C, shifting_register, overflow_block_bits;
    block_data_t similarity_counter;

    //SINTAXIS DE LA ALU PARA QUE SEA FRIENDLY CON FLUJOS DE DATOS
    switch(sel_op){
    case BINDING:

    	BindingOpControlLoop: while (i < vector_size) {
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

    	BundlingOpControlLoop: while(i < vector_size){
    		if (!fifo_A.empty() && !fifo_B.empty() && !fifo_C.full()) {
				A = fifo_A.read();
				B = fifo_B.read();

				C = A | B;

				fifo_C.write(C);

				i++;
			}
    	}
    	break;

    case PERMUTATION:

    	PermutationOpReadyReadLoop: while(fifo_A.empty() || fifo_B.empty());

    	//Cantidad de shift a la izquierda (MAXIMO DATA_SIZE)
    	B = fifo_B.read();

    	A = fifo_A.read();

    	overflow_block_bits = A >> (DATA_SIZE - B);

    	shifting_register = A << B;

    	PermutationOpControlLoop: while(i < vector_size){
    		if(!fifo_A.empty() && !fifo_C.full()){
    			A = fifo_A.read();

				//Curent block is shifted block plus next block overflow
				C = shifting_register | A >> (DATA_SIZE-B);

				shifting_register = A << B;

				fifo_C.write(C);

				i++;
    		}
    	}

    	PermutationOpReadyWriteLoop: while(fifo_C.full());

    	C = shifting_register | overflow_block_bits;

    	fifo_C.write(C);

    	break;

    case SIMILARITY:

    	//Reset counter value
    	similarity_counter = 0;

    	SimilarityOpControlLoop: while(i<vector_size){
    	    if(!fifo_A.empty() && !fifo_B.empty()){
				A = fifo_A.read();
				B = fifo_B.read();

				C = A ^ B;

				//Popcount
				PopCountOperationLoop: for(unsigned int j=0; j<DATA_SIZE; j++){
					if(C[j])
						similarity_counter ++;
				}

				i++;
    	    }
		}

    	//Solo puede bloquearse si el tamaño del stream es menor que las iteraciones del bucle
    	SimilarityOpWriteLoop: for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
    		fifo_C.write(similarity_counter.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
    	}

		break;
    }
    
    //Syncronization in component termination
    fifo_accelerator_finish.write(true);
    fifo_data_mover_finish.read();

}
