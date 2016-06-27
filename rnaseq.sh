#!/bin/sh
# Privision a single node and 8 CPUs
#$ -pe smp 8
# Change to the current working directory
#$ -cwd
# Specify that we are running a shell script!
#$ -S /bin/sh

# Run the makefile in the rnaseq directory with the memory intensive
# alignment rule as a single job
make -C rnaseq threads=8 align
# Run the remaining rules
make -C rnaseq threads=2 -j4
