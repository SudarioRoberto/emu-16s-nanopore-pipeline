# Example Sample: Run01_soil_barcode01

This directory contains intermediate files from **one sample** (Run01_soil_barcode01) at every step of the Emu default pipeline, for verification and review.

## Files at each step

### Step 01 — Concatenated raw reads
```
step01_concatenated/Run01_soil_barcode01.fastq.gz
```
Multiple split FASTQ files from MinKNOW merged into one file.

### Step 02 — Quality filtered
```
step02_filtered/Run01_soil_barcode01_filt.fastq.gz
```
After chopper filtering: Q >= 12, length 1,200-1,900 bp, head/tail crop 20 bp.

### Step 03 — Primer trimmed
```
step03_trimmed/Run01_soil_barcode01_trimmed.fastq.gz
```
After cutadapt: residual 27F/1492R primers and rapid attachment tags removed.

### Step 05 — Emu classification output
```
step05_emu_output/
  Run01_soil_barcode01_rel-abundance.tsv           <- Taxonomic abundances
  Run01_soil_barcode01_read-assignment-distributions.tsv  <- Per-read assignments
  Run01_soil_barcode01_unclassified_mapped.fastq   <- Reads that mapped but couldn't be classified
  Run01_soil_barcode01_unmapped.fastq              <- Reads that didn't map to database
```

## Quick verification

To check read counts at each step:
```bash
conda activate emu_16s_pipeline
seqkit stats -T step01_concatenated/*.fastq.gz
seqkit stats -T step02_filtered/*.fastq.gz
seqkit stats -T step03_trimmed/*.fastq.gz
```
