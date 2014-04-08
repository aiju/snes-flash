library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma is
	port(
		clk : in std_logic;
		snesreset : in std_logic;
		
		addr : in unsigned(23 downto 0);
		datin : in unsigned(7 downto 0);
		datout : out unsigned(7 downto 0);
		
		rd, wr, cart : in std_logic;
		
		romaddr : out unsigned(22 downto 0);
		dmaaddr : buffer unsigned(22 downto 0);

		memen, sden, dmaen : out std_logic;
		memmode : buffer std_logic;
		
		txstart, txstep : in std_logic;
		txdata : in unsigned(7 downto 0);
		
		txinstart : out std_logic;
		txindata : out unsigned(7 downto 0);
		wrblk : out unsigned(31 downto 0);
		
		txdone, txerr, card : in std_logic;
		
		spice : out std_logic := '1';
		spisck, spisi : out std_logic := '0';
		spiso : in std_logic
	);
end dma;

architecture main of dma is
	signal hirom, booten, sramen, regen, bat, armed1, armed2 : std_logic;
	signal romaddr0, rommask : unsigned(22 downto 0);
	signal rammask, ramaddr0, ramaddr, curaddr : unsigned(15 downto 0);
	signal regout, ramout : unsigned(7 downto 0);
	
	type state_t is (IDLE, READBLK, CHECKBLK, WRITEBLK, WAITDONE);
	signal state : state_t;
	constant nsram : integer := 16;
	type sram_t is array(0 to (512 * nsram - 1)) of unsigned(7 downto 0);
	signal sram : sram_t;
	signal dirty : unsigned(nsram - 1 downto 0) := (others => '0');
	signal writeout : std_logic := '0';
	type blocks_t is array(0 to nsram - 1) of unsigned(31 downto 0);
	signal blocks : blocks_t := (others => (others => '1'));
	signal blk : unsigned(23 downto 0);
	signal nblk : unsigned(7 downto 0);
	
	constant SAVETIME : integer := 100000000 / 2;
	signal saveclk : integer := 0;
	signal flush : std_logic;
	
	signal spibuf : unsigned(7 downto 0);
	signal spictr : unsigned(4 downto 0);
