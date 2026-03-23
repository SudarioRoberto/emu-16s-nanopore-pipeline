#!/usr/bin/env bash
# ============================================================================
# Step 02: Quality and length filtering with chopper
# ============================================================================
# Removes low-quality and off-target-length reads.
# Full-length 16S rRNA is ~1,500 bp; the 1,200-1,900 bp window accommodates
# Nanopore read length variation while excluding non-target amplicons.
# Head/tail cropping removes adapter ligation artifacts and noisy bases.
#
# Tool: chopper (Rust-based, preferred over NanoFilt per De Coster et al. 2023)
#
# Input:  data/concatenated/<sample>.fastq.gz
# Output: data/filtered/<sample>_filt.fastq.gz
# Expected retention: ~85-95% of reads
#
# Usage: bash scripts/02_quality_filter.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "============================================"
echo " Step 02: Quality filtering (chopper)"
echo " Parameters: Q>=${MIN_QUALITY}, ${MIN_LENGTH}-${MAX_LENGTH} bp"
echo "             headcrop=${HEAD_CROP}, tailcrop=${TAIL_CROP}"
echo " Date: $(date)"
echo "============================================"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${FILTERED_DIR}" "${LOG_DIR}"

TOTAL=$(wc -l < "${SAMPLE_LIST}")
COUNT=0

while IFS= read -r SAMPLE; do
    COUNT=$((COUNT + 1))

    INPUT="${CONCAT_DIR}/${SAMPLE}.fastq.gz"
    OUTPUT="${FILTERED_DIR}/${SAMPLE}_filt.fastq.gz"

    if [ -f "${OUTPUT}" ]; then
        echo "[${COUNT}/${TOTAL}] ${SAMPLE}: already filtered, skipping."
        continue
    fi

    if [ ! -f "${INPUT}" ]; then
        echo "[${COUNT}/${TOTAL}] ${SAMPLE}: WARNING input not found, skipping."
        continue
    fi

    RAW=$(seqkit stats -T "${INPUT}" | awk 'NR==2{print $4}')

    gunzip -c "${INPUT}" \
        | chopper \
            -q "${MIN_QUALITY}" \
            -l "${MIN_LENGTH}" \
            --maxlength "${MAX_LENGTH}" \
            --headcrop "${HEAD_CROP}" \
            --tailcrop "${TAIL_CROP}" \
        | gzip > "${OUTPUT}"

    FILT=$(seqkit stats -T "${OUTPUT}" | awk 'NR==2{print $4}')
    PCT=$(echo "scale=1; ${FILT} * 100 / ${RAW}" | bc)

    echo "[${COUNT}/${TOTAL}] ${SAMPLE}: ${RAW} -> ${FILT} reads (${PCT}% retained)"

    echo -e "step02_filter\t${SAMPLE}\t${RAW}\t${FILT}\t${PCT}%\t$(date '+%Y-%m-%d %H:%M')" >> "${LOG_DIR}/pipeline_log.tsv"

    if (( $(echo "${PCT} < 20" | bc -l) )); then
        echo "  WARNING: Retention < 20% — investigate quality distribution"
    fi

done < "${SAMPLE_LIST}"

echo ""
echo "============================================"
echo " Step 02 complete: ${COUNT} samples filtered"
echo " Output: ${FILTERED_DIR}/"
echo " Next: bash scripts/03_trim_primers.sh"
echo "============================================"
