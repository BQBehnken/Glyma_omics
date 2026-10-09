#!/usr/bin/env bash
# Here is how I configured my directories. "Order and method, Hastings, order and method." 

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

# 0a Reference genome
GENOME_DIR="${GENOME_DIR:-${PROJECT_ROOT}/genome}"
GENOME_FASTA="${GENOME_FASTA:-${GENOME_DIR}/Gmax_880_Wm82.a6.v1.fa}"
GENOME_GFF="${GENOME_GFF:-${GENOME_DIR}/Gmax_880_Wm82.a6.v1.gene.gff3}"
GENOME_GTF="${GENOME_GTF:-${GENOME_DIR}/Gmax_880_Wm82.a6.v1.gtf}"
GENOME_BED12="${GENOME_BED12:-${GENOME_DIR}/Gmax_880_Wm82.a6.v1.bed12}"
STAR_INDEX="${STAR_INDEX:-${GENOME_DIR}/STAR_index}"

EXPECTED_GENE_COUNT="${EXPECTED_GENE_COUNT:-45398}"

# 0b Sample sheet
SAMPLE_SHEET="${SAMPLE_SHEET:-${SCRIPT_DIR}/samples.tsv}"

# 0c Directory layout
RAW_DIR="${RAW_DIR:-${PROJECT_ROOT}/00_fastq}"
TRIM_DIR="${TRIM_DIR:-${PROJECT_ROOT}/fastq_trimmed}"
ALIGN_DIR="${ALIGN_DIR:-${PROJECT_ROOT}/alignment}"
COUNT_DIR="${COUNT_DIR:-${PROJECT_ROOT}/counts}"
QC_DIR="${QC_DIR:-${PROJECT_ROOT}/qc}"
QC_RAW_DIR="${QC_RAW_DIR:-${QC_DIR}/fastqc_raw}"
QC_TRIM_DIR="${QC_TRIM_DIR:-${QC_DIR}/fastqc_trim}"
FASTP_DIR="${FASTP_DIR:-${QC_DIR}/fastp}"
STRAND_DIR="${STRAND_DIR:-${QC_DIR}/strandedness}"
RSEQC_DIR="${RSEQC_DIR:-${QC_DIR}/rseqc}"
COMPOSITION_DIR="${COMPOSITION_DIR:-${QC_DIR}/composition}"
MULTIQC_DIR="${MULTIQC_DIR:-${QC_DIR}/multiqc}"
LOG_DIR="${LOG_DIR:-${PROJECT_ROOT}/logs}"

# 0d Threads and parallel jobs
THREADS="${THREADS:-36}"
TRIM_THREADS="${TRIM_THREADS:-8}"
TRIM_JOBS="${TRIM_JOBS:-4}"
ALIGN_JOBS="${ALIGN_JOBS:-2}"
RSEQC_JOBS="${RSEQC_JOBS:-16}"
IO_JOBS="${IO_JOBS:-6}"

# 0e Library and strandedness
READ_LENGTH="${READ_LENGTH:-150}"
SJDB_OVERHANG=$(( READ_LENGTH - 1 ))

STRANDEDNESS="${STRANDEDNESS:-0}"   # 0 unstranded, 1 forward, 2 reverse

case "${STRANDEDNESS}" in
  0) STAR_COUNT_COL=2 ;;
  1) STAR_COUNT_COL=3 ;;
  2) STAR_COUNT_COL=4 ;;
  *) echo "00_config.sh: STRANDEDNESS must be 0, 1 or 2. The value is '${STRANDEDNESS}'." >&2
     return 1 2>/dev/null || exit 1 ;;
esac

# 0f Helpers
step="${step:-pipeline}"

die()  { echo "${step}: ERROR: $*" >&2; exit 1; }
warn() { echo "${step}: WARNING: $*" >&2; }
say()  { echo "${step}: $*"; }

need_programs() {
  local prog missing=0
  for prog in "$@"; do
    if ! command -v "${prog}" >/dev/null 2>&1; then
      echo "${step}: ERROR: this machine has no ${prog}." >&2
      missing=1
    fi
  done
  if (( missing )); then
    echo "  Create or update the environment from ${SCRIPT_DIR}/environment.yml." >&2
    exit 1
  fi
}

sheet_get() {
  local want="$1"
  grep -v '^#' "${SAMPLE_SHEET}" | awk -F'\t' -v want="${want}" '
    NR == 1 {
      for (i = 1; i <= NF; i++) if ($i == want) col = i
      if (col == 0) {
        print "sheet_get: the sample sheet has no column named " want > "/dev/stderr"
        exit 1
      }
      next
    }
    NF > 0 { print $col }
  '
}

sample_count() { sheet_get sample_id | wc -l | tr -d ' '; }

raw_path() {   # a sheet FASTQ entry, absolute or relative to RAW_DIR
  if [[ "$1" = /* ]]; then printf '%s\n' "$1"; else printf '%s\n' "${RAW_DIR}/$1"; fi
}

export SCRIPT_DIR PROJECT_ROOT GENOME_DIR GENOME_FASTA GENOME_GFF GENOME_GTF \
       GENOME_BED12 STAR_INDEX EXPECTED_GENE_COUNT SAMPLE_SHEET \
       RAW_DIR TRIM_DIR ALIGN_DIR COUNT_DIR QC_DIR QC_RAW_DIR QC_TRIM_DIR \
       FASTP_DIR STRAND_DIR RSEQC_DIR COMPOSITION_DIR MULTIQC_DIR LOG_DIR \
       THREADS TRIM_THREADS TRIM_JOBS ALIGN_JOBS RSEQC_JOBS IO_JOBS \
       READ_LENGTH SJDB_OVERHANG STRANDEDNESS STAR_COUNT_COL
