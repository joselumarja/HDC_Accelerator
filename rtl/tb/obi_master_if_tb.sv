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
  initial clk = 1'b0;
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

  // ------------------------------------------------------------
  // Reset
  // ------------------------------------------------------------
  task automatic reset_dut();
    begin
      rst              = 1'b1;
      start            = 1'b0;
      rw               = 1'b0;
      addr             = '0;
      wdata            = '0;
      mst_obi_gnt_i    = 1'b0;
      mst_obi_rvalid_i = 1'b0;
      mst_obi_rdata_i  = '0;

      repeat (3) @(posedge clk);
      rst = 1'b0;
      @(posedge clk);

      assert(done == 1'b0)
        else $error("ERROR: done debería estar a 0 tras reset");

      assert(busy == 1'b0)
        else $error("ERROR: busy debería estar a 0 tras reset");
    end
  endtask

  // ------------------------------------------------------------
  // Transacción de escritura
  // ------------------------------------------------------------
  task automatic do_write(
    input logic [ADDR_WIDTH-1:0] test_addr,
    input logic [DATA_WIDTH-1:0] test_wdata
  );
    begin
      $display("Iniciando ESCRITURA: addr = 0x%08X, data = 0x%08X",
               test_addr, test_wdata);

      @(negedge clk);
      rw    = 1'b1;
      addr  = test_addr;
      wdata = test_wdata;
      start = 1'b1;

      @(negedge clk);
      start = 1'b0;

      // Esperar a que el DUT emita la petición
      wait(mst_obi_req_o == 1'b1);
      #1;

      assert(busy == 1'b1)
        else $error("ERROR WRITE: busy debería estar activo durante la transacción");

      assert(mst_obi_we_o == 1'b1)
        else $error("ERROR WRITE: mst_obi_we_o debería ser 1");

      assert(mst_obi_addr_o == test_addr)
        else $error("ERROR WRITE: dirección incorrecta. Esperada=0x%08X, obtenida=0x%08X",
                    test_addr, mst_obi_addr_o);

      assert(mst_obi_wdata_o == test_wdata)
        else $error("ERROR WRITE: dato incorrecto. Esperado=0x%08X, obtenido=0x%08X",
                    test_wdata, mst_obi_wdata_o);

      assert(mst_obi_be_o == {DATA_WIDTH/8{1'b1}})
        else $error("ERROR WRITE: byte enable incorrecto");

      // Simular grant del bus
      @(negedge clk);
      mst_obi_gnt_i = 1'b1;

      @(negedge clk);
      mst_obi_gnt_i = 1'b0;

      // Esperar finalización
      wait(done == 1'b1);
      #1;

      assert(done == 1'b1)
        else $error("ERROR WRITE: done no se activó");

      @(posedge clk);
      #1;

      assert(done == 1'b0)
        else $error("ERROR WRITE: done debería durar solo un ciclo");

      $display("Escritura completada correctamente\n");
    end
  endtask

  // ------------------------------------------------------------
  // Transacción de lectura
  // ------------------------------------------------------------
  task automatic do_read(
    input  logic [ADDR_WIDTH-1:0] test_addr,
    input  logic [DATA_WIDTH-1:0] expected_rdata
  );
    begin
      $display("Iniciando LECTURA: addr = 0x%08X", test_addr);

      @(negedge clk);
      rw    = 1'b0;
      addr  = test_addr;
      wdata = '0;
      start = 1'b1;

      @(negedge clk);
      start = 1'b0;

      // Esperar a que el DUT emita la petición
      wait(mst_obi_req_o == 1'b1);
      #1;

      assert(busy == 1'b1)
        else $error("ERROR READ: busy debería estar activo durante la transacción");

      assert(mst_obi_we_o == 1'b0)
        else $error("ERROR READ: mst_obi_we_o debería ser 0");

      assert(mst_obi_addr_o == test_addr)
        else $error("ERROR READ: dirección incorrecta. Esperada=0x%08X, obtenida=0x%08X",
                    test_addr, mst_obi_addr_o);

      assert(mst_obi_be_o == {DATA_WIDTH/8{1'b1}})
        else $error("ERROR READ: byte enable incorrecto");

      // Simular grant
      @(negedge clk);
      mst_obi_gnt_i = 1'b1;

      @(negedge clk);
      mst_obi_gnt_i = 1'b0;

      // Simular latencia de lectura
      repeat (2) @(negedge clk);

      mst_obi_rdata_i  = expected_rdata;
      mst_obi_rvalid_i = 1'b1;

      @(negedge clk);
      mst_obi_rvalid_i = 1'b0;

      // Esperar finalización
      wait(done == 1'b1);
      #1;

      assert(rdata == expected_rdata)
        else $error("ERROR READ: dato leído incorrecto. Esperado=0x%08X, obtenido=0x%08X",
                    expected_rdata, rdata);

      @(posedge clk);
      #1;

      assert(done == 1'b0)
        else $error("ERROR READ: done debería durar solo un ciclo");

      $display("Lectura completada correctamente. rdata = 0x%08X\n", rdata);
    end
  endtask

  // ------------------------------------------------------------
  // Test principal
  // ------------------------------------------------------------
  initial begin
    $display("\n--- TESTBENCH OBI MASTER IF ---\n");

    reset_dut();

    do_write(32'h1000_0000, 32'hCAFE_BABE);

    do_read(32'h2000_0000, 32'hBEEF_1234);

    $display("--- TEST COMPLETADO CORRECTAMENTE ---\n");

    #20;
    $stop;
  end

endmodule