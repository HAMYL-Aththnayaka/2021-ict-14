
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

# Download the UCI dataset

data_url <- "https://raw.githubusercontent.com/MinorProphet/Vertebral-Column-Data-Set/master/column_2C.dat"

data_file <- "data/column_2C.dat"

if (!file.exists(data_file)) {
  download.file(
    data_url,
    data_file,
    mode = "wb"
  )
}

cat("Dataset downloaded successfully!\n")
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


# 6. Convert original class labels

# Check the original labels
unique(spine$class)

spine$class <- factor(
  ifelse(spine$class == "NO", "Normal", "Abnormal"),
  levels = c("Normal", "Abnormal")
)

print(table(spine$class))

# Check the corrected class distribution
table(spine$class)


# Display first six records

head(spine)

# Dataset dimensions

dim(spine)

# Dataset structure

str(spine)

# ==========================================
# PART 2: DATA QUALITY CHECKS
# ==========================================

# 1. Check missing values
cat("\nMissing values:\n")
print(colSums(is.na(spine)))

# 2. Check duplicate records
cat("\nDuplicate records:\n")
print(sum(duplicated(spine)))

# 3. Check dataset structure
cat("\nDataset structure:\n")
str(spine)

# 4. Summary statistics
cat("\nSummary statistics:\n")
summary(spine)

# 5. Check class distribution
cat("\nClass distribution:\n")
print(table(spine$class))

# 6. Check class percentages
cat("\nClass percentages:\n")
print(round(prop.table(table(spine$class)) * 100, 2))

# 7. Save dataset summary
numeric_summary <- data.frame(
  Feature = names(spine)[1:6],
  Minimum = sapply(spine[1:6], min),
  Maximum = sapply(spine[1:6], max),
  Mean = sapply(spine[1:6], mean),
  Median = sapply(spine[1:6], median)
)

write.csv(
  numeric_summary,
  "results/tables/dataset_summary.csv",
  row.names = FALSE
)

cat("\nDataset summary saved successfully!\n")



# ==========================================
# PART 3: EXPLORATORY DATA ANALYSIS
# ==========================================

# 1. Class distribution bar chart

class_plot <- ggplot(spine, aes(x = class, fill = class)) +
  geom_bar() +
  labs(
    title = "Distribution of Vertebral Column Classes",
    x = "Classification",
    y = "Number of Patients"
  ) +
  theme_minimal()

# Display graph
print(class_plot)

# Save graph
ggsave(
  "results/figures/class_distribution.png",
  class_plot,
  width = 7,
  height = 5
)
# 2. Boxplots comparing measurements by class

spine_long <- reshape(
  spine,
  varying = names(spine)[1:6],
  v.names = "Measurement",
  timevar = "Feature",
  times = names(spine)[1:6],
  direction = "long"
)

boxplot_plot <- ggplot(
  spine_long,
  aes(x = class, y = Measurement, fill = class)
) +
  geom_boxplot() +
  facet_wrap(~ Feature, scales = "free", ncol = 2) +
  labs(
    title = "Biomechanical Measurements by Vertebral Column Class",
    x = "Classification",
    y = "Measurement Value"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 0),
    legend.position = "none"
  )

# Display graph
print(boxplot_plot)

# Save graph
ggsave(
  "results/figures/feature_boxplots.png",
  boxplot_plot,
  width = 10,
  height = 9
)
# 3. Correlation analysis

correlation_matrix <- cor(spine[1:6])

print(round(correlation_matrix, 2))

# Convert correlation matrix into a format for ggplot
correlation_data <- as.data.frame(
  as.table(correlation_matrix)
)

correlation_plot <- ggplot(
  correlation_data,
  aes(x = Var1, y = Var2, fill = Freq)
) +
  geom_tile() +
  geom_text(aes(label = round(Freq, 2)), size = 3) +
  scale_fill_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 0
  ) +
  labs(
    title = "Correlation Between Biomechanical Features",
    x = "",
    y = "",
    fill = "Correlation"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )

# Display graph
print(correlation_plot)

# Save graph
ggsave(http://127.0.0.1:42377/graphics/d9d4dff6-7e8b-4daf-a1de-2ec729c52607.png
  "results/figures/correlation_heatmap.png",
  correlation_plot,
  width = 9,
  height = 7
)

# ==========================================
# PART 4: DATA PREPARATION
# ==========================================

# Set seed for reproducibility
set.seed(123)

# Separate observations by class
normal_data <- spine[spine$class == "Normal", ]
abnormal_data <- spine[spine$class == "Abnormal", ]

# Randomly select 70% from each class for training
normal_train_index <- sample(
  seq_len(nrow(normal_data)),
  size = floor(0.70 * nrow(normal_data))
)

abnormal_train_index <- sample(
  seq_len(nrow(abnormal_data)),
  size = floor(0.70 * nrow(abnormal_data))
)

# Combine training observations
train_data <- rbind(
  normal_data[normal_train_index, ],
  abnormal_data[abnormal_train_index, ]
)

# Remaining observations become testing data
test_data <- rbind(
  normal_data[-normal_train_index, ],
  abnormal_data[-abnormal_train_index, ]
)

# Shuffle both datasets
train_data <- train_data[
  sample(seq_len(nrow(train_data))), 
]

test_data <- test_data[
  sample(seq_len(nrow(test_data))), 
]

# Check dataset sizes
cat("Training dataset size:\n")
print(dim(train_data))

cat("\nTesting dataset size:\n")
print(dim(test_data))

# Check class distribution
cat("\nTraining class distribution:\n")
print(table(train_data$class))

cat("\nTesting class distribution:\n")
print(table(test_data$class))