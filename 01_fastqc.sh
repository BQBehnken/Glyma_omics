#!/usr/bin/env bash
# 1 FastQC raw reads

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"
step="$(basename "${BASH_SOURCE[0]}" .sh)"

need_programs fastqc

files=()
while IFS=$'\t' read -r r1 r2; do
  files+=( "$(raw_path "${r1}")" "$(raw_path "${r2}")" )
done < <(paste <(sheet_get fastq_R1) <(sheet_get fastq_R2))

mkdir -p "${QC_RAW_DIR}"
fastqc -t "${THREADS}" -o "${QC_RAW_DIR}" "${files[@]}"

say "the raw read reports are in ${QC_RAW_DIR}."
