library ieee;
use ieee.std_logic_1164.all;

entity tb_DisplayControl is
end tb_DisplayControl;

architecture tb of tb_DisplayControl is

    component DisplayControl
        port (ALiteData         : in std_logic_vector (31 downto 0);
              WriteToggle       : in std_logic;
              ProcessStream     : in std_logic;
              BusyBit           : out std_logic;
              CS                : out std_logic;
              DCX               : out std_logic;
              WR                : out std_logic;
              RD                : out std_logic;
              IM0               : out std_logic;
              ResetDisplay      : out std_logic;
              LCD_Data          : out std_logic_vector (15 downto 0);
              S_AXIS_DIS_tvalid : in std_logic;
              S_AXIS_DIS_tready : out std_logic;
              S_AXIS_DIS_tdata  : in std_logic_vector (15 downto 0);
              S_AXIS_DIS_tlast  : in std_logic;
              S_AXIS_clk        : in std_logic;
              S_AXIS_resetn     : in std_logic);
    end component;

    signal ALiteData         : std_logic_vector (31 downto 0);
    signal WriteToggle       : std_logic;
    signal ProcessStream     : std_logic;
    signal BusyBit           : std_logic;
    signal CS                : std_logic;
    signal DCX               : std_logic;
    signal WR                : std_logic;
    signal RD                : std_logic;
    signal IM0               : std_logic;
    signal ResetDisplay      : std_logic;
    signal LCD_Data          : std_logic_vector (15 downto 0);
    signal S_AXIS_DIS_tvalid : std_logic;
    signal S_AXIS_DIS_tready : std_logic;
    signal S_AXIS_DIS_tdata  : std_logic_vector (15 downto 0);
    signal S_AXIS_DIS_tlast  : std_logic;
    signal S_AXIS_clk        : std_logic;
    signal S_AXIS_resetn     : std_logic;

    constant TbPeriod : time := 50 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : DisplayControl
    port map (ALiteData         => ALiteData,
              WriteToggle       => WriteToggle,
              ProcessStream     => ProcessStream,
              BusyBit           => BusyBit,
              CS                => CS,
              DCX               => DCX,
              WR                => WR,
              RD                => RD,
              IM0               => IM0,
              ResetDisplay      => ResetDisplay,
              LCD_Data          => LCD_Data,
              S_AXIS_DIS_tvalid => S_AXIS_DIS_tvalid,
              S_AXIS_DIS_tready => S_AXIS_DIS_tready,
              S_AXIS_DIS_tdata  => S_AXIS_DIS_tdata,
              S_AXIS_DIS_tlast  => S_AXIS_DIS_tlast,
              S_AXIS_clk        => S_AXIS_clk,
              S_AXIS_resetn     => S_AXIS_resetn);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that S_AXIS_clk is really your main clock signal
    S_AXIS_clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        ALiteData <= (others => '0');
        WriteToggle <= '0';
        ProcessStream <= '0';
        S_AXIS_DIS_tvalid <= '0';
        S_AXIS_DIS_tdata <= (others => '0');
        S_AXIS_DIS_tlast <= '0';

        -- Reset generation
        -- EDIT: Check that S_AXIS_resetn is really your reset signal
        S_AXIS_resetn <= '0';
        wait for 100 ns;
        S_AXIS_resetn <= '1';
        wait for 100 ns;
        wait for 10 ns;
        wait for TbPeriod/2;

        -- EDIT Add stimuli here
        ALiteData(31 downto 0) <= x"000000BB";
        ALiteData(8) <= '1';
        ALiteData(9) <= '1';
        WriteToggle <= not WriteToggle;
        wait for TbPeriod;

        while BusyBit = '1' loop
            wait for TbPeriod;
        end loop;
        wait for TbPeriod;

        ALiteData(31 downto 0) <= x"000000FF";
        ALiteData(8) <= '1';
        ALiteData(9) <= '0';
        WriteToggle <= not WriteToggle;
        wait for TbPeriod;
        while BusyBit = '1' loop
            wait for TbPeriod;
        end loop;
        wait for TbPeriod;
        ALiteData(31 downto 0) <= x"000000AA";
        ALiteData(8) <= '0';
        ALiteData(9) <= '1';
        WriteToggle <= not WriteToggle;
        wait for TbPeriod;

        while(BusyBit = '1') loop
            wait for TbPeriod;
        end loop;
        wait for TbPeriod;

        ProcessStream <= '1';
        wait for TbPeriod;

        S_AXIS_DIS_tdata(15 downto 0) <= x"0001";
        S_AXIS_DIS_tvalid <= '1';
        wait for TbPeriod;
        while S_AXIS_DIS_tready = '0' loop
            wait for TbPeriod;
        end loop;
        wait for TbPeriod;

        S_AXIS_DIS_tdata(15 downto 0) <= x"0002";
        S_AXIS_DIS_tvalid <= '1';
        wait for TbPeriod;
        while S_AXIS_DIS_tready = '0' loop
            wait for TbPeriod;
        end loop;
        wait for TbPeriod;

        S_AXIS_DIS_tvalid <= '0';
        wait for TbPeriod;
        wait for TbPeriod;

        S_AXIS_DIS_tdata(15 downto 0) <= x"0003";
        S_AXIS_DIS_tvalid <= '1';
        wait for TbPeriod;
        while S_AXIS_DIS_tready = '0' loop
            wait for TbPeriod;
        end loop;

        S_AXIS_DIS_tdata(15 downto 0) <= x"0004";
        S_AXIS_DIS_tvalid <= '1';
        wait for TbPeriod;
        while S_AXIS_DIS_tready = '0' loop
            wait for TbPeriod;
        end loop;

        S_AXIS_DIS_tdata(15 downto 0) <= x"0005";
        S_AXIS_DIS_tvalid <= '1';
        wait for TbPeriod;
        while S_AXIS_DIS_tready = '0' loop
            wait for TbPeriod;
        end loop;

        S_AXIS_DIS_tdata(15 downto 0) <= x"0006";
        S_AXIS_DIS_tvalid <= '1';
        S_AXIS_DIS_tlast <= '1';
        while S_AXIS_DIS_tready = '0' loop
            wait for TbPeriod;
        end loop;
        wait for TbPeriod;
        S_AXIS_DIS_tvalid <= '0';
        S_AXIS_DIS_tlast <= '0';
        wait for TbPeriod;
        wait for TbPeriod;
        wait for TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;


