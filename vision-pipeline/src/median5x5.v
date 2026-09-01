`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 17:16:03
// Design Name: 
// Module Name: median5x5
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module median5x5 #(parameter H_SIZE = 83)  
    (input clk, 
    input ce, 
    input rst, 
    
    input de_in,
    input hsync_in, 
    input vsync_in,
    input mask_in,
    
    output [7:0] mask_out,
    output de_out,
    output hsync_out,
    output vsync_out

    );
    


    wire [15:0] data_in;
    assign data_in = {12'd0, mask_in, de_in, hsync_in, vsync_in};

    wire [12:0] h_size_delay;
    assign h_size_delay = H_SIZE - 5;


    reg [15:0] d11 = 16'd0, d12 = 16'd0, d13 = 16'd0, d14 = 16'd0, d15 = 16'd0;
    reg [15:0] d21 = 16'd0, d22 = 16'd0, d23 = 16'd0, d24 = 16'd0, d25 = 16'd0;
    reg [15:0] d31 = 16'd0, d32 = 16'd0, d33 = 16'd0, d34 = 16'd0, d35 = 16'd0;
    reg [15:0] d41 = 16'd0, d42 = 16'd0, d43 = 16'd0, d44 = 16'd0, d45 = 16'd0;
    reg [15:0] d51 = 16'd0, d52 = 16'd0, d53 = 16'd0, d54 = 16'd0, d55 = 16'd0;


    wire [15:0] line1_out;
    wire [15:0] line2_out;
    wire [15:0] line3_out;
    wire [15:0] line4_out;

    delayLineBRAM_WP #(
        .WIDTH(16),
        .BRAM_SIZE_W(13)
    ) line1 (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .din(d15),
        .dout(line1_out),
        .h_size(h_size_delay)
    );

    delayLineBRAM_WP #(
        .WIDTH(16),
        .BRAM_SIZE_W(13)
    ) line2 (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .din(d25),
        .dout(line2_out),
        .h_size(h_size_delay)
    );

    delayLineBRAM_WP #(
        .WIDTH(16),
        .BRAM_SIZE_W(13)
    ) line3 (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .din(d35),
        .dout(line3_out),
        .h_size(h_size_delay)
    );

    delayLineBRAM_WP #(
        .WIDTH(16),
        .BRAM_SIZE_W(13)
    ) line4 (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .din(d45),
        .dout(line4_out),
        .h_size(h_size_delay)
    );


    always @(posedge clk) begin
        if (ce) begin
            if (rst) begin
                d11 <= 16'd0; d12 <= 16'd0; d13 <= 16'd0; d14 <= 16'd0; d15 <= 16'd0;
                d21 <= 16'd0; d22 <= 16'd0; d23 <= 16'd0; d24 <= 16'd0; d25 <= 16'd0;
                d31 <= 16'd0; d32 <= 16'd0; d33 <= 16'd0; d34 <= 16'd0; d35 <= 16'd0;
                d41 <= 16'd0; d42 <= 16'd0; d43 <= 16'd0; d44 <= 16'd0; d45 <= 16'd0;
                d51 <= 16'd0; d52 <= 16'd0; d53 <= 16'd0; d54 <= 16'd0; d55 <= 16'd0;
            end
            else begin
                
                d11 <= data_in;
                d12 <= d11;
                d13 <= d12;
                d14 <= d13;
                d15 <= d14;

                
                d21 <= line1_out;
                d22 <= d21;
                d23 <= d22;
                d24 <= d23;
                d25 <= d24;

                
                d31 <= line2_out;
                d32 <= d31;
                d33 <= d32;
                d34 <= d33;
                d35 <= d34;

                
                d41 <= line3_out;
                d42 <= d41;
                d43 <= d42;
                d44 <= d43;
                d45 <= d44;

                
                d51 <= line4_out;
                d52 <= d51;
                d53 <= d52;
                d54 <= d53;
                d55 <= d54;
            end
        end
    end

    wire p11 = d11[3]; wire p12 = d12[3]; wire p13 = d13[3]; wire p14 = d14[3]; wire p15 = d15[3];
    wire p21 = d21[3]; wire p22 = d22[3]; wire p23 = d23[3]; wire p24 = d24[3]; wire p25 = d25[3];
    wire p31 = d31[3]; wire p32 = d32[3]; wire p33 = d33[3]; wire p34 = d34[3]; wire p35 = d35[3];
    wire p41 = d41[3]; wire p42 = d42[3]; wire p43 = d43[3]; wire p44 = d44[3]; wire p45 = d45[3];
    wire p51 = d51[3]; wire p52 = d52[3]; wire p53 = d53[3]; wire p54 = d54[3]; wire p55 = d55[3];


    wire context_valid;

    assign context_valid =
        d11[2] & d12[2] & d13[2] & d14[2] & d15[2] &
        d21[2] & d22[2] & d23[2] & d24[2] & d25[2] &
        d31[2] & d32[2] & d33[2] & d34[2] & d35[2] &
        d41[2] & d42[2] & d43[2] & d44[2] & d45[2] &
        d51[2] & d52[2] & d53[2] & d54[2] & d55[2];


    wire [4:0] sum_ones;

    assign sum_ones =
        p11 + p12 + p13 + p14 + p15 +
        p21 + p22 + p23 + p24 + p25 +
        p31 + p32 + p33 + p34 + p35 +
        p41 + p42 + p43 + p44 + p45 +
        p51 + p52 + p53 + p54 + p55;


    wire median_bit;
    assign median_bit = context_valid && (sum_ones > 5'd12);


    assign mask_out  = median_bit ? 8'd255 : 8'd0;
    assign de_out    = d33[2];
    assign hsync_out = d33[1];
    assign vsync_out = d33[0];

endmodule