-------------------------------------------------------------------------------
-- Doc: A naive implementation of advanced encryption standard
-------------------------------------------------------------------------------
-- Author    : Peter Samarin <peter.samarin@gmail.com>
-------------------------------------------------------------------------------
-- Copyright (c) 2020 Peter Samarin
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AESlib.all;
------------------------------------------------------------
entity AES_Naive is
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    -- I/O
    enc    : in  boolean;
    key    : in  key_t;
    input  : in  block_t;
    output : out block_t);
end entity AES_Naive;
------------------------------------------------------------
architecture arch of AES_Naive is
  signal pre_state : block_t;
  signal state     : state_t;
  signal state_sr  : state_t;
  signal state_mc  : state_t;
begin
  process (input, key, pre_state, state, state_sr) is
  begin
    pre_state <= input xor key;
    state     <= block2state(pre_state);
    state_sr  <= shift_rows(state);
    state_mc  <= mix_columns(state_sr);
  end process;

end architecture arch;
