#include "hdc_accelerator_component.hpp"
#include "data_controller.hpp"
#include "definitions.hpp"
#include "hdc_functional_unit.hpp"

void hdc_accelerator_component(unsigned int &vector_size, Op_t &sel_op, hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response){

    hls::stream<Data_t> fifo_A, fifo_B, fifo_C;

    Data_t A, B, C;

    data_mover(fifo_A, fifo_B, fifo_C, data_request, data_response);

    for(unsigned int i=0; i<vector_size; i++){

        A = fifo_A.read();
        B = fifo_B.read();

        functional_unit(A, B, C, sel_op);

        fifo_C.write(C);
    }
    
}