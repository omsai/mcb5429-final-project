# Usage:
#
# To take advantage of parallel processes in this script, on a
# cluster you must request additional CPU cores from the scheduler.
# As there are 6 input files, using 6 CPU cores would be optimal:
#
#     $ qrsh -pe smp 6
#
# Then enter the directory containing this Makefile and run it with:
#
#     $ make --check-symlink-times -j 6
#
# This script conserves disk space using symlinks, and therefore the
# `--check-symlink-times` option above is necessary to avoid
# re-running rules involving symlinks (for more detail, see
# http://stackoverflow.com/a/19138136).


# Configuration settings
input_prefix = /archive/MCB5429/Final_data/ChIPseq
scratch = /tempdata/$(shell whoami) #FIXME: this is currently unused.
chromosome = chr15

# Convenience variables for make rules
fastq_abs = $(wildcard $(input_prefix)/*.fastq)
fastq_inputs = $(addsuffix %.fastq,$(dir $(fastq_abs)))
fastq = $(notdir $(fastq_abs))
fastqc_targets = $(fastq:.fastq=_fastqc.data)
trim_targets = $(fastq:.fastq=.adapter_removal_1.fastq)
reqc_targets = $(trim_targets:.fastq=_fastqc.data)
this_makefile = $(lastword $(MAKEFILE_LIST))

# Rule sets
all : qc trim
qc : $(fastqc_targets)
trim : $(trim_targets)
reqc : 

# Rules

# Initial QC of unprocessed data.
%_fastqc.zip : $(fastq_inputs)
	time fastqc -o . $<

# Extract FastQC text file for overrepresented sequences.
%_fastqc.data : %_fastqc.zip
	unzip -p $< $(basename $<)/fastqc_data.txt > $@

# Create adapters file with overrepresented sequences, ignoring
# sequences with "N" in them.
%.unprocessed.adapters : %_fastqc.data
	awk '{print $$1}' $< \
	| awk '/^>>END_MODULE/ {seq=0} seq && /^[^#]/ && ! /.*N.*/ {print} /^>>Overrepresented/ {seq=1}' > $@

# Remove adapters, if any.  Conserve disk space using symlinks for
# unmodified data.
%.adapter_removed_round_1.fastq : $(input_prefix)/%.fastq %.unprocessed.adapters
	if [[ -s $(lastword $^) ]] ; then \
		ln -vfs $< $@.before ; \
		while read adapter ; do \
			@echo "Removing adapter $$adapter from $(<F) ..." ; \
			fastx_clipper -v -Q33 \
			-i $@.before \
			-o $@.after \
			-a $$adapter ; \
			mv -v $@.after $@.before ; \
		done < $(lastword $^) ; \
		mv -v $@.before $@ ; \
	else \
		ln -vfs $< $@ ; \
	fi

# Re-QC of processed data.
%.adapter_removed_round_1._fastqc.zip : %.adapter_removed_round_1.fastq
	time fastqc -o . $<

# Extract FastQC text file for overrepresented sequences.
%.adapter_removed_round_1._fastqc.data: %.adapter_removed_round_1._fastqc.zip
	unzip -p $< $(basename $<)/fastqc_data.txt > $@

# Create adapters file with overrepresented sequences, ignoring
# sequences with "N" in them.
%.adapter_removed_round_1.adapters : %.adapter_removed_round_1._fastqc.data
	awk '{print $$1}' $< \
	| awk '/^>>END_MODULE/ {seq=0} seq && /^[^#]/ && ! /.*N.*/ {print} /^>>Overrepresented/ {seq=1}' > $@

# Remove adapters, if any.  Conserve disk space using symlinks for
# unmodified data.
%.adapter_removed_round_2.fastq : %adapter_removed_round_1.fastq %.adapter_removed_round_1.adapters
	if [[ -s $(lastword $^) ]] ; then \
		ln -vfs $< $@.before ; \
		while read adapter ; do \
			@echo "Removing adapter $$adapter from $(<F) ..." ; \
			fastx_clipper -v -Q33 \
			-i $@.before \
			-o $@.after \
			-a $$adapter ; \
			mv -v $@.after $@.before ; \
		done < $(lastword $^) ; \
		mv -v $@.before $@ ; \
	else \
		ln -vfs $< $@ ; \
	fi

clean :
	find -not -name $(this_makefile) -not -path . -delete

.PHONY : clean all qc trim
