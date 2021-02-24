function simultaneous_actions(maxNIsland, low)
% This is the MATLAB code used for the paper "Selecting simultaneous actions of different durations to optimally
% manage an ecological network" (rev) Martin Péron, Cassie C. Jansen, Chrystal Mantyka-Pringle, Sam
% Nicol, Nancy A. Schellhorn, Kai H. Becker and Iadine Chadès.
% Abstract:
% 1.	Species management requires decision-making under uncertainty. Given a management objective
% and limited budget, managers need to decide what to do, and where and when to do it. A schedule of
% management actions that achieves the best performance is an optimal policy. A popular optimisation
% technique used to find optimal policies in ecology and conservation is stochastic dynamic
% programming (SDP). Most SDP approaches can only accommodate actions of equal durations. However,
% in many situations, actions take time to implement or cannot change rapidly. Calculating the
% optimal policy of such problems is computationally demanding and becomes intractable for large
% problems. Here, we address the problem of implementing several actions of different durations
% simultaneously.
% 2.	We demonstrate analytically that synchronising actions and their durations provide upper and
% lower bounds of the optimal performance. These bounds provide a simple way to evaluate the
% performance of any policy, including rules of thumb. We apply this approach to the management of a
% dynamic ecological network of Aedes albopictus, an invasive mosquito that vectors human diseases.
% The objective is to prevent mosquitoes from colonising mainland Australia from the nearby Torres
% Straits Islands where managers must decide between management actions that differ in duration and
% effectiveness.
% 3.	We were unable to compute an optimal policy for more than seven eight islands out of 17, but
% obtained upper and lower bounds for up to 12 13 islands. These bounds are within 16% of an optimal
% policy.  We used the bounds to recommend managing highly populated islands as a priority.
% 4.	Our approach calculates upper and lower bounds for the optimal policy by solving simpler
% problems that are guaranteed to perform better and worse than the optimal policy, respectively. By
% providing bounds on the optimal solution, the performance of policies can be evaluated even if the
% optimal policy cannot be calculated. Our general approach can be replicated for problems where
% simultaneous actions of different durations need to be implemented.
%
% INPUT:
% simultaneous_actions(maxNIsland, Low)
% maxNIsland (1-12): maximum number of islands to manage.
%              - If maxNIsland > 7, Since the exact model likely is computationally intractable 
%              on a standard desktop, it is deactivated (this can be modified in the section 
%              "General Parameters" below). Only upper and lower bound models are calculated.
%              - If maxNIsland > 12, it becomes computationally intractable to
%              solve the upper and lower bound models on a standard desktop.
% Low : if Low =1 the probailities of transmission of mosquitoes between islands are low;
%       if Low != 1 the probailities of transmission are high (as defined in Peron et al)
% EXAMPLE:
%   simultaneous_actions(3,0)  (Solves models for 1-3 islands, with high transmission probailities.)



%% Parameters that can be changed by users
minNIsland = 1;	% min number of islands <= maxNIsland
% Durations of each sub-action (in time steps): [Do nothing, light management, strong management]
subActionDurations = [1 6 6];				% Real-world mosquito problem.
% subActionDurations = [2 5 7];			% Hard case (durations do not share divisors)
% subActionDurations = [3 6 6];			% Easy case (durations share a lot of divisors)
budget = 3;     % 6-month budget >=0
subActionCosts = [0 1 2]; % costs of implementing sub-actions: [Do nothing, light management, strong management].

%% General Parameters
if (maxNIsland >= 8 && maxNIsland <13)
	display('The exact model likely is intractable. Upper and Lower bound calculation only. ');
	computeModels = [0 1 1];
elseif maxNIsland >= 13
	display('It is unlikely that your computer will be able to solve this problem.')
	display('Please use maxNIsland < 13')
	return
else
	display('Computing the exact, lower and upper bound solutions')
	computeModels = [1 1 1];
end
% Note: one may select computeModels = [1 1 0]; but not [1 0 1], because the upper bound model
% requires the lower bound model to generate transition matrix.

discount = 0.99999999;						% 6-month discount rate.

%%  Display
verbose = 1;									% (0-2) Prints information about data & computation progress.
displayConfig = [1 0];				% Display [performances, relative error] (0 or 1).
profiler = 0;									% Activate profiler or not.
modelNames = {'Exact MDP model' 'Upper bound MDP model' 'Lower bound MDP model' ...
	'Unlimited budget' 'No actions' 'Highest population first' ...
	'Closest first' 'Easiest first' 'Highest transmission first'};


%% Fill variable 'parameters'
nSubActions = size(subActionDurations, 2);
parameters = {0, 0, discount, computeModels, 0, budget, 0, ...
	nSubActions, 0, modelNames, subActionDurations, subActionCosts, 0, 0, 0, ...
	0, 1};
parameters{35} = computeModels;
parameters{43} = 1;  % Transmission from PNG allowed (1) or not (0).
parameters{49} = verbose; parameters{59} = low;


%% Initialisations
RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock))); % randomness generator.
nModel = length(computeModels);
format('long');
[perf, R, P] = deal(cell(1, nModel));   % Performances (values), reward and transition matrices.
if profiler == 1, profile clear; profile on; end
nIslandArray = minNIsland : maxNIsland; parameters{61} = nIslandArray;

