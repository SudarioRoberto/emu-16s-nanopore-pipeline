# Emu 16S Nanopore Microbiome Pipeline

A reproducible pipeline for full-length 16S rRNA amplicon analysis from Oxford Nanopore sequencing data using [Emu](https://github.com/treangenlab/emu) for taxonomic classification.

Designed for the **SQK-16S114-24** barcoding kit with R10.4.1 flow cells.

---

## Pipeline Overview

```
Raw Nanopore FASTQs (demultiplexed by MinKNOW)
  |
  v
Step 01: Concatenate split files per sample (cat + seqkit)
  |
  v
Step 02: Quality & length filtering (chopper)
  |        Q >= 12, length 1200-1900 bp, head/tail crop 20 bp
  v
Step 03: Primer & adapter trimming (cutadapt)
  |        Removes residual 27F/1492R primers + rapid attachment tags
  v
Step 04: Download Emu reference database (one-time)
  |        Default DB: rrnDB v5.6 + NCBI 16S RefSeq
  v
Step 05: Taxonomic classification (emu abundance)
  |        Minimap2 alignment + EM algorithm -> species-level abundances
  v
Step 06: Combine per-sample results into merged tables
           Species, genus, and family-level abundance tables
```

---

## Requirements

### Software

All tools are installed via a single conda environment. No other software is needed.

| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| [chopper](https://github.com/wdecoster/chopper) | 0.12.0 | Quality and length filtering (Rust-based) | bioconda |
| [seqkit](https://bioinf.shenwei.me/seqkit/) | 2.13.0 | FASTQ statistics and manipulation | bioconda |
| [cutadapt](https://cutadapt.readthedocs.io/) | 4.9 | Primer/adapter trimming | bioconda |
| [Emu](https://github.com/treangenlab/emu) | 3.6.2 | Taxonomic classification (EM + minimap2) | bioconda |

### System Requirements

- **OS**: Linux or macOS (tested on Linux x86_64)
- **RAM**: 8 GB minimum, 16+ GB recommended
- **Disk**: ~5 GB for the Emu database + space for your FASTQ data
- **CPU**: Multi-core recommended (Emu uses minimap2 for alignment)
- **Conda**: [Miniconda](https://docs.conda.io/en/latest/miniconda.html) or [Mamba](https://mamba.readthedocs.io/)

---

## Installation

### 1. Clone this repository

```bash
git clone https://github.com/YOUR_USERNAME/emu-16s-nanopore-pipeline.git
cd emu-16s-nanopore-pipeline
```

### 2. Create the conda environment

```bash
# Using conda
conda env create -f environment.yml

# Or using mamba (faster)
mamba env create -f environment.yml
```

Or run the setup script:

```bash
bash scripts/00_setup_env.sh
```

### 3. Download the Emu database

This requires internet access and only needs to be done once:

```bash
conda activate emu_16s_pipeline
bash scripts/04_download_emu_db.sh
```

The default database (rrnDB v5.6 + NCBI 16S RefSeq) will be downloaded from the [Open Science Framework](https://osf.io/56uf7/).

---

## Quick Start

### 1. Prepare your data

Place your raw MinKNOW output in `data/raw_runs/`:

```
data/raw_runs/
  Run01_soil_samples/
    fastq_pass/
      barcode01/
        file1.fastq.gz
        file2.fastq.gz
        ...
      barcode02/
        ...
  Run02_soil_samples/
    ...
```

### 2. Create a sample list

Create `data/sample_list.txt` with one sample ID per line:

```
Run01_soil_barcode01
Run01_soil_barcode02
Run02_soil_barcode01
Run03_swab_barcode01
Run05_fecal_barcode01
...
```

The naming convention is: `RunXX_<type>_barcodeXX` where type is `soil`, `swab`, or `fecal`.

### 3. Edit the configuration

Review and adjust `config/config.sh` if needed. The defaults match the SQK-16S114-24 kit parameters.

### 4. Run the pipeline

Run all steps at once:

```bash
bash scripts/run_all.sh
```

Or run each step individually:

```bash
bash scripts/01_concatenate.sh
bash scripts/02_quality_filter.sh
bash scripts/03_trim_primers.sh
bash scripts/05_emu_classify.sh               # sequential
bash scripts/05_emu_classify.sh --parallel 4   # 4 samples at a time
bash scripts/06_combine_results.sh
```

---

## Output

Final results are in `results/emu_combined/`:

| File | Description |
|------|-------------|
| `emu-combined-taxonomy-species.tsv` | Relative abundance at species level (all samples) |
| `emu-combined-taxonomy-genus.tsv` | Relative abundance at genus level |
| `emu-combined-taxonomy-family.tsv` | Relative abundance at family level |
| `emu-combined-abundance-species-counts.tsv` | Absolute read counts at species level |
| `emu-combined-abundance-genus-counts.tsv` | Absolute read counts at genus level |
| `emu-combined-abundance-family-counts.tsv` | Absolute read counts at family level |

Per-sample detailed output (read assignments, unclassified reads) is in `results/emu_per_sample/<sample>/`.

---

## Directory Structure

```
emu-16s-nanopore-pipeline/
├── README.md               <- This file
├── environment.yml         <- Conda environment definition
├── config/
│   └── config.sh           <- All pipeline parameters (edit this)
├── scripts/
│   ├── 00_setup_env.sh     <- Create conda environment
│   ├── 01_concatenate.sh   <- Merge split FASTQs per sample
│   ├── 02_quality_filter.sh <- Quality/length filtering (chopper)
│   ├── 03_trim_primers.sh  <- Primer/adapter trimming (cutadapt)
│   ├── 04_download_emu_db.sh <- Download Emu reference database
│   ├── 05_emu_classify.sh  <- Emu taxonomic classification
│   ├── 06_combine_results.sh <- Merge per-sample results
│   └── run_all.sh          <- Run full pipeline (steps 01-06)
├── data/
│   ├── raw_runs/           <- Raw MinKNOW output (user provides)
│   ├── sample_list.txt     <- Sample IDs (user creates)
│   ├── concatenated/       <- Step 01 output
│   ├── filtered/           <- Step 02 output
│   ├── trimmed/            <- Step 03 output
│   └── emu_db/             <- Emu reference database (Step 04)
├── results/
│   ├── emu_per_sample/     <- Step 05 output (per-sample)
│   └── emu_combined/       <- Step 06 output (merged tables)
└── logs/
    └── pipeline_log.tsv    <- Read counts at each step
```

---

## Configurable Parameters

All parameters are in `config/config.sh`:

### Quality Filtering (chopper)
| Parameter | Default | Description |
|-----------|---------|-------------|
| `MIN_QUALITY` | 12 | Minimum Phred quality score |
| `MIN_LENGTH` | 1200 | Minimum read length (bp) |
| `MAX_LENGTH` | 1900 | Maximum read length (bp) |
| `HEAD_CROP` | 20 | Bases trimmed from read start |
| `TAIL_CROP` | 20 | Bases trimmed from read end |

### Primer Trimming (cutadapt)
| Parameter | Default | Description |
|-----------|---------|-------------|
| `ADAPTER_5` | Tag + 27F | 5' adapter (rapid attachment tag + forward primer) |
| `ADAPTER_3` | 1492R_RC + Tag_RC | 3' adapter (reverse primer RC + tag RC) |
| `CUTADAPT_ERROR_RATE` | 0.15 | Error tolerance (15% for Nanopore) |

### Emu Classification
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EMU_THREADS` | 8 | Threads per sample |
| `EMU_TYPE` | map-ont | Minimap2 preset for Nanopore |
| `PARALLEL_JOBS` | 4 | Samples processed in parallel |

---

## Primer and Adapter Sequences

For the **SQK-16S114-24** barcoding kit:

| Name | Sequence (5' to 3') |
|------|---------------------|
| Rapid Attachment Tag | `ATCGCCTACCGTGAC` |
| 27F (forward primer) | `AGAGTTTGATCMTGGCTCAG` |
| 1492R (reverse primer) | `GGTTACCTTGTTACGACTT` |
| 1492R reverse complement | `AAGTCGTAACAAGGTAACC` |

The pipeline trims the combined tag + primer as a single adapter on each end.

**Note on MinKNOW pre-processing**: MinKNOW v24.02.16 removes primers and barcoding tags from ~90% of reads during demultiplexing. The cutadapt step catches the remaining ~10%. The `--discard-untrimmed` flag is intentionally NOT used to avoid discarding the already-cleaned reads.

---

## Sequencing Platform

This pipeline was developed for:

| Parameter | Value |
|-----------|-------|
| Platform | Oxford Nanopore Technologies |
| Flow cell | FLO-MIN114 (R10.4.1) |
| Sequencing kit | SQK-16S114-24 (16S barcoding) |
| Basecaller | MinKNOW v24.02.16 |
| Basecalling model | Super-accuracy |
| Target gene | Full-length 16S rRNA (~1,500 bp) |

---

## Key Design Decisions

1. **chopper over NanoFilt**: chopper is Rust-based, faster, and handles gzipped input natively (De Coster et al. 2023).

2. **No `--discard-untrimmed`**: MinKNOW already stripped primers from ~90% of reads. Using this flag would discard those clean reads (3.3% retention observed vs ~100% without).

3. **Emu over OTU-based approaches**: Emu's EM algorithm works directly on reads without dereplication or OTU clustering, avoiding the computational issues caused by Nanopore error rates generating millions of unique sequences.

4. **Default Emu database**: The rrnDB + NCBI 16S RefSeq database provides comprehensive coverage. Custom databases can be used by changing `EMU_DB_DIR` in the config.

---

## Adapting for Different Kits

To use this pipeline with a different sequencing kit:

1. Update the primer sequences in `config/config.sh` (`ADAPTER_5` and `ADAPTER_3`)
2. Adjust length filters if targeting a different 16S region (e.g., V3-V4 is ~460 bp)
3. If your kit does not use rapid attachment tags, remove the tag portions from the adapter sequences

---

## References

- Curry KD, et al. (2022). Emu: species-level microbial community profiling of full-length 16S rRNA Oxford Nanopore sequencing data. *Nature Methods*, 19, 845-853.
- De Coster W, et al. (2023). NanoPack2: population-scale evaluation of long-read sequencing data. *Bioinformatics*, 39(5).
- Martin M (2011). Cutadapt removes adapter sequences from high-throughput sequencing reads. *EMBnet.journal*, 17(1), 10-12.

---

## License

MIT
