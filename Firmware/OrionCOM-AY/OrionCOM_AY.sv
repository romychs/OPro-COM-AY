//
// Дешифратор портов и сигналов для платы OrionPro COM-AY
//
module OrionCOM_AY (
	
	// Сигналы шины Orion PRO
	input wire clk,			// 10MHz Orion Clock
	input wire reset_n,		// RES0
	input wire iorq_n,		// -IORQ
	input wire m1_n,			// -M1
	input wire wr_n,			// -WR
	input wire rd_n,			// -RD
	input wire wait_n,		// -WAIT
	input wire [9:0] a,		// A0-A7,A14,A15
	
	// Сигналы готовности от ВВ51
	input wire rdy1,			// от порта COM1
	input wire rdy2,			// от порта COM2
	
	// Выходные сигналы
	output wire cs_vi_n,		// Выборка ВИ53
	output wire cs_vv1_n,	// Выборка ВВ51 COM1
	output wire cs_vv2_n,	// Выборка ВВ51 COM2
	output wire bdir,			// Направление данных AY
	output wire bc1,			// Выбор команды AY
	output wire w1,			// Задержанный WR для ВИ53
	output wire clk1,  		// Тактирование ВИ53, ВВ51
	output wire clk2,  		// Тактирование AY
	output wire reset,		// Инвертированный сброс для ВВ51
	output wire irq3,			// Запрос прерывания 3 в шину Orion PRO
	output wire irq4,			// Запрос прерывания 4 в шину Orion PRO
	output wire debug
);

	wire sel3x;
	wire cs_ay_opro;
	wire cs_ay_lb;
	wire cs_ay_ff;
	wire cs_ay_bf;
	wire cs_ay_3f;
	wire cs_ay_3e;
	wire cs_ay_0;
	wire cs_ay_1;
	
	assign reset = !reset_n;
	assign irq3 = !rdy1;
	assign irq4 = !rdy2;
	assign w1 = wait_n | wr_n;
	
	// Сигналы выборки портов IO
	assign sel3x = (a[7:4] == 4'b0011) && !iorq_n;
	
	assign cs_vv1_n = !(sel3x & !a[3] & !a[2]);
	assign cs_vv2_n = !(sel3x & !a[3] & a[2]);
	assign cs_vi_n  = !(sel3x & a[3] & !a[2]);
	
	// Сигналы выборки AY
	assign cs_ay_opro  = sel3x & a[2] & a[3];
	
	assign cs_ay_3f = cs_ay_opro & a[0];
	assign cs_ay_3e = cs_ay_opro & !a[0];
	
	assign cs_ay_lb =  (a[7:0] == 8'hFD) ? (m1_n & !iorq_n) : 1'b0;
	assign cs_ay_bf = a[9] & !a[8] & cs_ay_lb;
	assign cs_ay_ff = a[9] & a[8] & cs_ay_lb;
	
	assign cs_ay_0 = cs_ay_bf || cs_ay_3e;
	assign cs_ay_1 = cs_ay_ff || cs_ay_3f;
	
	
	// Сигналы управления AY
	assign bc1 = cs_ay_1 & (!rd_n | !wr_n);
   assign bdir = (cs_ay_0 || cs_ay_1) & !wr_n;
	// Тактирование AY
	AyClkDiv ayClkDiv( .clk(clk), .reset_n(reset_n), .clk_out(clk2) );
	
	// Тактирование для ВИ53, ВВ51
	ViClkDiv viClkDiv( .clk(clk), .reset_n(reset_n), .clk_out(clk1) );
	
	
	// -- DEBUG
	assign debug = clk2;			
		
endmodule


module ViClkDiv(
	input clk,
	input reset_n,
	output clk_out
);

	reg [1:0] div1;
	
	assign clk_out = div1[1];
	
	always @ (posedge clk, negedge reset_n)
		if (!reset_n) div1 <= 2'b00;
		else div1 <= div1 + 1'b1;

endmodule


/* Делитель частоты для AY
	Коэффициенты 
	для базовой частоты 10MHz:
	k = 3/17,  F= 1.764705 MHz, c = 5h
	k = 10/57, F= 1.754385 MHz, c = 2d	
	k = 7/40,  F= 1.750000 MHz, c = 1Ch
	для базовой частоты 20MHz:
	k = 3/34,  F= 1.764705 MHz, c = 0Bh;
	k = 5/57,  F= 1.754385 MHz, c = 4Fh;
	k = 7/80,  F= 1.750000 MHz, c = 39h;
	k = 8/91,  F= 1.758241 MHz, c = 71h;
	k = N/M
	k = 179/1024 F= 1.748046, c = 3F4h;
*/

module AyClkDiv(
	input clk,
	input reset_n,
	output clk_out
);

	localparam N = 9;
	localparam C = 8'd179;
	
	reg [N:0] sum;
	assign clk_out = sum[N];

	always_ff @ (posedge clk, negedge reset_n)
		if (!reset_n) sum <= 0;		
		else sum <= sum + C;
	
endmodule

/*
module AyClkDivV2(
	input clk,
	input reset_n,
	output clk_out
);

   parameter M = 7;
	parameter N = 40;
	
   localparam X = ((1<<$clog2(N)) - N + M);
   bit [$clog2(N)-1:0] cnt; // счетчик
   always @(posedge clk, negedge reset_n)
      if (!reset_n) cnt <= 0;
      else {clk_out, cnt} = cnt + (clk_out ? X:M);

endmodule
*/
