# smoove  

[![Build Status](https://travis-ci.org/brentp/smoove.svg?branch=master)](https://travis-ci.org/brentp/smoove)

`smoove` simplifies and speeds calling and genotyping SVs for short reads. It also improves specificity by removing many
spurious alignment signals that are indicative of low-level noise and often contribute to spurious calls.

There is a blog-post describing `smoove` in more detail [here](https://brentp.github.io/post/smoove/)

It both supports small cohorts in a single command, and population-level calling with 4 total steps, 2
of which are parallel by sample.

It requires:

 + [lumpy and lumpy\_filter](https://github.com/arq5x/lumpy-sv)

 And optionally (but all highly recommended):

 + [svtyper](https://github.com/hall-lab/svtyper): to genotypes SVs
 + [svtools](https://github.com/hall-lab/svtools): required for large cohorts
 + [samtools](https://github.com/samtools/samtools): for CRAM support
 + [gsort](https://github.com/brentp/gsort): to sort final VCF
 + [bgzip+tabix](https://github.com/samtools/htslib): to compress and index final VCF
 + [mosdepth](https://github.com/brentp/mosdepth): remove high coverage regions.
 + [bcftools](https://github.com/samtools/bcftools): version 1.5 or higher for VCF indexing and filtering. 

 Running `smoove` without any arguments will show which of these are found so they can be added to the PATH as needed.

`smoove` will:

1. parallelize calls to `lumpy_filter` to extract split and discordant reads required by lumpy
2. further filter `lumpy_filter` calls to remove high-coverage, spurious regions and user-specified chroms like 'hs37d5';
   it will also remove reads that we've found are likely spurious signals. 
   after this, it will remove singleton reads (where the mate was removed by one of the previous filters) from the discordant
   bams. This makes `lumpy` much faster and less memory-hungry.
3. calculate per-sample metrics for mean, standard deviation, and distribution of insert size as required by lumpy.
4. stream output of lumpy directly into multiple svtyper processes for parallel-by-region genotyping while lumpy is still running.
5. sort, compress, and index final VCF.

# installation

you can get `smoove` and all dependencies via (a large) docker image:

```
docker pull brentp/smoove
docker run -it brentp/smoove smoove -h
```

Or, you can download a `smoove` binary from here: https://github.com/brentp/smoove/releases

# usage

## small cohorts (n < ~ 40)

for small cohorts it's possible to get a jointly-called, genotyped VCF in a **single command**.

```
smoove call -x --name my-cohort --exclude $bed --fasta $fasta -p $threads --genotype /path/to/*.bam
```
output will go to `./my-cohort-smoove.genotyped.vcf.gz`

the `$exclude` is optional but can be used to remove problematic regions.

## population calling

For population-level calling (large cohorts) the steps are:

1. For each sample, call genotypes:

```
smoove call --outdir results-smoove/ --name $sample --fasta $fasta -p $threads --genotype /path/to/$sample.bam
```

output will go to `results-smoove/$sample-smoove.genotyped.vcf.gz``

2. Get the union of sites across all samples (this can parallelize this across as many CPUs or machines as needed):

```
# this will create ./merged.sites.vcf.gz
smoove merge --name merged -f $fasta --outdir ./ results-smoove/*.genotyped.vcf.gz
```

3. genotype all samples at those sites (this can parallelize this across as many CPUs or machines as needed).

```
smoove genotype -x -p 1 --name $sample-joint --outdir results-genotped/ --fasta $fasta --vcf merged.sites.vcf.gz /path/to/$sample.$bam
```

4. paste all the single sample VCFs with the same number of variants to get a single, squared, joint-called file.

```
smoove paste --name $cohort results-genotyped/*.vcf.gz
```

# Troubleshooting

+ A panic with a message like ` Segmentation fault      (core dumped) | bcftools view -O z -c 1 -o` is likely to mean you have an old version of bcftools. 
  see #10

# TODO

+ [ ] annotate high-quality calls
+ [ ] incorporate WHAM
+ [ ] incorporate cnvnator (this is already a sub-command, but there's no way to use the output)

# see also

[svtools](https://github.com/hall-lab/svtools)
