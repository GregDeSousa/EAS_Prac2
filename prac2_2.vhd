library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity prac2_2 is
    port( CLK_MAIN: in std_logic;
          CLR_MAIN: in std_logic;	-- not using this at the moment
          RX_MAIN: in std_logic;		-- indicates when rx should start 
          TX_MAIN: out std_logic;	-- indicates start or stop for tx
          SW_MAIN: in std_logic_vector(1 downto 0);
			 LEDS: out std_logic_vector(7 downto 0) -- for debugging purposes
			 ); 
end prac2_2;

architecture rtl of prac2_2 is 
	
	----- Reused from prac 1 -----
	component baud_gen is
		port( CLK    : in std_logic;
				baud_CLK : out std_logic);
	end component;

	component Tx_system
		port( CLR,B_CLK,SYS_CLK: in std_logic;
				SW       : in std_logic_vector(1 downto 0);
				TX_IN    : in std_logic_vector(7 downto 0);
				START_TX : in std_logic;
				TX_DONE  : out std_logic;
				TX       : out std_logic);
	end component;

	component prac1_rx
		port (
			clk : in std_logic;
			s_tick : in std_logic;
			rx_in : in std_logic;
			rx_final : out std_logic_vector(7 downto 0);    
			rx_done : out std_logic;    
			reset : in std_logic
			);
	end component;
	----- Resused from prac 1 -----
	
	component ram_256_byte is
		port (
				clk          : in  std_logic;
				address      : in  std_logic_vector(7 downto 0);
				data_in      : in  std_logic_vector(7 downto 0);
				high_nib_wr  : in  std_logic;
				high_nib_rd  : in  std_logic;
				low_nib_rd   : in  std_logic;
				low_nib_wr   : in  std_logic;
				full_word_wr : in  std_logic;
				data_out     : out std_logic_vector(7 downto 0)
				);
	end component;

	signal BAUD_TICK  : std_logic;
	signal RX_OUT     : std_logic_vector(7 downto 0);
	signal RX_DONE    : std_logic;
	signal TX_DONE    : std_logic;
	signal TX_IN      : std_logic_vector(7 downto 0);
	signal START_TX   : std_logic;
	signal RESET_SIGNAL : std_logic;
    
	-- RAM signals
	signal ram_addr     : std_logic_vector(7 downto 0) := (others => '0');
	signal ram_din      : std_logic_vector(7 downto 0) := (others => '0');
	signal ram_dout     : std_logic_vector(7 downto 0);
	signal full_word_wr : std_logic := '0';
	signal low_nib_wr   : std_logic := '0';
	signal high_nib_wr  : std_logic := '0';
	signal low_nib_rd   : std_logic := '0';
	signal high_nib_rd  : std_logic := '0';

	-- State Machine
	type state_type is (IDLE, WAIT_ADDRESS, WAIT_DATA, DECODE, TX_START, HOLD_TX); -- new state machine
	signal state : state_type := IDLE; -- initial state
	signal opcode : std_logic_vector(7 downto 0) := (others => '0'); -- opcode comes from pc app
	signal rx_done_prev : std_logic := '0'; -- rising edge detector (RX_DONE is held high for multiple clock cycles due to baud rate)

	begin    
		RESET_SIGNAL <= '0';
    
		high_nib_rd <= '1' when opcode = x"03" else '0'; -- toggle high nibble read if op code is 0x03
		low_nib_rd  <= '1' when opcode = x"02" else '0'; -- toggle low nibble read if op code is 0x02
		
		----- Reused from prac 1 -----
		BAUD_UNIT: baud_gen port map (
			CLK      => CLK_MAIN,
			baud_CLK => BAUD_TICK           
		);    
    
		RX_UNIT: prac1_rx port map( 
			clk      => CLK_MAIN,
			s_tick   => BAUD_TICK,
			rx_in    => RX_MAIN,
			rx_final => RX_OUT,
			rx_done  => RX_DONE,
			reset    => '0'
		);
         
		TX_UNIT: Tx_system port map(
			CLR      => '0',
			B_CLK    => BAUD_TICK,
			SYS_CLK  => CLK_MAIN,
			SW       => SW_MAIN,
			TX_IN    => TX_IN,
			START_TX => START_TX,
			TX_DONE  => TX_DONE,
			TX       => TX_MAIN
		);
		----- Reused from prac 1 -----

		RAM_UNIT: ram_256_byte port map(
			clk          => CLK_MAIN,
			address      => ram_addr,
			data_in      => ram_din,
			high_nib_wr  => high_nib_wr,
			high_nib_rd  => high_nib_rd,
			low_nib_rd   => low_nib_rd,
			low_nib_wr   => low_nib_wr,
			full_word_wr => full_word_wr,
			data_out     => ram_dout
		);

		--- RAM controller state machine ---
		process(CLK_MAIN)
		begin
			if rising_edge(CLK_MAIN) then
				rx_done_prev <= RX_DONE;
            
				-- Defaults values
				full_word_wr <= '0';
				low_nib_wr   <= '0';
				high_nib_wr  <= '0';
				
				if RESET_SIGNAL = '1' then
					--- !!!!! Not using this anymore
					state <= IDLE;
					START_TX <= '0';
				else
					-- State machine logic starts here
					case state is
						when IDLE =>
							-- Wait for a command/opcode from pc app
							START_TX <= '0'; -- make sure tx does not start from a random starting value
							if RX_DONE = '1' and rx_done_prev = '0' then -- read opcode
								opcode <= RX_OUT;
								state <= WAIT_ADDRESS;
							end if;
									
						when WAIT_ADDRESS =>
							if RX_DONE = '1' and rx_done_prev = '0' then
								ram_addr <= RX_OUT;
								state <= WAIT_DATA;
							end if;

							when WAIT_DATA =>
								if RX_DONE = '1' and rx_done_prev = '0' then
									ram_din <= RX_OUT;
									state <= DECODE;
								end if;

							when DECODE =>
								-- Command Decoding
								if opcode = x"04" then
									full_word_wr <= '1';
									state <= IDLE;
								elsif opcode = x"05" then
									low_nib_wr <= '1';
									state <= IDLE;
								elsif opcode = x"06" then
									high_nib_wr <= '1';
									state <= IDLE;
								elsif opcode = x"01" or opcode = x"02" or opcode = x"03" then
									state <= TX_START;
								else
									state <= IDLE;
								end if;

							when TX_START =>
								-- Start transmission
								TX_IN <= ram_dout;
								START_TX <= '1';
								state <= HOLD_TX;

							when HOLD_TX =>
								-- Keep start signal high until tx is actually done
								-- This is needed because baud clock is slower than actual clock in ram controller
								if TX_DONE = '1' then
									START_TX <= '0';
									state <= IDLE;
								end if;
					end case;
				end if;
        end if;
    end process;
end rtl;