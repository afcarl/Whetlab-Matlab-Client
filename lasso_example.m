% Let's train up a logistic regression with an elastic net regularization
% and use whetlab to pick the best model parameters.

% First put the whetlab api client on the path
addpath(genpath('.'));

% Fill in with your whetlab access token.
accessToken = '';

load ovarian_dataset;
order = randperm(size(ovarianInputs,2)); % Grab a subset of data to make the problem harder.
X = ovarianInputs(:, order(1:50))';
Y = ovarianTargets(1,order(1:50))';

parameters = {struct('name', 'Lambda', 'type','float', 'min', 1e-4, 'max', 0.75, 'size', 1),...
              struct('name', 'Alpha', 'type', 'float', 'min',1e-4, 'max',1, 'size', 1)};

outcome.name = 'Negative deviance';

% Create a new experiment 
scientist = whetlab('Logistic Regression Example',...
                    'Use Logistic regression with an elastic net regularization penalty to detect ovarian cancer.',...
                    accessToken,...
                    parameters,...
                    outcome, true);

n_iterations = 20;
for i = 1:n_iterations
    % Get suggested new experiment
    job = scientist.suggest();

    % Perform experiment. Perform a quick five-fold cross validation with 
    % the parameters proposed by Whetlab.
    [B,FitInfo] = lassoglm(X,Y,'binomial', 'Lambda', job.Lambda,...
        'CV', 5, 'Alpha', job.Alpha);

    % Take the negative of the returned value.
    % Whetlab will maximize negative deviance which is equivalent to minimizing deviance.
    negDeviance = -FitInfo.Deviance;

    % Now inform scientist about the outcome.
    scientist.update(job,negDeviance);
    scientist.report(); % Plot our progress
end