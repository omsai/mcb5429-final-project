#!/bin/sh
# Specify that we need a single node and 6 CPUs
#$ -pe smp 6
# Change to the current working directory
#$ -cwd
# Specify that we are running a shell script!
#$ -S /bin/sh

make -j6 strip-adapters
make threads=6 align
make -j6 all
