#!/usr/bin/env bash
# ============================================================================
# Step 03: Primer and adapter trimming with cutadapt
# ============================================================================
# Removes residual primer and rapid attachment tag sequences.
#
# IMPORTANT: MinKNOW v24.02.16 already removes primers/tags from ~90% of reads
# during demultiplexing. Only ~10% of reads retain residual sequences.
# We do NOT use --discard-untrimmed (that would throw away the 90% of reads
# that MinKNOW already cleaned). Instead, we trim where found and keep all reads.
#
# Adapter sequences (SQK-16S114-24 kit):
#   5' = Rapid Attachment Tag + 27F primer
#   3' = 1492R_RC + Tag_RC
#
# Input:  data/filtered/<sample>_filt.fastq.gz
# Output: data/trimmed/<sample>_trimmed.fastq.gz
# Expected retention: ~100%
#
# Usage: bash scripts/03_trim_primers.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "============================================"
echo " Step 03: Primer trimming (cutadapt)"
echo " 5' adapter: ${ADAPTER_5}"
echo " 3' adapter: ${ADAPTER_3}"
echo " Error rate: ${CUTADAPT_ERROR_RATE}"
echo " Date: $(date)"
echo "============================================"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${TRIMMED_DIR}" "${LOG_DIR}"

TOTAL=$(wc -l < "${SAMPLE_LIST}")
COUNT=0

while IFS= read -r SAMPLE; do
    COUNT=$((COUNT + 1))

    INPUT="${FILTERED_DIR}/${SAMPLE}_filt.fastq.gz"
    OUTPUT="${TRIMMED_DIR}/${SAMPLE}_trimmed.fastq.gz"

    if [ -f "${OUTPUT}" ]; then
        echo "[${COUNT}/${TOTAL}] ${SAMPLE}: already trimmed, skipping."
        continue
    fi

    if [ ! -f "${INPUT}" ]; then
        echo "[${COUNT}/${TOTAL}] ${SAMPLE}: WARNING input not found, skipping."
        continue
    fi

    PRE=$(seqkit stats -T "${INPUT}" | awk 'NR==2{print $4}')

    cutadapt \
        -g "${ADAPTER_5}" \
        -a "${ADAPTER_3}" \
        --minimum-length "${CUTADAPT_MIN_LENGTH}" \
        -e "${CUTADAPT_ERROR_RATE}" \
        --json "${LOG_DIR}/step03_${SAMPLE}_cutadapt.json" \
        -o "${OUTPUT}" \
        "${INPUT}" > "${LOG_DIR}/step03_${SAMPLE}.log" 2>&1

    POST=$(seqkit stats -T "${OUTPUT}" | awk 'NR==2{print $4}')
    PCT=$(echo "scale=1; ${POST} * 100 / ${PRE}" | bc)

    echo "[${COUNT}/${TOTAL}] ${SAMPLE}: ${PRE} -> ${POST} reads (${PCT}% retained)"

    echo -e "step03_trim\t${SAMPLE}\t${PRE}\t${POST}\t${PCT}%\t$(date '+%Y-%m-%d %H:%M')" >> "${LOG_DIR}/pipeline_log.tsv"

done < "${SAMPLE_LIST}"

echo ""
echo "============================================"
echo " Step 03 complete: ${COUNT} samples trimmed"
echo " Output: ${TRIMMED_DIR}/"
echo " Next: bash scripts/04_download_emu_db.sh"
echo "============================================"
