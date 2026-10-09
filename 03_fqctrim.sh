#!/usr/bin/env bash
# 3 FastQC trimmed reads

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"
step="$(basename "${BASH_SOURCE[0]}" .sh)"

need_programs fastqc

files=()
while IFS= read -r sample; do
  files+=( "${TRIM_DIR}/${sample}_1.trim.fastq.gz" "${TRIM_DIR}/${sample}_2.trim.fastq.gz" )
done < <(sheet_get sample_id)

mkdir -p "${QC_TRIM_DIR}"
fastqc -t "${THREADS}" -o "${QC_TRIM_DIR}" "${files[@]}"

say "the trimmed read reports are in ${QC_TRIM_DIR}."
