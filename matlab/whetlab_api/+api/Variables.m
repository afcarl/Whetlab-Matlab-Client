classdef Variables

properties
  client = '';
  ;
end
methods
	function x = Variables(client)
		x.client = client;
        end

        % Return the variables set corresponding to user
        % '/alpha/variables' GET
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
                

                response = self.client.get(['/alpha/variables'], body, options);

        end

end % methods
end % classdef