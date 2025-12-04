process SANITIZE_HEADERS {
    tag "sanitize_headers"
    label 'process_low'
   
    input:
    path input_fasta
    
    output:
    path 'sanitized_sequences.fasta', emit: fasta
    path 'header_mapping.json', emit: mapping
    path "versions.yml", emit: versions
    
    script:
    """
    python ${params.bin_dir}/sanitize_fasta_headers.py \\
        ${input_fasta} \\
        sanitized_sequences.fasta \\
        header_mapping.json
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    touch sanitized_sequences.fasta
    echo '{}' > header_mapping.json
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
