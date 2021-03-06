
#' Prepare a bim-like reference file
#'
#' @description
#' Prepare a bim-like file from the imputation reference legend file
#' (e.g. 1000 genome project).

#' @param inputFile a set of legend file from the imputation reference panel.
#' For example, 1000 genome projects.
#' @param referencePanel a string indicating the type of imputation 
#' reference panels is used: c("1000Gphase1v3_macGT1", "1000Gphase3").
#' @param outputFile the pure text file that stores the prepared PLINK BIM
#' file alike format data.
#' @param ncore the number of cores used for computation.
#' The default is 20.

#' @return Prepare a bim-like reference file. Note that the column names
#' are already defined, i.e. "chr", "rsID", "pos", "a0", "a1."
#' @details To prepare a bim-like reference file from legend files.
#' One should first extract the specific content from these legend files
#' after downloading. Note that extract only biallelic SNPs (only 1 allele
#' in column3 and 4, and start with 'rs") and remove duplicated snp IDs.
#' Column names are added in the end.


#' @author Junfang Chen
##' @export
#' @import doParallel

.prepareLegend2bim <- function(inputFile, referencePanel, outputFile, ncore=20){

    tmpFolder <- "tmp4legend"
    system(paste0("mkdir ", tmpFolder))
    system(paste0("scp ", inputFile, " ", tmpFolder))
    setwd(tmpFolder)
    system("gunzip *.gz")
    if (referencePanel == "1000Gphase1v3_macGT1"){ 
        prefix <- "ALL_1000G_phase1integrated_v3_chr"
        suffix <- "_impute_macGT1.legend"
        XnonPAR <- paste0(prefix, "X_nonPAR", suffix)
        XnonPARv2 <- paste0(prefix, "23", suffix)
        XPAR1 <- paste0(prefix, "X_PAR1", suffix)
        XPAR1v2 <- paste0(prefix, "24", suffix)
        XPAR2 <- paste0(prefix, "X_PAR2", suffix)
        XPAR2v2 <- paste0(prefix, "25", suffix)
    } else if (referencePanel == "1000Gphase3"){
        prefix <- "1000GP_Phase3_chr"
        suffix <- ".legend"
        XnonPAR <- paste0(prefix, "X_NONPAR", suffix)
        XnonPARv2 <- paste0(prefix, "23", suffix)
        XPAR1 <- paste0(prefix, "X_PAR1", suffix)
        XPAR1v2 <- paste0(prefix, "24", suffix)
        XPAR2 <- paste0(prefix, "X_PAR2", suffix)
        XPAR2v2 <- paste0(prefix, "25", suffix)
    } else { print("Wrong reference panel during alignment check!!")}
    ## change chrX.legend files and chr24 is for parallel computing
    system(paste0("mv ", XnonPAR, " ", XnonPARv2))
    system(paste0("mv ", XPAR1, " ", XPAR1v2))
    system(paste0("mv ", XPAR2, " ", XPAR2v2))
    chrslist <- as.list(seq_len(25))
    mclapply(chrslist, function(i){
        arg1 <- paste0("awk '{print $1, $2, $3, $4}' ")  
        a2 <- paste0(" | awk '{if(length($3) == 1 && length($4) == 1) print}'")
        a3 <- paste0(" | grep 'rs' | awk '{ if (a[$1]++ == 0) print $0; }' ")
        a4 <- paste0(" | tail -n+2  > chr")
        system(paste0(arg1, prefix, i, suffix, a2, a3, a4, i, ".txt"))
    }, mc.cores=ncore)
    ## add chr
    mclapply(chrslist, function(i){
        bimTmp <- paste0(" > bimChr", i, ".txt")
        system(paste0("awk '{print ", i, ", $0}' chr", i, ".txt", bimTmp))
    }, mc.cores=ncore)
    ## --> Change chr24 to chr25
    system(paste0("awk '{print ", 25, ", $0}' chr24.txt > bimChr24.txt"))
    system("cat bimChr*.txt >> chrAl.txt ")
    system("{ printf 'chr\trsID\tpos\ta0\ta1\n'; cat chrAl.txt; } > final.txt ")
    ## only for the panel "1000Gphase3"
    if (referencePanel == "1000Gphase3"){
        system("mv final.txt f4.txt")  
        system("awk '{print $1, $2}' f4.txt > final.txt") 
        system("rm f4.txt")
    }  
    setwd("..")  
    system(paste0("mv ", tmpFolder, "/final.txt ", outputFile)) 
    ## Do not remove, for recoding the disk usage
    # system(paste0("rm -r ", tmpFolder))  
}


#' Check the alignment with the imputation reference panel
#'
#' @description
#' Perform the alignment against a reference panel by considering the following
#' parameters: variant name, genomic position and the allele profile.
#' Output files are generated sequentially depending on their previous PLINK data.

