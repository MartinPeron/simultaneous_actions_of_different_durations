function [legend_names, legCount] = draw_model...
	(parameters, perf, legend_names, legCount, symb, col)

% Prepares the array for display in display_performance. 

% Load parameters
iModel = parameters{2};
modelNames = parameters{10};
verbose = parameters{49};
displayConfig = parameters{57};
nIslandArray = parameters{61};

if displayConfig == 1   % display value.
	
	if isempty(nIslandArray)
		fprintf('\n%s: no values to display.\n', modelNames{iModel});
	else		
		valueArray = perf{iModel}; % values of model 'iModel'. 
	end
	
elseif displayConfig == 2 % display relative error.
	
	if isempty(nIslandArray)
		fprintf('\nUpper bound missing.\n');
	else		
		valueArray = perf{iModel}; % values of model 'iModel'.  
		upperBoundArray = perf{2}; % values of upper bound model.  
%   Calculate relative error to the upper bound model:
		valueArray = 100 * max(0, (1 - (valueArray ./ upperBoundArray(1,:)))); 
	end
end

if ~isempty(nIslandArray)
	h = plot(nIslandArray, valueArray, symb, 'color', col,'LineWidth',2.5);
	hold on;
	legend_names{legCount} = modelNames{iModel};
	if verbose >= 2
		fprintf('\nDisplayed values (%s):\n', modelNames{iModel});
		fprintf('%3g ',round(valueArray(1, :)*100)/100);
	end
	legCount = legCount + 1;
end

end

