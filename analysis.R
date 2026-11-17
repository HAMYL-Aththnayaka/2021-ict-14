
# ==========================================
# IT4133 BIOINFORMATICS PROJECT
# Classification of Vertebral Column Abnormalities
# Registration Number: 2021ICT14
# ==========================================


# ==========================================
# PART 1: SETUP AND DATA IMPORT
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


# 2. Create project output folders

dir.create("data", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

dir.create(
  "results/figures",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)


# 3. Download the dataset if it is not already available

data_url <- "https://raw.githubusercontent.com/MinorProphet/Vertebral-Column-Data-Set/master/column_2C.dat"

data_file <- "data/column_2C.dat"

if (!file.exists(data_file)) {
  download.file(
    data_url,
    data_file,
    mode = "wb"
  )
}

cat("Dataset file is available.\n")


# 4. Import the dataset

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

spine$class <- factor(
  ifelse(
    spine$class == "NO",
    "Normal",
    "Abnormal"
  ),
  levels = c("Normal", "Abnormal")
)


# 7. Inspect the imported dataset

cat("\nDataset dimensions:\n")
print(dim(spine))

cat("\nDataset structure:\n")
str(spine)

cat("\nFirst six records:\n")
print(head(spine))

cat("\nClass distribution:\n")
print(table(spine$class))


# ==========================================
# PART 2: DATA QUALITY CHECKS
# ==========================================

# 1. Check missing values

cat("\nMissing values:\n")
print(colSums(is.na(spine)))


# 2. Check duplicate records

cat("\nDuplicate records:\n")
print(sum(duplicated(spine)))


# 3. Display dataset summary statistics

cat("\nSummary statistics:\n")
print(summary(spine))


# 4. Check class distribution

cat("\nClass distribution:\n")
print(table(spine$class))


# 5. Calculate class percentages

cat("\nClass percentages:\n")

print(
  round(
    prop.table(table(spine$class)) * 100,
    2
  )
)


# 6. Create and save numerical summary table

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

cat("\nDataset summary saved successfully.\n")


# ==========================================
# PART 3: EXPLORATORY DATA ANALYSIS
# ==========================================

# 1. Class distribution bar chart

class_plot <- ggplot(
  spine,
  aes(x = class, fill = class)
) +
  geom_bar() +
  labs(
    title = "Distribution of Vertebral Column Classes",
    x = "Classification",
    y = "Number of Patients"
  ) +
  theme_minimal()

print(class_plot)

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
  facet_wrap(
    ~ Feature,
    scales = "free",
    ncol = 2
  ) +
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

print(boxplot_plot)

ggsave(
  "results/figures/feature_boxplots.png",
  boxplot_plot,
  width = 10,
  height = 9
)


# 3. Correlation analysis

correlation_matrix <- cor(spine[1:6])

cat("\nCorrelation matrix:\n")
print(round(correlation_matrix, 2))


# 4. Correlation heatmap

correlation_data <- as.data.frame(
  as.table(correlation_matrix)
)

correlation_plot <- ggplot(
  correlation_data,
  aes(x = Var1, y = Var2, fill = Freq)
) +
  geom_tile() +
  geom_text(
    aes(label = round(Freq, 2)),
    size = 3
  ) +
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

print(correlation_plot)

ggsave(
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


# 1. Separate observations by class

normal_data <- spine[
  spine$class == "Normal",
]

abnormal_data <- spine[
  spine$class == "Abnormal",
]


# 2. Select 70% of each class for training

normal_train_index <- sample(
  seq_len(nrow(normal_data)),
  size = floor(0.70 * nrow(normal_data))
)

abnormal_train_index <- sample(
  seq_len(nrow(abnormal_data)),
  size = floor(0.70 * nrow(abnormal_data))
)


# 3. Create training dataset

train_data <- rbind(
  normal_data[normal_train_index, ],
  abnormal_data[abnormal_train_index, ]
)


# 4. Create testing dataset

test_data <- rbind(
  normal_data[-normal_train_index, ],
  abnormal_data[-abnormal_train_index, ]
)


# 5. Shuffle both datasets

train_data <- train_data[
  sample(seq_len(nrow(train_data))),
]

test_data <- test_data[
  sample(seq_len(nrow(test_data))),
]


# 6. Display dataset sizes

cat("\nTraining dataset size:\n")
print(dim(train_data))

cat("\nTesting dataset size:\n")
print(dim(test_data))


# 7. Display class distributions

cat("\nTraining class distribution:\n")
print(table(train_data$class))

cat("\nTesting class distribution:\n")
print(table(test_data$class))


# ==========================================
# END OF CURRENT ANALYSIS
# ==========================================

cat("\nData preparation and EDA completed successfully!\n")


# ==========================================
# PART 5: LOGISTIC REGRESSION
# ==========================================

# Train logistic regression model

logistic_model <- glm(
  class ~ pelvic_incidence +
    pelvic_tilt +
    lumbar_lordosis_angle +
    sacral_slope +
    pelvic_radius +
    degree_spondylolisthesis,
  data = train_data,
  family = binomial
)

# Display model results

cat("\nLogistic Regression Model:\n")

print(summary(logistic_model))



# ==========================================
# PART 6: LOGISTIC REGRESSION PREDICTIONS
# ==========================================

# Predict probabilities for testing data

logistic_probabilities <- predict(
  logistic_model,
  newdata = test_data,
  type = "response"
)

# Convert probabilities into class predictions

logistic_predictions <- ifelse(
  logistic_probabilities >= 0.5,
  "Abnormal",
  "Normal"
)

logistic_predictions <- factor(
  logistic_predictions,
  levels = c("Normal", "Abnormal")
)

# Create confusion matrix

logistic_confusion_matrix <- table(
  Predicted = logistic_predictions,
  Actual = test_data$class
)

cat("\nLogistic Regression Confusion Matrix:\n")

print(logistic_confusion_matrix)


# ==========================================
# PART 7: LOGISTIC REGRESSION EVALUATION
# ==========================================

# Extract values from confusion matrix

TN <- logistic_confusion_matrix["Normal", "Normal"]
TP <- logistic_confusion_matrix["Abnormal", "Abnormal"]
FP <- logistic_confusion_matrix["Abnormal", "Normal"]
FN <- logistic_confusion_matrix["Normal", "Abnormal"]

# Calculate evaluation metrics

accuracy <- (TP + TN) / (TP + TN + FP + FN)

precision <- TP / (TP + FP)

sensitivity <- TP / (TP + FN)

specificity <- TN / (TN + FP)

f1_score <- 2 * (precision * sensitivity) /
  (precision + sensitivity)

# Display results as percentages

logistic_metrics <- data.frame(
  Metric = c(
    "Accuracy",
    "Precision",
    "Sensitivity",
    "Specificity",
    "F1 Score"
  ),
  Value = round(
    c(
      accuracy,
      precision,
      sensitivity,
      specificity,
      f1_score
    ) * 100,
    2
  )
)

cat("\nLogistic Regression Evaluation Metrics:\n")

print(logistic_metrics)

# Save evaluation results

write.csv(
  logistic_metrics,
  "results/tables/logistic_regression_metrics.csv",
  row.names = FALSE
)

cat("\nLogistic regression metrics saved successfully.\n")


# ==========================================
# PART 8: DECISION TREE CLASSIFICATION
# ==========================================

# Train decision tree model

tree_model <- rpart(
  class ~ .,
  data = train_data,
  method = "class"
)

# Display decision tree model

cat("\nDecision Tree Model:\n")

print(tree_model)

# Visualize decision tree

rpart.plot(
  tree_model,
  type = 3,
  extra = 104,
  fallen.leaves = TRUE,
  main = "Decision Tree for Vertebral Column Classification"
)


# ==========================================
# PART 9: DECISION TREE PREDICTIONS
# ==========================================

# Predict classes for testing data

tree_predictions <- predict(
  tree_model,
  newdata = test_data,
  type = "class"
)

# Create confusion matrix

tree_confusion_matrix <- table(
  Predicted = tree_predictions,
  Actual = test_data$class
)

cat("\nDecision Tree Confusion Matrix:\n")

print(tree_confusion_matrix)


# ==========================================
# PART 10: DECISION TREE EVALUATION
# ==========================================

# Extract values from confusion matrix

tree_TN <- tree_confusion_matrix["Normal", "Normal"]
tree_TP <- tree_confusion_matrix["Abnormal", "Abnormal"]
tree_FP <- tree_confusion_matrix["Abnormal", "Normal"]
tree_FN <- tree_confusion_matrix["Normal", "Abnormal"]

# Calculate evaluation metrics

tree_accuracy <- (tree_TP + tree_TN) /
  (tree_TP + tree_TN + tree_FP + tree_FN)

tree_precision <- tree_TP / (tree_TP + tree_FP)

tree_sensitivity <- tree_TP / (tree_TP + tree_FN)

tree_specificity <- tree_TN / (tree_TN + tree_FP)

tree_f1_score <- 2 * (tree_precision * tree_sensitivity) /
  (tree_precision + tree_sensitivity)

# Create evaluation results table

tree_metrics <- data.frame(
  Metric = c(
    "Accuracy",
    "Precision",
    "Sensitivity",
    "Specificity",
    "F1 Score"
  ),
  Value = round(
    c(
      tree_accuracy,
      tree_precision,
      tree_sensitivity,
      tree_specificity,
      tree_f1_score
    ) * 100,
    2
  )
)

# Display results

cat("\nDecision Tree Evaluation Metrics:\n")

print(tree_metrics)

# Save results

write.csv(
  tree_metrics,
  "results/tables/decision_tree_metrics.csv",
  row.names = FALSE
)

cat("\nDecision Tree metrics saved successfully.\n")


# ==========================================
# PART 11: MODEL COMPARISON
# ==========================================

# Create comparison table

model_comparison <- data.frame(
  Metric = logistic_metrics$Metric,
  Logistic_Regression = logistic_metrics$Value,
  Decision_Tree = tree_metrics$Value
)

cat("\nComparison of Classification Models:\n")

print(model_comparison)

# Save comparison table

write.csv(
  model_comparison,
  "results/tables/model_comparison.csv",
  row.names = FALSE
)


# Prepare data for comparison chart

comparison_long <- data.frame(
  Metric = rep(model_comparison$Metric, 2),
  Model = c(
    rep("Logistic Regression", 5),
    rep("Decision Tree", 5)
  ),
  Value = c(
    model_comparison$Logistic_Regression,
    model_comparison$Decision_Tree
  )
)

# Create comparison chart

comparison_plot <- ggplot(
  comparison_long,
  aes(x = Metric, y = Value, fill = Model)
) +
  geom_col(position = "dodge") +
  labs(
    title = "Performance Comparison of Classification Models",
    x = "Evaluation Metric",
    y = "Performance (%)",
    fill = "Classification Model"
  ) +
  ylim(0, 100) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

print(comparison_plot)

# Save comparison chart

ggsave(
  "results/figures/model_comparison.png",
  comparison_plot,
  width = 10,
  height = 6
)

cat("\nModel comparison completed successfully.\n")



# ==========================================
# PART 12: MULTICOLLINEARITY INVESTIGATION
# ==========================================

# Check the relationship between pelvic measurements

measurement_difference <- spine$pelvic_incidence -
  (spine$pelvic_tilt + spine$sacral_slope)

cat("\nPelvic measurement relationship:\n")

cat(
  "Maximum absolute difference:",
  max(abs(measurement_difference)),
  "\n"
)

cat(
  "Mean absolute difference:",
  mean(abs(measurement_difference)),
  "\n"
)


