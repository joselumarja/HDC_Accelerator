module fifo_round_robin_arbiter #(
)(
    input  logic [2:0] fifo_data_movement_request,
    input  logic [1:0] rr_priority_base,
    output logic [1:0] fifo_grant
);

logic [2:0] rotated_req, rotated_grant, fifo_grant_oh;

always_comb begin : rotate_requests_by_priority

    case (rr_priority_base)

        2'b00: begin
            rotated_req[0] = fifo_data_movement_request[0];
            rotated_req[1] = fifo_data_movement_request[1];
            rotated_req[2] = fifo_data_movement_request[2];
        end

        2'b01: begin
            rotated_req[0] = fifo_data_movement_request[1];
            rotated_req[1] = fifo_data_movement_request[2];
            rotated_req[2] = fifo_data_movement_request[0];
        end

        2'b10: begin
            rotated_req[0] = fifo_data_movement_request[2];
            rotated_req[1] = fifo_data_movement_request[0];
            rotated_req[2] = fifo_data_movement_request[1];
        end

        default: begin
            rotated_req[0] = fifo_data_movement_request[0];
            rotated_req[1] = fifo_data_movement_request[1];
            rotated_req[2] = fifo_data_movement_request[2];
        end

    endcase
end

always_comb begin : generate_rotated_grant

    rotated_grant[0] = rotated_req[0];
    rotated_grant[1] = rotated_req[1] & ~rotated_req[0];
    rotated_grant[2] = rotated_req[2] & ~rotated_req[0] & ~rotated_req[1];

end

always_comb begin : restore_original_fifo_order

    case (rr_priority_base)

        2'b00: begin
            fifo_grant_oh[0] = rotated_grant[0];
            fifo_grant_oh[1] = rotated_grant[1];
            fifo_grant_oh[2] = rotated_grant[2];
        end

        2'b01: begin
            fifo_grant_oh[0] = rotated_grant[2];
            fifo_grant_oh[1] = rotated_grant[0];
            fifo_grant_oh[2] = rotated_grant[1];
        end

        2'b10: begin
            fifo_grant_oh[0] = rotated_grant[1];
            fifo_grant_oh[1] = rotated_grant[2];
            fifo_grant_oh[2] = rotated_grant[0];
        end

        default: begin
            fifo_grant_oh[0] = rotated_grant[0];
            fifo_grant_oh[1] = rotated_grant[1];
            fifo_grant_oh[2] = rotated_grant[2];
        end

    endcase
end

always_comb begin : final_encoding
    case(fifo_grant_oh)
        3'b001: begin
            fifo_grant = 2'd0;
        end

        3'b010: begin
            fifo_grant = 2'd1;
        end

        3'b100: begin
            fifo_grant = 2'd2;
        end
        
        default:fifo_grant = 2'd0;
    endcase
end

endmodule
