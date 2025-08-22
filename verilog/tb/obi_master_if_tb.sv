`timescale 1ns/1ps

module obi_master_if_tb;

  // Parámetros
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;

  // Señales de testbench
  logic clk;
  logic rst;

  logic start;
  logic rw;
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] wdata;
  logic [DATA_WIDTH-1:0] rdata;
  logic done;
  logic busy;

  // Señales OBI simuladas
  logic mst_obi_req_o;
  logic mst_obi_we_o;
  logic [ADDR_WIDTH-1:0] mst_obi_addr_o;
  logic [DATA_WIDTH-1:0] mst_obi_wdata_o;
  logic [DATA_WIDTH/8-1:0] mst_obi_be_o;
  logic mst_obi_gnt_i;
  logic [DATA_WIDTH-1:0] mst_obi_rdata_i;
  logic mst_obi_rvalid_i;

  // Reloj
  always #5 clk = ~clk;

  // Instancia del DUT
  obi_master_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .rw(rw),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata),
    .done(done),
    .busy(busy),
    .mst_obi_req_o(mst_obi_req_o),
    .mst_obi_we_o(mst_obi_we_o),
    .mst_obi_addr_o(mst_obi_addr_o),
    .mst_obi_wdata_o(mst_obi_wdata_o),
    .mst_obi_be_o(mst_obi_be_o),
    .mst_obi_gnt_i(mst_obi_gnt_i),
    .mst_obi_rdata_i(mst_obi_rdata_i),
    .mst_obi_rvalid_i(mst_obi_rvalid_i)
  );

  // Procedimiento de prueba
  initial begin
    $display("\n--- TESTBENCH OBI MASTER IF ---");

    // Inicialización
    clk = 0;
    rst = 1;
    start = 0;
    rw = 0;
    addr = 32'h00000000;
    wdata = 32'hDEADBEEF;
    mst_obi_gnt_i = 0;
    mst_obi_rvalid_i = 0;
    mst_obi_rdata_i = 32'h12345678;

    #20;
    rst = 0;

    // -------------------------------
    // Prueba de ESCRITURA
    // -------------------------------
    $display("Iniciando ESCRITURA...");
    rw = 1;
    addr = 32'h10000000;
    wdata = 32'hCAFEBABE;
    start = 1;

    @(posedge clk);
    start = 0;

    // Simular el gnt (grant)
    wait(mst_obi_req_o);
    #5 mst_obi_gnt_i = 1;
    @(posedge clk);
    mst_obi_gnt_i = 0;

    wait(done);
    @(posedge clk);

    $display("Escritura completada");

    // -------------------------------
    // Prueba de LECTURA
    // -------------------------------
    $display("Iniciando LECTURA...");
    rw = 0;
    addr = 32'h20000000;
    start = 1;

    @(posedge clk);
    start = 0;

    // Simular el gnt (grant)
    wait(mst_obi_req_o);
    #5 mst_obi_gnt_i = 1;
    @(posedge clk);
    mst_obi_gnt_i = 0;

    // Simular el rvalid con datos
    wait(mst_obi_req_o);
    #10 mst_obi_rvalid_i = 1;
    mst_obi_rdata_i = 32'hBEEF1234;
    @(posedge clk);
    mst_obi_rvalid_i = 0;

    wait(done);
    @(posedge clk);
    $display("Lectura completada, datos recibidos = 0x%08X", rdata);

    $display("--- TEST COMPLETADO ---\n");
    $stop;
  end

endmodule
