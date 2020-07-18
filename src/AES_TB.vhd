-----------------------------------------------------------------------------
-- Title      : AES Testbench
-----------------------------------------------------------------------------
-- File       : AES_TB
-- Author     : Peter Samarin <peter.samarin@gmail.com>
-----------------------------------------------------------------------------
-- Copyright (c) 2020 Peter Samarin
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.txt_util.all;
------------------------------------------------------------------------
entity AES_TB is
end AES_TB;
------------------------------------------------------------------------
architecture Testbench of AES_TB is
  constant T : time      := 20 ns;      -- clk period
  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  -- random numbers
  shared variable seed1 : positive := 1000;
  shared variable seed2 : positive := 2000;

  -- simulation control
  shared variable ENDSIM : boolean := false;
begin

  ---- Design Under Verification -----------------------------------------
  DUV : entity work.AES_Naive
    port map (
      clk => clk,
      rst => rst);

  ---- DUT clock running forever ----------------------------
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


  ----- Test vector generation -------------------------------------------
  TESTS : process is
  begin
    print("");
    print("------------------------------------------------------------");
    print("--------------------- AES Testbench ------------------------");
    print("------------------------------------------------------------");

    wait until rising_edge(clk);

    ENDSIM := true;
    print("Simulation end...");
    print("");
    wait;
  end process;
end Testbench;
