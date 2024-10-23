`include "../eth_phy_10g_rx_frame_aligner_v3.v"

`timescale 1us / 100ns

module eth_phy_10g_rx_frame_aligner_tb;

    //----------------------------
    // Parametros del modulo
    //----------------------------
    
    parameter  DATA_WIDTH            = 64                       ;
    parameter  HDR_WIDTH             = 2                        ;
    parameter  FRAME_WIDTH           = DATA_WIDTH + HDR_WIDTH   ;
    parameter  SH_POS_WIDTH          = $clog2(FRAME_WIDTH)      ;
    
    //----------------------------
    // Definicion de senales
    //----------------------------
    
    reg                         clk                             ;
    reg                         rst                             ;
    reg     [FRAME_WIDTH-1:0]   i_serdes_rx                     ;
    wire                        o_serdes_rx_bitslip             ;
    wire    [DATA_WIDTH-1:0]    o_serdes_rx_data                ;
    wire    [HDR_WIDTH-1:0]     o_serdes_rx_hdr                 ;
    wire                        o_rx_block_lock                 ;
    
    //----------------------------
    // Otras senales/variables
    //----------------------------
    
    wire    [SH_POS_WIDTH-1:0]  sh_pos                          ;
    wire    [5:0]               sh_cnt                          ;
    wire    [3:0]               sh_invalid_cnt                  ;
    integer                     idx_pattern                     ;
    
    //----------------------------
    // Generacion de clock
    //----------------------------
    
    always #0.5 clk = ~clk;
    
    //----------------------------
    // Definir prueba
    //----------------------------

    `define FIXED_DATA;

    /*
        FIXED_DATA:  Patron de datos fijo 
        RANDOM_DATA: Patron de datos aleatorio
    */

    //----------------------------
    // Patrones de prueba
    //----------------------------
    
    `ifdef FIXED_DATA
        
        reg [FRAME_WIDTH-1:0] test_pattern [5:0];
    
        initial begin
            test_pattern[0] = 66'hFFFFFFFFFFFFFFFF; // Todos 1
            test_pattern[1] = 66'h0000000000000000; // Todos 0
            test_pattern[2] = 66'h5555555555555555; // Alternar 01s
            test_pattern[3] = 66'hAAAAAAAAAAAAAAAA; // Alternar 10s
            test_pattern[4] = 66'hFEFEFEFEFEFEFEFE; // Todos Error
            test_pattern[5] = 66'h0707070707070707; // Todos Idle
        end
        
        // Asignar patrones a la entrada
        always @(posedge clk) begin
            if (!rst) begin
                for (idx_pattern = 0; idx_pattern < 6; idx_pattern = idx_pattern + 1) begin
                    i_serdes_rx <= test_pattern[idx_pattern];
                    #400;
                end
            end
        end
    
    `elsif RANDOM_DATA
    
        integer                     seed1           = 32'd1 ;
        integer                     seed2           = 32'd2 ;
        integer                     seed3           = 32'd3 ;
        reg     [FRAME_WIDTH-1:0]   test_pattern            ;
       
        always begin
            test_pattern = {{$dist_uniform(seed3, 0, 4), $random(seed2), $random(seed1)}};
            #100;
        end
        
        // Asignar patrones a la entrada
        always @(posedge clk) begin
            if (!rst) begin
                i_serdes_rx <= test_pattern;
                #400;
            end
        end
        
    `endif
    
    //----------------------------
    // Senales internas
    //----------------------------
    
    assign sh_pos           = dut.sh_pos                    ;
    assign sh_cnt           = dut.sh_cnt                    ;
    assign sh_invalid_cnt   = dut.sh_invalid_cnt            ;
    
    //----------------------------
    // Testbench
    //----------------------------
    
    initial begin
        $dumpfile("eth_phy_10g_rx_frame_aligner_tb.vcd")    ;
        $dumpvars(0, eth_phy_10g_rx_frame_aligner_tb)       ;
    
        $display("Ejecutando simulacion...")                ;
    
        // Inicializar clock y reset
        clk         = 0                                     ;
        rst         = 1                                     ;

        idx_pattern = 0                                     ;
        
        // Inicializar serdes
        i_serdes_rx = test_pattern[0]                       ;
        
        #10                                                 ;
        @(posedge clk)                                      ;
        rst         = 0                                     ;
        
        #1000;
        $display("Tiempo de ejecucion: %0t ps", $realtime)  ;
        $finish;
    end
    
    //----------------------------
    // Instanciacion del modulo bajo prueba
    //----------------------------
    
    eth_phy_10g_rx_frame_aligner #(
        .DATA_WIDTH             (DATA_WIDTH)            ,
        .HDR_WIDTH              (HDR_WIDTH)             ,
        .FRAME_WIDTH            (FRAME_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .o_serdes_rx_bitslip    (o_serdes_rx_bitslip)   ,
        .o_serdes_rx_data       (o_serdes_rx_data)      ,
        .o_serdes_rx_hdr        (o_serdes_rx_hdr)       ,
        .o_rx_block_lock        (o_rx_block_lock)       ,
        .i_serdes_rx            (i_serdes_rx)
    );

endmodule
