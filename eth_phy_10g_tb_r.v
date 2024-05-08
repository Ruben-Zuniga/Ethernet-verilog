`timescale 1ns / 1ps
`include "eth_phy_10g.v"

module eth_phy_10g_tb_r;

    // Parámetros del módulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter PRBS31_ENABLE = 1; // Habilitar generación de PRBS31

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

    // Clock generation
    always #5 rx_clk = ~rx_clk;
    always #5 tx_clk = ~tx_clk;
    
    // Loopback
    always @ (posedge rx_clk) begin
	//serdes_rx_data <= serdes_tx_data & {{DATA_WIDTH-32{1'b1}},{32{1'b0}}};
    serdes_rx_data <= serdes_tx_data;
	serdes_rx_hdr <= serdes_tx_hdr;
    end
    
    // Testbench stimulus
    initial begin
        $dumpfile("eth_phy_10g_tb_r.vcd");
        $dumpvars(0, eth_phy_10g_tb_r);
        // Habilitar generación PRBS31 para transmisión y recepción
        cfg_tx_prbs31_enable = 1;
        cfg_rx_prbs31_enable = 1;
        rx_clk = 0;
        tx_clk = 0;
        rx_rst = 1;
        tx_rst = 1;
        
    	//serdes_rx_hdr = 2'b10;
    	
        #50
        rx_rst = 0;
        tx_rst = 0;

        // Esperar un tiempo para estabilización
        //#100

        // Monitoreo
	    $display("time\t rx_error_count\t xgmii_rxd\t\t serdes_tx_data\t\t serdes_rx_data\t\t tx_hdr\t rx_hdr");
	    $monitor("%g\t %h\t\t %h\t %h\t %h\t %b\t %b", $time, rx_error_count, xgmii_rxd, serdes_tx_data, serdes_rx_data, serdes_tx_hdr, serdes_rx_hdr);
        #300; // Imprimir cada ciclo de clock

        // Finalizar simulación
        $finish;
    end

endmodule
