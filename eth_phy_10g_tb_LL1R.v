`timescale 1ns / 1ps
`include "eth_phy_10g.v"

module eth_phy_10g_LL1R;

    // Parámetros del módulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter PRBS31_ENABLE = 0;
    parameter SCRAMBLER_DISABLE = 1;
    parameter BIT_REVERSE = 0;
    parameter TX_SERDES_PIPELINE = 0;
    parameter RX_SERDES_PIPELINE = 0;
    parameter BITSLIP_HIGH_CYCLES = 1;
    parameter BITSLIP_LOW_CYCLES = 8;
    parameter COUNT_125US = 125000/6.4;

    // Definición de señales
    reg rx_clk, rx_rst, tx_clk, tx_rst;
    reg [DATA_WIDTH-1:0] xgmii_txd;
    reg [CTRL_WIDTH-1:0] xgmii_txc;
    wire [DATA_WIDTH-1:0] xgmii_rxd;
    wire [CTRL_WIDTH-1:0] xgmii_rxc;
    wire [DATA_WIDTH-1:0] serdes_tx_data;
    wire [HDR_WIDTH-1:0] serdes_tx_hdr;
    reg [DATA_WIDTH-1:0] serdes_rx_data;
    reg [HDR_WIDTH-1:0] serdes_rx_hdr;
    wire serdes_rx_bitslip, serdes_rx_reset_req;
    wire tx_bad_block;
    wire [6:0] rx_error_count;
    wire rx_bad_block, rx_sequence_error, rx_block_lock, rx_high_ber, rx_status;
    reg cfg_tx_prbs31_enable, cfg_rx_prbs31_enable;

    // Instanciación del módulo bajo prueba
    eth_phy_10g #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .PRBS31_ENABLE(PRBS31_ENABLE)
    ) dut (
        .rx_clk(rx_clk),
        .rx_rst(rx_rst),
        .tx_clk(tx_clk),
        .tx_rst(tx_rst),
        .xgmii_txd(xgmii_txd),
        .xgmii_txc(xgmii_txc),
        .xgmii_rxd(xgmii_rxd),
        .xgmii_rxc(xgmii_rxc),
        .serdes_tx_data(serdes_tx_data),
        .serdes_tx_hdr(serdes_tx_hdr),
        .serdes_rx_data(serdes_rx_data),
        .serdes_rx_hdr(serdes_rx_hdr),
        .serdes_rx_bitslip(serdes_rx_bitslip),
        .serdes_rx_reset_req(serdes_rx_reset_req),
        .tx_bad_block(tx_bad_block),
        .rx_error_count(rx_error_count),
        .rx_bad_block(rx_bad_block),
        .rx_sequence_error(rx_sequence_error),
        .rx_block_lock(rx_block_lock),
        .rx_high_ber(rx_high_ber),
        .rx_status(rx_status),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable),
        .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable)
    );

    // Generacion de clock
    always #5 rx_clk = ~rx_clk;
    always #5 tx_clk = ~tx_clk;
    
    // Loopback
    always @ (posedge tx_clk) begin
        if (!tx_rst) begin
            serdes_rx_data <= serdes_tx_data;
	        serdes_rx_hdr <= serdes_tx_hdr;
        end
    end

    // Patrones de prueba
    reg [63:0] test_patterns [0:5];
    initial begin
        test_patterns[0] = 64'hFFFFFFFFFFFFFFFF; // Todos 1
        test_patterns[1] = 64'h0000000000000000; // Todos 0
        test_patterns[2] = 64'h5555555555555555; // Alternar 01s
        test_patterns[3] = 64'hAAAAAAAAAAAAAAAA; // Alternar 10s
        test_patterns[4] = 64'hFEFEFEFEFEFEFEFE; // Todos Error
        test_patterns[5] = 64'h0707070707070707; // Todos Idle
    end
    
    integer i;
    integer j;

    // Alternar XGMII con los distintos patrones
    always @(posedge tx_clk) begin
        if (!tx_rst) begin
            for (i = 0; i < 6; i = i + 1) begin
                xgmii_txd <= test_patterns[i];
                #100;
            end
        end
    end
    
    // Testbench
    initial begin
        $dumpfile("eth_phy_10g_LL1R.vcd");
        $dumpvars(0, eth_phy_10g_LL1R);

        // Monitoreo
        $display("Ejecutando simulacion...");
	    $display("time\t xgmii_txd\t\t xgmii_rxd\t\t serdes_tx_data\t\t serdes_rx_data\t\t tx_hdr\t rx_hdr");

        // Configurar generación de PRBS31 para transmisión y recepción
        if(PRBS31_ENABLE) begin
            cfg_tx_prbs31_enable = 1;
            cfg_rx_prbs31_enable = 1;
        end else begin
            cfg_tx_prbs31_enable = 0;
            cfg_rx_prbs31_enable = 0;
        end

        // Inicializar clock y reset
        rx_clk = 0;
        tx_clk = 0;
        rx_rst = 1;
        tx_rst = 1;
    	
        // Inicializar XGMII
        xgmii_txd = {test_patterns[0]};
        xgmii_txc = 8'h00;

        #10
        rx_rst = 0;
        tx_rst = 0;

	// Imprimir cada ciclo de clock
	$monitor("%g\t %h\t %h\t %h\t %h\t %b\t %b", $time, xgmii_txd, xgmii_rxd, serdes_tx_data, serdes_rx_data, serdes_tx_hdr, serdes_rx_hdr);
        #1000;

        $finish;
    end

endmodule
