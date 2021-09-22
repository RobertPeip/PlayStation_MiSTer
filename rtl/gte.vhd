library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 
use STD.textio.all;

use work.pGTE.all;

entity gte is
   port 
   (
      clk2x                : in  std_logic;
      clk2xIndex           : in  std_logic;
      ce                   : in  std_logic;
      reset                : in  std_logic;
      
      gte_busy             : out std_logic;
      gte_readAddr         : in  unsigned(5 downto 0);
      gte_readData         : out unsigned(31 downto 0);
      gte_writeAddr        : in  unsigned(5 downto 0);
      gte_writeData        : in  unsigned(31 downto 0);
      gte_writeEna         : in  std_logic; 
      gte_cmdData          : in  unsigned(31 downto 0);
      gte_cmdEna           : in  std_logic
   );
end entity;

architecture arch of gte is

   -- GTE data regs
   signal REG_V0X  : signed(15 downto 0);
   signal REG_V0Y  : signed(15 downto 0);
   signal REG_V0Z  : signed(15 downto 0);
   signal REG_V1X  : signed(15 downto 0);
   signal REG_V1Y  : signed(15 downto 0);
   signal REG_V1Z  : signed(15 downto 0);
   signal REG_V2X  : signed(15 downto 0);
   signal REG_V2Y  : signed(15 downto 0);
   signal REG_V2Z  : signed(15 downto 0);
   signal REG_RGBC : unsigned(31 downto 0);
   signal REG_OTZ  : unsigned(15 downto 0);
   signal REG_IR0  : signed(15 downto 0);
   signal REG_IR1  : signed(15 downto 0);
   signal REG_IR2  : signed(15 downto 0);
   signal REG_IR3  : signed(15 downto 0);
   signal REG_SX0  : signed(15 downto 0);
   signal REG_SY0  : signed(15 downto 0);
   signal REG_SX1  : signed(15 downto 0);
   signal REG_SY1  : signed(15 downto 0);
   signal REG_SX2  : signed(15 downto 0);
   signal REG_SY2  : signed(15 downto 0);
   signal REG_SZ0  : unsigned(15 downto 0);
   signal REG_SZ1  : unsigned(15 downto 0);
   signal REG_SZ2  : unsigned(15 downto 0);
   signal REG_SZ3  : unsigned(15 downto 0);
   signal REG_RGB0 : unsigned(31 downto 0);
   signal REG_RGB1 : unsigned(31 downto 0);
   signal REG_RGB2 : unsigned(31 downto 0);
   signal REG_RES1 : unsigned(31 downto 0);
   signal REG_MAC0 : signed(31 downto 0);
   signal REG_MAC1 : signed(31 downto 0);
   signal REG_MAC2 : signed(31 downto 0);
   signal REG_MAC3 : signed(31 downto 0);
   signal REG_IRGB : unsigned(14 downto 0);
   signal REG_ORGB : unsigned(14 downto 0);
   signal REG_LZCS : signed(31 downto 0);
   signal REG_LZCR : signed(31 downto 0);
   
   -- GTE control regs
   signal REG_RT11  : signed(15 downto 0);
   signal REG_RT12  : signed(15 downto 0);
   signal REG_RT13  : signed(15 downto 0);
   signal REG_RT21  : signed(15 downto 0);
   signal REG_RT22  : signed(15 downto 0);
   signal REG_RT23  : signed(15 downto 0);
   signal REG_RT31  : signed(15 downto 0);
   signal REG_RT32  : signed(15 downto 0);
   signal REG_RT33  : signed(15 downto 0);
   signal REG_TR0   : unsigned(31 downto 0);
   signal REG_TR1   : unsigned(31 downto 0);
   signal REG_TR2   : unsigned(31 downto 0);
   signal REG_LL11  : signed(15 downto 0);
   signal REG_LL12  : signed(15 downto 0);
   signal REG_LL13  : signed(15 downto 0);
   signal REG_LL21  : signed(15 downto 0);
   signal REG_LL22  : signed(15 downto 0);
   signal REG_LL23  : signed(15 downto 0);
   signal REG_LL31  : signed(15 downto 0);
   signal REG_LL32  : signed(15 downto 0);
   signal REG_LL33  : signed(15 downto 0);
   signal REG_BK0   : unsigned(31 downto 0);
   signal REG_BK1   : unsigned(31 downto 0);
   signal REG_BK2   : unsigned(31 downto 0);
   signal REG_LC11  : signed(15 downto 0);
   signal REG_LC12  : signed(15 downto 0);
   signal REG_LC13  : signed(15 downto 0);
   signal REG_LC21  : signed(15 downto 0);
   signal REG_LC22  : signed(15 downto 0);
   signal REG_LC23  : signed(15 downto 0);
   signal REG_LC31  : signed(15 downto 0);
   signal REG_LC32  : signed(15 downto 0);
   signal REG_LC33  : signed(15 downto 0);
   signal REG_FC0   : unsigned(31 downto 0);
   signal REG_FC1   : unsigned(31 downto 0);
   signal REG_FC2   : unsigned(31 downto 0);
   signal REG_OFX   : unsigned(31 downto 0);
   signal REG_OFY   : unsigned(31 downto 0);
   signal REG_H     : signed(15 downto 0);
   signal REG_DQA   : signed(15 downto 0);
   signal REG_DQB   : unsigned(31 downto 0);
   signal REG_ZSF3  : signed(15 downto 0);
   signal REG_ZSF4  : signed(15 downto 0);
   signal REG_FLAG  : unsigned(31 downto 0);
   
  
   -- calculation
   type tstate is
   (
      IDLE,
      CALC_NCLIP
   );
   signal state : tstate := IDLE;
   
   signal calcStep : integer range 0 to 15;
   
   signal cmdShift : std_logic;
   signal cmdsatIR : std_logic;
   signal cmdMM    : unsigned(1 downto 0);
   signal cmdMV    : unsigned(1 downto 0);
   signal cmdTV    : unsigned(1 downto 0);
   
   -- MACs
   signal MAC0req          : tMAC0req;
   signal mac0_result      : signed(31 downto 0);
   signal mac0_writeback   : std_logic;
   signal mac0Last         : signed(31 downto 0);
   
  
