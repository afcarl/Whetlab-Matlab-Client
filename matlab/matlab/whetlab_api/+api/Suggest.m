classdef Suggest

properties
  client = '';
  
  taskid;
end
methods
	function x = Suggest(taskid, client)
		x.taskid = taskid;
		x.client = client;
        end

        % Ask the server to propose a new set of parameters to run the next experiment
        % '/alpha/tasks/:taskid/suggest/' POST
        %
        function response = go(self, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'body')
                    body = options.body;
                else
                    body = struct;
                end
                

                response = self.client.post(['/alpha/tasks/' self.taskid '/suggest/'], body, options);

        end

end % methods
end % classdef