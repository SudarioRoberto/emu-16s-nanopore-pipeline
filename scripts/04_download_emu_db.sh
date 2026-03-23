#!/usr/bin/env bash
# ============================================================================
# Step 04: Download the default Emu database
# ============================================================================
# Downloads the pre-built Emu database (rrnDB v5.6 + NCBI 16S RefSeq)
# from the Open Science Framework (OSF).
#
# This step requires internet access.
# Only needs to be run once — the database is reused for all samples.
#
# Output: data/emu_db/ (contains species_taxid.fasta and taxonomy files)
#
# Usage: bash scripts/04_download_emu_db.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "============================================"
echo " Step 04: Download Emu default database"
echo " Target: ${EMU_DB_DIR}"
echo " Date: $(date)"
echo "============================================"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${EMU_DB_DIR}"

if [ -f "${EMU_DB_DIR}/species_taxid.fasta" ]; then
    echo "Database already exists at ${EMU_DB_DIR}/"
    echo "Files:"
    ls -lh "${EMU_DB_DIR}/"
    echo ""
    echo "To re-download, delete the directory first:"
    echo "  rm -rf ${EMU_DB_DIR} && bash $0"
    exit 0
fi

echo "Downloading default Emu database from OSF (rrnDB v5.6 + NCBI 16S RefSeq)..."
echo "This may take several minutes depending on your connection."

cd "${EMU_DB_DIR}"
osf -p 56uf7 fetch osfstorage/emu-prebuilt/emu.tar

echo "Extracting..."
tar -xvf emu.tar
rm -f emu.tar

echo ""
echo "Database files:"
ls -lh "${EMU_DB_DIR}/"

NSEQS=$(grep -c '>' "${EMU_DB_DIR}/species_taxid.fasta" 2>/dev/null || echo "unknown")
echo ""
echo "============================================"
echo " Step 04 complete"
echo " Database: ${EMU_DB_DIR}"
echo " Reference sequences: ${NSEQS}"
echo " Next: bash scripts/05_emu_classify.sh"
echo "============================================"
