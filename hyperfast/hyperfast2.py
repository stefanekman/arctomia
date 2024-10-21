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

# Generate a target network and make predictions
model.fit(X_train, y_train.values.ravel())

# First training set...
predtrain = model.predict(X_train)
acctrain = accuracy_score(y_train, predtrain)
acctrain

# Then test set...
predtest = model.predict(X_test)
predtestprob = model.predict_proba(X_test)
predtestprob_df = pd.DataFrame(predtestprob, columns=class_names)
predtestprob_df['class'] = predtest

# Save training accuracy and class membership probabilities
with open('HF_output.txt', 'w') as f:
	f.write('Training accuracy:')
	f.write(str(acctrain))
	f.write('\n\n\n')
	f.write('Test data predictions with class membership probabilities:\n\n')
	f.write(tabulate(predtestprob_df, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\n')

# Create a SHAP explainer using the training data
explainer = shap.KernelExplainer(model.predict_proba, X_train)

# Calculate SHAP values for the training set
shap_values = explainer.shap_values(X_train)
feature_importance = np.array([np.abs(sv) for sv in shap_values]).mean(axis=0)

# Create dataframe and add feature name column
feature_importance_df = pd.DataFrame(feature_importance, columns=[f'Class_{i}' for i in range(1, len(class_names) + 1)])
feature_importance_df['Feature'] = feature_names

# Reorder columns to have 'Feature' as the first column
cols = feature_importance_df.columns.tolist()
cols = cols[-1:] + cols[:-1]
feature_importance_df = feature_importance_df[cols]

# Transpose dataframe
transposed_df = feature_importance_df.set_index('Feature').T

# Use the extracted class names for the index
transposed_df.index = class_names

# Append SHAP values to the output file
with open('HF_output.txt', 'a') as f:
    f.write('Combined mean absolute SHAP values for each class:\n\n')
    f.write(tabulate(transposed_df, headers='keys', showindex=True, floatfmt='.5f'))
    f.write('\n\n')
