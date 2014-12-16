addpath(genpath('..'))

% Define parameters to optimize
parameters = {
    struct('name', 'numhid', 'type', 'integer', 'min', 10, 'max', 100);
    struct('name', 'epsilon', 'type', 'float', 'min', 0.001, 'max',  0.01);
    struct('name', 'momentum', 'type', 'float', 'min', 0.5, 'max', 0.99)
    struct('name', 'pretrain_maxepoch', 'type', 'integer', 'min', 1, 'max', 100);
    struct('name', 'maxepoch', 'type', 'integer', 'min', 10, 'max', 100);
    struct('name', 'weightcost', 'type', 'float', 'min', 0.0, 'max', 1.0);
    struct('name', 'pretrain_weightcost', 'type', 'float', 'min', 0.0, 'max', 1.0);
};

outcome.name = '# correct test examples';

accessToken = ''; % Either replace this with your access token or put it in your ~/.whetlab file.
name = 'CSC321 A4 - Automated Student';
description = 'Automate the completion of CSC 321 assignment 4 - Tuning neural net hyperparameters to get at least 2500 correct test cases (500 test errors).';

% Create a new experiment
scientist = whetlab(name,...
                    description,...                    
                    parameters,...
                    outcome);

% Load in data
load unlabeled.mat
load assign2data2011.mat

% Loop over requesting parameters and training models
for i = 1:50

  % Get a set of parameters.
  job = scientist.suggest();
  epsilon = job.epsilon;
  weightcost = job.weightcost;
  finalmomentum = job.momentum;
  numhid = job.numhid;
  pretrain_wc = job.pretrain_weightcost;
  pretrain_me = job.pretrain_maxepoch;
  maxepoch = job.maxepoch;

  % Set the random seed to something fixed to limit
  % noise from random initialization  
  RandStream.setGlobalStream(RandStream('mt19937ar','seed', 123456));

  % Run rbm pretraining on the unlabeled data
  [hidbiases, vishid] = rbmfun(...
      [double(data); unlabeleddata], numhid, pretrain_wc, pretrain_me);

  % Now perform classification using backprop
  w_class = 0.01.*randn(size(vishid,2)+1, size(targets,2)); restart = 1;
  [terrors, crosste, errs, allterrors] = classbp2cg([vishid; hidbiases], w_class, data, targets,...
    testdata, testtargets, maxepoch, weightcost);

  % The objective is the number of correct test examples
  y = 3000 - terrors;
  scientist.update(job, y);
end