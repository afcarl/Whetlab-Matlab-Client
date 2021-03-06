addpath(genpath('../..'));

% Define parameters to optimize
parameters = {
    struct('name', 'numhid', 'type', 'integer', 'min', 10, 'max', 100);
    struct('name', 'epsilon', 'type', 'float', 'min', 0.01, 'max',  0.1);
    struct('name', 'momentum', 'type', 'float', 'min', 0.7, 'max', 0.95);
    struct('name', 'pretrain_maxepoch', 'type', 'integer', 'min', 10, 'max', 200);
    struct('name', 'maxepoch', 'type', 'integer', 'min', 10, 'max', 100);
    struct('name', 'weightcost', 'type', 'float', 'min', 0.0, 'max', 0.5);
    struct('name', 'pretrain_weightcost', 'type', 'float', 'min', 0.0, 'max', 0.5);
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

  % Set the random seed to something fixed to limit
  % noise from random initialization  
  RandStream.setGlobalStream(RandStream('mt19937ar','seed', 1234567));

  % Run rbm pretraining on the unlabeled data
  [hidbiases, vishid] = rbmfun(...
      [double(data); unlabeleddata], job.numhid, job.pretrain_weightcost, job.pretrain_maxepoch, job.epsilon, job.momentum, 'Yes');

  % Now perform classification using backprop
  w_class = 0.01.*randn(size(vishid,2)+1, size(targets,2)); restart = 1;
  [terrors, ce, errs, allterrors] = classbp2cg([vishid; hidbiases], w_class, data, targets,...
    testdata, testtargets, job.maxepoch, job.weightcost);

  % The objective is the number of correct test examples
  scientist.update(job, 3000 - terrors);

  % Also tell whetlab about the best we've seen so far over epochs
  %[y,ind] = min(allterrors);
  %if ind ~= job.maxepoch && y < terrors
  %  job.maxepoch = ind;
  %  scientist.update(job, 3000 - y);
  %end
end
