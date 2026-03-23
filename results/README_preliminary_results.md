# 16S Nanopore Microbiome Pipeline — Preliminary Results

**Date**: March 16, 2026
**Prepared by**: Silvaju
**Status**: Pipeline complete; GG2 phylogenetic tree in progress

---

## 1. Study Overview

Full-length 16S rRNA amplicon sequencing (Oxford Nanopore, SQK-16S114-24 kit) of 148 samples across 7 sequencing runs:

| Sample Type | Runs | Number of Samples |
|---|---|---|
| Soil | Run01, Run02 | 46 |
| Swabs | Run03, Run04 | 47 |
| Fecal | Run05, Run06, Run07 | 55 |
| **Total** | **7 runs** | **148 samples** |

**Sequencing**: MinKNOW v24.02.16, super-accuracy basecalling, R10.4.1 flow cell.

---

## 2. Pipeline Summary

| Step | Tool | Description |
|---|---|---|
| 0. Concatenation | cat + seqkit | Merge per-barcode FASTQs into one file per sample |
| 1. Quality filtering | chopper v0.11.0 | Q >= 12, length 1,200–1,900 bp, head/tail crop 20 bp |
| 2. Primer trimming | cutadapt v4.9 | Remove residual 27F/1492R primers + rapid attachment tags |
| 3. QIIME 2 import | QIIME 2 (2024.10) | Import into single artifact |
| 4. Chimera removal | — | Skipped (see Section 5) |
| 5. OTU clustering | q2-vsearch | Dereplication + 97% identity de novo clustering |
| 6. Taxonomy (SILVA) | q2-feature-classifier | SILVA 138.1, Naive Bayes, confidence 0.7 |
| 7. Taxonomy (GG2) | q2-feature-classifier | Greengenes2 2024.09, Naive Bayes, confidence 0.7 |
| 8. Phylogenetic tree | SEPP (q2-fragment-insertion) | Fragment insertion into Greengenes 13_8 backbone |
| 9. Export | biom | BIOM, TSV, collapsed tables (family/genus/species), Newick tree |

**Framework**: QIIME 2 amplicon-2024.10 on MSI Agate (SLURM).

---

## 3. Read Retention Through the Pipeline

### 3.1 Overall flow

```
Raw reads:                 5,770,231  (148 samples)
  Quality filtered:       ~5,414,765  (retention ~90%)
    Primer trimmed:       ~5,414,765  (retention ~100%)
      OTU clustered (97%): 1,478,337 OTUs
```

### 3.2 After taxonomic classification and filtering

Two classifiers were used independently to maximize read retention:

| Metric | SILVA 138.1 | Greengenes2 2024.09 |
|---|---|---|
| Classification rate | 79.3% | 72.7% |
| Bacterial OTUs retained | 700,513 | 1,066,307 |
| Bacterial reads retained | 2,624,306 | 3,961,338 |
| Samples retained | 147 | 148 |
| Median reads/sample | 7,224 | 16,248 |

**Key finding**: Greengenes2 retains **51% more reads** than SILVA. Many OTUs that SILVA classified as "Unassigned" are classified as Bacteria by GG2. GG2 also recovers 1 sample (Run02_soil_barcode22) that SILVA dropped entirely.

### 3.3 Average per-sample retention (raw reads to final bacterial reads)

| Sample Type | SILVA Retention | GG2 Retention |
|---|---|---|
| Soil (n=43–44) | 22.0% | 62.2% |
| Swabs (n=45) | 41.1% | 81.1% |
| Fecal (n=52) | 26.4% | 64.7% |
| **Overall** | **29.8%** | **69.1%** |

The main sources of read loss are:
1. **Quality filtering** (~10% loss): Reads outside Q >= 12 or 1,200–1,900 bp length range
2. **Taxonomy classification** (~50% loss with SILVA, ~27% with GG2): Reads classified as Eukaryota, Mitochondria, Chloroplast, or Unassigned

### 3.4 SILVA phylogenetic tree (SEPP)

For phylogenetic diversity analyses (UniFrac), a low-abundance OTU filter (>= 10 reads) was applied before tree construction:

| Metric | Value |
|---|---|
| OTUs in tree | 15,751 |
| Reads in tree | 1,747,002 |
| Samples | 147 |
| Median reads/sample | 7,224 |

A GG2 phylogenetic tree is currently being built (same SEPP approach), which will enable UniFrac analyses with the higher-retention GG2 dataset.

---

## 4. SILVA vs. Greengenes2 — Classifier Comparison

| | SILVA 138.1 | Greengenes2 2024.09 |
|---|---|---|
| Total OTUs classified as Bacteria | 700,513 | 1,066,307 |
| Total bacterial reads | 2,624,306 | 3,961,338 |
| Unassigned OTUs | 305,535 (20.7%) | 404,183 (27.3%) |
| Eukaryota flagged | 382,316 | 7,847 |
| Samples with data | 147 | 148 |

