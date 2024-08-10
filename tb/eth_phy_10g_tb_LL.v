`include "eth_phy_10g.v"
`timescale 1us / 100ns

module eth_phy_10g_tb;

  // Parameters
    localparam  DATA_WIDTH            = 64;
    localparam  CTRL_WIDTH            = (DATA_WIDTH/8);
    localparam  HDR_WIDTH             = 2;
    localparam  FRAME_WIDTH           = DATA_WIDTH + HDR_WIDTH;
    localparam  BIT_REVERSE           = 0;
    localparam  SCRAMBLER_DISABLE     = 1;
    localparam  PRBS31_ENABLE         = 0;
    localparam  TX_SERDES_PIPELINE    = 0;
    localparam  RX_SERDES_PIPELINE    = 0;
    localparam  BITSLIP_HIGH_CYCLES   = 1;
    localparam  BITSLIP_LOW_CYCLES    = 8;
    localparam  COUNT_125US           = 125;

    //Ports
    reg                       rx_clk;
    reg                       rx_rst;
    reg                       tx_clk;
    reg                       tx_rst;
    reg   [DATA_WIDTH-1:0]    xgmii_txd;
    reg   [CTRL_WIDTH-1:0]    xgmii_txc;
    wire  [DATA_WIDTH-1:0]    xgmii_rxd;
    wire  [CTRL_WIDTH-1:0]    xgmii_rxc;
    wire  [DATA_WIDTH-1:0]    serdes_tx_data;
    wire  [HDR_WIDTH-1:0]     serdes_tx_hdr;
    reg   [FRAME_WIDTH-1:0]   serdes_rx;
    wire                      serdes_rx_bitslip;
    wire                      serdes_rx_reset_req;
    wire                      tx_bad_block;
    wire  [6:0]               rx_error_count;
    wire                      rx_bad_block;
    wire                      rx_sequence_error;
    wire                      rx_block_lock;
    wire                      o_rx_block_lock;
    wire                      rx_high_ber;
    wire                      rx_status;
    reg                       cfg_tx_prbs31_enable;
    reg                       cfg_rx_prbs31_enable;

    //----------------------------
    // Otras senales/variables
    //----------------------------
    
    reg     [5:0] sh_cnt;
    integer       i = 0;
    integer       j = 0;
    
    //----------------------------
    // Definir prueba. COLOCAR UNO PARA LOS DATOS Y UNO PARA LOS HEADERS
    //----------------------------
    
    `define FIXED_DATA
    `define VALID_HDR
    
    /*
    Datos:
        FIXED_DATA: Patron de datos fijo 
        RANDOM_DATA: Patron de datos aleatorio
    Headers: 
        VALID_HDR: Header valido
        INVALID_HDR: Header invalido
        LIGHTLY_CORRUPTED: Header lijeramente corrupto
        STRONGLY_CORRUPTED: Header fuertemente corrupto
    */
    
    //----------------------------
    // Generacion de clock
    //----------------------------
    
    always #0.5 rx_clk = ~rx_clk;
    always #0.5 tx_clk = ~tx_clk;
    
    //----------------------------
    // Loopback de los datos
    //----------------------------
    
    always @ (posedge rx_clk) begin
        if (!rx_rst) begin
            serdes_rx <= {serdes_tx_data, serdes_tx_hdr};
        end
    end
    
    //----------------------------
    // Patrones de prueba
    //----------------------------
    
    `ifdef FIXED_DATA
        
        reg [DATA_WIDTH-1:0] test_pattern [5:0];
    
        initial begin
            test_pattern[0] = 64'hFFFFFFFFFFFFFFFF; // Todos 1
            test_pattern[1] = 64'h0000000000000000; // Todos 0
            test_pattern[2] = 64'h5555555555555555; // Alternar 01s
            test_pattern[3] = 64'hAAAAAAAAAAAAAAAA; // Alternar 10s
            test_pattern[4] = 64'hFEFEFEFEFEFEFEFE; // Todos Error
            test_pattern[5] = 64'h0707070707070707; // Todos Idle
        end
        
        // Asignar patrones a la entrada
        always @(posedge tx_clk) begin
            if (!tx_rst) begin
                for (j = 0; j < 6; j = j + 1) begin
                    xgmii_txd <= test_pattern[j];
                    #100;
                end
            end
        end
    
    `elsif RANDOM_DATA
    
        integer seed1 = 32'd1;
        integer seed2 = 32'd2;
        reg [DATA_WIDTH-1:0] test_pattern;
       
        always begin
            test_pattern = {{$random(seed1), $random(seed2)}};
            #100;
        end
        
        // Asignar patrones a la entrada
        always @(posedge tx_clk) begin
            if (!tx_rst) begin
                xgmii_txd <= test_pattern;
                #100;
            end
        end
        
    `endif
    
    //----------------------------
    //----------------------------
    
    always @(posedge rx_clk) begin
        sh_cnt <= dut.eth_phy_10g_rx_inst.eth_phy_10g_rx_if_inst.eth_phy_10g_rx_frame_sync_inst.sh_count_reg;
    end
    
    //----------------------------
    // Testbench Tx
    //----------------------------
    
    initial begin
        $dumpfile("eth_phy_10g_tb.vcd");
        $dumpvars(0, eth_phy_10g_tb);
    
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
        xgmii_txd = test_pattern[0];
        xgmii_txc = 8'hFF;    // Control
        //xgmii_txc = 8'h00;    // Datos
        
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
        serdes_rx = {FRAME_WIDTH{1'b0}};
        
        #10;
        @(posedge rx_clk);
        rx_rst = 0;

        #2400;
        @(posedge rx_clk);
        rx_rst = 1;
    
    end
    
    //----------------------------
    // Instanciacion del modulo bajo prueba
    //----------------------------
    eth_phy_10g # (
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .BIT_REVERSE(BIT_REVERSE),
        .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
        .PRBS31_ENABLE(PRBS31_ENABLE),
        .TX_SERDES_PIPELINE(TX_SERDES_PIPELINE),
        .RX_SERDES_PIPELINE(RX_SERDES_PIPELINE),
        .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
        .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES),
        .COUNT_125US(COUNT_125US)
    )
    dut (
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
        .serdes_rx(serdes_rx),
        .serdes_rx_bitslip(serdes_rx_bitslip),
        .serdes_rx_reset_req(serdes_rx_reset_req),
        .tx_bad_block(tx_bad_block),
        .rx_error_count(rx_error_count),
        .rx_bad_block(rx_bad_block),
        .rx_sequence_error(rx_sequence_error),
        .rx_block_lock(rx_block_lock),
        .o_rx_block_lock(o_rx_block_lock),
        .rx_high_ber(rx_high_ber),
        .rx_status(rx_status),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable),
        .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable)
    );

endmodule
