library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity baud_gen is

    generic (
        DIVIDER : integer := 27 
    );
    port (
        CLK      : in  std_logic;
        baud_CLK : out std_logic  
    );
end baud_gen;

architecture baud_arch of baud_gen is
    signal count : integer range 0 to DIVIDER - 1 := 0;
begin
    sync_proc: process(CLK)
    begin
        if rising_edge(CLK) then
            if count >= (DIVIDER - 1) then
                count <= 0;
                baud_CLK <= '1'; 
            else
                count <= count + 1;
                baud_CLK <= '0'; 
            end if;
        end if;
    end process sync_proc;
end baud_arch;
