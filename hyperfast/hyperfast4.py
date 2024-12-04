# +-----------------------------------------------------------------------+
# | This script performs HyperFast machine learning on tabular data sets. |
# | It also calculates the mean Shannon entropy across specimens.         |
# | of the probability distribution across classes, as well as mean       |
# | SHAP values across classes.                                           |
# |                                                                       |
# | Stefan Ekman, 3 Dec 2024                                              |
# +-----------------------------------------------------------------------+


# Read packages, HyperFast here in ver. 1.0.2
import torch
from hyperfast import HyperFastClassifier
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import StandardScaler
import numpy as np
import pandas as pd
from tabulate import tabulate
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

# Scale numerical data
# Preprocessing of numerical data is required before HyperFast analysis
scaler = StandardScaler()
numerical_data = ['L', 'W', 'Ap', 'Sept']
data[numerical_data] = scaler.fit_transform(data[numerical_data])

# Divide data into train and test sets
train_data = data[data['seq'] == 1]
test_data = data[data['seq'] == 0]

# Extract class names from the 'label' column
class_names = train_data['label'].unique().tolist()
class_names = sorted(class_names)

# Store line IDs
train_data_ids = train_data['ID']
test_data_ids = test_data['ID']

# Partition data scikit-learn-style
X_train = train_data[numerical_data]
y_train = train_data[['label']]
X_test = test_data[numerical_data]

# Set the device
device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

# Initialize HyperFast
# model = HyperFastClassifier(device=device)
# "If you are dealing with an imbalanced dataset, consider setting stratify_sampling=True with n_ensemble > 1"
model = HyperFastClassifier(device=device, n_ensemble=4, stratify_sampling=True)

# Generate a target network and make predictions
model.fit(X_train, y_train.values.ravel())

# First training set...
trainprobs = model.predict_proba(X_train)
trainprobs_df = pd.DataFrame(trainprobs, columns=class_names)
trainprobs_df.index = train_data_ids
predtrain = model.predict(X_train)
acctrain = accuracy_score(y_train, predtrain)

# Calculate entropies in training data
sample_entropies = calculate_entropy(trainprobs_df)
average_entropy = np.mean(sample_entropies)

# Then test set...
testprobs = model.predict_proba(X_test)
testprobs_df = pd.DataFrame(testprobs, columns=class_names)
testprobs_df.index = test_data_ids

# Format output numbers properly
for col in trainprobs_df.select_dtypes(include=[np.number]).columns:
	trainprobs_df[col] = trainprobs_df[col].apply(format_number)

for col in testprobs_df.select_dtypes(include=[np.number]).columns:
	testprobs_df[col] = testprobs_df[col].apply(format_number)

# Add column with classifications to training data
# Predictions already available above from predtrain
trainprobs_df['class'] = predtrain

# Add column with classifications to test data
predtest = model.predict(X_test)
testprobs_df['class'] = predtest

# Create SHAP explainer using KernelExplainer for the training data
explainer = shap.KernelExplainer(model.predict_proba, X_train)

# Calculate SHAP values
shap_values = explainer.shap_values(X_train)

# Infer dimensions from shap_values
num_features = shap_values[0].shape[0]
num_classes = shap_values[0].shape[1]

# Calculate mean absolute SHAP values for each feature and class
mean_shap_values = np.abs(np.array(shap_values)).mean(axis=0)

# Create DataFrame and transpose it
combined_mean_shap = pd.DataFrame(mean_shap_values, index=numerical_data, columns=class_names)
combined_mean_shap = combined_mean_shap.T

# Write output to file
with open('HF_output.txt', 'w') as f:
	f.write(f'Training accuracy: {acctrain:.5f}\n')
	f.write(f'Average entropy across training data: {average_entropy:.5f}\n')
	f.write('\n\nTraining data predictions with class membership probabilities:\n\n')
	f.write(tabulate(trainprobs_df, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\nTest data predictions with class membership probabilities:\n\n')
	f.write(tabulate(testprobs_df, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n\nCombined mean absolute SHAP values for each class:\n\n')
	f.write(tabulate(combined_mean_shap, headers='keys', showindex=True, floatfmt='.5f'))
	f.write('\n\n')
