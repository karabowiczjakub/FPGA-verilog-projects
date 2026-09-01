`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 15:38:15
// Design Name: 
// Module Name: processor
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


module processor(
    input clk,
    input [7 : 0] gpi,
    output [7 : 0] gpo
);

    // rejestry
    reg [7:0] r0 = 8'd0;
    reg [7:0] r1 = 8'd0;
    reg [7:0] r2 = 8'd0;
    reg [7:0] r3 = 8'd0;
    reg [7:0] r4 = 8'd0;
    //reg [7:0] r5 = 8'd0;
    
    assign gpo = r4;

    wire [7:0] r5;
    assign r5 = gpi;
    // r6 = stala wartosc 0
    wire [7:0] r6;
    assign r6 = 8'd0;

    // r7 = pc
    reg [7:0] pc = 8'd0;


    // pamiec instrukcji
    wire [7:0] pc_addr;
    wire [31:0] instr;

    assign pc_addr = pc;

    i_mem instruction_memory (
        .address(pc_addr),
        .data(instr)
    );


    // pamiec danych
    wire [7:0] d_addr;
    wire [7:0] d_data;

    d_mem data_memory (
        .address(d_addr),
        .data(d_data)
    );


    // dekodowanie instrukcji
    wire [1:0] pc_op;
    wire [1:0] alu_op;
    wire [2:0] rx_op;
    wire       imm_op;
    wire [2:0] ry_op;
    wire       rd_op;
    wire [2:0] d_op;
    wire [7:0] imm;

    assign pc_op  = instr[25:24];
    assign alu_op = instr[21:20];
    assign rx_op  = instr[18:16];
    assign imm_op = instr[15];
    assign ry_op  = instr[14:12];
    assign rd_op  = instr[11];
    assign d_op   = instr[10:8];
    assign imm    = instr[7:0];


    // mux rx i ry
    reg [7:0] rx;
    reg [7:0] ry;

    always @(*) begin
        case (rx_op)
            3'd0: rx = r0;
            3'd1: rx = r1;
            3'd2: rx = r2;
            3'd3: rx = r3;
            3'd4: rx = r4;
            3'd5: rx = r5;
            3'd6: rx = r6;
            3'd7: rx = pc;
            default: rx = 8'd0;
        endcase
    end

    always @(*) begin
        case (ry_op)
            3'd0: ry = r0;
            3'd1: ry = r1;
            3'd2: ry = r2;
            3'd3: ry = r3;
            3'd4: ry = r4;
            3'd5: ry = r5;
            3'd6: ry = r6;
            3'd7: ry = pc;
            default: ry = 8'd0;
        endcase
    end


    // mux imm
    wire [7:0] alu_y;

    assign alu_y = (imm_op == 1'b1) ? imm : ry;


    // ALU
    reg [7:0] alu_res;
    wire      cmp_res;

    // komparator sprawdza zawsze rx
    assign cmp_res = (rx == 8'd0);

    always @(*) begin
        case (alu_op)
            2'd0: begin
                // AND
                alu_res = rx & alu_y;
            end

            2'd1: begin
                // ADD
                alu_res = rx + alu_y;
            end

            2'd2: begin
               
                alu_res = {7'd0, cmp_res};
            end

            2'd3: begin
               
                alu_res = alu_y;
            end

            default: begin
                alu_res = 8'd0;
            end
        endcase
    end


    // adres pamieci danych pochodzi z ALU
    assign d_addr = alu_res;


    // rd_mux - wybor danych do zapisu
    wire [7:0] rd_data;

    assign rd_data = (rd_op == 1'b1) ? d_data : alu_res;


    // warunek skoku
    reg pc_jump;

    always @(*) begin
        case (pc_op)
            2'd0: pc_jump = 1'b0;       // brak skoku
            2'd1: pc_jump = 1'b1;       // jump
            2'd2: pc_jump = cmp_res;    // jz
            2'd3: pc_jump = ~cmp_res;   // jnz
            default: pc_jump = 1'b0;
        endcase
    end


    // pc_mux
    wire [7:0] pc_next;

    assign pc_next = (pc_jump == 1'b1) ? alu_res : (pc + 8'd1);


    // zapis do rejestrow i aktualizacja pc
    always @(posedge clk) begin
        case (d_op)
            3'd0: r0 <= rd_data;
            3'd1: r1 <= rd_data;
            3'd2: r2 <= rd_data;
            3'd3: r3 <= rd_data;
            3'd4: r4 <= rd_data;
            //3'd5: r5 <= rd_data;

            default: begin
                // r6 jest stale zerem, r7 to pc
                // tutaj nic nie zapisujemy
            end
        endcase

        pc <= pc_next;
    end

endmodule