`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.05.2026 17:31:56
// Design Name: 
// Module Name: accumulator_unsigned
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


module accumulator_unsigned #(
    parameter ACC_W  = 32,
    parameter DATA_W = 12
)(
    input clk,
    input rst,
    input ce,

    input  [DATA_W-1:0] din,
    output reg [ACC_W-1:0] dout
);

always @(posedge clk) begin
    if (rst) begin
        dout <= {ACC_W{1'b0}};
    end
    else begin
        if (ce) begin
            dout <= dout + {{(ACC_W-DATA_W){1'b0}}, din};
        end
    end
end

endmodule