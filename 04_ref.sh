#!/usr/bin/env bash
# 4 Reference files: GTF (featureCounts, STAR) and BED12 (RSeQC)

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/00_config.sh"
step="$(basename "${BASH_SOURCE[0]}" .sh)"

need_programs awk grep sort gffread gtfToGenePred genePredToBed samtools

[[ -s "${GENOME_FASTA}" ]] || die "the genome FASTA is absent: ${GENOME_FASTA}"
[[ -s "${GENOME_GFF}" ]] || die "the GFF3 annotation is absent: ${GENOME_GFF}"

mkdir -p "${GENOME_DIR}"
work_dir="$(mktemp -d "${GENOME_DIR}/.${step}.XXXXXX")"
trap 'rm -rf -- "${work_dir}"' EXIT

# 4a GTF
gffread "${GENOME_GFF}" -T -o "${work_dir}/genes.gtf" || die "gffread stopped."

gene_count="$(awk -F'\t' '$3 == "exon"' "${work_dir}/genes.gtf" \
              | grep -o 'gene_id "[^"]*"' | sort -u | wc -l | tr -d ' ')"
say "the GTF holds ${gene_count} genes."
(( EXPECTED_GENE_COUNT == 0 || gene_count == EXPECTED_GENE_COUNT )) \
  || die "expected ${EXPECTED_GENE_COUNT} genes (Wm82.a6.v1). Confirm the annotation release."

# 4b BED12
gtfToGenePred -genePredExt "${work_dir}/genes.gtf" "${work_dir}/genes.genePred" \
  || die "gtfToGenePred stopped."
genePredToBed "${work_dir}/genes.genePred" "${work_dir}/genes.bed12" \
  || die "genePredToBed stopped."

mv -f -- "${work_dir}/genes.gtf" "${GENOME_GTF}"
mv -f -- "${work_dir}/genes.bed12" "${GENOME_BED12}"

# 4c FASTA index
samtools faidx "${GENOME_FASTA}"

say "the reference files are ready: ${GENOME_GTF}, ${GENOME_BED12}."
