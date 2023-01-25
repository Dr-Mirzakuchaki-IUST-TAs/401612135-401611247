
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity spi_protocol is

	port(	
			--input signals
			clk_sys 	   		: in 	std_logic 					    	:= '0'; -- 50 Mhz
			serial_data_in 		: in 	std_logic_vector(23 downto 0)  		:= (others => '0'); -- data to be transmited including addres and rw bit
			start_bit 	   		: in 	std_logic 					  		:= '0'; -- start a transmission cycle (24 bit)
			Miso_line	   		: in 	std_logic 					  		:= 'Z'; -- SDO (optional)
			sdo_en 	  	   		: inout std_logic 				  			:= '0'; -- sdo line enabling

			test_cnt 		    : buffer integer 		range 0 to 23  	    := 0 ;

			--output signals
			Mosi_line 			: out   std_logic 							:= 'Z'; --SDI
			sync_n 	  			: out   std_logic 							:= '1'; -- enabling the spi communication protocol
			cs_n 			  	: out   std_logic 							:= '1';  --selects one of the target devices (one device here)
			sclk 	  			: out   std_logic 							:= '0'; --serial clk for data transmission (CLK POL = 0)
			read_back_data_out  : out   std_logic_vector(15 downto 0)   	:= (others => '0');
			error_sig 			: out   std_logic 							:= '0'
		);

end spi_protocol;

architecture Behavioral of spi_protocol is
--internal signals:
signal start_bit_INT      : std_logic           := '0';
signal sync_n_INT         : std_logic 	 	    := '1';
signal serial_data_in_INT : std_logic_vector(23 downto 0)    := (others => '0');
signal Mosi_line_INT      : std_logic 		    := 'Z';
signal cs_n_INT           : std_logic 		    := '1';
signal sclk_start  		  : std_logic 			:= '0';
signal R_W 				  : std_logic 			:= '0';
signal read_back_data	  : std_logic_vector(23 downto 0)    := (others => 'Z');
signal read_back_data_r	  : std_logic_vector(23 downto 0)    := (others => 'Z');

--controll signal:
signal bit_cnt 			  : unsigned(4 downto 0):= "10111";
--states:
type states is (idle , delay_inst , inst , write_st , read_command , read_data , error_st , delay_cs);
signal state 			  : states              := idle ;

begin

---
cs_n <= cs_n_INT ;
sync_n <= sync_n_INT;
Mosi_line <= Mosi_line_INT ;
read_back_data_out <= read_back_data_r(15 downto 0) ;
---
with sclk_start select
	 sclk <= clk_sys after 20 ns when '1', -- delay considered because data is transmitted at the falling edge of sclk  (clk phase = 0)
	 	  	 '0'				 when others ;
---
process(clk_sys)

begin
	
	if(rising_edge(clk_sys))then
		-- this counter is for test bench only
	    if(test_cnt /= 23)then
	    	test_cnt <= test_cnt + 1;
	    else
	    	test_cnt <= 0 ;
	    end if;
	    --
		case state is 

			when idle =>
				 start_bit_INT <= start_bit ;
				 Mosi_line_INT <= 'Z';
				 bit_cnt  <= "10111";
				 sync_n_INT <= '1';
				 sdo_en <= '0';
				 cs_n_INT <= '1';
				 sclk_start <= '0';
				 R_W <= '0';

				if(start_bit_INT = '1')then
					serial_data_in_INT <= serial_data_in;
					sclk_start <= '1';
					state <= delay_inst ;
					cs_n_INT <= '0';
					sync_n_INT <= '0';
				else
					state <= idle ;
					cs_n_INT <= '1';
					sync_n_INT <= '1';
				end if;
			when delay_inst =>

				state <= inst ;
				cs_n_INT <= '0';
				sync_n_INT <= '0';
				Mosi_line_INT <= serial_data_in_INT(to_integer(bit_cnt)); -- MSB bit of serial data input is passed to mosi line (R/W)
				bit_cnt <= bit_cnt - 1;
				R_W <= serial_data_in_INT(to_integer(bit_cnt)) ; --register the R/W bit
				
			when inst =>

				cs_n_INT <= '0';
				sync_n_INT <= '0';
				Mosi_line_INT <= serial_data_in_INT(to_integer(bit_cnt));
				if(bit_cnt /= "10000")then

					state <= inst ;
					bit_cnt <= bit_cnt - 1 ;
				else
					if(R_W = '0')then
						state <= write_st ;
					else
						state <= read_command ;						
					end if ;
				end if;

			when write_st =>
			
				cs_n_INT <= '0';
				sync_n_INT <= '0';
				Mosi_line_INT <= serial_data_in_INT(to_integer(bit_cnt));
				if(bit_cnt /= "00000")then
					bit_cnt <= bit_cnt -1;
					state <= write_st;
				else
					bit_cnt <= "10111";
					state <= delay_cs ;
				end if;

			when read_command =>

				cs_n_INT <= '0';
				sync_n_INT <= '0';
				if(sdo_en = '0')then
					Mosi_line_INT <= serial_data_in_INT(to_integer(bit_cnt));
					if(bit_cnt /= "00000")then
						bit_cnt <= bit_cnt -1;
						state <= read_command ;
					else
						bit_cnt <= "10111";
						state <= read_data ;
						sdo_en <= '1';
					end if ;
				else
					state <= error_st;
				end if;

			when read_data =>
				sdo_en <= '1';
				Mosi_line_INT <= 'Z';
				if(bit_cnt /= "00000")then
					read_back_data(to_integer(bit_cnt)) <= Miso_line;
					bit_cnt <= bit_cnt - 1;
					state <= read_data ;
				else
					read_back_data_r <= read_back_data ;
					read_back_data <= (others => 'Z');
					bit_cnt <= "10111";
					sdo_en <= '0';
					state <= delay_cs ;
				end if;

			when error_st =>

				cs_n_INT <= '1';
				sync_n_INT <= '1';
				read_back_data <= (others =>'Z');
				state <= idle;
				error_sig <= '1';

			when delay_cs =>

				cs_n_INT <= '0';
				state <= idle ;
				Mosi_line_INT <= 'Z';
				bit_cnt <= "10111";
				sync_n_INT <= '0';

		end case;
	end if;
end process;

end Behavioral;