begin
	process
	begin
		wait until rising_edge(clk);
		
		flush <= '0';
		if wr = '1' and regen = '1' then
			case to_integer(addr(3 downto 0)) is
			when 0 =>
				memmode <= datin(0);
				booten <= not datin(1);
				hirom <= datin(2);
				if armed1 = '1' and armed2 = '1' then
					bat <= datin(3);
				end if;
				if datin(4) = '1' then
					flush <= '1';
				end if;
				spice <= not datin(5);
			when 1 =>
				dmaaddr(15 downto 8) <= datin;
			when 2 =>
				dmaaddr(22 downto 16) <= datin(6 downto 0);
			when 3 =>
				rommask(15 downto 8) <= datin;
			when 4 =>
				rommask(22 downto 16) <= datin(6 downto 0);
			when 5 =>
				rammask(15 downto 8) <= datin;
			when 6 =>
				nblk <= datin;
			when 7 =>
				if armed1 = '1' and armed2 = '1' then
					blk(7 downto 0) <= datin;
				end if;
			when 8 =>
				if armed1 = '1' and armed2 = '1' then
					blk(15 downto 8) <= datin;
				end if;
			when 9 =>
				if armed1 = '1' and armed2 = '1' then
					blk(23 downto 16) <= datin;
				end if;
			when 10 =>
				if armed1 = '1' and armed2 = '1' then
					blocks(to_integer(nblk)) <= datin & blk;
				end if;
			when 11 =>
				if datin = X"37" then
					armed1 <= '1';
				else
					armed1 <= '0';
				end if;
			when 12 =>
				if datin = X"13" then
					armed2 <= '1';
				else
					armed2 <= '0';
				end if;
			when others =>
			end case;
		end if;
		
		if snesreset = '0' then
			armed1 <= '0';
			armed2 <= '0';
			booten <= '1';
			spice <= '1';
			rommask(22 downto 8) <= (others => '1');
		end if;
		if card = '0' then
			bat <= '0';
		end if;
	end process;
	
	process
	begin
		wait until rising_edge(clk);
	
		if rd = '1' and regen = '1' then
			regout <= (others => '0');
			case to_integer(addr(3 downto 0)) is
			when 0 =>
				if state /= IDLE then
					regout(7) <= '0';
				else
					regout(7) <= '1';
				end if;
			when 6 =>
				regout <= nblk;
			when 13 =>
				regout <= spibuf;
			when others =>
			end case;
		end if;
	end process;
	
	process
	begin
		wait until rising_edge(clk);

		ramout <= sram(to_integer(ramaddr));
		txindata <= sram(to_integer(curaddr));
		wrblk <= blocks(to_integer(curaddr(15 downto 9)));
		if wr = '1' and sramen = '1' then
			sram(to_integer(ramaddr)) <= datin;
		end if;
		if bat = '1' and saveclk = 0 and dirty /= (nsram - 1 downto 0 => '0') and state = IDLE then
			saveclk <= SAVETIME;
		end if;
		if saveclk /= 0 then
			saveclk <= saveclk - 1;
		end if;
		if flush = '1' then
			saveclk <= 0;
		end if;
	end process;
	
	process
		variable ctr : integer;
	begin
		wait until rising_edge(clk);
		
		case state is
		when IDLE =>
			txinstart <= '0';
			if txstart = '1' and memmode = '0' then
				curaddr <= dmaaddr(15 downto 0);
				dirty(to_integer(dmaaddr(15 downto 9))) <= '0';
				state <= READBLK;
			end if;
			if writeout = '1' then
				state <= CHECKBLK;
				curaddr <= (others => '0');
				writeout <= '0';
			end if;
		when READBLK =>
			if txstep = '1' then
				sram(to_integer(curaddr)) <= txdata;
				curaddr <= curaddr + 1;
			end if;
			if txstart = '0' then
				state <= IDLE;
			end if;
		when CHECKBLK =>
			ctr := to_integer(curaddr(15 downto 9));
			if ctr = nsram then
				state <= IDLE;
				txinstart <= '0';
			elsif dirty(ctr) = '1' then
				dirty(ctr) <= '0';
				state <= WRITEBLK;
				curaddr(8 downto 0) <= (others => '0');
				txinstart <= '1';
			else
				txinstart <= '0';
				curaddr <= curaddr + X"0200";
			end if;
		when WRITEBLK =>
			if txstep = '1' then
				curaddr(8 downto 0) <= curaddr(8 downto 0) + 1;
				if curaddr(8 downto 0) = "111111111" then
					state <= WAITDONE;
					txinstart <= '0';
				end if;
			end if;
			if txdone = '1' then
				state <= WAITDONE;
			end if;
		when WAITDONE =>
			if txdone = '1' then
				if txerr = '1' then
					dirty(to_integer(curaddr(15 downto 9))) <= '1';
				end if;
				curaddr <= curaddr + X"0200";
				state <= CHECKBLK;
			end if;
		end case;
		if bat = '1' and (saveclk = 1 or flush = '1') then
			writeout <= '1';
		else
			writeout <= '0';
		end if;
		if wr = '1' and sramen = '1' then
			dirty(to_integer(ramaddr(15 downto 9))) <= '1';
		end if;
		if bat = '0' and flush = '1' then
			dirty <= (others => '0');
		end if;
	end process;

	rammask(7 downto 0) <= (others => '1');
	rommask(7 downto 0) <= (others => '1');
	dmaaddr(7 downto 0) <= (others => '0');
	
	romaddr0 <= addr(23) & addr(21 downto 0) when hirom = '1' else addr(23 downto 16) & addr(14 downto 0);
	romaddr <= romaddr0 and rommask;
	ramaddr0 <= addr(18 downto 16) & addr(12 downto 0) when hirom = '1' else addr(16) & addr(14 downto 0);
	ramaddr <= ramaddr0 and rammask;

	datout <= regout when regen = '1' else ramout;
	sden <= booten when (addr and X"40FFF0") = X"003000" else '0';
	regen <= booten when (addr and X"40FFF0") = X"003010" else '0';
	sramen <= snesreset and addr(21) and
		((hirom and addr(14) and addr(13) and not addr(22) and not cart) or (not hirom and addr(20) and addr(22) and not addr(15) and cart));
	dmaen <= regen or sramen;
	memen <= (rd and cart) when booten = '0' or addr(23 downto 16) /= "00000000" else '0';
	
	process
	begin
		wait until rising_edge(clk);
		
		if spictr /= "00000" then
			case spictr(1 downto 0) is
			when "00" =>
			when "01" =>
				spisck <= '1';
			when "10" =>
				spibuf <= spibuf(6 downto 0) & spiso;
			when "11" =>
				spisi <= spibuf(7);
				spisck <= '0';
			end case;
			spictr <= spictr + 1;
		elsif wr = '1' and regen = '1' and addr(3 downto 0) = X"D" then
			spictr <= spictr + 1;
			spisi <= datin(7);
			spibuf <= datin;
		end if;
	end process;
end main;