#' @param plink an executable program in either the current working directory
#' or somewhere in the command path.
#' @param inputPrefix the prefix of the input PLINK files.
#' @param referencePanel a string indicating the type of imputation 
#' reference panels is used: c("1000Gphase1v3_macGT1", "1000Gphase3").
#' @param bimReferenceFile the reference file used for the alignment, which is
#' a PLINK BIM alike format file.
#' @param out2 the prefix of the output PLINK binary files after removing SNPs
#' whose genomic positions are not in the imputation reference,
#' taking SNP names into account.
#' @param out2.snp the output plain text file that stores the removed SNPs
#' whose genomic positions are not in the imputation reference,
#' taking SNP names into account.
#' @param out3 the prefix of the output PLINK binary files after removing SNPs
#' whose genomic positions are not in the imputation reference,
#' ingoring SNP names.
#' @param out3.snp the output plain text file that stores the removed SNPs
#' whose genomic positions are not in the imputation reference,
#' ingoring SNP names.
#' @param out4 the prefix of the output PLINK binary files after removing SNPs
#' whose alleles are not in the imputation reference,
#' taking their genomic positions into account.
#' @param out4.snp the output plain text file that stores the removed SNPs
#' whose alleles are not in the imputation reference,
#' taking their genomic positions into account.
#' @param out4.snpRetained the output plain text file that stores the
#' removed SNPs whose alleles are in the imputation reference,
#' taking their genomic positions into account.

#' @param nCore the number of cores used for computation.
#' This can be tuned along with nThread.
#' @return The set of aligned PLINK files from your own study compared with
#' the imputation reference.
#' @details The output files are genrated in order. Genomic position includes
#' chromosomal location and base-pair position of the individual variant.
#' All monomorphic SNPs are retained for further processing.

#' @author Junfang Chen
###' @examples
#' @export
#' @import doParallel


