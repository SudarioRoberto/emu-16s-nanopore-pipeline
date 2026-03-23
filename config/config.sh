#!/usr/bin/env bash
# ============================================================================
# Emu 16S Nanopore Pipeline — Configuration
# ============================================================================
# Edit the variables below to match your project before running the pipeline.

# --- Project paths --------------------------------------------------------
# Root directory of the project (all paths are relative to this)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Input: directory containing raw run folders
# Expected structure: RAW_RUN_DIR/<RunXX_type>/fastq_pass/barcodeXX/*.fastq.gz
RAW_RUN_DIR="${PROJECT_DIR}/data/raw_runs"

# Sample list: one sample ID per line (e.g., Run01_soil_barcode01)
SAMPLE_LIST="${PROJECT_DIR}/data/sample_list.txt"

# Output directories (created automatically)
CONCAT_DIR="${PROJECT_DIR}/data/concatenated"
FILTERED_DIR="${PROJECT_DIR}/data/filtered"
TRIMMED_DIR="${PROJECT_DIR}/data/trimmed"
EMU_OUTPUT_DIR="${PROJECT_DIR}/results/emu_per_sample"
EMU_COMBINED_DIR="${PROJECT_DIR}/results/emu_combined"
LOG_DIR="${PROJECT_DIR}/logs"

# Emu database
EMU_DB_DIR="${PROJECT_DIR}/data/emu_db"

# --- Conda environment name -----------------------------------------------
CONDA_ENV="emu_16s_pipeline"

# --- Quality filtering (chopper) ------------------------------------------
MIN_QUALITY=12           # Minimum Phred quality score
MIN_LENGTH=1200          # Minimum read length (bp)
MAX_LENGTH=1900          # Maximum read length (bp)
HEAD_CROP=20             # Bases to trim from read start
TAIL_CROP=20             # Bases to trim from read end

# --- Primer trimming (cutadapt) -------------------------------------------
# SQK-16S114-24 kit: Rapid Attachment Tag + 16S primers
# 5' adapter: tag (ATCGCCTACCGTGAC) + 27F (AGAGTTTGATCMTGGCTCAG)
ADAPTER_5="ATCGCCTACCGTGACAGAGTTTGATCMTGGCTCAG"
# 3' adapter: 1492R_RC (AAGTCGTAACAAGGTAACC) + tag_RC (GTCACGGTAGGCGAT)
ADAPTER_3="AAGTCGTAACAAGGTAACCGTCACGGTAGGCGAT"
CUTADAPT_ERROR_RATE=0.15   # 15% error tolerance (for Nanopore)
CUTADAPT_MIN_LENGTH=1200   # Discard reads shorter than this after trimming

# --- Emu classification ---------------------------------------------------
EMU_THREADS=8              # Threads per sample (adjust to your machine)
EMU_TYPE="map-ont"         # Minimap2 preset for Oxford Nanopore reads

# --- Parallel execution ----------------------------------------------------
# Number of samples to process in parallel (adjust to your CPU count)
PARALLEL_JOBS=4
