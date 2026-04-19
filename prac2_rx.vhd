--library IEEE;
--use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;
--use IEEE.math_real.all;
--
--entity prac1_rx is
--	port (
--		clk : in std_logic;
--		s_tick : in std_logic;
--		rx_in : in std_logic;
--		rx_final : out std_logic_vector(7 downto 0);	-- received data byte
--		rx_done : out std_logic;	-- flag to indicate when system is done receiving data
--		reset : in std_logic
--	);
--end prac1_rx;
--
--architecture prac1_rx_arch of prac1_rx is
--	-- State definitions
--	type state_type is (idle, start, receiving, stop);
--	signal NS, PS : state_type;
--	
--	-- Working variables
--	signal data_bits : std_logic_vector(7 downto 0);
--	signal data_bits_next : std_logic_vector(7 downto 0);
--	
--	-- Counters
--	signal tick_count : unsigned(3 downto 0); -- prevents program from crashing if vector counter rolls over for some reason
--	signal tick_count_next : unsigned(3 downto 0);
--	signal bit_count : unsigned(2 downto 0);
--	signal bit_count_next : unsigned(2 downto 0);
--begin	
--
--	sync_process : process(clk, NS, reset)
--	begin
--		if (reset = '1') then 
--			PS <= idle;
--			tick_count <= (others => '0');
--			bit_count <= (others => '0');
--			data_bits <= (others => '0');
--		elsif rising_edge(clk) then 
--			PS <= NS;
--			tick_count <= tick_count_next;
--			bit_count <= bit_count_next;
--			data_bits <= data_bits_next;
--		end if;
--	end process;
--	
--	comb_proc : process(PS, s_tick, tick_count, bit_count, data_bits, rx_in)
--	begin
--		-- Default assignments to prevent latches
--		NS <= PS;
--		bit_count_next <= bit_count;
--		tick_count_next <= tick_count;
--		data_bits_next <= data_bits;
--		rx_done <= '0';
--		
--		-- State logic
--		case PS is
--			when idle =>
--				if (rx_in = '0') then 
--					NS <= start;
--					tick_count_next <= (others => '0');
--					bit_count_next <= (others => '0');
--					data_bits_next <= (others => '0');
--				end if;
--			when start =>
--				if (s_tick = '1') then
--						  if (tick_count = 7) then
--								tick_count_next <= (others => '0');
--								NS <= receiving;
--						  else
--								tick_count_next <= tick_count + 1;
--						  end if;
--					 end if;
--			when receiving =>
--				if (s_tick = '1') then
--					-- Check if we are sampling the middle of the data bit
--					if (tick_count = 15) then
--						tick_count_next <= (others => '0');
--						data_bits_next <= rx_in & data_bits(7 downto 1);
--						
--						-- Check if how many bits we have received
--						if (bit_count = 7) then
--							NS <= stop;
--						else
--							bit_count_next <= bit_count + 1;
--						end if;
--					else
--						tick_count_next <= tick_count + 1;
--					end if;
--				end if;
--			when stop =>
--			if (s_tick = '1') then 
--        if (tick_count = 15) then
--            rx_done <= '1'; 
--            NS <= idle;
--        else
--            tick_count_next <= tick_count + 1;
--        end if;
--    end if;
--	 	end case;
--	end process;
--
--	rx_final <= data_bits;
--	
--end prac1_rx_arch;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity prac1_rx is
	port (
		clk : in std_logic;
		s_tick : in std_logic;
		rx_in : in std_logic;
		rx_final : out std_logic_vector(7 downto 0);	-- received data byte
		rx_done : out std_logic;	-- flag to indicate when system is done receiving data
		reset : in std_logic
	);
end prac1_rx;

architecture prac1_rx_arch of prac1_rx is
	-- State definitions
	type state_type is (idle, start, receiving, stop);
	signal NS, PS : state_type;
	
	-- Working variables
	signal data_bits : std_logic_vector(7 downto 0);
	
	-- Counters
	signal tick_count : unsigned(3 downto 0) := (others => '0'); -- prevents program from crashing if vector counter rolls over for some reason
	signal bit_count : unsigned(2 downto 0) := (others => '0');
begin	

	sync_process : process(clk, reset)
	begin
		if (reset = '1') then 
			PS <= idle;
			tick_count <= (others => '0');
			bit_count <= (others => '0');
			data_bits <= (others => '0');
		elsif rising_edge(clk) then 
			rx_done <= '0';
			if (s_tick = '1') then
				PS <= NS;
				case PS is
					when idle =>
						if (rx_in = '0') then
							tick_count <= (others => '0');
						end if;
						
					when start =>
						if (tick_count = 7) then
							tick_count <= (others => '0');
							bit_count <= (others => '0');
						else
							tick_count <= tick_count + 1;
						end if;
						
					when receiving =>
						if (tick_count = 15) then
							tick_count <= (others => '0');
							data_bits <= rx_in & data_bits(7 downto 1);
							
							if (bit_count /= 7) then
								bit_count <= bit_count + 1;
							end if;
						else
							tick_count <= tick_count + 1;
						end if;
						
					when stop =>
						if (tick_count = 15) then
							rx_done <= '1';
							tick_count <= (others => '0');
						else
							tick_count <= tick_count + 1;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	comb_proc : process(PS, tick_count, bit_count, rx_in)
	begin
		-- Next state logic
		case PS is
			when idle =>
				if (rx_in = '0') then 
					NS <= start;
				else
					NS <= idle;
				end if;
				
			when start =>
				if (tick_count = 7) then
					NS <= receiving;
				else
					NS <= start;
				end if;
					 
			when receiving =>
				if (tick_count = 15) then
					if (bit_count = 7) then
						NS <= stop;
					else
						NS <= receiving;
					end if;
				else
					NS <= receiving;
				end if;
					
			when stop =>
				if (tick_count = 15) then
					NS <= idle;
				else
					NS <= stop;
				end if;
	 	end case;
	end process;

	rx_final <= data_bits;
	
end prac1_rx_arch;