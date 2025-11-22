process MSA {
    tag "msa"
    label 'process_medium'
   
    input:
    path modified_seqs
    
    output:
    path 'aligned_protein_sequences.fasta', emit: alignment
    path 'msa_complete.txt', emit: flag
    path "versions.yml", emit: versions
    
    script:
    """
    python ${params.bin_dir}/msa.py ${modified_seqs} aligned_protein_sequences.fasta
    touch msa_complete.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        mafft: \$(mafft --version 2>&1 | head -n1 || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    touch aligned_protein_sequences.fasta
    touch msa_complete.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

