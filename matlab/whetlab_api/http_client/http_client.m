% Main HttpClient which is used by Api classes
classdef http_client
    properties
       auth = '';
       options = struct;
       headers = struct;
       base = '';
    end
    methods
        function x = http_client(auth, options)

		if ischar(auth)
			x.auth = struct('access_token', auth);
                end

                
		x.options.base = ['https://api.whetlab.com/',];
                x.options.user_agent = 'alpaca/0.2.0 (https://github.com/pksunkara/alpaca)';

                fields = fieldnames(options);
                for i = 1:numel(fields)
                    x.options.(fields{i}) = options.(fields{i});
                end
                
                if isfield(x.options, 'base')
                    x.base = x.options.base;
                end

                if isfield(options, 'user_agent')
                    x.headers.user_agent = x.options.user_agent;
                end

                if isfield(x.options, 'headers')
                    fields = fieldnames(x.options.headers);
                    for i = 1:numel(fields)
                        x.headers.(fields{i}) = x.options.headers.(fields{i});
                    end
                    x.options = rmfield(x.options, 'headers');
                end

		x.auth = auth_handler(x.auth);
        end % HttpClient

	function response = get(self, path, params, options)
            if nargin > 2
                options.query = params;
            end
                body = struct;
		response = self.request(path, body, 'get', options);
        end

	function response = post(self, path, body, options)
		response = self.request(path, body, 'post', options);
        end

	function response = patch(self, path, body, options)
		response = self.request(path, body, 'patch', options);
        end

        function response = delete(self, path, body, options)
		response = self.request(path, body, 'delete', options);
        end

	function response =  put(self, path, body, options)
		response = self.request(path, body, 'put', options);
        end

	% Intermediate function which does three main things
	%
	% - Transforms the body of request into correct format
	% - Creates the requests with give parameters
	% - Returns response body after parsing it into correct format
	function response = request(self, path, body, method, options)

                f = fieldnames(self.options);
                for i = 1:numel(f)
                    options.(f{i}) = self.options.(f{i});
                end

                options = self.auth.set(options);

                headers = self.headers;
                 if isfield(options, 'headers')
                     fields = fieldnames(options.headers);
                     for i = 1:numel(fields)
                         headers.(fields{i}) = options.headers.(fields{i});
                     end
                     options = rmfield(options, 'headers');
                 end
                
                if isfield(options, 'query')
                    f = fieldnames(options.query);
                    params = {};
                    if ~isempty(f)
                        for i = 1:numel(f)
                            params{end+1} = f{i};
                            params{end+1} = num2str(options.query.(f{i}));
                        end
                    end
                else
                    params = {};
                end

                if isfield(options, 'user_agent')
                    params{end+1} = 'user_agent';
                    params{end+1} = options.user_agent;
                end

                if isfield(options, 'response_type')
                    params{end+1} = 'response_type';
                    params{end+1} = options.response_type;
                end

                if isfield(options, 'request_type')
                    request_type = options.request_type;
                else
                    request_type = 'json';
                end
               
                paramString = '';
                heads = [];
                if strcmp(request_type,'json')
                    request_type = 'application/json';
                    
                    for i = 1:2:numel(params)
                        body.(params{i}) = params{i+1};
                    end
                    f = fieldnames(body);
                    if ~isempty(f)
                      if strcmp(upper(method), 'GET')
                          if ~isempty(params)
                              [paramString,heads] = ...
                                  http_paramsToString(params,1);
                          end
%                           paramString = urlencode(savejson('', ...
%                                                            body, ...
%                                                            'ForceRootName', 0));
                      else
                          paramString = savejson('',body,'ForceRootName', ...
                                                 0);
                      end
                      heads(1).name = 'Content-Type';
                      heads(1).value = 'application/json';
                    end
                elseif strcmp(request_type,'form')
                    f = fieldnames(body);
                    if ~isempty(f)
                        for i = 1:numel(f)
                            params{end+1} = f{i};
                            params{end+1} = num2str(body.(f{i}));
                        end
                    end
                    request_type = ['application/x-www-form-' ...
                                    'urlencoded'];
                    
                    if ~isempty(params)
                        [paramString,heads] = ...
                            http_paramsToString(params,1);
                    end

                elseif strcmp(request_type, 'raw')
                    request_type = '';
                end                    


                
                url = [self.base '/' self.options.api_version '/' path];
                url = regexprep(url,'(/+)','/');
                url = regexprep(url,'(http:/+)','http://'); % Hack to fix http
                url = regexprep(url,'(https:/+)','https://'); % Hack to fix https

                f = fieldnames(headers);
                for i = 1:numel(f)
                    heads(end+1).name = f{i};
                    heads(end).value = headers.(f{i});
                end

                % Add request type to header
                if ~isempty(request_type)
                    heads(end+1).name = 'Accept';
                    heads(end).value = request_type;
                end
                
                if strcmp(method,'patch')
                    method = 'put';
                end
                try
                if strcmp(method,'get')
                    [outputs,extras] = urlread2([url '?' paramString],...
                                                upper(method), '', heads);
                else
                    [outputs,extras] = urlread2(url,upper(method), ...
                                                paramString, heads);
                end
                catch
                     s = lasterror();
                     if strfind(s.message, 'java.net')
                         error('MATLAB:HttpConection:ConnectionError',...
                             'Could not connect to server.');                         
                     else
                         rethrow(s);
                     end
                end
                % Display a reasonable amount of information if the
                % Http request fails for whatever reason
                if extras.isGood <= 0
                    msg = sprintf(['Http connection to %s failed ' ...
                                   'with status %s/%s. '], extras.url, ...
                                  num2str(extras.status.value), ...
                                  extras.status.msg);
                    % Tack on the message from the server
                    if ~isempty(outputs)
                        msg = strcat(msg, sprintf(['Message from server: ' ...
                        '%s'], outputs));
                    end
                    error('MATLAB:HttpConection:ConnectionError', msg);
                end
                response = extras; % Return the status code and
                                   % headers as well
                % outputs can be empty on a delete
                if ~isempty(outputs)
                    response.body = loadjson(outputs);
                end
        end % function
    end % methods
end %classdef
