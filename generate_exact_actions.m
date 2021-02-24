function actionList = generate_exact_actions(nSubActions, subActionCosts, ...
	actionStates, nIslandRemaining, actionBalance, actionList)

% Dynamic programming used to identify actions which satisfy the budget constraint.'

if nIslandRemaining == 0
	% Fill the list of actions
	actionList = [actionList; actionStates];
		
else
		
		for iSubAction = 1 : nSubActions
			nextActionBalance = actionBalance - subActionCosts(iSubAction);			
			
			if nextActionBalance >= 0
				
					actionList = generate_exact_actions(nSubActions, subActionCosts, ...
						[actionStates iSubAction], nIslandRemaining - 1, nextActionBalance, actionList);
				end
			end		
end


end