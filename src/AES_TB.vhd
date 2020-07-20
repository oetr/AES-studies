------------------------------------------------------------
-- Title      : AES Testbench
------------------------------------------------------------
-- File       : AES_TB
-- Author     : Peter Samarin <peter.samarin@gmail.com>
------------------------------------------------------------
-- Copyright (c) 2020 Peter Samarin
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AESlib.all;

use std.textio.all;
use work.txt_util.all;

use ieee.math_real.all;  -- using uniform(seed1,seed2,rand)
------------------------------------------------------------
entity AES_TB is
end AES_TB;
------------------------------------------------------------
architecture Testbench of AES_TB is
  constant T : time      := 20 ns;      -- clk period
  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  -- DUV: I/O
  signal enc    : boolean := true;
  signal key    : key_t   := (others => '0');
  signal input  : block_t := (others => '0');
  signal output : block_t := (others => '0');

  -- random numbers
  shared variable seed1 : positive := 1000;
  shared variable seed2 : positive := 2000;
  shared variable rand  : real;  -- random real-number value in range 0 to 1.0  

  -- simulation control
  shared variable ENDSIM : boolean := false;
begin

  ---- Design Under Verification ---------------------------
  DUV : entity work.AES_Naive
    port map (
      clk    => clk,
      rst    => rst,
      enc    => enc,
      key    => key,
      input  => input,
      output => output
      );

  ---- DUT clock running forever ---------------------------
  process
  begin
    if ENDSIM = false then
      clk <= '0';
      wait for T/2;
      clk <= '1';
      wait for T/2;
    else
      wait;
    end if;
  end process;


  ----- Test vector generation -----------------------------
  TESTS : process is

    function get_rand_bytes (
      constant n : natural)
      return std_logic_vector is
      variable data_out : std_logic_vector(n*8-1 downto 0);
      variable byte     : integer := 0;

    begin
      for i in 0 to n-1 loop
        uniform(seed1, seed2, rand);
        byte                       := integer(rand*255.0);
        data_out(i*8+7 downto i*8) := std_logic_vector(to_unsigned(byte, 8));
      end loop;

      return data_out;
    end function get_rand_bytes;

  begin
    print("");
    print("------------------------------------------------------------");
    print("--------------------- AES Testbench ------------------------");
    print("------------------------------------------------------------");

    for i in 0 to 1000 loop
      wait until rising_edge(clk);
      if i = 0 then
        input <= X"19a09ae93df4c6f8e3e28d48be2b2a08";
      -- input <= X"d4e0b81e27bfb44111985d52aef1e530";
      else
        input <= get_rand_bytes(16);
      end if;
    end loop;

    ENDSIM := true;
    print("Simulation end...");
    print("");
    wait;
  end process;
end Testbench;
