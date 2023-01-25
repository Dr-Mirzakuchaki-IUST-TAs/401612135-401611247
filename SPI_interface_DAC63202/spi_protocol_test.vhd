--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:43:52 12/28/2022
-- Design Name:   
-- Module Name:   E:/uni_master/course 1/VHDL/main project/SPI_interface_DAC63202/spi_protocol_test.vhd
-- Project Name:  SPI_interface_DAC63202
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: spi_protocol
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY spi_protocol_test IS
END spi_protocol_test;
 
ARCHITECTURE behavior OF spi_protocol_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spi_protocol
    PORT(
         clk_sys : IN  std_logic;
         serial_data_in : IN  std_logic_vector(23 downto 0);
         start_bit : IN  std_logic;
         Miso_line : IN  std_logic;
         Mosi_line : OUT  std_logic;
         sync_n : OUT  std_logic;
         cs_n : OUT  std_logic;
         sclk : OUT  std_logic;
         sdo_en : INOUT  std_logic;
         read_back_data_out : OUT  std_logic_vector(15 downto 0);
         error_sig : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_sys : std_logic := '0';
   signal serial_data_in : std_logic_vector(23 downto 0) := (others => '0');
   signal start_bit : std_logic := '0';
   signal Miso_line : std_logic := '0';
   signal sdo_en : std_logic := '0';

 	--Outputs
   signal Mosi_line : std_logic;
   signal sync_n : std_logic;
   signal cs_n : std_logic;
   signal sclk : std_logic;
   signal read_back_data_out : std_logic_vector(15 downto 0);
   signal error_sig : std_logic;

   -- Clock period definitions
   constant clk_sys_period : time := 10 ns;
   constant sclk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: spi_protocol PORT MAP (
          clk_sys => clk_sys,
          serial_data_in => serial_data_in,
          start_bit => start_bit,
          Miso_line => Miso_line,
          Mosi_line => Mosi_line,
          sync_n => sync_n,
          cs_n => cs_n,
          sclk => sclk,
          sdo_en => sdo_en,
          read_back_data_out => read_back_data_out,
          error_sig => error_sig
        );

    clk_sys <= not clk_sys after 20 ns;
    serial_data_in <= "000110011001101001100110" after 80 ns , (others => '0') after 200 ns ;
    start_bit <= '1' after 120 ns , '0' after 150 ns ;
    --sdo_en <= '1' after 50 ns;
   -- Miso_line <= '1'after 50 ns , '0' after 1500 ns , '1' after 1550 ns , '0' after 1600 ns , '1' after 1650 ns , '0' after 1700 ns, '1' after 1800 ns , '0' after 1900 ns ;

END;
