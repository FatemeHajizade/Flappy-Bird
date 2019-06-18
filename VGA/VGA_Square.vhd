library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Square is
  port ( CLK_24MHz		: in std_logic;
			RESET				: in std_logic;
			Kilid				: in std_logic;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SquareWidth		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			SevenSeg			: out std_logic_vector(7 downto 0):=(others=>'1');
			SevenSegEn		: buffer std_logic_vector(3 downto 0):=(others=>'1');
			LED				: out std_logic_vector(7 downto 0) := (others=>'0')
			);
end VGA_Square;

architecture Behavioral of VGA_Square is
	 
	signal ColorOutput: std_logic_vector(5 downto 0);
	signal SquareX: std_logic_vector(8 downto 0) := "001100100";  
	signal SquareY: std_logic_vector(8 downto 0) := "011111010"; 
	signal BarrierX: std_logic_vector(9 downto 0) := "1000110000";
	signal BarrierX2:std_logic_vector(9 downto 0);
	signal BarrierWidth	: std_logic_vector(7 downto 0):= "00010010";  
	signal Prescaler: unsigned(32 downto 0) := (others => '0');
	signal scaler: std_logic_vector(32 downto 0) := (others => '0');
	signal clk: std_logic := '0';
	signal pseudo_rand: std_logic_vector(31 downto 0) := ("01000111001010101010010101010010");
	signal randomint: std_logic_vector(9 downto 0) := ("0100000000");
	signal randomint2: std_logic_vector(9 downto 0) := (others =>'0');
	signal didCollide: std_logic :='0';
	signal Didwin: std_logic :='0';
	signal PassedCounter: unsigned(6 downto 0) :=(others=>'0');
	type myFSM is (SWait,GameOn,Ended);   
	signal PresentState : myFSM :=Swait;
	signal Counter: unsigned(6 downto 0) := (others=>'0');
	type ButtFSM is (Tamam, JustHit);
	signal PresButt: ButtFSM := Tamam;
	Signal Jump: integer := 20;
  
	function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
	begin
		return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
	end function;
	
