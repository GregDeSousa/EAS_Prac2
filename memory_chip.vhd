library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_chip is
	port(
		row: 			in  std_logic_vector(2 downto 0);
		col: 			in  std_logic_vector(2 downto 0);
		bit_in:  	in  std_logic;
		bit_out:    out std_logic;
		wr_en:		in  std_logic
	);
end entity;

architecture cell_rw of memory_chip is
	 type mem_array is array (0 to 7) of std_logic_vector(7 downto 0);
	 signal storage: mem_array;
	 begin
	process(wr_en, row, col, bit_in)
		 begin
			  if wr_en = '1' then
					storage(to_integer(unsigned(row)))(to_integer(unsigned(col))) <= bit_in;
			  end if;
		 end process;

		bit_out <= storage(to_integer(unsigned(row)))(to_integer(unsigned(col)));
end architecture;
		
	