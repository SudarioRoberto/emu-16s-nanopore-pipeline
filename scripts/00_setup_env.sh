#!/usr/bin/env bash
# ============================================================================
# Step 00: Set up the conda environment with all required tools
# ============================================================================
# Usage: bash scripts/00_setup_env.sh
#
# This creates a single conda environment with:
#   - chopper (quality filtering)
#   - seqkit  (read statistics)
#   - cutadapt (primer trimming)
#   - emu     (taxonomic classification)
#
# Prerequisites:
#   - Conda or Mamba installed (https://docs.conda.io/en/latest/miniconda.html)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/config.sh"

echo "============================================"
echo " Step 00: Create conda environment"
echo " Environment: ${CONDA_ENV}"
echo " Date: $(date)"
echo "============================================"

# Check if conda is available
if ! command -v conda &>/dev/null; then
    echo "ERROR: conda not found. Install Miniconda first:"
    echo "  https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

# Check if environment already exists
if conda env list | grep -q "^${CONDA_ENV} "; then
    echo "Environment '${CONDA_ENV}' already exists."
    echo "To recreate: conda env remove -n ${CONDA_ENV} && bash $0"
    exit 0
fi

ENV_FILE="${SCRIPT_DIR}/../environment.yml"

if [ -f "${ENV_FILE}" ]; then
    echo "Creating environment from environment.yml..."
    conda env create -f "${ENV_FILE}"
else
    echo "Creating environment manually..."
    conda create -n "${CONDA_ENV}" -y -c bioconda -c conda-forge \
        python=3.9 \
        chopper=0.12.0 \
        seqkit=2.13.0 \
        cutadapt=4.9 \
        emu=3.6.2
fi

echo ""
echo "============================================"
echo " Environment '${CONDA_ENV}' created."
echo " Activate with: conda activate ${CONDA_ENV}"
echo " Next step: bash scripts/01_concatenate.sh"
echo "============================================"
