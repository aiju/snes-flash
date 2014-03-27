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
		data1 : in unsigned(7 downto 0)
	);
end mem;

architecture main of mem is
	type state_t is (RESETCMD, IDLE, READCMD, WRITECMD);
	signal curaddr : unsigned(22 downto 0);
	signal buf : unsigned(7 downto 0);
	signal state : state_t := RESETCMD;
	signal ctr : unsigned(2 downto 0) := "000";
begin
	data0 <= buf;
	process
	begin
		wait until rising_edge(clk);
		cke <= '1';
		cs <= '0';
		we <= '1';
		cas <= '1';
		ras <= '1';
		a <= (others => '0');
		ba <= (others => '0');
		dq <= (others => 'Z');
		case state is
		when RESETCMD =>
			ctr <= ctr + 1;
			case ctr is
			when "000" =>
				ras <= '0';
				we <= '0';
				a(10) <= '1';
			when "001" | "011" =>
				ras <= '0';
				cas <= '0';
			when "101" =>
				ras <= '0';
				cas <= '0';
				we <= '0';
				a(5) <= '1';
			when "110" =>
				ctr <= "000";
				state <= IDLE;
			when others =>
			end case;
		when IDLE =>
			cs <= '1';
			cke <= '0';
			if mode = '0' and en = '1' and addr0 /= curaddr then
				cke <= '1';
				cs <= '0';
				ctr <= "000";
				state <= READCMD;
				curaddr <= addr0;
			end if;
			if mode = '1' and start = '1' then
				cke <= '1';
				cs <= '0';
				ctr <= "000";
				state <= WRITECMD;
				curaddr <= addr1;
			end if;
		when READCMD =>
			ctr <= ctr + 1;
			case ctr is
			when "001" =>
				ras <= '0';
				ba <= curaddr(22 downto 21);
				a <= curaddr(20 downto 9);
				ldqm <= curaddr(0);
				udqm <= not curaddr(0);
			when "100" =>
				cas <= '0';
				ba <= curaddr(22 downto 21);
				a(7 downto 0) <= curaddr(8 downto 1);
				a(10) <= '1';
			when "111" =>
				if curaddr(0) = '1' then
					buf <= dq(15 downto 8);
				else
					buf <= dq(7 downto 0);
				end if;
				ctr <= "000";
				state <= IDLE;
			when others =>
			end case;
		when WRITECMD =>
			ctr <= ctr + 1;
			case ctr is
			when "001" =>
				ras <= '0';
				ba <= curaddr(22 downto 21);
				a <= curaddr(20 downto 9);
			when "100" =>
				if step = '1' then
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
					ctr <= "100";
				end if;
			when "110" =>
				ras <= '0';
				we <= '0';
				a(10) <= '1';
			when "111" =>
				ctr <= "000";
				state <= IDLE;
			when others =>
			end case;
		end case;
		if reset = '0' then
			state <= RESETCMD;
			ctr <= "000";
			cke <= '0';
		end if;
	end process;
end main;