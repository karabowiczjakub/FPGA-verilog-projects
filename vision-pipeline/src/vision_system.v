`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2026 10:54:29
// Design Name: 
// Module Name: vision_system
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
module vision_system #(
    parameter IMG_W = 1920,  ///dla symulacji zmieniamy 1920 lub 64
    parameter IMG_H = 1080,   ///dka symulacji zemianiamy 1080 lub 64
    parameter H_SIZE = 2200
)
(
    input         clk,
    input         de_in,
    input         hsync_in,
    input         vsync_in,
    input  [23:0] pixel_in,
    input  [3:0]  sw,

    output        de_out,
    output        hsync_out,
    output        vsync_out,
    output [23:0] pixel_out
);


    wire [7:0] r_in;
    wire [7:0] g_in;
    wire [7:0] b_in;

    wire lut_r_out;
    wire lut_g_out;
    wire lut_b_out;
    wire bin_out;

    wire [23:0] pixel_ycbcr;
    wire        de_ycbcr;
    wire        hsync_ycbcr;
    wire        vsync_ycbcr;

    wire [23:0] pixel_in_delayed;
    wire [2:0]  sync_in_delayed;

    assign r_in = pixel_in_delayed[23:16];
    assign g_in = pixel_in_delayed[15:8];
    assign b_in = pixel_in_delayed[7:0];


    delay_line #(
        .N(24),
        .DELAY(9)
    ) delay_rgb_original (
        .clk(clk),
        .idata(pixel_in),
        .odata(pixel_in_delayed)
    );

    delay_line #(
        .N(3),
        .DELAY(9)
    ) delay_sync_original (
        .clk(clk),
        .idata({de_in, hsync_in, vsync_in}),
        .odata(sync_in_delayed)
    );


    rgb2ycbcr_0 rgb2ycbcr_0 (
        .clk(clk),

        .de_in(de_in),
        .hsync_in(hsync_in),
        .vsync_in(vsync_in),
        .pixel_in(pixel_in),

        .de_out(de_ycbcr),
        .hsync_out(hsync_ycbcr),
        .vsync_out(vsync_ycbcr),
        .pixel_out(pixel_ycbcr)
    );


    LUT lut_r (
        .a(r_in),
        .clk(clk),
        .qspo(lut_r_out)
    );

    LUT lut_g (
        .a(g_in),
        .clk(clk),
        .qspo(lut_g_out)
    );

    LUT lut_b (
        .a(b_in),
        .clk(clk),
        .qspo(lut_b_out)
    );

    assign bin_out = lut_r_out & lut_g_out & lut_b_out;


    wire [7:0] cb_val;
    wire [7:0] cr_val;

    assign cb_val = pixel_ycbcr[15:8];
    assign cr_val = pixel_ycbcr[7:0];

    localparam Ta = 8'd85;
    localparam Tb = 8'd135;
    localparam Tc = 8'd135;
    localparam Td = 8'd180;

    wire [7:0] skin_bin;
assign skin_bin = ((cb_val > Ta) && (cb_val < Tb) &&
                   (cr_val > Tc) && (cr_val < Td)) ? 8'd255 : 8'd0;

wire skin_mask;
assign skin_mask = (skin_bin == 8'd255);

wire [23:0] skin_bin_rgb;
assign skin_bin_rgb = {skin_bin, skin_bin, skin_bin};


//filtracja medianowa
wire [7:0] median_bin;
wire       median_de;
wire       median_hsync;
wire       median_vsync;

median5x5 #(
    .H_SIZE(H_SIZE)
) median5x5_inst (
    .clk(clk),
    .ce(1'b1),
    .rst(1'b0),

    .de_in(de_ycbcr),
    .hsync_in(hsync_ycbcr),
    .vsync_in(vsync_ycbcr),
    .mask_in(skin_mask),

    .mask_out(median_bin),
    .de_out(median_de),
    .hsync_out(median_hsync),
    .vsync_out(median_vsync)
);

wire median_mask;
assign median_mask = (median_bin == 8'd255);

wire [23:0] median_bin_rgb;
assign median_bin_rgb = {median_bin, median_bin, median_bin};




wire [11:0] centroid_x;
wire [11:0] centroid_y;

centroid #(
    .IMG_W(IMG_W),
    .IMG_H(IMG_H)
) centroid_inst (
    .clk(clk),
    .ce(1'b1),
    .rst(1'b0),

    .de(median_de),
    .hsync(median_hsync),
    .vsync(median_vsync),
    .mask(median_mask),

    .x(centroid_x),
    .y(centroid_y)
);

wire [23:0] centroid_pixel;

vis_centroid #(
    .IMG_W(IMG_W),
    .IMG_H(IMG_H)
) vis_centroid_inst (
    .clk(clk),
    .ce(1'b1),
    .rst(1'b0),

    .de(median_de),
    .hsync(median_hsync),
    .vsync(median_vsync),

    .pixel_in(median_bin_rgb),

    .x(centroid_x),
    .y(centroid_y),

    .pixel_out(centroid_pixel)
);


    reg [23:0] pixel_out_reg;
    reg        de_out_reg;
    reg        hsync_out_reg;
    reg        vsync_out_reg;

    always @(*) begin
        case (sw)

            4'd0: begin //passthrough
                pixel_out_reg = pixel_in_delayed;
                de_out_reg    = sync_in_delayed[2];
                hsync_out_reg = sync_in_delayed[1];
                vsync_out_reg = sync_in_delayed[0];
            end

            4'd1: begin //ycbcr
                pixel_out_reg = pixel_ycbcr;
                de_out_reg    = de_ycbcr;
                hsync_out_reg = hsync_ycbcr;
                vsync_out_reg = vsync_ycbcr;
            end

            4'd2: begin //maska LUT
                pixel_out_reg = (bin_out == 1'b1) ? 24'hFFFFFF : 24'h000000;
                de_out_reg    = sync_in_delayed[2];
                hsync_out_reg = sync_in_delayed[1];
                vsync_out_reg = sync_in_delayed[0];
            end

            4'd3: begin //maska ycbcr
                pixel_out_reg = {skin_bin, skin_bin, skin_bin};
                de_out_reg    = de_ycbcr;
                hsync_out_reg = hsync_ycbcr;
                vsync_out_reg = vsync_ycbcr;
            end


            4'd4 : begin //mediana
                pixel_out_reg = median_bin_rgb;
                de_out_reg = median_de;
                hsync_out_reg = median_hsync;
                vsync_out_reg = median_vsync;
            end
            4'd5 : begin //centroid na medianie
                pixel_out_reg = centroid_pixel;
                de_out_reg    = median_de;
                hsync_out_reg = median_hsync;
                vsync_out_reg = median_vsync;
            end 
            default: begin
                pixel_out_reg = pixel_in_delayed;
                de_out_reg    = sync_in_delayed[2];
                hsync_out_reg = sync_in_delayed[1];
                vsync_out_reg = sync_in_delayed[0];
            end

        endcase
    end

    assign pixel_out = pixel_out_reg;
    assign de_out    = de_out_reg;
    assign hsync_out = hsync_out_reg;
    assign vsync_out = vsync_out_reg;
    

endmodule