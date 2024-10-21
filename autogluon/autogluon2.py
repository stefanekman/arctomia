#!/usr/bin/env python3

from autogluon.tabular import TabularDataset, TabularPredictor
from tabulate import tabulate
import shap
import pandas as pd
import numpy as np

train_data = TabularDataset("/Users/stefanekman/Python_workdir/autogluon/train4.csv")
test_data = TabularDataset("/Users/stefanekman/Python_workdir/autogluon/newdata4.csv")

predictor = TabularPredictor(label="label", eval_metric='log_loss').fit(train_data, presets='best_quality', ag_args_ensemble=dict(fold_fitting_strategy='sequential_local'))
leaderboard = predictor.leaderboard(train_data)
trainacc = predictor.evaluate(train_data)
imp = predictor.feature_importance(train_data)
probs = predictor.predict_proba(test_data)

def format_number(x):
	if abs(x) < 1e-5:
		return '0.00000'
	else:
		return f'{x:.5f}'

for col in probs.select_dtypes(include=[np.number]).columns:
	probs[col] = probs[col].apply(format_number)

with open('AG_output.txt', 'w') as f:
	f.write('Leaderboard:\n\n')
	f.write(tabulate(leaderboard, headers='keys'))
	f.write('\n\n\n')
	f.write('Training result:\n\n')
	for key, value in trainacc.items():
    		f.write(f"{key}: {value}\n")
	f.write('\n\n')
	f.write('Feature importance:\n\n')
	f.write(tabulate(imp, headers='keys'))
	f.write('\n\n\n')
	f.write('Test data predictions with class membership probabilities:\n\n')
	f.write(tabulate(probs, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\n')

# Prepare the data for SHAP analysis
X = train_data.drop(columns=['label'])
y = train_data['label']

# Store the column names
feature_names = X.columns.tolist()

# Create a function that the SHAP explainer can use
def model_predict(X):
    if isinstance(X, np.ndarray):
        X = pd.DataFrame(X, columns=feature_names)
    elif isinstance(X, pd.DataFrame):
        X = X.copy()
    else:
        raise TypeError("Input must be a numpy array or pandas DataFrame")
    return predictor.predict_proba(X)

# Create a SHAP explainer using KernelExplainer with the entire dataset
explainer = shap.KernelExplainer(model_predict, X)

# Calculate SHAP values for the entire dataset
# Note: This might take a long time for large datasets
shap_values = explainer.shap_values(X)

# Get class names
class_names = predictor.class_labels

# Get the number of features and classes from the shape of shap_values
num_features = shap_values.shape[1]
num_classes = shap_values.shape[2]

# Calculate mean absolute SHAP values for each feature and class
mean_shap_values = []
for i in range(num_classes):
    class_shap_values = shap_values[i][:, :num_features]
    mean_shap = np.abs(class_shap_values).mean(axis=0)
    mean_shap_values.append(mean_shap)

# Create a DataFrame with classes as rows and features as columns
combined_mean_shap = pd.DataFrame(mean_shap_values, columns=feature_names, index=class_names)

# Add SHAP values to the output file
with open('AG_output.txt', 'a') as f:
    f.write('Combined mean absolute SHAP values for each class:\n\n')
    f.write(tabulate(combined_mean_shap, headers='keys', showindex=True, floatfmt='.5f'))
