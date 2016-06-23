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
adapter = GATCGGAAGAGCTCGTATGCCGTCTTCTGCTTGAAA
bowtie_index = $(genome_prefix)/bowtieIndex/$(genome)
threads = 1
color_untreated = 0,0,125
color_treated = 125,0,0

# Convenience functions
filestem = $(firstword $(subst ., ,$1))
colorize = $(if $(findstring untr,$(call filestem $1)) \
	,$(color_untreated),$(color_treated))

# Convenience variables for make rules
SHELL := /bin/bash		# Needed for <( )
this_makefile = $(lastword $(MAKEFILE_LIST))
fastq = $(notdir $(wildcard $(input_prefix)/*.fastq))
targets_qc = $(fastq:.fastq=_fastqc.data)
targets_adapter_stripped = $(fastq:.fastq=.adapter_removed.fastq)
targets_reqc = $(targets_adapter_stripped:.fastq=_fastqc.data)
targets_aligned = $(fastq:.fastq=.$(chromosome).bam)
targets_bedgraph = $(targets_aligned:.bam=.bedgraph)

# Rules
all : qc strip-adapters reqc align bedgraph
qc : $(addprefix qc1/,$(targets_qc))
strip-adapters : $(targets_adapter_stripped)
reqc : $(addprefix qc2/,$(targets_reqc))
align : $(targets_aligned)
bedgraph : $(targets_bedgraph)
.PHONY : all qc strip-adapters reqc align bedgraph

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
.PHONY : clean-all clean-qc clean-strip-adapters clean-align \
	clean-bedgraph clean-call-peaks
