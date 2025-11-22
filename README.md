# AncflowNF - Nextflow Pipeline

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A521.04.0-brightgreen.svg)](https://www.nextflow.io/)
[![Docker](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/)

Ancestral sequence reconstruction pipeline for phylogenetic analysis. Modular Nextflow implementation for scalable ancestral sequence reconstruction.

## Pipeline Overview

AncflowNF processes protein sequence data through:
- **Multiple sequence alignment** via [MAFFT](https://github.com/GSLBiotech/mafft)
- **Phylogenetic tree inference** via [IQ-TREE](https://github.com/iqtree/iqtree2)
- **Monophyletic clustering** via [AutoPhy](https://github.com/aortizsax/autophy)
- **Ancestral sequence reconstruction** via [IQ-TREE](https://github.com/iqtree/iqtree2) (with proper indel/gap handling)

## Quick Start

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Run with Conda
nextflow run main.nf -profile conda

# Run with Mamba (faster)
nextflow run main.nf -profile mamba

# Run with Docker
nextflow run main.nf -profile docker

# Resume from checkpoint
nextflow run main.nf -profile conda -resume

# Show help
nextflow run main.nf --help
```

## Installation

### Option 1: Conda/Mamba (Recommended)

```bash
# Create environment
conda env create -f environment.yml
conda activate ancflownf

# Run pipeline
nextflow run main.nf -profile conda
```

**Note:** This pipeline uses a fork of AutoPhy (`git+https://github.com/rrouz/autophy@main`) for compatibility. The fork is public and will be automatically installed when creating the conda environment.

### Option 2: Docker

```bash
# Build Docker image
docker build -t ancflownf:latest .

# Run with Docker profile
nextflow run main.nf -profile docker
```

### Option 3: Manual Installation

Install dependencies manually:
- Nextflow (>=21.04.0)
- Python 3.9+
- MAFFT
- IQ-TREE (for both phylogenetic inference and ASR)
- AutoPhy

## Pipeline Steps

The pipeline consists of 4 core steps:

1. **MSA** - Multiple sequence alignment using MAFFT
2. **IQTREE** - Phylogenetic tree inference with IQ-TREE
3. **AUTOPHY** - Monophyletic clustering to identify clades
4. **ASR_AUTOPHY** - Ancestral sequence reconstruction using IQ-TREE on the AutoPhy-clustered tree
   - Extracts all ancestral sequences
   - Filters to MRCA (Most Recent Common Ancestor) sequences for each clade

## Input Requirements

Place protein sequences in FASTA format with pipe-delimited headers:

```
>sp|P45996.1|OMP53_HAEIF RecName: Full=Outer membrane protein P5
MKVLSLLSLSLLFLSSATYAQSLGFQDNNIRGLQRGQRILLSHDDPGE...
```

**Requirements:**
- Minimum 50 curated protein sequences recommended
- Use Swiss-Prot sequences from [Pfam](https://pubmed.ncbi.nlm.nih.gov/26673716/) or [UniProt](https://www.uniprot.org/)
- Pipe-delimited header format: `>sp|ACCESSION|IDENTIFIER Description`

## Usage

### Basic Usage

```bash
# Run with default settings
nextflow run main.nf -profile conda

# Custom input file
nextflow run main.nf -profile conda --input_fasta my_sequences.fasta

# Custom output directory
nextflow run main.nf -profile conda --outdir my_results
```

### Advanced Options

```bash
# Custom IQ-TREE parameters
nextflow run main.nf -profile conda \
    --iqtree_model LG+G+F \
    --iqtree_bootstrap 1000

# Adjust resource limits
nextflow run main.nf -profile conda \
    --max_cpus 16 \
    --max_memory 64.GB \
    --max_time 48.h

# Debug mode
nextflow run main.nf -profile conda,debug
```

## Output Structure

```
results/
├── pipeline_info/           # Execution reports and timelines
│   ├── execution_report_*.html
│   ├── execution_timeline_*.html
│   ├── execution_trace_*.txt
│   └── pipeline_dag_*.mmd
├── alignments/              # MAFFT alignment output
├── iqtree/                  # IQ-TREE phylogenetic tree outputs
├── autophy/                 # AutoPhy clustering results
│   ├── *colored_RF.csv     # Cluster assignments
│   ├── *coloredtree.svg     # Colored phylogenetic tree
│   ├── *clustered.tree      # Clustered tree (NEXUS format)
│   ├── *GMMsweep.svg       # GMM sweep visualization
│   └── *ogUMAPprog.svg      # UMAP progression visualization
└── asr/                     # Ancestral reconstruction results
    ├── ancestral_autophy_sequences.fasta  # All ancestral sequences
    ├── clade_mrca_sequences.fasta         # MRCA sequences
    ├── alignment_clustered.fasta           # Alignment with cluster IDs
    └── autophy_tree.nwk                   # AutoPhy tree in Newick format
```

## Configuration

### Resource Management

Edit `nextflow.config` or use command-line parameters:

```groovy
params {
    max_cpus = 32
    max_memory = '128.GB'
    max_time = '240.h'
}
```

### Profiles

Available profiles in `nextflow.config`:

- **conda**: Use Conda for dependencies
- **mamba**: Use Mamba (faster than Conda)
- **docker**: Use Docker containers
- **debug**: Enable debug mode

### Process Labels

Processes are categorized by resource requirements:

- **process_low**: 1 CPU, 4 GB RAM, 4h
- **process_medium**: 4 CPUs, 8 GB RAM, 8h
- **process_high**: 8 CPUs, 16 GB RAM, 16h

## Directory Structure

```
AncflowNF/
├── main.nf                  # Pipeline entry point
├── nextflow.config          # Main configuration
├── Dockerfile               # Docker image definition
├── environment.yml          # Conda environment
├── conf/
│   ├── base.config         # Base process configuration
│   └── modules.config      # Module-specific settings
├── workflows/
│   └── ancflow.nf          # Main workflow definition
├── modules/
│   └── local/              # Process modules
│       ├── msa/
│       ├── iqtree/
│       ├── autophy/
│       └── asr_autophy/
└── bin/                     # Python utility scripts
    ├── msa.py
    ├── add_cluster_ids_to_alignment.py
    ├── convert_autophy_tree_to_newick.py
    ├── extract_ancestral_sequences.py
    └── extract_clade_mrcas.py
```

## Interpreting Results

### AutoPhy Clustering

After IQ-TREE inference, AutoPhy clusters sequences into monophyletic clades. Review the `autophy/` output directory to see:
- Colored phylogenetic trees showing clusters
- CSV files with cluster assignments
- Statistical support values

### Ancestral Sequences

The pipeline produces two FASTA files:
- **`ancestral_autophy_sequences.fasta`**: All ancestral nodes (internal nodes of the tree)
- **`clade_mrca_sequences.fasta`**: Only MRCA sequences (one per clade) - **recommended for most analyses**

The MRCA sequences represent the most recent common ancestor of each clade, providing more accurate ancestral reconstructions for downstream analysis.

## Troubleshooting

### Conda/Mamba Issues
```bash
# Ensure conda version >=4.14
conda --version

# Remove and recreate environment
conda env remove -n ancflownf
conda env create -f environment.yml
```

### Pipeline Failures
```bash
# Resume from last successful step
nextflow run main.nf -profile conda -resume

# Check work directory for logs
ls -la work/

# Enable debug mode
nextflow run main.nf -profile conda,debug
```

### Memory Issues
```bash
# Increase memory for specific processes
nextflow run main.nf -profile conda --max_memory 256.GB
```

## Citation

If you use AncflowNF, please cite:

- **MAFFT**: Katoh & Standley (2013) Molecular Biology and Evolution
- **IQ-TREE**: Nguyen et al. (2015) Molecular Biology and Evolution (phylogenetic inference and ASR)
- **AutoPhy**: Ortiz-Sax et al. (GitHub: https://github.com/aortizsax/autophy)
  - This pipeline uses a fork: https://github.com/rrouz/autophy (for compatibility)