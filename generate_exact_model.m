function [parameters, R, pRow, pCol, pVal] = ...
		generate_exact_model(parameters)

% Compute the matrix R (reward) and the matrix P for the exact model.	
	
% Load parameters
nIsland = parameters{1};
discount = parameters{3};
subActionDurations = parameters{11};
beginningSeason = parameters{17};
infestationProba = parameters{36};
transmissionProba = parameters{40};
transmissionToMainland = parameters{41};
PNG = parameters{43};
verbose = parameters{49};

[stateList, actionList, decomposedBinStates, indexMatrix] = initialise_exact(parameters);


nState = size(stateList, 1) + 1;    % + 1 is for the absorbing state
nAction = size(actionList, 1);
parameters{14} = nState;
parameters{15} = nAction;
for i = 1 : (nState - 1)
    indexRow(i) = stateList(i, end) + 1;
    indexVal(i) = i;
end
		
 % the variable index links row number to state number:
parameters{30} = sparse(indexRow, ones(1, nState - 1), indexVal, indexRow(end) + 1, 1); 
parameters{71} = retrieve_exact_state_index(parameters, ...
	ones(1,nIsland), zeros(1,nIsland), zeros(1,nIsland), beginningSeason);  % initial state
parameters{34} = parameters{71};   % for simulations

% 	discountArray will be useful to process Bellamn's equation: 
parameters{21} = discount * ones(1,nAction);
parameters{22} = stateList;
parameters{23} = actionList;	

if verbose >= 1, fprintf('Number of states / actions : %i / %i \n', nState, nAction); end


reward = 0.5;     % reward per time step.
% last (absorbing) state gets reward 0.
R = [reward * ones(nState - 1, nAction); zeros(1, nAction)];

pRow = cell(1,nAction);     % rows of P for each actions
pCol = cell(1,nAction);     % columns of P for each actions  
pVal = cell(1,nAction);     % values of P for each actions  


% Computation of the matrix P by looping on the states
pCounter = ones(1,nAction);  
for iState = 1 : nState
	
	if iState == nState
% 		Absorbing state (mainland infested):
		for iAction = 1 : nAction
			pRow{iAction}(pCounter(iAction)) = iState;
			pCol{iAction}(pCounter(iAction)) = iState;
			pVal{iAction}(pCounter(iAction)) = 1;	
			pCounter(iAction) = pCounter(iAction) + 1;
		end
	else		
		
	% By using stateList, we decompose the states into its components: the season, the state of each
	% island, which action is implemented and the time before the action terminates.
		islandState = stateList(iState, 1 : nIsland );
		actionState = stateList(iState, (nIsland + 1) : (2 * nIsland) );
		remainingTime = stateList(iState, (2 * nIsland + 1) : (3 * nIsland) );
		season = stateList(iState, 3 * nIsland + 1 );
		rowArray = iState * ones(1, 2 ^ nIsland + 1);
		
		islandManaged = logical(actionState);
		susNotManaged = logical((1 - islandState) .* (1 - islandManaged));
    onGoingActions = actionState(islandManaged);
		for iAction = 1 : nAction
			subActions = actionList(iAction, :);
			
% 		Sub-actions in progress must continue / do not start a management action on susceptible
% 		islands if 'no action' lasts one time step
			if all(subActions(islandManaged) == onGoingActions) ...
                    && (all(subActions(susNotManaged) == 1) || subActionDurations(1) > 1)	

% 			iProb is the probability of remaining infested - only for infested islands.
				iProb = zeros(1, nIsland);
				nextRemainingTimes = zeros(1, nIsland);
				nextActionStates = zeros(1, nIsland);
				for iIsland = 1 : nIsland
					subAction = subActions(iIsland);					% sub-action implemented.
					if islandState(iIsland) == 1 % infested island	
						
						if subAction == 1 && season == 0
							iProb(iIsland) = infestationProba(iIsland, 1);
						elseif subAction == 1 && season == 1
							iProb(iIsland) = infestationProba(iIsland, 2);
						elseif subAction == 2
							iProb(iIsland) = infestationProba(iIsland, 3);
						elseif subAction == 3
							iProb(iIsland) = infestationProba(iIsland, 4);							
						end   
					end
					
					if remainingTime(iIsland) == 1 || subActionDurations(subAction) == 1
						% Finishing the sub-action or starting with duration 1
						nextActionStates(iIsland) = 0;
						nextRemainingTimes(iIsland) = 0;
					elseif remainingTime(iIsland) > 1
						% Continuing a sub-action
						nextActionStates(iIsland) = actionState(iIsland);
						nextRemainingTimes(iIsland) = remainingTime(iIsland) - 1;			
					else
						% Starting a new sub-action of duration at least 2.
						nextActionStates(iIsland) = subAction;
						nextRemainingTimes(iIsland) = subActionDurations(subAction) - 1;								
					end
					
				end
				
% 				Array giving the probability of being infested in the next time step for each island. 
%					The first product is the proba of remaining infested, while the second one is the proba of
% 				being reinfested. PNG can play a role or not.
				resultAction = islandState .* iProb + (1-islandState) .* ...
					(1 - prod(1 - bsxfun(@times, [islandState PNG], transmissionProba),2)');
% 			compute transmission probability towards the mainland.
				toMainlandProba = 1 - prod(1 - islandState .* transmissionToMainland);			

%       find the index of each of the 2 ^ nIsland next states
				colArray = retrieve_exact_state_index(parameters, ...
					decomposedBinStates, nextActionStates, nextRemainingTimes, 1 - season);
				colArray(2 ^ nIsland + 1) = nState; % Absorbing State 
				
% 			Calculate the probabilities associated to the 2 ^ nIsland possible future states (2
% 			possibilities of probability 'resultAction(jIsland)' for all jIsland.
				res = ones(nIsland, 2 ^ nIsland);
				for jIsland = 1 : nIsland
					res(jIsland, :) = resultAction(jIsland);										% proba of being infested next
					res(jIsland, indexMatrix(jIsland,:)) = 1 - resultAction(jIsland);	% proba of not being infested next
				end
				probaArray = [prod(res, 1) * (1 - toMainlandProba)   toMainlandProba];

% 			Store the lines for matrix P. 
				count = pCounter(iAction);
				l = length(rowArray);
				pRow{iAction}(count:count + l - 1) = rowArray;
				pCol{iAction}(count:count + l - 1) = colArray;
				pVal{iAction}(count:count + l - 1) = probaArray;
				pCounter(iAction) = count + l;
			end
		end
	end
end
if verbose >= 1, fprintf('Reward matrix and transtion matrix computed\n'); end

end
