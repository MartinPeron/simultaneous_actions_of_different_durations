function [parameters, RUpper, PUpper, RLower, PLower] = ...
		generate_bound_model(parameters)

% Compute the matrix R (reward) and the matrix P for the lower and upper bound models. 

% Load parameters
nIsland = parameters{1};
discount = parameters{3};
computeModels = parameters{4};	
nSubActions = parameters{8};
subActionDurations = parameters{11};
beginningSeason = parameters{17};
infestationProba = parameters{36};
fullMatrices = parameters{37};		
transmissionToMainland = parameters{41};
verbose = parameters{49};

% Caculated the actions within the budget, their duration in the lower bound model and also a
% mtaching of states number with the states of states of each islands.

nState = 2 * 2 ^ nIsland + 1;				
parameters{14} = nState;
parameters{71} = 2 ^ nIsland * (1 + beginningSeason);    % initial state 

[feasibleActions, indexMatrix, subStates, colonisation] = initialise_bounds(parameters);
nAction = size(feasibleActions, 1); % number of feasible actions
parameters{15} = nAction;
parameters{18} = feasibleActions;
parameters{27} = subStates;
% 	In the upper bound model, all actions have the same durations, equal to the greatest common
% 	divisor of all possible sub-actions.
if computeModels(2) == 1 
	UpperBoundDuration = subActionDurations(1);  % First sub-action
else
	UpperBoundDuration = 1;
end
for iSubAction = 2 : nSubActions						% gcd for each sub-action
	UpperBoundDuration = gcd(UpperBoundDuration, subActionDurations(iSubAction));   
end
parameters{19} = UpperBoundDuration;

% Calculating the discount factor for each actions (In a semi-MDP, the discount may depend on
% actions because actions differ in durations.)
upperDiscountArray = (discount .^ UpperBoundDuration) * ones(nAction, 1);
parameters{20} = upperDiscountArray;
lowerDiscountArray = discount .^ feasibleActions(:, nIsland + 2);
parameters{21} = lowerDiscountArray;
	
if verbose >= 1, fprintf('Number of states / actions : %i / %i \n', nState, nAction); end
if fullMatrices == 0
	pRow = cell(1,nAction);     % rows of P for each actions
	pCol = cell(1,nAction);     % columns of P for each actions  
	pVal = cell(1,nAction);     % values of P for each actions  
	pCounter = ones(1,nAction); 
end

RLower = zeros(nState, nAction);			% R matrix lower bound
PUpper = cell(1, nAction);						% P matrix upper bound
PLower = cell(1, nAction);						% P matrix lower bound


res = zeros(2 ^ nIsland, nIsland); % useful to calculate colonisation probabilities
% res2 = zeros(2 ^ nIsland, nIsland); % useful to calculate colonisation probabilities


% Fill in R
reward = 0.5;	 
% Reward of half a year (one time step), received when mainland Australia is not infested. The value
% of each policy (cumulated reward) with discount 1 will be the mean time before infestation.

RUpper = reward * ones(nState, nAction);			% R matrix upper bound
RUpper(nState, :) = 0;					% the last state gets reward 0 ('mainland infested')
            
for iAction = 1 : nAction  
% 	iAction
% Start by calculating the one-step transition matrix 'PAction' for action 'iAction'.
	if fullMatrices == 1
		PAction = zeros(nState);
	end
	
	for iState = 1 : nState
	% The following command decomposes iState into its components, namely 
	% the islands' states followed by the season.

		stateInfo = subStates(iState, :);
		season = stateInfo(nIsland + 1);
		islandState = stateInfo(1:nIsland);

		if iState == nState   % absorbing state referring to 'mainland infested'.
				if fullMatrices == 0
					pRow{iAction}(pCounter(iAction)) = iState;
					pCol{iAction}(pCounter(iAction)) = iState;
					pVal{iAction}(pCounter(iAction)) = 1;	
					pCounter(iAction) = pCounter(iAction) + 1;
				else
					PAction(iState, iState) = 1;
				end
		else									% All other states. Loop on actions followed by a loop on future states.		

			if fullMatrices == 0
		% 	Pre-fill arrays for the sparse matrix.
				rowArray = iState * ones(1, 2 ^ nIsland + 1);
				colArray = [(1 : 2 ^ nIsland) 0]; %last elt modified a few lines further on.
			end
		

% 		iProb is the probability of remaining infested - only for
% 		the infested islands.
			iProb = zeros(1, nIsland);
			for iIsland = 1 : nIsland
				if islandState(iIsland) == 1 % infested island	
					subAction = feasibleActions(iAction, iIsland);					% sub-action implemented.
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
			end

