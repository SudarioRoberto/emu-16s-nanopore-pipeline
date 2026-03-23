#!/usr/bin/env bash
# ============================================================================
# Run the full Emu 16S Nanopore pipeline (all steps sequentially)
# ============================================================================
# Usage: bash scripts/run_all.sh
#
# This runs steps 01 through 06 in order. Step 00 (environment setup) and
# Step 04 (database download) are prerequisites that must be run manually first.
#
# To run with parallel sample processing:
#   PARALLEL_JOBS=4 bash scripts/run_all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "========================================================"
echo " Emu 16S Nanopore Pipeline — Full Run"
echo " Date: $(date)"
echo "========================================================"

# Check prerequisites
source "$(conda info --base)/etc/profile.d/conda.sh"

if ! conda env list | grep -q "^${CONDA_ENV} "; then
    echo "ERROR: Conda environment '${CONDA_ENV}' not found."
    echo "Run first: bash scripts/00_setup_env.sh"
    exit 1
fi

if [ ! -f "${EMU_DB_DIR}/species_taxid.fasta" ]; then
    echo "ERROR: Emu database not found."
    echo "Run first: bash scripts/04_download_emu_db.sh"
    exit 1
fi

if [ ! -f "${SAMPLE_LIST}" ]; then
    echo "ERROR: Sample list not found: ${SAMPLE_LIST}"
    exit 1
fi

echo ""
echo "Samples: $(wc -l < "${SAMPLE_LIST}")"
echo "Parallel jobs: ${PARALLEL_JOBS}"
echo ""

# Run pipeline steps
bash "${SCRIPT_DIR}/01_concatenate.sh"
echo ""

bash "${SCRIPT_DIR}/02_quality_filter.sh"
echo ""

bash "${SCRIPT_DIR}/03_trim_primers.sh"
echo ""

bash "${SCRIPT_DIR}/05_emu_classify.sh" --parallel "${PARALLEL_JOBS}"
echo ""

bash "${SCRIPT_DIR}/06_combine_results.sh"

echo ""
echo "========================================================"
echo " Pipeline complete!"
echo " Results: ${EMU_COMBINED_DIR}/"
echo " Log: ${LOG_DIR}/pipeline_log.tsv"
echo " Date: $(date)"
echo "========================================================"