begin 

   process (clk2x)
   begin
      if rising_edge(clk2x) then
      
         if (reset = '1') then
         
            state    <= IDLE;
         
            gte_busy <= '0';
         
            REG_V0X  <= (others => '0');
            REG_V0Y  <= (others => '0');
            REG_V0Z  <= (others => '0');
            REG_V1X  <= (others => '0');
            REG_V1Y  <= (others => '0');
            REG_V1Z  <= (others => '0');
            REG_V2X  <= (others => '0');
            REG_V2Y  <= (others => '0');
            REG_V2Z  <= (others => '0');
            REG_RGBC <= (others => '0');
            REG_OTZ  <= (others => '0');
            REG_IR0  <= (others => '0');
            REG_IR1  <= (others => '0');
            REG_IR2  <= (others => '0');
            REG_IR3  <= (others => '0');
            REG_SX0  <= (others => '0');
            REG_SY0  <= (others => '0');
            REG_SX1  <= (others => '0');
            REG_SY1  <= (others => '0');
            REG_SX2  <= (others => '0');
            REG_SY2  <= (others => '0');
            REG_SZ0  <= (others => '0');
            REG_SZ1  <= (others => '0');
            REG_SZ2  <= (others => '0');
            REG_SZ3  <= (others => '0');
            REG_RGB0 <= (others => '0');
            REG_RGB1 <= (others => '0');
            REG_RGB2 <= (others => '0');
            REG_RES1 <= (others => '0');
            REG_MAC0 <= (others => '0');
            REG_MAC1 <= (others => '0');
            REG_MAC2 <= (others => '0');
            REG_MAC3 <= (others => '0');
            REG_IRGB <= (others => '0');
            REG_ORGB <= (others => '0');
            REG_LZCS <= (others => '0');
            REG_LZCR <= (others => '0');
            
            REG_RT11 <= (others => '0');
            REG_RT12 <= (others => '0');
            REG_RT13 <= (others => '0');
            REG_RT21 <= (others => '0');
            REG_RT22 <= (others => '0');
            REG_RT23 <= (others => '0');
            REG_RT31 <= (others => '0');
            REG_RT32 <= (others => '0');
            REG_RT33 <= (others => '0');
            REG_TR0  <= (others => '0');
            REG_TR1  <= (others => '0');
            REG_TR2  <= (others => '0');
            REG_LL11 <= (others => '0');
            REG_LL12 <= (others => '0');
            REG_LL13 <= (others => '0');
            REG_LL21 <= (others => '0');
            REG_LL22 <= (others => '0');
            REG_LL23 <= (others => '0');
            REG_LL31 <= (others => '0');
            REG_LL32 <= (others => '0');
            REG_LL33 <= (others => '0');
            REG_BK0  <= (others => '0');
            REG_BK1  <= (others => '0');
            REG_BK2  <= (others => '0');
            REG_LC11 <= (others => '0');
            REG_LC12 <= (others => '0');
            REG_LC13 <= (others => '0');
            REG_LC21 <= (others => '0');
            REG_LC22 <= (others => '0');
            REG_LC23 <= (others => '0');
            REG_LC31 <= (others => '0');
            REG_LC32 <= (others => '0');
            REG_LC33 <= (others => '0');
            REG_FC0  <= (others => '0');
            REG_FC1  <= (others => '0');
            REG_FC2  <= (others => '0');
            REG_OFX  <= (others => '0');
            REG_OFY  <= (others => '0');
            REG_H    <= (others => '0');
            REG_DQA  <= (others => '0');
            REG_DQB  <= (others => '0');
            REG_ZSF3 <= (others => '0');
            REG_ZSF4 <= (others => '0');
            REG_FLAG <= (others => '0');
            
         elsif (ce = '1') then
         
            MAC0req.trigger <= '0';
         
            case (to_integer(gte_readAddr)) is
               when 00 => gte_readData <= unsigned(REG_V0Y & REG_V0X);
               when 01 => gte_readData <= unsigned(x"0000" & REG_V0Z);
               when 02 => gte_readData <= unsigned(REG_V1Y & REG_V1X);
               when 03 => gte_readData <= unsigned(x"0000" & REG_V1Z);
               when 04 => gte_readData <= unsigned(REG_V2Y & REG_V2X);
               when 05 => gte_readData <= unsigned(x"0000" & REG_V2Z);
               when 06 => gte_readData <= REG_RGBC;
               when 07 => gte_readData <= x"0000" & REG_OTZ;
               when 08 => gte_readData <= unsigned(resize(REG_IR0, 32));
               when 09 => gte_readData <= unsigned(resize(REG_IR1, 32));
               when 10 => gte_readData <= unsigned(resize(REG_IR2, 32));
               when 11 => gte_readData <= unsigned(resize(REG_IR3, 32));
               when 12 => gte_readData <= unsigned(REG_SY0 & REG_SX0);
               when 13 => gte_readData <= unsigned(REG_SY1 & REG_SX1);
               when 14 => gte_readData <= unsigned(REG_SY2 & REG_SX2);
               when 15 => gte_readData <= unsigned(REG_SY2 & REG_SX2);
               when 16 => gte_readData <= x"0000" & REG_SZ0;
               when 17 => gte_readData <= x"0000" & REG_SZ1;
               when 18 => gte_readData <= x"0000" & REG_SZ2;
               when 19 => gte_readData <= x"0000" & REG_SZ3;
               when 20 => gte_readData <= REG_RGB0;
               when 21 => gte_readData <= REG_RGB1;
               when 22 => gte_readData <= REG_RGB2;
               when 23 => gte_readData <= REG_RES1;
               when 24 => gte_readData <= unsigned(REG_MAC0);
               when 25 => gte_readData <= unsigned(REG_MAC1);
               when 26 => gte_readData <= unsigned(REG_MAC2);
               when 27 => gte_readData <= unsigned(REG_MAC3);
               when 28 | 29 => 
                  gte_readData(31 downto 15) <= (others => '0');
                  if (REG_IR1 < 0) then gte_readData( 4 downto  0) <= "00000"; elsif (REG_IR1(15 downto 7) > 31) then gte_readData( 4 downto  0) <= "11111"; else gte_readData( 4 downto  0) <= unsigned(REG_IR1(11 downto 7)); end if;
                  if (REG_IR2 < 0) then gte_readData( 9 downto  5) <= "00000"; elsif (REG_IR2(15 downto 7) > 31) then gte_readData( 9 downto  5) <= "11111"; else gte_readData( 9 downto  5) <= unsigned(REG_IR2(11 downto 7)); end if;
                  if (REG_IR3 < 0) then gte_readData(14 downto 10) <= "00000"; elsif (REG_IR3(15 downto 7) > 31) then gte_readData(14 downto 10) <= "11111"; else gte_readData(14 downto 10) <= unsigned(REG_IR3(11 downto 7)); end if;

               when 30 => gte_readData <= unsigned(REG_LZCS);
               when 31 => gte_readData <= unsigned(REG_LZCR);
               when 32 => gte_readData <= unsigned(REG_RT12 & REG_RT11);
               when 33 => gte_readData <= unsigned(REG_RT21 & REG_RT13);
               when 34 => gte_readData <= unsigned(REG_RT23 & REG_RT22);
               when 35 => gte_readData <= unsigned(REG_RT32 & REG_RT31);
               when 36 => gte_readData <= unsigned(x"0000"  & REG_RT33);
               when 37 => gte_readData <= REG_TR0;
               when 38 => gte_readData <= REG_TR1;
               when 39 => gte_readData <= REG_TR2;
               when 40 => gte_readData <= unsigned(REG_LL12 & REG_LL11);
               when 41 => gte_readData <= unsigned(REG_LL21 & REG_LL13);
               when 42 => gte_readData <= unsigned(REG_LL23 & REG_LL22);
               when 43 => gte_readData <= unsigned(REG_LL32 & REG_LL31);
               when 44 => gte_readData <= unsigned(x"0000"  & REG_LL33);
               when 45 => gte_readData <= REG_BK0;
               when 46 => gte_readData <= REG_BK1;
               when 47 => gte_readData <= REG_BK2;
               when 48 => gte_readData <= unsigned(REG_LC12 & REG_LC11);
               when 49 => gte_readData <= unsigned(REG_LC21 & REG_LC13);
               when 50 => gte_readData <= unsigned(REG_LC23 & REG_LC22);
               when 51 => gte_readData <= unsigned(REG_LC32 & REG_LC31);
               when 52 => gte_readData <= unsigned(x"0000"  & REG_LC33);
               when 53 => gte_readData <= REG_FC0;
               when 54 => gte_readData <= REG_FC1;
               when 55 => gte_readData <= REG_FC2;
               when 56 => gte_readData <= REG_OFX;
               when 57 => gte_readData <= REG_OFY;
               when 58 => gte_readData <= unsigned(resize(REG_H, 32));
               when 59 => gte_readData <= unsigned(resize(REG_DQA, 32));
               when 60 => gte_readData <= REG_DQB;
               when 61 => gte_readData <= unsigned(resize(REG_ZSF3, 32));
               when 62 => gte_readData <= unsigned(resize(REG_ZSF4, 32));
               when 63 => gte_readData <= REG_FLAG;
               when others => null;
            end case;
         
            if (gte_writeEna = '1' and clk2xIndex = '1') then
            
               case (to_integer(gte_writeAddr)) is
                  when 00 => REG_V0X <= signed(gte_writeData(15 downto 0)); REG_V0Y <= signed(gte_writeData(31 downto 16));
                  when 01 => REG_V0Z <= signed(gte_writeData(15 downto 0));
                  when 02 => REG_V1X <= signed(gte_writeData(15 downto 0)); REG_V1Y <= signed(gte_writeData(31 downto 16));
                  when 03 => REG_V1Z <= signed(gte_writeData(15 downto 0));
                  when 04 => REG_V2X <= signed(gte_writeData(15 downto 0)); REG_V2Y <= signed(gte_writeData(31 downto 16));
                  when 05 => REG_V2Z <= signed(gte_writeData(15 downto 0));
                  when 06 => REG_RGBC <= gte_writeData;
                  when 07 => REG_OTZ  <= gte_writeData(15 downto 0);
                  when 08 => REG_IR0  <= signed(gte_writeData(15 downto 0));
                  when 09 => REG_IR1  <= signed(gte_writeData(15 downto 0));
                  when 10 => REG_IR2  <= signed(gte_writeData(15 downto 0));
                  when 11 => REG_IR3  <= signed(gte_writeData(15 downto 0));
                  when 12 => REG_SX0  <= signed(gte_writeData(15 downto 0)); REG_SY0 <= signed(gte_writeData(31 downto 16));
                  when 13 => REG_SX1  <= signed(gte_writeData(15 downto 0)); REG_SY1 <= signed(gte_writeData(31 downto 16));
                  when 14 => REG_SX2  <= signed(gte_writeData(15 downto 0)); REG_SY2 <= signed(gte_writeData(31 downto 16));
                  when 15 => 
                     REG_SX2  <= signed(gte_writeData(15 downto 0)); REG_SY0 <= signed(gte_writeData(31 downto 16));
                     REG_SX1  <= REG_SX2; REG_SY1 <= REG_SY2;
                     REG_SX0  <= REG_SX1; REG_SY0 <= REG_SY1;
                  when 16 => REG_SZ0  <= gte_writeData(15 downto 0);
                  when 17 => REG_SZ1  <= gte_writeData(15 downto 0);
                  when 18 => REG_SZ2  <= gte_writeData(15 downto 0);
                  when 19 => REG_SZ3  <= gte_writeData(15 downto 0);
                  when 20 => REG_RGB0 <= gte_writeData;
                  when 21 => REG_RGB1 <= gte_writeData;
                  when 22 => REG_RGB2 <= gte_writeData;
                  when 23 => REG_RES1 <= gte_writeData;
                  when 24 => REG_MAC0 <= signed(gte_writeData);
                  when 25 => REG_MAC1 <= signed(gte_writeData);
                  when 26 => REG_MAC2 <= signed(gte_writeData);
                  when 27 => REG_MAC3 <= signed(gte_writeData);
                  when 28 => 
                     REG_IRGB <= gte_writeData(14 downto 0);
                     REG_IR1  <= signed("0000" & gte_writeData( 4 downto  0) & "0000000");
                     REG_IR2  <= signed("0000" & gte_writeData( 9 downto  5) & "0000000");
                     REG_IR3  <= signed("0000" & gte_writeData(14 downto 10) & "0000000");
                  when 29 => -- read only
                  when 30 =>
                     REG_LZCS <= signed(gte_writeData);
                     -- todo: trigger counting
                  when 31 => -- read only
                  when 32 => REG_RT11 <= signed(gte_writeData(15 downto 0)); REG_RT12 <= signed(gte_writeData(31 downto 16));
                  when 33 => REG_RT21 <= signed(gte_writeData(15 downto 0)); REG_RT13 <= signed(gte_writeData(31 downto 16));
                  when 34 => REG_RT23 <= signed(gte_writeData(15 downto 0)); REG_RT22 <= signed(gte_writeData(31 downto 16));
                  when 35 => REG_RT32 <= signed(gte_writeData(15 downto 0)); REG_RT31 <= signed(gte_writeData(31 downto 16));
                  when 36 => REG_RT33 <= signed(gte_writeData(15 downto 0));
                  when 37 => REG_TR0  <= gte_writeData;
                  when 38 => REG_TR1  <= gte_writeData;
                  when 39 => REG_TR2  <= gte_writeData;
                  when 40 => REG_LL11 <= signed(gte_writeData(15 downto 0)); REG_LL12 <= signed(gte_writeData(31 downto 16));
                  when 41 => REG_LL21 <= signed(gte_writeData(15 downto 0)); REG_LL13 <= signed(gte_writeData(31 downto 16));
                  when 42 => REG_LL23 <= signed(gte_writeData(15 downto 0)); REG_LL22 <= signed(gte_writeData(31 downto 16));
                  when 43 => REG_LL32 <= signed(gte_writeData(15 downto 0)); REG_LL31 <= signed(gte_writeData(31 downto 16));
                  when 44 => REG_LL33 <= signed(gte_writeData(15 downto 0));
                  when 45 => REG_BK0  <= gte_writeData;
                  when 46 => REG_BK1  <= gte_writeData;
                  when 47 => REG_BK2  <= gte_writeData;
                  when 48 => REG_LC11 <= signed(gte_writeData(15 downto 0)); REG_LC12 <= signed(gte_writeData(31 downto 16));
                  when 49 => REG_LC21 <= signed(gte_writeData(15 downto 0)); REG_LC13 <= signed(gte_writeData(31 downto 16));
                  when 50 => REG_LC23 <= signed(gte_writeData(15 downto 0)); REG_LC22 <= signed(gte_writeData(31 downto 16));
                  when 51 => REG_LC32 <= signed(gte_writeData(15 downto 0)); REG_LC31 <= signed(gte_writeData(31 downto 16));
                  when 52 => REG_LC33 <= signed(gte_writeData(15 downto 0));
                  when 53 => REG_FC0  <= gte_writeData;
                  when 54 => REG_FC1  <= gte_writeData;
                  when 55 => REG_FC2  <= gte_writeData;
                  when 56 => REG_OFX  <= gte_writeData;
                  when 57 => REG_OFY  <= gte_writeData;
                  when 58 => REG_H    <= signed(gte_writeData(15 downto 0));
                  when 59 => REG_DQA  <= signed(gte_writeData(15 downto 0));
                  when 60 => REG_DQB  <= gte_writeData;
                  when 61 => REG_ZSF3 <= signed(gte_writeData(15 downto 0));
                  when 62 => REG_ZSF4 <= signed(gte_writeData(15 downto 0));
                  when 63 => 
                     REG_FLAG(30 downto 12) <= gte_writeData(30 downto 12);
                     REG_FLAG(31) <= '0';
                     if ((gte_writeData(30 downto 12) and to_unsigned(16#7F87E#, 19)) > 0) then
                        REG_FLAG(31) <= '1';
                     end if;
                  when others => null;
               end case;
            
            end if;
            
            -- calculation
            calcStep <= calcStep + 1; 
            
            case (state) is
            
               when IDLE =>
                  calcStep <= 0;
                  if (gte_cmdEna = '1' and clk2xIndex = '0') then
                     gte_busy <= '1';
                     cmdShift <= gte_cmdData(19);
                     cmdsatIR <= gte_cmdData(10);
                     cmdMM    <= gte_cmdData(18 downto 17);
                     cmdMV    <= gte_cmdData(16 downto 15);
                     cmdTV    <= gte_cmdData(14 downto 13);
                     case (to_integer(gte_cmdData(5 downto 0))) is
                        
                        when 16#06# => state <= CALC_NCLIP; 
                     
                        when others => gte_busy <= '0';
                     end case;
                  end if;
               
               when CALC_NCLIP =>
                  case (calcStep) is
                     --                     mul1       mul2      add     sub  swap useIR IRs cOvf uRes trigger
                     when 0 => MAC0req <= (REG_SX0, REG_SY1, x"00000000", '0', '0', '0', '0', '0', '0', '1'); 
                     when 1 => MAC0req <= (REG_SX1, REG_SY2, x"00000000", '0', '0', '0', '0', '0', '1', '1'); 
                     when 2 => MAC0req <= (REG_SX2, REG_SY0, x"00000000", '0', '0', '0', '0', '0', '1', '1'); 
                     when 3 => MAC0req <= (REG_SX0, REG_SY2, x"00000000", '1', '0', '0', '0', '0', '1', '1'); 
                     when 4 => MAC0req <= (REG_SX1, REG_SY0, x"00000000", '1', '0', '0', '0', '0', '1', '1'); 
                     when 5 => MAC0req <= (REG_SX2, REG_SY1, x"00000000", '1', '0', '0', '0', '1', '1', '1'); 
                     when 7 => state <= IDLE; gte_busy <= '0';
                     when others => null;
                  end case;
               
            
            
            end case;
            
            -- writebacks
            if (mac0_writeback = '1') then
               REG_MAC0 <= mac0_result;
            end if;
            
         
         
         end if;
         
      end if;
   end process;
   
   -- processing units
   igte_mac0 : entity work.gte_mac0
   port map
   (
      clk2x          => clk2x,         
      MAC0req        => MAC0req,       
      mac0_result    => mac0_result,   
      mac0_writeback => mac0_writeback,
      mac0Last       => mac0Last
   );
   
   
   
   
   
   
   
   
   
   -- synthesis translate_off
   
   goutput : if 1 = 1 generate
   begin
   
      process
         file outfile            : text;
         variable f_status       : FILE_OPEN_STATUS;
         variable line_out       : line;
         variable regcheck       : integer range 0 to 3; 
         variable busy_1         : std_logic := '0'; 
         variable gte_writeEna_1 : std_logic := '0';
         variable gte_cmdEna_1   : std_logic := '0';
         
         variable var_V0X   : signed(15 downto 0)   := (others => '0');
         variable var_V0Y   : signed(15 downto 0)   := (others => '0');
         variable var_V0Z   : signed(15 downto 0)   := (others => '0');
         variable var_V1X   : signed(15 downto 0)   := (others => '0');
         variable var_V1Y   : signed(15 downto 0)   := (others => '0');
         variable var_V1Z   : signed(15 downto 0)   := (others => '0');
         variable var_V2X   : signed(15 downto 0)   := (others => '0');
         variable var_V2Y   : signed(15 downto 0)   := (others => '0');
         variable var_V2Z   : signed(15 downto 0)   := (others => '0');
         variable var_RGBC  : unsigned(31 downto 0) := (others => '0');
         variable var_OTZ   : unsigned(15 downto 0) := (others => '0');
         variable var_IR0   : signed(15 downto 0)   := (others => '0');
         variable var_IR1   : signed(15 downto 0)   := (others => '0');
         variable var_IR2   : signed(15 downto 0)   := (others => '0');
         variable var_IR3   : signed(15 downto 0)   := (others => '0');
         variable var_SX0   : signed(15 downto 0)   := (others => '0');
         variable var_SY0   : signed(15 downto 0)   := (others => '0');
         variable var_SX1   : signed(15 downto 0)   := (others => '0');
         variable var_SY1   : signed(15 downto 0)   := (others => '0');
         variable var_SX2   : signed(15 downto 0)   := (others => '0');
         variable var_SY2   : signed(15 downto 0)   := (others => '0');
         variable var_SZ0   : unsigned(15 downto 0) := (others => '0');
         variable var_SZ1   : unsigned(15 downto 0) := (others => '0');
         variable var_SZ2   : unsigned(15 downto 0) := (others => '0');
         variable var_SZ3   : unsigned(15 downto 0) := (others => '0');
         variable var_RGB0  : unsigned(31 downto 0) := (others => '0');
         variable var_RGB1  : unsigned(31 downto 0) := (others => '0');
         variable var_RGB2  : unsigned(31 downto 0) := (others => '0');
         variable var_RES1  : unsigned(31 downto 0) := (others => '0');
         variable var_MAC0  : signed(31 downto 0)   := (others => '0');
         variable var_MAC1  : signed(31 downto 0)   := (others => '0');
         variable var_MAC2  : signed(31 downto 0)   := (others => '0');
         variable var_MAC3  : signed(31 downto 0)   := (others => '0');
         variable var_IRGB  : unsigned(14 downto 0) := (others => '0');
         variable var_ORGB  : unsigned(14 downto 0) := (others => '0');
         variable var_LZCS  : signed(31 downto 0)   := (others => '0');
         variable var_LZCR  : signed(31 downto 0)   := (others => '0');
         variable var_RT11  : signed(15 downto 0)   := (others => '0');
         variable var_RT12  : signed(15 downto 0)   := (others => '0');
         variable var_RT13  : signed(15 downto 0)   := (others => '0');
         variable var_RT21  : signed(15 downto 0)   := (others => '0');
         variable var_RT22  : signed(15 downto 0)   := (others => '0');
         variable var_RT23  : signed(15 downto 0)   := (others => '0');
         variable var_RT31  : signed(15 downto 0)   := (others => '0');
         variable var_RT32  : signed(15 downto 0)   := (others => '0');
         variable var_RT33  : signed(15 downto 0)   := (others => '0');
         variable var_TR0   : unsigned(31 downto 0) := (others => '0');
         variable var_TR1   : unsigned(31 downto 0) := (others => '0');
         variable var_TR2   : unsigned(31 downto 0) := (others => '0');
         variable var_LL11  : signed(15 downto 0)   := (others => '0');
         variable var_LL12  : signed(15 downto 0)   := (others => '0');
         variable var_LL13  : signed(15 downto 0)   := (others => '0');
         variable var_LL21  : signed(15 downto 0)   := (others => '0');
         variable var_LL22  : signed(15 downto 0)   := (others => '0');
         variable var_LL23  : signed(15 downto 0)   := (others => '0');
         variable var_LL31  : signed(15 downto 0)   := (others => '0');
         variable var_LL32  : signed(15 downto 0)   := (others => '0');
         variable var_LL33  : signed(15 downto 0)   := (others => '0');
         variable var_BK0   : unsigned(31 downto 0) := (others => '0');
         variable var_BK1   : unsigned(31 downto 0) := (others => '0');
         variable var_BK2   : unsigned(31 downto 0) := (others => '0');
         variable var_LC11  : signed(15 downto 0)   := (others => '0');
         variable var_LC12  : signed(15 downto 0)   := (others => '0');
         variable var_LC13  : signed(15 downto 0)   := (others => '0');
         variable var_LC21  : signed(15 downto 0)   := (others => '0');
         variable var_LC22  : signed(15 downto 0)   := (others => '0');
         variable var_LC23  : signed(15 downto 0)   := (others => '0');
         variable var_LC31  : signed(15 downto 0)   := (others => '0');
         variable var_LC32  : signed(15 downto 0)   := (others => '0');
         variable var_LC33  : signed(15 downto 0)   := (others => '0');
         variable var_FC0   : unsigned(31 downto 0) := (others => '0');
         variable var_FC1   : unsigned(31 downto 0) := (others => '0');
         variable var_FC2   : unsigned(31 downto 0) := (others => '0');
         variable var_OFX   : unsigned(31 downto 0) := (others => '0');
         variable var_OFY   : unsigned(31 downto 0) := (others => '0');
         variable var_H     : signed(15 downto 0)   := (others => '0');
         variable var_DQA   : signed(15 downto 0)   := (others => '0');
         variable var_DQB   : unsigned(31 downto 0) := (others => '0');
         variable var_ZSF3  : signed(15 downto 0)   := (others => '0');
         variable var_ZSF4  : signed(15 downto 0)   := (others => '0');
         variable var_FLAG  : unsigned(31 downto 0) := (others => '0');
         
      begin
   
         file_open(f_status, outfile, "R:\\debug_gte_sim.txt", write_mode);
         file_close(outfile);
         
         file_open(f_status, outfile, "R:\\debug_gte_sim.txt", append_mode);
         
         while (true) loop
            
            wait until rising_edge(clk2x);
                        
            regcheck := 0;
            
            if (gte_writeEna_1 = '1') then
               regcheck := 2;
            end if;
            
            if (gte_busy = '0' and busy_1 = '1') then
               regcheck := 3;
            end if;

            if (regcheck > 0) then
               if (var_V0X  /= REG_V0X or var_V0Y  /= REG_V0Y  ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("00 ")); write(line_out, to_hstring(std_logic_vector(REG_V0Y & REG_V0X)));        writeline(outfile, line_out); var_V0X  := REG_V0X ; var_V0Y  := REG_V0Y ; end if;
               if (var_V0Z  /= REG_V0Z                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("01 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_V0Z)));        writeline(outfile, line_out); var_V0Z  := REG_V0Z ; end if;
               if (var_V1X  /= REG_V1X or var_V1Y  /= REG_V1Y  ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("02 ")); write(line_out, to_hstring(std_logic_vector(REG_V1Y & REG_V1X)));        writeline(outfile, line_out); var_V1X  := REG_V1X ; var_V1Y  := REG_V1Y ; end if;
               if (var_V1Z  /= REG_V1Z                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("03 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_V1Z)));        writeline(outfile, line_out); var_V1Z  := REG_V1Z ; end if;
               if (var_V2X  /= REG_V2X                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("04 ")); write(line_out, to_hstring(std_logic_vector(REG_V2Y & REG_V2X)));        writeline(outfile, line_out); var_V2X  := REG_V2X ; var_V2Y  := REG_V2Y ; end if;
               if (var_V2Y  /= REG_V2Y                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("04 ")); write(line_out, to_hstring(std_logic_vector(REG_V2Y & REG_V2X)));        writeline(outfile, line_out); var_V2Y  := REG_V2Y ; end if;
               if (var_V2Z  /= REG_V2Z                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("05 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_V2Z)));        writeline(outfile, line_out); var_V2Z  := REG_V2Z ; end if;
               if (var_RGBC /= REG_RGBC                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("06 ")); write(line_out, to_hstring(std_logic_vector(REG_RGBC)));                 writeline(outfile, line_out); var_RGBC := REG_RGBC; end if;
               if (var_OTZ  /= REG_OTZ                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("07 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_OTZ)));        writeline(outfile, line_out); var_OTZ  := REG_OTZ ; end if;
               if (var_IR0  /= REG_IR0                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("08 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_IR0, 32))));      writeline(outfile, line_out); var_IR0  := REG_IR0 ; end if;
               if (var_IR1  /= REG_IR1                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("09 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_IR1, 32))));      writeline(outfile, line_out); var_IR1  := REG_IR1 ; end if;
               if (var_IR2  /= REG_IR2                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("10 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_IR2, 32))));      writeline(outfile, line_out); var_IR2  := REG_IR2 ; end if;
               if (var_IR3  /= REG_IR3                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("11 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_IR3, 32))));      writeline(outfile, line_out); var_IR3  := REG_IR3 ; end if;
               if (var_SX0  /= REG_SX0 or var_SY0  /= REG_SY0  ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("12 ")); write(line_out, to_hstring(std_logic_vector(REG_SY0 & REG_SX0)));        writeline(outfile, line_out); var_SX0  := REG_SX0 ; var_SY0  := REG_SY0 ; end if;
               if (var_SX1  /= REG_SX1 or var_SY1  /= REG_SY1  ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("13 ")); write(line_out, to_hstring(std_logic_vector(REG_SY1 & REG_SX1)));        writeline(outfile, line_out); var_SX1  := REG_SX1 ; var_SY1  := REG_SY1 ; end if;
               if (var_SX2  /= REG_SX2 or var_SY2  /= REG_SY2  ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("14 ")); write(line_out, to_hstring(std_logic_vector(REG_SY2 & REG_SX2)));        writeline(outfile, line_out); var_SX2  := REG_SX2 ; var_SY2  := REG_SY2 ; end if;
               if (var_SZ0  /= REG_SZ0                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("16 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_SZ0)));        writeline(outfile, line_out); var_SZ0  := REG_SZ0 ; end if;
               if (var_SZ1  /= REG_SZ1                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("17 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_SZ1)));        writeline(outfile, line_out); var_SZ1  := REG_SZ1 ; end if;
               if (var_SZ2  /= REG_SZ2                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("18 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_SZ2)));        writeline(outfile, line_out); var_SZ2  := REG_SZ2 ; end if;
               if (var_SZ3  /= REG_SZ3                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("19 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & REG_SZ3)));        writeline(outfile, line_out); var_SZ3  := REG_SZ3 ; end if;
               if (var_RGB0 /= REG_RGB0                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("20 ")); write(line_out, to_hstring(std_logic_vector(REG_RGB0)));                 writeline(outfile, line_out); var_RGB0 := REG_RGB0; end if;
               if (var_RGB1 /= REG_RGB1                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("21 ")); write(line_out, to_hstring(std_logic_vector(REG_RGB1)));                 writeline(outfile, line_out); var_RGB1 := REG_RGB1; end if;
               if (var_RGB2 /= REG_RGB2                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("22 ")); write(line_out, to_hstring(std_logic_vector(REG_RGB2)));                 writeline(outfile, line_out); var_RGB2 := REG_RGB2; end if;
               if (var_RES1 /= REG_RES1                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("23 ")); write(line_out, to_hstring(std_logic_vector(REG_RES1)));                 writeline(outfile, line_out); var_RES1 := REG_RES1; end if;
               if (var_MAC0 /= REG_MAC0                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("24 ")); write(line_out, to_hstring(std_logic_vector(REG_MAC0)));                 writeline(outfile, line_out); var_MAC0 := REG_MAC0; end if;
               if (var_MAC1 /= REG_MAC1                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("25 ")); write(line_out, to_hstring(std_logic_vector(REG_MAC1)));                 writeline(outfile, line_out); var_MAC1 := REG_MAC1; end if;
               if (var_MAC2 /= REG_MAC2                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("26 ")); write(line_out, to_hstring(std_logic_vector(REG_MAC2)));                 writeline(outfile, line_out); var_MAC2 := REG_MAC2; end if;
               if (var_MAC3 /= REG_MAC3                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("27 ")); write(line_out, to_hstring(std_logic_vector(REG_MAC3)));                 writeline(outfile, line_out); var_MAC3 := REG_MAC3; end if;
               if (var_IRGB /= REG_IRGB                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("28 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & '0' & REG_IRGB))); writeline(outfile, line_out); var_IRGB := REG_IRGB; end if;
               if (var_ORGB /= REG_ORGB                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("29 ")); write(line_out, to_hstring(std_logic_vector(x"0000" & '0' & REG_ORGB))); writeline(outfile, line_out); var_ORGB := REG_ORGB; end if;
               if (var_LZCS /= REG_LZCS                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("30 ")); write(line_out, to_hstring(std_logic_vector(REG_LZCS)));                 writeline(outfile, line_out); var_LZCS := REG_LZCS; end if;
               if (var_LZCR /= REG_LZCR                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("31 ")); write(line_out, to_hstring(std_logic_vector(REG_LZCR)));                 writeline(outfile, line_out); var_LZCR := REG_LZCR; end if;
               if (var_RT11 /= REG_RT11 or var_RT12 /= REG_RT12) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("32 ")); write(line_out, to_hstring(std_logic_vector(REG_RT12 & REG_RT11)));      writeline(outfile, line_out); var_RT11 := REG_RT11; var_RT12 := REG_RT12; end if;
               if (var_RT13 /= REG_RT13 or var_RT21 /= REG_RT21) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("33 ")); write(line_out, to_hstring(std_logic_vector(REG_RT21 & REG_RT13)));      writeline(outfile, line_out); var_RT13 := REG_RT13; var_RT21 := REG_RT21; end if;
               if (var_RT22 /= REG_RT22 or var_RT23 /= REG_RT23) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("34 ")); write(line_out, to_hstring(std_logic_vector(REG_RT23 & REG_RT22)));      writeline(outfile, line_out); var_RT22 := REG_RT22; var_RT23 := REG_RT23; end if;
               if (var_RT31 /= REG_RT31 or var_RT32 /= REG_RT32) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("35 ")); write(line_out, to_hstring(std_logic_vector(REG_RT32 & REG_RT31)));      writeline(outfile, line_out); var_RT31 := REG_RT31; var_RT32 := REG_RT32; end if;
               if (var_RT33 /= REG_RT33                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("36 ")); write(line_out, to_hstring(std_logic_vector(x"0000"  & REG_RT33)));      writeline(outfile, line_out); var_RT33 := REG_RT33; end if;
               if (var_TR0  /= REG_TR0                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("37 ")); write(line_out, to_hstring(std_logic_vector(REG_TR0)));                  writeline(outfile, line_out); var_TR0  := REG_TR0 ; end if;
               if (var_TR1  /= REG_TR1                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("38 ")); write(line_out, to_hstring(std_logic_vector(REG_TR1)));                  writeline(outfile, line_out); var_TR1  := REG_TR1 ; end if;
               if (var_TR2  /= REG_TR2                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("39 ")); write(line_out, to_hstring(std_logic_vector(REG_TR2)));                  writeline(outfile, line_out); var_TR2  := REG_TR2 ; end if;
               if (var_LL11 /= REG_LL11 or var_LL12 /= REG_LL12) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("40 ")); write(line_out, to_hstring(std_logic_vector(REG_LL12 & REG_LL11)));      writeline(outfile, line_out); var_LL11 := REG_LL11; var_LL12 := REG_LL12; end if;
               if (var_LL13 /= REG_LL13 or var_LL21 /= REG_LL21) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("41 ")); write(line_out, to_hstring(std_logic_vector(REG_LL21 & REG_LL13)));      writeline(outfile, line_out); var_LL13 := REG_LL13; var_LL21 := REG_LL21; end if;
               if (var_LL22 /= REG_LL22 or var_LL23 /= REG_LL23) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("42 ")); write(line_out, to_hstring(std_logic_vector(REG_LL23 & REG_LL22)));      writeline(outfile, line_out); var_LL22 := REG_LL22; var_LL23 := REG_LL23; end if;
               if (var_LL31 /= REG_LL31 or var_LL32 /= REG_LL32) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("43 ")); write(line_out, to_hstring(std_logic_vector(REG_LL32 & REG_LL31)));      writeline(outfile, line_out); var_LL31 := REG_LL31; var_LL32 := REG_LL32; end if;
               if (var_LL33 /= REG_LL33                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("44 ")); write(line_out, to_hstring(std_logic_vector(x"0000"  & REG_LL33)));      writeline(outfile, line_out); var_LL33 := REG_LL33; end if;
               if (var_BK0  /= REG_BK0                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("45 ")); write(line_out, to_hstring(std_logic_vector(REG_BK0)));                  writeline(outfile, line_out); var_BK0  := REG_BK0 ; end if;
               if (var_BK1  /= REG_BK1                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("46 ")); write(line_out, to_hstring(std_logic_vector(REG_BK1)));                  writeline(outfile, line_out); var_BK1  := REG_BK1 ; end if;
               if (var_BK2  /= REG_BK2                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("47 ")); write(line_out, to_hstring(std_logic_vector(REG_BK2)));                  writeline(outfile, line_out); var_BK2  := REG_BK2 ; end if;
               if (var_LC11 /= REG_LC11 or var_LC12 /= REG_LC12) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("48 ")); write(line_out, to_hstring(std_logic_vector(REG_LC12 & REG_LC11)));      writeline(outfile, line_out); var_LC11 := REG_LC11; var_LC12 := REG_LC12; end if;
               if (var_LC13 /= REG_LC13 or var_LC21 /= REG_LC21) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("49 ")); write(line_out, to_hstring(std_logic_vector(REG_LC21 & REG_LC13)));      writeline(outfile, line_out); var_LC13 := REG_LC13; var_LC21 := REG_LC21; end if;
               if (var_LC22 /= REG_LC22 or var_LC23 /= REG_LC23) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("50 ")); write(line_out, to_hstring(std_logic_vector(REG_LC23 & REG_LC22)));      writeline(outfile, line_out); var_LC22 := REG_LC22; var_LC23 := REG_LC23; end if;
               if (var_LC31 /= REG_LC31 or var_LC32 /= REG_LC32) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("51 ")); write(line_out, to_hstring(std_logic_vector(REG_LC32 & REG_LC31)));      writeline(outfile, line_out); var_LC31 := REG_LC31; var_LC32 := REG_LC32; end if;
               if (var_LC33 /= REG_LC33                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("52 ")); write(line_out, to_hstring(std_logic_vector(x"0000"  & REG_LC33)));      writeline(outfile, line_out); var_LC33 := REG_LC33; end if;
               if (var_FC0  /= REG_FC0                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("53 ")); write(line_out, to_hstring(std_logic_vector(REG_FC0)));                  writeline(outfile, line_out); var_FC0  := REG_FC0 ; end if;
               if (var_FC1  /= REG_FC1                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("54 ")); write(line_out, to_hstring(std_logic_vector(REG_FC1)));                  writeline(outfile, line_out); var_FC1  := REG_FC1 ; end if;
               if (var_FC2  /= REG_FC2                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("55 ")); write(line_out, to_hstring(std_logic_vector(REG_FC2)));                  writeline(outfile, line_out); var_FC2  := REG_FC2 ; end if;
               if (var_OFX  /= REG_OFX                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("56 ")); write(line_out, to_hstring(std_logic_vector(REG_OFX)));                  writeline(outfile, line_out); var_OFX  := REG_OFX ; end if;
               if (var_OFY  /= REG_OFY                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("57 ")); write(line_out, to_hstring(std_logic_vector(REG_OFY)));                  writeline(outfile, line_out); var_OFY  := REG_OFY ; end if;
               if (var_H    /= REG_H                           ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("58 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_H, 32))));        writeline(outfile, line_out); var_H    := REG_H   ; end if;
               if (var_DQA  /= REG_DQA                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("59 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_DQA, 32))));      writeline(outfile, line_out); var_DQA  := REG_DQA ; end if;
               if (var_DQB  /= REG_DQB                         ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("60 ")); write(line_out, to_hstring(std_logic_vector(REG_DQB)));                  writeline(outfile, line_out); var_DQB  := REG_DQB ; end if;
               if (var_ZSF3 /= REG_ZSF3                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("61 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_ZSF3, 32))));     writeline(outfile, line_out); var_ZSF3 := REG_ZSF3; end if;
               if (var_ZSF4 /= REG_ZSF4                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("62 ")); write(line_out, to_hstring(std_logic_vector(resize(REG_ZSF4, 32))));     writeline(outfile, line_out); var_ZSF4 := REG_ZSF4; end if;
               if (var_FLAG /= REG_FLAG                        ) then if (regcheck = 2) then write(line_out, string'("WRITE REG: ")); end if; if (regcheck = 3) then write(line_out, string'("COMMAND REG: ")); end if; write(line_out, string'("63 ")); write(line_out, to_hstring(std_logic_vector(REG_FLAG)));                 writeline(outfile, line_out); var_FLAG := REG_FLAG; end if;
            end if;
            
            if (gte_cmdEna_1 = '1') then
               write(line_out, string'("COMMAND: 00 ")); 
               write(line_out, to_hstring(gte_cmdData));
               writeline(outfile, line_out);
            end if;
            
            busy_1 := gte_busy;
            gte_writeEna_1 := gte_writeEna and clk2xIndex;
            gte_cmdEna_1   := gte_cmdEna and clk2xIndex;
            
         end loop;
         
      end process;
   
   end generate goutput;
   
   -- synthesis translate_on

end architecture;




