--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:05:28 01/21/2023
-- Design Name:   
-- Module Name:   E:/uni_master/course 1/VHDL/main project/I2C_Protocol_DAC63202/i2c_test.vhd
-- Project Name:  I2C_Protocol_DAC63202
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: I2C_Protocol
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
 
ENTITY i2c_test IS
END i2c_test;
 
ARCHITECTURE behavior OF i2c_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT I2C_Protocol
    PORT(
         clk : IN  std_logic;
         reset_n : IN  std_logic;
         enable : IN  std_logic;
         busy : OUT  std_logic;
         ack_error : INOUT  std_logic;
         sda : INOUT  std_logic;
         scl : OUT  std_logic;
         rw : IN  std_logic;
         rw_ctrl : OUT  std_logic;
         command_byte : IN  std_logic_vector(7 downto 0);
         data_wr : IN  std_logic_vector(7 downto 0);
         data_rd : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset_n : std_logic := '0';
   signal enable : std_logic := '0';
   signal rw : std_logic := '0';
   signal command_byte : std_logic_vector(7 downto 0) := (others => '0');
   signal data_wr : std_logic_vector(7 downto 0) := (others => '0');

	--BiDirs
   signal ack_error : std_logic;
   signal sda : std_logic;

 	--Outputs
   signal busy : std_logic;
   signal scl : std_logic;
   signal rw_ctrl : std_logic;
   signal data_rd : std_logic_vector(7 downto 0);

   -- Clock period definitions
   
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: I2C_Protocol PORT MAP (
          clk => clk,
          reset_n => reset_n,
          enable => enable,
          busy => busy,
          ack_error => ack_error,
          sda => sda,
          scl => scl,
          rw => rw,
          rw_ctrl => rw_ctrl,
          command_byte => command_byte,
          data_wr => data_wr,
          data_rd => data_rd
        );
        clk <= not clk after 20 ns ;
        enable <= '1' after 100 us , '0' after 800 us;
        data_wr <= "11011001"  ;
        command_byte <= "11100000" after 100 us;
        sda <= 'Z' when rw_ctrl = '0' else '0';
        reset_n <= '1'; 
   
END;
