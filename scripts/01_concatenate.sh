#!/usr/bin/env bash
# ============================================================================
# Step 01: Concatenate per-barcode FASTQ files into one file per sample
# ============================================================================
# MinKNOW splits output into multiple small FASTQ files per barcode.
# This step merges them into a single file per sample for downstream processing.
#
# Input:  data/raw_runs/<RunXX_type>/fastq_pass/barcodeXX/*.fastq.gz
# Output: data/concatenated/<sample>.fastq.gz
#
# Usage: bash scripts/01_concatenate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "============================================"
echo " Step 01: Concatenate raw FASTQ files"
echo " Date: $(date)"
echo "============================================"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${CONCAT_DIR}" "${LOG_DIR}"

if [ ! -f "${SAMPLE_LIST}" ]; then
    echo "ERROR: Sample list not found: ${SAMPLE_LIST}"
    echo "Create a file with one sample ID per line (e.g., Run01_soil_barcode01)"
    exit 1
fi

TOTAL=$(wc -l < "${SAMPLE_LIST}")
COUNT=0

while IFS= read -r SAMPLE; do
    COUNT=$((COUNT + 1))
    echo "[${COUNT}/${TOTAL}] Processing: ${SAMPLE}"

    # Parse sample ID to find source directory
    RUN=$(echo "${SAMPLE}" | sed -E 's/^(Run[0-9]+)_.*/\1/')
    BARCODE=$(echo "${SAMPLE}" | grep -oP 'barcode\d+')

    # Map sample type to directory name
    case "${SAMPLE}" in
        *_soil_*)  RUNDIR="${RUN}_soil_samples" ;;
        *_swab_*)  RUNDIR="${RUN}_swabs" ;;
        *_fecal_*) RUNDIR="${RUN}_fecal_samples" ;;
        *)
            echo "  WARNING: Cannot parse sample type from '${SAMPLE}', skipping."
            continue
            ;;
    esac

    SRCDIR="${RAW_RUN_DIR}/${RUNDIR}/fastq_pass/${BARCODE}"
    OUTFILE="${CONCAT_DIR}/${SAMPLE}.fastq.gz"

    if [ -f "${OUTFILE}" ]; then
        echo "  Already exists, skipping."
        continue
    fi

    if [ ! -d "${SRCDIR}" ]; then
        echo "  WARNING: Source directory not found: ${SRCDIR}, skipping."
        continue
    fi

    NFILES=$(ls "${SRCDIR}"/*.fastq.gz 2>/dev/null | wc -l)
    if [ "${NFILES}" -eq 0 ]; then
        echo "  WARNING: No .fastq.gz files in ${SRCDIR}, skipping."
        continue
    fi

    cat "${SRCDIR}"/*.fastq.gz > "${OUTFILE}"

    READS=$(seqkit stats -T "${OUTFILE}" | awk 'NR==2{print $4}')
    echo "  Concatenated ${NFILES} files -> ${READS} reads"

    echo -e "step01_concat\t${SAMPLE}\t${READS}\t$(date '+%Y-%m-%d %H:%M')" >> "${LOG_DIR}/pipeline_log.tsv"

done < "${SAMPLE_LIST}"

echo ""
echo "============================================"
echo " Step 01 complete: ${COUNT} samples processed"
echo " Output: ${CONCAT_DIR}/"
echo " Next: bash scripts/02_quality_filter.sh"
echo "============================================"
