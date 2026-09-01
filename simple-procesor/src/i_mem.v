`timescale 1ns / 1ps
//-----------------------------------------------
// Company: agh
//-----------------------------------------------

module i_mem
(
    input  [7:0] address,
    output [31:0] data
);

    wire [31:0] program [255:0];

    // instr = {6'b000000, pc_op, 2'b00, alu_op, 1'b0, rx_op, imm_op, ry_op, rd_op, d_op, imm}

    
    assign program[0]  = 32'h00168401; // movi R4, 0x01
    assign program[1]  = 32'h001680F0; // movi R0, 0xF0
    assign program[2]  = 32'h00108001; // addi R0, R0, 0x01
    assign program[3]  = 32'h02308605; // jz   R0, 0x05
    assign program[4]  = 32'h01368602; // jump 0x02


    assign program[5]  = 32'h00168402; // movi R4, 0x02
    assign program[6]  = 32'h001680F0; // movi R0, 0xF0
    assign program[7]  = 32'h00108001; // addi R0, R0, 0x01
    assign program[8]  = 32'h0230860A; // jz   R0, 0x0A
    assign program[9]  = 32'h01368607; // jump 0x07


    assign program[10] = 32'h00058001; // andi R0, R5, 0x01
    assign program[11] = 32'h0230860A; // jz   R0, 0x0A

   
    assign program[12] = 32'h00168404; // movi R4, 0x04
    assign program[13] = 32'h001680F0; // movi R0, 0xF0
    assign program[14] = 32'h00108001; // addi R0, R0, 0x01
    assign program[15] = 32'h02308611; // jz   R0, 0x11
    assign program[16] = 32'h0136860E; // jump 0x0E

   
    assign program[17] = 32'h00168408; // movi R4, 0x08
    assign program[18] = 32'h001680F0; // movi R0, 0xF0
    assign program[19] = 32'h00108001; // addi R0, R0, 0x01
    assign program[20] = 32'h02308616; // jz   R0, 0x16
    assign program[21] = 32'h01368613; // jump 0x13


    assign program[22] = 32'h00058002; // andi R0, R5, 0x02
    assign program[23] = 32'h02308616; // jz   R0, 0x16


    assign program[24] = 32'h01368600; // jump 0x00

    assign program[25] = 32'h00000000;
    assign program[26] = 32'h00000000;
    assign program[27] = 32'h00000000;
    assign program[28] = 32'h00000000;
    assign program[29] = 32'h00000000;
    assign program[30] = 32'h00000000;
    assign program[31] = 32'h00000000;

    assign data = program[address];

endmodule


/*

0:  movi R4, 0x01      ; zapal LED0
1:  movi R0, 0xF0      ; ustaw licznik opóŸnienia

2:  addi R0, R0, 0x01  ; zwiêksz licznik
3:  jz   R0, 0x05      ; jeœli R0 == 0, zakoñcz opóŸnienie
4:  jump 0x02          ; jeœli nie, wróæ do pêtli opóŸnienia

5:  movi R4, 0x02      ; zapal LED1
6:  movi R0, 0xF0      ; ustaw licznik opóŸnienia

7:  addi R0, R0, 0x01  ; zwiêksz licznik
8:  jz   R0, 0x0A      ; jeœli R0 == 0, zakoñcz opóŸnienie
9:  jump 0x07          ; jeœli nie, wróæ do pêtli opóŸnienia

10: andi R0, R5, 0x01  ; sprawdŸ SW0
11: jz   R0, 0x0A      ; jeœli SW0 == 0, czekaj dalej

12: movi R4, 0x04      ; zapal LED2
13: movi R0, 0xF0      ; ustaw licznik opóŸnienia

14: addi R0, R0, 0x01  ; zwiêksz licznik
15: jz   R0, 0x11      ; jeœli R0 == 0, zakoñcz opóŸnienie
16: jump 0x0E          ; jeœli nie, wróæ do pêtli opóŸnienia

17: movi R4, 0x08      ; zapal LED3
18: movi R0, 0xF0      ; ustaw licznik opóŸnienia

19: addi R0, R0, 0x01  ; zwiêksz licznik
20: jz   R0, 0x16      ; jeœli R0 == 0, zakoñcz opóŸnienie
21: jump 0x13          ; jeœli nie, wróæ do pêtli opóŸnienia

22: andi R0, R5, 0x02  ; sprawdŸ SW1
23: jz   R0, 0x16      ; jeœli SW1 == 0, czekaj dalej

24: jump 0x00          ; wróæ na pocz¹tek programu
*/