SILVA flagged a large number of OTUs as Eukaryota (Cnidaria/Myxozoa — likely host DNA or parasites). GG2 classifies many of these same OTUs as Bacteria, which explains the higher retention. Both classifiers agree on the dominant bacterial phyla.

**Recommendation**: Use the GG2-classified table as the primary dataset for downstream analysis due to substantially higher read retention. SILVA results are available as a secondary reference.

---

## 5. Key Methodological Decisions

1. **Chimera removal skipped**: Nanopore error rates (1–5%) create millions of unique sequences after dereplication, making UCHIME de novo computationally intractable. OTU clustering at 97% implicitly collapses chimeric reads. This is consistent with published Nanopore 16S workflows.

2. **97% OTU clustering** (not 99%): Nanopore error rates mean 99% clusters fragment the same species into noise OTUs and was computationally intractable (>10h). 97% is the established standard for species-level 16S resolution.

3. **No singleton removal before clustering**: Unlike Illumina data, Nanopore errors cause nearly every dereplicated sequence to be unique. Removing singletons before clustering would discard 99.7% of reads. Post-clustering, low-abundance OTUs (< 10 reads) are removed only for phylogenetic tree construction.

4. **No `--discard-untrimmed` in cutadapt**: MinKNOW already removed primers from ~90% of reads during demultiplexing. Discarding "untrimmed" reads would remove these already-clean reads (initial test: 3.3% retention vs. ~100% without the flag).

5. **SEPP fragment insertion** (not de novo tree): De novo alignment (MAFFT) + tree building (FastTree) timed out after 24h on 700K OTUs. SEPP places fragments into a curated reference phylogeny (Greengenes 13_8), which is both computationally tractable and recommended for large amplicon datasets.

---

## 6. Output Files

### Primary results (GG2 — higher retention)
```
results/gg2/
  table_with_taxonomy.biom    — Full OTU table with GG2 taxonomy (1.07M OTUs, 148 samples)
  table_with_taxonomy.tsv     — Same as above in tab-delimited format
  table_L5.tsv                — Collapsed at family level
  table_L6.tsv                — Collapsed at genus level
  table_L7.tsv                — Collapsed at species level
  table_summary.txt           — Sample read count summary
```

### SILVA results (with phylogenetic tree)
```
results/
  table_with_taxonomy.biom    — OTU table with SILVA taxonomy (15,751 OTUs, 147 samples)
  table_with_taxonomy.tsv     — Tab-delimited format
  table_L5.tsv                — Family level
  table_L6.tsv                — Genus level
  table_L7.tsv                — Species level
  sepp_tree.nwk               — Phylogenetic tree (Newick format, for UniFrac)
  table_summary.txt           — Sample read count summary
  per_sample_retention.csv    — Read counts at every pipeline step per sample
```

### In progress
```
results/gg2_tree/             — GG2 tree-filtered table + Newick tree (SEPP running)
```

---

## 7. Samples to Flag

The following samples have very low read counts (< 100 bacterial reads) and may need to be excluded from downstream analysis:

| Sample | GG2 Reads | SILVA Reads | Notes |
|---|---|---|---|
| Run02_soil_barcode22 | 1 | 0 (dropped) | Essentially no data |
| Run05_fecal_barcode20 | 6 | 3 | Near-zero |
| Run03_swab_barcode24 | 7 | 5 | Near-zero |
| Run03_swab_barcode05 | 33 | 15 | Very low |
| Run03_swab_barcode14 | 33 | 17 | Very low |
| Run03_swab_barcode15 | 80 | 30 | Very low |

These likely represent failed amplifications or barcode assignment errors.

---

## 8. Next Steps

1. **GG2 phylogenetic tree** — Currently running. Once complete, UniFrac analyses can use the GG2 dataset.
2. **Alpha diversity** — Rarefaction curves, Shannon, observed OTUs, Faith's PD (with tree).
3. **Beta diversity** — Bray-Curtis, weighted/unweighted UniFrac, PCoA ordination.
4. **Differential abundance** — Compare bacterial communities across soil, swab, and fecal sample types.
5. **Rarefaction depth** — Determine appropriate rarefaction depth based on sample read count distributions. With GG2 median of ~16K reads/sample, a depth of ~5,000–10,000 may be appropriate (balancing sample retention vs. depth).

---

## 9. Software Versions

| Software | Version |
|---|---|
| MinKNOW | v24.02.16 |
| seqkit | v2.11.0 |
| chopper | v0.11.0 |
| cutadapt | v4.9 |
| QIIME 2 | amplicon-2024.10 |
| SILVA | 138.1 |
| Greengenes2 | 2024.09 |
| SEPP reference | Greengenes 13_8 (99% OTUs) |
