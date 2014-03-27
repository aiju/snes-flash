library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd is
	port(
		clk : in std_logic;
		sdclk : out std_logic;
		sdcd : in std_logic;
		sdcmd : inout std_logic;
		sddat : inout unsigned(3 downto 0);
		regrd, regwr : in std_logic;
		regaddr : in unsigned(3 downto 0);
		regin: in unsigned(7 downto 0);
		regout : out unsigned(7 downto 0);
		txstart, txstep : out std_logic;
		txdata : out unsigned(7 downto 0)
	);
end sd;

architecture main of sd is
	signal div : unsigned(7 downto 0);
	signal clkout, clkin : std_logic;
	signal sdcd0, sdcd1, sdcmd0 : std_logic;
	signal sddat0 : unsigned(3 downto 0);
	signal cdctr : unsigned(23 downto 0);
	signal card : std_logic := '0';
	signal slow : std_logic := '1';
	
	type cmdstate_t is (IDLE, COMMAND, WAITRESP, RESP, RESP2, WAITBUSY, DONE, WAIT0);
	signal cmdstate : cmdstate_t := IDLE;
	signal buf : unsigned(47 downto 0);
	type counter_t is range 0 to 255;
	signal cmdctr, ctr : counter_t;
	signal cmd : unsigned(5 downto 0);
	constant NOOP : unsigned(5 downto 0) := "111111";
	signal arg : unsigned(31 downto 0);
	signal go, failed : std_logic;
	
	type nbyte_t is range 0 to 511;
	signal datbuf : unsigned(3 downto 0);
	type datastate_t is (IDLE, WAITDATA, DATA, CRC);
	signal datastate : datastate_t := IDLE;
	signal nibble : std_logic;
	signal nbyte : nbyte_t;
	signal datago, datastop : std_logic;

	signal response : unsigned(31 downto 0);
	type state_t is (NOCARD, RESET, IDLE, ERROR, READCMD, WAITDATA);
	signal state : state_t := NOCARD;
	signal hc : std_logic;
	
	signal blk : unsigned(31 downto 0);
	signal readblk : std_logic;
