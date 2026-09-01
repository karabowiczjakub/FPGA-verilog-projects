`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.05.2026 17:58:32
// Design Name: 
// Module Name: vis_centroid
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


module vis_centroid #(
    parameter IMG_W = 1920,
    parameter IMG_H = 1080
)(
    input clk,
    input ce,
    input rst,

    input de,
    input hsync,
    input vsync,

    input [23:0] pixel_in,

    input [11:0] x,
    input [11:0] y,

    output [23:0] pixel_out
);

wire [7:0] i_red;
wire [7:0] i_green;
wire [7:0] i_blue;

assign i_red   = pixel_in[23:16];
assign i_green = pixel_in[15:8];
assign i_blue  = pixel_in[7:0];



reg [11:0] x_pos = 12'd0;
reg [11:0] y_pos = 12'd0;

always @(posedge clk) begin
    if (ce) begin
        if (rst || vsync) begin
            x_pos <= 12'd0;
            y_pos <= 12'd0;
        end
        else begin
            if (de) begin
                if (x_pos == IMG_W - 1) begin
                    x_pos <= 12'd0;

                    if (y_pos == IMG_H - 1) begin
                        y_pos <= 12'd0;
                    end
                    else begin
                        y_pos <= y_pos + 12'd1;
                    end
                end
                else begin
                    x_pos <= x_pos + 12'd1;
                end
            end
        end
    end
end


wire draw;
assign draw = de && ((x_pos == x) || (y_pos == y));

wire [7:0] o_red;
wire [7:0] o_green;
wire [7:0] o_blue;

assign o_red   = draw ? 8'hff : i_red;
assign o_green = draw ? 8'h00 : i_green;
assign o_blue  = draw ? 8'h00 : i_blue;

assign pixel_out = {o_red, o_green, o_blue};

endmodule