%% Generate and solve MDP models - start loop on #islands and models
for nIsland = nIslandArray					% Loop on islands
	parameters{1} = nIsland;
	
	% Load and display information on islands
	parameters = load_islands_features(parameters);
	
	for iModel = 1 : 3	% Loop over different models to calculate their performance
		if computeModels(iModel) == 1
			parameters{2} = iModel;
			if verbose >= 0
				fprintf('\n\n-----------------------------------------------------------');
				fprintf('\nGenerating and solving the %s \n\n', modelNames{iModel});
			end
			if iModel < 3 && verbose >= 1
				fprintf('- Generate the transition and reward matrices:\n');
			end
			if iModel == 1          % exact model - sparse matrix (many irrelevant action-state pairs)
				[parameters, R{iModel}, row{iModel},  ...
					col{iModel}, val{iModel}] = generate_exact_model(parameters);
			elseif iModel == 2      % generate bound models
				[parameters, R{2}, P{2}, R{3}, P{3}] = ...
					generate_bound_model(parameters);   % full matrices (not sparse)
			end
			
			% Solve the mosquito problem
			if verbose >= 1
				fprintf('\n- Find the optimal policy and value (MDPSolve):');
			end
			
			% 1) Format matrices for MDPSOLVE - only select the non-zero columns of the transition matrix
			nS = parameters{14}; % number of states
			nA = parameters{15}; % number of actions
			X = rectgrid([0:nA-1]',[1:nS]'); % raises error if MDPSOLVE is not added to path - see readme
			% store transition matrix with rows representing future states.
			Rt = R{iModel}(:);
			nzIndices = []; % indices of non-zero columns.
			nCols = 0; % total number of non-zero columns
			if iModel == 1			% exact model
				bigP = sparse(nS, size(X,1));  % sparse matrix for the exact model
			else								% bound models.
				for iAction = 1 : nA
					% For each action, detect non-zero columns (i.e. states for which this action is defined)
					combi = logical(sum(P{iModel}{iAction}, 2));
					nzIndices = [nzIndices combi];
					nCols = nCols + sum(combi);
					% Then, replace P with its new version (deprived of useless states).
					P{iModel}{iAction} = P{iModel}{iAction}(combi, :);
				end
				nzIndices = logical(nzIndices);
				bigP = zeros(nS, nCols);      % full matrix for the bound models.
			end
			
			first = 1; % first index of a block of non-zero columns (for bound models only).
			for iAction = 1 : nA
				% Fill 'bigP' with the transition matrices per action
				columns = (iAction-1)*nS + 1 : iAction*nS;
				if iModel == 1			% exact model - sparse matrix
					bigP(:, columns) = sparse(row{iModel}{iAction}, ...
						col{iModel}{iAction}, val{iModel}{iAction}, ...
						parameters{14}, parameters{14})';
				else								% bound models - full matrix
					last = first + size(P{iModel}{iAction}, 1) - 1;
					bigP(:, first : last) = full((P{iModel}{iAction})');
					first = last + 1;
					P{iModel}{iAction} = 0;
				end
			end
			if iModel == 1 % exact model - only keep non-zero columns.
				nzIndices = logical(sum(bigP, 1));
				bigP = bigP(:,nzIndices);
			end
			X = X(nzIndices, :);
			
			clear model;  model.name = 'Mosquitoes';
			model.R = Rt(nzIndices); model.Ix = getI(X,2);
			model.d = discount; model.P = bigP;
			
			% 2) Solve MDP with MDPSOLVE
			mdpResults = mdpsolve(model);
					
			% 3) Store MDP value (i.e. performance)
			value = mdpResults.v;
			% The initial action is: X(mdpResults.Ixopt, 1) + 1;
			
			perf{iModel} = [perf{iModel} value(parameters{71})];     % 71 is the initial state
			if verbose >= 1,
				fprintf('--> MDP Value: %.15f\n', perf{iModel}(end));
			end
		end
	end	 % loop on models
	
	%% Print performances.
	if sum(computeModels) > 0.5
		fprintf('\n\n-----------------------------------------------------------\n');
		fprintf('Values of the MDP models (to maximise) for %i island(s):\n', nIsland);
		format long e
		for iModel = 1 : 3
			if computeModels(iModel) == 1
				fprintf('   - %s: %.15f\n', modelNames{iModel}, perf{iModel}(end));
			end
		end
		if sum(computeModels) > 0.5
			fprintf('-----------------------------------------------------------\n\n');
		end
	end	
	if length(nIslandArray) > 1
		clear P; clear R; clear bigP; clear model;  % Free some space
	end
	
end	 % loop on islands


%% Display results

if displayConfig(1) == 1 && ~isempty(nIslandArray)
	% 	Display the performances of different models
	parameters{57} = 1;
	display_performances(parameters, perf);
	movegui('north');
end
if displayConfig(2) == 1 && ~isempty(nIslandArray)
	% 		Relative error to the upper bound
	if ~isempty(perf{2})
		fprintf('\nRelative error to the upper bound.');
		parameters{57} = 2;   % Relative error graph.
		display_performances(parameters, perf);
		movegui('northeast');
	else
		fprintf('\nUpper bound missing.\n');
	end
end

if profiler == 1, profile viewer; end  % Profiler
end