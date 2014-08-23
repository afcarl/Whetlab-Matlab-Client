% In this example we will optimize the 'Braninhoo' optimization benchmark with a small twist to 
% demonstrate how to set up a categorical variable.  There is also a constraint on the function.

% Define parameters to optimize
parameters{1} = struct('name', 'X', 'type','float',...
    'min',0,'max',15,'size',1);
parameters{2} = struct('name', 'Y', 'type','float',...
    'min',-5,'max',10,'size',1);     
parameters{3} = struct('name', 'Z', 'type','enum', 'size', 1, 'options', {{'Good' 'Ok' 'Bad'}});

outcome.name = 'negative braninhoo output';
           
accessToken = ''; % Either replace this with your access token or put it in your ~/.whetlab file.
name = 'Categorical Braninhoo';
description = 'Optimize the categorical braninhoo optimization benchmark';
outcome.name = 'Negative Categorical Braninhoo output';

% Create a new experiment
scientist = whetlab('Categorical Braninhoo',...
                    'Categorical Braninhoo example.',...
                    accessToken,...
                    parameters,...
                    outcome, true);

for i = 1:100
    % Get suggested new experiment
    job = scientist.suggest();

    % Perform experiment
    % Braninhoo function
    if strcmp(job.Z, 'Good')
        factor = 1;
    elseif (strcmp(job.Z, 'OK'))
        factor = 2;
    else
        factor = 3;
    end
    if job.X > 10
        result = nan;
    else
        result = (job.Y - (5.1/(4*pi^2))*job.X^2 + (5/pi)*job.X - 6) + 10*(1-(1./(8*pi)))*cos(job.X) + 10*factor;
    end
    
    % Inform scientist about the outcome
    scientist.update(job,result);
end