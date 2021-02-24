function parameters = load_islands_features(parameters)

% Load and prepare data for the MDPs. 

nIsland = parameters{1};
verbose = parameters{49};
low = parameters{59};

% The following line should be commented if no island features has been recently changed.
% [allIsland] = BBN_Island_Mgmt(0, 0);
% Otherwise the variable allIsland is in the file 'IslandData.mat'.

load IslandData.mat;


allIsland = Sort_Islands(allIsland); %#ok<*NODEF>
names = cell(1, nIsland);
% for i = 1:nIsland, names{i} = allIsland(i).name; end
names{1} = allIsland(1).engName;
for i = 2:nIsland, names{i} = ['+' allIsland(i).engName ' (' num2str(i) ')']; end
parameters{25} = names;
infestationProba = zeros(nIsland, 4);
for i = 1:nIsland
	infestationProba(i, :) = max(0,min(1, [allIsland(i).annualInfestationProb(1), ...
		allIsland(i).annualInfestationProb(2), allIsland(i).annualInfestationProb(3), ...
		allIsland(i).annualInfestationProb(4)]));
% 	infestationProba(i, :) = allIsland(i).annualInfestationProb(1) * ones(1,4);
end

if verbose >= 2
	fprintf('\n\n------------------------------------------------------------------------------------\n');
	fprintf('Input data: Effectiveness of the management actions (%i islands):', nIsland);
	fprintf('\n    name             Nothing - Dry   Nothing - Wet ');
	fprintf('     Mgmt 1         Mgmt 2       \n');

	% Display effectiveness of management actions
	for i = 1:nIsland
		fprintf(' % 13s  %15f %15f %15f %15f\n', allIsland(i).engName, ...
			1 - infestationProba(i, :));
	end
	fprintf('------------------------------------------------------------------------------------\n');
end

distPNG(1,nIsland) = 0;
distMain(1,nIsland) = 0;
distIsl(nIsland,nIsland) = 0;

for i = 1 : nIsland
	distPNG(i) = allIsland(i).distance(19);
	distMain(i) = allIsland(i).distance(1);
	for j = 1 : nIsland
		distIsl(i,j) = allIsland(i).distance(j+1);
	end
end

			
% transmissionProba: the element (i,j) is the proba that island j transmits
% the mosquito to i; on row i are the transmission probabilities towards i.
for i = 1 : nIsland
	if low == 1   % Low transmission probabilities 
		shape = 5 * 10 ^ 4;
		PNGPop = 5000;
		AusPop = 100;
		constant = 5 * 10 ^ - 8;
	elseif low == 0   % High transmission probabilities 
		shape = 5 * 10 ^ 4;
		PNGPop = 5000;
		AusPop = 150;
		constant = 10 ^ - 7;
	end
	transmissionFromPNG(i, 1) = constant * PNGPop * allIsland(i).population / (1 + (distPNG(i) / shape) ^ 2); %#ok<*AGROW>
	transmissionToMainland(i) = constant * AusPop * allIsland(i).population / (1 + (distMain(i) / shape) ^ 2);

	for j = 1 : nIsland
		popFactor = allIsland(i).population * allIsland(j).population;
		transmissionProba(i, j) = (i ~= j) * constant * popFactor ...
			/ (1 + (distIsl(i, j) / shape) ^ 2);
	end
end
	
% Add PNG array to transmissionProba.
transmissionProba = [transmissionProba transmissionFromPNG];

if any(any(transmissionProba > 1)) || any(any(transmissionProba < 0)) || ...
		any(any(transmissionToMainland > 1)) || any(any(transmissionToMainland < 0))
	transmissionProba = max(0, min(1, transmissionProba));
	transmissionToMainland = max(0, min(1, transmissionToMainland));
	fprintf('Probabilities altered to be between 0 and 1. \n');
end

% Prioritisation
prioritisation = zeros(4, nIsland);  % matrix of preferred islands for 4 criteria.
for iIsland = 1 : nIsland
	populations(1, iIsland) = allIsland(iIsland).population;
	disToMain(1, iIsland) = allIsland(iIsland).distance(1);
end

% Sort islands for criteria "largest".
[~, ranks] = sort(populations);  % Get the ranking of each island.
prioritisation(1,:) = fliplr(ranks);   % Decreasing order instead of increasing.

% Sort islands for criteria "closest".
[~, ranks] = sort(disToMain);
prioritisation(2,:) = ranks;

% Sort islands for criteria "easiest".
[~, ranks] = sort(infestationProba(:, 4)');
prioritisation(3,:) = ranks;

% Sort islands for criteria "most dangerous".
[~, ranks] = sort(1-transmissionToMainland);
prioritisation(4,:) = ranks;

parameters{36} = infestationProba;
parameters{40} = transmissionProba;
parameters{41} = transmissionToMainland;
parameters{66} = prioritisation;

end


