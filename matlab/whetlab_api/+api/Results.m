classdef Results

properties
  client = '';
  ;
end
methods
	function x = Results(client)
		x.client = client;
        end

        % Return a result set corresponding to an experiment
        % '/alpha/results' GET
        %
        function response = get(self, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'query')
                    body = options.query;
                else
                    body = struct;
                end
                

                response = self.client.get(['/alpha/results'], body, options);

        end

        % Add a user created result
        % '/alpha/results/' POST
        %
        % variables - The result list of dictionary objects with updated fields.
        % task - Task id
        % userProposed - userProposed
        % description - description
        % runDate - <no value>
        function response = add(self, variables, task, userProposed, description, runDate, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                
                body.variables = variables;
                body.task = task;
                body.userProposed = userProposed;
                body.description = description;
                body.runDate = runDate;

                response = self.client.post(['/alpha/results/'], body, options);

        end

end % methods
end % classdef