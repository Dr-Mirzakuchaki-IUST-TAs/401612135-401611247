
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity I2C_Protocol is

	port(clk 			:		 in 	 STD_LOGIC 					   := '0';  -- standard mode (fc = 50 Mhz)
		 reset_n 		:		 in 	 STD_LOGIC 					   := '1';
		 enable 		:		 in 	 STD_LOGIC 					   := '0';
		 busy 			:		 out 	 STD_LOGIC 					   := '0';
		 ack_error  	:		 inout   STD_LOGIC 					   := '0';
		 sda 			:		 inout   STD_LOGIC 					   := 'Z';
		 scl 			:		 out     STD_LOGIC 					   := 'Z';
		 rw 			:		 in 	 STD_LOGIC 					   := '0';
		 rw_ctrl		: 		 out 	 STD_LOGIC 					   := '0';	
		 read_mode 		: 		 out 	 STD_LOGIC  				   := '0';
		 command_byte	:		 in   	 STD_LOGIC_vector(7 downto 0)  := (others => '0');
		 addres 		:	 	 in      STD_LOGIC_vector(6 downto 0)  := "1001000"; --(A0 is connected to GND)
		 data_wr 		:		 in  	 STD_LOGIC_vector(7 downto 0)  := (others => '0');
		 data_rd 		:		 out 	 STD_LOGIC_vector(7 downto 0)  := (others => '0');
		 rd_cnt  		:  		 buffer  integer 		 range 0 to 7  := 0 

		);
end I2C_Protocol ;

architecture Behavioral of I2C_Protocol is

	type      machine is (ready ,start_con ,addr_seq ,slave_ack1 , command_seq , slave_ack2 , wr , rd ,slave_ack3 , mstr_ack , stop_con);
	signal    state 			: 			machine 						:= ready;
	signal    data_clk 			: 			STD_LOGIC 						:= '0';
	signal    data_clk_prev 	: 			STD_LOGIC 						:= '0';
	signal    scl_clk 			: 			STD_LOGIC 						:= '0';
	signal    scl_en 			: 			STD_LOGIC 						:= '0';
	signal    sda_int 			: 			STD_LOGIC 						:= '1';
	signal 	  tx 				:  			STD_LOGIC 						:= '0';
	signal    sda_enable		: 			STD_LOGIC 						:= '0';
	signal    addr_rw 			: 			STD_LOGIC_vector(7 downto 0)	:=(others => '0');
	signal    command_byte_r 	: 			STD_LOGIC_vector(7 downto 0)	:=(others => '0');
	signal    data_tx 			: 			STD_LOGIC_vector(7 downto 0)	:=(others => '0');
	signal    data_rx 			: 			STD_LOGIC_vector(7 downto 0)	:=(others => '0');
	signal    bit_cnt 			: 			integer range 0 to 7 			:= 7;
	signal    read_mode_int  	:  			STD_LOGIC  						:= '0';
	signal 	  rw_ctrl_int 		:			STD_LOGIC 						:= '0';
 
begin

-- SDA & SCL clock generation 
process(clk,reset_n)
	variable count : integer range 0 to 500 ;
