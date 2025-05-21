---------------------------------------------------------------------------------------------------------------------------------
--  File           : pwm.vhd
--  Author         : Hunter Mills
---------------------------------------------------------------------------------------------------------------------------------
--  Description:
--    Create a PWM signal at a specified duty cycle.
--
---------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm is
  generic (
    pwm_bits : integer := 8
  );
  port (
    clk : in std_logic;
    resetn : in std_logic;
    duty_cycle : in unsigned(pwm_bits - 1 downto 0); -- All ones is 100%, all zeros is 0%
    pwm_out : out std_logic
  );
end pwm;

architecture behv of pwm is

  -- Counters
  signal pwm_cnt : unsigned(pwm_bits - 1 downto 0);

begin

  pwm_proc : process(clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        pwm_cnt <= (others => '0');
        pwm_out <= '0';
      else
          pwm_cnt <= pwm_cnt + 1;
    
          if pwm_cnt = unsigned(to_signed(-2, pwm_cnt'length)) then
            pwm_cnt <= (others => '0');
          end if;
    
          if pwm_cnt < duty_cycle then
            pwm_out <= '1';
          else 
            pwm_out <= '0';
          end if;
    
      end if;
    end if;
  end process pwm_proc;

end behv;