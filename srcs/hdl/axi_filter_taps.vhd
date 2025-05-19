---------------------------------------------------------------------------------------------------------------------------------
--  File           : axi_filter_taps.vhd
--  Author         : Hunter Mills
---------------------------------------------------------------------------------------------------------------------------------
--  Description:
--    AXI4LITE interface for configurable taps used for an FIR filter.
--  Memory Map:
--    REG0  : TAP_ADDR, address of RAM to write the tap to.
--    REG1  : TAP_DATA, filter tap value.
--    REG2  : WRITE_TAPS, register to write the taps from RAM into an FIR filter.
--    REG3  : CONST_DEBUG, RO registers that holds 0xCAFE0123 to ensure interface works correctly.
--
---------------------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use IEEE.math_real."ceil";
use IEEE.math_real."log2";

entity axi_filter_taps is
  generic (
    -- Width of S_AXI data bus
    c_s_axi_data_width : integer := 32;
    -- Width of S_AXI address bus
    c_s_axi_addr_width : integer := 4;
    -- Size of ram to create
    g_ntaps : integer := 128
  );
  port (
    -- AXI Signals
    s_axi_aclk    : in    std_logic;
    s_axi_aresetn : in    std_logic;

    s_axi_awaddr  : in    std_logic_vector(c_s_axi_addr_width - 1 downto 0);
    s_axi_awprot  : in    std_logic_vector(2 downto 0);
    s_axi_awvalid : in    std_logic;
    s_axi_awready : out   std_logic;

    s_axi_wdata  : in    std_logic_vector(c_s_axi_data_width - 1 downto 0);
    s_axi_wstrb  : in    std_logic_vector((c_s_axi_data_width / 8) - 1 downto 0);
    s_axi_wvalid : in    std_logic;
    s_axi_wready : out   std_logic;

    s_axi_bresp  : out   std_logic_vector(1 downto 0);
    s_axi_bvalid : out   std_logic;
    s_axi_bready : in    std_logic;

    s_axi_araddr  : in    std_logic_vector(c_s_axi_addr_width - 1 downto 0);
    s_axi_arprot  : in    std_logic_vector(2 downto 0);
    s_axi_arvalid : in    std_logic;
    s_axi_arready : out   std_logic;

    s_axi_rdata  : out   std_logic_vector(c_s_axi_data_width - 1 downto 0);
    s_axi_rresp  : out   std_logic_vector(1 downto 0);
    s_axi_rvalid : out   std_logic;
    s_axi_rready : in    std_logic;

    -- BRAM Read Interface
    ram_rd_en : in std_logic;
    ram_rd_addr : in std_logic_vector(integer(ceil(log2(real(g_ntaps))))-1 downto 0);
    ram_rd_valid  : out std_logic;
    ram_rd_data : out std_logic_vector(c_s_axi_data_width-1 downto 0)
  );
end entity axi_filter_taps;

