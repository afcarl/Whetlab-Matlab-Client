classdef auth_handler
        properties

	    URL_SECRET = 2;
	    URL_TOKEN = 3;

            auth;
        end
        methods
            function self = auth_handler(auth)
                self.auth = auth;
            end

	    % Calculating the Authentication Type
	    function authtype = get_auth_type(self)
                authtype = -1;
                if isstruct(self.auth)

	    	    if (isfield(self.auth, 'client_id') && isfield(self.auth, ...
                                                                  'client_secret'))
			    authtype = self.URL_SECRET;
                    end
	  	    if (isfield(self.auth, 'access_token'))
			    authtype = self.URL_TOKEN;
                    end                

                
                end
            end
            function request = set(self, request)
		if isempty(self.auth)
                    return 
                end
		auth = self.get_auth_type();
		flag = false;

		if auth == self.URL_SECRET
			request = self.url_secret(request);
			flag = true;
                end
		if auth == self.URL_TOKEN
			request = self.url_token(request);
			flag = true;
                end

		if ~flag
                    msg = 'Unable to calculate authorization method. Please check';
                    error('MATLAB:HttpConection:AuthenticationError', msg);
                end
            end


            % OAUTH2 Authorization with client secret
	    function request = url_secret(self, request)
		request.params.client_id = self.auth.client_id;
		request.params.client_secret = self.auth.client_secret;
            end

	    % OAUTH2 Authorization with access token
	    function request = url_token(self, request)
		request.params.access_token = self.auth.access_token;
            end


        end
end

