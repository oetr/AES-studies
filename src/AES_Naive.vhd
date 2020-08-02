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
    clk         : in  std_logic;
    rst         : in  std_logic;
    -- I/O
    input_valid : in  std_logic;
    done        : out std_logic;
    enc         : in  boolean;
    key         : in  key_t;
    input       : in  block_t;
    output      : out block_t);
end entity AES_Naive;
------------------------------------------------------------
architecture arch of AES_Naive is
  signal initial_state : state_t := (others => (others => (others => '0')));
  signal aes_state     : state_t := (others => (others => (others => '0')));
  signal state_xor     : state_t := (others => (others => (others => '0')));
  signal state_sb      : state_t := (others => (others => (others => '0')));
  signal state_sr      : state_t := (others => (others => (others => '0')));
  signal state_mc      : state_t := (others => (others => (others => '0')));

  -- key
  signal initial_key : key_state_t := (others => (others => (others => '0')));
  signal round_key   : key_state_t := (others => (others => (others => '0')));

  -- Round
  signal round    : integer range 0 to RCON'length - 1 := 0;
  signal done_reg : std_logic                          := '1';

  signal output_reg : state_t := (others => (others => (others => '0')));

  type fsm_t is (idle_s, busy_s, final_round_s);
  signal state : fsm_t := idle_s;

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

  initial_key   <= key2state(key);
  initial_state <= block2state(input);

  state_sb  <= subbytes(aes_state);
  state_sr  <= shift_rows(state_sb);
  state_mc  <= mix_columns(state_sr);
  state_xor <= state_xor_key(state_mc, round_key);

  done   <= done_reg;
  output <= state2block(output_reg);
end architecture arch;
