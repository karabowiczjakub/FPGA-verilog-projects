`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 11:27:47
// Design Name: 
// Module Name: top
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


module top
(
    input clk,
    input [3:0] sw,
    output [3:0] led
);



    reg [20:0] counter = 21'd0;
    reg slow_clk = 1'b0;
    
    always @(posedge clk) begin
        if (counter == 21'd1_249_999) begin
            counter <= 21'd0;
            slow_clk <= ~slow_clk;
        end else begin
            counter <= counter + 21'd1;
        end
    end

    wire [7:0] gpi;
    wire [7:0] gpo;

    assign gpi = {4'b0000, sw};
    assign led = gpo[3:0];

    processor processor_i (
        .clk(slow_clk),
        .gpi(gpi),
        .gpo(gpo)
    );

endmodule