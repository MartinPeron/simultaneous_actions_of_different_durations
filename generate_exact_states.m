function stateList = generate_exact_states(nSubActions, subActionDurations, subActionCosts, ...
	islandStates, actionStates, durationsStates, nIslandRemaining, actionBalance, stateList, ...
	actionIndex, stateIndex)

% Recursive function to generate the list of exact states. We only keep the states whose
% corresponding action satisfy the budget constraint. 

if nIslandRemaining == 0
	
	% Fill the list of states with new states
	stateList = [stateList [islandStates; actionStates; durationsStates; 0; actionIndex; ...
		stateIndex * 2]];		% dry season
	stateList = [stateList [islandStates; actionStates; durationsStates; 1; actionIndex; ...
		stateIndex * 2 + 1]];		% wet season
	
else
	for infestationState = 0 : 1			% loop on potential states of current island		
					
		% Calculcate unique indices of the state/action for later retrieval. 		
		nextActionIndex = actionIndex * (nSubActions + 1) + 0; 
		nextStateIndex = stateIndex * 2 * (nSubActions + 1) * max(subActionDurations)  + ...
			infestationState * (nSubActions + 1) * max(subActionDurations) + ...
			0 * max(subActionDurations) + 0; 
					
		% No sub-action in progress on current island
		stateList = generate_exact_states(nSubActions, subActionDurations, subActionCosts, ...
			[islandStates; infestationState], [actionStates; 0], [durationsStates; 0], ... 
			nIslandRemaining - 1, actionBalance, stateList, nextActionIndex, nextStateIndex);	
		
		% If a sub-action is in progress on current island: loop on potential sub-actions
		for iSubAction = 1 : nSubActions
			nextActionBalance = actionBalance - subActionCosts(iSubAction);
			
			
			if nextActionBalance >= 0
				for timeRemaining = 1 : (subActionDurations(iSubAction) - 1) % loop on potential remaining times of action on current island
			
					% Calculcate unique indices of the state/action for later retrieval. 
					nextActionIndex = actionIndex * (nSubActions + 1) + iSubAction; 
					nextStateIndex = stateIndex * 2 * (nSubActions + 1) * max(subActionDurations)  + ...
						infestationState * (nSubActions + 1) * max(subActionDurations) + ...
						iSubAction * max(subActionDurations) + timeRemaining; 
					
					stateList = generate_exact_states(nSubActions, subActionDurations, subActionCosts, ...
						[islandStates; infestationState], [actionStates; iSubAction], ...
						[durationsStates; timeRemaining], nIslandRemaining - 1, nextActionBalance, ...
						stateList, nextActionIndex, nextStateIndex);
				end
			end			
		end
	end
end


end