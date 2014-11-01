classdef SimpleREST
    %% SimpleREST(access_token, url)
    %
    % Simple class that wraps calls to the web server through the REST API.
    %
    % The main reason for this class is to deal with retries, to be
    %robust to glitches in the communication with the server.

    properties(Access=protected)
        client;
        INF_PAGE_SIZE = 1000000;
        RETRY_ERROR_MESSAGES = {'Could not connect to server.'};
        RETRY_TIMES = [5,30,60,150,300,600];
    end


    methods

    function self = SimpleREST(access_token, url, retries)
        options = struct('user_agent', 'whetlab_matlab_client',...
                 'api_version','api', 'base', url);
        options.headers.('Authorization') = ['Bearer ' access_token];
        self.client = whetlab_api_client('', options);
        if ~retries
            self.RETRY_TIMES = [];
        end
    end

    function n_retries = retry_or_not(self, err, n_retries)
        %%
        % Checks whether ``err`` is an error for which we do retries.
        %%

        % Get the HTTP status code from the error message
        if (strcmp(err.identifier, 'MATLAB:HttpConection:ConnectionError'))
            [startIndex,endIndex] = regexp(err.message,'code:\d+/');
            if ~isempty(startIndex)
                code = str2num(err.message(startIndex+5:endIndex-1));
            else
                code = 600; % Couldn't connect to server
            end
        end

        retry = false;
        if code == 503 % 503 indicates maintenance
            retry_in = round(rand()*60);
            disp(sprintf('WARNING: Site is temporarily down for maintenance. Will try again in %d seconds.', retry_in));

        elseif code > 500 
            n_retries = n_retries + 1;
            if n_retries > numel(self.RETRY_TIMES)
                rethrow(err);
            else
                retry_in = round(rand()*2*self.RETRY_TIMES(n_retries));
                if n_retries >= 2;                
                    disp(sprintf('WARNING: experiencing problems communicating with the server. Will try again in %d seconds.', retry_in));
                end                
            end

        % Rate limiting
        elseif code == 429
            n_retries = n_retries + 1;
            if n_retries > numel(self.RETRY_TIMES)
                rethrow(err);
            else
                retry_in = round(rand()*2*self.RETRY_TIMES(n_retries));
                disp(sprintf('WARNING: Rate limited by the server: %s Will try again in %d seconds.', err.message, retry_in));
            end

        else
            rethrow(err);
        end
        pause(retry_in);
    end

    function experiment_id = create(self, name, description, settings)
        %%
        % Create experiment and return its ID.
        %%

        n_retries = 0;
        while true;
        try 


        res = self.client.experiments().create(name, description, settings, struct());
        experiment_id = res.body.('id');


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function delete_experiment(self, experiment_id)
        %% 
        % Delete experiment with the given ID ``experiment_id``.
        %%

        n_retries = 0;
        while true;
        try 


        res = self.client.experiment(num2str(experiment_id)).delete();
        disp('Experiment has been deleted');


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function experiment_id = find_experiment(self, name)
        %%
        % Look for experiment matching name and return its ID.
        % If experiment not found, returns -1.
        %%

        n_retries = 0;
        while true;
        try 


        % Look for experiment and get the ID... search one page at a time
        page = 1;
        more_pages = true;
        experiment_id = -1;
        found = false;
        while more_pages
            rest_exps = self.client.experiments().get(struct('query',struct('page',page))).body;
        
            % Check if more pages to come
            more_pages = ~isempty(rest_exps.('next'));
            page = page + 1;

            % Find in current page whether we find the experiment we are looking for
            rest_exps = rest_exps.results;                
            for i = 1:numel(rest_exps)
                expt = rest_exps{i};
                if (strcmp(expt.('name'),name) == 1)
                    experiment_id = expt.id;
                    found = true;
                    break;
                end
            end
            if found
                break;
            end
        end


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end
    end

    function details = get_experiment_details(self, experiment_id)
        %%
        % Gives the details of an experiment (including name and description) from it's ID.
        %%

        n_retries = 0;
        while true;
        try 


        res = self.client.experiments().get(struct('query',struct('id',experiment_id))).body.('results');
        details = res{1};


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function parameters = get_parameters(self, experiment_id)
        %%
        % Gives the parameters of an experiment, from it's ID
        %%

        n_retries = 0;
        while true;
        try 


        parameters = self.client.settings().get(num2str(experiment_id), struct('query', struct('page_size', self.INF_PAGE_SIZE))).body.('results');


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function results = get_results(self, experiment_id)
        %%
        % Gives the results of an experiment, from it's ID.
        %%

        n_retries = 0;
        while true;
        try 


        results = self.client.results().get(struct('query',struct('experiment',experiment_id,'page_size', self.INF_PAGE_SIZE))).body.('results');


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function result_id = get_suggestion(self, experiment_id)
        %%
        % Get suggestion. Obtained in the form of a result ID.
        %%

        n_retries = 0;
        while true;
        try 


        res = self.client.suggest(num2str(experiment_id)).go(struct());
        res = res.body;
        result_id = res.('id');


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function result = get_result(self, result_id)
        %%
        % Get a result from its ID.
        %%

        n_retries = 0;
        while true;
        try 


        result = self.client.result(num2str(result_id)).get(struct()).body;


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function result_id = add_result(self, variables, experiment_id)
        %%
        % Add a result with variable assignments from ``variables``,
        % to experiment with ID ``experiment_id``.
        %%

        n_retries = 0;
        while true;
        try 


        result = self.client.results().add(variables, experiment_id, true, '', '', struct());
        result = result.body;
        result_id = result.id;


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    function update_result(self, result_id, result)
        %%
        % Update a result from its ID ``result_id``, based on the content of ``result``.
        %%

        n_retries = 0;
        while true;
        try 


        res = self.client.result(num2str(result_id)).replace(...
            result.variables, result.experiment, result.userProposed,...
            result.description, result.createdDate, result.id, struct());


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end


    end

    function delete_result(self, result_id)
        %%
        % Delete a result from its ID ``result_id``.
        %%

        n_retries = 0;
        while true;
        try 


        res = self.client.result(num2str(result_id)).delete(struct());


        break;
        catch err
            n_retries = self.retry_or_not(err, n_retries);
        end
        end

    end

    end % methods
end