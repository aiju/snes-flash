library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity snes is
	port(
		clk : in std_logic;
		sddat2 : out std_logic;
		snesdir : out std_logic;
		cicin, cicclk, cicreset : in std_logic;
		cicout : out std_logic
	);
end snes;

architecture main of snes is
begin
	snesdir <= '0';
	sddat2 <= cicin;
	cic0: entity work.cic port map(cicclk, cicreset, cicin, cicout);
end main;