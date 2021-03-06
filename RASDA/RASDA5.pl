#!/usr/bin/env  perl5
use  strict;
use  warnings;
use  v5.22;

## Perl5 version >= 5.22
## You can create a symbolic link for perl5 by using "sudo  ln  /usr/bin/perl   /usr/bin/perl5" in Ubuntu.
## Suffixes of all self-defined global variables must be "_g".
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $genome_g = '';  ## such as "mm10", "ce11", "hg38".
my $input_g  = '';  ## such as "5-rawBAM/3A_STAR"
my $output_g = '';  ## such as "6-MAPQ30/3A_STAR"

{
## Help Infromation
my $HELP = '
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        Welcome to use RASDA (RNA-Seq Data Analyzer), version 0.9.0, 2017-10-01.
        RASDA is a Pipeline for Single-end and Paired-end RNA-Seq Data Analysis by Integrating Lots of Softwares.

        Step 5: Only the mapped reads with MAPQ>30 are retained and reads on chr_random, chr_alt, chrUn and chrM, all of them are removed.
                Assess the quality of BAM files to identify possible sequencing errors or biases by using 13 softwares:
                    SAMtools, Subread utilities, FASTQC, SAMstat, qualimap, PRESEQ, Picard, goleft, deepTools, phantompeakqualtools, QoRTs, RNA-SeQC and RSeQC.
                And aggregate the results from Kallisto, Salmon, STAR, FastQC, Picard, Samtools, Preseq, Qualimap, goleft, RNA-SeQC and RSeQC analyses
                across many samples into a single report by using MultiQC.

        Usage:
               perl  RASDA5.pl    [-version]    [-help]   [-genome RefGenome]    [-in inputDir]    [-out outDir]
        For instance:
               perl  RASDA5.pl   -genome hg38   -in 5-rawBAM/3A_STAR   -out 6-MAPQ30/3A_STAR    > RASDA5.runLog

        ----------------------------------------------------------------------------------------------------------
        Optional arguments:
        -version        Show version number of this program and exit.

        -help           Show this help message and exit.

        Required arguments:
        -genome RefGenome   "RefGenome" is the short name of your reference genome, such as "mm10", "ce11", "hg38".    (no default)

        -in inputDir        "inputDir" is the name of input path that contains your BAM files.  (no default)

        -out outDir         "outDir" is the name of output path that contains your running results (BAM files) of this step.  (no default)
        -----------------------------------------------------------------------------------------------------------

        For more details about this pipeline and other NGS data analysis piplines, please visit https://github.com/CTLife/2ndGS_Pipelines

        Yong Peng @ Jie Qiao Lab, yongp@outlook.com, Key Laboratory of Assisted Reproduction at Third Hospital,
        Academy for Advanced Interdisciplinary Studies, and Peking-Tsinghua Center for Life Sciences (CLS), Peking University, China.
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        ------------------------------------------------------------------------------------------------------------------------------------------------------
';

## Version Infromation
my $version = "    The Fifth Step of RASDA (RNA-Seq Data Analyzer), version 0.9.0, 2017-10-01.";

## Keys and Values
if ($#ARGV   == -1)   { say  "\n$HELP\n";  exit 0;  }       ## when there are no any command argumants.
if ($#ARGV%2 ==  0)   { @ARGV = (@ARGV, "-help") ;  }       ## when the number of command argumants is odd.
my %args = @ARGV;

## Initialize  Variables
$genome_g = 'hg38';                ## This is only an initialization value or suggesting value, not default value.
$input_g  = '5-rawBAM/3A_STAR';    ## This is only an initialization value or suggesting value, not default value.
$output_g = '6-MAPQ30/3A_STAR';    ## This is only an initialization value or suggesting value, not default value.

## Available Arguments
my $available = "   -version    -help   -genome   -in   -out  ";
my $boole = 0;
while( my ($key, $value) = each %args ) {
    if ( ($key =~ m/^\-/) and ($available !~ m/\s$key\s/) ) {say    "\n\tCann't recognize $key";  $boole = 1; }
}
if($boole == 1) {
    say  "\tThe Command Line Arguments are wrong!";
    say  "\tPlease see help message by using 'perl  RASDA5.pl  -help' \n";
    exit 0;
}

## Get Arguments
if ( exists $args{'-version' }   )     { say  "\n$version\n";    exit 0; }
if ( exists $args{'-help'    }   )     { say  "\n$HELP\n";       exit 0; }
if ( exists $args{'-genome'  }   )     { $genome_g = $args{'-genome'  }; }else{say   "\n -genome is required.\n";   say  "\n$HELP\n";    exit 0; }
if ( exists $args{'-in'      }   )     { $input_g  = $args{'-in'      }; }else{say   "\n -in     is required.\n";   say  "\n$HELP\n";    exit 0; }
if ( exists $args{'-out'     }   )     { $output_g = $args{'-out'     }; }else{say   "\n -out    is required.\n";   say  "\n$HELP\n";    exit 0; }

## Conditions
$genome_g =~ m/^\S+$/    ||  die   "\n\n$HELP\n\n";
$input_g  =~ m/^\S+$/    ||  die   "\n\n$HELP\n\n";
$output_g =~ m/^\S+$/    ||  die   "\n\n$HELP\n\n";

## Print Command Arguments to Standard Output
say  "\n
        ################ Arguments ###############################
                Reference Genome:  $genome_g
                Input       Path:  $input_g
                Output      Path:  $output_g
        ###############################################################
\n";
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say    "\n\n\n\n\n\n##################################################################################################";
say    "Running......";

sub myMakeDir  {
    my $path = $_[0];
    if ( !( -e $path) )  { system("mkdir  -p  $path"); }
    if ( !( -e $path) )  { mkdir $path  ||  die; }
}

my $output2_g = "$output_g/QC_Results";
&myMakeDir($output_g);
&myMakeDir($output2_g);

opendir(my $DH_input_g, $input_g)  ||  die;
my @inputFiles_g = readdir($DH_input_g);
my $pattern_g    = "[-.0-9A-Za-z]+";
my $numCores_g   = 4;
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "Checking all the necessary softwares in this step......" ;

sub printVersion  {
    my $software = $_[0];
    system("echo    '##############################################################################'  >> $output2_g/VersionsOfSoftwares.txt   2>&1");
    system("echo    '#########$software'                                                              >> $output2_g/VersionsOfSoftwares.txt   2>&1");
    system("$software                                                                                 >> $output2_g/VersionsOfSoftwares.txt   2>&1");
    system("echo    '\n\n\n\n\n\n'                                                                    >> $output2_g/VersionsOfSoftwares.txt   2>&1");
}

sub fullPathApp  {
    my $software = $_[0];
    say($software);
    system("which   $software  > yp_my_temp_1.$software.txt");
    open(tempFH, "<", "yp_my_temp_1.$software.txt")  or  die;
    my @fullPath1 = <tempFH>;
    ($#fullPath1 == 0)  or  die;
    system("rm  yp_my_temp_1.$software.txt");
    $fullPath1[0] =~ s/\n$//  or  die;
    return($fullPath1[0]);
}

my  $Picard_g = &fullPathApp("picard.jar");
my  $phantompeakqualtools_g = &fullPathApp("run_spp.R");
my  $QoRTs_g = &fullPathApp("QoRTs.jar");
my  $RNASeQC_g = &fullPathApp("RNA-SeQC.jar");

&printVersion("samtools");
&printVersion("fastqc    -v");
&printVersion("samstat   -v");
&printVersion("Rscript  $phantompeakqualtools_g");
&printVersion("preseq");
&printVersion("qualimap  -v");
&printVersion("multiqc   --version");
&printVersion("propmapped");     ## in subread
&printVersion("qualityScores");  ## in subread
&printVersion("plotFingerprint --version");
&printVersion("goleft  -v");

&printVersion("bam_stat.py             --version");  ## in RSeQC
&printVersion("geneBody_coverage.py    --version");  ## in RSeQC
&printVersion("inner_distance.py       --version");  ## in RSeQC
&printVersion("junction_annotation.py  --version");  ## in RSeQC
&printVersion("junction_saturation.py  --version");  ## in RSeQC
&printVersion("read_distribution.py    --version");  ## in RSeQC
&printVersion("read_duplication.py     --version");  ## in RSeQC
&printVersion("RPKM_saturation.py      --version");  ## in RSeQC
&printVersion("tin.py                  --version");  ## in RSeQC

&printVersion("java  -jar  $QoRTs_g");
&printVersion("java  -jar  $RNASeQC_g");

&printVersion("java  -jar  $Picard_g   CollectIndependentReplicateMetrics  --version");
&printVersion("java  -jar  $Picard_g   CollectAlignmentSummaryMetrics      --version");
&printVersion("java  -jar  $Picard_g   CollectBaseDistributionByCycle      --version");
&printVersion("java  -jar  $Picard_g   CollectGcBiasMetrics                --version");
&printVersion("java  -jar  $Picard_g   CollectInsertSizeMetrics            --version");
&printVersion("java  -jar  $Picard_g   CollectJumpingLibraryMetrics        --version");
&printVersion("java  -jar  $Picard_g   CollectMultipleMetrics              --version");
&printVersion("java  -jar  $Picard_g   CollectOxoGMetrics                  --version");
&printVersion("java  -jar  $Picard_g   CollectQualityYieldMetrics          --version");
&printVersion("java  -jar  $Picard_g   CollectSequencingArtifactMetrics    --version");
&printVersion("java  -jar  $Picard_g   CollectTargetedPcrMetrics           --version");
&printVersion("java  -jar  $Picard_g   CollectWgsMetrics                   --version");
&printVersion("java  -jar  $Picard_g   EstimateLibraryComplexity           --version");
&printVersion("java  -jar  $Picard_g   MeanQualityByCycle                  --version");
&printVersion("java  -jar  $Picard_g   QualityScoreDistribution            --version");
###################################################################################################################################################################################################





###################################################################################################################################################################################################
{
say   "\n\n\n\n\n\n##################################################################################################";
say   "Checking all the input file names ......";
my @groupFiles = ();
my $fileNameBool = 1;
for ( my $i=0; $i<=$#inputFiles_g; $i++ ) {
        next unless $inputFiles_g[$i] =~ m/\.bam$/;
        next unless $inputFiles_g[$i] !~ m/^[.]/;
        next unless $inputFiles_g[$i] !~ m/[~]$/;
        next unless $inputFiles_g[$i] !~ m/^QC_Results$/;
        next unless $inputFiles_g[$i] !~ m/^unpaired/;
        say   "\t......$inputFiles_g[$i]" ;
        my $temp = $inputFiles_g[$i];
        $groupFiles[++$#groupFiles] = $inputFiles_g[$i];
        $temp =~ m/^(\d+)_($pattern_g)_(Rep[1-9])/   or  die   "wrong-1: ## $temp ##";
        $temp =~ m/_(Rep[1-9])\.bam$/   or  die   "wrong-2: ## $temp ##";
        if($temp !~ m/^((\d+)_($pattern_g)_(Rep[1-9]))(_[1-2])?\.bam$/) {
             $fileNameBool = 0;
        }
}
if($fileNameBool == 1)  { say    "\n\t\tAll the file names are passed.\n";  }
@groupFiles   = sort(@groupFiles);
my $numGroup  = 0;
my $noteGroup = 0;
for ( my $i=0; $i<=$#groupFiles; $i++ ) {
    $groupFiles[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])/  or  die;
    my $n1 = $1;
    $n1>=1  or  die;
    if($noteGroup != $n1) {say "\n\t\tGroup $n1:";  $numGroup++; }
    say  "\t\t\t$groupFiles[$i]";
    $noteGroup = $n1;
}
say  "\n\t\tThere are $numGroup groups.";
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "Detecting BAM files in input folder ......";
my @BAMfiles_g = ();
{
open(seqFiles_FH, ">", "$output2_g/BAM-Files.txt")  or  die; 
for ( my $i=0; $i<=$#inputFiles_g; $i++ ) {     
    next unless $inputFiles_g[$i] =~ m/\.bam$/;
    next unless $inputFiles_g[$i] !~ m/^[.]/;
    next unless $inputFiles_g[$i] !~ m/[~]$/;
    next unless $inputFiles_g[$i] !~ m/^unpaired/;
    say    "\t......$inputFiles_g[$i]"; 
    $inputFiles_g[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])\.bam$/  or  die;  
    $BAMfiles_g[$#BAMfiles_g+1] =  $inputFiles_g[$i];
    say        "\t\t\t\tBAM file:  $inputFiles_g[$i]\n";
    say   seqFiles_FH  "BAM file:  $inputFiles_g[$i]\n";
}

say   seqFiles_FH  "\n\n\n\n\n";  
say   seqFiles_FH  "All BAM files:@BAMfiles_g\n\n\n";
say        "\t\t\t\tAll BAM files:@BAMfiles_g\n\n";
my $num1 = $#BAMfiles_g + 1;
say seqFiles_FH   "\nThere are $num1 BAM files.\n";
say         "\t\t\t\tThere are $num1 BAM files.\n";
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_1  {
    my $dir1      =  $_[0];   ## All the SAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $SAMtools  = "$QCresults/1_SAMtools";
    my $FastQC    = "$QCresults/2_FastQC";
    my $qualimap  = "$QCresults/3_qualimap";
    my $samstat   = "$QCresults/4_samstat";
    my $MultiQC1  = "$QCresults/5_MultiQC_FastQC";
    my $MultiQC2  = "$QCresults/5_MultiQC_qualimap";
    my $MultiQC3  = "$QCresults/5_MultiQC_SAMtools";
    my $MultiQC4  = "$QCresults/5_MultiQC_Bowtie2";

    &myMakeDir($QCresults);
    &myMakeDir($SAMtools);
    &myMakeDir($FastQC);
    &myMakeDir($qualimap);
    &myMakeDir($samstat);
    &myMakeDir($MultiQC1);
    &myMakeDir($MultiQC2);
    &myMakeDir($MultiQC3);
    &myMakeDir($MultiQC4);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using SAMtools, FastQC, qualimap, samstat and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.sam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        next unless $Files[$i] !~ m/^removed/;
        next unless $Files[$i] =~ m/^[1-9]/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.sam$//  ||  die;
        system("samtools  sort  -m 2G  -o $dir1/$temp.bam   --output-fmt bam  -T $dir1/yp_$temp   --threads $numCores_g    $dir1/$temp.sam    >>$SAMtools/$temp.runLog    2>&1");
        system("samtools  index           $dir1/$temp.bam      >>$SAMtools/$temp.index.runLog  2>&1");
        system("samtools  flagstat        $dir1/$temp.bam      >>$SAMtools/$temp.flagstat      2>&1");
        system(`samtools  idxstats        $dir1/$temp.bam      >>$SAMtools/$temp.idxstats      2>&1`);
        system( "fastqc    --outdir $FastQC    --threads $numCores_g  --format bam   --kmers 7    $dir1/$temp.bam                   >> $FastQC/$temp.runLog      2>&1" );
        system( "qualimap  bamqc  -bam $dir1/$temp.bam   -c  -ip  -nt $numCores_g   -outdir $qualimap/$temp   --java-mem-size=16G   >> $qualimap/$temp.runLog    2>&1" );
        system( "samstat   $dir1/$temp.bam      >> $samstat/$temp.runLog         2>&1");
        system( "rm   $dir1/$temp.sam" );
    }

    system( "multiqc    --title FastQC     --verbose  --export   --outdir $MultiQC1          $FastQC            >> $MultiQC1/MultiQC.FastQC.runLog     2>&1" );
    system( "multiqc    --title qualimap   --verbose  --export   --outdir $MultiQC2          $qualimap          >> $MultiQC2/MultiQC.qualimap.runLog   2>&1" );
    system( "multiqc    --title SAMtools   --verbose  --export   --outdir $MultiQC3          $SAMtools          >> $MultiQC3/MultiQC.SAMtools.runLog   2>&1" );
    system( "multiqc    --title Bowtie2    --verbose  --export   --outdir $MultiQC4          $dir1/*.runLog     >> $MultiQC4/MultiQC.Bowtie2.runLog    2>&1" );

}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_2  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $Fingerprint    = "$QCresults/6_Fingerprint";
    my $Fingerprint2   = "$QCresults/7_Fingerprint2";
    my $goleft         = "$QCresults/8_goleft";
    my $phantompeak    = "$QCresults/9_phantompeakqualtools";
    my $MultiQC1       = "$QCresults/10_MultiQC_goleft";

    &myMakeDir($QCresults);
    &myMakeDir($Fingerprint);
    &myMakeDir($Fingerprint2);
    &myMakeDir($goleft);
    &myMakeDir($phantompeak);
    &myMakeDir($MultiQC1);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using plotFingerprint in deepTools, goleft , phantompeakqualtools and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.bam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        next unless $Files[$i] !~ m/^removed/;
        next unless $Files[$i] =~ m/^[1-9]/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.bam$//  ||  die;
        system("plotFingerprint --bamfiles $dir1/$temp.bam   --extendReads 220  --numberOfSamples 1000000    --plotFile $Fingerprint/$temp.pdf    --plotTitle $temp   --outRawCounts  $Fingerprint/$temp.cov   --outQualityMetrics $Fingerprint/$temp.Metrics.txt   --numberOfProcessors $numCores_g   --binSize 500    >> $Fingerprint/$temp.runLog    2>&1");                           
        system("plotFingerprint --bamfiles $dir1/$temp.bam   --extendReads 220  --numberOfSamples 1000000    --plotFile $Fingerprint2/$temp.pdf   --plotTitle $temp   --outRawCounts  $Fingerprint2/$temp.cov  --outQualityMetrics $Fingerprint2/$temp.Metrics.txt  --numberOfProcessors $numCores_g   --binSize 5000   >> $Fingerprint2/$temp.runLog   2>&1");                                   
        system("goleft   covstats    $dir1/$temp.bam  > $goleft/$temp.covstats " );
        system("goleft   indexcov  --sex chrX,chrY  -d $goleft/$temp  $dir1/$temp.bam  > $goleft/$temp.indexcov.runLog      2>&1" );
        &myMakeDir("$phantompeak/$temp");
        system("Rscript    $phantompeakqualtools_g    -c=$dir1/$temp.bam   -p=$numCores_g   -odir=$phantompeak/$temp    -savd=$phantompeak/$temp/rdatafile.RData     -savp=$phantompeak/$temp/plotdatafile.pdf   -out=$phantompeak/$temp/resultfile.txt   >> $phantompeak/$temp.runLog   2>&1");
    }
    system("sleep 5s");
    system( "multiqc    --title goleft    --verbose  --export   --outdir $MultiQC1          $goleft     >> $MultiQC1/MultiQC.goleft.runLog    2>&1" );

}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_3  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $PRESEQ    = "$QCresults/11_PRESEQ";
    my $PicardDir = "$QCresults/12_Picard";
    my $MultiQC1  = "$QCresults/13_MultiQC_PRESEQ";
    my $MultiQC2  = "$QCresults/13_MultiQC_Picard";

    &myMakeDir($QCresults);
    &myMakeDir($PRESEQ);
    &myMakeDir($PicardDir);
    &myMakeDir($MultiQC1);
    &myMakeDir($MultiQC2);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using PRESEQ, Picard and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.bam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        next unless $Files[$i] !~ m/^removed/;
        next unless $Files[$i] =~ m/^[1-9]/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.bam$//  ||  die;
        system("preseq  c_curve     -output  $PRESEQ/$temp.c_curve.pe.PRESEQ       -step 1000000    -verbose   -pe  -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.c_curve.pe.runLog   2>&1");
        system("preseq  c_curve     -output  $PRESEQ/$temp.c_curve.se.PRESEQ       -step 1000000    -verbose        -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.c_curve.se.runLog   2>&1");
        system("preseq  lc_extrap   -output  $PRESEQ/$temp.lc_extrap.pe.PRESEQ     -step 1000000    -verbose   -pe  -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.lc_extrap.pe.runLog   2>&1");
        system("preseq  lc_extrap   -output  $PRESEQ/$temp.lc_extrap.se.PRESEQ     -step 1000000    -verbose        -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.lc_extrap.se.runLog   2>&1");

        &myMakeDir("$PicardDir/$temp");
        #system("java  -jar   $Picard_g   CollectIndependentReplicateMetrics      INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/0_CollectIndependentReplicateMetrics     VCF=null    MINIMUM_MQ=20                                    >> $PicardDir/$temp/0.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectAlignmentSummaryMetrics          INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/1_CollectAlignmentSummaryMetrics                                                                      >> $PicardDir/$temp/1.runLog   2>&1" );
        system("java  -jar   $Picard_g   EstimateLibraryComplexity               INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/2_EstimateLibraryComplexity                                                                           >> $PicardDir/$temp/2.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectInsertSizeMetrics                INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/3_CollectInsertSizeMetrics               HISTOGRAM_FILE=$PicardDir/$temp/3.pdf  MINIMUM_PCT=0.05      >> $PicardDir/$temp/3.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectJumpingLibraryMetrics            INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/4_CollectJumpingLibraryMetrics                                                                        >> $PicardDir/$temp/4.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectMultipleMetrics                  INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/5_CollectMultipleMetrics                                                                              >> $PicardDir/$temp/5.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectBaseDistributionByCycle          INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/6_CollectBaseDistributionByCycle         CHART_OUTPUT=$PicardDir/$temp/6.pdf                          >> $PicardDir/$temp/6.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectQualityYieldMetrics              INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/7_CollectQualityYieldMetrics                                                                          >> $PicardDir/$temp/7.runLog   2>&1" );
        #system("java  -jar   $Picard_g   CollectWgsMetrics                       INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/8_CollectWgsMetricsFromQuerySorted       REFERENCE_SEQUENCE=null                                      >> $PicardDir/$temp/8.runLog   2>&1" );
        system("java  -jar   $Picard_g   MeanQualityByCycle                      INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/9_MeanQualityByCycle                     CHART_OUTPUT=$PicardDir/$temp/9.pdf                          >> $PicardDir/$temp/9.runLog   2>&1" );
        system("java  -jar   $Picard_g   QualityScoreDistribution                INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/10_QualityScoreDistribution              CHART_OUTPUT=$PicardDir/$temp/10.pdf                         >> $PicardDir/$temp/10.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectGcBiasMetrics                    INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/11_CollectGcBiasMetrics                  CHART_OUTPUT=$PicardDir/$temp/11.pdf   SUMMARY_OUTPUT=$PicardDir/$temp/11.summary.output                  >> $PicardDir/$temp/11.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectOxoGMetrics                      INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/12_CollectOxoGMetrics                    REFERENCE_SEQUENCE=null                                      >> $PicardDir/$temp/12.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectSequencingArtifactMetrics        INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/13_CollectSequencingArtifactMetrics                                       >> $PicardDir/$temp/13.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectTargetedPcrMetrics               INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/14_CollectTargetedPcrMetrics                                        >> $PicardDir/$temp/14.runLog  2>&1" );
    }
    system( "multiqc  --title PRESEQ    --verbose  --export  --outdir $MultiQC1          $PRESEQ                 >> $MultiQC1/MultiQC.PRESEQ.runLog   2>&1" );
    system( "multiqc  --title Picard    --verbose  --export  --outdir $MultiQC2          $PicardDir              >> $MultiQC2/MultiQC.Picard.runLog   2>&1" );
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_4  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $SubreadUti= "$QCresults/14_SubreadUti";

    &myMakeDir("$QCresults");
    &myMakeDir("$SubreadUti");

    opendir(my $DH_map, $dir1) || die;
    my @mapFiles = readdir($DH_map);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of bam files by using Subreads utilities and goleft ......";
    for (my $i=0; $i<=$#mapFiles; $i++) {
           next unless $mapFiles[$i] =~ m/\.bam$/;
           next unless $mapFiles[$i] !~ m/^[.]/;
           next unless $mapFiles[$i] !~ m/[~]$/;
           next unless $mapFiles[$i] !~ m/^removed/;
           next unless $mapFiles[$i] =~ m/^[1-9]/;
           my $temp = $mapFiles[$i];
           $temp =~ s/\.bam$//  ||  die;
           say   "\t......$mapFiles[$i]";
           system("propmapped   -i $dir1/$temp.bam                    -o $SubreadUti/$temp.prommapped      >> $SubreadUti/$temp.prommapped      2>&1");
           system("echo      '\n\n\n\n\n'                                                                  >> $SubreadUti/$temp.prommapped      2>&1");
           system("propmapped   -i $dir1/$temp.bam       -f           -o $SubreadUti/$temp.prommapped      >> $SubreadUti/$temp.prommapped      2>&1");
           system("echo      '\n\n\n\n\n'                                                                  >> $SubreadUti/$temp.prommapped      2>&1");
           system("propmapped   -i $dir1/$temp.bam       -f   -p      -o $SubreadUti/$temp.prommapped      >> $SubreadUti/$temp.prommapped      2>&1");
           system("qualityScores   --BAMinput   -i $dir1/$temp.bam    -o $SubreadUti/$temp.qualityScores   >> $SubreadUti/$temp.qualityScores   2>&1");
     }
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_RNA  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $QoRTs     = "$QCresults/RNA_1_QoRTs";
    my $RSeQC     = "$QCresults/RNA_2_RSeQC";
    my $RNA_SeQC  = "$QCresults/RNA_3_RNA-SeQC";
    my $MultiQC1  = "$QCresults/RNA_4_MultiQC1_RSeQC";
    my $MultiQC2  = "$QCresults/RNA_4_MultiQC2_RNA-SeQC";

    &myMakeDir($QCresults);
    &myMakeDir($QoRTs);
    &myMakeDir($RSeQC);
    &myMakeDir($RNA_SeQC);
    &myMakeDir($MultiQC1);
    &myMakeDir($MultiQC2);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using QoRTs, RSeQC, RNA-SeQC and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.bam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.bam$//  ||  die;

        &myMakeDir("$QoRTs/$temp");
        system("java  -jar  $QoRTs_g  QC    --generatePlots   $dir1/$temp.bam   0-Other/Shortcuts/$genome_g/$genome_g.RefSeq.GTF   $QoRTs/$temp   >> $QoRTs/$temp.runLog   2>&1");

        &myMakeDir("$RSeQC/$temp");
        system("tin.py                  --input=$dir1/$temp.bam                                                          --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed         >> $RSeQC/$temp/1-tin.runLog                   2>&1");
        system("bam_stat.py             --input-file=$dir1/$temp.bam                                                                                                                               >> $RSeQC/$temp/2-bam_stat.runLog              2>&1");
        system("clipping_profile.py     --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/3-clipping_profile     --sequencing=PE                                                           >> $RSeQC/$temp/3-clipping_profile.runLog      2>&1");
        system("deletion_profile.py     --input=$dir1/$temp.bam         --out-prefix=$RSeQC/$temp/4-deletion_profile     --read-align-length=150                                                   >> $RSeQC/$temp/4-deletion_profile.runLog      2>&1");
        system("geneBody_coverage.py    --input=$dir1/$temp.bam         --out-prefix=$RSeQC/$temp/5-geneBody_coverage    --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed         >> $RSeQC/$temp/5-geneBody_coverage.runLog     2>&1");
        system("inner_distance.py       --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/6-inner_distance       --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed         >> $RSeQC/$temp/6-inner_distance.runLog        2>&1");
        system("insertion_profile.py    --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/7-insertion_profile    --sequencing=PE                                                           >> $RSeQC/$temp/7-insertion_profile.runLog     2>&1");
        system("junction_annotation.py  --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/8-junction_annotation  --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed         >> $RSeQC/$temp/8-junction_annotation.runLog   2>&1");
        system("junction_saturation.py  --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/9-junction_saturation  --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed         >> $RSeQC/$temp/9-junction_saturation.runLog   2>&1");
        system("mismatch_profile.py     --input=$dir1/$temp.bam         --out-prefix=$RSeQC/$temp/10-mismatch_profile     --read-align-length=150                                                  >> $RSeQC/$temp/10-mismatch_profile.runLog     2>&1");
        system("read_distribution.py    --input-file=$dir1/$temp.bam                                                     --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed         >> $RSeQC/$temp/11-read_distribution.runLog    2>&1");
        system("read_duplication.py     --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/11-read_duplication                                                                              >> $RSeQC/$temp/12-read_duplication.runLog     2>&1");
        system("read_GC.py              --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/12-read_GC                                                                                       >> $RSeQC/$temp/13-read_GC.runLog              2>&1");
        system("read_NVC.py             --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/13-read_NVC             --nx                                                                     >> $RSeQC/$temp/14-read_NVC.runLog             2>&1");
        system("read_quality.py         --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/14-read_quality                                                                                  >> $RSeQC/$temp/15-read_quality.runLog         2>&1");
        system("RPKM_saturation.py      --input-file=$dir1/$temp.bam    --out-prefix=$RSeQC/$temp/15-RPKM_saturation      --refgene=0-Other/GenesBED/$genome_g/$genome_g.UCSC_knownGene.bed        >> $RSeQC/$temp/16-RPKM_saturation.runLog      2>&1");

        #system("java  -jar  $RNASeQC_g  -o $RNA_SeQC/$temp  -r 0-Other/Shortcuts/$genome_g/$genome_g.fasta     -s \"$temp|$dir1/$temp.bam|$temp\"     -t  0-Other/Shortcuts/$genome_g/$genome_g.RefSeq.GTF     >> $RNA_SeQC/$temp.runLog   2>&1");
    }
    system( "multiqc  --title RSeQC      --verbose  --export  --outdir $MultiQC1       $RSeQC                 >> $MultiQC1/MultiQC.RSeQC.runLog      2>&1" );
    #system( "multiqc  --title RNA_SeQC   --verbose  --export  --outdir $MultiQC2       $RNA_SeQC              >> $MultiQC2/MultiQC.RNA_SeQC.runLog   2>&1" );
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub myFilterSAM  {
    my $folder  = $_[0];  ## input and output dir
    my $filePre = $_[1];  ## prefix of name of input and out file
    open(FILE1, "<", "$folder/$filePre.t.sam")          or die "$!";                    
    open(FILE2, ">", "$folder/$filePre.sam")            or die "$!";  
    open(FILE3, ">", "$folder/removed_$filePre.sam")    or die "$!";  
    my $n1 = 0; ## all reads
    my $n2 = 0; ## kept reads
    my $n3 = 0; ## removed reads
    while (my $line1=<FILE1>) {
        if ($line1 =~ m/^@/) {
            print  FILE2  $line1   ;  
            print  FILE3  $line1   ;  
        }else{
            $line1 =~ m/^(\S+)\s+(\S+)\s+(\S+)\s+/  or die;
            my $chr = $3;
            $n1++;
            if( $chr =~ m/(chrM)|(chrUn_)|(chr\S+_random)|(chr\S+_alt)/ ) {
                 print  FILE3  $line1;  $n3++; 
            }else{
                 print  FILE2  $line1;  $n2++; 
            } 
        }
    }
    print      "\t\tall reads in $filePre: $n1\n";
    print     "\t\tkept reads in $filePre: $n2\n";
    print  "\t\tremoved reads in $filePre: $n3\n\n\n";
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "Removing some reads ......";
for (my $i=0; $i<=$#BAMfiles_g; $i++) {
    my $temp = $BAMfiles_g[$i]; 
    $temp =~ s/\.bam$//  ||  die; 
    say   "\t......$BAMfiles_g[$i]";
    system(`samtools  view   -h   -F 4    --threads $numCores_g    -q 30     -o $output_g/$temp.t.sam   $input_g/$temp.bam    >> $output2_g/$temp.runLog     2>&1  `);  
    &myFilterSAM($output_g, $temp); 
    system("rm   $output_g/$temp.t.sam"); 
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
&myQC_BAM_1($output_g);
&myQC_BAM_RNA($output_g);
&myQC_BAM_2($output_g);
&myQC_BAM_3($output_g); 
&myQC_BAM_4($output_g); 
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "\tJob Done! Cheers! \n\n\n\n\n";





## END
