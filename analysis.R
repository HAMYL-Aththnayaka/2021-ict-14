
# ==========================================
# IT4133 BIOINFORMATICS PROJECT
# Vertebral Column Classification
# ==========================================

# 1. Install and load required packages

packages <- c("ggplot2", "rpart", "rpart.plot")

new_packages <- packages[
  !packages %in% rownames(installed.packages())
]

if (length(new_packages) > 0) {
  install.packages(new_packages)
}

library(ggplot2)
library(rpart)
library(rpart.plot)

# 2. Create output directories

dir.create("data", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("results/figures",
           recursive = TRUE,
           showWarnings = FALSE)
dir.create("results/tables",
           recursive = TRUE,
           showWarnings = FALSE)

# 3. Download the UCI dataset

data_url <- paste0(
  "https://archive.ics.uci.edu/",
  "ml/machine-learning-databases/00212/column_2C.dat"
)

data_file <- "data/column_2C.dat"

if (!file.exists(data_file)) {
  download.file(
    data_url,
    data_file,
    mode = "wb"
  )
}

# 4. Import dataset

spine <- read.table(
  data_file,
  header = FALSE,
  stringsAsFactors = FALSE
)

# 5. Assign column names

colnames(spine) <- c(
  "pelvic_incidence",
  "pelvic_tilt",
  "lumbar_lordosis_angle",
  "sacral_slope",
  "pelvic_radius",
  "degree_spondylolisthesis",
  "class"
)

# 6. Convert target into a factor

spine$class <- factor(
  spine$class,
  levels = c("Normal", "Abnormal")
)

# Display first six records

head(spine)

# Dataset dimensions

dim(spine)

# Dataset structure

str(spine)


# ==========================================
# STEP 2: DATA QUALITY CHECKING
# ==========================================

# Check missing values
colSums(is.na(spine))

# Check duplicate records
sum(duplicated(spine))

# Check data structure
str(spine)

# Summary statistics
summary(spine)

# Check class distribution
table(spine$class)

# Check class percentages
prop.table(table(spine$class)) * 100

# Export summary information
write.csv(
  as.data.frame(summary(spine)),
  "results/tables/dataset_summary.csv"
)