architecture arch_imp of axi_filter_taps is

  -- AXI4 signals
  signal axi_awaddr  : std_logic_vector(c_s_axi_addr_width - 1 downto 0);
  signal axi_awready : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(c_s_axi_addr_width - 1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  -- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  constant addr_lsb          : integer := (c_s_axi_data_width / 32) + 1;
  constant opt_mem_addr_bits : integer := 1;
  signal mem_logic : std_logic_vector(addr_lsb + opt_mem_addr_bits downto addr_lsb);

  -- Signals for user logic register space
  signal slv_reg0 : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg1 : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg2 : std_logic_vector(c_s_axi_data_width - 1 downto 0);
  signal slv_reg3 : std_logic_vector(c_s_axi_data_width - 1 downto 0);

  -- State machine local parameters
  constant idle  : std_logic_vector(1 downto 0) := "00";
  constant raddr : std_logic_vector(1 downto 0) := "10";
  constant rdata : std_logic_vector(1 downto 0) := "11";
  constant waddr : std_logic_vector(1 downto 0) := "10";
  constant wdata : std_logic_vector(1 downto 0) := "11";

  -- State machine variables
  signal state_read  : std_logic_vector(1 downto 0);
  signal state_write : std_logic_vector(1 downto 0);

  -- RAM Signals
  signal ram_wr_en : std_logic;

  -- Dual Port Ram Component
  COMPONENT dp_ram
  GENERIC (
    g_width : integer := c_s_axi_data_width;
    g_depth : integer := g_ntaps
  );
  PORT (
    clk      : IN  std_logic;
    resetn   : IN  std_logic;
    wr_en    : IN  std_logic;
    rd_en    : IN  std_logic;
    wr_addr  : IN  std_logic_vector(integer(ceil(log2(real(g_ntaps))))-1 downto 0);
    rd_addr  : IN  std_logic_vector(integer(ceil(log2(real(g_ntaps))))-1 downto 0);
    wr_data  : IN  std_logic_vector(g_width-1 downto 0);
    rd_data  : OUT std_logic_vector(g_width-1 downto 0);
    rd_valid : OUT std_logic
  );
  END COMPONENT dp_ram;

begin

  -- DP RAM Instantiation
  i_dp_ram : dp_ram
  GENERIC MAP (
    g_width => c_s_axi_data_width,
    g_depth => g_ntaps
  )
  PORT MAP (
    clk      => s_axi_aclk,
    resetn   => s_axi_aresetn,
    wr_en    => ram_wr_en,
    rd_en    => ram_rd_en,
    wr_addr  => slv_reg0,
    rd_addr  => ram_rd_addr,
    wr_data  => slv_reg1,
    rd_data  => ram_rd_data,
    rd_valid => ram_rd_valid
  );

  -- I/O Connections assignments
  s_axi_awready <= axi_awready;
  s_axi_wready  <= axi_wready;
  s_axi_bresp   <= axi_bresp;
  s_axi_bvalid  <= axi_bvalid;
  s_axi_arready <= axi_arready;
  s_axi_rresp   <= axi_rresp;
  s_axi_rvalid  <= axi_rvalid;
  mem_logic     <= s_axi_awaddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) when (s_axi_awvalid = '1') else
                   axi_awaddr(addr_lsb + opt_mem_addr_bits downto addr_lsb);
  slv_reg3      <= x"CAFE0123";

  -- Implement Write state machine
  -- Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
  process (s_axi_aclk) is
  begin

    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        -- asserting initial values to all 0's during reset
        axi_awready <= '0';
        axi_wready  <= '0';
        axi_bvalid  <= '0';
        axi_bresp   <= (others => '0');
        state_write <= idle;
      else

        case (state_write) is

          when idle =>                                            -- Initial state inidicating reset is done and ready to receive read/write transactions

            if (s_axi_aresetn = '1') then
              axi_awready <= '1';
              axi_wready  <= '1';
              state_write <= waddr;
            else
              state_write <= state_write;
            end if;

          when waddr =>                                           -- At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state

            if (s_axi_awvalid = '1' and axi_awready = '1') then
              axi_awaddr <= s_axi_awaddr;
              if (s_axi_wvalid = '1') then
                axi_awready <= '1';
                state_write <= waddr;
                axi_bvalid  <= '1';
              else
                axi_awready <= '0';
                state_write <= wdata;
                if (s_axi_bready = '1' and axi_bvalid = '1') then
                  axi_bvalid <= '0';
                end if;
              end if;
            else
              state_write <= state_write;
              if (s_axi_bready = '1' and axi_bvalid = '1') then
                axi_bvalid <= '0';
              end if;
            end if;

          when wdata =>                                           -- At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length

            if (s_axi_wvalid = '1') then
              state_write <= waddr;
              axi_bvalid  <= '1';
              axi_awready <= '1';
            else
              state_write <= state_write;
              if (s_axi_bready = '1' and axi_bvalid = '1') then
                axi_bvalid <= '0';
              end if;
            end if;

          when others =>                                          -- reserved

            axi_awready <= '0';
            axi_wready  <= '0';
            axi_bvalid  <= '0';

        end case;

      end if;
    end if;

  end process;

  -- Implement memory mapped register select and write logic generation.
  write_proc : process (s_axi_aclk) is
  begin

    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        slv_reg0 <= (others => '0');
        ram_wr_en <= '0';
      else
        if (s_axi_wvalid = '1') then

          case (mem_logic) is

            when b"00" =>

              slv_reg0 <= s_axi_wdata;
              ram_wr_en <= '0';

            when b"01" =>
              slv_reg1  <= s_axi_wdata;
              ram_wr_en <= '1';

            when b"10" =>
              slv_reg2  <= s_axi_wdata;
              ram_wr_en <= '0';

            when others =>

              slv_reg0 <= slv_reg0;
              slv_reg1  <= slv_reg1;
              ram_wr_en <= '0';

          end case;

        end if;
      end if;
    end if;

  end process write_proc;

  -- Implement read state machine
  process (s_axi_aclk) is
  begin

    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        -- asserting initial values to all 0's during reset
        axi_arready <= '0';
        axi_rvalid  <= '0';
        axi_rresp   <= (others => '0');
        state_read  <= idle;
      else

        case (state_read) is

          when idle =>                                          -- Initial state inidicating reset is done and ready to receive read/write transactions

            if (s_axi_aresetn = '1') then
              axi_arready <= '1';
              state_read  <= raddr;
            else
              state_read <= state_read;
            end if;

          when raddr =>                                         -- At this state, slave is ready to receive address along with corresponding control signals

            if (s_axi_arvalid = '1' and axi_arready = '1') then
              state_read  <= rdata;
              axi_rvalid  <= '1';
              axi_arready <= '0';
              axi_araddr  <= s_axi_araddr;
            else
              state_read <= state_read;
            end if;

          when rdata =>                                         -- At this state, slave is ready to send the data packets until the number of transfers is equal to burst length

            if (axi_rvalid = '1' and s_axi_rready = '1') then
              axi_rvalid  <= '0';
              axi_arready <= '1';
              state_read  <= raddr;
            else
              state_read <= state_read;
            end if;

          when others =>                                        -- reserved

            axi_arready <= '0';
            axi_rvalid  <= '0';

        end case;

      end if;
    end if;

  end process;

  -- Implement memory mapped register select and read logic generation
  s_axi_rdata <= slv_reg0 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "00") else
                 slv_reg1 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "01") else
                 slv_reg2 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "10") else
                 slv_reg3 when (axi_araddr(addr_lsb + opt_mem_addr_bits downto addr_lsb) = "11") else
                 (others => '0');

end architecture arch_imp;
