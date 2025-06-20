#include "hdc_accelerator_component.hpp"

void hdc_accelerator_component(hls::stream<unsigned int> &vector_size_stream, hls::stream<Op_t> &sel_op_stream, hls::stream<Command_t> &data_request, hls::stream<Command_t> &data_response){

#pragma HLS DATAFLOW

	const unsigned int vector_size = vector_size_stream.read();
	const Op_t sel_op = sel_op_stream.read();

    hls_thread_local hls::stream<Data_t> fifo_A("fifo A");
    hls_thread_local hls::stream<Data_t> fifo_B("fifo B");
    hls_thread_local hls::stream<Data_t> fifo_C("fifo C");

    Data_t A, B, C;

    hls_thread_local hls::task t_data_mover(data_mover, fifo_A, fifo_B, fifo_C, data_request, data_response);

    for(unsigned int i=0; i<vector_size; i++){

        A = fifo_A.read();
        B = fifo_B.read();

        functional_unit(A, B, C, sel_op);

        fifo_C.write(C);
    }
    
}
