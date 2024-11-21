import torch
import numpy as np
from hyperfast import HyperFastClassifier
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import StandardScaler
import pandas as pd
from tabulate import tabulate
import shap


# Read data (already preprocessed))
train = pd.read_csv('/Users/stefan//Documents/trainsc.csv')
test = pd.read_csv('/Users/stefan//Documents/testsc.csv')

# Extract feature names from the header (all columns except 'label')
feature_names = train.columns[:-1].tolist()

# Extract class names from the 'label' column
class_names = train['label'].unique().tolist()
class_names = sorted(class_names)

# Partition data scikit-learn-style
X_train = train[feature_names]
X_test = test[feature_names]
y_train = train[['label']]
y_test = test[['label']]

# Set the device
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

# Initialize HyperFast
# model = HyperFastClassifier(device=device)
# "If you are dealing with an imbalanced dataset, consider setting stratify_sampling=True with n_ensemble > 1"
model = HyperFastClassifier(device=device, n_ensemble=4, stratify_sampling=True)

# Generate a target network and make predictions
model.fit(X_train, y_train.values.ravel())

# First training set...
predtrain = model.predict(X_train)
trainprobs = model.predict_proba(X_train)
trainprobs_df = pd.DataFrame(trainprobs, columns=class_names)
acctrain = accuracy_score(y_train, predtrain)

# Function for calculating log2 based entropy
def calculate_entropy(probabilities):
    return -np.sum(probabilities * np.log2(probabilities + 1e-15), axis=1)

# Calculate entropies
sample_entropies = calculate_entropy(trainprobs_df)
average_entropy = np.mean(sample_entropies)

# Then test set...
predtest = model.predict(X_test)
predtestprob = model.predict_proba(X_test)
predtestprob_df = pd.DataFrame(predtestprob, columns=class_names)
predtestprob_df['class'] = predtest

# Create SHAP explainer using the training data
explainer = shap.KernelExplainer(model.predict_proba, X_train)

# Calculate SHAP values for the training set
shap_values = explainer.shap_values(X_train)
feature_importance = np.array([np.abs(sv) for sv in shap_values]).mean(axis=0)

# Create data frame and add feature name column
feature_importance_df = pd.DataFrame(feature_importance, columns=[f'Class_{i}' for i in range(1, len(class_names) + 1)])
feature_importance_df['Feature'] = feature_names

# Reorder columns to have 'Feature' as the first column
cols = feature_importance_df.columns.tolist()
cols = cols[-1:] + cols[:-1]
feature_importance_df = feature_importance_df[cols]

# Transpose data frame
transposed_df = feature_importance_df.set_index('Feature').T

# Use extracted class names for the index
transposed_df.index = class_names

# Add class names to class membership matrix once entropy has been calculated
trainprobs_df['class'] = predtrain

# Write output to file
with open('HF_output.txt', 'w') as f:
	f.write(f'Training accuracy: {acctrain:.5f}\n')
	f.write(f'Average entropy across training data: {average_entropy:.5f}\n')
	f.write('\n\nTraining data predictions with class membership probabilities:\n\n')
	f.write(tabulate(trainprobs_df, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\nTest data predictions with class membership probabilities:\n\n')
	f.write(tabulate(predtestprob_df, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\nCombined mean absolute SHAP values for each class:\n\n')
	f.write(tabulate(transposed_df, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n')
