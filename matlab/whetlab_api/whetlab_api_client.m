classdef whetlab_api_client
    properties
        httpclient = '';
    end
    methods
      function x = whetlab_api_client(auth, options)
          x.httpclient = http_client(auth, options);
      end
      

        % Manipulate a result set indexed by its id
	%
	% id - Identifier of a result
	function response = result(x, id)
		response = api.Result(id, x.httpclient);
     end

        % Returns the variables set for a user
	%
	function response = variables(x)
		response = api.Variables(x.httpclient);
     end

        % Returns the settings config for an experiment
	%
	function response = settings(x)
		response = api.Settings(x.httpclient);
     end

        % Return user list
	%
	function response = users(x)
		response = api.Users(x.httpclient);
     end

        % Manipulate the results set for an experiment given filters
	%
	function response = results(x)
		response = api.Results(x.httpclient);
     end

        % Returns the tasks set for a user
	%
	function response = tasks(x)
		response = api.Tasks(x.httpclient);
     end

        % Ask the server to propose a new set of parameters to run the next experiment
	%
	% taskid - Identifier of corresponding task
	function response = suggest(x, taskid)
		response = api.Suggest(taskid, x.httpclient);
     end

        % Returns the experiments set for a user
	%
	function response = experiments(x)
		response = api.Experiments(x.httpclient);
     end

        % Manipulate an experimental settings object
	%
	function response = setting(x)
		response = api.Setting(x.httpclient);
     end

   end % methods
end %classdef
