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
#     $ make -j 6


# Configuration settings
input_prefix = /archive/MCB5429/Final_data/ChIPseq
genome = hg19
genome_prefix = /archive/MCB5429/genomes/$(genome)
genome_chromosome_sizes = $(genome_prefix)/$(genome)_chromInfo.txt
chromosome = chr15
chromosome_size = $(shell \
	grep $(chromosome) $(genome_chromosome_sizes) \
	| cut -f2)
chromosome_fasta = $(genome_prefix)/fasta/$(chromosome).fa
adapter = GATCGGAAGAGCTCGTATGCCGTCTTCTGCTTGAAA
bowtie_index = $(genome_prefix)/bowtieIndex/$(genome)
threads = 1
color_untreated = 0,0,125
color_treated = 125,0,0

# Convenience functions
filestem = $(foreach file,$1,$(firstword $(subst ., ,$(file))))
colorize = $(if $(findstring untr,$(call filestem $1)) \
	,$(color_untreated),$(color_treated))
strip_underscores = $(shell echo "$1" | \
	sed \
	-e 's/__/_/g' \
	-e 's/^_//')
status_remove = $(call strip_underscores,$(shell echo "$1" | \
	sed \
	-e 's/untr//' \
	-e 's/treat//'))
status_move_to_end = $(call strip_underscores,$(shell echo "$1" | \
	sed -E \
	-e 's/(.*)untr(.*)/\1\2_untr/' \
	-e 's/(.*)treat(.*)/\1\2_treat/'))
add_treat_suffix = $(foreach file,$1, \
	$(call status_move_to_end,$(file)))
remove_treat_status = $(foreach file,$1, \
	$(call status_remove,$(file)))

