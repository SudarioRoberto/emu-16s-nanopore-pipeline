#!/usr/bin/env bash
# ============================================================================
# Step 06: Combine per-sample Emu results into merged abundance tables
# ============================================================================
# Merges all per-sample Emu output into combined tables at species, genus,
# and family levels. Produces both relative abundance and absolute count tables.
#
# Input:  results/emu_per_sample/<sample>/ (148 per-sample directories)
# Output: results/emu_combined/
#           emu-combined-abundance-species-counts.tsv
#           emu-combined-abundance-genus-counts.tsv
#           emu-combined-abundance-family-counts.tsv
#           emu-combined-taxonomy-species.tsv
#           emu-combined-taxonomy-genus.tsv
#           emu-combined-taxonomy-family.tsv
#
# Usage: bash scripts/06_combine_results.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "============================================"
echo " Step 06: Combine Emu results"
echo " Date: $(date)"
echo "============================================"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${EMU_COMBINED_DIR}"

N_DONE=$(find "${EMU_OUTPUT_DIR}" -name "*_rel-abundance.tsv" 2>/dev/null | wc -l)
echo "Samples with Emu output: ${N_DONE}"

if [ "${N_DONE}" -eq 0 ]; then
    echo "ERROR: No Emu results found in ${EMU_OUTPUT_DIR}/"
    echo "Run step 05 first: bash scripts/05_emu_classify.sh"
    exit 1
fi

# Combine at species level (tax_id) with split tables and counts
echo ""
echo "Combining at species level..."
emu combine-outputs "${EMU_OUTPUT_DIR}" tax_id \
    --split-tables \
    --counts

# Move combined files to results directory
mv "${EMU_OUTPUT_DIR}"/emu-combined-* "${EMU_COMBINED_DIR}/" 2>/dev/null || true

echo ""
echo "Combined output files:"
ls -lh "${EMU_COMBINED_DIR}/"

# Print summary
echo ""
echo "--- Summary ---"
for f in "${EMU_COMBINED_DIR}"/*.tsv; do
    fname=$(basename "$f")
    n_samples=$(head -1 "$f" | tr '\t' '\n' | tail -n +2 | wc -l)
    n_taxa=$(tail -n +2 "$f" | wc -l)
    echo "  ${fname}: ${n_samples} samples, ${n_taxa} taxa"
done

echo ""
echo "============================================"
echo " Step 06 complete — Pipeline finished!"
echo " Results: ${EMU_COMBINED_DIR}/"
echo "============================================"
