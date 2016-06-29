#!/bin/sh
# Privision a single node and 6 CPUs
#$ -pe smp 6
# Change to the current working directory
#$ -cwd
# Specify that we are running a shell script!
#$ -S /bin/sh

# Terminate on any errors
set -e

# Copy the chipseq directory to the local filesystem
rsync="rsync -av"
scratch=/scratch/$(whoami)
$rsync chipseq $scratch/
pushd $scratch

# Run the makefile in the chipseq directory with the default rule
make -C chipseq -j6

# Copy the results back to the head node
popd
$rsync $scratch/chipseq .
