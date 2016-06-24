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
rnastar = $(genome_prefix)/STAR_gencode/
annotation = /archive/MCB5429/annotations/hs/GTF/gencode.v19.annotation_pc.gtf
threads = 1

# Functions and targets
fastq = $(notdir $(wildcard $(input_prefix)/*.fastq))
# Use sensible naming scheme of treatment next to file extension
fastq_symlinks = $(addsuffix .fastq,$(call status_move_to_end,	\
	$(basename $(fastq))))
status_move_to_end = $(foreach file,$1, $(shell echo "$(file)" | sed	\
-E -e 's/(.*)untr(.*)/\1\2_untr/' -e 's/(.*)treat(.*)/\1\2_treat/'))
symlink_hashmap = $(join $(addsuffix ~,$(fastq)), $(fastq_symlinks))
symlink_target = $(subst ~$1,,$(filter %~$1,$(symlink_hashmap)))
targets_qc = $(fastq_symlinks:.fastq=_fastqc.zip)
targets_trim = $(fastq_symlinks:.fastq=.trim.fastq.gz)
targets_align = $(fastq_symlinks:.fastq=_Aligned.out.sam)

# Rule sets
all : qc trim align
qc : $(targets_qc)
trim : $(targets_trim)
align : $(targets_align)

.PHONY : all qc trim align

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