begin

	if(reset_n = '0')then
		count := 0 ;
	elsif(clk 'event and clk ='1')then
		data_clk_prev <= data_clk ;
		if(count = 499)then -- i2c clock = 50000000/500 = 100000 hz
			count := 0 ;
		else
			count := count + 1;
		end if;

		case count is
		
			when 0 to 124 =>
				scl_clk <= '0';
				data_clk <= '0';
	
			when 125 to 249  =>
				scl_clk <= '0';
				data_clk <= '1';

			when 250 to 374 =>
				scl_clk <= '1';
				data_clk <= '1';

			when 375 to 499 =>
				scl_clk <= '1';
				data_clk <= '0';	
			when others =>
				null;
		end case ;

	end if ;

end process;

process(clk ,reset_n)
begin

	if(reset_n = '0')then
		state <= ready;
		busy <= '1';    --in reset condition we cannot transport data
		scl_en <= '0';	-- scl is high impedance
		sda_int <= '1';  --sda is high impedance
		ack_error <= '0';
		rw_ctrl_int <= 'Z';
		bit_cnt <= 7 ; -- meaning that we reseted the bit counter
		data_rd <= (others => '0');
	elsif(clk 'event and clk ='1')then
		-- writing cycle
		if(data_clk = '1' and data_clk_prev = '0')then -- rising edge of SDA clk is happend and we can transport data(no receive data in this edge)
			case state is
			
				when ready =>
					busy <= '0';
					rw_ctrl_int <= '0';
					if(enable = '1')then
					   busy <= '1';
					   addr_rw <= addres & rw ;
					   data_tx <= data_wr;
					   state <= start_con ;
					else
						scl_en <= '0';
						state <= ready ;
					end if ;
			
				when start_con =>

					rw_ctrl_int <= '0';
					busy <= '1';
					sda_int <= addr_rw(bit_cnt);
					if(rw = '1')then
						addr_rw <= addres & rw ;
						state <= addr_seq;
					else
						state <= addr_seq ;
					end if;

				when addr_seq =>

					rw_ctrl_int <= '0';
					if(bit_cnt = 0)then
						bit_cnt <= 7 ;
						sda_int <= '1'; -- sda is high impedance so slave can send the acknowledge data	
						if(addr_rw(0) = '0')then						 						
							state <= slave_ack1 ;
							rw_ctrl_int <= '1';
						else
							state <= slave_ack2 ;
							rw_ctrl_int <= '1';
						end if;
					else
						bit_cnt <= bit_cnt - 1 ;
						sda_int <= addr_rw(bit_cnt - 1);
						state <= addr_seq ;
					end if;

				when slave_ack1 => 
				
					rw_ctrl_int <= '0';
					state <= command_seq ;
					command_byte_r <= command_byte ;
					busy <= '1' ;
					
				when command_seq => 

					rw_ctrl_int <= '0';
					busy <= '1';
					if(bit_cnt = 0)then
						sda_int <= '1';
						bit_cnt <= 7 ;
						state <= slave_ack2;
						rw_ctrl_int <= '1';
					else
						bit_cnt <= bit_cnt - 1 ;
						sda_int <= command_byte_r(bit_cnt);
						state <= command_seq ;
					end if;

				when slave_ack2 =>

					rw_ctrl_int <= '0';
					busy <= '1';
					if(addr_rw(0) = '0')then
						if(rw = '1')then
							state <= start_con; -- in reading mode we have to send repeated start
						else
							state <= wr;
							sda_int <= data_tx(bit_cnt);
						end if;
					else
						sda_int <= '1'; --in reading condition sda should be high impedance at first
						rw_ctrl_int <= '1';
						state <= rd ;
					end if ;

				when wr =>

					rw_ctrl_int <= '0';
					busy <= '1';
					if(bit_cnt = 0)then
					 	rw_ctrl_int <= '1';
						bit_cnt <= 7 ;
						state <= slave_ack3 ;
					else
						bit_cnt <= bit_cnt - 1;
						sda_int <= data_tx(bit_cnt);
						state <= wr ;
					end if;

				when slave_ack3 => 
					rw_ctrl_int <= '0';
					if(enable = '1')then
						busy <= '1';
						addr_rw <= addres & rw ;
						command_byte_r <= command_byte ;
						data_tx <= data_wr ;
						if(addr_rw = addres & rw and command_byte_r = command_byte)then
						   sda_int <= data_wr(bit_cnt) ;
						   state <= wr ;
						else 
							state <= start_con ;
						end if;
					else
						state <= stop_con;
					end if;
					
				when rd => 

					read_mode_int <= '1';
					busy <= '1';
					rw_ctrl_int <= '1'; -- only reading in this state
					if(bit_cnt = 0)then
						bit_cnt <= 7 ;
						sda_int <= '0'; 
						data_rd <= data_rx;
						state <= mstr_ack ;
						rw_ctrl_int <= '0'; -- so master can send acknowledge
						if(enable = '1' and addr_rw = addres & rw)then
							sda_int <= '0'; -- meaning that acknowledge in sent to the slave and we want to send another byte to
						else
							sda_int <= '1';
						end if;
					else
						bit_cnt <= bit_cnt - 1;
						state <= rd;
					end if;

				when mstr_ack => 

					sda_int <= '0'; -- sending acknowledge to slave 
					if(enable = '1')then
						busy <= '0';
						addr_rw <= addres & rw ;
						data_tx <= data_wr ;
						if(addr_rw = addres & rw)then
							sda_int <= '0';
							state <= rd ;
						else
							state <= start_con;
							read_mode_int <= '0';
						end if;
					else
						state <= stop_con;
					end if;

				when stop_con =>
					busy <= '0';
					state <= ready;

			end case ;
		-- reading cycle
		elsif(data_clk = '0' and data_clk_prev = '1')then

			if(rd_cnt /= 7)then
				rd_cnt <= rd_cnt + 1;
			else
				rd_cnt <= 0;
			end if;
			
			case state is
			
				when start_con =>
					if(scl_en = '0')then
					   scl_en <= '1';
					   ack_error <= '0';
					else 
						null;
					end if;
				when slave_ack1 =>
					if(sda /='0')then
						ack_error <= '1';
					end if ; 
				when slave_ack2 =>
					if(sda /='0')then
						ack_error <= '1';
					end if ; 
				when rd =>

					data_rx(bit_cnt) <= sda ;

				when slave_ack3 =>
					if(sda /='0')then
						ack_error <= '1';
					end if ;

				when stop_con =>
					scl_en <= '0';
					state <= ready ;

				when others => 

					null;

			end case;
		end if ;
	end if;
end process ;
-----
read_mode <= read_mode_int ;
rw_ctrl <= rw_ctrl_int;
tx <= sda_int when rw_ctrl_int = '0' else 'Z';
-----
with state select
	sda_enable <= data_clk_prev 	when start_con,
			 	  not data_clk_prev  when stop_con,
			 	  tx	when others ;
-----			 	 
	scl <= '0' when (scl_en = '1' and scl_clk = '0') else 'Z';
	sda <= '0' when sda_enable = '0' else 'Z';
end Behavioral ;
