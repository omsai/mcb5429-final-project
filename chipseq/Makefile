# ChIP-seq analysis
#
# To take advantage of parallel processes in this script, on a
# cluster you must request additional CPU cores from the scheduler.
# As there are 6 input files, using 6 CPU cores would be optimal:
#
#     $ qrsh -pe smp 6
#
# Then enter the directory containing this Makefile and run it with:
#
#     $ make -j 6 && exit


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
scratch = /scratch

# Functions and targets
SHELL = /bin/bash # For using <( cmd ) process substitution
this_makefile = $(lastword $(MAKEFILE_LIST))
fastq = $(notdir $(wildcard $(input_prefix)/*.fastq))
define fastq_symlinks
	$(addsuffix .fastq, \
	$(call strip_underscores, \
	$(call rename, \
	$(basename $(fastq)))))
endef
# Rename to format <dataset>_<treatment>_<type>, where <dataset> is
# omitted for the input.
define rename
	$(foreach file,$1, \
	$(shell echo "$(file)" | \
	sed -E \
	-e 's/(.*)_untr(.*)/\2_untr_\1/' \
	-e 's/(.*)_treat(.*)/\2_treat_\1/' \
	-e 's/ChIPseq/chip/' \
	-e 's/Input/input/' \
	-e 's/^([0-9]+)/rep_\1/' \
	))
endef
define strip_underscores
	$(foreach file,$1, \
	$(shell echo "$(file)" | \
	sed \
	-e 's/__/_/g' \
	-e 's/^_//'))
endef
define strip_type
	$(sort \
	$(foreach file,$1, \
	$(shell echo "$(file)" | \
	sed -E \
	-e 's/(.*)_input(.*)/\1\2/' \
	-e 's/(.*)_chip(.*)/\1\2/')))
endef
symlink_hashmap = $(join $(addsuffix ~,$(fastq)), $(fastq_symlinks))
symlink_target = $(subst ~$1,,$(filter %~$1,$(symlink_hashmap)))
colorize = $(if $(findstring untr,$(call filestem $1)) \
	,$(color_untreated),$(color_treated))
targets_qc = $(fastq_symlinks:.fastq=_fastqc.data)
targets_aligned = $(fastq_symlinks:.fastq=.$(chromosome).bam)
targets_reqc = $(fastq_symlinks:.fastq=.adapter_removed_fastqc.data)
targets_bedgraph = $(fastq_symlinks:.fastq=.$(chromosome).bedgraph)
controls_peak_calls = treat_input.$(chromosome).bam untr_input.$(chromosome).bam
control = $(filter $(subst _, ,$*)%,$(controls_peak_calls))
targets_peak_calls = $(filter rep%,$(call				\
strip_type,$(fastq_symlinks:.fastq=.$(chromosome)_summits.bed)))
targets_peak_calls_pdfs = $(targets_peak_calls:summits.bed=model.pdf)
targets_peak_sequences = $(targets_peak_calls:.bed=.top200.fa)
targets_motif_aligned = $(targets_peak_calls:.bed=.top200.motif.aligned/mast.txt)
prereq_summary = $(fastq_symlinks:.fastq=.summary_reads.csv)

# Rules
all : qc reqc align bedgraph peak-calls peak-calls-pdfs peak-sequences motif-aligned summary
qc : $(targets_qc)
reqc : $(targets_reqc)
align : $(targets_aligned)
bedgraph : $(targets_bedgraph)
peak-calls : $(targets_peak_calls)
peak-calls-pdfs : $(targets_peak_calls_pdfs)
peak-sequences : $(targets_peak_sequences)
motif-aligned : $(targets_motif_aligned)
summary : summary_reads.csv

.PHONY : all qc reqc align bedgraph peak-calls peak-calls-pdfs	\
	peak-sequences motif-aligned summary

# Rename files to group treatment and type with file extension
#
# The input fastq names have type `ChIPseq' / `Input' at the
# beginning, and treatment `untr' / `treat' in the middle of the file
# name instead of towards the end.  This makes them difficult to
# distinguish by make rules, which relate files by extensions
# (i.e. differences at the end instead of the middle).  Therefore we
# need to create make-friendly symlinks to the real fastq inputs.
%_chip.fastq :
	ln -s $(input_prefix)/$(call symlink_target,$@) $@
%_input.fastq :
	ln -s $(input_prefix)/$(call symlink_target,$@) $@

# QC
%_fastqc.zip : %.fastq
	fastqc -t $(threads) $<

# Extract FastQC text file to see overrepresented sequences, etc
%_fastqc.data : %_fastqc.zip
	unzip -p $< $(basename $<)/fastqc_data.txt > $@

# Remove adapters
%.adapter_removed.fastq : %.fastq
	fastx_clipper -v -Q 33 -a $(adapter) -i $< -o $@ > $@.out

# Align reads as sorted bam file.
%.sam : %.adapter_removed.fastq
	bowtie -v2 -m1 --sam --time --threads $(threads) $(bowtie_index) $< \
	2> $@.out > $@

# Convert sam to unsorted bam
%.unsorted.bam : %.sam
	samtools view -hb $< -o $@ 2>&1 > $@.out

# Sort bam
%.sorted.bam : %.unsorted.bam
	samtools sort -T $(scratch)/$< -O bam $< -o $@ 2>&1 > $@.out
	rm -f $(scratch)/$<*

# Create index to be able to subset aligned file
%.sorted.bam.bai : %.sorted.bam
	samtools index $< 2>&1 > $@.out

# Subset to one chromosome
%.$(chromosome).bam : %.sorted.bam %.sorted.bam.bai
	samtools view -hb $< $(chromosome) -o $@ 2>&1 > $@.out

# Create sorted bed file
%.$(chromosome).bed : %.$(chromosome).bam
	bedtools bamtobed -i $< > $@ 2> $@.out

# Create bedgraph header for tracklines
%.bedgraph.header :
	echo 'track type=bedGraph name="$(call filestem,$@)_bedgraph"' > $@
	echo 'visibility=full autoScale=on alwaysZero=on' >> $@
	echo 'color=$(call colorize,$@) windowingFunction=maximum' >> $@

# Create bedgraph
%.bedgraph : %.bed %.bedgraph.header
	cat \
	$(lastword $^) \
	<( bedtools genomecov -bg -i $< -g $(genome_chromosome_sizes) ) \
	> $@

# Call peaks and create PDF model images of the peak calls
%.$(chromosome)_summits.bed %.$(chromosome)_model.r : %_chip.$(chromosome).bam $(controls_peak_calls)
	macs14 --gsize=$(chromosome_size) --name=$*.$(chromosome)	\
	--treatment=$< --control=$(control) 2> $@.out

# We need `--vanilla` due to a race condition of R depending on
# .RDataTmp/.RData files
%_model.pdf : %_model.r | peak-calls
	R CMD BATCH --vanilla $<

# Get sequence around top 200 peaks
%.$(chromosome)_summits.top200.fa : %.$(chromosome)_summits.bed
	sort -n -r -k5 $< | head -200 \
	| bedtools slop -i /dev/stdin -g $(genome_chromosome_sizes) -b 50 \
	| bedtools getfasta -fi $(chromosome_fasta) -bed /dev/stdin -fo $@

# Find 2 motifs in treated and untreated sequences
%.motif/meme.txt : %.fa
	meme $< -dna -nmotifs 2 -minw 5 -maxw 10 -revcomp -mod zoops -oc $(@D)

# Align motifs and count
%.motif.aligned/mast.txt : %.motif/meme.txt %.fa
	mast $< $(lastword $^) -oc $(@D)

# Summary files
%.summary_reads.csv : | align
	printf 'dataset.name,reads.before.processing,reads.without.adapters,reads.mapped.uniquely,reads.mapped.to.multiple.places\n$(subst _,.,$*)' > $@
	awk '/^I/{printf ",%s",$$2} /^O/{printf ",%s",$$2}' $*.adapter_removed.fastq.out >> $@
	awk -v FS=: 'function p(){split($$2,a," ");printf ",%s",a[1]} /^#.*report/{p()} /^#.*supp/{p()} END{printf "\n"}' $*.sam.out >> $@

summary_reads.csv : $(prereq_summary)
	head -1 $< > $@ && tail -q -n1 $^ >> $@

# Remove files to be able to re-run sections of the pipeline
clean-all : clean-qc clean-align clean-bedgraph clean-peak-calls	\
	clean-peak-sequences clean-motif-sequences			\
	clean-motif-aligned clean-output clean-summary
clean-qc :
	rm -f *.data *.html
clean-align :
	rm -f *.$(chromosome).bam *.sorted.bam *.sorted.bam.bai *.unsorted.bam
clean-bedgraph :
	rm -f *.bedgraph
clean-peak-calls :
	rm -f *_model.r *_model.r.Rout *_model.pdf *_peaks.xls *_peaks.bed *_summits.bed
clean-peak-sequences :
	rm -f *.fa
clean-motif-sequences :
	rm -rf *.motif/
clean-motif-aligned :
	rm -rf *.aligned/
clean-output :
	rm -f *.out
clean-summary :
	rm -f *.csv
.PHONY : clean-all clean-qc clean-align clean-bedgraph		\
	clean-peak-sequences clean-motif-aligned clean-output
