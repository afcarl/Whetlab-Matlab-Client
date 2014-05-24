classdef Users

properties
  client = '';
  ;
end
methods
	function x = Users(client)
		x.client = client;
        end

        % <no value>
        % '/users' GET
        %
        function response = getusers(self, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'query')
                    body = options.query;
                else
                    body = struct;
                end
                

                response = self.client.get(['/users'], body, options);

        end

end % methods
end % classdef