classdef Settings

properties
  client = '';
  ;
end
methods
	function x = Settings(client)
		x.client = client;
        end

        % Return the settings corresponding to the experiment.
        % '/alpha/settings/' GET
        %
        % experiment - Experiment id to filter by.
        function response = get(self, experiment, options)
                if ~exist('options')
                    options = struct;
                end
                if isfield(options, 'query')
                    body = options.query;
                else
                    body = struct;
                end
                
                body.experiment = experiment;

                response = self.client.get(['/alpha/settings/'], body, options);

        end

end % methods
end % classdef