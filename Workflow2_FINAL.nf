/*
INITIAL CONSIDERATIONS:
I ran this script on a linux system with a conda environment with Nextflow 23.10 installed
I have a Data folder that is in the project or base directory that contains one pair of raw fastq reads
I also have a nextflow config file that allows conda to be used, with specific environments specified in each process

Defining variables:

reads1 and reads2: The raw fastq reads that I will be working with for this workflow
assembly_dir: The directory where the assembly will be stored
quast_dir: The directory where the quast report will be stored
genotyping_dir: The directory where the mlst output will be stored 

*/
params.reads1 = "$projectDir/Data/*_1.fastq.gz"
params.reads2 = "$projectDir/Data/*_2.fastq.gz"
params.assembly_dir = "$projectDir/ASSEMBLY"
params.quast_dir = "$projectDir/QA"
params.genotyping_dir = "$projectDir/GENOTYPING"


/*

This is the assembly process:

I create a directory for my assembly output to go (outside of the individual work directories)
Then I use megahit to do an assembly on our raw fastq files

*/
process ASSEMBLY {
    conda 'megahit'
    //Directory where the assembly file will go
    publishDir(params.assembly_dir)
 
    output:
    path("megahit_out/final.contigs.fa"), emit: assembly
    //megahit on the paired reads
    """
    megahit -1 ${params.reads1} -2 ${params.reads2} --min-contig-len 500
    """
}

/*

QA Process;

I am using quast (which takes my paired reads and assembly as inputs) to do some QA
I also create a directory for my report to go like before

*/
process QA {
    conda 'quast'
    publishDir(params.quast_dir)

    //Takees the emitted assembly path as input
    input:
    path x

    output:
    path 'QUAST/report.tsv'
    //Quast command 
    """
    quast.py ${x} --pe1 ${params.reads1} --pe2 ${params.reads2} -o QUAST
    """
}

/*

Genotyping process:

Here I do some quick genotyping with mlst.
This takes the assembly file path as imput 

*/
process GENOTYPING {
    conda 'bioconda::mlst'
    //Directory where the mlst report will go
    publishDir(params.genotyping_dir)
    
    //Taking the assembly path as input
    input:
    path x

    output:
    path("mlst.tsv")
    
    //mlst command
    """
    mlst $x > mlst.tsv
    """
}

//This is the workflow step
//I run the ASSEMBLY command, and then the QA and GENOTYPING steps in parallel!
workflow {
    ASSEMBLY | QA & GENOTYPING
}
