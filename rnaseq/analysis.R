## RNA-seq analysis

## Configuration settings
files.htseq <- Sys.glob("*.htseq")
file.genes <- "/archive/MCB5429/annotations/hs/Beds/hg19_gencode_ENSG_geneID.bed"

########################################################################
## 2.2 Comparison of replicates

## Read in the HTseq output as a data.frame
counts <- do.call(cbind.data.frame,
                  lapply(files.htseq, read.delim, header = FALSE,
                         sep = "\t", row.names = 1,
                         col.names = c("gene.id", "counts")))
## Set the column name to the filenames, but without the prefix and
## file extension
col.names <- unlist(lapply(files.htseq, gsub,
                           pattern = "^RNAseq_(.*)_(.*)[.]htseq$",
                           replacement = "\\2.\\1"))
names(counts) <- col.names
## Drop the last 5 rows since they have summary statistics instead of
## gene counts
counts <- head(counts, -5)

## Convert counts to FPKM
read.bed <- function (file.bed) {
    col.names.bed <- c("chrom", "start", "end", "name", "score",
                       "strand")
    bed <- read.delim(file.bed, header = FALSE, sep = "\t",
                      col.names = col.names.bed)
    ## Drop empty columns, with all NAs
    col.na <- sapply(bed, function(x) all(is.na(x)))
    col.keep <- names(col.na)[!col.na]
    bed[,col.keep]
}
genes <- read.bed(file.genes)
genes$length <- genes$end - genes$start
## Prepare to merge data.frames
counts$gene.id <- rownames(counts)
rownames(counts) <- NULL
## Remove .NN suffix to match gene.id
counts$gene.id <- sub("\\..*", "", counts$gene.id)
names(genes)[names(genes) == "name"] <- "gene.id"
merged <- merge(counts, genes)
## FPKM calculation per https://archive.is/V0bgu
fpkm <- exp(log(merged[,col.names]) + log(1e9) - log(merged$length) -
            log(colSums(merged[,col.names])))
## Plot
library(ggplot2)
cor.treat <- cor(fpkm$treat.1, fpkm$treat.2)
ggplot(log2(fpkm), aes(treat.1, treat.2)) +
    geom_point() + geom_smooth() +
    annotate("text", label = sprintf("Correlation = %f", cor.treat),
             x = 0, y = -10)
ggsave("treat_correlation.ps")
cor.untr <- cor(fpkm$untr.1, fpkm$untr.2)
ggplot(log2(fpkm), aes(untr.1, untr.2)) +
    geom_point() + geom_smooth() +
    annotate("text", label = sprintf("Correlation = %f", cor.untr),
             x = 0, y = -10)
ggsave("untr_correlation.ps")

########################################################################
## 2.3 Differential Gene Expression

suppressMessages(library(DESeq2))
## Create DESeq2 object using DESeqDataFromMatrix
## 
## Generate countData
countData <- merged[col.names]
rownames(countData) <- merged$gene.id
## Generate colData
conditioner <- function(s) if (grepl("untr", s)) "untreated" else "treated"
condition <- unlist(lapply(col.names, conditioner))
# See notes at end of section for how single-read was determined
type <- replicate(length(condition), "single-read")
colData <- cbind.data.frame(condition, type)
rownames(colData) <- col.names
## Combine into DESeq2 object
dds <- DESeqDataSetFromMatrix(countData = countData,
                              colData = colData,
                              design = ~ condition)
dds$condition <- relevel(dds$condition, ref = "untreated")
dds <- DESeq(dds)
res <- results(dds)
setEPS()
postscript("ma_plot.ps")
plotMA(res, ylim = c(-1.5, 2))
dev.off()
## Determined all 4 datasets are single ended and not paired end using
## RSeQC per https://www.biostars.org/p/66627/#134380:
##
## $ pip install --user RSeQC
## $ ls *.sorted.sam | xargs -n1 ~/.local/bin/infer_experiment.py \
##  -r /archive/MCB5429/annotations/hs/Beds/hg19_gencode_ENSG_geneID.bed -i
##  ...
##  This is SingleEnd Data
##  Fraction of reads failed to determine: 0.0150
##  Fraction of reads explained by "++,--": 0.4927
##  Fraction of reads explained by "+-,-+": 0.4923
##  ...

########################################################################
## 2.4 Parse out regulated genes

res.df <- as.data.frame(res)
## Get significant rows with pvalue < 0.05
res.df <- na.omit(res.df[res.df$pvalue < 0.05,])
## Regulated gene names
res.df$reg <- as.factor(ifelse(res.df$log2FoldChange > 0, "up", "down"))
reg <- rownames(res.df)
upReg <- rownames(res.df[res.df$reg == "up",])
downReg <- rownames(res.df[res.df$reg == "down",])
write.csv(res.df, file = "reg.csv", quote = FALSE)
