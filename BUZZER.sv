module BUZZER
  #(parameter
  CLK_REF = 50_000_000,
  NUM_STATE = 3,
  WIDTH_NUM_STATE = $clog2(NUM_STATE), 
  NUM_OCTAV = 1,
  WIDTH_NUM_OCTAV = $clog2(NUM_OCTAV*7),
  NOTE_MIN = 21,
  WIDTH_RANG_NOTE_MIN = $clog2(CLK_REF/NOTE_MIN),
  NOTE_MAX = 520,
  WIDTH_NOTE_MAX = $clog2(NOTE_MAX),
  SIZE = 4, 
  TEMP = 8,// 1,2,4,8,16,32,64,128,256  
  RANG_TEMP = CLK_REF*SIZE/TEMP,
  WIDTH_RANG_TEMP = $clog2(RANG_TEMP) 
  )
  (
  input clk,
  input rst_l,
  input key1,
  output logic buzzer_o,
  output logic [4-1:0] led_o
  );
  
  logic buzzer;

  assign buzzer_o = buzzer;
  
  logic enable = 0;
  logic [1:0] mem_key1;

  always_ff @( posedge clk )
    begin
      mem_key1 <= {mem_key1[0],key1};
      case ( mem_key1 )
        2'b10:   enable <= ~enable;
        2'b00:   enable <= enable;
        2'b01:   enable <= enable;
        2'b11:   enable <= enable;
      endcase
    end
	 
  logic [ WIDTH_NOTE_MAX-1:0 ] note_frecuncy  [NUM_OCTAV*7];
  logic [ 4-1:0 ]              led  [NUM_OCTAV*7];
  
  initial
	begin
		$readmemb("note.txt", note_frecuncy,0,NUM_OCTAV*7-1);
		$readmemb("led.txt", led,0,NUM_OCTAV*7-1);
	end
  
  //initial begin
  //[NUM_OCTAV*7] note_frecuncy ={8'd330,8'd338,8'd345,8'd352,8'd359,8'd365,8'd372};
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[0]=330;
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[1]=338;
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[2]=345;
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[3]=352;
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[4]=359;
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[5]=365;
  //logic [ WIDTH_NOTE_MIN-1:0 ] note_frecuncy[6]=372;
  //end
  
  typedef enum logic [WIDTH_NUM_OCTAV-1:0]{
  Repeat_Note =  3'd0,
  DO_1tsOct   =  3'd1,
  RE_1tsOct   =  3'd2,
  MI_1tsOct   =  3'd3,
  FA_1tsOct   =  3'd4,
  SOL_1tsOct  =  3'd5,
  LYA_1tsOct  =  3'd6,
  SI_1tsOct   =  3'd7
  } nt;

  nt note;
  
  logic [ WIDTH_RANG_TEMP-1:0 ]        temp_count;
  logic [ WIDTH_RANG_NOTE_MIN-1:0 ]    note_count;
  logic [ $clog2(CLK_REF)-1:0 ]        led_count; 

  bit en_temp;
  bit en_note;
  bit rst_l_temp;
  bit rst_l_note;
  
  //led buzzer
  
  COUNT #( .WIDTH($clog2(CLK_REF)) ) cntSec   ( 
															 .clk(clk),
															 .reset(rst_l),
															 .enable(enable),
															 .count(led_count) 
															 );

	 
  //led buzzer	end
  
  //counters for note out of buzzer
  
  COUNT #( .WIDTH(WIDTH_RANG_TEMP) ) cntTemp ( 
															 .clk(clk),
															 .reset(rst_l_temp),
															 .enable(en_temp),
															 .count(temp_count) //for TempSate
															 );
															 
  COUNT #( .WIDTH(WIDTH_RANG_NOTE_MIN) ) cntNote ( 
															.clk(clk),
															.reset(rst_l_note),
															.enable(en_note),
															.count(note_count) //for NoteSate
															);
  
  //state machin of buzzer
  
  typedef enum logic [WIDTH_NUM_STATE-1:0]{
  ResetState, 
  TempSate,   
  NoteSate   
  } state;

  state st;
  
  enum logic [WIDTH_NUM_STATE-1:0]{
  StartNote_St, 
  ExitTemp_St 
  } temp_state;

  enum logic [WIDTH_NUM_STATE-1:0]{
  Posedge_St, 
  Negedge_St,   
  ExitNote_St  
  } note_state;

  int i;

  always@( posedge clk or negedge rst_l )
  begin  
    i   = 0;
    st <= ResetState;
    casez( st )
      ResetState: begin
		    if (!rst_l) begin
		      buzzer     <=  1'bz;
		      rst_l_temp <=  1'b0;
 		      rst_l_note <=  1'b0;
 		      st         <=  ResetState;
		    end else begin
		      if (enable) begin
		        st         <=  TempSate;
		        rst_l_temp <=  1'b1;
 		        rst_l_note <=  1'b1;
		        en_temp    <=  1'b1;
		      end else begin
		        buzzer     <=  1'b1;
 		        st         <=  ResetState;
		      end
		    end
		  end
      TempSate:   begin
		    temp_state <=  StartNote_St;
		    casez( temp_state )
		      StartNote_St: begin
				      if ( temp_count == 0 ) begin
				        if ( note_frecuncy[i] == 0 ) begin
				          st         <=  NoteSate;
				          temp_state <=  StartNote_St;
				          en_note    <=  1'b1;
				          rst_l_note <=  1'b1;
				        end else begin
				          st         <=  TempSate;
				          temp_state  =  StartNote_St;
				          en_note    <=  1'b1;
				          rst_l_note <=  1'b1;
				          buzzer     <=  1'b1;
				        end
				      end else begin
				        st         <=  TempSate;
				        temp_state <=  ExitTemp_St;
				      end
				    end
		      ExitTemp_St:  begin
				      if ( temp_count == RANG_TEMP ) begin 
		                        st         <=  ResetState;
		                        rst_l_temp <=  1'b0;
		                        led_o <= i[3:0];
		                        if ( i <= NUM_OCTAV*7-1 )
		                          i  <=  i + 1'b1;
		                        else
		                          i  <=  1'b0;
				      end else begin
  				        st         <=  TempSate;
				      end
				    end 
		    endcase
                  end  
      NoteSate:   begin
		    note_state <=  Posedge_St;
		    casez( note_state )
		      Posedge_St: begin
				    if ( note_count <= ((CLK_REF+1)/(2*note_frecuncy[i])) ) begin
				      st         <=  NoteSate;
				      buzzer     <=  1'b0;
				      note_state  =  Posedge_St;
				      rst_l_temp <=  1'b1;
				    end else begin
				      st         <=  NoteSate;
				      buzzer     <=  1'b1;
				      note_state <=  Negedge_St;
				    end
				  end
		      Negedge_St: begin
				    if ( note_count <= ((CLK_REF+1)/note_frecuncy[i]) ) begin 
				      st         <=  NoteSate;
				      buzzer     <=  1'b1;
				      note_state <=  Negedge_St;
				    end else begin
				      st         <=  NoteSate;
				      buzzer     <=  1'b0;
				      note_state <=  ExitNote_St;
				      rst_l_temp <=  1'b0;
				    end
				  end
		      ExitNote_St:begin
				    if ( note_count >= RANG_TEMP/((CLK_REF+1)/note_frecuncy[i]) ) begin
				      st         <=  TempSate;
				      note_state <=  ExitNote_St;
				    end else begin
				      st         <=  NoteSate;
				      note_state <=  Posedge_St;
				    end
				  end
		    endcase
                  end

    endcase
  end
endmodule 