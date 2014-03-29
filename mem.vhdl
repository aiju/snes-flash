library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem is
	port(
		clk, reset : in std_logic;
		cke, cs, we, cas, ras, ldqm, udqm : out std_logic;
		a : out unsigned(11 downto 0);
		ba : out unsigned(1 downto 0);
		dq : inout unsigned(15 downto 0);
		mode, en : in std_logic;
		addr0 : in unsigned(22 downto 0);
		data0 : out unsigned(7 downto 0);
		start, step : in std_logic;
		addr1 : in unsigned(22 downto 0);
		data1 : in unsigned(7 downto 0);
		refresh : in std_logic
	);
end mem;

architecture main of mem is
	type state_t is (RESETCMD, IDLE, READCMD, WRITECMD, AUTOREFRESH);
	signal curaddr : unsigned(22 downto 0);
	signal buf : unsigned(7 downto 0);
	signal state : state_t := RESETCMD;
	type ctr_t is range 0 to 7;
	constant tRCD : ctr_t := 2;
	constant tCAS : ctr_t := 3;
	constant tRP : ctr_t := 1;
	constant tRC : ctr_t := 5;
	signal ctr : ctr_t;
	signal stepped : std_logic;
begin
	data0 <= buf;
	cke <= '1';
	process
		variable sel : boolean;
		variable addr : unsigned(22 downto 0);
	begin
		wait until rising_edge(clk);
		cs <= '0';
		we <= '1';
		cas <= '1';
		ras <= '1';
		a <= (others => '0');
		ba <= (others => '0');
		dq <= (others => 'Z');
		if mode = '1' and start = '1' and step = '1' then
			stepped <= '1';
		end if;
		case state is
		when RESETCMD =>
			ctr <= ctr + 1;
			case ctr is
			when 0 =>
				ras <= '0';
				we <= '0';
				a(10) <= '1';
			when 1 | 3 =>
				ras <= '0';
				cas <= '0';
			when 5 =>
				ras <= '0';
				cas <= '0';
				we <= '0';
				a(5) <= '1';
			when 6 =>
				state <= IDLE;
			when others =>
			end case;
		when IDLE =>
			sel := false;
			cs <= '1';
			if refresh = '1' and (mode = '0' or start = '0') then
				ctr <= 0;
				cs <= '0';
				ras <= '0';
				cas <= '0';
				state <= AUTOREFRESH;
			end if;
			if mode = '0' and en = '1' and addr0 /= curaddr then
				sel := true;
				state <= READCMD;
				addr := addr0;
			end if;
			if mode = '1' and start = '1' then
				sel := true;
				state <= WRITECMD;
				addr := addr1;
			end if;
			if sel then
				cs <= '0';
				ras <= '0';
				cas <= '1';
				curaddr <= addr;
				ba <= addr(22 downto 21);
				a <= addr(20 downto 9);
				ldqm <= addr(0);
				udqm <= not addr(0);
				ctr <= 0;
			end if;
		when READCMD =>
			ctr <= ctr + 1;
			case ctr is
			when tRCD =>
				cas <= '0';
				ba <= curaddr(22 downto 21);
				a(7 downto 0) <= curaddr(8 downto 1);
				a(10) <= '1';
			when tRCD+tCAS =>
				if curaddr(0) = '1' then
					buf <= dq(15 downto 8);
				else
					buf <= dq(7 downto 0);
				end if;
				state <= IDLE;
			when others =>
			end case;
		when WRITECMD =>
			ctr <= ctr + 1;
			case ctr is
			when tRCD =>
				if step = '1' or stepped = '1' then
					stepped <= '0';
					cas <= '0';
					we <= '0';
					ba <= curaddr(22 downto 21);
					a(7 downto 0) <= curaddr(8 downto 1);
					ldqm <= curaddr(0);
					udqm <= not curaddr(0);
					if curaddr(0) = '1' then
						dq(15 downto 8) <= data1;
					else
						dq(7 downto 0) <= data1;
					end if;
					curaddr <= curaddr + 1;
				end if;
				if start = '1' then
					ctr <= tRCD;
				end if;
			when tRCD+1 =>
				ras <= '0';
				we <= '0';
				a(10) <= '1';
			when tRCD+1+tRP =>
				state <= IDLE;
			when others =>
			end case;
		when AUTOREFRESH =>
			ctr <= ctr + 1;
			if ctr = tRC then
				state <= IDLE;
			end if;
		end case;
		if reset = '0' then
			state <= RESETCMD;
			ctr <= 0;
			cs <= '1';
		end if;
	end process;
end main;