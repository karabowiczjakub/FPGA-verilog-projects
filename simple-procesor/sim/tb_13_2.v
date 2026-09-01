`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 13:40:29
// Design Name: 
// Module Name: tb_13_2
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


module tb_processor_13_2();

    reg clk = 1'b0;
    reg [7:0] gpi = 8'd0;
    wire [7:0] gpo;

    processor uut (
        .clk(clk),
        .gpi(gpi),
        .gpo(gpo)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
    
        force uut.instruction_memory.program[0] = 32'h00168005; //movi r0, 5
        force uut.instruction_memory.program[1] = 32'h00106100; //mov r1, r0
        force uut.instruction_memory.program[2] = 32'h01368602; //jump 2

        #10;

        $display("r0 = %d", uut.r0);
        $display("r1 = %d", uut.r1);
        $display("pc = %d", uut.pc);

        if (uut.r0 == 8'd5 && uut.r1 == 8'd5) begin
            $display("TEST 13.2 OK");
        end else begin
            $display("TEST 13.2 BLAD");
        end

        $finish;
    end

endmodule