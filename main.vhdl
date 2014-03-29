library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity snes is
	port(
		inclk : in std_logic;

		snesdir : out std_logic;
		snesa : in unsigned(23 downto 0);
		snesd : inout unsigned(7 downto 0);
		snesrd, sneswr, snescart : in std_logic;
		snesreset : in std_logic;

		ramclk, ramcke, ramcs, ramwe : out std_logic;
		ramcas, ramras, ramldqm, ramudqm : out std_logic;
		rama : out unsigned(11 downto 0);
		ramba : out unsigned(1 downto 0);
		ramdq : inout unsigned(15 downto 0);

		sdclk : out std_logic;
		sdcmd : inout std_logic;
		sddat : inout unsigned(3 downto 0);
		sdcd : in std_logic
	);
end snes;

architecture main of snes is
	signal clk, reset, memmode, romen, memstart, txstart, txstep : std_logic;
	signal snesrd0, snesrd1, sneswr0, sneswr1, snescart0, snesreset0 : std_logic;
	signal snesa0 : unsigned(23 downto 0);
	signal romaddr, dmaaddr : unsigned(22 downto 0);
	signal memdata, romdata, txdata, sdreg, dmareg, snesd0 : unsigned(7 downto 0);
	signal memen, cartrd, regen, dmaen : std_logic;
	signal romdata0 : std_logic_vector(7 downto 0);
	
	signal sden : std_logic;
begin
	process
	begin
		wait until rising_edge(clk);
		snesreset0 <= snesreset;
		snescart0 <= snescart;
		snesrd0 <= snesrd;
		sneswr0 <= sneswr;
		sneswr1 <= sneswr0;
		snesa0 <= snesa;
		snesd0 <= snesd;
	end process;

	pll0: entity work.pll port map(inclk, clk, reset);
	ramclk <= clk;
	mem0: entity work.mem port map(clk, reset, ramcke, ramcs, ramwe, ramcas, ramras, ramldqm, ramudqm, rama, ramba, ramdq, memmode, memen, romaddr, memdata, memstart, txstep, dmaaddr, txdata);
	--rom0: entity work.bootrom port map(clk, addr(15 downto 0), romdata);
	rom0: entity work.rom port map(std_logic_vector(romaddr(14 downto 0)), clk, (others => '0'), '0', romdata0);
	romdata <= unsigned(romdata0);
	regen <= sden or dmaen;
	cartrd <= snesrd0 nor (snescart0 and not regen);
	memen <= (snesrd0 nor snescart0) when romen = '0' or snesa0(23 downto 16) /= "00000000" else '0';
	snesd <= (others => 'Z') when cartrd = '0' else
				sdreg when sden = '1' else
				dmareg when dmaen = '1' else
	         memdata when memen = '1' else
				romdata;
	snesdir <= cartrd;
	sden <= '1' when (snesa0 and X"40FFF0") = X"003000" else '0';
	sd0: entity work.sd port map(clk, sdclk, sdcd, sdcmd, sddat, sden and not snesrd0, sden and sneswr0 and not sneswr1, snesa0(3 downto 0), snesd0, sdreg, txstart, txstep, txdata);
	dmaen <= '1' when (snesa0 and X"40FFF0") = X"003010" else '0';
	dma0: entity work.dma port map(clk, snesreset0, snesa0, romaddr, dmaen and not snesrd0, dmaen and sneswr0 and not sneswr1, snesa0(3 downto 0), snesd0, dmareg, dmaaddr, txstart, romen, memmode, memstart);
end main;