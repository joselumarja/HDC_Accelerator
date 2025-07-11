#include "data_controller.hpp"
#include "definitions.hpp"

void data_mover(hls::stream<Data_t> &fifo_A, hls::stream<Data_t> &fifo_B, hls::stream<Data_t> &fifo_C, hls::stream<Command_t> &command_request, hls::stream<Command_t> &command_response){

    bool on_going_read_request[2];
    bool vector_data_done[2];

    bool A_condition = false, B_condition = false, C_condition = false;

    Command_t request, response;

    CurrentState: unsigned int state = READ_0;

    for(unsigned int i = 0; i<2; i++){
        on_going_read_request[i]=false;
        vector_data_done[i]=false;
    }

    DataMoverLoop: while(true){

        request = 0;
        response = 0;

        switch(state){
            case WAITING_DATA:

                if(command_response.read_nb(response)){

                    bool remaining_data;
                    ap_uint<NUMBER_QUEUES_SIZE> fifo_id;
                    ap_uint<BLOCK_SIZE> vector_data;

                    remaining_data = response[0];
                    fifo_id = response.range(NUMBER_QUEUES_SIZE, 1);
                    vector_data = response.range(COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1);

                    switch(fifo_id){
                        case 0:

                            for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                                fifo_A.write(vector_data.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
                            }

                            vector_data_done[0] = !remaining_data;
                            on_going_read_request[0] = false;
                            break;

                        case 1:
                            for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                                fifo_B.write(vector_data.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE));
                            }

                            vector_data_done[1] = !remaining_data;
                            on_going_read_request[1] = false;
                            break;

                    }
                }

            break;

            case READ_0:

                //Read data request
                request[0] = READ_MODE;

                //Fifo id
                request.range(NUMBER_QUEUES_SIZE, 1) = 0;

                //Block size to read
                request.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = BLOCK_SIZE;

                command_request.write(request);

                on_going_read_request[0] = true;

            break;

            case READ_1:

                //Read data request
                request[0] = READ_MODE;

                //Fifo id
                request.range(NUMBER_QUEUES_SIZE, 1) = 1;

                //Block size to read
                request.range(COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = BLOCK_SIZE;

                command_request.write(request);

                on_going_read_request[1] = true;

            break;

            case WRITE_2:

                ap_uint<BLOCK_SIZE> vector_data = 0;

                for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                    vector_data.range(((i+1)*DATA_SIZE)-1, i*DATA_SIZE) = fifo_C.read();
                }

                //Write data request
                request[0] = WRITE_MODE;

                //Fifo id
                request.range(NUMBER_QUEUES_SIZE, 1) = 2;

                //Block data to write
                request.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = vector_data;

                command_request.write(request);

            break;

        }


        //MAQUINA DE ESTADOS

        A_condition = fifo_A.size() < TRANSMISSION_READ_THRESHOLD && !vector_data_done[0] && !on_going_read_request[0];
        B_condition = fifo_B.size() < TRANSMISSION_READ_THRESHOLD && !vector_data_done[1] && !on_going_read_request[1];

        //First part to control normal write dataflow, Second part to write lasting elements when all read transactions finish
        C_condition = (fifo_C.size() > TRANSMISSION_WRITE_THRESHOLD && !fifo_C.empty()) || (vector_data_done[0] && vector_data_done[1]);

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

        if(vector_data_done[0] && fifo_A.size()==0 && vector_data_done[1] && fifo_B.size()==0 && !(fifo_C.size()==0))
            break;

    }

}
