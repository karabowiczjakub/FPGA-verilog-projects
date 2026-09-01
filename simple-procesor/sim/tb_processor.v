`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 17:00:31
// Design Name: 
// Module Name: tb_processor
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
module tb_processor();

    reg clk = 1'b0;

    // gpi = symulowane przelaczniki SW
    reg [7:0] gpi = 8'd0;

    // gpo = symulowane diody LED
    wire [7:0] gpo;

    processor uut (
        .clk(clk),
        .gpi(gpi),
        .gpo(gpo)
    );

    // zegar: okres 2 ns
    initial begin
        while (1) begin
            #1 clk = 1'b0;
            #1 clk = 1'b1;
        end
    end

 
    initial begin
        gpi = 8'b00000000;

        //z led0 na led1
        #500;

        // SW0 zmienia na LED 2
        gpi = 8'b00000001;

        //do led3 i czeka
        #400;

        // SW1 gasi LED3 i wraca na pocz¹tek
        gpi = 8'b00000011;

        // procesor powinien wrocic do poczatku
        #600;

        $finish;
    end

endmodule