begin
	process
	begin
		wait until rising_edge(clk);
		div <= div + 1;
		sdcmd0 <= sdcmd;
		sdcd0 <= sdcd;
		sdcd1 <= sdcd0;
		sddat0 <= sddat;
		if sdcd1 /= card then
			cdctr <= X"000000";
		else
			cdctr <= cdctr + 1;
			if cdctr = X"FFFFFF" then
				card <= not sdcd1;
			end if;
		end if;
	end process;
	sdclk <= div(7) when slow = '1' else div(1);
	clkin <= '1' when (slow = '1' and div = X"81") or (slow = '0' and div(1 downto 0) = "11") else '0';
	clkout <= '1' when (slow = '1' and div = X"FF") or (slow = '0' and div(1 downto 0) = "11") else '0';

	process
	begin
		wait until rising_edge(clk);
		txstep <= '0';
		case datastate is
		when IDLE =>
			if datago = '1' then
				datastate <= WAITDATA;
			end if;
		when WAITDATA =>
			if clkin = '1' and sddat0(0) = '0' then
				datastate <= DATA;
				nibble <= '0';
				nbyte <= 0;
				txstart <= '1';
			end if;
			if datastop = '1' then
				txstart <= '0';
				datastate <= IDLE;
			end if;
		when DATA =>
			if clkin = '1' then
				if nibble = '0' then
					datbuf <= sddat0;
				else
					txstep <= '1';
					txdata(7 downto 4) <= datbuf;
					txdata(3 downto 0) <= sddat0;
					if nbyte = 511 then
						datastate <= CRC;
						txstart <= '0';
						nbyte <= 0;
					else
						nbyte <= nbyte + 1;
					end if;
				end if;
				nibble <= not nibble;
			end if;
		when CRC =>
			if clkin = '1' then
				if nbyte = 16 then
					datastate <= IDLE;
				else
					nbyte <= nbyte + 1;
				end if;
			end if;
		end case;
		if card = '0' then
			datastate <= IDLE;
			txstart <= '0';
		end if;
	end process;

	process
		variable err : std_logic;
		variable cond : boolean;
	begin
		wait until rising_edge(clk);
		datago <= '0';
		datastop <= '0';
		case cmdstate is
		when IDLE =>
			sdcmd <= '1';
			sddat <= "ZZZZ";
			if go = '1' then
				buf(47) <= '0';
				buf(46) <= '1';
				buf(45 downto 40) <= cmd;
				buf(39 downto 8) <= arg;
				buf(7 downto 1) <= "0000000";
				buf(0) <= '1';
				cmdstate <= COMMAND;
				cmdctr <= 0;
				if cmd = NOOP then
					cmdstate <= RESP2;
				end if;
			end if;
		when COMMAND =>
			if clkout = '1' then
				buf <= buf(46 downto 1) & (buf(47) xor buf(7)) & '0';
				if cmdctr < 40 then
					sdcmd <= buf(47);
					buf(1) <= buf(47) xor buf(7);
					buf(4) <= buf(3) xor (buf(47) xor buf(7));
				else
					sdcmd <= buf(7);
				end if;
				if cmdctr = 47 then
					sdcmd <= '1';
				end if;
				if cmdctr = 48 then
					cmdctr <= 0;
					case cmd is
					when "000000" =>
						sdcmd <= '1';
						cmdstate <= WAIT0;
					when "010001" =>
						sdcmd <= 'Z';
						cmdstate <= WAITRESP;
						datago <= '1';
					when others =>	
						sdcmd <= 'Z';
						cmdstate <= WAITRESP;
					end case;
				else
					cmdctr <= cmdctr + 1;
				end if;
			end if;
		when WAITRESP =>
			if clkin = '1' and sdcmd0 = '0' then
				if cmd = "000010" then
					cmdstate <= RESP2;
				else
					cmdstate <= RESP;
				end if;
				buf(0) <= '0';
			end if;
		when RESP =>
			if clkin = '1' then
				buf <= buf(46 downto 0) & sdcmd0;
				if cmdctr = 47 then
					cmdstate <= DONE;
					response <= buf(39 downto 8);
					cond := false;
					case cmd is
					when "000010" | "101001" =>
					when "000011" =>
						cond := buf(23 downto 21) /= "000";
					when "000111" =>
						cmdstate <= WAITBUSY;
					when "001000" =>
						cond := buf(19 downto 8) /= arg(11 downto 0);
					when others =>
						cond := buf(39 downto 27) /= (12 downto 0 => '0');
					end case;
					if cond then
						failed <= '1';
					else
						failed <= buf(46) or not buf(0);
					end if;
					if cmd = "010001" and failed = '1' then
						datastop <= '1';
					end if;
				else
					cmdctr <= cmdctr + 1;
				end if;
			end if;
		when RESP2 =>
			if clkin = '1' then
				if cmdctr = 135 then
					cmdstate <= DONE;
					response <= (others => '0');
					failed <= '0';
				else
					cmdctr <= cmdctr + 1;
				end if;
			end if;
		when WAIT0 =>
			if cmdctr = 9 then
				cmdstate <= DONE;
				response <= (others => '0');
				failed <= '0';
			else
				cmdctr <= cmdctr + 1;
			end if;
		when WAITBUSY =>
			if clkin = '1' and sddat0(0) = '1' then
				cmdstate <= DONE;
			end if;
		when DONE =>
			cmdstate <= IDLE;
		end case;
		if card = '0' then
			cmdstate <= IDLE;
		end if;
	end process;
	
	process
	begin
		wait until rising_edge(clk);
		go <= '0';
		case state is
		when NOCARD =>
			if card = '1' then
				state <= RESET;
				ctr <= 0;
			end if;
		when RESET =>
			if cmdstate = IDLE then
				go <= '1';
				case ctr is
				when 0 =>
					cmd <= "000000";
					arg <= (others => '0');
				when 1 =>
					cmd <= "001000";
					arg <= X"000001A5";
				when 2 =>
					cmd <= "110111";
					arg <= (others => '0');
				when 3 =>
					cmd <= "101001";
					arg <= X"40700000";
				when 4 =>
					go <= '0';
					if response(31) = '0' then
						ctr <= 2;
					else
						ctr <= 5;
						hc <= response(30);
					end if;
				when 5 =>
					cmd <= "000010";
					arg <= (others => '0');
				when 6 =>
					cmd <= "000011";
				when 7 =>
					cmd <= "000111";
					arg(31 downto 16) <= response(31 downto 16);
				when 8 => 
					slow <= '0';
					cmd <= NOOP;
				when 9 =>
					cmd <= "110111";
				when 10 =>
					cmd <= "101010";
				when 11 =>
					cmd <= "110111";
				when 12 =>
					cmd <= "000110";
					arg(1) <= '1';
				when others =>
					cmd <= "000000";
					go <= '0';
					state <= IDLE;
				end case;
			end if;
			if cmdstate = DONE then
				if failed = '1' then
					state <= ERROR;
				else
					ctr <= ctr + 1;
				end if;
			end if;
		when IDLE =>
			if readblk = '1' then
				state <= READCMD;
			end if;
		when READCMD =>
			if cmdstate = IDLE then
				if hc = '1' then
					arg <= blk;
				else
					arg <= blk(22 downto 0) & "000000000";
				end if;
				cmd <= "010001";
				go <= '1';
			end if;
			if cmdstate = DONE then
				state <= WAITDATA;
			end if;
		when WAITDATA =>
			if datastate = IDLE then
				state <= IDLE;
			end if;
		when ERROR =>
		end case;
		if card = '0' then
			state <= NOCARD;
			slow <= '1';
		end if;
	end process;
	
	process
	begin
		wait until rising_edge(clk);
		readblk <= '0';
		if regrd = '1' then
			regout <= X"00";
			case to_integer(regaddr) is
			when 0 =>
				if state /= IDLE then
					regout(7) <= card;
				end if;
				regout(6) <= not card or failed;
				if card = '1' then
					regout(5 downto 0) <= cmd;
				end if;
			when 1 => regout <= response(7 downto 0);
			when 2 => regout <= response(15 downto 8);
			when 3 => regout <= response(23 downto 16);
			when 4 => regout <= response(31 downto 24);
			when others =>
			end case;
		end if;
		if regwr = '1' then
			case to_integer(regaddr) is
			when 0 =>
				case to_integer(regin) is
				when 1 =>
					readblk <= '1';
				when others =>
				end case;
			when 1 => blk(7 downto 0) <= regin;
			when 2 => blk(15 downto 8) <= regin;
			when 3 => blk(23 downto 16) <= regin;
			when 4 => blk(31 downto 24) <= regin;
			when others =>
			end case;
		end if;
	end process;
end main;