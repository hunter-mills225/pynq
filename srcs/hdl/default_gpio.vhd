---------------------------------------------------------------------------------------------------------------------------------
--  File           : default_gpio.vhd
--  Author         : Hunter Mills
---------------------------------------------------------------------------------------------------------------------------------
--  Description:
--    Default GPIO for PYNQ-Z2 LEDs and Pushbuttons.
--
---------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real."ceil";
use IEEE.math_real."log2";
use ieee.numeric_std.all;

entity default_gpio is
port(
  clk : in std_logic;
  resetn : in std_logic;
  pb : in std_logic_vector(1 downto 0);
  leds : out std_logic_vector(3 downto 0);
  tri_color_leds : out std_logic_vector(5 downto 0)
);
end default_gpio;

architecture behv of default_gpio is
  -- Components
  COMPONENT counter
  GENERIC (
      g_max : integer := 32
  );
  PORT (
    clk    : IN  std_logic;
    resetn : IN  std_logic;
    enable : IN  std_logic;
    count  : OUT std_logic_vector(integer(ceil(log2(real(g_max))))-1 downto 0)
  );
  END COMPONENT counter;

  COMPONENT pwm
  GENERIC (
    pwm_bits : integer := 8
  );
  PORT (
    clk        : IN  std_logic;
    resetn     : IN  std_logic;
    duty_cycle : IN  unsigned(pwm_bits - 1 downto 0);
    pwm_out    : OUT std_logic
  );
  END COMPONENT pwm;


  signal led_p1_count : std_logic_vector(integer(ceil(log2(real(125000000/2))))-1 downto 0);
  signal led_p2_count : std_logic_vector(integer(ceil(log2(real(125000000))))-1 downto 0);
  signal leds_s : std_logic_vector(1 downto 0);
  signal pwm_driver : std_logic;

begin

  -- Counter for LED with period of 1s
  led_p1_inst : counter
  GENERIC MAP (
    g_max => 125000000/2
  )
  PORT MAP (
    clk    => clk,
    resetn => resetn,
    enable => '1',
    count  => led_p1_count
  );

  -- Counter for LED with period of 2s
  led_p2_inst : counter
  GENERIC MAP (
    g_max => 125000000
  )
  PORT MAP (
    clk    => clk,
    resetn => resetn,
    enable => '1',
    count  => led_p2_count
  );

  -- Drive leds from counters
  drive_leds_proc : process is
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        leds_s(1) <= '0';
      elsif unsigned(led_p1_count) = 0 then
        leds_s(1) <= not(leds_s(1));
      end if;
      if resetn = '0' then
        leds_s(2) <= '0';
      elsif unsigned(led_p2_count) = 0 then
        leds_s(2) <= not(leds_s(2));
      end if;
    end if;
  end process drive_leds_proc;

  -- PWM Driver for multi-colored LEDS
  i_pwm : pwm
  GENERIC MAP (
      pwm_bits => 8
  )
  PORT MAP (
    clk        => clk,
    resetn     => resetn,
    duty_cycle => x"7F",
    pwm_out    => pwm_driver
  );
 
  -- Combinational Logic
  leds(1 downto 0) <= pb;
  leds(3 downto 2) <= leds_s;
  tri_color_leds(1 downto 0) <= "00";
  tri_color_leds(2) <= pwm_driver;
  tri_color_leds(2 downto 1) <= "00";
  tri_color_leds(0) <= pwm_driver;
end behv;