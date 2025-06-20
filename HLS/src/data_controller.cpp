#include "data_controller.hpp"
#include "definitions.hpp"

void data_mover(hls::stream<Data_t> &fifo_A, hls::stream<Data_t> &fifo_B, hls::stream<Data_t> &fifo_C, hls::stream<Command_t> &command_request, hls::stream<Command_t> &command_response){

    bool finish = false;

    bool on_going_read_request[2], vector_data_done[2];

    Command_t request, response;

    for(unsigned int i = 0; i<2; i++){
        on_going_read_request[i]=false;
        vector_data_done[i]=false;
    }

    while(!finish){

        request = 0;
        response = 0;

        if(fifo_A.size() < TRANSMISSION_READ_THRESHOLD && !vector_data_done[0]){

            //Read data request
            request[0] = READ_MODE;

            //Fifo id
            request.range(NUMBER_QUEUES_SIZE, 1) = 0;

            //Block size to read
            request.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = BLOCK_SIZE;

            command_request.write(request);

            on_going_read_request[0] = true;

        }else if (fifo_B.size() < TRANSMISSION_READ_THRESHOLD && !vector_data_done[1]) {

            //Read data request
            request[0] = READ_MODE;

            //Fifo id
            request.range(NUMBER_QUEUES_SIZE, 1) = 1;

            //Block size to read
            request.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = BLOCK_SIZE;

            command_request.write(request);

            on_going_read_request[1] = true;
        
        }else if ((fifo_C.size() > TRANSMISSION_WRITE_THRESHOLD || (vector_data_done[0] && vector_data_done[1])) && !fifo_C.empty()) {

            ap_uint<BLOCK_SIZE> vector_data = 0;

            for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                vector_data.range((i+1)*BLOCK_SIZE, i*BLOCK_SIZE) = fifo_C.read();
            }

            //Write data request
            request[0] = WRITE_MODE;

            //Fifo id
            request.range(NUMBER_QUEUES_SIZE, 1) = 2;

            //Block data to write
            request.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1) = vector_data;

            command_request.write(request);
            
        }

        if(command_response.read_nb(response)){

            bool remaining_data;
            ap_uint<NUMBER_QUEUES_SIZE> fifo_id;
            ap_uint<BLOCK_SIZE> vector_data;

            remaining_data = response[0];
            fifo_id = response.range(NUMBER_QUEUES_SIZE, 1);
            vector_data = response.range( COMMAND_SIZE-1, NUMBER_QUEUES_SIZE+1);

            switch(fifo_id){
                case 0:

                    for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                        fifo_A.write(vector_data.range((i+1)*BLOCK_SIZE, i*BLOCK_SIZE));
                    }

                    vector_data_done[0] = !remaining_data;
                    on_going_read_request[0] = false;
                    break;

                case 1:
                    for(unsigned int i=0; i<BLOCK_SIZE/DATA_SIZE; i++){
                        fifo_B.write(vector_data.range((i+1)*BLOCK_SIZE, i*BLOCK_SIZE));
                    }

                    vector_data_done[1] = !remaining_data;
                    on_going_read_request[1] = false;
                    break;

            }
        }

        finish = vector_data_done[0] && vector_data_done[1] && fifo_A.size()==0 && fifo_B.size()==0 && fifo_C.size()==0;

    }

}
