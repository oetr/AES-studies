------------------------------------------------------------
-- Title      : AES Testbench
------------------------------------------------------------
-- File       : AES_TB
-- Author     : Peter Samarin <peter.samarin@gmail.com>
------------------------------------------------------------
-- Copyright (c) 2020 Peter Samarin
------------------------------------------------------------
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.txt_util.all;
------------------------------------------------------------
package AESlib is


  subtype key_t is std_logic_vector(127 downto 0);
  subtype block_t is std_logic_vector(127 downto 0);
  type state_t is array (0 to 3, 0 to 3) of unsigned (7 downto 0);
  type column_t is array (0 to 3) of unsigned (7 downto 0);
  type column_array_t is array (0 to 3) of column_t;


  ----------------------------------------------------------
  -- Functions
  ----------------------------------------------------------
  function block2state (
    signal block_in : block_t)
    return state_t;

  -- Shift rows
  function shift_rows (
    signal state_in : state_t)
    return state_t;

  -- Shift rows
  function mix_columns (
    signal state_in : state_t)
    return state_t;

  -- Shift rows
  function mix_one_column (
    constant column_in : column_t)
    return column_t;

end AESlib;

------------------------------------------------------------
-- Body
------------------------------------------------------------
package body AESlib is


  function block2state (
    signal block_in : block_t)
    return state_t is

    variable state_out : state_t;
  begin

    for i in 0 to 15 loop
      state_out(integer(i / 4), i mod 4) := unsigned(block_in(127 - i*8 downto 127 - (i*8+7)));
    end loop;

    return state_out;
  end function block2state;


  -- Shift rows
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


  -- mix columns
  function mix_columns (
    signal state_in : state_t)
    return state_t is

    variable state_out  : state_t;
    variable column_in  : column_array_t;
    variable column_out : column_array_t;
  begin

    for col in 0 to 3 loop
      for row in 0 to 3 loop
        column_in(col)(row) := state_in(row, col);
      end loop;

      column_out(col) := mix_one_column(column_in(col));

      for row in 0 to 3 loop
        state_out(row, col) := column_out(col)(row);
      end loop;
    end loop;

    return state_out;
  end function mix_columns;


  function mix_one_column (
    constant column_in : column_t)
    return column_t is

    variable columnX2   : column_t;
    variable column_out : column_t;
    variable h          : unsigned(7 downto 0) := (others => '0');
  begin
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

end package body AESlib;
