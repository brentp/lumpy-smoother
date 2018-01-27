# lumpy-smoother

`lumpy-smoother` simplifies and speeds running [lumpy](https://github.com/arq5x/lumpy-sv) and associated pre and post-processing steps.

It requires:

 + [lumpy and lumpy\_filter](https://github.com/arq5x/lumpy-sv)

 And optionally:

 + [cnvnator](https://github.com/abyzovlab/CNVnator): makes per-sample CNV calls that lumpy can use
 + [svtyper](https://github.com/hall-lab/svtyper): to genotypes SVs
 + [samtools](https://github.com/samtools/samtools): for CRAM support


`lumpy-smoother` will:

1. parallelize calls to `lumpy_filter` to extract split and discordant reads required by lumpy
2. further filter `lumpy_filter` calls to remove high-coverage, spurious regions.
3. parallelize calling cnvnator if it is on the $PATH, including splitting the reference as it requires.
   calls to `lumpy_filter` and `cnvnator` are in the same process-pool for maximum efficiency
4. calculate per-sample metrics for mean, standard deviation, and distribution of insert size as required by lumpy.
5. correct the reference allele (lumpy always puts 'N')
6. stream output of lumpy directly into multiple svtyper processes for parallel-by-region genotyping while lumpy is still running.

# usage

run `lumpy-smoother -h` for full usage

```
lumpy-smoother \
        -n my-project \                        # arbitrary project name for file prefixes
        -f $reference \
        --processes 10 \                       # parallelize with this many processors.
        --exclude low-complexity-regions.bed \ # see: https://github.com/hall-lab/speedseq/tree/master/annotations 
        data/*.bam                             # any number of BAM or CRAM files
```

# TODO

+ [X] further filter lumpy-filter output to remove bad regions with lots of spurious signals using [mosdepth](https://github.com/brentp/mosdepth)
      and then filtering split and discordant bams to remove high-coverage regions.
+ [ ] annotate high-quality calls
+ [ ] (unlikely) isolate steps so that users can call, e.g.: 
    lumpy-smoother cnvs
    lumpy-smoother filter
    lumpy-smoother lumpy
    lumpy-smoother call
```

# limitations

Until item 3 above is done, this is limited to cohorts of ~ 1 dozen or so. Once item 1 is done, this will go up to 30-40.

# see also

[svtools](https://github.com/hall-lab/svtools)
