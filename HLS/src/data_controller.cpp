#include "data_controller.hpp"
#include "definitions.hpp"

void data_mover(hls::stream<data_t, FIFO_SIZE> &fifo_A, hls::stream<data_t, FIFO_SIZE> &fifo_B, hls::stream<data_t, FIFO_SIZE> &fifo_C, hls::stream<bool> &fifo_accelerator_finish, hls::stream<bool> &fifo_data_mover_finish, hls::stream<Command_t, FIFO_SIZE> &command_request, hls::stream<Command_t, FIFO_SIZE> &command_response){

    bool on_going_read_request[2];
    bool vector_data_done[2];

    bool A_condition = false, B_condition = false, C_condition = false;

    Command_t request, response;

    CurrentState: unsigned int state = WAITING_DATA;

    bool finish_flag = false, finish = false;

    for(unsigned int i = 0; i<2; i++){
        on_going_read_request[i]=false;
        vector_data_done[i]=false;
    }

    DataMoverLoop: while(!finish){

        switch(state){

            case WAITING_DATA:

                if(command_response.read_nb(response)){

                    block_data_t vector_data;

                    vector_data = response.data_block;

                    switch(response.id_queue){
                        case 0:

                            FifoAFillForLoopDataReceived:for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                                fifo_A.write(vector_data.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
                            }

                            if(response.last)
                            	vector_data_done[0] = true;

                            on_going_read_request[0] = false;
                            break;

                        case 1:
                        	FifoBFillForLoopDataReceived:for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                                fifo_B.write(vector_data.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
                            }

                            if(response.last)
                            	vector_data_done[1] = true;

                            on_going_read_request[1] = false;
                            break;

                    }

                }else
                	fifo_accelerator_finish.read_nb(finish_flag);

            break;

            case READ_0:

                //Always false
                request.last = false;

                //Fifo id
                request.id_queue = 0;

                //Block size to read
                request.data_block = BLOCK_SIZE;

                command_request.write(request);

                on_going_read_request[0] = true;

            break;

            case READ_1:

            	//Always false
				request.last = false;

				//Fifo id
				request.id_queue = 1;

				//Block size to read
				request.data_block = BLOCK_SIZE;

                command_request.write(request);

                on_going_read_request[1] = true;

            break;

            case WRITE_2:

                block_data_t vector_data = 0;

                FifoCForLoopForDataSending:for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                    vector_data.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE) = fifo_C.read();
                }

                //Always false
				request.last = false;

				//Fifo id
				request.id_queue = 2;

				//Block size to read
				request.data_block = vector_data;

                command_request.write(request);

            break;

        }


        //MAQUINA DE ESTADOS

        A_condition = (fifo_A.size() < TRANSMISSION_READ_THRESHOLD) && !vector_data_done[0] && !on_going_read_request[0];
        B_condition = (fifo_B.size() < TRANSMISSION_READ_THRESHOLD) && !vector_data_done[1] && !on_going_read_request[1];

        //First part to control normal write dataflow, Second part to write lasting elements when all read transactions finish
        C_condition = ((fifo_C.size() > TRANSMISSION_WRITE_THRESHOLD) && !fifo_C.empty()) || (vector_data_done[0] && vector_data_done[1]);

        switch(state){
            case WAITING_DATA:
                if(A_condition)
                    state = READ_0;
                else if(B_condition)
                    state = READ_1;
                else if(C_condition)
                    state = WRITE_2;
                else
                    state = WAITING_DATA;
            break;

            case READ_0:
                if (B_condition)
                    state = READ_1;
                else if (C_condition)
                    state = WRITE_2;
                else
                    state = WAITING_DATA;
            break;

            case READ_1:
                if(C_condition)
                    state = WRITE_2;
                else if (A_condition)
                    state = READ_0;
                else
                    state = WAITING_DATA;
            break;

            case WRITE_2:
                if(A_condition)
                    state = READ_0;
                else if(B_condition)
                    state = READ_1;
                else
                    state = WAITING_DATA;
            break;

        }

        if(finish_flag && fifo_C.size()==0){

        	//data movement finish notification
			request.last = true;
			command_request.write(request);

        	//data mover finish notification
            fifo_data_mover_finish.write(true);

            //Espera activa al finalizar el movimiento de datos para que no se resetee la tarea
            //while(true);
            finish = true;
        }

    }

}
