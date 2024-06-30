`include "eth_phy_10g.v"

`resetall
`timescale 1us / 100ns
`default_nettype none

module eth_phy_10g_block_lock_tb;

    //----------------------------
    // Parametros del modulo
    //----------------------------
    parameter   DATA_WIDTH = 64;
    parameter   CTRL_WIDTH = (DATA_WIDTH/8);
    parameter   HDR_WIDTH = 2;
    parameter   BIT_REVERSE = 0;
    parameter   SCRAMBLER_DISABLE = 0;
    parameter   PRBS31_ENABLE = 0;
    parameter   TX_SERDES_PIPELINE = 0;
    parameter   RX_SERDES_PIPELINE = 0;
    parameter   BITSLIP_HIGH_CYCLES = 1;
    parameter   BITSLIP_LOW_CYCLES = 8;
    parameter   COUNT_125US = 125;

    //----------------------------
    // Señales
    //----------------------------

    // Clocks y resets
    reg rx_clk;
    reg rx_rst;
    reg tx_clk;
    reg tx_rst;
    
    // XGMII
    reg     [DATA_WIDTH-1:0] xgmii_txd;
    reg     [CTRL_WIDTH-1:0] xgmii_txc;
    wire    [DATA_WIDTH-1:0] xgmii_rxd;
    wire    [CTRL_WIDTH-1:0] xgmii_rxc;
    
    // SERDES
    wire    [DATA_WIDTH-1:0] serdes_tx_data;
    wire    [HDR_WIDTH-1:0]  serdes_tx_hdr;
    reg     [DATA_WIDTH-1:0] serdes_rx_data;
    reg     [HDR_WIDTH-1:0]  serdes_rx_hdr;
    
    // Banderas en Tx
    wire tx_bad_block;
    
    // Banderas en Rx
    wire    rx_block_lock;
    wire    serdes_rx_bitslip;
    wire    rx_status;
    wire    rx_bad_block;
    wire    rx_sequence_error;
    wire    rx_high_ber;
    wire    serdes_rx_reset_req;
    
    // Contadores
    wire [6:0] rx_error_count;
    reg [3:0] ber_count;
    reg [5:0] sh_cnt;
    reg [3:0] sh_invalid_cnt;
    
    // PRBS31
    reg cfg_tx_prbs31_enable, cfg_rx_prbs31_enable;
    
    // Patrones de entrada
    reg [63:0] test_patterns [0:5];
    

    //----------------------------
    // Asignaciones
    //----------------------------
    always #10 rx_clk = ~rx_clk;
    always #10 tx_clk = ~tx_clk;

    always@(*) begin
        ber_count        = dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_ber_mon_inst.ber_count_reg;
        sh_cnt           = dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_frame_sync_inst.sh_count_reg;
        sh_invalid_cnt   = dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_frame_sync_inst.sh_invalid_count_reg;
    end
    
    //----------------------------
    // Inicializacion
    //----------------------------
    initial begin
        $dumpfile("eth_phy_10g_block_lock_tb.vcd");
        $dumpvars(0, eth_phy_10g_block_lock_tb);

        // Inicializar clock y reset
            tx_clk = 0;
            rx_clk = 0;
            tx_rst = 1;
            rx_rst = 1;
        
        // Deshabilitar PRBS31
        #2  cfg_tx_prbs31_enable = 0;
            cfg_rx_prbs31_enable = 0;

        // Mandar Idle
        #2  xgmii_txc = 8'hFF;
            xgmii_txd = 64'h0707070707070707;

        #10 rx_rst = 0;
            tx_rst = 0;
        
    end

    //----------------------------
    // Casos de prueba
    //----------------------------
    integer i;
    `define CASE_2_VALID

    initial begin
            
        // Envia 63 validos + 1 invalido
        `ifdef CASE_1_VALID

            for(i = 0; i < 3; i = i+1) begin
                // Envia 63 bloques validos
                serdes_rx_hdr <= 2'h2;
                #1280;
                // Envia 1 bloque invalido
                serdes_rx_hdr <= 2'h0;
                #20;
            end

        // Envia 62 validos + 1 invalido + 1 valido
        `elsif CASE_2_VALID
            for(i = 0; i < 3; i = i+1) begin
                // Envia 62 bloques validos
                serdes_rx_hdr <= 2'h2;
                #1260;
                // Envia 1 bloque invalido
                serdes_rx_hdr <= 2'h0;
                #20;
                // Envia 1 bloque valido
                serdes_rx_hdr <= 2'h2;
                #20;
            end

        // Envia 64 validos + 1 invalido
        `elsif CASE_3_VALID
            for(i = 0; i < 5; i = i+1) begin
                // Envia 64 bloques validos
                serdes_rx_hdr <= 2'h2;
                #1300;
                // Envia 1 bloque invalido
                serdes_rx_hdr <= 2'h0;
                #20;
            end

        // Envia 64 validos, 15 invalido, resto validos
        `elsif CASE_1_INVALID
            for(i = 0; i < 5; i = i+1) begin
                // Envia 64 bloques validos
                serdes_rx_hdr <= 2'h2;
                #1270;
                // Envia 15 bloques invalidos
                serdes_rx_hdr <= 2'h0;
                #300;
            end

        // Envia 64 validos, 15 invalido, 48 validos, 1 invalido
        `elsif CASE_2_INVALID
            for(i = 0; i < 5; i = i+1) begin
                // Envia 64 bloques validos
                serdes_rx_hdr <= 2'h2;
                #1270;
                // Envia 15 bloques invalidos
                serdes_rx_hdr <= 2'h0;
                #300;
                // Envia 48 bloques validos
                serdes_rx_hdr <= 2'h2;
                #960;
                // Envia 1 bloques invalido
                serdes_rx_hdr <= 2'h0;
                #20;
            end

        `elsif CASE_3_INVALID
            for(i = 0; i < 5; i = i+1) begin
                // Envia 64 bloques validos
                serdes_rx_hdr <= 2'h2;
                #1270;
                // Envia 16 bloques invalidos
                serdes_rx_hdr <= 2'h0;
                #320;
                // Envia 8 bloques validos
                serdes_rx_hdr <= 2'h2;
                #180;
                // Envia 1 bloques invalido
                serdes_rx_hdr <= 2'h0;
                #20;
            end

        `endif

        $finish;
    end
       
    //----------------------------
    // Instanciacion del modulo bajo prueba
    //----------------------------
    eth_phy_10g #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .BIT_REVERSE(BIT_REVERSE),
        .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
        .PRBS31_ENABLE(PRBS31_ENABLE),
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

