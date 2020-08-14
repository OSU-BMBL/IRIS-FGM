# IRIS-FGM

IRIS-CEM provides an R environment for integrating [LTMG](https://academic.oup.com/nar/article/47/18/e111/5542876) and [QUBIC2](https://academic.oup.com/bioinformatics/advance-article/doi/10.1093/bioinformatics/btz692/5567116)

## Abstract
Single-cell RNA-Seq data is useful in discovering cell heterogeneity and signature genes in specific cell populations in cancer and other complex diseases. Specifically, the investigation of functional gene modules (FGM) can help to understand gene interactive networks and complex biological processes. QUBIC2 is recognized as one of the most efficient and effective tools for FGM identification from scRNA-Seq data. However, its availability is limited to a C implementation, and its applicative power is affected by only a few downstream analyses functionalities. We developed an R package named IRIS-FGM (integrative scRNA-Seq interpretation system for functional gene module analysis) to support the investigation of FGMs and cell clustering using scRNA-Seq data. Empowered by QUBIC2, IRIS-FGM can identify co-expressed and co-regulated FGMs, predict types/clusters, identify differentially expressed genes, and perform functional enrichment analysis. It is noteworthy that IRIS-FGM also applies Seurat objects that can be easily used in the Seurat vignettes.

## Workflow
<img src="https://user-images.githubusercontent.com/26455910/90200476-f64ff900-dda5-11ea-902c-c91726c22eac.jpg" alt="IRISFGM_working_flow" width="400" height="700">

## Environment

1. System environment:

We recommend users to install IRIS-FGM on large memory (32GB) based UNIX/Linux operation system if the user aims at analyzing bicluster-based co-expression analysis. If the user seeks to analyze data by quick mode, we recommend installing IRIS-FGM on a small memory (8GB) based Windows or Linux operation system; IRIS-FGM does not support MAC. 

2. R environment:
R (equal or greater than 3.5)

# Usage

## Pre-installation
1. Install required packages from CRAN: 

```install.packages(c('BiocManager','devtools', 'AdaptGauss', "pheatmap", 'mixtools','MCL', 'anocva', 'qgraph','Rtools','ggpubr',"ggraph","Seurat"))```
                   
2. Install required package from Bioconductor:  

```BiocManager::install(c('org.Mm.eg.db','multtest','org.Hs.eg.db','clusterProfiler','DEsingle', 'DrImpute','scater', 'scran'))```

3. Install IRIS-FGM from github:

```devtools::install_github("BMEngineeR/IRIS-FGM", force = T)```

Now the MetaQUBIC is successfully installed and ready for use. 
***
## Data preparation

1. Download example data from [Yan's RPKM 90 cell embroyonic single cell RNA-Seq data](https://bmbl.bmi.osumc.edu/downloadFiles/Yan_expression.txt), and [paper](https://www.nature.com/articles/nsmb.2660).

2. Set the working directory where you put data and import the IRIS-FGM library.
```{r setwd, eval =FALSE, echo = TRUE}
setwd("./my_working_dir/")
library(IRISFGM)
```
## Read in data.
```InputMatrix <- read.table("./my_working_dir/Yan_expression.txt",header = T, row.names = 1)```

IRIS-FGM also provides the function to read in 10X scRNA-Seq data format.

Read HDF5 file```ReadFrom10X_h5()``` or read the folder which contain three files (barcode, sparse matrix, genes)```ReadFrom10X_folder()```

## Analysis data
### Data preprocessing and LTMG modeling
1. **Create IRIS-FGM object**:
```{r create_object, eval= FALSE, echo = TRUE,message=FALSE}
object <- CreateIRISCEMObject(InputMatrix)
```
2. **Adding meta information for your cell**:

This step can add the customized cell label by the user. The format of a file passing to `meta.info` is a data frame of which row name should be cell ID, and column name should be cell type.
```{r add_metadata, eval= FALSE, echo = TRUE}
object <- AddMeta(object, meta.info = NULL)
```

3. **Filtering out low quality data**:

Use `PlotMeta` and `SubsetData` together to filter out low-quality cells. 
```{r plot_metadata,eval= TRUE, echo = TRUE}
PlotMeta(object)
```
<img src="https://user-images.githubusercontent.com/26455910/90202006-6eb8b900-ddaa-11ea-9bcd-38ec1401e88b.png" alt="metadata" width="400" height="400">

```
object <- SubsetData(object , nFeature.upper=15000,nFeature.lower=8000,
                         Counts.upper=700000,Counts.lower=400000)
```
After cells get filtered, we can check the distribution again.
```
PlotMeta(object)
```
<img src="https://user-images.githubusercontent.com/26455910/90202006-6eb8b900-ddaa-11ea-9bcd-38ec1401e88b.png" alt="metadata" width="400" height="400">

4. **Normalization**:

Users can choose to perform normalization based on their needs. The normalization method has two options, one is the simplest CPM normalization (default `normalization = 'LibrarySizeNormalization'`). The other is from package scran and can be opened by using parameter `normalization = 'scran'`. Compared to the CPM normalization method, scran will be more accurate but takes more time.
```
object <- ProcessData(object, normalization = "LibrarySizeNormalization")
```
5. **LTMG modeling**:

Here, we will use Left-truncated Mixture Gaussian distribution to model the regulatory signal of each gene. Parameter, 'Gene_use', decides number of top high variant gene for LTMG modeling, and here we use all genes.
```{r run_LTMG, echo = TRUE,eval = FALSE}
object <- RunLTMG(object, Gene_use = "all", seed = 123)
```
### Biclustering

IRIS-FGM can provide biclustering function, which is based on our in-house novel algorithm, [QUBIC2] (https://github.com/maqin2001/qubic2) to predict functional gene module. 

**Discretization & biclustering**  
If you have more cells to analyze functional gene module you can use LTMG or Quantile based discretization ([QUBIC](https://academic.oup.com/nar/article/37/15/e101/2409951)). In this step, IRIS-FGM will generate some files in the local working directory.

1. LTMG based discretization: 

It might take a lot of time if you have a large size of cells.
```
object <- CalBinaryMultiSignal(object)
object <- RunBicluster(object, DiscretizationModel = "LTMG",OpenDual = FALSE,
                          NumBlockOutput = 100, BlockOverlap = 0.7, BlockCellMin = 15)
```
2. Quantile based discretization: 

It might require users to adjust parameter q for deciding cutoff of binarizing. 
```
object <- RunDiscretization(object, q = 0.06)
object <- RunBicluster(object, DiscretizationModel = "Quantile",OpenDual = TRUE, Extension = 0.90,
                          NumBlockOutput = 1000, BlockOverlap = 0.7, BlockCellMin = 15)
```
**Analyzing Functional gene module**
This section is based on the quantile based discretization and biclustering results.

1. Visualize co-expression gene module network: 

Yellow nodes represent the gene module network from bicluster #1. The size of the nodes indicates the degree of presence (the number of connected edges for one node). The thickness of edges indicates the value of the correlation coefficient. From this figure, we can conclude that PRAMEF4, PRAMEF9, PRAMEF6, PRAMEF5, PRAMEF15 genes are highly co-expressed. 

```
PlotModuleNetwork(object, N.bicluster = 1, cutoff=0.6, Node.color = "#E8E504")
```
<img src="https://user-images.githubusercontent.com/26455910/90209972-c6f7b700-ddba-11ea-8678-7481f3431cff.png" alt="metadata" width="900" height="700">

2. Visualize the gene module-to-module global relationship:

The figure via the number of overlap genes (controlled `edge.by = "gene"`) shows that bicluster 1, 2, 3, 9, and 10 have similar gene components. Bicluster4, 5, 6, 7, and 8 have similar gene components. The figure via the number of overlap cells (controlled `edge.by = "cell"`) shows that bicluster 1, 2, 3, 9, and 10 have similar cell components. Bicluster 4, 5, 6, 7, and 8 have similar cell components. In conclusion, bicluster 1, 2, 3, 9, and 10 may have similar gene and cell component, which differ from components of bicluster 4, 5, 6, 7, and 8.
```
PlotNetwork(object,N.bicluster =c(20:30), cutoff=0.6, edge.by = "gene")
```

<img src="https://user-images.githubusercontent.com/26455910/90210312-a11ee200-ddbb-11ea-9fd6-3ec17491def8.png" alt="metadata" width="600" height="300">
```
PlotNetwork(object,N.bicluster =c(1:10),edge.by = "cell")
```
<img src="https://user-images.githubusercontent.com/26455910/90216577-ec8dbc00-ddcc-11ea-8f37-64dbab05e8ab.png" alt="metadata" width="600" height="300">

3. Visualize bicluster 1 & bicluster 4 on heatmap.

The diagonal pattern validates that bicluster 1 and bicluster 4 has different cell and gene components. Gene module in bicluster 1 may have a different function comparing to gene module in the bicluster 4.   
```
PlotHeatmap(object,N.bicluster = c(1,4),show.annotation = F)
```
<img src="https://user-images.githubusercontent.com/26455910/90216551-d41da180-ddcc-11ea-9ac2-ecf647912b25.png" alt="metadata" width="400" height="300">

4. Functional enrichment analysis.

ISIR-FGM provide a functional enrichment analysis for gene module. 

1. For gene module from bicluster 1. 

```








