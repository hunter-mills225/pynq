---------------------------------------------------------------------------------------------------------------------------------
--  File           : counter.vhd
--  Author         : Hunter Mills
---------------------------------------------------------------------------------------------------------------------------------
--  Description:
--    Module to create a counter.
--
---------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real."ceil";
use IEEE.math_real."log2";
use ieee.numeric_std.all;

entity counter is
generic (
  g_max : integer := 32
);
port(
  clk : in std_logic;
  resetn : in std_logic;
  enable  : in std_logic;
  count : out std_logic_vector(integer(ceil(log2(real(g_max))))-1 downto 0)
);
end counter;

architecture behv of counter is
  -- Counter Signals
  signal count_s : unsigned(integer(ceil(log2(real(g_max))))-1 downto 0);

begin

  -- Counting process
  count_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        count_s <= (others => '0');
      elsif enable = '1' and count_s = g_max-1 then
        count_s <= (others => '0');
      elsif enable = '1' then
        count_s <= count_s + 1;
      end if;
    end if;
  end process count_proc;

  -- Combinational Logic
  count <= std_logic_vector(count_s);

end behv;