------------------------------------------------------------
-- Doc: A naive implementation of advanced encryption standard
------------------------------------------------------------
------------------------------------------------------------
-- Author    : Peter Samarin <peter.samarin@gmail.com>
------------------------------------------------------------
-- Copyright (c) 2020 Peter Samarin
------------------------------------------------------------
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
  signal state     : state_t := (others => (others => (others => '0')));
  signal state_xor : state_t := (others => (others => (others => '0')));
  signal state_sb  : state_t := (others => (others => (others => '0')));
  signal state_sr  : state_t := (others => (others => (others => '0')));
  signal state_mc  : state_t := (others => (others => (others => '0')));

  -- key
  signal key_state : key_state_t := (others => (others => (others => '0')));
  signal rk0       : key_state_t := (others => (others => (others => '0')));


begin

  process (input, key, key_state, state, state_sb, state_sr,
           state_xor) is
  begin
    key_state <= key2state(key);
    state     <= block2state(input);
    state_xor <= state_xor_key(state, key_state);
    state_sb  <= subbytes(state_xor);
    state_sr  <= shift_rows(state_sb);
    state_mc  <= mix_columns(state_sr);

    rk0 <= key_scheduler(key_state, RCON(0));
  end process;

  output <= (others => '0');

end architecture arch;
