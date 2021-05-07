`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Wu Yuzhang
//
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////
//功能和接口说明
//ControlUnit       是本CPU的指令译码器，组合逻辑电路
//输入
// Op               是指令的操作码部分
// Fn3              是指令的func3部分
// Fn7              是指令的func7部分
//输出
// JalD==1          表示Jal指令到达ID译码阶段
// JalrD==1         表示Jalr指令到达ID译码阶段
// RegWriteD        表示ID阶段的指令对应的寄存器写入模式
// MemToRegD==1     表示ID阶段的指令需要将data memory读取的值写入寄存器,
// MemWriteD        共4bit，采用独热码格式，对于data memory的32bit字按byte进行写入,MemWriteD=0001表示只写入最低1个byte，和xilinx bram的接口类似
// LoadNpcD==1      表示将NextPC输出到ResultM
// RegReadD         表示A1和A2对应的寄存器值是否被使用到了，用于forward的处理
// BranchTypeD      表示不同的分支类型，所有类型定义在Parameters.v中
// AluContrlD       表示不同的ALU计算功能，所有类型定义在Parameters.v中
// AluSrc2D         表示Alu输入源2的选择
// AluSrc1D         表示Alu输入源1的选择
// ImmType          表示指令的立即数格式
//实验要求
//补全模块

`include "Parameters.v"
module ControlUnit(
           input wire [6: 0] Op,
           input wire [2: 0] Fn3,
           input wire [6: 0] Fn7,
           output wire JalD,
           output wire JalrD,
           output reg [2: 0] RegWriteD,
           output wire MemToRegD,
           output reg [3: 0] MemWriteD,
           output wire LoadNpcD,
           output reg [1: 0] RegReadD,
           output reg [2: 0] BranchTypeD,
           output reg [3: 0] AluContrlD,
           output wire [1: 0] AluSrc2D,
           output wire AluSrc1D,
           output reg [2: 0] ImmType
       );
assign LoadNpcD = JalD | JalrD ;
assign JalD = (Op == 7'b1101111) ? 1'b1 : 1'b0;
assign JalrD = (Op == 7'b1100111) ? 1'b1 : 1'b0;
assign MemToRegD = (Op == 7'b0000011) ? 1'b1 : 1'b0;
assign AluSrc1D = (Op == 7'b0010111) ? 1'b1 : 1'b0;
;
always @( * ) begin
    if (Op == 7'b0010011)
        && (Fn3[1: 0] == 2'b01)
     begin
         AluSrc2D <= 2'b01;
     end
     else if ( (Op == 7'b0110011) || (Op == 7'b1100011) )
     begin
         AluSrc2D <= 2'b00 ;
     end
     else
     begin
         AluSrc2D <= 2'b10;
     end
 end
 always @( * ) begin
     case (ImmType)
         `RTYPE:
             RegReadD = 2'b11;
         `ITYPE:
             RegReadD = 2'b10;
         `STYPE:
             RegReadD = 2'b11;
         `BTYPE:
             RegReadD = 2'b11;
         `UTYPE:
             RegReadD = 2'b00;
         `JTYPE:
             RegReadD = 2'b00;
         default:
             RegReadD = 2'b00;
     endcase
 end
 always @( * ) begin
     if (Op == 7'b1100011)
     begin
         case (Fn3)
             3'b000:
                 BranchTypeD <= `BEQ;
             3'b001:
                 BranchTypeD <= `BNE;
             3'b100:
                 BranchTypeD <= `BLT;
             3'b101:
                 BranchTypeD <= `BGE;
             3'b110:
                 BranchTypeD <= `BLTU;
             default:
                 BranchTypeD <= `BGEU;
         endcase
     end
     else
     begin
         BranchTypeD <= `NOBRANCH;
     end
 end
 always @( * ) begin
     case (Op)
         7'b0010011:
         begin
             RegWriteD <= `LW;
             MemWriteD <= 4'b0000;
             ImmType <= `ITYPE;
             case (Fn3)
                 3'b000:
                     AluContrlD <= `ADD;
                 3'b001:
                     AluContrlD <= `SLL;
                 3'b010:
                     AluContrlD <= `SLT;
                 3'b011:
                     AluContrlD <= `SLTU;
                 3'b100:
                     AluContrlD <= `XOR;
                 3'b101:
                 begin
                     if (Fn7[5] == 1)
                         AluContrlD <= `SRA;
                     else
                     begin
                         AluCOntrolD <= `SRL;
                     end
                 end

                 3`110:
                     AluContrlD <= `OR;
                 default:
                     AluContrlD <= `AND;
             endcase
         end
         7'b0000011:
         begin
             MemWriteD <= 4'b0000;
             AluContrlD <= `ADD;
             ImmType <= `ITYPE;
             case (Fn3)
                 3'b000:
                     RegWriteD <= `LB;
                 3'b001:
                     RegWriteD <= `LH;
                 3'b010:
                     RegWriteD <= `LW;
                 3'b100:
                     RegWriteD <= `LBU;
                 default:
                     RegWriteD <= `LHU;
             endcase
         end
         7'b0100011:
         begin
             RegWriteD <= `NOREGWRITE;
             AluContrlD <= `ADD;
             ImmType <= `STYPE;
             case (Fn3)
                 3'b000:
                     MemWriteD <= 4'b0001;
                 3'b001:
                     MemWriteD <= 4'b0011;
                 default:
                     MemWriteD <= 4'b1111;
             endcase
         end
         7'b0110111:
         begin
             RegWriteD <= `LW;
             MemWriteD <= 4'b0000;
             AluContrlD <= `LUI;
             ImmType <= `UTYPE;
         end
         7'b0010111:
         begin
             RegWriteD <= `LW;
             MemWriteD <= 4'b0000;
             AluContrlD <= `ADD;
             ImmType <= `UTYPE;
         end
         7'b1101111:
         begin
             RegWriteD <= `LW;
             MemWriteD <= 4'b0000;
             AluContrlD <= `ADD;
             ImmType <= `JTYPE;
         end
         7'b1100111:
         begin
             RegWriteD <= `LW;
             MemWriteD <= 4'b0000;
             AluContrlD <= `ADD;
             ImmType <= `ITYPE;
         end
         7'b1100011:
         begin
             RegWriteD <= `NOREGWRITE;
             MemWriteD <= 4'b0000;
             ImmType <= `BTYPE;
             AluContrlD <= `ADD;
         end
         default:
         begin
             RegWriteD <= `NOREGWRITE;
             MemWriteD <= 4'b0000;
             AluContrlD <= `ADD;
             ImmType <= `ITYPE;
         end
     endcase
 end
 // 请补全此处代码

 endmodule

