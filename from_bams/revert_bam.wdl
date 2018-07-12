workflow bam_reverter
{
    Array[File] input_bams
    String tools
    String sampleName

    scatter(index in range(length(input_bams)))
    {
       Int i = index
       File bam = input_bams[i]
       call RevertBAM
       {
          input:
            input_bam = bam,
            picard = tools + "/picard.jar",
            output_dir = "/net/home/isaevt/revertBAM_" + sampleName + "_" + i,
            sampleName = sampleName
       }
    }

    output
    {
       Array[Array[String]] reverted_bams =  RevertBAM.file_paths
       String sName = sampleName
    }
}

task RevertBAM
{
   File input_bam
   String picard
   String output_dir
   String sampleName

   command
   {
      java -jar ${picard} RevertSam \
         OUTPUT_BY_READGROUP=true \
         I=${input_bam} \
         O=${output_dir} \
         SORT_ORDER=unsorted \
         QUIET=true
          
      find ${output_dir} -maxdepth 1 -type f
   }

   output
   {
      Array[String] file_paths = read_lines(stdout())
   }

   runtime
   {
      memory: "1 GB"
      cpu: 1
   }
}
