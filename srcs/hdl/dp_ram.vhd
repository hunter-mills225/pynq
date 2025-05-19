---------------------------------------------------------------------------------------------------------------------------------
--  File           : dp_ram.vhd
--  Author         : Hunter Mills
---------------------------------------------------------------------------------------------------------------------------------
--  Description:
--    Simple Dual Port BRAM.
--
---------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real."ceil";
use IEEE.math_real."log2";

entity dp_ram is
generic (
  g_width : integer := 32;
  g_depth : integer := 128
);
port(
  clk : in std_logic;
  resetn : in std_logic;
  wr_en : in std_logic;
  rd_en : in std_logic;
  wr_addr : in std_logic_vector(integer(ceil(log2(real(g_depth))))-1 downto 0);
  rd_addr : in std_logic_vector(integer(ceil(log2(real(g_depth))))-1 downto 0);
  wr_data : in std_logic_vector(g_width-1 downto 0);
  rd_data : out std_logic_vector(g_width-1 downto 0);
  rd_valid : out std_logic
);
end dp_ram;

architecture behv of dp_ram is
  -- BRAM Signals
  type ram_type is array (0 to g_depth-1) of std_logic_vector(g_width-1 downto 0);
  signal RAM : ram_type;

begin

  -- Write Process
  wr_proc : process(clk) is
  begin
    if (rising_edge(clk)) then
      if wr_en = '1' then
        RAM(conv_integer(wr_addr)) <= wr_data;
      end if;
    end if;
  end process wr_proc;

  -- Read Process
  rd_proc : process(clk) is 
  begin
    if (rising_edge(clk)) then
      if resetn = '0' then
        rd_data <= (others => '0');
        rd_valid  <= '0';
      elsif rd_en = '1' then
        rd_data <= RAM(conv_integer(rd_addr));
        rd_valid  <= '1';
      else
        rd_valid <= '0';
      end if;
    end if;
  end process rd_proc;

end behv;
