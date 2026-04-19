library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_256_byte is
	port(
		clk		    : in  std_logic;
		address 	    : in  std_logic_vector(7 downto 0);
		data_in      : in  std_logic_vector(7 downto 0);
		high_nib_wr  : in  std_logic;
		high_nib_rd  : in  std_logic;
		low_nib_rd   : in  std_logic;
		low_nib_wr   : in  std_logic;
		full_word_wr : in  std_logic;
		data_out     : out std_logic_vector(7 downto 0)
	);
end entity ram_256_byte;

architecture ram_arch of ram_256_byte is
		component memory_chip is
			port(
				clk:			in  std_logic;
				row: 			in  std_logic_vector(2 downto 0);
				col: 			in  std_logic_vector(2 downto 0);
				bit_in:  	in  std_logic;
				bit_out:    out std_logic;
				wr_en:		in  std_logic
			);
		end component;

		signal row_sel : std_logic_vector (2 downto 0);
		signal col_sel : std_logic_vector (2 downto 0);
		signal bank_sel: std_logic_vector (1 downto 0);
		
		type memory_out_arr is array(0 to 3, 0 to 7) of std_logic;
		signal memory_outputs: memory_out_arr;
		
		begin
			row_sel <= address(5 downto 3);
			col_sel <= address(2 downto 0);
			bank_sel <= address(7 downto 6);
		
		 banks: for b in 0 to 3 generate
			  bits: for i in 0 to 7 generate
					signal write_en : std_logic;
					signal actual_bit_in : std_logic;
			  begin
					write_en <= '1' when (bank_sel = std_logic_vector(to_unsigned(b, 2))) and (
												  full_word_wr = '1' or
												  (low_nib_wr = '1' and i < 4) or 
												  (high_nib_wr = '1' and i > 3)
											 ) else '0';

					actual_bit_in <= data_in(i - 4) when (high_nib_wr = '1' and i > 3) else data_in(i);

					chip_inst: memory_chip
						 port map (
							  clk     => clk,
							  row     => row_sel,
							  col     => col_sel,
							  bit_in  => actual_bit_in,
							  wr_en   => write_en,  
							  bit_out => memory_outputs(b, i)
						 );
			  end generate bits; 
		 end generate banks;   
	 
	process(bank_sel, memory_outputs, high_nib_rd, low_nib_rd)
		 variable full_word : std_logic_vector(7 downto 0);
	begin
		 for i in 0 to 7 loop
			  full_word(i) := memory_outputs(to_integer(unsigned(bank_sel)), i);
		 end loop;

		 if high_nib_rd = '1' then
			  data_out <= "0000" & full_word(7 downto 4); 
		 elsif low_nib_rd = '1' then
			  data_out <= "0000" & full_word(3 downto 0);
		 else
			  data_out <= full_word; 
		 end if;
	end process;
end architecture ram_arch;
			
			
