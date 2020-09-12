----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/07/2020 02:00:21 PM
-- Design Name: 
-- Module Name: DisplayControl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY DisplayControl IS
    PORT (
        --8=CMD
        --9=done
        SoftResetn : in std_logic;
        ALiteData : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        WriteToggle : IN std_logic;
        ProcessStream : IN std_logic;
        BusyBit_out : OUT std_logic;

        CS : OUT std_logic;
        DCX : OUT std_logic;
        WR : OUT std_logic;
        RD : OUT std_logic;
        IM0 : OUT std_logic;
        ResetDisplay : OUT std_logic;
        LCD_Data : OUT std_logic_vector(15 DOWNTO 0);

        S_AXIS_DIS_tvalid : IN STD_LOGIC;
        S_AXIS_DIS_tready : OUT STD_LOGIC;
        S_AXIS_DIS_tdata : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        S_AXIS_DIS_tlast : IN STD_LOGIC;
        S_AXIS_clk : IN std_logic;
        S_AXIS_resetn : IN std_logic);
END DisplayControl;

ARCHITECTURE Behavioral OF DisplayControl IS
    SIGNAL WriteToggleCheck : std_logic;
    SIGNAL DataOutMask : std_logic;
    SIGNAL LatchedCommand : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal LatchedDataOut : std_logic_vector(15 downto 0);
    SIGNAL LatchedStreamInProcess : std_logic;
    signal tLast_Delay1 : std_logic;
    signal S_AXIS_tready_sig : std_logic;
    TYPE mainControlBlock IS (
        WaitForStart_main, --togle chip select low and command
        CommandSetup_main, -- load data on output
        CommandWriteLatch_main,
        CommandDCXEnd_main,
        CommandCheckEnd_main,
        StreamWriteSetup_main,
        StreamWriteLatch_main,
        StreamWriteEnd_main

    );
    SIGNAL controlSignal : mainControlBlock;
BEGIN
    RD <= '1';
    IM0 <= '0';
    LCD_Data(15 DOWNTO 0) <= x"00" & LatchedCommand(7 DOWNTO 0) WHEN DataOutMask = '1'
    ELSE
    LatchedDataOut(15 DOWNTO 0);

    S_AXIS_DIS_tready <= S_AXIS_tready_sig;
    ResetDisplay <= SoftResetn;

    --main state machine
    PROCESS (S_AXIS_clk)
    BEGIN
        if (rising_edge (S_AXIS_clk)) then
        IF S_AXIS_resetn = '0' or SoftResetn = '0' THEN
            WriteToggleCheck <= WriteToggle;
            DCX <= '1';
            CS <= '1';
            WR <= '1';
            DataOutMask <= '1';
            S_AXIS_tready_sig <= '0';
            controlSignal <= WaitForStart_main;
        ELSE
            CASE(controlSignal) IS

            WHEN WaitForStart_main =>
                LatchedStreamInProcess <= ProcessStream; --latched so axi write can't mess up case
                --if looking for stream data check tValid
                IF (ProcessStream = '1' AND S_AXIS_DIS_tvalid = '1') THEN
                    CS <= '0';
                    LatchedCommand(7 DOWNTO 0) <= x"2C";
                    controlSignal <= CommandSetup_main;

                    --if write toggle changes then initiate command
                ELSIF (WriteToggle /= WriteToggleCheck) THEN
                    CS <= '0';
                    LatchedCommand(7 DOWNTO 0) <= ALiteData(7 DOWNTO 0);
                    controlSignal <= CommandSetup_main;
                END IF;
                WriteToggleCheck <= WriteToggle;
            WHEN CommandSetup_main =>
                DataOutMask <= '1'; --first write always command
                if(ALiteData(8) = '1') then
                    DCX <= '0';
                end if;
                WR <= '0';
                controlSignal <= CommandWriteLatch_main;
            WHEN CommandWriteLatch_main =>
                WR <= '1';
                controlSignal <= CommandDCXEnd_main;
            WHEN CommandDCXEnd_main =>
                DCX <= '1';
                IF (LatchedStreamInProcess = '1') THEN
                    controlSignal <= StreamWriteSetup_main;
                    S_AXIS_tready_sig <= '1';
                ELSE
                    IF (ALiteData(9) = '1') THEN
                        --done
                        CS <= '1';
                    END IF;
                    controlSignal <= WaitForStart_main;
                END IF;

            WHEN StreamWriteSetup_main =>
                DataOutMask <= '0';
                if(S_AXIS_DIS_tvalid = '1') then
                    WR <= '0';
                    S_AXIS_tready_sig <= '0';
                    controlSignal <= StreamWriteLatch_main;
                end if;
            WHEN StreamWriteLatch_main =>
                WR <= '1';
                if(tlast_Delay1 = '1') then
                    controlSignal <= StreamWriteEnd_main;
                else
                    S_AXIS_tready_sig <= '1';
                    controlSignal <= StreamWriteSetup_main;
                end if;
            WHEN StreamWriteEnd_main =>
                controlSignal <= WaitForStart_main;
                CS <= '1';
            WHEN OTHERS =>

            END CASE;
        END IF;
        end if;
    END PROCESS; -- identifier

    PROCESS (S_AXIS_clk)
    BEGIN
        if (rising_edge (S_AXIS_clk)) then
        IF S_AXIS_resetn = '0' or SoftResetn = '0' THEN
            BusyBit_out <= '1';
        ELSE
            IF (controlSignal = WaitForStart_main 
            and WriteToggle = WriteToggleCheck
            and ProcessStream = '0') THEN
                BusyBit_out <= '0';
            ELSE
                BusyBit_out <= '1';
            END IF;

        END IF;
        END IF;
    END PROCESS; -- 

    PROCESS (S_AXIS_clk)
    BEGIN
        if (rising_edge (S_AXIS_clk)) then
            if S_AXIS_DIS_tvalid = '1' and S_AXIS_tready_sig = '1' then
            LatchedDataOut(15 DOWNTO 0) <= S_AXIS_DIS_tdata(15 downto 0);
            end if;
        end if;
    END PROCESS; -- 

    PROCESS (S_AXIS_clk)
    BEGIN
        if (rising_edge (S_AXIS_clk)) then
            tlast_Delay1 <= S_AXIS_DIS_tlast;
        end if;
    END PROCESS; -- 
     



END Behavioral;