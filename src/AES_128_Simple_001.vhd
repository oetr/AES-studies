------------------------------------------------------------
-- Doc: A naive implementation of advanced encryption standard
------------------------------------------------------------
-- Author    : Peter Samarin <peter.samarin@gmail.com>
------------------------------------------------------------
-- Copyright (c) 2021 Peter Samarin
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.AESlib.all;
------------------------------------------------------------
entity AES_128_Simple_001 is
  port (
    clk         : in  std_logic;
    -- management
    input_valid : in  std_logic;
    done        : out std_logic;
    -- data
    key         : in  std_logic_vector(127 downto 0);
    input       : in  std_logic_vector(127 downto 0);
    output      : out std_logic_vector(127 downto 0));
end entity AES_128_Simple_001;
------------------------------------------------------------
architecture arch of AES_128_Simple_001 is
    subtype block_t is std_logic_vector(127 downto 0);
  subtype byte_t is unsigned(7 downto 0);
  type word_t is array (0 to 3) of byte_t;
  type state_t is array (0 to 3, 0 to 3) of byte_t;
  type column_t is array (0 to 3) of byte_t;
  type column_array_t is array (0 to 3) of column_t;

  subtype key_t is std_logic_vector(127 downto 0);
  type key_state_t is array (0 to 3, 0 to 3) of byte_t;

  type sbox_t is array (0 to 255) of byte_t;
  constant sbox : sbox_t := (
    x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76",
    x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
    x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
    x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
    x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
    x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
    x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
    x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
    x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
    x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
    x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
    x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
    x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
    x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
    x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
    x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16");


  type rcon_t is array (0 to 9) of byte_t;
    constant RCON : rcon_t := (x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1B", x"36");
    

  
  subtype byte_t is unsigned(7 downto 0);
  type state_t is array (0 to 3, 0 to 3) of byte_t;
  type column_t is array (0 to 3) of byte_t;
  type column_array_t is array (0 to 3) of column_t;

  signal initial_state : std_logic_vector(127 downto 0) := (others => '0');
  signal aes_state     : std_logic_vector(127 downto 0) := (others => '0');
  signal state_xor     : std_logic_vector(127 downto 0) := (others => '0');
  signal state_sb      : std_logic_vector(127 downto 0) := (others => '0');
  signal state_sr      : std_logic_vector(127 downto 0) := (others => '0');
  signal state_mc      : std_logic_vector(127 downto 0) := (others => '0');

  -- key
  signal initial_key : std_logic_vector(127 downto 0) := (others => '0');
  signal round_key   : std_logic_vector(127 downto 0) := (others => '0');

  -- Round
  type rcon_t is array (0 to 9) of byte_t;
  constant RCON   : rcon_t                             := (x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1B", x"36");
  signal round    : integer range 0 to RCON'length - 1 := 0;
  signal done_reg : std_logic                          := '1';

  signal output_reg : std_logic_vector(127 downto 0) := (others => '0');

  type fsm_t is (idle_s, busy_s, final_round_s);
  signal state : fsm_t := idle_s;


  --subtype byte_t is unsigned(7 downto 0);
  type sbox_tt is array (0 to 255) of unsigned(7 downto 0);
  constant sbox : sbox_tt := (
    x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76",
    x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
    x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
    x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
    x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
    x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
    x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
    x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
    x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
    x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
    x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
    x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
    x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
    x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
    x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
    x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16");

  ----------------------------------------------------------
  -- Functions
  ----------------------------------------------------------
  function rc2high (
    constant row, col : integer range 0 to 3)
    return integer is
  begin
    return 127-(col*4+row)*8;
  end function rc2high;

  function rc2low (
    constant row, col : integer range 0 to 3)
    return integer is
  begin
    return 127-(col*4+row)*8-7;
  end function rc2low;


  function shift_rows (
    signal state_in : std_logic_vector(127 downto 0))
    return std_logic_vector is
    variable state_out : std_logic_vector(127 downto 0);
    variable index     : integer := 0;
    variable highL     : integer;
    variable lowL      : integer;
    variable highR     : integer;
    variable lowR      : integer;
  begin
    for row in 0 to 3 loop
      for col in 0 to 3 loop
        highL := rc2high(row, (col-row+4) mod 4);
        lowL  := rc2low(row, (col-row+4) mod 4);
        highR := rc2high(row, col);
        lowR  := rc2low(row, col);

        state_out(highL downto lowL) := state_in(highR downto lowR);
      end loop;
    end loop;

    return state_out;
  end function shift_rows;


  function mix_one_column (
    constant column_in : std_logic_vector(31 downto 0))
    return column_t is

    variable columnX2   : std_logic_vector(31 downto 0);  -- times 2
    variable column_out : std_logic_vector(31 downto 0);
    variable h          : std_logic_vector(7 downto 0) := (others => '0');
  begin
    -- times 2 computation
    for row in 0 to 3 loop
      if column_in(row*8+7) = '1' then
        h := (others => '1');
      else
        h := (others => '0');
      end if;
      columnX2(row*8+7 downto row*8) := shift_left(column_in(row*8+7 downto row*8), 1) xor (x"1b" and h);
    end loop;

    column_out(7 downto 0) := columnX2(7 downto 0) xor column_in(3*8+7 downto 3*8) xor column_in(2) xor columnX2(1) xor column_in(1);
    column_out(1) := columnX2(1) xor column_in(0) xor column_in(3) xor columnX2(2) xor column_in(2);
    column_out(2) := columnX2(2) xor column_in(1) xor column_in(0) xor columnX2(3) xor column_in(3);
    column_out(3) := columnX2(3) xor column_in(2) xor column_in(1) xor columnX2(0) xor column_in(0);

    return column_out;
  end function mix_one_column;



  function mix_columns (
    signal state_in : std_logic_vector(127 downto 0))
    return std_logic_vector is

    variable state_out : std_logic_vector(127 downto 0);

    variable column_in  : std_logic_vector(31 downto 0);
    variable column_out : std_logic_vector(31 downto 0);

    variable high : integer;
    variable low  : integer;
  begin
    for col in 0 to 3 loop
      for row in 0 to 3 loop
        -- extract columns from state
        high                            := rc2high(row, col);
        low                             := rc2low(row, col);
        column_in(row*8+7 downto row*8) := state_in(high downto low);
      end loop;

      column_out := mix_one_column(column_in);

      -- assemble the state from mixed columns
      for row in 0 to 3 loop
        high                       := rc2high(row, col);
        low                        := rc2low(row, col);
        state_out(high downto low) := column_out(row*8+7 downto row*8);
      end loop;
    end loop;

    return state_out;
  end function mix_columns;

  ----------------------------------------------------------
  function subbytes (
    signal state_in : std_logic_vector(127 downto 0))
    return std_logic_vector is

    variable state_out : std_logic_vector;
    variable index     : integer := 0;
  begin
    for i in 0 to 16 loop
      index                       := to_integer(state_in(i*8+7 downto i*8));
      state_out(i*8+7 downto i*8) := sbox(index);
    end loop;

    return state_out;
  end function subbytes;

begin

  process (clk) is
  begin
    if rising_edge(clk) then
      done_reg <= '0';

      case state is
        when idle_s =>
          if input_valid = '1' then
            round     <= 1;
            round_key <= key_scheduler(initial_key, RCON(0));
            aes_state <= state_xor_key(initial_state, initial_key);
            state     <= busy_s;
          end if;

        when busy_s =>
          round_key <= key_scheduler(round_key, RCON(round));
          aes_state <= state_xor;
          if round = 9 then
            state <= final_round_s;
            round <= 0;
          else
            round <= round + 1;
          end if;

        when final_round_s =>
          state      <= idle_s;
          done_reg   <= '1';
          output_reg <= state_xor_key(state_sr, round_key);
        when others => null;
      end case;

    end if;
  end process;

  initial_key   <= key;
  initial_state <= input;

  state_sb  <= subbytes(aes_state);
  state_sr  <= shift_rows(state_sb);
  state_mc  <= mix_columns(state_sr);
  state_xor <= state_xor_key(state_mc, round_key);

  done   <= done_reg;
  output <= output_reg;
end architecture arch;
