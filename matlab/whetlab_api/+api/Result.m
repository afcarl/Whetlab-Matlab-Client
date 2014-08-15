classdef Result

properties
  client = '';
  
  id;
end
methods
	function x = Result(id, client)
		x.id = id;
		x.client = client;
        end

        % Return a specific result indexed by id
        % '/alpha/results/:id/' GET
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
                

                response = self.client.get(['/alpha/results/' self.id '/'], body, options);

        end

        % Delete the result instance indexed by id
        % '/alpha/results/:id/' DELETE
        %
        function response = delete(self, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                

                response = self.client.delete(['/alpha/results/' self.id '/'], body, options);

        end

        % Update a specific result indexed by id
        % '/alpha/results/:id/' PATCH
        %
        % variables - The result list of dictionary objects with updated fields.
        % experiment - Experiment id
        % userProposed - userProposed
        % description - description
        % runDate - <no value>
        % id - <no value>
        function response = update(self, variables, experiment, userProposed, description, runDate, id, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                
                body.variables = variables;
                body.experiment = experiment;
                body.userProposed = userProposed;
                body.description = description;
                body.runDate = runDate;
                body.id = id;

                response = self.client.patch(['/alpha/results/' self.id '/'], body, options);

        end

        % Replace a specific result indexed by id. To be used instead of update if HTTP patch is unavailable
        % '/alpha/results/:id/' PUT
        %
        % variables - The result list of dictionary objects with updated fields.
        % task - Task id
        % userProposed - userProposed
        % description - description
        % runDate - <no value>
        % id - <no value>
        function response = replace(self, variables, experiment, userProposed, description, runDate, id, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                
                body.variables = variables;
                body.experiment = experiment;
                body.userProposed = userProposed;
                body.description = description;
                body.runDate = runDate;
                body.id = id;

                response = self.client.put(['/alpha/results/' self.id '/'], body, options);

        end

end % methods
end % classdef