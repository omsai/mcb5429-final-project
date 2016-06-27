#!/bin/sh
# Privision a single node and 6 CPUs
#$ -pe smp 6
# Change to the current working directory
#$ -cwd
# Specify that we are running a shell script!
#$ -S /bin/sh

# Run the makefile in the chipseq directory with the default rule
make -C chipseq -j6
