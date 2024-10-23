/*
    Generador de MII hecho por el profe y adaptado por mi
*/

module signal_generator #(
    parameter               DATA_WIDTH = 64             ,   // Must be a multiple of 8 bits (octets)
    parameter               CTRL_WIDTH = DATA_WIDTH / 8 ,   // Control interface
    parameter int           DATA_CHAR_PROBABILITY = 70  ,   // Probability in percentage (0-100)
    parameter       [7:0]   DATA_CHAR_PATTERN = 8'hAA   ,   // Pattern for data character
    parameter       [7:0]   CTRL_CHAR_PATTERN = 8'h55       // Pattern for control character
)(
    input  logic                        clk             ,
    input  logic                        rst             ,
    output logic    [DATA_WIDTH-1:0]    o_data          ,
    output logic    [CTRL_WIDTH-1:0]    o_ctrl
);
    // Internal variables
    int random_num;

    always_ff @(posedge clk or posedge rst) begin     // Edge dependent sequencial logic 
        if (rst) begin
            o_data <= '0;
            o_ctrl <= '0;
        end else begin
            // For each octet, decide whether to generate a data or control character
            for (int i = 0; i < CTRL_WIDTH; i++) begin
                random_num = $urandom_range(0, 99);
                if (random_num < DATA_CHAR_PROBABILITY) begin
                    // Data character
                    o_data[i*8 +: 8] <= DATA_CHAR_PATTERN;
                    o_ctrl[i]        <= 1'b0;
                end else begin
                    // Control character
                    o_data[i*8 +: 8] <= CTRL_CHAR_PATTERN;
                    o_ctrl[i]        <= 1'b1;
                end
            end
        end
    end
endmodule