# Convenience variables for make rules
SHELL := /bin/bash		# Needed for <( )
this_makefile = $(lastword $(MAKEFILE_LIST))
fastq = $(notdir $(wildcard $(input_prefix)/*.fastq))
targets_qc = $(fastq:.fastq=_fastqc.data)
targets_adapter_stripped = $(fastq:.fastq=.adapter_removed.fastq)
targets_reqc = $(targets_adapter_stripped:.fastq=_fastqc.data)
targets_aligned = $(fastq:.fastq=.$(chromosome).bam)
targets_bedgraph = $(targets_aligned:.bam=.bedgraph)
# Unfortunately the input file names have `untr' and `treat' in the
# middle of the file name instead of towards the end.  This makes them
# difficult to distinguish by Make's rules which tries to relate files
# by extensions (i.e. differences at the end instead of the middle).
# Therefore we need to create a symlinks with `untr' and `treat' which
# point to the real targets.
prereqs_call_peaks = $(targets_aligned)
prereqs_call_peaks_symlinks = $(addsuffix .$(chromosome).bam, \
	$(call add_treat_suffix, \
	$(call filestem,$(fastq))))
targets_call_peaks_no_suffix = $(sort \
	$(call remove_treat_status, \
	$(call filestem,$(fastq))))
targets_call_peaks = $(foreach suffix,model.r model.pdf, \
	$(addsuffix .$(chromosome)_$(suffix), \
	$(targets_call_peaks_no_suffix)))
# Function to fetch target from symlink
symlink_hashmap = $(join \
	$(addsuffix ~,$(prereqs_call_peaks)), \
	$(prereqs_call_peaks_symlinks))
symlink_target = $(subst ~$1,,$(filter %~$1,$(symlink_hashmap)))
targets_peak_sequences = $(addsuffix \
	.$(chromosome)_summits.top200.fa, \
	$(targets_call_peaks_no_suffix))

# Rules
all : qc strip-adapters reqc align bedgraph call-peaks peak-sequences
qc : $(addprefix qc1/,$(targets_qc))
strip-adapters : $(targets_adapter_stripped)
reqc : $(addprefix qc2/,$(targets_reqc))
align : $(targets_aligned)
bedgraph : $(targets_bedgraph)
call-peaks : $(targets_call_peaks)
peak-sequences : $(targets_peak_sequences)

.PHONY : all qc strip-adapters reqc align bedgraph call-peaks peak-sequences

# QC of unprocessed data
qc1/%_fastqc.zip : $(input_prefix)/%.fastq
	mkdir -p $(@D)
	fastqc -o $(@D)/ $<

# Extract FastQC text file to see overrepresented sequences, etc
qc1/%_fastqc.data : qc1/%_fastqc.zip
	unzip -p $< $(basename $(<F))/fastqc_data.txt > $@

# Remove adapters
%.adapter_removed.fastq : $(input_prefix)/%.fastq
	fastx_clipper -v -Q 33 -a $(adapter) -i $< -o $@

# Re-QC of adapter stripped data
qc2/%_fastqc.zip : %.adapter_removed.fastq
	mkdir -p $(@D)
	fastqc -o $(@D)/ $<

# Extract FastQC text file to see overrepresented sequences, etc
qc2/%_fastqc.data : qc2/%_fastqc.zip
	unzip -p $< $(basename $(<F))/fastqc_data.txt > $@

# Align reads
%.bam : %.adapter_removed.fastq
	bowtie -v2 -m1 --sam --time --threads $(threads) $(bowtie_index) $< \
	| samtools view -hb /dev/stdin \
	| samtools sort -O bam -T $$(mktemp -d)/$@ /dev/stdin -o $@

# Create index to be able to subset aligned file
%.bam.bai : %.bam
	samtools index $<

# Subset to one chromosome
%.$(chromosome).bam : %.bam %.bam.bai
	samtools view -hb $< $(chromosome) > $@

# Create sorted bed file
%.$(chromosome).bed : %.$(chromosome).bam
	bedtools bamtobed -i $< > $@

# Create bedgraph header for tracklines
%.$(chromosome).bedgraph.header :
	echo 'track type=bedGraph name="$(call filestem,$@)_bedgraph"' > $@
	echo 'visibility=full autoScale=on alwaysZero=on' >> $@
	echo 'color=$(call colorize,$@) windowingFunction=maximum' >> $@

# Create bedgraph
%.$(chromosome).bedgraph : %.$(chromosome).bed %.$(chromosome).bedgraph.header
	cat $(lastword $^) <( bedtools genomecov -bg -i $< -g $(genome_chromosome_sizes) ) > $@

# Call peaks
%.$(chromosome)_model.r %.$(chromosome)_summits.bed : %_treat.$(chromosome).bam %_untr.$(chromosome).bam
	macs14 --gsize=$(chromosome_size) --name=$(@:_peaks.bed=) \
	--treatment=$< --control=$(lastword $^)

# Temporary symlinks with treatment status at end of filename
%_treat.$(chromosome).bam : | align # "Order-only" prerequisite
	ln -s $(call symlink_target,$@) $@
%_untr.$(chromosome).bam : | align # "Order-only" prerequisite
	ln -s $(call symlink_target,$@) $@

# Create PDF model images of the peak calls
%.$(chromosome)_model.pdf : %.$(chromosome)_model.r
	R CMD BATCH $<

# Get sequence around top 200 peaks
%.$(chromosome)_summits.top200.fa : %.$(chromosome)_summits.bed
	sort -n -r -k5 $< | head -200 \
	| bedtools slop -i /dev/stdin -g $(genome_chromosome_sizes) -b 50 \
	| bedtools getfasta -fi $(chromosome_fasta) -bed /dev/stdin -fo $@

# Remove files to be able to re-run sections of the pipeline
clean-all : clean-qc clean-strip-adapters clean-align clean-bedgraph
clean-qc :
	rm -rf qc1/ qc2/
clean-strip-adapters :
	rm -f *.fastq
clean-align :
	rm -f *.bam *.bai
clean-bedgraph :
	rm -f *.bed *.header *.bedgraph
clean-call-peaks :
	rm -f *_model. *_peaks.xls *_peaks.bed *_summits.bed
clean-peak-sequences :
	rm -f *.fa
.PHONY : clean-all clean-qc clean-strip-adapters clean-align \
	clean-bedgraph clean-call-peaks clean-peak-sequences
