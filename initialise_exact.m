function [stateList, actionList, decomposedBinStates, indexMatrix] = initialise_exact(parameters)

% Generates list of actions within budget and states corresponding to these actions.
% decomposedBinStates and indexMatrix are matrices used in generate_exact_model to accelerate the
% computation.

% Load parameters
nIsland = parameters{1};
budget = parameters{6};
nSubActions = parameters{8};
subActionDurations = parameters{11};
subActionCosts = parameters{12};

% Generate all states of the exact model (dynamic programming)
stateList = generate_exact_states(nSubActions, subActionDurations, subActionCosts, ...
	[], [], [], nIsland, budget, [], 0, 0);
stateList = stateList';

% Generate all actions of the exact model (dynamic programming)
actionList = generate_exact_actions(nSubActions, subActionCosts, [], nIsland, budget, []);

% This matrix will be useful when filling matrix P.
decomposedBinStates = LeftDecompose([0 : 2^nIsland - 1]', 2, nIsland);


% Creating a matrix of indices that will be useful to compute the transition matrix. 
for jIsland = 1 : nIsland
	step = 2^(jIsland - 1);
	index = 1;
	tempArr = [];
	while index < 2 ^ nIsland
		tempArr = [tempArr index:index+step-1];
		index = index+2*step;
	end
	indexMatrix(jIsland, :) = tempArr;
end

end