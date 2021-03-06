------------------------------------------------------------
-- Title      : AES Library
------------------------------------------------------------
-- Author     : Peter Samarin <peter.samarin@gmail.com>
------------------------------------------------------------
-- Copyright (c) 2021 Peter Samarin
------------------------------------------------------------
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.txt_util.all;
------------------------------------------------------------
package AESlib is
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

  ----------------------------------------------------------
  -- Functions
  ----------------------------------------------------------
  function block2state (
    signal block_in : block_t)
    return state_t;

  ----------------------------------------------------------
  function state2block (
    signal state_in : state_t)
    return block_t;

  ----------------------------------------------------------
  function key2state (
    signal key_in : key_t)
    return key_state_t;

  ----------------------------------------------------------
  function shift_rows (
    signal state_in : state_t)
    return state_t;

  ----------------------------------------------------------
  function mix_columns (
    signal state_in : state_t)
    return state_t;

  ----------------------------------------------------------
  function mix_one_column (
    constant column_in : column_t)
    return column_t;

  ----------------------------------------------------------
  function subbytes (
    signal state_in : state_t)
    return state_t;

  ----------------------------------------------------------
  function key_scheduler (
    signal key    : key_state_t;
    constant rc_i : byte_t)
    return key_state_t;

  ----------------------------------------------------------
  function key_scheduler_g (
    constant w3   : word_t;
    constant rc_i : byte_t)
    return word_t;

  ----------------------------------------------------------
  -- XOR two words
  function word_xor (
    constant w0 : word_t;
    constant w1 : word_t)
    return word_t;

  ----------------------------------------------------------
  function state_xor_key (
    signal s : state_t;
    signal k : key_state_t)
    return state_t;

end AESlib;

------------------------------------------------------------
-- Body
------------------------------------------------------------
package body AESlib is
  -- convert given block into state
  function block2state (
    signal block_in : block_t)
    return state_t is

    variable state_out : state_t;
  begin

    for i in 0 to 15 loop
      state_out(i mod 4, integer(i / 4)) := unsigned(block_in(127 - i*8 downto 127 - (i*8+7)));
    end loop;

    return state_out;
  end function block2state;


  -- convert given state into block
  function state2block (
    signal state_in : state_t)
    return block_t is

    variable block_out : block_t;
  begin

    for i in 0 to 15 loop
      block_out(127 - i*8 downto 127 - (i*8+7)) := std_logic_vector(state_in(i mod 4, integer(i / 4)));
    end loop;

    return block_out;
  end function state2block;

  ----------------------------------------------------------
  function key2state (
    signal key_in : key_t)
    return key_state_t is

    variable state_out : key_state_t;
  begin

    for i in 0 to 15 loop
      state_out(integer(i / 4), i mod 4) := unsigned(key_in(127 - i*8 downto 127 - (i*8+7)));
    end loop;

    return state_out;
  end function key2state;

  ----------------------------------------------------------
  function shift_rows (
    signal state_in : state_t)
    return state_t is

    variable state_out : state_t;
    variable index     : integer := 0;
  begin
    for row in 0 to 3 loop
      for col in 0 to 3 loop
        state_out(row, (col - row + 4) mod 4) := state_in(row, col);
      end loop;
    end loop;

    return state_out;
  end function shift_rows;

  ----------------------------------------------------------
  function mix_columns (
    signal state_in : state_t)
    return state_t is

    variable state_out  : state_t;
    variable column_in  : column_t;
    variable column_out : column_t;
  begin

    -- extract columns from state
    for col in 0 to 3 loop
      for row in 0 to 3 loop
        column_in(row) := state_in(row, col);
      end loop;

      column_out := mix_one_column(column_in);

      -- assemble the state from mixed columns
      for row in 0 to 3 loop
        state_out(row, col) := column_out(row);
      end loop;
    end loop;

    return state_out;
  end function mix_columns;

  ----------------------------------------------------------
  function mix_one_column (
    constant column_in : column_t)
    return column_t is

    variable columnX2   : column_t;     -- times 2
    variable column_out : column_t;
    variable h          : byte_t := (others => '0');
  begin
    -- times 2 computation
    for row in 0 to 3 loop
      if column_in(row)(7) = '1' then
        h := (others => '1');
      else
        h := (others => '0');
      end if;
      columnX2(row) := shift_left(column_in(row), 1) xor (x"1b" and h);
    end loop;

    column_out(0) := columnX2(0) xor column_in(3) xor column_in(2) xor columnX2(1) xor column_in(1);
    column_out(1) := columnX2(1) xor column_in(0) xor column_in(3) xor columnX2(2) xor column_in(2);
    column_out(2) := columnX2(2) xor column_in(1) xor column_in(0) xor columnX2(3) xor column_in(3);
    column_out(3) := columnX2(3) xor column_in(2) xor column_in(1) xor columnX2(0) xor column_in(0);

    return column_out;
  end function mix_one_column;


  ----------------------------------------------------------
  function subbytes (
    signal state_in : state_t)
    return state_t is

    variable state_out : state_t;
    variable index     : integer := 0;
  begin
    for row in 0 to 3 loop
      for col in 0 to 3 loop
        index               := to_integer(state_in(row, col));
        state_out(row, col) := sbox(index);
      end loop;
    end loop;

    return state_out;
  end function subbytes;


  ----------------------------------------------------------
  function key_scheduler (
    signal key    : key_state_t;
    constant rc_i : byte_t)
    return key_state_t is

    variable w0, w1, w2, w3 : word_t;
    variable w4, w5, w6, w7 : word_t;
    variable key_out        : key_state_t;
  begin
    for col in 0 to 3 loop
      w0(col) := key(0, col);
      w1(col) := key(1, col);
      w2(col) := key(2, col);
      w3(col) := key(3, col);
    end loop;

    w4 := word_xor(key_scheduler_g(w3, rc_i), w0);
    w5 := word_xor(w4, w1);
    w6 := word_xor(w5, w2);
    w7 := word_xor(w6, w3);

    for col in 0 to 3 loop
      key_out(0, col) := w4(col);
      key_out(1, col) := w5(col);
      key_out(2, col) := w6(col);
      key_out(3, col) := w7(col);
    end loop;

    return key_out;
  end function key_scheduler;


  ----------------------------------------------------------
  function key_scheduler_g (
    constant w3   : word_t;
    constant rc_i : byte_t)
    return word_t is

    variable word_out : word_t;
  begin
    word_out(0) := rc_i xor sbox(to_integer(w3(1)));
    word_out(1) := sbox(to_integer(w3(2)));
    word_out(2) := sbox(to_integer(w3(3)));
    word_out(3) := sbox(to_integer(w3(0)));

    return word_out;
  end function key_scheduler_g;

  ----------------------------------------------------------
  function word_xor (
    constant w0 : word_t;
    constant w1 : word_t)
    return word_t is

    variable w_out : word_t;
  begin
    for i in 0 to 3 loop
      w_out(i) := w0(i) xor w1(i);
    end loop;

    return w_out;
  end function word_xor;

  ----------------------------------------------------------
  function state_xor_key (
    signal s : state_t;
    signal k : key_state_t)
    return state_t is

    variable s_out : state_t;
  begin
    for row in 0 to 3 loop
      for col in 0 to 3 loop
        s_out(row, col) := s(row, col) xor k(col, row);
      end loop;
    end loop;

    return s_out;
  end function state_xor_key;


end package body AESlib;
