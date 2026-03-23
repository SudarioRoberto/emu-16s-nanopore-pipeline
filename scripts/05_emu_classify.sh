#!/usr/bin/env bash
# ============================================================================
# Step 05: Emu taxonomic classification
# ============================================================================
# Classifies trimmed reads against the Emu default database using minimap2
# alignment and an expectation-maximization (EM) algorithm.
#
# Unlike OTU-based pipelines, Emu works directly on reads — no dereplication
# or clustering needed. Each read is mapped to the reference database and
# species-level abundances are estimated via EM.
#
# Input:  data/trimmed/<sample>_trimmed.fastq.gz
# Output: results/emu_per_sample/<sample>/ (per-sample abundance tables)
#
# Usage: bash scripts/05_emu_classify.sh
#
# To process samples in parallel (e.g., 4 at a time):
#   bash scripts/05_emu_classify.sh --parallel 4

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

# Parse --parallel flag
JOBS=1
if [[ "${1:-}" == "--parallel" ]] && [[ -n "${2:-}" ]]; then
    JOBS="$2"
fi

echo "============================================"
echo " Step 05: Emu classification"
echo " Database: ${EMU_DB_DIR}"
echo " Threads per sample: ${EMU_THREADS}"
echo " Parallel samples: ${JOBS}"
echo " Date: $(date)"
echo "============================================"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${EMU_OUTPUT_DIR}" "${LOG_DIR}"

# Verify database
if [ ! -f "${EMU_DB_DIR}/species_taxid.fasta" ]; then
    echo "ERROR: Emu database not found at ${EMU_DB_DIR}/"
    echo "Run step 04 first: bash scripts/04_download_emu_db.sh"
    exit 1
fi

classify_sample() {
    local SAMPLE="$1"
    local INPUT="${TRIMMED_DIR}/${SAMPLE}_trimmed.fastq.gz"
    local SAMPLE_OUT="${EMU_OUTPUT_DIR}/${SAMPLE}"

    if [ ! -f "${INPUT}" ]; then
        echo "  WARNING: Input not found for ${SAMPLE}, skipping."
        return
    fi

    # Skip if already classified
    if ls "${SAMPLE_OUT}/"*_rel-abundance.tsv &>/dev/null 2>&1; then
        echo "  ${SAMPLE}: already classified, skipping."
        return
    fi

    mkdir -p "${SAMPLE_OUT}"

    emu abundance "${INPUT}" \
        --db "${EMU_DB_DIR}" \
        --output-dir "${SAMPLE_OUT}" \
        --output-basename "${SAMPLE}" \
        --threads "${EMU_THREADS}" \
        --type "${EMU_TYPE}" \
        --keep-counts \
        --keep-read-assignments \
        --output-unclassified

    # Log results
    TOTAL_READS=$(zcat "${INPUT}" | awk 'NR%4==1' | wc -l)
    EMU_TSV=$(ls "${SAMPLE_OUT}/${SAMPLE}"*_rel-abundance.tsv 2>/dev/null | head -1)
    N_TAXA="NA"
    if [ -f "${EMU_TSV}" ]; then
        N_TAXA=$(tail -n +2 "${EMU_TSV}" | wc -l)
    fi

    echo "  ${SAMPLE}: ${TOTAL_READS} reads -> ${N_TAXA} taxa"
    echo -e "step05_emu\t${SAMPLE}\t${TOTAL_READS}\t${N_TAXA}\t$(date '+%Y-%m-%d %H:%M')" >> "${LOG_DIR}/pipeline_log.tsv"
}

export -f classify_sample
export TRIMMED_DIR EMU_OUTPUT_DIR EMU_DB_DIR EMU_THREADS EMU_TYPE LOG_DIR
export CONDA_DEFAULT_ENV="${CONDA_ENV}"

TOTAL=$(wc -l < "${SAMPLE_LIST}")
echo "Processing ${TOTAL} samples..."
echo ""

if [ "${JOBS}" -gt 1 ] && command -v parallel &>/dev/null; then
    echo "Running ${JOBS} samples in parallel using GNU parallel..."
    cat "${SAMPLE_LIST}" | parallel -j "${JOBS}" classify_sample {}
else
    if [ "${JOBS}" -gt 1 ]; then
        echo "NOTE: GNU parallel not found, running sequentially."
        echo "Install with: conda install -c conda-forge parallel"
    fi
    COUNT=0
    while IFS= read -r SAMPLE; do
        COUNT=$((COUNT + 1))
        echo "[${COUNT}/${TOTAL}] Classifying: ${SAMPLE}"
        classify_sample "${SAMPLE}"
    done < "${SAMPLE_LIST}"
fi

echo ""
echo "============================================"
echo " Step 05 complete"
echo " Output: ${EMU_OUTPUT_DIR}/"
echo " Next: bash scripts/06_combine_results.sh"
echo "============================================"
