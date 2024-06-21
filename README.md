# basic-sequence-trimmer
A generic pipeline for trimming, filtering, and dehosting reads that can be run on an arbitrary set of FASTQ files from Illumina or Nanopore NGS. This uses [`bbduk`][bbduk] (Illumina) and [`porechop`][porechop]/[`chopper`][chopper] (Nanopore) for removing adapters, filtering low quality reads and contaminants, and other QC tasks. Host reads are removed with [`hostile`][hostile].

## Quick code
```
conda activate basic-sequence-trimmer
nextflow run <path/to/basic-sequence-trimmer> \
  --label <label> \
  --sheet <path/to/samplesheet.csv> \
  --outdir <path/to/output_dir> \
  [--config <path/to/file.config>]
```
## Dependencies

[Conda] is required to build the basic-sequence-trimmer [environment] with the necessary workflow dependencies. To create the environment:
```
conda env create -f ./environments/environment.yml
```

## Arguments
**`--sheet`**: A sample sheet specifying FASTQ files/directories corresponding to a sample. See [Input](#input).
<br>
**`--output`**: The output directory. See [Output](#output).
<br>
**`--label`**: The label to output directory. See [Output](#output). Default is 'processed'.
<br>
**`[--config]`**: A nextflow configuration file. See [Input](#input). Optional.

## Input

<table border="0"><tr><td style="vertical-align:top"><b>Sample&nbsp;sheet</b><br>

`--sheet`

</td><td>

The sample sheet is a CSV file that specifies an `ID` and list of `reads`. Each read must be in `.fastq.gz` format, and paired reads are accepted for Illumina runs in `illumina1` and `illumina2`. Only a single file can be specified in each field. If a sample has multiple files or folders, use [`basic-sequence-collecter`][basic-sequence-collecter] first to validate and collate the files.

For example:

```
ID,         illumina1,                  illumina2,                 nanopore
SAMPLE-01 , /path/to/SAMPLE-01.fq    ,                           ,
SAMPLE-02 , /path/to/SAMPLE-02_R1.fq ,  /path/to/SAMPLE-02_R2.fq , 
SAMPLE-03 ,                          ,                           , /path/to/SAMPLE-03.fq
SAMPLE-04 , /path/to/SAMPLE-04_R1.fq ,  /path/to/SAMPLE-04_R2.fq , /path/to/SAMPLE-04.fq
```
<sup>(for readability, `.fq` is used instead of `.fastq.gz`)</sup>

</td></tr>
<tr><td style="vertical-align:top"><b>Config file</b><br>

`--config`

</td><td>

The tool takes an optional [Nextflow config file]. A generic `trimmer.config` is provided in this repo:

```
process {
  withName: TRIMMER {
      "hostile_index_long":  "/path/to/hostile_index_long_reads",
      "hostile_index_short": "/path/to/hostile_index_short_reads",
      "skip_qc": "true|false",
      "skip_dehost": "true|false"
  }
}
```

**`hostile_index_long`**: Index of human long read indexes (Minimap2) for [`hostile`][hostile]. Default: `human-t2t-hla.fa.gz`.
<br>
**`hostile_index_short`**: Index of human short read indexes (Bowtie2) for [`hostile`][hostile]. Default: `human-t2t-hla`.
<br>
**`skip_read_qc`**: Skips read qc with [`bbduk`][bbduk] (Illumina) or [`porechop`][porechop]/[`chopper`][chopper] (Nanopore). Default: `false`.
<br>
**`skip_dehost`**: Skips dehosting with [`hostile`][hostile]. Default: `false`.
<br>

</td></tr></table>

## Output

The output file structure is determined by the `--outdir` and `--label`:

```
<outdir>
   ├── pipeline_info
   │      └── software_versions.yml
   └── <label>
          ├── samplesheet.csv
          └── fastq
                 └── <ID>.fastq[.gz]
```



[Conda]: https://conda.io/projects/conda/en/latest/user-guide/install/index.html
[environment]: /environments/environment.yml
[bbduk]: https://sourceforge.net/projects/bbmap
[porechop]: https://github.com/rrwick/Porechop
[chopper]: https://github.com/wdecoster/chopper
[hostile]: https://github.com/bede/hostile
[basic-sequence-collecter]: https://github.com/provlab-bioinfo/basic-sequence-collecter
[Nextflow config file]: https://www.nextflow.io/docs/latest/config.html