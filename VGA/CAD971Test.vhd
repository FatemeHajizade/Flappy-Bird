library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CAD971Test is
	Port(
		--//////////// CLOCK //////////
		CLOCK_24 	: in std_logic;
		
		--//////////// KEY //////////
		RESET_N	: in std_logic;
		
		--//////////// 7Seg /////////
		
		seg : out std_logic_vector(7 downto 0);
		an: buffer std_logic_vector(3 downto 0);
		
		--//////////// VGA //////////
		VGA_B		: out std_logic_vector(1 downto 0);
		VGA_G		: out std_logic_vector(1 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(1 downto 0);
		VGA_VS	: out std_logic;
		
		--//////////// KEYS //////////
		Key0 : in std_logic;
		LED : out std_logic_vector(7 downto 0);
		SW : in std_logic_vector(7 downto 0)
	);
end CAD971Test;

--}} End of automatically maintained section

architecture CAD971Test of CAD971Test is

Component VGA_controller
	port ( CLK_24MHz		: in std_logic;
         VS					: out std_logic;
			HS					: out std_logic;
			RED				: out std_logic_vector(1 downto 0);
			GREEN				: out std_logic_vector(1 downto 0);
			BLUE				: out std_logic_vector(1 downto 0);
			RESET				: in std_logic;
			ColorIN			: in std_logic_vector(5 downto 0);
			ScanlineX		: out std_logic_vector(10 downto 0);
			ScanlineY		: out std_logic_vector(10 downto 0)
  );
end component;

Component VGA_Square
	port ( CLK_24MHz		: in std_logic;
			RESET				: in std_logic;
			Kilid				: in std_logic;
			LED				: out std_logic_vector(7 downto 0);
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SquareWidth		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			SevenSeg			: out std_logic_vector(7 downto 0);
			SevenSegEn		: buffer std_logic_vector(3 downto 0)
  );
end component;

signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
signal ColorTable	: std_logic_vector(5 downto 0);

begin

	 --------- VGA Controller -----------
	 VGA_Control: vga_controller
			port map(
				CLK_24MHz	=> CLOCK_24,
				VS				=> VGA_VS,
				HS				=> VGA_HS,
				RED			=> VGA_R,
				GREEN			=> VGA_G,
				BLUE			=> VGA_B,
				RESET			=> not RESET_N,
				ColorIN		=> ColorTable,
				ScanlineX	=> ScanlineX,
				ScanlineY	=> ScanlineY
			);
		
		--------- Moving Square -----------
		VGA_SQ: VGA_Square
			port map(
				CLK_24MHz		=> CLOCK_24,
				RESET				=> not RESET_N,
				Kilid				=> not Key0,
				LED				=> LED,
				ColorOut			=> ColorTable,
				SquareWidth		=> "00011001",
				ScanlineX		=> ScanlineX,
				ScanlineY		=> ScanlineY,
				SevenSeg			=>	 seg,
				SevenSegEn	=>  an
			);
			
	 

	 
end CAD971Test;
