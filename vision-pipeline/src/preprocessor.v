`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2026 10:35:48
// Design Name: 
// Module Name: preprocessor
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

module preprocess(
    input  [23:0] video_in,
    output [23:0] video_out
);

// wejœcie z kamery BRG = {B, R, G}
// wyjœcie do vision_system RGB = {R, G, B}
assign video_out = {
    video_in[15:8],   // R
    video_in[7:0],    // G
    video_in[23:16]   // B
};

endmodule