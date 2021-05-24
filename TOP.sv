`timescale 10 ns/ 1 ns
module TOP
  #(parameter
  CLK_REF = 50_000_000,
  NOTE_MIN = 21,
  WIDTH_NOTE_MIN = $clog2(CLK_REF/NOTE_MIN),  
  TEMP = 8,// 1,2,4,8,16,32,64,128,256  
  RANG_TEMP = CLK_REF*4/TEMP,
  WIDTH_RANG_TEMP = $clog2(RANG_TEMP),
  NOTE = 330
  );
  logic clk;
  logic rst_l;
  logic buzzer;
  logic key1;
  
  BUZZER #(.CLK_REF(CLK_REF),.NOTE_MIN(NOTE_MIN),.TEMP(TEMP)) dut (.clk(clk),.rst_l(rst_l),.buzzer_o(buzzer),.key1(key1));
  
  always #1 clk=~clk;
  initial
    begin
	  clk=0;
	  rst_l=0;
	  key1=1;
	  @(posedge clk);
	  rst_l=1;
	  @(posedge clk);
	  key1=0;
	  @(posedge clk);
	  key1=0;
	  @(posedge clk);
	  key1=0;
	  @(posedge clk);
	  key1=1;
     #500_000_000 $stop;
	 end
endmodule
  