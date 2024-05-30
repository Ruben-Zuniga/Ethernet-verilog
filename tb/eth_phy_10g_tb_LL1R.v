`include "eth_phy_10g.v"

`resetall
`timescale 1us / 100ns
`default_nettype none

module eth_phy_10g_LL1R;

    // Parametros del modulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter PRBS31_ENABLE = 0;
    parameter SCRAMBLER_DISABLE = 0;
    parameter BIT_REVERSE = 0;
    parameter TX_SERDES_PIPELINE = 0;
    parameter RX_SERDES_PIPELINE = 0;
    parameter BITSLIP_HIGH_CYCLES = 1;
    parameter BITSLIP_LOW_CYCLES = 8;
    parameter COUNT_125US = 125;
    
    // Definicion de senales
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
    
    // Generacion de clock
    always #0.5 rx_clk = ~rx_clk;
    always #0.5 tx_clk = ~tx_clk;
    
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

    always @(posedge tx_clk) begin
        if (!tx_rst) begin
            for (i = 0; i < 6; i = i + 1) begin
                xgmii_txd <= test_patterns[i];
                #100;
            end
        end
    end
    /*
    // Aviso de 125 us (tiempo del watchdog)
    always @* begin
        if(dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_watchdog_inst.time_count_reg == 0)
            $display("%0t ps: 125 us", $realtime);
    end
    */
    // Testbench
    initial begin
        $dumpfile("eth_phy_10g_LL1R.vcd");
        $dumpvars(0, eth_phy_10g_LL1R);
    
        // Monitoreo
        $display("Ejecutando simulacion...");
    
        // Configurar generacion de PRBS31
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
        xgmii_txc = 8'hFF;
        
        #10
        rx_rst = 0;
        tx_rst = 0;
        
        #2400;
        
    /*
        // Forzar errores de header cada cierto tiempo
        integer j;
        for (j = 0; j < 200; j = j + 1) begin 
            serdes_rx_hdr = 2'b00;
            #40;
        end
    */
	    $display("Finalizado. Tiempo de simulacion: %0t ps", $realtime);
        $finish;
    end
    
    // Instanciacion del modulo bajo prueba
    eth_phy_10g #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .PRBS31_ENABLE(PRBS31_ENABLE),
        .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
        .BIT_REVERSE(BIT_REVERSE),
        .TX_SERDES_PIPELINE(TX_SERDES_PIPELINE),
        .RX_SERDES_PIPELINE(RX_SERDES_PIPELINE),
        .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
        .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES),
        .COUNT_125US(COUNT_125US)
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

endmodule
