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
chromosome = chr15
adapter = GATCGGAAGAGCTCGTATGCCGTCTTCTGCTTGAAA
bowtie_index = /archive/MCB5429/genomes/$(genome)/bowtieIndex/$(genome)
threads = 1

# Convenience variables for make rules
this_makefile = $(lastword $(MAKEFILE_LIST))
fastq = $(notdir $(wildcard $(input_prefix)/*.fastq))
targets_qc = $(fastq:.fastq=_fastqc.data)
targets_adapter_stripped = $(fastq:.fastq=.adapter_removed.fastq)
targets_reqc = $(targets_adapter_stripped:.fastq=_fastqc.data)
targets_aligned = $(fastq:.fastq=.$(chromosome).bam)

# Rules
all : qc strip-adapters reqc align
qc : $(addprefix qc1/,$(targets_qc))
strip-adapters : $(targets_adapter_stripped)
reqc : $(addprefix qc2/,$(targets_reqc))
align : $(targets_aligned)

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
	| samtools sort -O bam -T $(mktemp -d)/$@ /dev/stdin -o $@

%.bam.bai : %.bam
	samtools index $<

%.$(chromosome).bam : %.bam %.bam.bai
	samtools view -hb $< $(chromosome) > $@

# Remove files to be able to re-run sections of the pipeline
clean-all : clean-qc clean-strip-adapters clean-align
clean-qc :
	rm -rf qc1/ qc2/
clean-strip-adapters :
	rm -f $(targets_adapter_stripped)
clean-align :
	rm -f *.bam *.bai

.PHONY : all qc strip-adapters reqc align clean-all clean-qc clean-strip-adapters clean-align
