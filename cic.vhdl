library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cic is
	port(
		clk : in std_logic;
		reset, cicin : in std_logic;
		cicout : out std_logic
	);
end cic;

architecture main of cic is
	signal a, x, bl, p0 : unsigned(3 downto 0);
	signal bm, sp, pch : unsigned(1 downto 0);
	signal pc : unsigned(9 downto 0);
	signal carry : unsigned(0 downto 0);

	signal b : integer;
	type ram_t is array(31 downto 0) of unsigned(3 downto 0);
	signal mem : ram_t;
	type stack_t is array(3 downto 0) of unsigned(9 downto 0);
	signal stack : stack_t;
	type rom_t is array(511 downto 0) of unsigned(7 downto 0);
	signal rom : rom_t := (
X"00", X"80", X"78", X"cb", X"21", X"00", X"46", X"27", X"00", X"35", X"00", X"d3", X"75", X"31", X"7c", X"4a", 
X"21", X"00", X"a1", X"30", X"c1", X"00", X"01", X"70", X"00", X"d4", X"21", X"41", X"46", X"00", X"34", X"70", 
X"20", X"30", X"00", X"34", X"9b", X"fa", X"48", X"30", X"c1", X"93", X"00", X"00", X"00", X"5d", X"79", X"21", 
X"e1", X"00", X"67", X"00", X"01", X"46", X"3d", X"2e", X"30", X"00", X"46", X"21", X"fd", X"62", X"31", X"46", 
X"7c", X"33", X"e4", X"3c", X"00", X"4c", X"21", X"46", X"46", X"73", X"7d", X"20", X"00", X"2b", X"4c", X"43", 
X"46", X"4a", X"42", X"5d", X"33", X"00", X"00", X"46", X"00", X"00", X"b4", X"38", X"42", X"46", X"32", X"55", 
X"27", X"01", X"00", X"74", X"00", X"55", X"00", X"55", X"75", X"30", X"20", X"00", X"ae", X"42", X"b8", X"67", 
X"30", X"2b", X"00", X"66", X"21", X"30", X"31", X"f6", X"23", X"de", X"30", X"75", X"46", X"21", X"20", X"80", 
X"00", X"80", X"80", X"bd", X"bf", X"00", X"d7", X"61", X"55", X"10", X"00", X"00", X"23", X"60", X"d9", X"a1", 
X"df", X"00", X"5d", X"55", X"5d", X"00", X"00", X"46", X"7d", X"4a", X"d9", X"23", X"46", X"7c", X"01", X"7c", 
X"d9", X"5d", X"00", X"20", X"6c", X"46", X"5c", X"00", X"f5", X"68", X"00", X"74", X"7d", X"00", X"41", X"dd", 
X"7c", X"74", X"47", X"4c", X"4c", X"7c", X"40", X"7d", X"f0", X"41", X"b0", X"d7", X"d7", X"5d", X"cb", X"5c", 
X"30", X"7c", X"fe", X"d7", X"21", X"00", X"55", X"7c", X"20", X"41", X"41", X"00", X"fa", X"41", X"00", X"b1", 
X"60", X"64", X"64", X"47", X"61", X"4c", X"fa", X"78", X"d9", X"75", X"20", X"f0", X"7d", X"30", X"65", X"74", 
X"21", X"bd", X"4c", X"4a", X"4a", X"55", X"75", X"55", X"fa", X"21", X"c1", X"4b", X"61", X"27", X"f0", X"7d", 
X"46", X"7d", X"30", X"64", X"d7", X"60", X"fa", X"cb", X"80", X"de", X"00", X"75", X"fc", X"7d", X"31", X"80", 
X"00", X"80", X"78", X"74", X"42", X"fe", X"00", X"00", X"31", X"39", X"78", X"42", X"00", X"6a", X"c8", X"42", 
X"75", X"36", X"42", X"3d", X"31", X"41", X"3f", X"00", X"3b", X"68", X"65", X"3f", X"42", X"7c", X"3f", X"60", 
X"3b", X"41", X"42", X"da", X"36", X"3e", X"3a", X"42", X"69", X"3c", X"3c", X"3e", X"3d", X"37", X"6b", X"7c", 
X"21", X"42", X"65", X"30", X"35", X"da", X"42", X"42", X"3b", X"3a", X"30", X"da", X"61", X"42", X"31", X"21", 
X"78", X"21", X"38", X"83", X"42", X"31", X"7c", X"34", X"22", X"42", X"42", X"7c", X"31", X"42", X"31", X"30", 
X"42", X"65", X"42", X"38", X"00", X"42", X"42", X"c8", X"3f", X"42", X"42", X"38", X"42", X"65", X"30", X"31", 
X"80", X"75", X"3e", X"42", X"39", X"da", X"42", X"7c", X"31", X"42", X"7c", X"31", X"41", X"37", X"35", X"63", 
X"7d", X"36", X"42", X"c8", X"42", X"62", X"7c", X"30", X"fa", X"31", X"34", X"7c", X"e1", X"c8", X"75", X"80", 
X"00", X"80", X"78", X"69", X"00", X"00", X"d0", X"42", X"00", X"00", X"00", X"00", X"20", X"64", X"72", X"f4", 
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"ef", X"00", X"40", X"20", X"00", X"00", X"08", X"67", X"52", 
X"4c", X"00", X"00", X"37", X"00", X"00", X"00", X"00", X"30", X"00", X"00", X"00", X"00", X"00", X"4c", X"4a", 
X"72", X"00", X"57", X"00", X"00", X"55", X"00", X"00", X"00", X"00", X"42", X"5d", X"42", X"55", X"4a", X"2f", 
X"78", X"00", X"00", X"01", X"00", X"00", X"4a", X"4d", X"00", X"00", X"00", X"5d", X"00", X"00", X"00", X"72", 
X"68", X"60", X"00", X"00", X"4a", X"00", X"00", X"52", X"4a", X"00", X"00", X"00", X"00", X"0f", X"70", X"40", 
X"80", X"00", X"00", X"00", X"00", X"5c", X"00", X"54", X"6a", X"00", X"23", X"49", X"52", X"00", X"00", X"5c", 
X"74", X"00", X"00", X"42", X"4c", X"72", X"c3", X"48", X"7d", X"73", X"20", X"21", X"bf", X"72", X"75", X"80"
);
	signal loadpc, skip : std_logic;
