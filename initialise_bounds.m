function [feasibleActions, indexMatrix, subStates, colonisation] = initialise_bounds(parameters)

% Generates list of actions within budget. indexMatrix is used in generate_bound_model to accelerate
% the computation. Each row of subStates describes the states of each island. 

% Load parameters
nIsland = parameters{1};
budget = parameters{6};
nSubActions = parameters{8};
subActionDurations = parameters{11};
subActionCosts = parameters{12};
nState = parameters{14};
transmissionProba = parameters{40};
PNG = parameters{43};

subStates = LeftDecompose([0:nState - 1]', 2, nIsland + 2);   
% In the lower bound model, actions may have different durations (calculated in find_actions).
	
% find actions that are within the budget and calculate their durations (dynamic programming)
feasibleActions = generate_bound_actions(nSubActions, subActionDurations, subActionCosts, ...
	[], nIsland, budget, [], 1);

% 	Creating a matrix of indices that will be useful to compute the transition matrix. 
indexMatrix(2 ^ nIsland, nIsland) = 0;
for jIsland = 1 : nIsland
	step = 2^(jIsland - 1);
	index = 1;
	tempArr = [];
	while index < 2 ^ nIsland
		tempArr = [tempArr index:index+step-1];
		index = index+2*step;
	end
% 	indexMatrix(:, jIsland) = tempArr;
	indexMatrix(tempArr, jIsland) = 1;
end
indexMatrix = logical(indexMatrix);

% Pre-processing of colonisation probabilities on all islands (columns)
% given all possible combinations of island infestations (rows).
colonisation = zeros(nState, nIsland); 

for iState = 1 : nState
	islandState = subStates(iState, 1:nIsland);
    colonisation(iState, :) = (1-islandState) .* ...
        (1 - prod(1 - bsxfun(@times, [islandState PNG], transmissionProba),2)');
end


end