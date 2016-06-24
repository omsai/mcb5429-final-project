# RNA-seq analysis
# 
# Alignment takes a lot of memory and time.  Therefore, it is better
# to parallelize just the `align' step using threads instead of
# multiple make jobs:
#
#   $ qrsh -pe smp 8
#   $ cd path/to/this/directory
#   $ make threads=8 align
#
# Then run the the rest of the pipeline with one job for each input
# file:
#
#   $ make -j4 threads=2 && exit


# Configuration settings
input_prefix = /archive/MCB5429/Final_data/RNAseq/
genome = hg19
genome_prefix = /archive/MCB5429/genomes/$(genome)
genome_chromosome_sizes = $(genome_prefix)/$(genome)_chromInfo.txt
rnastar = $(genome_prefix)/STAR_gencode/
annotation = /archive/MCB5429/annotations/hs/GTF/gencode.v19.annotation_pc.gtf
color_untreated = 0,0,125
color_treated = 125,0,0
scratch = /scratch/$(USER)
threads = 1

# Functions and targets
SHELL = /bin/bash # For using <( cmd ) process substitution
fastq = $(notdir $(wildcard $(input_prefix)/*.fastq))
# Use sensible naming scheme of treatment next to file extension
fastq_symlinks = $(addsuffix .fastq,$(call status_move_to_end,	\
	$(basename $(fastq))))
status_move_to_end = $(foreach file,$1, $(shell echo "$(file)" | sed	\
-E -e 's/(.*)untr(.*)/\1\2_untr/' -e 's/(.*)treat(.*)/\1\2_treat/'))
symlink_hashmap = $(join $(addsuffix ~,$(fastq)), $(fastq_symlinks))
symlink_target = $(subst ~$1,,$(filter %~$1,$(symlink_hashmap)))
colorize = $(if $(findstring			\
untr,$1),$(color_untreated),$(color_treated))
targets_qc = $(fastq_symlinks:.fastq=_fastqc.zip)
targets_trim = $(fastq_symlinks:.fastq=.trim.fastq.gz)
targets_align = $(fastq_symlinks:.fastq=_Aligned.out.sam)
targets_bedgraph = $(fastq_symlinks:.fastq=.bedgraph) \
	$(fastq_symlinks:.fastq=.sorted.sam) \
	$(fastq_symlinks:.fastq=.bed)
targets_htseq = $(fastq_symlinks:.fastq=.htseq)

# Rule sets
all : qc trim align bedgraph htseq
qc : $(targets_qc)
trim : $(targets_trim)
align : $(targets_align)
bedgraph : $(targets_bedgraph)
htseq : $(targets_htseq)

.PHONY : all qc trim align bedgraph htseq

# Rules

# Sensible file naming of treatment status grouped with file extension
%_treat.fastq :
	ln -s $(input_prefix)/$(call symlink_target,$@) $@
%_untr.fastq :
	ln -s $(input_prefix)/$(call symlink_target,$@) $@

# QC
%_fastqc.zip : %.fastq
	fastqc -t $(threads) -o . $<

# Trim reads wtih quality score < 20
%.trim.fastq.gz : %.fastq
	fastq_quality_trimmer -zv -t20 -Q33 -i $< -o $@

# Align
%_Aligned.out.sam : %.trim.fastq.gz
	STAR --runThreadN $(threads) --genomeDir $(rnastar) \
	--readFilesIn $< --readFilesCommand zcat \
	--sjdbGTFfile $(annotation) --outFileNamePrefix $*_

# Sort
%.sorted.sam : %_Aligned.out.sam
	mkdir -p $(scratch)
	samtools view -@ $(threads) -hb $< \
        | samtools sort -@ $(threads) -O sam \
	-T $$(mktemp -d --tmpdir=$(scratch))/$@ \
	/dev/stdin -o $@
	@echo Cleaning scratch directory $(scratch)
	find $(scratch) -name '$@*' -exec sh -c 'dirname {} | xargs rm -rf' \;

# Create bedgraph header for tracklines
%.bedgraph.header :
	echo 'track type=bedGraph name="$*_bedgraph"' > $@
	echo 'visibility=full autoScale=on alwaysZero=on' >> $@
	echo 'color=$(call colorize,$@) windowingFunction=maximum' >> $@

# Convert sam to bam for bedgraph
%.bam : %.sam
	samtools view -@ $(threads) -hb $< > $@

# Convert bam to bed for bedgraph
%.bed : %.sorted.bam
	bedtools bamtobed -i $< > $@

# Create bedgraph
%.bedgraph : %.bed %.bedgraph.header
	cat $(lastword $^) <( bedtools genomecov -bg -i $< -g $(genome_chromosome_sizes) ) > $@

# HTSeq to quantify reads in transcripts
%.htseq : %.sorted.sam
	htseq-count -i gene_id $< $(annotation) > $@