% 		Array giving the probability of being infested in the next time step for each island. 
%		The first product is the proba of remaining infested, while the second one is the proba of
% 		being reinfested. Mosquitoes can colonise from PNG if PNG = 1.
			resultAction = islandState .* iProb + colonisation(iState, :);
			toMainlandProba = 1 - prod(1 - islandState .* transmissionToMainland);			

% 		Calculate the probabilities associated to the 2 ^ nIsland possible future states (2
% 		possibilities of probability 'resultAction(jIsland)' for all jIsland.

			for jIsland = 1 : nIsland
				res(:, jIsland) = resultAction(jIsland);    % proba of being infested next
			end		
			res2 = 1-res(indexMatrix);
			res(indexMatrix) = res2;
			probaProduct = prod(res, 2);
			
			seasonShift = (1 - season) * 2 ^ nIsland;     % state numbers depend on the season.
%			Store the lines for matrix P. 
			if fullMatrices == 0
				probaArray = [probaProduct * (1 - toMainlandProba)   toMainlandProba]; 
				colArray(2 ^ nIsland + 1) = nState - seasonShift; % Absorbing State
				count = pCounter(iAction);
				l = length(rowArray);
				pRow{iAction}(count:count + l - 1) = rowArray;
				pCol{iAction}(count:count + l - 1) = colArray + seasonShift;
				pVal{iAction}(count:count + l - 1) = probaArray;
				pCounter(iAction) = count + l;
			else
				PAction(iState, (seasonShift + 1) : (seasonShift + 2 ^ nIsland)) = ...
					probaProduct * (1 - toMainlandProba);
				PAction(iState, nState) = toMainlandProba;
			end
		end
	end
	if fullMatrices == 0
		PAction = sparse(pRow{iAction}, pCol{iAction}, pVal{iAction}, nState, nState);
	end
	
	% Compute matries for the bound models
	
	if computeModels(2) == 1			 % Compute matrices for upper bound model
		if UpperBoundDuration == 1
			PUpperTemp = PAction;			
			
		else
	% 	Matrix P: PAction raised to the power of the duration.
			PUpperTemp = PAction ^ UpperBoundDuration;    % Improve if too slow? (binary)
			
	% 	Matrix R: Cumulative expected rewards over the course of the action
			cumulativeReward = RUpper(:, iAction);
			rewardVector = RUpper(:, iAction);
			for iStep = 1 : UpperBoundDuration - 1
				rewardVector = discount * PAction * rewardVector;
				cumulativeReward = cumulativeReward + rewardVector;		
			end
			RUpper(:, iAction) = cumulativeReward;
		end
		
		if subActionDurations(1) == 1
			% when 'no action' lasts one time step, we can forbid actions on susceptible islands
			% without changing the value. 
			stateIndices = [];
			for iState = 1 : nState			
				if any(subStates(iState, 1:nIsland) == 0 & feasibleActions(iAction, 1:nIsland) ~= 1)
					% states where susceptible islands are managed
					stateIndices = [stateIndices iState];  
				end		
			end
			PUpperTemp(stateIndices, :) = 0;  % forbid actions on susceptible islands
		end
            
		PUpper{iAction} = sparse(PUpperTemp);	
	else
		PUpper = cell(1);
	end

	if computeModels(3) == 1				% Compute matrices for lower bound model
% 	Matrix P: PAction raised to the power of the duration.
		PLowerTemp = PAction ^ feasibleActions(iAction, end);
		
		if subActionDurations(1) == 1
			% forbid actions on susceptible islands (only when 'no action' lasts one time step)			
			stateIndices = [];
			for iState = 1 : nState			
				if any(subStates(iState, 1:nIsland) == 0 ...
						& feasibleActions(iAction, 1:nIsland) ~= 1)
					% states where susceptible islands are managed
					stateIndices = [stateIndices iState];  
				end		
			end
			PLowerTemp(stateIndices, :) = 0;  % forbid actions on susceptible islands
		end
		PLower{iAction} = sparse(PLowerTemp);
						
		
		if UpperBoundDuration == 1    % means cumulativeReward & rewardVector are not declared.
			cumulativeReward = RUpper(:, iAction);
			rewardVector = RUpper(:, iAction);
		end
% 	Matrix R: Cumulative expected rewards over the course of the action
		for iStep = UpperBoundDuration : feasibleActions(iAction, end) - 1  
			rewardVector = discount * PAction * rewardVector;
			cumulativeReward = cumulativeReward + rewardVector;		
		end
		RLower(:, iAction) = cumulativeReward;
		
	else
		RLower = [];
		PLower = cell(1);
	end
end
	
if verbose >= 1 && computeModels(2) == 1
	fprintf('Reward matrix and transtion matrix computed (Upper bound)\n')
end
if verbose >= 1 && computeModels(3) == 1
	fprintf('Reward matrix and transtion matrix computed (Lower bound)\n')
end

end
