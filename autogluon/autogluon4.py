# +-----------------------------------------------------------------------+
# | This script performs Autogluon machine learning on tabular data sets. |
# | It also calculates the mean Shannon entropy across specimens.         |
# | of the probability distribution across classes, as well as mean.      |
# | SHAP values across classes.                                           |
# |                                                                       |
# | Stefan Ekman, 3 Dec 2024                                              |
# +-----------------------------------------------------------------------+


# Read packages, Autogluon here in version 1.2.0
from autogluon.tabular import TabularDataset, TabularPredictor
from tabulate import tabulate
import pandas as pd
import numpy as np
import shap
import os

# Function for calculating Shannon entropy
def calculate_entropy(probabilities):
	return -np.sum(probabilities * np.log2(probabilities + 1e-15), axis=1)

# Function for formatting numbers
def format_number(x):
	if abs(x) < 1e-5:
		return '0.00000'
	else:
		return f'{x:.5f}'

# Set working directory
os.chdir('/Users/stefan/Python_workdir')

# Read complete data
data = pd.read_csv('arctomia_morph.txt', sep='\t')

# Divide data into train (seq=1) and test (seq=0) data
# Preprocessing of numerical data is NOT neeeded for Autogluon; this is handled internally
train_data = data[data['seq'] == 1]
test_data = data[data['seq'] == 0]

# Remove seq flag from both datasets
train_data = train_data.drop('seq', axis=1)
test_data = test_data.drop('seq', axis=1)

# Remove 'label' column from test_data
test_data = test_data.drop('label', axis=1)

# Remove ID column from train_data and test_data and store separately
train_data_ids = train_data['ID']
test_data_ids = test_data['ID']
train_data = train_data.drop('ID', axis=1)
test_data = test_data.drop('ID', axis=1)

# Perform Autogluon TabularPredictor fit; note that class labels are in column named 'label' in train_data
predictor = TabularPredictor(label="label", eval_metric='log_loss').fit(train_data, presets='best_quality', ag_args_ensemble=dict(fold_fitting_strategy='sequential_local'))
leaderboard = predictor.leaderboard(train_data)
trainacc = predictor.evaluate(train_data)
imp = predictor.feature_importance(train_data)

# Predict class membership for training data
train_probs = predictor.predict_proba(train_data)
train_probs.index = train_data_ids

# Calculate entropies
sample_entropies = calculate_entropy(train_probs)
average_entropy = np.mean(sample_entropies)

# Predict class membership for test data
test_probs = predictor.predict_proba(test_data)
test_probs.index = test_data_ids

# Format output numbers properly
for col in train_probs.select_dtypes(include=[np.number]).columns:
	train_probs[col] = train_probs[col].apply(format_number)

for col in test_probs.select_dtypes(include=[np.number]).columns:
	test_probs[col] = test_probs[col].apply(format_number)

# Drop label column from train_data (needed for SHAP calculations)
X = train_data.drop(columns=['label'])

# Store column names
feature_names = X.columns.tolist()

# Store class names
class_names = predictor.class_labels

# Format input data and call predict_proba
model_predict = lambda X: predictor.predict_proba(pd.DataFrame(X, columns=feature_names))

# Create a SHAP explainer using KernelExplainer for the training data
explainer = shap.KernelExplainer(model_predict, X)

# Calculate SHAP values
shap_values = explainer.shap_values(X)

# Infer dimensions from shap_values
num_features = shap_values[0].shape[0]
num_classes = shap_values[0].shape[1]

# Calculate mean absolute SHAP values for each feature and class
mean_shap_values = np.abs(np.array(shap_values)).mean(axis=0)

# Create DataFrame and transpose it
combined_mean_shap = pd.DataFrame(mean_shap_values, index=feature_names, columns=class_names)
combined_mean_shap = combined_mean_shap.T

# Write output to file
with open('AG_output.txt', 'w') as f:
	f.write('Leaderboard:\n\n')
	f.write(tabulate(leaderboard, headers='keys'))
	f.write('\n\n\nTraining result:\n\n')
	for key, value in trainacc.items():
    		f.write(f"{key}: {value}\n")
	f.write(f'average entropy across training data: {average_entropy:.5f}\n')
	f.write('\n\nTraining data predictions with class membership probabilities:\n\n')
	f.write(tabulate(train_probs, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\nFeature importance:\n\n')
	f.write(tabulate(imp, headers='keys'))
	f.write('\n\n\nTest data predictions with class membership probabilities:\n\n')
	f.write(tabulate(test_probs, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\nCombined mean absolute SHAP values for each class:\n\n')
	f.write(tabulate(combined_mean_shap, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n')
