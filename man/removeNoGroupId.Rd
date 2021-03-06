% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genotypeInfoUpdate.R
\name{removeNoGroupId}
\alias{removeNoGroupId}
\title{Remove samples without group information}
\usage{
removeNoGroupId(plink, inputPrefix, outputPrefix)
}
\arguments{
\item{plink}{an executable program in either the current working directory 
or somewhere in the command path.}

\item{inputPrefix}{the prefix of the input PLINK binary files.}

\item{outputPrefix}{the prefix of the output PLINK binary files.}
}
\value{
The output PLINK binary files after removing samples without group 
information.
}
\description{
Remove samples without group/outcome/phenotype information, which is coded 
as -9 in the PLINK .FAM file.
}
\examples{
## In the current working directory
bedFile <- system.file("extdata", "controlData.bed", package="Gimpute")
bimFile <- system.file("extdata", "controlData.bim", package="Gimpute") 
famFile <- system.file("extdata", "controlData.fam", package="Gimpute")
system(paste0("scp ", bedFile, bimFile, famFile, " ."))
inputPrefix <- "controlData" ## Specify the input PLINK file prefix
outputPrefix <- "1_04_removedNoGroupId" 
## Not run: Requires an executable program PLINK, e.g.
## plink <- "/home/tools/plink"
## removeNoGroupId(plink, inputPrefix, outputPrefix)
}
\author{
Junfang Chen
}
