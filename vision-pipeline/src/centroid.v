`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.05.2026 16:30:30
// Design Name: 
// Module Name: centroid
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


module centroid #(
    parameter IMG_W = 1920,
    parameter IMG_H = 1080
)(
    input clk,
    input ce,
    input rst,

    input de,
    input hsync,
    input vsync,
    input mask,

    output [11:0] x,
    output [11:0] y
);

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


reg prev_vsync = 1'b0;

always @(posedge clk) begin
    if (ce) begin
        if (rst) begin
            prev_vsync <= 1'b0;
        end
        else begin
            prev_vsync <= vsync;
        end
    end
end

wire eof;
assign eof = (prev_vsync == 1'b0 && vsync == 1'b1) ? 1'b1 : 1'b0;


wire mask_de;
assign mask_de = mask & de;


reg [31:0] m00 = 32'd0;

always @(posedge clk) begin
    if (ce) begin
        if (rst || eof) begin
            m00 <= 32'd0;
        end
        else begin
            if (mask_de) begin
                m00 <= m00 + 32'd1;
            end
        end
    end
end



wire [31:0] m10;
wire [31:0] m01;

accumulator_unsigned #(
    .ACC_W(32),
    .DATA_W(12)
) acc_m10 (
    .clk(clk),
    .rst(rst | eof),
    .ce(ce & mask_de),
    .din(x_pos),
    .dout(m10)
);

accumulator_unsigned #(
    .ACC_W(32),
    .DATA_W(12)
) acc_m01 (
    .clk(clk),
    .rst(rst | eof),
    .ce(ce & mask_de),
    .din(y_pos),
    .dout(m01)
);


wire div_start;
assign div_start = ce & eof & (m00 != 32'd0);


wire [31:0] x_div;
wire [31:0] y_div;

wire x_qv;
wire y_qv;

divider_32_21_0 div_x (
    .clk(clk),
    .start(div_start),
    .dividend(m10),
    .divisor(m00[20:0]),
    .quotient(x_div),
    .qv(x_qv)
);

divider_32_21_0 div_y (
    .clk(clk),
    .start(div_start),
    .dividend(m01),
    .divisor(m00[20:0]),
    .quotient(y_div),
    .qv(y_qv)
);


reg [11:0] x_reg = 12'd0;
reg [11:0] y_reg = 12'd0;

always @(posedge clk) begin
    if (ce) begin
        if (rst) begin
            x_reg <= 12'd0;
            y_reg <= 12'd0;
        end
        else begin
            if (eof && m00 == 32'd0) begin
                x_reg <= 12'd0;
                y_reg <= 12'd0;
            end

            if (x_qv) begin
                x_reg <= x_div[11:0];
            end

            if (y_qv) begin
                y_reg <= y_div[11:0];
            end
        end
    end
end

assign x = x_reg;
assign y = y_reg;

endmodule