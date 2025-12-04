#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    AncflowNF Nextflow workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow definition
----------------------------------------------------------------------------------------
*/

include { SANITIZE_HEADERS } from '../modules/local/sanitize_headers/main'
include { MSA } from '../modules/local/msa/main'
include { IQTREE } from '../modules/local/iqtree/main'
include { AUTOPHY } from '../modules/local/autophy/main'
include { ASR_AUTOPHY } from '../modules/local/asr_autophy/main'

workflow ANCFLOW {
    take:
        input_fasta_ch

    main:
        // Step 0: Sanitize FASTA headers for iq-tree/autophy compatibility
        SANITIZE_HEADERS(input_fasta_ch)
        
        // Step 1: Multiple Sequence Alignment
        MSA(SANITIZE_HEADERS.out.fasta)
        
        // Step 2: Phylogenetic Tree Inference with IQ-TREE
        IQTREE(MSA.out.alignment)
        
        // Step 3: AutoPhy Clustering/Visualization
        AUTOPHY(IQTREE.out.treefile)
        
        // Step 4: Ancestral Sequence Reconstruction using AutoPhy Clustered Tree
        ASR_AUTOPHY(MSA.out.alignment, AUTOPHY.out.autophy_dir)

    emit:
        asr_complete = ASR_AUTOPHY.out.flag
        asr_outputs = ASR_AUTOPHY.out.asr_outputs
        ancestral_fasta_all = ASR_AUTOPHY.out.ancestral_fasta_all
        ancestral_fasta_mrca = ASR_AUTOPHY.out.ancestral_fasta_mrca
        clustered_alignment = ASR_AUTOPHY.out.clustered_alignment
        alignment = MSA.out.alignment
        tree = IQTREE.out.treefile
        autophy_tree = ASR_AUTOPHY.out.tree
        autophy_dir = AUTOPHY.out.autophy_dir
        iqtree_outputs = IQTREE.out.all_outputs
        header_mapping = SANITIZE_HEADERS.out.mapping
}

