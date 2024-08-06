/*
    Maquina de estados para un alineador segun el diagrama 49-14 de la norma:
    Este diseño fue realizado utilizando el metodo 1 entre N para una maquina de estados.
    7 estados -> 7 flip flops

    Señales:
        reset
        o_rx_block_lock
        test_sh         (No se usa)
        sh_cnt
        sh_invalid_cnt
        slip_done       (No se usa)
        sh_valid

    Estados:
        LOCK_INIT   = Q0
        RESET_CNT   = Q1
        TEST_SH     = Q2
        VALID_SH    = Q3
        GOOD_64     = Q4
        INVALID_SH  = Q5
        SLIP        = Q6

    Q0 = reset
    Q1 = Q0 + Q3 * (sh_cnt=64 * sh_invalid_cnt>0) + Q4 + Q5 * (sh_cnt=64 * sh_invalid_cnt<16 * o_rx_block_lock) + Q6 * slip_done
    Q2 = Q1 * test_sh + Q3 * (test_sh * sh_cnt<64) + Q5 * (test_sh * sh_cnt<64 * sh_invalid_cnt<16 * o_rx_block_lock)
    Q3 = Q2 * sh_valid
    Q4 = Q3 * (sh_cnt=64 * sh_invalid_cnt=0)
    Q5 = Q2 * !sh_valid
    Q6 = Q5 * (sh_invalid_cnt=16 + !o_rx_block_lock)
*/

