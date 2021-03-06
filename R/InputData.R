#' Read 10X HDF5 file based on Seurat package
#'
#' This function provide a method for reading in HDF5 file from 10X platform.
#'
#' @param input Input an HDF5 object
#' @param use.names Use barcode, default is true
#' @param unique.features  use gene name, default is true
#'
#' @return The output from \code{\link{Read10X_h5}}
#' @export
#' @importFrom Matrix sparseMatrix
#' @return It will return a gene expression matrix. 
#' @examples \dontrun{input_mat <- ReadFrom10X_h5(input= "my.h5")}
ReadFrom10X_h5<-function(input=NULL,use.names = TRUE, unique.features = TRUE){
  if (!requireNamespace("hdf5r", quietly = TRUE)) {
    stop("Please install hdf5r by using install.packages('hdf5r')")
  }
  infile <- hdf5r::H5File$new(filename = input, mode = "r")
  genomes <- names(x = infile)
  output <- list()
  if (!infile$attr_exists("PYTABLES_FORMAT_VERSION")) {
    if (use.names) {
      feature_slot <- "features/name"
    }
    else {
      feature_slot <- "features/id"
    }
  }
  else {
    if (use.names) {
      feature_slot <- "gene_names"
    }
    else {
      feature_slot <- "genes"
    }
  }
  for (genome in genomes) {
    counts <- infile[[paste0(genome, "/data")]]
    indices <- infile[[paste0(genome, "/indices")]]
    indptr <- infile[[paste0(genome, "/indptr")]]
    shp <- infile[[paste0(genome, "/shape")]]
    features <- infile[[paste0(genome, "/", feature_slot)]][]
    barcodes <- infile[[paste0(genome, "/barcodes")]]
    sparse.mat <- sparseMatrix(i = indices[] + 1, p = indptr[],
                               x = as.numeric(x = counts[]), dims = shp[], giveCsparse = FALSE)
    if (unique.features) {
      features <- make.unique(names = features)
    }
    rownames(x = sparse.mat) <- features
    colnames(x = sparse.mat) <- barcodes[]
    sparse.mat <- as(object = sparse.mat, Class = "dgCMatrix")
    if (infile$exists(name = paste0(genome, "/features"))) {
      types <- infile[[paste0(genome, "/features/feature_type")]][]
      types.unique <- unique(x = types)
      if (length(x = types.unique) > 1) {
        message("Genome ", genome, " has multiple modalities, returning a list of matrices for this genome")
        sparse.mat <- sapply(X = types.unique, FUN = function(x) {
          return(sparse.mat[which(x = types == x), ])
        }, simplify = FALSE, USE.NAMES = TRUE)
      }
    }
    output[[genome]] <- sparse.mat
  }
  infile$close_all()
  if (length(x = output) == 1) {
    return(output[[genome]])
  }
  else {
    return(output)
  }
}

#' @rdname ReadFrom10X_h5
#' @export
setMethod("ReadFrom10X_h5", "BRIC", ReadFrom10X_h5)


#' Read 10X folder based on Seurat package
#' 
#' This function provide a method for reading in a folder from 10X platform. In this folder, it should contain three files: barcode, matrix, and gene.
#' @param Input.dir Input 10X Chromium output data by using output folder
#'
#' @return The output from \code{\link{Read10X}}
#' @export
#' @importFrom Matrix readMM
#'
#' @examples \dontrun{input_mat <- ReadFrom10X_folder(input.dir = "my_path_to_folder")}
ReadFrom10X_folder <- function (input.dir = NULL)
{

  my.path <- input.dir
  if (!dir.exists(paths = my.path)) {
    stop("Directory provided does not exist")
  }
  tmp.file <-list.files(path = my.path, pattern ="*" )
  gene.check <- c(any(grepl("gene",tmp.file )) | any(grepl("feature",tmp.file)))
  barcode.check <- any(grepl("barcode",tmp.file))
  matrix.check <- any(grepl("matrix",tmp.file))
  if(gene.check == FALSE) {stop(" cannot find gene name, please check the file with gene name.")}
  if(barcode.check == FALSE) {stop(" cannot find barcode information, please check the file with barcode.")}
  if(matrix.check == FALSE) {stop(" cannot find sparse matrix, please check the expression matrix")}
  if(any(grepl("gene",tmp.file ))){
    gene.path <- file.path(my.path, tmp.file[grepl("gene",tmp.file )])
  } else if (any(grepl("feature",tmp.file))) {gene.path <- file.path(my.path, tmp.file[grepl("feature",tmp.file )]) }
  barcode.path <- file.path(my.path, tmp.file[grepl("barcode",tmp.file)])
  matrix.path <- file.path(my.path, tmp.file[grepl("matrix",tmp.file)])
  matrix.readin <- readMM(file = matrix.path)
  cellID.readin <- readLines(barcode.path)
  cellID <- gsub("-1$","",cellID.readin)
  geneID.readin <- read.delim(gene.path,sep = "\t",stringsAsFactors = FALSE,header = FALSE)
  geneID <- make.unique(geneID.readin$V2)
  if (ncol(x = geneID.readin) > 2){
    data.types <- factor(x = geneID.readin$V3)
    lvls <- levels(x = data.types)
    expr.name <- "Gene Expression"
    if (expr.name %in% lvls) {
      lvls <- c(expr.name, lvls[-which(lvls ==
                                         expr.name)])
    }
    geneID <- geneID[which(geneID.readin$V3 == lvls)]


  } else {geneID <- geneID}
  colnames(matrix.readin) <- cellID
  rownames(matrix.readin) <- geneID
  return(matrix.readin)
}

#' @rdname ReadFrom10X_folder
#' @export
setMethod("ReadFrom10X_folder", "BRIC", ReadFrom10X_folder)



