import torch
import numpy as np
from hyperfast import HyperFastClassifier
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import StandardScaler
import pandas as pd

# Read data (standardized and centered around zero)
train = pd.read_csv('/Users/stefan//Documents/trainsc.csv')
test= pd.read_csv('/Users/stefan//Documents/testsc.csv')

# Partition data scikit-learn-style
X_train = train[['L','W','Ap','Sept']]
X_test = test[['L','W','Ap','Sept']]
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
acctrain = accuracy_score(y_train, predtrain)
acctrain

# Then test set...
predtest = model.predict(X_test)
predtest
predtestprob = model.predict_proba(X_test)
predtestprob



