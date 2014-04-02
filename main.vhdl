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
		snesreset, snesclk : in std_logic;

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
	signal clk, reset, refresh, memmode, romen, memstart, txstart, txstep, txinstart, txdone, txerr, card : std_logic;
	signal snesrd0, snesrd1, sneswr0, sneswr1, snescart0, snesreset0, snesclk0 : std_logic;
	signal snesa0 : unsigned(23 downto 0);
	signal romaddr, dmaaddr : unsigned(22 downto 0);
	signal memdata, romdata, txdata, sdreg, dmareg, snesd0, txindata : unsigned(7 downto 0);
	signal memen, cartrd, regen, dmaen : std_logic;
	signal romdata0 : std_logic_vector(7 downto 0);
	signal wrblk : unsigned(31 downto 0);
	
	signal sden : std_logic;
	
	type refcnt_t is range 0 to 127;
	constant thresh : refcnt_t := 64;
	signal rctr : refcnt_t;
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
		snesclk0 <= snesclk;
		if snesclk0 = '0' then
			if rctr < rctr'high then
				rctr <= rctr + 1;
			end if;
		else
			rctr <= 0;
		end if;
	end process;

	refresh <= '1' when rctr > 64 else '0';
	pll0: entity work.pll port map(inclk, clk, reset);
	ramclk <= clk;
	mem0: entity work.mem port map(clk, reset, ramcke, ramcs, ramwe, ramcas, ramras, ramldqm, ramudqm, rama, ramba, ramdq, memmode, memen, romaddr, memdata, txstart, txstep, dmaaddr, txdata, refresh);
	rom0: entity work.rom port map(std_logic_vector(romaddr(14 downto 0)), clk, (others => '0'), '0', romdata0);
	romdata <= unsigned(romdata0);
	regen <= sden or dmaen;
	cartrd <= snesrd0 nor (snescart0 and not regen);
	snesd <= (others => 'Z') when cartrd = '0' else
				sdreg when sden = '1' else
				dmareg when dmaen = '1' else
	         memdata when memen = '1' else
				romdata;
	snesdir <= cartrd;

	sd0: entity work.sd port map(clk, sdclk, sdcd, sdcmd, sddat, sden and not snesrd0, sden and sneswr0 and not sneswr1, snesa0(3 downto 0), snesd0, sdreg, txstart, txstep, txdata, txinstart, txindata, wrblk, txdone, txerr, card);
	dma0: entity work.dma port map(clk, snesreset0, snesa0, snesd0, dmareg, not snesrd0, not sneswr0, not snescart0, romaddr, dmaaddr, memen, sden, dmaen, memmode, txstart, txstep, txdata, txinstart, txindata, wrblk, txdone, txerr, card);
end main;