begin
	process(CLK_24MHz, reset)
	begin
		if rising_edge(CLK_24MHz) then
			pseudo_rand <= lfsr32(pseudo_rand);
		end if;
	end process;

	process(CLK_24MHz, reset)
	variable c: integer := 0;
	variable Speed: integer := 720000; --0.03 sec
	begin		
		if reset = '1' then
			c := 0;
			Speed := 720000; --0.03 sec
			Jump <= 20;
			SquareX <= "001100100";
			SquareY <= "011111010";
			didCollide<='0';
			didWin<='0';
			PassedCounter<=(others=>'0');
			BarrierX <= "1000110000";
			BarrierX2 <= BarrierX - 530;

		elsif rising_edge(CLK_24MHz) and PresentState = GameOn then
			c := c + 1;	 
			if c = Speed then
				case PresButt is
					when Tamam => if kilid='1' then PresButt <= JustHit; end if;
					when JustHit => if kilid='0' then PresButt <= Tamam; end if;
				end case;
				
				if PresButt = Tamam then
					if kilid = '1' and SquareY>=20 then
						SquareY <= SquareY-Jump;
					elsif kilid ='0' and SquareY+SquareWidth>=479 then
						SquareY <= SquareY+1;
					end if;
				end if;
				
				if PresButt = JustHit then
					if SquareY+SquareWidth <= 479 then
						SquareY <= SquareY+1;
					end if;
				end if;

				BarrierX <= BarrierX - 1;
				BarrierX2 <= BarrierX - 530;
			
				if BarrierX = "1010111100" then -- 700
					if pseudo_rand(8 downto 0) > "110010000" then -- >400
						randomint <= '0' & pseudo_rand(8 downto 0) - "0001111111"; --127
					elsif pseudo_rand(8 downto 0) < "000000110" then -- <5
						randomint <= '0' & pseudo_rand(8 downto 0) + "000000110"; --5
					else		
						randomint <= '0' & pseudo_rand(8 downto 0);
					end if;
				end if;
				
				if BarrierX2 = "1010111100" then --700
					if pseudo_rand(8 downto 0) > "110010000" then --400
						randomint2 <= '0' & pseudo_rand(8 downto 0) - "0001111111"; --127
					elsif pseudo_rand(8 downto 0) < "000000110" then -- <5
						randomint2 <= '0' & pseudo_rand(8 downto 0) + "000000110"; --5
					else		
						randomint2 <= '0' & pseudo_rand(8 downto 0);
					end if;
				end if;
				
				if Counter = "0010000" then
					Speed := 360000; --0.015 sec
					Jump <= 30;
				elsif Counter = "0011111" then
					Speed := 180000; --0.0075 sec
				elsif Counter = "0101101" then
					Speed := 90000; --0.0025 sec
				elsif Counter = "0111100" then
					Speed := 45000; --0.00375 sec
				elsif Counter = "1001011" then
					Speed := 22500; --0.0001875 sec
				elsif Counter = "1011010" then
					Speed := 11250; --0.00009375 sec
				end if;
				
				if (((SquareX+SquareWidth>=BarrierX and SquareX+SquareWidth<=BarrierX+BarrierWidth) or (SquareX<=BarrierX+BarrierWidth and SquareX>=BarrierX)) and (SquareY<randomint or SquareY+SquareWidth>randomint+SquareWidth+SquareWidth+SquareWidth)) or (((SquareX+SquareWidth>=BarrierX2 and SquareX+SquareWidth<=BarrierX2+BarrierWidth) or (SquareX<=BarrierX2+BarrierWidth and SquareX>=BarrierX2)) and (SquareY<randomint2 or SquareY+SquareWidth>randomint2+SquareWidth+SquareWidth+SquareWidth)) then	
					didCollide<='1';
				end if;
				
				if SquareX = BarrierX+BarrierWidth or SquareX = BarrierX2+BarrierWidth then
					PassedCounter <= PassedCounter + 1;
					if PassedCounter = "0001001" or Counter="1100011" then
						Didwin<='1';
					else
						DidWin<=DidWin;
					end if;
				end if;
				
				c := 0;
			end if;	
		end if;
	end process PrescalerCounter; 
	
	FSM: process(CLK_24MHZ,reset)
	begin
		if reset='1' then PresentState<=Swait;
		elsif rising_edge(CLK_24MHZ) then
			case PresentState is
				when Swait => if kilid='1' then PresentState<=GameOn; end if;
				when GameOn =>	if didCollide='1' or Didwin='1' then PresentState<=Ended; end if;
				when Ended =>	PresentState<=Ended;
			end case;
		end if;
	end process FSM;

	process(CLK_24MHZ,reset)
	variable count : integer;
	begin
		if reset = '1' then
			count := 0;
			clk <= '0';
		elsif rising_edge(CLK_24MHZ) then
			if count = 24000000 then
				count := 0;
				clk <= not(clk);
			else	
				count := count + 1;
			end if;
		end if;
	end process;
	
	CounterFSM: process(clk,reset)
	begin
		if reset='1' then Counter <= (others=>'0');
		elsif rising_edge(clk) and PresentState = GameOn then
				if Counter = "1100011" then
					Counter <= (others=>'0');
				else
					Counter <= Counter + 1;
				end if;
		end if;
	end process;
		
	Seg: process(CLK_24MHZ,reset)
	variable yekan: unsigned(6 downto 0) := "0000000";
	variable dahgan: unsigned(6 downto 0) := "0000000";
	variable yekan2: unsigned(6 downto 0) := "0000000";
	variable dahgan2: unsigned(6 downto 0) := "0000000";
	begin
		if reset='1' then
			SevenSeg <= "00000000";
			SevenSegEn <= "1110";
			LED <= "00000000";
			scaler <= (others => '0');
		elsif rising_edge(CLK_24MHZ) then
			scaler <= scaler + 1;
			if scaler = "0001001110001000" and PresentState = Swait then -- 0.05sec
				if SevenSegEn = "0111" then SevenSeg<="11000000"; SevenSegEn<="1110";
				elsif SevenSegEn = "1110" then SevenSeg<="10110000"; SevenSegEn<="1101";
				elsif SevenSegEn = "1101" then SevenSeg<="10110000"; SevenSegEn<="1011";
				elsif SevenSegEn = "1011" then SevenSeg<="10110000"; SevenSegEn<="0111";
				else SevenSeg<="11111111";
				end if;
				scaler <= (others => '0');
			elsif scaler = "0001001110001000" and PresentState = GameOn then
				yekan := Counter rem "0001010";
				dahgan := Counter/"0001010";
				yekan2 := PassedCounter rem "0001010";
				dahgan2 := PassedCounter/"0001010";
				
				if SevenSegEn = "1011" then
					if yekan2 = "0000" then SevenSeg<="11000000"; SevenSegEn<="0111";
					elsif yekan2 = "0001" then SevenSeg<="11111001"; SevenSegEn<="0111";
					elsif yekan2 = "0010" then SevenSeg<="10100100"; SevenSegEn<="0111";
					elsif yekan2 = "0011" then SevenSeg<="10110000"; SevenSegEn<="0111";
					elsif yekan2 = "0100" then SevenSeg<="10011001"; SevenSegEn<="0111";
					elsif yekan2 = "0101" then SevenSeg<="10010010"; SevenSegEn<="0111";
					elsif yekan2 = "0110" then SevenSeg<="10000010"; SevenSegEn<="0111";
					elsif yekan2 = "0111" then SevenSeg<="11111000"; SevenSegEn<="0111";
					elsif yekan2 = "1000" then SevenSeg<="10000000"; SevenSegEn<="0111";
					elsif yekan2 = "1001" then SevenSeg<="10010000"; SevenSegEn<="0111";
					else SevenSeg<="11111111";
					end if;				
				elsif SevenSegEn = "1101" then
					if dahgan2 = "0000" then SevenSeg<="11000000"; SevenSegEn<="1011";
					elsif dahgan2 = "0001" then SevenSeg<="11111001"; SevenSegEn<="1011";
					elsif dahgan2 = "0010" then SevenSeg<="10100100"; SevenSegEn<="1011";
					elsif dahgan2 = "0011" then SevenSeg<="10110000"; SevenSegEn<="1011";
					elsif dahgan2 = "0100" then SevenSeg<="10011001"; SevenSegEn<="1011";
					elsif dahgan2 = "0101" then SevenSeg<="10010010"; SevenSegEn<="1011";
					elsif dahgan2 = "0110" then SevenSeg<="10000010"; SevenSegEn<="1011";
					elsif dahgan2 = "0111" then SevenSeg<="11111000"; SevenSegEn<="1011";
					elsif dahgan2 = "1000" then SevenSeg<="10000000"; SevenSegEn<="1011";
					elsif dahgan2 = "1001" then SevenSeg<="10010000"; SevenSegEn<="1011";
					else SevenSeg<="11111111";
					end if;				
				elsif SevenSegEn = "1110" then
					if yekan = "0000000" then SevenSeg<="11000000"; SevenSegEn<="1101";
					elsif yekan = "0000001" then SevenSeg<="11111001"; SevenSegEn<="1101";
					elsif yekan = "0000010" then SevenSeg<="10100100"; SevenSegEn<="1101";
					elsif yekan = "0000011" then SevenSeg<="10110000"; SevenSegEn<="1101";
					elsif yekan = "0000100" then SevenSeg<="10011001"; SevenSegEn<="1101";
					elsif yekan = "0000101" then SevenSeg<="10010010"; SevenSegEn<="1101";
					elsif yekan = "0000110" then SevenSeg<="10000010"; SevenSegEn<="1101";
					elsif yekan = "0000111" then SevenSeg<="11111000"; SevenSegEn<="1101";
					elsif yekan = "0001000" then SevenSeg<="10000000"; SevenSegEn<="1101";
					elsif yekan = "0001001" then SevenSeg<="10010000"; SevenSegEn<="1101";
					else SevenSeg<="11111111";
					end if;
				elsif SevenSegEn = "0111" then
					if dahgan = "0000000" then SevenSeg<="11000000"; SevenSegEn<="1110";
					elsif dahgan = "0000001" then SevenSeg<="11111001"; SevenSegEn<="1110";
					elsif dahgan = "0000010" then SevenSeg<="10100100"; SevenSegEn<="1110";
					elsif dahgan = "0000011" then SevenSeg<="10110000"; SevenSegEn<="1110";
					elsif dahgan = "0000100" then SevenSeg<="10011001"; SevenSegEn<="1110";
					elsif dahgan = "0000101" then SevenSeg<="10010010"; SevenSegEn<="1110";
					elsif dahgan = "0000110" then SevenSeg<="10000010"; SevenSegEn<="1110";
					elsif dahgan = "0000111" then SevenSeg<="11111000"; SevenSegEn<="1110";
					elsif dahgan = "0001000" then SevenSeg<="10000000"; SevenSegEn<="1110";
					elsif dahgan = "0001001" then SevenSeg<="10010000"; SevenSegEn<="1110";
					else SevenSeg<="11111111";
					end if;
				else SevenSeg<="11111111";
				end if;		
				scaler <= (others => '0');
			elsif  scaler = "0001001110001000" and PresentState = Ended and Didwin = '1' then
				LED <= "11111111";
				if SevenSegEn = "0111" then SevenSeg<="11111111"; SevenSegEn<="1110";
				elsif SevenSegEn = "1110" then SevenSeg<="10000110"; SevenSegEn<="1101";
				elsif SevenSegEn = "1101" then SevenSeg<="10101011"; SevenSegEn<="1011";
				elsif SevenSegEn = "1011" then SevenSeg<="10100001"; SevenSegEn<="0111";
				else SevenSeg<="11111111";
				end if;
				scaler <= (others => '0');
			elsif scaler = "11111111111111111111" and PresentState = Ended and DidCollide = '1' then
				LED <= "11111111";
				if SevenSegEn = "0111" then SevenSeg<="11000111"; SevenSegEn<="1110";
				elsif SevenSegEn = "1110" then SevenSeg<="11000000"; SevenSegEn<="1101";
				elsif SevenSegEn = "1101" then SevenSeg<="10010010"; SevenSegEn<="1011";
				elsif SevenSegEn = "1011" then SevenSeg<="10000110"; SevenSegEn<="0111";
				else SevenSeg<="11111111";
				end if;
				scaler <= (others=>'0');			
			end if;
		end if;
	end Process;	
		
	ColorOutput <=		"110011" when ScanlineX >= SquareX AND ScanlineY >= SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth  
					else	"000000" when ScanlineX >= BarrierX AND ScanlineX < (BarrierX+BarrierWidth) AND (ScanlineY < randomint OR ScanlineY > randomint+SquareWidth+SquareWidth+SquareWidth) 
					else  "000000" when ScanlineX >= BarrierX2 AND ScanlineX < (BarrierX2+BarrierWidth) AND (ScanlineY < randomint2 OR ScanlineY > randomint2+SquareWidth+SquareWidth+SquareWidth)
					else "111111";

	ColorOut <= ColorOutput;
end Behavioral;