## RNA-seq analysis

## Configuration settings
files.htseq <- Sys.glob("*.htseq")
file.genes <- "/archive/MCB5429/annotations/hs/Beds/hg19_gencode_ENSG_geneID.bed"

########################################################################
## 2.2 Comparison of replicates

## Read in the HTseq output as a data.frame
counts <- do.call(cbind.data.frame,
                  lapply(files.htseq, read.delim, header=FALSE,
                         sep="\t", row.names=1,
                         col.names=c("gene.id", "counts")))
## Set the column name to the filenames, but without the prefix and
## file extension
col.names <- unlist(lapply(files.htseq, gsub,
                           pattern="^RNAseq_(.*)_(.*)[.]htseq$",
                           replacement="\\2.\\1"))
names(counts) <- col.names
## Drop the last 5 rows since they have summary statistics instead of
## gene counts
counts <- head(counts, -5)

## Convert counts to FPKM
col.names.bed <- c("chrom", "start", "end", "gene.id", "score", "strand")
genes <- read.delim(file.genes, header=FALSE, sep="\t",
                    col.names=col.names.bed)
genes$length <- genes$end - genes$start
## Prepare to merge data.frames
counts$gene.id <- rownames(counts)
rownames(counts) <- NULL
## Remove .NN suffix to match gene.id
counts$gene.id <- sub("\\..*", "", counts$gene.id)
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
ggsave("treat_correlation.png")
cor.untr <- cor(fpkm$untr.1, fpkm$untr.2)
ggplot(log2(fpkm), aes(untr.1, untr.2)) +
    geom_point() + geom_smooth() +
    annotate("text", label = sprintf("Correlation = %f", cor.untr),
             x = 0, y = -10)
ggsave("untr_correlation.png")
