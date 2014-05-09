classdef Experiments

properties
  client = '';
  ;
end
methods
	function x = Experiments(client)
		x.client = client;
        end

        % Return the experiments set corresponding to user
        % '/alpha/experiments' GET
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
                

                response = self.client.get(['/alpha/experiments'], body, options);

        end

        % Create a new experiment and get the corresponding id
        % '/alpha/experiments/' POST
        %
        % name - The name of the experiment to be created.
        % description - A detailed description of the experiment
        % user - The user id of this user
        function response = create(self, name, description, user, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                
                body.name = name;
                body.description = description;
                body.user = user;

                response = self.client.post(['/alpha/experiments/'], body, options);

        end

end % methods
end % classdef