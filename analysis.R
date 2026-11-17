
# IT4133 Bioinformatics Project
# Classification of Vertebral Column Abnormalities


# 1. Load the packages needed for the analysis

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


# 2. Create folders to store the dataset and analysis results

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


# 3. Download the dataset from the UCI repository

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


# 4. Import the dataset and give the columns meaningful names

spine <- read.table(
  data_file,
  header = FALSE,
  stringsAsFactors = FALSE
)

colnames(spine) <- c(
  "pelvic_incidence",
  "pelvic_tilt",
  "lumbar_lordosis_angle",
  "sacral_slope",
  "pelvic_radius",
  "degree_spondylolisthesis",
  "class"
)

# Convert the original labels into readable class names

spine$class <- trimws(spine$class)

spine$class <- factor(
  spine$class,
  levels = c("NO", "AB"),
  labels = c("Normal", "Abnormal")
)

if (any(is.na(spine$class))) {
  stop("Some class labels could not be recognised.")
}

cat("\nFirst six observations:\n")
print(head(spine))

cat("\nDataset dimensions:\n")
print(dim(spine))

cat("\nDataset structure:\n")
str(spine)


# 5. Check the dataset before starting the analysis

cat("\nMissing values in each column:\n")
print(colSums(is.na(spine)))

cat("\nNumber of duplicate records:\n")
print(sum(duplicated(spine)))

cat("\nSummary of the dataset:\n")
print(summary(spine))

cat("\nOriginal class distribution:\n")
print(table(spine$class))

cat("\nClass percentages:\n")
print(prop.table(table(spine$class)) * 100)

capture.output(
  summary(spine),
  file = "results/tables/dataset_summary.txt"
)


# 6. Clean the data and prepare the numerical features

spine_clean <- na.omit(spine)

spine_clean <- spine_clean[
  !duplicated(spine_clean),
]

spine_clean$class <- droplevels(spine_clean$class)

features <- c(
  "pelvic_incidence",
  "pelvic_tilt",
  "lumbar_lordosis_angle",
  "sacral_slope",
  "pelvic_radius",
  "degree_spondylolisthesis"
)

if (
  nrow(spine_clean) == 0 ||
  nlevels(spine_clean$class) != 2
) {
  stop("The cleaned dataset is not suitable for classification.")
}

cat("\nCleaned dataset dimensions:\n")
print(dim(spine_clean))

cat("\nClass distribution after cleaning:\n")
print(table(spine_clean$class))

write.csv(
  spine_clean,
  "results/tables/cleaned_dataset.csv",
  row.names = FALSE
)


# 7. Explore the distribution of normal and abnormal cases

class_counts <- as.data.frame(
  table(spine_clean$class)
)

colnames(class_counts) <- c("Class", "Frequency")

p1 <- ggplot(
  class_counts,
  aes(x = Class, y = Frequency, fill = Class)
) +
  geom_col() +
  labs(
    title = "Distribution of Vertebral Column Classes",
    x = "Classification",
    y = "Number of Patients"
  ) +
  theme_minimal()

ggsave(
  "results/figures/class_distribution.png",
  p1,
  width = 7,
  height = 5
)


# Look at how each measurement is distributed across the dataset

for (feature in features) {
  
  p <- ggplot(
    spine_clean,
    aes(
      x = .data[[feature]],
      fill = class
    )
  ) +
    geom_histogram(
      bins = 25,
      alpha = 0.7,
      position = "identity"
    ) +
    labs(
      title = paste("Distribution of", feature),
      x = feature,
      y = "Frequency"
    ) +
    theme_minimal()
  
  ggsave(
    paste0(
      "results/figures/",
      feature,
      "_distribution.png"
    ),
    p,
    width = 7,
    height = 5
  )
}


# Compare the measurements between the two classes using boxplots

for (feature in features) {
  
  p <- ggplot(
    spine_clean,
    aes(
      x = class,
      y = .data[[feature]],
      fill = class
    )
  ) +
    geom_boxplot() +
    labs(
      title = paste(feature, "by Classification"),
      x = "Classification",
      y = feature
    ) +
    theme_minimal()
  
  ggsave(
    paste0(
      "results/figures/",
      feature,
      "_boxplot.png"
    ),
    p,
    width = 7,
    height = 5
  )
}


# 8. Check the relationships between numerical measurements

correlation_matrix <- cor(
  spine_clean[, features]
)

print(correlation_matrix)

write.csv(
  correlation_matrix,
  "results/tables/correlation_matrix.csv"
)

correlation_data <- as.data.frame(
  as.table(correlation_matrix)
)

