`timescale 1ns/1ps

module tb_hdc_fifo_round_robin_arbiter;

    // Señales del testbench
    logic [1:0] rr_priority_base, fifo_grant;
    logic [2:0] fifo_data_movement_request;

    // Instancia del DUT
    fifo_round_robin_arbiter dut (
        .rr_priority_base (rr_priority_base),
        .fifo_data_movement_request         (fifo_data_movement_request),
        .fifo_grant    (fifo_grant)
    );

    // Tarea para aplicar estímulos y comprobar resultados
    task automatic check_result(
        input logic [1:0] tb_rr_priority_base,
        input logic [2:0] tb_fifo_req,
        input logic [1:0] expected_grant
    );
        begin
            rr_priority_base = tb_rr_priority_base;
            fifo_data_movement_request         = tb_fifo_req;

            #1;

            if (fifo_grant !== expected_grant) begin
                $error(
                    "ERROR: rr_priority_base=%b fifo_req=%b -> fifo_grant=%b, esperado=%b",
                    rr_priority_base,
                    fifo_data_movement_request,
                    fifo_grant,
                    expected_grant
                );
            end
            else begin
                $display(
                    "OK: rr_priority_base=%b fifo_req=%b -> fifo_grant=%b",
                    rr_priority_base,
                    fifo_data_movement_request,
                    fifo_grant
                );
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display(" Testbench hdc_fifo_round_robin_arbiter");
        $display("========================================");

        rr_priority_base = 2'b00;
        fifo_data_movement_request         = 3'b000;

        #5;

        // ------------------------------------------------------------
        // Caso rr_priority_base = 00
        // Prioridad: FIFO 0 -> FIFO 1 -> FIFO 2
        // ------------------------------------------------------------

        check_result(2'b00, 3'b000, 2'b00); // Ninguna petición
        check_result(2'b00, 3'b001, 2'b00); // Solo FIFO 0
        check_result(2'b00, 3'b010, 2'b01); // Solo FIFO 1
        check_result(2'b00, 3'b100, 2'b10); // Solo FIFO 2

        check_result(2'b00, 3'b011, 2'b00); // FIFO 0 y 1 -> gana FIFO 0
        check_result(2'b00, 3'b101, 2'b00); // FIFO 0 y 2 -> gana FIFO 0
        check_result(2'b00, 3'b110, 2'b01); // FIFO 1 y 2 -> gana FIFO 1
        check_result(2'b00, 3'b111, 2'b00); // Todas -> gana FIFO 0

        // ------------------------------------------------------------
        // Caso rr_priority_base = 01
        // Prioridad: FIFO 1 -> FIFO 2 -> FIFO 0
        // ------------------------------------------------------------

        check_result(2'b01, 3'b000, 2'b00); // Ninguna petición
        check_result(2'b01, 3'b001, 2'b00); // Solo FIFO 0
        check_result(2'b01, 3'b010, 2'b01); // Solo FIFO 1
        check_result(2'b01, 3'b100, 2'b10); // Solo FIFO 2

        check_result(2'b01, 3'b011, 2'b01); // FIFO 0 y 1 -> gana FIFO 1
        check_result(2'b01, 3'b101, 2'b10); // FIFO 0 y 2 -> gana FIFO 2
        check_result(2'b01, 3'b110, 2'b01); // FIFO 1 y 2 -> gana FIFO 1
        check_result(2'b01, 3'b111, 2'b01); // Todas -> gana FIFO 1

        // ------------------------------------------------------------
        // Caso rr_priority_base = 10
        // Prioridad: FIFO 2 -> FIFO 0 -> FIFO 1
        // ------------------------------------------------------------

        check_result(2'b10, 3'b000, 2'b00); // Ninguna petición
        check_result(2'b10, 3'b001, 2'b00); // Solo FIFO 0
        check_result(2'b10, 3'b010, 2'b01); // Solo FIFO 1
        check_result(2'b10, 3'b100, 2'b10); // Solo FIFO 2

        check_result(2'b10, 3'b011, 2'b00); // FIFO 0 y 1 -> gana FIFO 0
        check_result(2'b10, 3'b101, 2'b10); // FIFO 0 y 2 -> gana FIFO 2
        check_result(2'b10, 3'b110, 2'b10); // FIFO 1 y 2 -> gana FIFO 2
        check_result(2'b10, 3'b111, 2'b10); // Todas -> gana FIFO 2

        // ------------------------------------------------------------
        // Caso rr_priority_base = 11
        // No usado. Se espera comportamiento por default.
        // Prioridad por defecto: FIFO 0 -> FIFO 1 -> FIFO 2
        // ------------------------------------------------------------

        check_result(2'b11, 3'b000, 2'b00);
        check_result(2'b11, 3'b001, 2'b00);
        check_result(2'b11, 3'b010, 2'b01);
        check_result(2'b11, 3'b100, 2'b10);
        check_result(2'b11, 3'b111, 2'b00);

        $display("========================================");
        $display(" Fin de la simulacion");
        $display("========================================");

        $finish;
    end

endmodule