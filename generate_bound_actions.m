function feasibleActions = generate_bound_actions(nSubActions, subActionDurations, subActionCosts, ...
	SubActionsSoFar, nIslandRemaining, actionBalance, feasibleActions, actionDuration)

% recursive function to generate a list of actions for the bound models.

if nIslandRemaining == 0
	feasibleActions = [feasibleActions; [SubActionsSoFar actionBalance actionDuration] ];
else
	for iSubAction = 1 : nSubActions
		nextActionBalance = actionBalance - subActionCosts(iSubAction);
		nextActionDuration = lcm(actionDuration, subActionDurations(iSubAction)); % lower bound
% 		For the upper bound, all durations are the same (calculated in initialise_bounds).
		if nextActionBalance >= 0
			feasibleActions = generate_bound_actions(nSubActions, subActionDurations, subActionCosts, ...
				[SubActionsSoFar iSubAction], nIslandRemaining - 1, nextActionBalance, ...
					feasibleActions, nextActionDuration);
		end
	end
end


end