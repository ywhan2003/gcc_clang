#!/bin/bash

# Define the combinations of compilers and optimization levels
compilers=("gcc g++" "clang clang++")
opt_levels=("O0" "O1" "O2")

# Navigate to the CppPerformanceBenchmarks-master directory
cd CppPerformanceBenchmarks-master || exit

# Loop through each combination of compilers and optimization levels
for compiler in "${compilers[@]}"; do
  for opt_level in "${opt_levels[@]}"; do
    # Split the compiler string into CC and CXX
    read -r CC CXX <<< "$compiler"
    
    # Clean previous builds
    make clean
    
    # Build and generate the report
    make report CC="$CC" CXX="$CXX" OPTLEVEL="-$opt_level"
    
    # Rename the report file
    mv report.txt "report.txt.${CC}-${CXX}-${opt_level}"
  done
done