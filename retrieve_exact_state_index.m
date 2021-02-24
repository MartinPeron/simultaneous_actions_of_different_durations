function stateNumber = retrieve_exact_state_index(parameters, ...
	decomposedBinStates, actionStates, durationsStates, season)

% Retrieve the number (in stateList) of a state from its characteristics, i.e.
% islandStates, actionStates & durationsStates.

% Load parameters
nIsland = parameters{1};
nSubActions = parameters{8};
subActionDurations = parameters{11};
index = parameters{30};

% First, find the state index in stateList through the following calculation
stateIndex = zeros(size(decomposedBinStates, 1), 1);
for iIsland = 1 : nIsland	
	stateIndex = stateIndex * 2 * (nSubActions + 1) * max(subActionDurations)  + ...
		decomposedBinStates(:, iIsland) * (nSubActions + 1) * max(subActionDurations) + ...
		actionStates(iIsland) * max(subActionDurations) + durationsStates(iIsland);	
end
stateIndex = stateIndex * 2 + season;
stateNumber = full(index(stateIndex + 1));

end
