% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genotypeQC.R
\name{removedSnpFemaleChrXhweControl}
\alias{removedSnpFemaleChrXhweControl}
\title{Hardy Weinberg Equilibrium test for chromosome X SNPs in female controls.}
\usage{
removedSnpFemaleChrXhweControl(plink, inputPrefix, pval = 1e-06,
  outputPvalFile, outputSNPfile, outputPrefix)
}
\arguments{
\item{plink}{an executable program in either the current working directory 
or somewhere in the command path.}

\item{inputPrefix}{the prefix of the input PLINK binary files.}

\item{pval}{the p-value cutoff for controlling HWE test in female control 
subjects. Only chromosome X SNPs are considered. 
The default value is 0.000001.}

\item{outputPvalFile}{the output pure text file that stores chromosome X 
SNPs and their sorted HWE p-values.}

\item{outputSNPfile}{the output pure text file that stores the removed SNPs, 
one per line.}

\item{outputPrefix}{the prefix of the output PLINK binary files.}
}
\value{
The output PLINK binary files after HWE test on chromosomal X 
in female controls.
}
\description{
Hardy Weinberg Equilibrium test for SNPs on the chromosome X in 
female controls.
}
\examples{
 
## In the current working directory
bedFile <- system.file("extdata", "genoUpdatedData.bed", package="Gimpute")
bimFile <- system.file("extdata", "genoUpdatedData.bim", package="Gimpute") 
famFile <- system.file("extdata", "genoUpdatedData.fam", package="Gimpute")
system(paste0("scp ", bedFile, bimFile, famFile, " ."))   
inputPrefix <- "genoUpdatedData"  
outputPvalFile <- "2_12_snpHwePvalfemaleXct.txt" 
outputSNPfile <- "2_12_snpRemovedHweFemaleXct.txt" 
outputPrefix <- "2_12_removedSnpHweFemaleX"
## Not run: Requires an executable program PLINK, e.g.
## plink <- "/home/tools/plink"
## removedSnpFemaleChrXhweControl(plink, inputPrefix, pval=0.000001,
##                                outputPvalFile, outputSNPfile, 
##                                outputPrefix)
}
\seealso{
\code{\link{removedSnpHWEauto}}
}
\author{
Junfang Chen
}
