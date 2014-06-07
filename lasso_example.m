% Let's train up a logistic regression with an elastic net regularization
% and use whetlab to pick the best model parameters.

% First put the whetlab api client on the path
addpath(genpath('.'));

% Fill in with your whetlab access token.
%accessToken = '6d70e340-a677-4e7e-af87-f1229a9a1f1e'; % john
accessToken = 'f5f453f8-e38e-419f-81a1-14e674b81000';  % rpa

load ovarian_dataset;
order = randperm(size(ovarianInputs,2)); % Grab a subset of data to make the problem harder.
X = ovarianInputs(:, order(1:50))';
Y = ovarianTargets(1,order(1:50))';

% Optimize both Lambda and Alpha using whetlab.
parameters(1) = struct('name', 'Lambda', 'type','float',...
    'min',1e-4,'max',0.75,'size',1, 'isOutput',false);
parameters(2) = struct('name', 'Alpha', 'type','float',...
    'min',1e-4,'max',1,'size',1, 'isOutput',false);
outcome.name = 'Negative deviance';

% Create a new experiment 
scientist = whetlab('E-Net Logistic Regressiony Thing',...
                    'Logistic regression with an elastic net lasso penalty',...
                    accessToken,...
                    parameters,...
                    outcome, true);

n_iterations = 20;
for i = 1:n_iterations
    % Get suggested new experiment
    job = scientist.suggest();

    % Perform experiment. Perform a quick three-fold cross validation with 
    % the parameters proposed by Whetlab.
    [B,FitInfo] = lassoglm(X,Y,'binomial', 'Lambda', job.Lambda,...
        'CV', 10, 'Alpha', job.Alpha);

    % Take the negative of the returned value.
    % Whetlab will maximize negative deviance which is equivalent to minimizing deviance.
    negDeviance = -FitInfo.Deviance;

    % Now inform scientist about the outcome.
    scientist.update(job,negDeviance);
    scientist.report(); % Plot our progress
end

%Let Matlab do crossvalidation with a grid search to find the best Lambda.
[B_CV,FitInfo_CV] = lassoglm(X,Y,'binomial',...
    'NumLambda',25,'CV',10);
lassoPlot(B_CV,FitInfo_CV,'PlotType','CV');

% Plot the crossvalidation results against the whetlab results
figure(1); hold on; 
plot(FitInfo_CV.Deviance,'b:', 'Marker','x', 'LineWidth', 3);
legend('Outcomes', 'Best so far', 'Crossvalidation');