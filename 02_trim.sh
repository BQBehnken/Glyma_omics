#!/usr/bin/env bash
# 2 Read trimming

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"
step="$(basename "${BASH_SOURCE[0]}" .sh)"

need_programs fastp xargs

mkdir -p "${TRIM_DIR}" "${FASTP_DIR}"

trim_one() {
  local sample="$1" in1="$2" in2="$3"
  echo "${step}: ${sample}"
  fastp \
    --in1 "${in1}" --in2 "${in2}" \
    --out1 "${TRIM_DIR}/${sample}_1.trim.fastq.gz" \
    --out2 "${TRIM_DIR}/${sample}_2.trim.fastq.gz" \
    --thread "${TRIM_THREADS}" \
    --detect_adapter_for_pe \
    --trim_poly_g \
    --cut_right --cut_right_window_size 4 --cut_right_mean_quality 15 \
    --length_required 50 \
    --json "${FASTP_DIR}/${sample}.fastp.json" \
    --html "${FASTP_DIR}/${sample}.fastp.html" \
    > "${FASTP_DIR}/${sample}.fastp.log" 2>&1
}
export -f trim_one
export step

while IFS=$'\t' read -r sample r1 r2; do
  printf '%s\t%s\t%s\n' "${sample}" "$(raw_path "${r1}")" "$(raw_path "${r2}")"
done < <(paste <(sheet_get sample_id) <(sheet_get fastq_R1) <(sheet_get fastq_R2)) \
  | xargs -d '\n' -P "${TRIM_JOBS}" -I{} \
      bash -c 'set -uo pipefail; IFS=$'"'"'\t'"'"' read -r s a b <<< "$1"; trim_one "$s" "$a" "$b"' _ {} \
  || die "fastp stopped for at least one sample. Read the log files in ${FASTP_DIR}."

say "the trimmed reads are in ${TRIM_DIR}; the fastp reports are in ${FASTP_DIR}."
