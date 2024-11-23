#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SIM_SRC="sim_rt.f"
SYN_SRC="sim_gate.f"

# Loop over S and NUM
for S in {1..32}; do
  for NUM in {1..3}; do
    # Run the Verilog simulation and redirect output to a log file
    log_file="./rtl_sim_log/rtl_S${S}_NUM${NUM}.log"
    ncverilog -f ${SIM_SRC} +define+NUM=$NUM +define+S=$S > $log_file 2>&1

    # Check for the pass/fail message in the log file
    if grep -q "setuphold<setup>" $log_file; then
      echo -e "${RED}Setup violation${NC} for sequence_length=$S, NUM=$NUM"
    elif grep -q "setuphold<hold>" $log_file; then
      echo -e "${RED}Hold violation${NC} for sequence_length=$S, NUM=$NUM"
    elif grep -q "Congratulation! All result are correct" $log_file; then
      echo -e "${GREEN}Simulation passed${NC} for sequence_length=$S, NUM=$NUM"
    elif grep -q "errors QQ" $log_file; then
      echo -e "${RED}Simulation failed${NC} for sequence_length=$S, NUM=$NUM"
    elif grep -q "You have exceeded the cycle count limit" $log_file; then
      echo -e "${RED}You have exceeded the cycle count limit${NC} for sequence_length=$S, NUM=$NUM"
    else
      echo -e "${RED}Simulation for S=$S, NUM=$NUM did not produce a recognizable pass/fail message${NC}"
    fi
  done
done