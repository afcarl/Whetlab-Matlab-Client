classdef Experiment

properties
  client = '';
  
  id;
end
methods
	function x = Experiment(id, client)
		x.id = id;
		x.client = client;
        end

        % Return the experiment corresponding to id.
        % '/alpha/experiments/:id/' GET
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
                

                response = self.client.get(['/alpha/experiments/' self.id '/'], body, options);

        end

        % Delete the experiment corresponding to id.
        % '/alpha/experiments/:id/' DELETE
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
                

                response = self.client.delete(['/alpha/experiments/' self.id '/'], body, options);

        end

end % methods
end % classdef