begin
	b <= to_integer(bm & bl);
	cicout <= p0(0);
	p0(1) <= cicin;
	p0(2) <= '0';
	p0(3) <= '0';
	process(clk)
		variable op : unsigned(7 downto 0);
		variable tmp : unsigned(4 downto 0);
		variable jumped : std_logic;
	begin
		if rising_edge(clk) then
			if loadpc = '1' then
				pc(8 downto 7) <= pch;
				pc(6 downto 0) <= rom(to_integer(pc))(6 downto 0);
				jumped := '1';
			else
				jumped := '0';
				skip <= '0';
			end if;
			if reset = '1' then
				pc <= (others => '0');
			end if;
			if loadpc = '1' or skip = '1' or reset = '1' then
				op := X"00";
			else
				op := rom(to_integer(pc));
			end if;
			loadpc <= '0';
			case op(7 downto 4) is
			when X"0" =>
				tmp := ('0' & a) + ('0' & op(3 downto 0));
				a <= tmp(3 downto 0);
				skip <= tmp(4);
			when X"1" =>
				if a = op(3 downto 0) then
					skip <= '1';
				end if;
			when X"2" =>
				bl <= op(3 downto 0);
			when X"3" =>
				a <= op(3 downto 0);
			when X"4" | X"5" | X"6" | X"7" =>
				case op is
				when X"40" => a <= mem(b);
				when X"41" => a <= mem(b); mem(b) <= a;
				when X"42" =>
					a <= mem(b);
					mem(b) <= a;
					bl <= bl + 1;
					if bl = X"F" then
						skip <= '1';
					end if;
				when X"43" =>
					a <= mem(b);
					mem(b) <= a;
					bl <= bl - 1;
					if bl = X"0" then
						skip <= '1';
					end if;
				when X"44" => a <= (not a) + 1;
				when X"46" =>
					if bl = X"0" then
						p0(0) <= a(0);
					end if;
				when X"47" =>
					if bl = X"0" then
						p0(0) <= '0';
					end if;
				when X"48" => carry <= "1";
				when X"49" => carry <= "0";
				when X"4C" =>
					pc <= stack(to_integer(sp));
					jumped := '1';
					sp <= sp + 1;
				when X"4D" =>
					pc <= stack(to_integer(sp));
					sp <= sp + 1;
					jumped := '1';
					skip <= '1';
				when X"52" =>
					a <= mem(b);
					bl <= bl + 1;
					if bl = X"F" then
						skip <= '1';
					end if;
				when X"55" =>
					if bl = X"0" then
						a <= p0;
					else
						a <= X"0";
					end if;
				when X"54" => a <= not a;
				when X"57" => a <= bl; bl <= a;
				when X"5C" => x <= a;
				when X"5D" => x <= a; a <= x;
				when X"60" => skip <= mem(b)(0);
				when X"61" => skip <= mem(b)(1);
				when X"62" => skip <= mem(b)(2);
				when X"63" => skip <= mem(b)(3);
				when X"64" => skip <= a(0);
				when X"65" => skip <= a(1);
				when X"66" => skip <= a(2);
				when X"67" => skip <= a(3);
				when X"68" => mem(b)(0) <= '0';
				when X"69" => mem(b)(1) <= '0';
				when X"6A" => mem(b)(2) <= '0';
				when X"6B" => mem(b)(3) <= '0';
				when X"6C" => mem(b)(0) <= '1';
				when X"6D" => mem(b)(1) <= '1';
				when X"6E" => mem(b)(2) <= '1';
				when X"6F" => mem(b)(3) <= '1';
				when X"70" => a <= a + mem(b);
				when X"72" => a <= a + mem(b) + carry;
				when X"73" =>
					tmp := ('0' & a) + ('0' & mem(b)) + ("0000" & carry);
					a <= tmp(3 downto 0);
					skip <= tmp(4);
				when X"74" => bm <= "00";
				when X"75" => bm <= "01";
				when X"76" => bm <= "10";
				when X"77" => bm <= "11";
				when X"78" => pch <= "00"; loadpc <= '1';
				when X"79" => pch <= "01"; loadpc <= '1';
				when X"7a" => pch <= "10"; loadpc <= '1';
				when X"7b" => pch <= "11"; loadpc <= '1';
				when X"7c" | X"7d" | X"7e" | X"7f" =>
					pch <= op(1 downto 0);
					loadpc <= '1';
					stack(to_integer(sp - 1)) <= pc;
					sp <= sp - 1;
				when others =>
				end case;
			when others =>
				pc(6 downto 0) <= op(6 downto 0);
				jumped := '1';
			end case;
			if jumped = '0' then
				pc(6 downto 0) <= (pc(0) xnor pc(1)) & pc(6 downto 1);
			end if;
		end if;
	end process;
end main;