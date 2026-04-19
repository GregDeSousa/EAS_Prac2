library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Tx_system is 
    port(   CLR,SYS_CLK,B_CLK: in std_logic;
				SW       : in std_logic_vector(1 downto 0);
            TX_IN    : in std_logic_vector(7 downto 0);
            START_TX : in std_logic;
            TX_DONE  : out std_logic;
            TX       : out std_logic);
end Tx_system;



architecture Tx_arch of Tx_system is

    component baud_gen is
        port( 
            CLK      : in std_logic;
            baud_CLK : out std_logic
        );
    end component;

    type state_type is (IDLE, START, SEND_DATA, STOP);
    signal PS, NS : state_type;
    signal clk_count  : INTEGER := 0;
    signal data_count : INTEGER := 0;
    signal dataBuf    : std_logic_vector(7 downto 0);


begin

    -- SYNCHRONOUS PROCESS
    sync_proc: process(SYS_CLK, CLR)
    begin
        if (CLR = '1') then
            PS <= IDLE;
            clk_count <= 0;
            data_count <= 0;
            dataBuf <= (others => '0');
        elsif rising_edge(SYS_CLK) then
            -- Use B_CLK as a "Clock Enable"
            -- The logic inside only runs when the pulse is active
					TX_DONE <= '0'; 
            if (B_CLK = '1') then
                PS <= NS; 
                case PS is
                    when IDLE =>
                        if (START_TX = '1') then
                            clk_count <= 0;
									 dataBuf <= TX_IN;
--                            case SW is
--                                when "00" => dataBuf <= TX_IN(6 downto 0) & TX_IN(7);
--                                when "01" => dataBuf <= TX_IN(0) & TX_IN(7 downto 1);
--                                when "10" => dataBuf <= TX_IN(5 downto 0) & TX_IN(7 downto 6);
--                                when "11" => dataBuf <= TX_IN(1 downto 0) & TX_IN(7 downto 2);
--                                when others => dataBuf <= (others => '0');
--                            end case;
                        end if;
                    
                    when START =>
                        if (clk_count /= 15) then
                            clk_count <= clk_count + 1;
                        else
                            clk_count <= 0;
                            data_count <= 0;
                        end if;

                    when SEND_DATA =>
                        if (clk_count /= 15) then
                            clk_count <= clk_count + 1;
                        else
                            clk_count <= 0;
                            -- Shift data out
                            dataBuf <= '0' & dataBuf(7 downto 1);
                            if (data_count /= 7) then
                                data_count <= data_count + 1;
                            end if;
                        end if;

                    when STOP =>
                        if (clk_count /= 15) then
                            clk_count <= clk_count + 1;
                        else
									 TX_DONE <= '1';
                            clk_count <= 0;
                        end if;
                end case;
            end if;
        end if;
    end process sync_proc;
    
    -- COMBINATIONAL PROCESS
    comb_proc: process(PS, clk_count, data_count, dataBuf, START_TX)
    begin

        case PS is
            when IDLE => 
					TX <= '1';
		
                if (START_TX = '1') then
                    NS <= START;
                else
                    NS <= IDLE;
                end if;

            when START =>
                TX <= '0'; -- Start bit
                if (clk_count /= 15) then
                    NS <= START;
                else
                    NS <= SEND_DATA;
                end if;

            when SEND_DATA => 

                TX <= dataBuf(0); 
                if (clk_count /= 15) then
                    NS <= SEND_DATA;
                else
                    if (data_count /= 7) then
                        NS <= SEND_DATA;
                    else
                        NS <= STOP;
                    end if;
                end if;

            when STOP =>
                TX <= '1'; -- Stop bit
                if (clk_count /= 15) then
                    NS <= STOP; 
                else
                    NS <= IDLE;
                     
                end if;
        end case;
    end process comb_proc;
     


end Tx_arch;