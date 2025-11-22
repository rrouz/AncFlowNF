#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { ANCFLOW } from './workflows/ancflow'

def helpMessage() {
    log.info"""
    =========================================
    AncflowNF
    =========================================
    
    Usage:
      nextflow run main.nf [options]
    
    Required Parameters:
      --input_fasta       Path to input protein sequences FASTA file
                         (default: ${params.input_fasta})
    
    Optional Parameters:
      --outdir           Output directory (default: ${params.outdir})
      --iqtree_model     IQ-TREE substitution model (default: ${params.iqtree_model})
      --iqtree_bootstrap Bootstrap replicates for IQ-TREE (default: ${params.iqtree_bootstrap})
      --autophy_mode     AutoPhy clustering mode (default: ${params.autophy_mode})
      --max_cpus         Maximum CPUs to use (default: ${params.max_cpus})
      --max_memory       Maximum memory to use (default: ${params.max_memory})
      --max_time         Maximum time for jobs (default: ${params.max_time})
    
    Profiles:
      -profile conda     Use Conda for dependency management
      -profile mamba     Use Mamba for dependency management (faster)
      -profile docker    Use Docker containers
      -profile debug     Enable debug mode
    
    Examples:
      # Run with default settings (conda)
      nextflow run main.nf -profile conda
      
      # Run with custom input file
      nextflow run main.nf -profile mamba --input_fasta my_sequences.fasta
      
      # Run with Docker
      nextflow run main.nf -profile docker
      
      # Resume a failed run
      nextflow run main.nf -profile conda -resume
    
    For more information, see README.md
    =========================================
    """.stripIndent()
}

def validateParameters() {
    def valid = true
    
    if (!params.input_fasta) {
        log.error "Input FASTA file not specified! Use --input_fasta"
        valid = false
    } else if (!file(params.input_fasta).exists()) {
        log.error "Input FASTA file does not exist: ${params.input_fasta}"
        valid = false
    }
    
    if (!valid) {
        helpMessage()
        exit 1
    }
}

workflow {
    if (params.help) {
        helpMessage()
        exit 0
    }
    
    log.info """
    =========================================
    AncflowNF - Ancestral Sequence Reconstruction
    =========================================
    Input FASTA    : ${params.input_fasta}
    Output Dir     : ${params.outdir}
    IQ-TREE Model  : ${params.iqtree_model}
    Bootstrap      : ${params.iqtree_bootstrap}
    Max CPUs       : ${params.max_cpus}
    Max Memory     : ${params.max_memory}
    =========================================
    """.stripIndent()
    
    validateParameters()
    
    Channel
        .fromPath(params.input_fasta, checkIfExists: true)
        .set { input_fasta_ch }
    
    ANCFLOW(input_fasta_ch)
}

workflow.onComplete {
    log.info """
    =========================================
    Pipeline completed at: ${workflow.complete}
    Execution status      : ${workflow.success ? 'SUCCESS' : 'FAILED'}
    Duration              : ${workflow.duration}
    Results               : ${params.outdir}
    =========================================
    """.stripIndent()
}

workflow.onError {
    log.info """
    =========================================
    Pipeline execution stopped with error
    Error message: ${workflow.errorMessage}
    =========================================
    """.stripIndent()
}
