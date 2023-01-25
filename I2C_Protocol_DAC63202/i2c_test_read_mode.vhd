
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 

ENTITY i2c_test_read_mode IS
END i2c_test_read_mode;
 
ARCHITECTURE behavior OF i2c_test_read_mode IS 
 
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
         read_mode : out std_logic;
         data_rd : OUT  std_logic_vector(7 downto 0);
         rd_cnt : buffer integer range 0 to 7 
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
   signal read_mode : std_logic;
   signal data_rd : std_logic_vector(7 downto 0);

   -- Buffer
   signal rd_cnt : integer range 0 to 7 ;

   constant read_back : std_logic_vector(7 downto 0) := "01110111";


 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: I2C_Protocol PORT MAP (
          clk => clk,
          reset_n => reset_n,
          enable => enable,
          busy => busy,
          rd_cnt => rd_cnt,
          ack_error => ack_error,
          sda => sda,
          scl => scl,
          rw => rw,
          rw_ctrl => rw_ctrl,
          read_mode =>  read_mode ,
          command_byte => command_byte,
          data_wr => data_wr,
          data_rd => data_rd
        );


        clk <= not clk after 20 ns;
        rw <= '1' after 485 us  ;
        read_mode <= '1' after 450 us, '0' after 830 us ;
        enable <= '1' after 100 us , '0' after 830 us;
        data_wr <= "10110110" ;
        reset_n <= '1';
        command_byte <= "11100000" after 100 us;
        sda <= 'Z'              when rw_ctrl = '0' else 
               read_back(rd_cnt) when ( read_mode = '1') else '0' ;


 

   -- Stimulus process


END;
