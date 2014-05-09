classdef Tasks

properties
  client = '';
  ;
end
methods
	function x = Tasks(client)
		x.client = client;
        end

        % Return the task set corresponding to user
        % '/alpha/tasks' GET
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
                

                response = self.client.get(['/alpha/tasks'], body, options);

        end

        % Creates a new task
        % '/alpha/tasks/' POST
        %
        % experiment - The id of the relevant experiment.
        % name - A short name for the task. Max 500 chars
        % description - A detailed description of the task
        function response = create(self, experiment, name, description, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                
                body.experiment = experiment;
                body.name = name;
                body.description = description;

                response = self.client.post(['/alpha/tasks/'], body, options);

        end

end % methods
end % classdef