
`timescale 1us / 100ns

module eth_phy_10g_prbs31_tb;

    //----------------------------
    // Parametros del modulo
    //----------------------------
    
    parameter DATA_WIDTH            = 64;
    parameter CTRL_WIDTH            = (DATA_WIDTH/8);
    parameter HDR_WIDTH             = 2;
    parameter PRBS31_ENABLE         = 1; // Habilitar generación de PRBS31
    parameter SCRAMBLER_DISABLE     = 0;
    parameter BIT_REVERSE           = 0;
    parameter TX_SERDES_PIPELINE    = 0;
    parameter RX_SERDES_PIPELINE    = 0;
    parameter BITSLIP_HIGH_CYCLES   = 1;
    parameter BITSLIP_LOW_CYCLES    = 8;
    parameter COUNT_125US           = 125;

    //----------------------------
    // Definicion de senales
    //----------------------------
    
    reg                         rx_clk;
    reg                         rx_rst;
    reg                         tx_clk;
    reg                         tx_rst;
    reg     [DATA_WIDTH-1:0]    xgmii_txd;
    reg     [CTRL_WIDTH-1:0]    xgmii_txc;
    wire    [DATA_WIDTH-1:0]    xgmii_rxd;
    wire    [CTRL_WIDTH-1:0]    xgmii_rxc;
    wire    [DATA_WIDTH-1:0]    serdes_tx_data;
    wire    [HDR_WIDTH-1:0]     serdes_tx_hdr;
    reg     [DATA_WIDTH-1:0]    serdes_rx_data;
    reg     [HDR_WIDTH-1:0]     serdes_rx_hdr;
    wire                        serdes_rx_bitslip;
    wire                        serdes_rx_reset_req;
    wire                        tx_bad_block;
    wire    [6:0]               rx_error_count;     // (test_pattern_error_count)
    wire                        rx_bad_block;
    wire                        rx_sequence_error;
    wire                        rx_block_lock;
    wire                        rx_high_ber;
    wire                        rx_status;
    reg                         cfg_tx_prbs31_enable;
    reg                         cfg_rx_prbs31_enable;

    //----------------------------
    // Generacion de clock
    //----------------------------
    
    always #0.5 rx_clk = ~rx_clk;
    always #0.5 tx_clk = ~tx_clk;
    
    //----------------------------
    // Loopback
    //----------------------------
    always @ (posedge rx_clk) begin
        if (!tx_rst) begin
            serdes_rx_data  <= serdes_tx_data;
            serdes_rx_hdr   <= serdes_tx_hdr;
        end
    end
    
    //----------------------------
    // Testbench Tx
    //----------------------------
    
    initial begin
	    $dumpfile("eth_phy_10g_prbs31_tb.vcd");
	    $dumpvars(0, eth_phy_10g_prbs31_tb);
    
        $display("Ejecutando simulacion...");
    
        // Configurar generacion de PRBS31
        if(PRBS31_ENABLE)
            cfg_tx_prbs31_enable = 1;
        else
            cfg_tx_prbs31_enable = 0;
    
        // Inicializar clock y reset
        tx_clk = 0;
        tx_rst = 1;
        
        // Inicializar XGMII
        xgmii_txd = {DATA_WIDTH{1'b0}};
        //xgmii_txc = 8'hFF;    // Control
        xgmii_txc = 8'h00;    // Datos
        
        #10;
        @(posedge tx_clk);
        tx_rst = 0;
        
        @(posedge rx_rst);
        tx_rst = 1;
        #10;
        
        $display("Tiempo de ejecucion: %0t ps", $realtime);
        $finish;
    end
    
    //----------------------------
    // Testbench Rx
    //----------------------------

    initial begin
        // Configurar generacion de PRBS31
        if(PRBS31_ENABLE)
            cfg_rx_prbs31_enable = 1;
        else
            cfg_rx_prbs31_enable = 0;

        // Inicializar clock y reset
        rx_clk = 0;
        rx_rst = 1;
        
        // Inicializar serdes
        serdes_rx_data = {DATA_WIDTH{1'b0}};
        serdes_rx_hdr  = {HDR_WIDTH{1'b0}};
        
        #10;
        @(posedge rx_clk);
        rx_rst = 0;

        #500;
        @(posedge rx_clk);
        rx_rst = 1;
    end
	
    //----------------------------
    // Instanciacion del modulo bajo prueba
    //----------------------------
    
    eth_phy_10g #(
        .DATA_WIDTH             (DATA_WIDTH)            ,
        .CTRL_WIDTH             (CTRL_WIDTH)            ,
        .HDR_WIDTH              (HDR_WIDTH)             ,
        .PRBS31_ENABLE          (PRBS31_ENABLE)         ,
        .SCRAMBLER_DISABLE      (SCRAMBLER_DISABLE)     ,
        .BIT_REVERSE            (BIT_REVERSE)           ,
        .TX_SERDES_PIPELINE     (TX_SERDES_PIPELINE)    ,
        .RX_SERDES_PIPELINE     (RX_SERDES_PIPELINE)    ,
        .BITSLIP_HIGH_CYCLES    (BITSLIP_HIGH_CYCLES)   ,
        .BITSLIP_LOW_CYCLES     (BITSLIP_LOW_CYCLES)    ,
        .COUNT_125US            (COUNT_125US)
    ) dut (
        .rx_clk                 (rx_clk)                ,
        .rx_rst                 (rx_rst)                ,
        .tx_clk                 (tx_clk)                ,
        .tx_rst                 (tx_rst)                ,
        .xgmii_txd              (xgmii_txd)             ,
        .xgmii_txc              (xgmii_txc)             ,
        .xgmii_rxd              (xgmii_rxd)             ,
        .xgmii_rxc              (xgmii_rxc)             ,
        .serdes_tx_data         (serdes_tx_data)        ,
        .serdes_tx_hdr          (serdes_tx_hdr)         ,
        .serdes_rx_data         (serdes_rx_data)        ,
        .serdes_rx_hdr          (serdes_rx_hdr)         ,
        .serdes_rx_bitslip      (serdes_rx_bitslip)     ,
        .serdes_rx_reset_req    (serdes_rx_reset_req)   ,
        .tx_bad_block           (tx_bad_block)          ,
        .rx_error_count         (rx_error_count)        ,
        .rx_bad_block           (rx_bad_block)          ,
        .rx_sequence_error      (rx_sequence_error)     ,
        .rx_block_lock          (rx_block_lock)         ,
        .rx_high_ber            (rx_high_ber)           ,
        .rx_status              (rx_status)             ,
        .cfg_tx_prbs31_enable   (cfg_tx_prbs31_enable)  ,
        .cfg_rx_prbs31_enable   (cfg_rx_prbs31_enable)
    );

endmodule