p_correlation <- ggplot(
  correlation_data,
  aes(
    x = Var1,
    y = Var2,
    fill = Freq
  )
) +
  geom_tile() +
  geom_text(
    aes(label = round(Freq, 2))
  ) +
  scale_fill_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 0
  ) +
  labs(
    title = "Correlation Between Vertebral Measurements",
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

ggsave(
  "results/figures/correlation_matrix.png",
  p_correlation,
  width = 9,
  height = 7
)


# 9. Test whether the measurements differ between the two classes

statistical_results <- data.frame()

for (feature in features) {
  
  test_result <- wilcox.test(
    spine_clean[[feature]] ~ spine_clean$class,
    exact = FALSE
  )
  
  statistical_results <- rbind(
    statistical_results,
    data.frame(
      Feature = feature,
      P_Value = test_result$p.value
    )
  )
}

# Adjust the p-values because six separate tests were performed

statistical_results$Adjusted_P_Value <- p.adjust(
  statistical_results$P_Value,
  method = "bonferroni"
)

statistical_results$Significant <- ifelse(
  statistical_results$Adjusted_P_Value < 0.05,
  "Yes",
  "No"
)

cat("\nStatistical test results:\n")
print(statistical_results)

write.csv(
  statistical_results,
  "results/tables/statistical_tests.csv",
  row.names = FALSE
)


# 10. Divide the data into training and testing groups

set.seed(123)

# Keep the original class proportions in both groups

normal_data <- spine_clean[
  spine_clean$class == "Normal",
]

abnormal_data <- spine_clean[
  spine_clean$class == "Abnormal",
]

normal_train_index <- sample(
  seq_len(nrow(normal_data)),
  size = floor(0.7 * nrow(normal_data))
)

abnormal_train_index <- sample(
  seq_len(nrow(abnormal_data)),
  size = floor(0.7 * nrow(abnormal_data))
)

train_data <- rbind(
  normal_data[normal_train_index, ],
  abnormal_data[abnormal_train_index, ]
)

test_data <- rbind(
  normal_data[-normal_train_index, ],
  abnormal_data[-abnormal_train_index, ]
)

# Shuffle the observations in both groups

train_data <- train_data[
  sample(nrow(train_data)),
]

test_data <- test_data[
  sample(nrow(test_data)),
]

cat("\nTraining class distribution:\n")
print(table(train_data$class))

cat("\nTesting class distribution:\n")
print(table(test_data$class))

cat("\nTraining observations:", nrow(train_data))
cat("\nTesting observations:", nrow(test_data), "\n")


# 11. Build the logistic regression model

logistic_model <- glm(
  class ~ .,
  data = train_data,
  family = binomial(link = "logit")
)

cat("\nLogistic regression summary:\n")
print(summary(logistic_model))

# Predict the probability of each test observation being abnormal

logistic_probabilities <- predict(
  logistic_model,
  newdata = test_data,
  type = "response"
)

# Use 0.5 as the classification threshold

logistic_predictions <- factor(
  ifelse(
    logistic_probabilities >= 0.5,
    "Abnormal",
    "Normal"
  ),
  levels = c("Normal", "Abnormal")
)


# 12. Build the decision tree model

decision_tree <- rpart(
  class ~ .,
  data = train_data,
  method = "class",
  control = rpart.control(
    cp = 0.01,
    minsplit = 10
  )
)

cat("\nDecision tree summary:\n")
print(decision_tree)

# Save a visual representation of the decision tree

png(
  "results/figures/decision_tree.png",
  width = 1200,
  height = 900
)

rpart.plot(
  decision_tree,
  type = 4,
  extra = 104,
  fallen.leaves = TRUE,
  main = "Vertebral Column Classification Tree"
)

dev.off()

# Predict the classes of the test observations

tree_predictions <- predict(
  decision_tree,
  newdata = test_data,
  type = "class"
)


# 13. Evaluate both classification models

evaluate_model <- function(actual, predicted) {
  
  actual <- factor(
    actual,
    levels = c("Normal", "Abnormal")
  )
  
  predicted <- factor(
    predicted,
    levels = c("Normal", "Abnormal")
  )
  
  cm <- table(
    Actual = actual,
    Predicted = predicted
  )
  
  TN <- cm["Normal", "Normal"]
  FP <- cm["Normal", "Abnormal"]
  FN <- cm["Abnormal", "Normal"]
  TP <- cm["Abnormal", "Abnormal"]
  
  accuracy <- (TP + TN) / sum(cm)
  
  precision <- ifelse(
    TP + FP == 0,
    0,
    TP / (TP + FP)
  )
  
  recall <- ifelse(
    TP + FN == 0,
    0,
    TP / (TP + FN)
  )
  
  specificity <- ifelse(
    TN + FP == 0,
    0,
    TN / (TN + FP)
  )
  
  f1_score <- ifelse(
    precision + recall == 0,
    0,
    2 * precision * recall /
      (precision + recall)
  )
  
  list(
    confusion_matrix = cm,
    metrics = data.frame(
      Accuracy = accuracy,
      Precision = precision,
      Recall = recall,
      Specificity = specificity,
      F1_Score = f1_score
    )
  )
}


# Check how well logistic regression classified the test data

logistic_results <- evaluate_model(
  test_data$class,
  logistic_predictions
)

cat("\nLogistic Regression Confusion Matrix:\n")
print(logistic_results$confusion_matrix)

cat("\nLogistic Regression Metrics:\n")
print(logistic_results$metrics)


# Check how well the decision tree classified the test data

tree_results <- evaluate_model(
  test_data$class,
  tree_predictions
)

cat("\nDecision Tree Confusion Matrix:\n")
print(tree_results$confusion_matrix)

cat("\nDecision Tree Metrics:\n")
print(tree_results$metrics)


# Save the confusion matrices for the report

write.csv(
  as.data.frame.matrix(
    logistic_results$confusion_matrix
  ),
  "results/tables/logistic_confusion_matrix.csv"
)

write.csv(
  as.data.frame.matrix(
    tree_results$confusion_matrix
  ),
  "results/tables/tree_confusion_matrix.csv"
)


# 14. Compare the performance of the two models

model_comparison <- data.frame(
  Model = c(
    "Logistic Regression",
    "Decision Tree"
  ),
  Accuracy = c(
    logistic_results$metrics$Accuracy,
    tree_results$metrics$Accuracy
  ),
  Precision = c(
    logistic_results$metrics$Precision,
    tree_results$metrics$Precision
  ),
  Recall = c(
    logistic_results$metrics$Recall,
    tree_results$metrics$Recall
  ),
  Specificity = c(
    logistic_results$metrics$Specificity,
    tree_results$metrics$Specificity
  ),
  F1_Score = c(
    logistic_results$metrics$F1_Score,
    tree_results$metrics$F1_Score
  )
)

cat("\nModel comparison:\n")
print(model_comparison)

write.csv(
  model_comparison,
  "results/tables/model_comparison.csv",
  row.names = FALSE
)


# Create a graph to compare the evaluation metrics

comparison_long <- data.frame(
  Model = rep(
    model_comparison$Model,
    each = 4
  ),
  Metric = rep(
    c(
      "Accuracy",
      "Precision",
      "Recall",
      "F1_Score"
    ),
    times = 2
  ),
  Score = c(
    model_comparison$Accuracy,
    model_comparison$Precision,
    model_comparison$Recall,
    model_comparison$F1_Score
  )
)

p_comparison <- ggplot(
  comparison_long,
  aes(
    x = Metric,
    y = Score,
    fill = Model
  )
) +
  geom_col(position = "dodge") +
  labs(
    title = "Performance Comparison of Classification Models",
    x = "Evaluation Metric",
    y = "Score"
  ) +
  theme_minimal()

ggsave(
  "results/figures/model_comparison.png",
  p_comparison,
  width = 9,
  height = 6
)


# 15. Find out which measurements were important in the decision tree

importance_values <- decision_tree$variable.importance

if (!is.null(importance_values) && length(importance_values) > 0) {
  
  feature_importance <- data.frame(
    Feature = names(importance_values),
    Importance = as.numeric(importance_values)
  )
  
  feature_importance <- feature_importance[
    order(
      feature_importance$Importance,
      decreasing = TRUE
    ),
  ]
  
  cat("\nFeature importance:\n")
  print(feature_importance)
  
  write.csv(
    feature_importance,
    "results/tables/feature_importance.csv",
    row.names = FALSE
  )
  
  p_importance <- ggplot(
    feature_importance,
    aes(
      x = reorder(Feature, Importance),
      y = Importance
    )
  ) +
    geom_col() +
    coord_flip() +
    labs(
      title = "Decision Tree Feature Importance",
      x = "Measurement",
      y = "Importance"
    ) +
    theme_minimal()
  
  ggsave(
    "results/figures/feature_importance.png",
    p_importance,
    width = 8,
    height = 5
  )
  
} else {
  
  cat("\nNo feature importance values were available.\n")
}


# 16. Save the models and other important results

capture.output(
  summary(logistic_model),
  file = "results/logistic_regression_summary.txt"
)

capture.output(
  print(decision_tree),
  file = "results/decision_tree_summary.txt"
)

saveRDS(
  logistic_model,
  "results/logistic_model.rds"
)

saveRDS(
  decision_tree,
  "results/decision_tree_model.rds"
)

capture.output(
  sessionInfo(),
  file = "results/session_info.txt"
)


# Display a summary when the analysis is finished


cat("BIOINFORMATICS PROJECT COMPLETED\n")


cat("\nCleaned observations:", nrow(spine_clean))
cat("\nTraining observations:", nrow(train_data))
cat("\nTesting observations:", nrow(test_data))

cat("\n\nFinal model comparison:\n")
print(model_comparison)

cat("\nAll results have been saved in the results folder.\n")

