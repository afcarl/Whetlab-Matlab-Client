% Let's train up a logistic regression with an elastic net regularization
% and use whetlab to pick the best model parameters.

% First put the whetlab api client on the path
addpath(genpath('.'));

% Fill in with your whetlab access token.
%accessToken = '6d70e340-a677-4e7e-af87-f1229a9a1f1e'; % john
accessToken = 'ec0e3e69-cd1a-4479-aa8d-aa3c7f670117';  % rpa
%accessToken = 'b4a0dbff-7dae-4945-b3d0-48b7add88a8a'; % local john

load ovarian_dataset;
order = randperm(size(ovarianInputs,2)); % Grab a subset of data to make the problem harder.
X = ovarianInputs(:, order(1:50))';
Y = ovarianTargets(1,order(1:50))';

% Optimize both Lambda and Alpha using whetlab.
parameters.('Lambda') = struct('name',     'Lambda', ...
                               'type',     'float',...
                               'min',      1e-4, ...
                               'max',      0.75, ...
                               'size',     1, ...
                               'isOutput', false);

parameters.('Alpha') = struct('name',     'Alpha', ...
                              'type',     'float',...
                              'min',      1e-4, ...
                              'max',      1, ...
                              'size',     1, ...
                              'isOutput', false);
outcome.name = 'Negative deviance';

% Create a new experiment 
expt_name = 'Parallel E-Net Logistic Regression I';
scientist = whetlab(expt_name,...
                    'Optimizing the hyper-parameters of an elastic net in matlab',...
                    accessToken, ...
                    parameters, ...
                    outcome);

% Get suggested new experiment
fprintf('Requesting suggestion.\n');
job = scientist.suggest();
fprintf('Suggestion received.\n');

% Perform experiment. Perform a quick three-fold cross validation with 
% the parameters proposed by Whetlab.
fprintf('Running experiment.\n');
[B,FitInfo] = lassoglm(X, Y, 'binomial', 'Lambda', job.Lambda,...
                       'CV', 10, 'Alpha', job.Alpha);
fprintf('Experiment complete.\n');

% Take the negative of the returned value.
% Whetlab will maximize negative deviance which is equivalent to minimizing deviance.
negDeviance = -FitInfo.Deviance;

% Now inform scientist about the outcome.
fprintf('Reporting result.\n');
scientist.update(job,negDeviance);
fprintf('Result reported.\n');
