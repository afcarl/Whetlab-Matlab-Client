classdef test_whetlab < matlab.unittest.TestCase
	properties
		default_expt_name = 'Matlab test experiment';
		default_access_token = '';  % Read from dotfile
	end

	methods (Test)
		%% We need to be able to delete experiments for most tests to work
		function testCreateDeleteExperiment(testCase)
		    parameters(1) = struct('name', 'Lambda', 'type','float',...
		        'min',1e-4,'max',0.75,'size',1, 'isOutput',false);
		    parameters(2) = struct('name', 'Alpha', 'type','float',...
		        'min',1e-4,'max',1,'size',1, 'isOutput',false);
		    outcome.name = 'Negative deviance';

		    % Create a new experiment 
		    scientist = whetlab(testCase.default_expt_name,...
		                    'Foo',...
		                    testCase.default_access_token,...
		                    parameters,...
		                    outcome, true);
		    
			whetlab.delete_experiment(testCase.default_access_token, testCase.default_expt_name)
		end

		%% Empty experiment names shouldn't work. 
		function testEmptyCreateExperiment(testCase)    
		    parameters(1) = struct('name', 'Lambda', 'type','float',...
		        'min',1e-4,'max',0.75,'size',1, 'isOutput',false);
		    parameters(2) = struct('name', 'Alpha', 'type','float',...
		        'min',1e-4,'max',1,'size',1, 'isOutput',false);
		    outcome.name = 'Negative deviance';

			try
				% Create a new experiment 
				whetlab('',...
	                    'Foo',...
	                    testCase.default_access_token,...
	                    parameters,...
	                    outcome, true);
			catch err
				testCase.verifyTrue(strcmp(err.identifier, 'Whetlab:ValueError'));
			end
		end

		%% Empty experiment names shouldn't work. 
		function testInvalidParameterType(testCase)    
		    parameters(1) = struct('name', 'Lambda', 'type','foot',...
		        'min',1e-4,'max',0.75,'size',1, 'isOutput',false);
		    parameters(2) = struct('name', 'Alpha', 'type','float',...
		        'min',1e-4,'max',1,'size',1, 'isOutput',false);
		    outcome.name = 'Negative deviance';

			try
				% Create a new experiment 
				whetlab(testCase.default_expt_name,...
	                    'Foo',...
	                    testCase.default_access_token,...
	                    parameters,...
	                    outcome, true);
			catch err
				testCase.verifyTrue(strcmp(err.identifier, 'MATLAB:HttpConection:ConnectionError'));
				testCase.verifySubstring(err.message, 'Type foot not a valid choice');
			end
		end

		function FunctionTwotest(testCase)
		% Test specific code
		end
	end

	methods(TestMethodSetup)
		function setup(testCase)  % do not change function name
			% Make sure the test experiment doesn't exist
		    try
		        whetlab.delete_experiment(testCase.default_access_token, testCase.default_expt_name)
		    catch
		    	% pass
		    end
		end
	end

	methods(TestMethodTeardown)
		function teardown(testCase)  % do not change function name
			% Make sure the test experiment doesn't exist
		    try
		        whetlab.delete_experiment(testCase.default_access_token, testCase.default_expt_name)
		    catch
		    	% pass
		    end
		end
	end
end