checkAlign2ref <- function(plink, inputPrefix, referencePanel, bimReferenceFile, 
                           out2, out2.snp, out3, out3.snp, out4, 
                           out4.snp, out4.snpRetained, nCore=25){

    bim <- read.table(paste0(inputPrefix, ".bim"), stringsAsFactors=FALSE)

    if (referencePanel == "1000Gphase3"){
        impRefRaw <- read.table(file=bimReferenceFile, header=TRUE,
                             stringsAsFactors=FALSE)  
        refTmp = strsplit(impRefRaw[,2], ":", fixed = TRUE)
        mat <- matrix(unlist(refTmp), byrow=TRUE, ncol=length(refTmp[[1]]))
        subRef <- data.frame(rsID=mat[,1], pos=as.integer(mat[,2]), 
                         a0=mat[,3], a1=mat[,4], stringsAsFactors=FALSE) 
        impRef <- cbind(chr=impRefRaw[,1], subRef) 

    } else { 
        impRef <- read.table(file=bimReferenceFile, header=TRUE,
                             stringsAsFactors=FALSE)
    } 
    ## step 1: for the same SNP names, but with different genomic position
    interSNPs <- intersect(bim[,2], impRef[,"rsID"])
    bimSubV1 <- bim[match(interSNPs, bim[,2]), ]
    impRefSubV1 <- impRef[match(interSNPs, impRef[,"rsID"]), ]

    ## check chr and bp position consistency
    whChrNotSame <- which(bimSubV1[,1]!= impRefSubV1[,"chr"])
    whPosNotSame <- which(bimSubV1[,4]!= impRefSubV1[,"pos"])
    whChrPosNotSame <- union(whChrNotSame, whPosNotSame)
    # str(whChrPosNotSame)
    snpSameNameDiffPos <- bimSubV1[whChrPosNotSame, 2]
    write.table(snpSameNameDiffPos, file=paste0(out2.snp, ".txt"), quote=FALSE,
                row.names=FALSE, col.names=FALSE, eol="\r\n", sep=" ")
    cmd1 <- paste0(plink, " --bfile ", inputPrefix, " --exclude ")
    cmd2 <- paste0(out2.snp, ".txt --make-bed --out ", out2)
    system(paste0(cmd1, cmd2))

    bimSubV2tmpV1 <- bimSubV1[!is.element(bimSubV1[,2], snpSameNameDiffPos), ]
    bimSubV2tmpV2 <- bim[!is.element(bim[,2], interSNPs), ]
    bimSubV2 <- rbind(bimSubV2tmpV1, bimSubV2tmpV2)
    ## step 2: SNPs with different genomic position (chr+bp) other than that
    ## in the imputation reference, ignoring the same SNP name.
    chrDist <- table(bimSubV2[,1])
    currentChr <- names(chrDist)
    print(currentChr)

    sharePosList <- mclapply(as.list(currentChr), function(i){

        print(i)
        bimSubSet <- bimSubV2[which(bimSubV2[,1] == i), ]
        impRefSubSet <- impRef[which(impRef[,"chr"] == i), ]
        sharedPos <- intersect(bimSubSet[,4], impRefSubSet[,"pos"])
        print(length(sharedPos))
        if (length(sharedPos) != 0){
            bimSubSub <- bimSubSet[match(sharedPos, bimSubSet[,4]), ]
            refSub2 <- impRefSubSet[match(sharedPos, impRefSubSet[,"pos"]), ]
            # sum(bimSubSub[,4] == refSub2[,"pos"])
            subComb <- cbind(bimSubSub, refSub2)
            ## SNPs with common genomic position
            snpSharedPos <- subComb[is.element(subComb[,4], sharedPos), 2]
            ## SNPs with common genomic position but diff alleles
            bimAlleleMat <- apply(subComb[,5:6], 1, sort)
            refAlleleMat <- apply(subComb[,c("a0","a1")], 1, sort)
            bimAA <- paste0(bimAlleleMat[1,], bimAlleleMat[2,])
            refAA <- paste0(refAlleleMat[1,], refAlleleMat[2,])

            subCombV1 <- cbind(subComb, bimAA, refAA)
            snpSharedPosAllele <- subCombV1[which(bimAA == refAA), 2]
            list(snpSharedPos, snpSharedPosAllele)
        }
    }, mc.cores=nCore)

    snpSharedPos <- unique(unlist(lapply(sharePosList, function(i){i[1]})))
    posAllelTmp <- unlist(lapply(sharePosList, function(i){i[2]}))
    snpSharedPosAllele <- unique(posAllelTmp)

    ## find the different genomic position
    snpDifpos <- bimSubV2[!is.element(bimSubV2[,2], snpSharedPos), 2] 
    write.table(snpDifpos, file=paste0(out3.snp, ".txt"), quote=FALSE,
                row.names=FALSE, col.names=FALSE, eol="\r\n", sep=" ")
    cmd1 <- paste0(plink, " --bfile ", out2, " --exclude ")
    cmd2 <- paste0(out3.snp, ".txt --make-bed --out ", out3)
    system(paste0(cmd1, cmd2))

    ## step 3:
    ## find the same genomic position and but different alleles
    snpDifAlleleMono <- setdiff(snpSharedPos, snpSharedPosAllele)
    difAllelMonoBIM <- bimSubV2[is.element(bimSubV2[,2], snpDifAlleleMono), ]
    snpDifAllel4mono <- difAllelMonoBIM[which(difAllelMonoBIM[,5] == "0"), 2]
    snpDifAllele <- setdiff(snpDifAlleleMono, snpDifAllel4mono)

    write.table(snpDifAllele, file=paste0(out4.snp, ".txt"), quote=FALSE,
                row.names=FALSE, col.names=FALSE, eol="\r\n", sep=" ")
    cmd1 <- paste0(plink, " --bfile ", out3, " --exclude ")
    cmd2 <- paste0(out4.snp, ".txt --make-bed --out ", out4)
    system(paste0(cmd1, cmd2))

    snpSharedPosAllele <- c(snpSharedPosAllele, snpDifAllel4mono)
    ## keep those SNPs with same genomic position and alleles
    write.table(snpSharedPosAllele, 
                file=paste0(out4.snpRetained, ".txt"),
                quote=FALSE, row.names=FALSE, 
                col.names=FALSE, eol="\r\n", sep=" ")

    system(paste0("rm  *.log")) 
}


#' Find shared genomic position between two files.
#'
#' @description
#' Find shared genomic position between two files
#' and return the snp names of the second input file.

#' @param inputFile1 the pure text file that has at least three columns:
#' chromosomal location, snp name and base-pair position, with the name 
#' c("chr", "rsID", "pos")
#' @param inputFile2 the pure text file that has at least three columns:
#' chromosomal location, snp name and base-pair position, with the name 
#' c("chr", "rsID", "pos")
#' @param outputFile the pure text file return the snp name of 
#' the second input file.
#' @param nCore the number of cores used for computation.
#' The default is 20.

#' @return The snp name of the second input file which shares the same genomic
#' position with that of the first input file.

##' @export
#' @import doParallel

.snpSharedPos <- function(inputFile1, inputFile2, outputFile, nCore=20){

    chrDist <- table(inputFile1[,"chr"])
    currentChr <- names(chrDist)
    print(currentChr)
    
    snpSharedPosList <- mclapply(as.list(currentChr), function(i){
        print(i)
        inputFile1sub <- inputFile1[which(inputFile1[,"chr"] == i), ]
        sub2 <- inputFile2[which(inputFile2[,"chr"] == i), ]
        sharedPos <- intersect(inputFile1sub[,"pos"], sub2[,"pos"])
        print(length(sharedPos))
        snpSharedPos <- sub2[is.element(sub2[,"pos"], sharedPos), "rsID"]

    }, mc.cores=nCore)

    snpSharedPos <- unique(unlist(snpSharedPosList))
    write.table(snpSharedPos, file=outputFile, quote=FALSE,
                row.names=FALSE, col.names=FALSE, eol="\r\n", sep=" ")
}

