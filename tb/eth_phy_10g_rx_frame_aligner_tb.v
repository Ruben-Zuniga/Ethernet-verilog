`include "eth_phy_10g_rx_frame_aligner.v"

`resetall
`timescale 1us / 100ns
`default_nettype none

module eth_phy_10g_rx_frame_aligner_tb;

    //----------------------------
    // Parametros del modulo
    //----------------------------
    
    parameter  DATA_WIDTH            = 64;
    parameter  HDR_WIDTH             = 2;
    parameter  RX_WIDTH              = DATA_WIDTH+HDR_WIDTH;
    parameter  BITSLIP_HIGH_CYCLES   = 1;
    parameter  BITSLIP_LOW_CYCLES    = 8;
    localparam SH_POS_WIDTH          = $clog2(RX_WIDTH);
    
    //----------------------------
    // Definicion de senales
    //----------------------------
    
    reg                         clk;
    reg                         rst;
    reg     [RX_WIDTH-1:0]      serdes_rx;
    reg                         serdes_rx_bitslip;
    wire    [DATA_WIDTH-1:0]    serdes_rx_data;
    wire    [HDR_WIDTH-1:0]     serdes_rx_hdr;
    
    //----------------------------
    // Otras senales/variables
    //----------------------------
    
    reg     [SH_POS_WIDTH-1:0]  sh_pos;
    
    //----------------------------
    // Generacion de clock
    //----------------------------
    
    always #0.5 clk = ~clk;
    
    //----------------------------
    // Definir prueba
    //----------------------------

    `define RANDOM_DATA;

    /*
        FIXED_DATA:  Patron de datos fijo 
        RANDOM_DATA: Patron de datos aleatorio
    */

    //----------------------------
    // Patrones de prueba
    //----------------------------
    
    `ifdef FIXED_DATA
        
        reg [RX_WIDTH-1:0] test_pattern [5:0];
    
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
                for (j = 0; j < 6; j = j + 1) begin
                    serdes_rx <= test_pattern[j];
                    #100;
                end
            end
        end
    
    `elsif RANDOM_DATA
    
        integer seed1 = 32'd1;
        integer seed2 = 32'd2;
        integer seed3 = 32'd3;
        reg [RX_WIDTH-1:0] test_pattern;
       
        always begin
            test_pattern = {{$dist_uniform(seed3, 0, 4), $random(seed2), $random(seed1)}};
            #100;
        end
        
        // Asignar patrones a la entrada
        always @(posedge clk) begin
            if (!rst) begin
                serdes_rx <= test_pattern;
                #100;
            end
        end
        
    `endif
    
    //----------------------------
    // Senales internas
    //----------------------------
    
    always @(posedge clk) begin
        sh_pos <= dut.sh_pos;
    end
    
    //----------------------------
    // Testbench
    //----------------------------
    
    initial begin
        $dumpfile("eth_phy_10g_rx_frame_aligner_tb.vcd");
        $dumpvars(0, eth_phy_10g_rx_frame_aligner_tb);
    
        $display("Ejecutando simulacion...");
    
        // Inicializar clock y reset
        clk = 0;
        rst = 1;
        
        // Inicializar serdes y bitslip
        serdes_rx           = test_pattern[0];
        serdes_rx_bitslip   = 1'b0;
        
        #10;
        @(posedge clk);
        rst = 0;

        #500;
        @(posedge clk);
        serdes_rx_bitslip = 1'b1;
        @(posedge clk);
        serdes_rx_bitslip = 1'b0;
        
        #250;
        @(posedge clk);
        serdes_rx_bitslip = 1'b1;
        @(posedge clk);
        serdes_rx_bitslip = 1'b0;
        
        #100;
        $display("Tiempo de ejecucion: %0t ps", $realtime);
        $finish;
    end
    
    //----------------------------
    // Instanciacion del modulo bajo prueba
    //----------------------------
    
    eth_phy_10g_rx_frame_aligner #(
        .DATA_WIDTH(DATA_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .RX_WIDTH(RX_WIDTH),
        .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
        .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES)
    ) dut (
        .clk(clk),
        .rst(rst),
        .serdes_rx(serdes_rx),
        .serdes_rx_bitslip(serdes_rx_bitslip),
        .serdes_rx_data(serdes_rx_data),
        .serdes_rx_hdr(serdes_rx_hdr)
    );

endmodule