`timescale 1us / 100ns

/*
 * 10G Ethernet PHY frame aligner
 */
module eth_phy_10g_rx_frame_aligner
#(
    parameter   DATA_WIDTH          = 64,
    parameter   HDR_WIDTH           = 2,
    parameter   FRAME_WIDTH         = DATA_WIDTH + HDR_WIDTH
)
(
    input  wire                     clk,
    input  wire                     rst,

    // Interfaz Serdes
    input  wire [FRAME_WIDTH-1:0]   i_serdes_rx,            // Senial de entrada de 66 bits
    output wire                     o_serdes_rx_bitslip,    // Bandera del estado Slip
    output wire [DATA_WIDTH-1:0]    o_serdes_rx_data,       // Salida de datos
    output wire [HDR_WIDTH-1:0]     o_serdes_rx_hdr,        // Salida del header

    // Status
    output wire                     o_rx_block_lock         // Bandera del estado Alineado
);

localparam      [7:0]               SH_POS_WIDTH    = $clog2(FRAME_WIDTH)   ;
localparam                          LOCK_INIT       = 7'b0000001            ;
localparam                          RESET_CNT       = 7'b0000010            ;
localparam                          TEST_SH         = 7'b0000100            ;
localparam                          VALID_SH        = 7'b0001000            ;
localparam                          GOOD_64         = 7'b0010000            ;
localparam                          INVALID_SH      = 7'b0100000            ;
localparam                          SLIP            = 7'b1000000            ;

reg             [SH_POS_WIDTH-1:0]  sh_pos                              ;   // Posicion de testeo
reg                                 serdes_rx_bitslip_reg               ;
reg                                 rx_block_lock                       ;

reg             [FRAME_WIDTH-1:0]   serdes_rx_reg                       ;
reg             [2*FRAME_WIDTH-1:0] serdes_rx_concat_reg                ;   // Registro que concatena dos frames
reg             [2*FRAME_WIDTH-1:0] serdes_rx_concat_next               ;

reg             [HDR_WIDTH-1:0]     serdes_rx_hdr_reg                   ;
reg             [HDR_WIDTH-1:0]     serdes_rx_hdr_next                  ;
reg             [DATA_WIDTH-1:0]    serdes_rx_data_reg                  ;
reg             [DATA_WIDTH-1:0]    serdes_rx_data_next                 ;

reg             [7:0]               state                               ;   // Estado actual del sistema
//reg                                 test_sh                             ;
reg             [6:0]               sh_cnt                              ;
reg             [4:0]               sh_invalid_cnt                      ;
//reg                                 slip_done                           ;
reg                                 sh_valid                            ;

always @(*) begin
    /*  ej: sh_pos = 0 y DATA_WIDTH = 2     ej: sh_pos = 3 y DATA_WIDTH = 2
        concat  = [11111111] (7:0)          concat  = [00011111] (7:0)
        hdr     = [00000011] (1:0)          hdr     = [00000011] (4:3)
        data    = [00001100] (3:2)          data    = [00001100] (6:5)
    */
    serdes_rx_concat_next           = serdes_rx_concat_reg >> sh_pos                    ;
    serdes_rx_hdr_next              = serdes_rx_concat_next[HDR_WIDTH-1   : 0]          ;
    serdes_rx_data_next             = serdes_rx_concat_next[FRAME_WIDTH-1 : HDR_WIDTH]  ;

    if(serdes_rx_hdr_next[0] ^ serdes_rx_hdr_next[1])   // Si hdr es 2'b01 o 2'b10
        sh_valid = 1'b1;
    else
        sh_valid = 1'b0;
end

always @(posedge clk) begin

    if (rst) begin
        sh_pos                          <= {SH_POS_WIDTH{1'b0}}                         ;
        state                           <= LOCK_INIT                                    ;

    end else
        case (state)
            LOCK_INIT: begin
                rx_block_lock           <= 1'b0                                         ;

                state                   <= RESET_CNT                                    ;
            end

            RESET_CNT: begin
                serdes_rx_bitslip_reg   <= 1'b0                                         ;
                sh_cnt                  <= 6'b0                                         ;
                sh_invalid_cnt          <= 4'b0                                         ;

                state                   <= TEST_SH                                      ;
            end

            TEST_SH: begin

                if(sh_valid)
                    state               <= VALID_SH                                     ;

                else
                    state               <= INVALID_SH                                   ;
            end

            VALID_SH: begin
                sh_cnt                  <= sh_cnt + 1                                   ;
                    
                if(&sh_cnt) // sh_cnt = 64
                    if(!sh_invalid_cnt) // sh_invalid_cnt = 0
                        state           <= GOOD_64                                      ;
                    else
                        state           <= RESET_CNT                                    ;
                else
                    state               <= TEST_SH                                      ;
            end

            GOOD_64: begin
                rx_block_lock         <= 1'b1                                         ;

                state                   <= RESET_CNT                                    ;
            end

            INVALID_SH: begin
                sh_cnt                  <= sh_cnt + 1                                   ;
                sh_invalid_cnt          <= sh_invalid_cnt + 1                           ;

                if(&sh_invalid_cnt || !rx_block_lock)
                    state               <= SLIP                                         ;
                else
                    if(&sh_cnt)
                        state           <= RESET_CNT                                    ;
                    else
                        state           <= TEST_SH                                      ;                                    ;
            end

            SLIP: begin
                rx_block_lock         <= 1'b0                                         ;
                serdes_rx_bitslip_reg   <= 1'b1                                         ;

                if(sh_pos == FRAME_WIDTH)
                    sh_pos              <= {SH_POS_WIDTH{1'b0}};
                else
                    sh_pos              <= sh_pos + 1;
            
                //if(slip_done)
                    state               <= RESET_CNT                                    ;
            end

            default:
                state                   <= LOCK_INIT                                    ;
                
        endcase

end

always @(posedge clk) begin
    
    if (rst) begin
        serdes_rx_concat_reg        <= {2*FRAME_WIDTH  {1'b0}}  ;
        serdes_rx_hdr_reg           <= {HDR_WIDTH   {1'b0}}     ;
        serdes_rx_data_reg          <= {DATA_WIDTH  {1'b0}}     ;
        
    end else begin
        serdes_rx_concat_reg        <= {serdes_rx_concat_reg[FRAME_WIDTH-1:0], i_serdes_rx} ;
        serdes_rx_hdr_reg           <= serdes_rx_hdr_next                                   ;
        serdes_rx_data_reg          <= serdes_rx_data_next                                  ;

        /*
        if (serdes_rx_bitslip) begin
            if(sh_pos == FRAME_WIDTH)
                sh_pos              <= {SH_POS_WIDTH{1'b0}};
            else
                sh_pos              <= sh_pos + 1;
            
            slip_done               <= 1'b1;
            
        end else
            sh_pos                  <= sh_pos;
        */
            
    end
    
end

assign o_serdes_rx_hdr      = serdes_rx_hdr_reg     ;
assign o_serdes_rx_data     = serdes_rx_data_reg    ;
assign o_serdes_rx_bitslip  = serdes_rx_bitslip_reg ;
assign o_rx_block_lock      = rx_block_lock         ;

endmodule
