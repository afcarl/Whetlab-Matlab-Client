classdef whetlab
    %% whetlab(name, description, parameters, outcome, resume, access_token)
    %
    % Instantiate a Whetlab client.
    % This client allows you to manipulate experiments in Whetlab
    % and interact with the Whetlab server.
    %
    % A name and description for the experiment must be specified.
    % A Whetlab access token must also be provided.
    % The parameters to tune in the experiment are specified by
    % ``parameters``. It should be a cell array, where each cell is
    % a parameter, in the form of a ``struct`` describing it. Each of these
    % ``struct`` should contain the appropriate keys to properly describe
    % the parameter:
    %
    % * **name**: name of the parameter (``str``)
    % * **type**: type of the parameter, among ``float``, ``int`` and ``enum``(default: ``float``)
    % * **min**: minimum value of the parameter (only for types ``float`` and ``int``)
    % * **max**: maximum value of the parameter (only for types ``float`` and ``int``)
    % * **options**: cell of strings, of the possible values that can take an ``enum`` parameter (only for type ``enum``)
    % * **size**: size of parameter (default: ``1``)
    %
    % Outcome should also be a ``struct``, describing the outcome. It
    % should have the field:
    %
    % * *name*: name (str) for the outcome being optimized
    %
    % Finally, experiments can be resumed from a previous state.
    % To do so, ``name`` must match a previously created experiment
    % and argument ``resume`` must be set to ``True`` (default is ``False``).
    %
    % * *name* (str): Name of the experiment.
    % * *description* (str): Description of the experiment.
    % * *parameters* (struct, cell array): Parameters to be tuned during the experiment.
    % * *outcome* (struct): Description of the outcome to maximize.
    % * *resume* (boolean): Whether to resume a previously executed experiment. If ``True`` and experiment's name matches an existing experiment, ``parameters`` and ``outcome`` are ignored (default: ``None``).
    % * *access_token* (str): Access token for your Whetlab account. If ``''``, then is read from whetlab configuration file (default: ``''``).
    %
    % A Whetlab experiment instance will have the following variables:
    %
    % * *parameters* (struct): Parameters to be tuned during the experiment.
    % * *outcome* (struct): Description of the outcome to maximize.
    %
    % Example usage::
    %
    %   % Create a new experiment
    %   name = 'A descriptive name';
    %   description = 'The description of the experiment';
    %   parameters = {struct('name', 'Lambda', 'type','float', 'min', 1e-4, 'max', 0.75, 'size', 1),...
    %                 struct('name', 'Alpha', 'type', 'float', 'min', 1e-4, 'max',1, 'size', 1)};
    %   outcome.name = 'Accuracy';
    %   accessToken = ''; % Assume this is specified in ~/.whetlab
    %
    %   scientist = whetlab(name,...
    %               description,...
    %               parameters,...
    %               outcome, true, access_token);
    
    properties(Access=protected)
        client;
        % Use native java hashtables
        % These are for the client to keep track of things without always 
        % querying the REST server ...
        % ... From result IDs to client parameter values
        ids_to_param_values   = java.util.Hashtable;
        % ... From result IDs to outcome values
        ids_to_outcome_values = java.util.Hashtable;
        % ... From parameters to their 'ids'
        params_to_setting_ids = java.util.Hashtable;
        % All of the parameter values seen thus far
        param_values          = java.util.Hashtable;
        % All of the outcome values seen thus far
        outcome_values        = java.util.Hashtable;
        % The set of result IDs corresponding to suggested jobs that are pending
        pending_ids           = [];
        experiment            = '';
        experiment_description= '';
        experiment_id = -1;
        outcome_name = '';
        parameters = struct([struct('name',{}, 'type', {}, 'min', {}, 'max', {}, 'size', {}, 'isOutput', {}, 'units',{},'scale',{})]);

        % Validation things
        supported_properties = struct('isOutput', {}, 'name', {}, 'min',{}, 'max',{}, 'size',{}, 'scale', {},'units', {}, 'type', {});
        required_properties = struct('min', {}, 'max', {});
        default_values = struct('size',1, 'scale', 'linear', 'units', 'Reals', 'type', 'float');

        INF_PAGE_SIZE = 1000000;

    end

    methods(Static)
        function vars = read_dot_file()
            vars = struct();
            dot_file_path = '';

            if exist('.whetlab', 'file') > 0 
                dot_file_path = '.whetlab';
            end

            if strcmp(dot_file_path,'') && exist('~/.whetlab', 'file') > 0 
                dot_file_path = '~/.whetlab';
            end

            if ~strcmp(dot_file_path,'') 
                fid = fopen(dot_file_path);
                tline = fgetl(fid);
                while ischar(tline)
                    if ~isempty(strfind(tline,'=')) && ~strcmp(tline(1), '#') && ~strcmp(tline(1), '%')
                        C = strsplit(tline, '=');
                        vars.(strtrim(C{1})) = strtrim(C{2});
                    end
                    tline = fgetl(fid);
                end
                fclose(fid);
            end
        end

        % Convert from a struct to a cell 
        function params = struct_2_cell_params(paramstruct)
            f = fieldnames(paramstruct);
            params = {};
            for i = 1:length(f)
                params{end+1} = f{i};
                params{end+1} = paramstruct.(f{i});
            end
        end

        function equal = struct_almost_equal(a, b)
            equal = true;
            if ~isstruct(a) or ~isstruct(b)
                equal = false;
                return
            end

            fa = fieldnames(a);
            fb = fieldnames(b);
            if ~isempty(setdiff(fa, fb))
                equal = false;
                return
            end

            for i = 1:numel(fa)
                if isnumeric(b.(fa{i})) & isnumeric(a.(fa{i}))
                    if sum((b.(fa{i}) - a.(fa{i})).^2) > 1e-12
                        equal = false;
                    end
                else
                    if isstr(b.(fa{i}))
                        if isstr(a.(fa{i}))
                            if strcmp(b.(fa{i}), a.(fa{i}))
                                equal = true;
                            else
                                equal = false;
                            end
                        else
                            equal = false;
                        end                                
                    elseif b.(fa{i}) ~= a.(fa{i})
                        equal = false;
                    end
                end
                if ~equal
                    return
                end
            end
        end
                    
        function delete_experiment(name, access_token)
            %% delete_experiment(name, access_token)
            %
            % Delete the experiment with the given name.  
            %
            % Important, this cancels the experiment and removes all saved results!
            %
            % * *name* (str): Experiment name
            % * *access_token* (str): User access token
            %
            % Example usage::
            %
            %   % Delete the experiment and all corresponding results.
            %   access_token = ''; % Assume this is taken from ~/.whetlab
            %   whetlab.delete_experiment('My Experiment',access_token);
        
            % First make sure the experiment with name exists
            outcome.name = '';
            scientist = whetlab(name, '', [], outcome, true, access_token);
            scientist.delete();
        end
    end

    methods

    function self = whetlab(...
             name,...
             description,...
             parameters,...
             outcome,...
             resume,...
             access_token,...
             retries)

        assert(usejava('jvm'),'This code requires Java');
        if (nargin <= 4)
            resume = true;
        end
        experiment_id = -1;

        vars = whetlab.read_dot_file();

        if (nargin <= 5 | isempty(access_token))
            try
                access_token = vars.access_token;
            catch
                error('You must specify your access token in the variable access_token either in the client or in your ~/.whetlab file')
            end
        end

        if nargin <= 6
            retries = true;
        end

        % Make a few obvious asserts
        if (isempty(name) || ~strcmp(class(name), 'char'))
            error('Whetlab:ValueError', 'Name of experiment must be a non-empty string.');
        end

        if (~strcmp(class(description), 'char'))
            error('Whetlab:ValueError', 'Description of experiment must be a string.');
        end

        % Create REST server client
        if isfield(vars, 'api_url')
            hostname = vars.api_url;
        else
            hostname = 'https://www.whetlab.com/';
        end
        self.client = SimpleREST(access_token, hostname, retries);

        self.experiment_description = description;
        self.experiment = name;
        self.outcome_name = outcome.name;

        if resume
            % Try to resume if the experiment exists. If it doesn't exist, we'll create it.
            self.experiment_id = experiment_id;
            try
                self = self.sync_with_server();
                disp(['Resuming experiment: ' self.experiment]);
                return % Successfully resumed
            catch err
                if ~strcmp(err.identifier, 'Whetlab:ExperimentNotFoundError')
                    rethrow(err);
                end
            end
        end

        if ~strcmp(class(parameters), 'struct') && ~strcmp(class(parameters), 'cell')
            error('Whetlab:ValueError', 'Parameters of experiment must be a structure array or a cell array.');
        end

        if ~strcmp(class(outcome), 'struct') && ~isempty(fieldnames(outcome))
            error('Whetlab:ValueError', 'Outcome of experiment must be a non-empty struct.');
        end

        if ~isfield(outcome, 'name')
            error('Whetlab:ValueError', 'Argument outcome should have a field called: name.');
        end
        self.outcome_name = outcome.name;

        % Create new experiment
        % Add specification of parameters
        settings = {};     
        for i = 1:numel(parameters)
            if isstruct(parameters)
                param = parameters(i);
            else % A cell array
                param = parameters{i};
            end

            if ~isfield(param, 'name')
                error('Whetlab:UnnamedParameterError', 'You must specify a name for each parameter.')
            end

            if ~isfield(param,'type'), param.('type') = self.default_values.type; end

            if strcmp(param.type, 'int')
                param.('type') = 'integer';
            end

            if strcmp(param.type, 'enum')
                if ~isfield(param, 'options')  || numel(param.options) < 2
                     error('Whetlab:ValueError', ['Parameter ' param.name ' is an enum type which requires the field options with more than one element.']);
                end
                % Add default parameters if not present
                if ~isfield(param,'isOutput'), param.('isOutput') = false; end
            else
                properties = fieldnames(param);
                for ii = 1:numel(properties)
                    if ~isfield(self.supported_properties, properties{ii})
                        error('Whetlab:ValueError', ['Parameter ' param.name ': property ' properties{ii} ' is not supported.']);
                    end
                end

                % Check if required properties are present
                properties = fieldnames(self.required_properties);
                for ii = 1:numel(properties)
                    if ~isfield(param, properties{ii})
                        error('Whetlab:ValueError', ['Parameter ' param.name ': property ' properties{ii} ' must be defined.']);
                    end
                end

                % Add default parameters if not present
                if ~isfield(param,'units'), param.('units') = self.default_values.units; end
                if ~isfield(param,'scale'), param.('scale') = self.default_values.scale; end
                if ~isfield(param,'isOutput'), param.('isOutput') = false; end

                % Check compatibility of properties
                if param.('min') >= param.('max')
                    error('Whetlab:ValueError', ['Parameter ' param.name ': min should be smaller than max.']);
                end

                if (~isfinite(param.('min')) | ~isfinite(param.('max')))
                    error('Whetlab:ValueError', ['Parameter ' param.name ': min and max should be finite.']);
                end

                if (numel(param.('min')) ~= 1 | numel(param.('max')) ~= 1)
                    error('Whetlab:ValueError', ['Parameter ' param.name ': min and max should each be a single number.']);
                end

            end
            settings{i} = param;

            f = fieldnames(param);
            for j = 1:numel(f)
                self.parameters(i).(f{j}) = param.(f{j});
            end
        end

        % Add the outcome variable
        param = struct('units','Reals', 'scale','linear', 'type','float', 'isOutput', true, 'min',-100, 'max', 100, 'size',1);
        outcome = self.structUpdate(param, outcome);
        % outcome = self.structUpdate(settings(end), outcome);
        outcome.name = self.outcome_name;
        settings{end+1} = outcome;    
        try
            experiment_id = self.client.create(name, description, settings);
        catch err
            % Resume, unless got a ConnectionError
            if resume && strfind(err.message, 'already exists')
                % This experiment was just already created - race condition.
                self = self.sync_with_server();
                return
            else
                rethrow(err);
            end
        end

        self.experiment_id = experiment_id;

        % Check if there are pending experiments
        p = self.pending();
        if length(p) > 0
            disp(sprintf('INFO: this experiment currently has %d jobs (results) that are pending.',length(p)));
        end
    end % Experiment()

    function self = sync_with_server(self)
        %% sync_with_server(self)
        %
        % Synchronize the client's internals with the REST server.
        %
        % Example usage::
        %
        %   % Create a new experiment 
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   scientist.sync_with_server()

        % Reset internals
        self.ids_to_param_values.clear();
        self.ids_to_outcome_values.clear();
        self.params_to_setting_ids.clear();

        found = false;

        if self.experiment_id < 0
            self.experiment_id = self.client.find_experiment(self.experiment);
            if self.experiment_id < 0
                error('Whetlab:ExperimentNotFoundError',...
                    'Experiment with name \"%s\" and description \"%s\" not found.',...
                     self.experiment, self.experiment_description);
            end
        else
            details = self.client.get_experiment_details(self.experiment_id);
            self.experiment = details.('name');
            self.experiment_description = details.('description');
        end

        % Get settings for this task, to get the parameter and outcome names
        rest_parameters = self.client.get_parameters(self.experiment_id);
        self.parameters = {};
        for i = 1:numel(rest_parameters)
            param = rest_parameters{i};
            if(param.experiment ~= self.experiment_id); continue; end
            id = param.('id');
            name = param.('name');
            vartype=param.('type');
            minval=param.('min');
            maxval=param.('max');
            varsize=param.('size');
            units=param.('units');
            scale=param.('scale');
            isOutput=param.('isOutput');

            self.params_to_setting_ids.put(name, id);

            if isOutput
                self.outcome_name = name;
            else
                if ~strcmp(vartype, 'enum')
                    self.parameters{end+1} = struct('name', name, 'type', vartype,'min',minval,'max',maxval,...
                                 'size', varsize,'isOutput', false, 'units', units,'scale', scale);
                elseif strcmp(vartype, 'enum')
                options = param.('options');
                    self.parameters{end+1} = struct('name', name, 'type', vartype,'min',minval,'max',maxval,...
                                 'size', varsize,'isOutput', false, 'units', units,'scale', scale,'options',options);
                else
                    error('Whetlab:ValueError', ['Type ' vartype ' not supported for variable ' name]);
                end                    
            end
        end

        % Get results generated so far for this task
        rest_results = self.client.get_results(self.experiment_id);
        % Construct things needed by client internally, to keep track of
        % all the results

        for i = 1:numel(rest_results)
            res = rest_results{i};
            res_id = res.('id');
            variables = res.('variables');
            tmp = {};

            % Construct param_values hash and outcome_values
            for j = 1:numel(variables)
                v = variables{j};

                id = v.('id');
                name = v.('name');                
                if isequal(name, self.outcome_name)
                    % Anything that's passed back as a string is assumed to be a
                    % constraint violation.
                    if isstr(v.value)
                        v.value = -inf;
                    end

                    % Don't record the outcome if the experiment is pending
                    if ~isempty(v.value)
                        self.ids_to_outcome_values.put(res_id, v.value);
                    else % Treat NaN as the special indicator that the experiment is pending. We use -INF for constraint violations
                        self.ids_to_outcome_values.put(res_id, nan);
                    end
                else
                    tmp.(v.('name')) = v.('value');
                    self.ids_to_param_values.put(res_id, savejson('',tmp, 'FloatFormat', '%0.64f'));
                end
            end
        end

        % Make sure that everything worked
        assert(~isempty(self.outcome_name))
        assert(self.experiment_id >= 0)

    end

    function [jobs, outcomes] = get_all_results(self)
        %% jobs, outcomes = get_all_results()
        % Return the list of all jobs and corresponding outcomes
        %
        % * *returns:* An cell array of parameter values and a cell array of outcome values
        % * *return type:* cell
        % 
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,
        %               description,
        %               parameters,
        %               outcome, true, access_token)
        %
        %   % Get the list of results
        %   jobs, outcomes = scientist.get_all_results()

        % Sync with the REST server
        self.sync_with_server();

        % Find IDs of results with value nil and append parameters to returned list
        jobs = {};
        outcomes = {};
        ids = self.ids_to_outcome_values.keySet().toArray();
        for j = 1:length(ids)
            outcomes{end+1} = self.ids_to_outcome_values.get(ids(j));
            jobs{end+1} = loadjson(self.ids_to_param_values.get(ids(j)));
        end
    end % get_all_results()

    function pend = pending(self)
        %% pend = pending(self)
        % Return the list of jobs which have been suggested, but for which no 
        % result has been provided yet.
        %
        % * *returns:* Struct array of parameter values.
        % * *return type:* struct array
        % 
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Get the list of pending experiments
        %   pend = scientist.pending()
    
        % Sync with the REST server     
        self = self.sync_with_server();

        % Find IDs of results with value None and append parameters to returned list
        i = 1;
        ids = self.ids_to_outcome_values.keySet().toArray();
        outcomes = self.ids_to_outcome_values.values().toArray();
        outcomes = arrayfun(@(x)x, outcomes);
        pend = [];
        for j = 1:length(outcomes)
            val = outcomes(j);
            if isnan(val)
                ret(i) = loadjson(self.ids_to_param_values.get(ids(j)));
                i = i + 1;
                pend = ret;
            end
        end
    end % pending()

    function clear_pending(self)
        %% clear_pending(self)
        % Delete all of the jobs which have been suggested but for which no 
        % result has been provided yet (i.e. pending jobs).
        %
        % This is a utility function that makes it easy to clean up
        % orphaned experiments.
        %
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Clear all of orphaned pending experiments
        %   scientist.clear_pending()
        
        jobs = self.pending();
        if ~isempty(jobs)
            for i = 1:numel(jobs)
                self.cancel(jobs(i));
            end
        end
        self = self.sync_with_server();
    end        
    function next = suggest(self)
        %% next = suggest(self)
        % Suggest a new job.
        % 
        % This function sends a request to Whetlab to suggest a new
        % experiment to run.  It may take some time to return while waiting
        % for the suggestion to complete on the server.
        %
        % This function returns struct containing parameter names and 
        % corresponding values detailing a new experiment to be run.
        %
        % * *returns:* Values to assign to the parameters in the suggested job.
        % * *return type:* struct
        %
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Get a new experiment to run.
        %   job = scientist.suggest();
        
        self.sync_with_server();
        result_id = self.client.get_suggestion(self.experiment_id);
        
        % Remember that this job is now assumed to be pending
        self.pending_ids(end+1) = result_id;
        
        % Poll the server for the actual variable values in the suggestion.  
        % Once the Bayesian optimization proposes an
        % experiment, the server will fill these in.
        result = self.client.get_result(result_id);
        variables = result.variables;
        while isempty(variables)
            pause(2);
            result = self.client.get_result(result_id);
            variables = result.variables;
        end
        
        % Put in a nicer format
        % next = {};
        for i = 1:numel(variables)
            if ~strcmp(variables{i}.name, self.outcome_name);
                next.(variables{i}.name) = variables{i}.value;
                % next{end+1} = variables{i}.name;
                % next{end+1} = variables{i}.value;
            end
        end        

        % Keep track of id / param_values relationship
        self.ids_to_param_values.put(result_id, savejson('',next, 'FloatFormat', '%0.64f'));
        next.('result_id_') = result_id;
    end % suggest

    function id = get_id(self, param_values)
        %% id = get_id(self, param_values)
        % Return the result ID corresponding to the given _param_values_.
        % If no result matches, return -1.
        %
        % * *param_values* (struct): Values of parameters.
        % * *returns:* ID of the corresponding result. If not match, -1 is returned.
        % * *return type:* int or -1
        %
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Get a new experiment to run
        %   job = scientist.suggest();
        %   
        %   % Get the corresponding experiment id.
        %   id = scientist.get_id(job);

        % Check to see if we have the result id
        if (isfield(param_values,'result_id_') & param_values.result_id_ > 0 & ...
            isfield(param_values, 'experiment_id_') & param_values.experiment_id_ == self.experiment_id)
            id = param_values.result_id_;
            return
        end

        % First sync with the server
        self = self.sync_with_server();

        % Remove key result_id_ if present
        if isfield(param_values,'result_id_')
            param_values = rmfield(param_values,'result_id_');
        end

        id = -1;
        keys = self.ids_to_param_values.keySet().toArray;
        for i = 1:numel(keys)
            % Note we have to check for "almost" equality since the fp representation 
            % can be fudged a bit during conversion from server
            if whetlab.struct_almost_equal(param_values, loadjson(self.ids_to_param_values.get(keys(i))))
                id = keys(i);
                break;
            end
        end
    end % get_id

    function delete(self)
        %% delete(self)
        %
        % Delete this experiment.  
        %
        % Important, this cancels the experiment and removes all saved results!
        %
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Delete this experiment and all corresponding results.
        %   scientist.delete()
        
        self.client.delete_experiment(self.experiment_id);
    end
    
    function self = update(self, param_values, outcome_val)
        %% update(self, param_values, outcome_val)
        % Update the experiment with the outcome value associated with some parameter values.
        % This informs Whetlab of the resulting outcome corresponding to
        % the experiment specified by _param_values_.  _param_values_ can 
        % correspond to an experiment suggested by Whetlab or an
        % independently run (user proposed) experiment.
        %
        % * *param* param_values: Values of parameters.
        % * *type* param_values: struct
        % * *param* outcome_val: Value of the outcome.
        % * *type* outcome_val: type defined for outcome
        % 
        % Example usage::
        % 
        %   % Assume that a whetlab instance has been instantiated in scientist.
        %   job = scientist.suggest(); % Get a suggestion
        %
        %   % Run an experiment with the suggested parameters and record the result.
        %   result = 1.7;  
        %   scientist.update(job, result);
        %
        if (length(outcome_val) > 1) or ((isstruct(param_values) && length(param_values) > 1))
            error('Whetlab:ValueError', 'Update does not accept more than one result at a time');
        end

        % Check whether this param_values has a result ID
        result_id = self.get_id(param_values);

        if result_id == -1
            % - Add new results with param_values and outcome_val

            % Create variables for new result
            param_names = self.params_to_setting_ids.keySet().toArray();
            for i = 1:numel(param_names)
                name = param_names(i);
                setting_id = self.params_to_setting_ids.get(name);
                if isfield(param_values, name)
                    value = param_values.(name);
                elseif strcmp(name, self.outcome_name)
                    value = outcome_val;
                    % Convert the outcome to a constraint violation if it's not finite
                    % This is needed to send the JSON in a manner that will be parsed
                    % correctly server-side.
                    if isnan(outcome_val)
                        value = 'NaN';
                    elseif ~isfinite(outcome_val)
                        value = '-infinity'; 
                    end
                else
                    error('InvalidJobError',...
                        'The job specified is invalid');
                end
                variables(i) = struct('setting', setting_id,...
                    'name',name, 'value',value);                
            end
            result.variables = variables;
            result_id = self.client.add_result(variables, self.experiment_id);

            % if isstruct(param_values)
            %     param_values = whetlab.struct_2_cell_params(param_values)
            % end

            self.ids_to_param_values.put(result_id, savejson('',param_values, 'FloatFormat', '%0.64f'));
        else
            result = self.client.get_result(result_id);

            for i = 1:numel(result.variables)
                var = result.variables{i};
                if strcmp(var.('name'), self.outcome_name)
                    % Convert the outcome to a constraint violation if it's not finite
                    % This is needed to send the JSON in a manner that will be parsed
                    % correctly server-side.                    
                    result.variables{i}.('value') = outcome_val;
                    if isnan(outcome_val)
                        result.variables{i}.('value') = 'NaN';
                    elseif ~isfinite(outcome_val)
                        result.variables{i}.('value') = '-infinity';
                    end
                    self.outcome_values.put(result_id, savejson('',var, 'FloatFormat', '%0.64f'));
                    break % Assume only one outcome per experiment!
                end
            end

            self.param_values.put(result_id, savejson('',result, 'FloatFormat', '%0.64f'));
            self.client.update_result(result_id, result);

            % Remove this job from the pending list
            self.pending_ids(self.pending_ids == result_id) = [];
        end
        self.ids_to_outcome_values.put(result_id, outcome_val);
    end %update
    
    function self = cancel(self,param_values)
        %% cancel(self,param_values)
        % Cancel a job, by removing it from the jobs recorded so far in the experiment.
        %
        % * *param_values* (struct): Values of the parameters for the job to cancel.
        %
        % Example usage::
        % 
        %   % Assume that a whetlab instance has been instantiated in scientist.
        %   job = scientist.suggest(); % Get a suggestion
        %
        %   % Run an experiment with the suggested parameters and record the result.
        %   result = 1.7;  
        %   scientist.update(job, result);
        %
        %   % Tell Whetlab to forget about that experiment (perhaps the result was an error).
        %   scientist.cancel(job);
        
        % Check whether this param_values has a results ID
        id = self.get_id(param_values);
        if id > 0
            self.ids_to_param_values.remove(num2str(id));

            % Delete from internals
            if self.ids_to_outcome_values.containsKey(id)
                self.ids_to_outcome_values.remove(id);
            end
                
            % Remove this job from the pending list if it's there.
            self.pending_ids(self.pending_ids == id) = [];

            % Delete from server
            self.client.delete_result(id);
        else
            warning('Did not find experiment with the provided parameters');
        end
    end % cancel
    
    function param_values = best(self)
        %% param_values = best(self)
        % Return the job with best outcome found so far.        
        %
        % * *returns:* Parameter values corresponding to the best outcome.
        % * *return type:* struct
        %
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Get the best job seen so far.
        %   best = scientist.best();

        % Sync with the REST server     
        self = self.sync_with_server();

        % Find ID of result with best outcomeh
        ids = self.ids_to_outcome_values.keySet().toArray();
        outcomes = self.ids_to_outcome_values.values().toArray();
        outcomes = arrayfun(@(x)x, outcomes);

        [~, ind] = max(outcomes);
        result_id = ids(ind);

        % Get param values that generated this outcome
        result = self.client.get_result(result_id);
        for i = 1:numel(result.('variables'))
            v = result.('variables'){i};
            if ~strcmp(v.name, self.outcome_name)
                param_values.(v.name) = v.value;
            end
        end
        
    end % best
        
    function report(self)
        %% report(self)
        % Plot a visual report of the progress made so far in the experiment.
        %
        % Example usage::
        %
        %   % Create a new experiment
        %   scientist = whetlab(name,...
        %               description,...
        %               parameters,...
        %               outcome, true, access_token);
        %
        %   % Visualize the results so far.
        %   scientist.report();
        
        % Sync with the REST server
        self = self.sync_with_server();

        % Report historical progress and experiments assumed pending

        % Get outcome values and put them in order of their IDs,
        % which should be equivalent to chronological order (of suggestion time)
        ids = self.ids_to_outcome_values.keySet().toArray();
        %# convert to MATLAB vector from java
        ids = arrayfun(@(x)x, ids);
        ids = sort(ids);
        
        for i = 1:numel(ids)
            outcome_values(i) = self.ids_to_outcome_values.get(ids(i));
        end
        
        font_size  = 12;
        fig_height = 10/2;
        fig_width  = 16.18/2;
        line_width = 3;
        position   = [0.14 0.14 0.84 0.84];

        set(0, 'DefaultTextInterpreter', 'tex', ...
              'DefaultTextFontName',    'Helvetica', ...
              'DefaultTextFontSize',    font_size, ...
              'DefaultAxesFontSize',    font_size);

        figure(1); clf();
        set(gcf(), 'Units', 'inches', ...
               'Position', [0 0 fig_width fig_height], ...
               'PaperPositionMode', 'auto');
        subplot('Position', position);
        hold on;

        % Plot progression        
        y = outcome_values;
        maxs(1) = y(1);
        for i = 2:numel(y); maxs(i) = max(y(i), maxs(i-1)); end
        best_so_far = maxs;
        plot(1:numel(y),y,'kx', 'LineWidth', line_width);
        plot(1:numel(y),best_so_far,'k', 'LineWidth', line_width);
        xlabel('Experiment ID');
        ylabel(self.outcome_name);
        title('Outcome values progression');
        legend('Outcomes', 'Best so far');

        figure(2); clf();
        % Add a table of experiments
        param_names = cell(self.params_to_setting_ids.keySet().toArray());
        param_names = setdiff(param_names, self.outcome_name);
        param_vals = [];

        for i = 1:numel(ids)
            params = loadjson(self.ids_to_param_values.get(ids(i)));
            for j = 1:numel(param_names)
                row{j} = params.(param_names{j});
            end
            param_vals = [param_vals; [row, y(i)]];
        end
        param_names{end+1} = self.outcome_name;
        uitable('Data', param_vals, 'ColumnName', param_names);

    end % report
    
    % Update struct first with new properties from struct second
    function first = structUpdate(self, first, second)
        f = fieldnames(second);
        for i = 1:numel(f)
            first.(f{i}) = second.(f{i});
        end
    end
    end % methods
end
