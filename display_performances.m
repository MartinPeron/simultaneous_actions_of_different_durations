function display_performances(parameters, perf)

% display different models values on a graph.

% Load parameters
computeModels = parameters{4};
IslandNames = parameters{25};
displayCfg = parameters{57};
nIslandArray = parameters{61};
nModel = length(computeModels);

% Constants
figure('color', 'white');
tame = 2;
col(1,:) = [34 72 0]/100;   % RGB code
col(2,:) = [34 1 53]/100;
col(3,:) = [80 35 0]/100;
col(4,:) = ones(1, 3) / tame;
col(5,:) = ones(1, 3) / tame;
col(6,:) = ones(1, 3) / tame;
col(7,:) = ones(1, 3) / tame;
col(8,:) = ones(1, 3) / tame;
col(9,:) = ones(1, 3) / tame;
symbol = {':+' ':+' '-+' 'o' 'o' '^' '+' 'd' '<'};
legCount = 1;
clear legend_names;
legend_names = cell(1);
xlim([min(nIslandArray) - 0.3, max(nIslandArray) + 0.3]);

% Display the values following the asked configuration.
for iModel = 1 : nModel
	parameters{2} = iModel;
	if computeModels(iModel) == 1 && (iModel ~= 2 || displayCfg ~= 2)
		[legend_names, legCount] = draw_model(parameters, perf, ...
			legend_names, legCount, symbol{iModel}, col(iModel, :));
	end
end

% 	 
if legCount ~= 1
	h_legend = legend(legend_names);
	legend boxoff 
	maxYlim = max(ylim);
		ylim([0 Inf]);
	if displayCfg == 1
		set(h_legend,'location','southwest');
		ylabel({'Mean time to infestation of ';'the Australian mainland (years)'}', 'FontWeight','bold');
	elseif displayCfg == 2
		set(h_legend,'location','southeast');
		ylabel({'Relative error to the ';'upper bound model (%)'}', 'FontWeight','bold');
	end
	if nIslandArray(1) == 1   
		% Display the names of islands added.
		set(gca,'XTickLabel','');
		pos = get(gca,'Position');
		set(gca,'XTick',nIslandArray);
		set(gca,'Position',[0.18 .34 pos(3) .55]);
		tl = text(mean(nIslandArray),(min(ylim)-maxYlim)/2.4, 'Active islands');
		set(tl, 'FontSize', 14 ,'FontWeight', 'bold', 'VerticalAlignment', 'top', ...
					 'HorizontalAlignment', 'center');
		t = text(nIslandArray, 0.008*ones(size(nIslandArray)), IslandNames);
		set(t, 'FontSize', 14 ,'HorizontalAlignment','right','VerticalAlignment','top', ...
				'Rotation',45);		
		set(gca,'box','off','color','none'); % remove top and right ticks.
	else
		xlabel('Number of active islands', 'FontSize', 14 , 'FontWeight','bold');
	end	
	set(gca, 'FontSize', 14 , 'FontWeight','bold');
else
	fprintf('\nModels performances are missing.\n');
end
xlim([min(nIslandArray) - 0.1, max(nIslandArray) + 0.1]);

end
