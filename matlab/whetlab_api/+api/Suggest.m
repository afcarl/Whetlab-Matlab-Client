classdef Suggest

properties
  client = '';
  
  exptid;
end
methods
	function x = Suggest(exptid, client)
		x.exptid = exptid;
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
                

                response = self.client.post(['/alpha/experiments/' self.exptid '/suggest/'], body, options);

        end

end % methods
end % classdef