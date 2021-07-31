------------------------------------------------------------
-- Title      : AES Testbench
------------------------------------------------------------
-- File       : AES_TB
-- Author     : Peter Samarin <peter.samarin@gmail.com>
------------------------------------------------------------
-- Copyright (c) 2021 Peter Samarin
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

  -- DUV: I/O
  signal input_valid : std_logic                      := '0';
  signal done        : std_logic                      := '0';
  signal key         : std_logic_vector(127 downto 0) := (others => '0');
  signal input       : std_logic_vector(127 downto 0) := (others => '0');
  signal output      : std_logic_vector(127 downto 0) := (others => '0');

  -- random numbers
  shared variable seed1 : positive := 1000;
  shared variable seed2 : positive := 2000;
  shared variable rand  : real;  -- random real-number value in range 0 to 1.0  

  -- simulation control
  shared variable ENDSIM : boolean := false;

  -- test vector
  type test_t is record
    key    : std_logic_vector(127 downto 0);
    input  : std_logic_vector(127 downto 0);
    output : std_logic_vector(127 downto 0);
  end record test_t;

  type test_array_t is array (natural range <>) of test_t;
  signal test_vector : test_array_t (0 to 2) :=(
    -- test 1
    (key    => X"2b7e151628aed2a6abf7158809cf4f3c",
     input  => X"3243f6a8885a308d313198a2e0370734",
     output => X"3925841d02dc09fbdc118597196a0b32"),
    -- test 2
    (key    => X"000102030405060708090a0b0c0d0e0f",
     input  => X"00112233445566778899aabbccddeeff",
     output => X"69c4e0d86a7b0430d8cdb78070b4c55a"),
    -- test 3
    (key    => X"000102030405060708090a0b0c0d0e0f",
     input  => X"000102030405060708090a0b0c0d0e0f",
     output => X"0a940bb5416ef045f1c39458c653ea5a")
    );
  signal test_nr : integer := 1;

begin

  ---- Design Under Verification ---------------------------
  DUV : entity work.AES_128_Simple_Pipelined
    port map (
      clk         => clk,
      key         => key,
      input       => input,
      output      => output,
      input_valid => input_valid,
      done        => done
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
    input <= (others => '0');
    key   <= (others => '0');
    print("");
    print("------------------------------------------------------------");
    print("--------------------- AES Testbench ------------------------");
    print("------------------------------------------------------------");

    wait until rising_edge(clk);

    for i in test_vector'left to test_vector'right loop
      input_valid <= '1';
      input       <= test_vector(i).input;
      key         <= test_vector(i).key;
      wait until rising_edge(clk);
      input_valid <= '0';
      wait until rising_edge(done);
      if output /= test_vector(i).output then
        print("Test " & str(test_nr) & " failed. key: " & hstr(key) & ", input: " & hstr(input));
        print("     expected: " & hstr(test_vector(i).output) & ", got: " & hstr(output));
      end if;
      test_nr <= test_nr + 1;
    end loop;

    wait until rising_edge(clk);
    ENDSIM := true;
    print("Simulation end...");
    print("");
    wait;
  end process;
end Testbench;
