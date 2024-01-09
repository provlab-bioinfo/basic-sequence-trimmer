# basic-sequence-trimmer
A generic pipeline for trimming, filtering, and dehosting reads that can be run on an arbitrary set of FASTQ files from Illumina or Nanopore NGS.


## Output

The output file structure is determined by the `outdir`:

```
<outdir>
   ├── pipeline_info
   │      ├── samplesheet.csv
   │      └── software_versions.yml
   └── <label>
          └── fastq
                 └── [prefix_]<ID>.fastq[.gz]
```