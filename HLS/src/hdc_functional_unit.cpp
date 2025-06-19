#include "hdc_functional_unit.hpp"
//#include "xf_blas/axpy.hpp"

void functional_unit(Data_t &A, Data_t &B, Data_t &C, Op_t &sel_op){
//#pragma HLS INTERFACE mode=ap_fifo port=A
//#pragma HLS INTERFACE mode=ap_fifo port=B
//#pragma HLS INTERFACE mode=ap_fifo port=C
//#pragma HLS INTERFACE mode=ap_fifo port=sel_op

    Data_t a_b_and = A & B;
    Data_t a_b_xor = A ^ B;

    switch(sel_op){
        case 0:
            C = a_b_xor;
            break;

        case 1:

            C = a_b_and | a_b_xor;
            break;

        case 2:
            C = A >> B;
            break;

        case 3:
            C = a_b_and;
            //C = xf::blas::axpy<Data_t, DATA_SIZE>(DATA_SIZE, 1, A, B, C);
            break;
    }
}