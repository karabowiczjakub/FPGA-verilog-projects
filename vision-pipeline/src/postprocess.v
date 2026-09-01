`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2026 10:50:30
// Design Name: 
// Module Name: postprocess
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

module postprocess(
    input  [23:0] video_in,
    output [35:0] video_out
);

// wejœcie z vision_system RGB = {R, G, B}
// wyjœcie do DisplayPort BRG = {B, R, G}
assign video_out = {
    video_in[7:0],    4'b0000,  // B 
    video_in[23:16],  4'b0000,  // R 
    video_in[15:8],   4'b0000   // G 
};

endmodule
