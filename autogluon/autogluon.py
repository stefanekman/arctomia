#!/usr/bin/env python3


from autogluon.tabular import TabularDataset, TabularPredictor
from tabulate import tabulate

train_data = TabularDataset("/Users/stefanekman/R_workdir/train4.csv")
test_data = TabularDataset("/Users/stefanekman/R_workdir/newdata4.csv")

predictor = TabularPredictor(label="label", eval_metric='log_loss').fit(train_data, presets='best_quality', ag_args_ensemble=dict(fold_fitting_strategy='sequential_local'))
leaderboard = predictor.leaderboard(train_data)
trainacc = predictor.evaluate(train_data)
imp = predictor.feature_importance(train_data)
probs = predictor.predict_proba(test_data)

with open('output.txt', 'w') as f:
	f.write(tabulate(leaderboard, headers='keys'))
	f.write('\n\n\n')
	f.write(str(trainacc))
	f.write('\n\n\n')
	f.write(tabulate(imp, headers='keys'))
	f.write('\n\n\n')
	f.write(tabulate(probs, headers='keys'))


# =================== System Info ===================
# AutoGluon Version:  1.1.0
# Python Version:     3.11.9
# Operating System:   Darwin
# Platform Machine:   x86_64
# Platform Version:   Darwin Kernel Version 21.6.0: Mon Feb 19 20:24:34 PST 2024; root:xnu-8020.240.18.707.4~1/RELEASE_X86_64
# CPU Count:          8
# Memory Avail:       5.11 GB / 16.00 GB (32.0%)
# Disk Space Avail:   387.84 GB / 931.64 GB (41.6%)

# TabularPredictor saved. To load, use: predictor = TabularPredictor.load("AutogluonModels/ag-20240808_132703")
