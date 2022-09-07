function [fig_handle, line_handles, t_max, t_min] = plotSetup1ch()
    %
    % PLOTSETUP1CH  sets up plots to visualize EMG input and the control
    % value calculated later in EMG_live. 
    % 
    % This function sets up one graph for a single channel EMG input, 
    % and one for the control graph. (two graphs total)
    %
    % figHandle is the Figure handle for the graphs generated. 
    %
    % lineHandles are the handles for the animated lines that are used to
    % update the graphs in updatePlot1ch.m. It makes it so the graphs can 
    % be shown in real time
    % 
    % Tmax is the max xlimit of the graph, initially set to 30
    % seconds
    % 
    % Tmin is the min xlimit of the graph, initially set to 0
    % both Tmax and Tmin are dynamically updated in updatePlot1ch.m
    
    n_chans = 1; %number of input channels 
    n_dofs = 4; %number of degrees of freedom controlled
    n_plots = n_chans + n_dofs;
    t_max = 30;
    t_min = 0;

    y_labels = cell( 1, n_plots);
    axis_handles=cell( 1, n_plots);
    line_handles=cell( 1, n_plots);
    
    for i = 1:n_chans
        y_labels{i} = strcat('v', num2str(i), ' (V)');
        y_labels{i + n_chans} = strcat('c', num2str(i));
    end
    
    fig_handle = figure('units', 'normalized'); %open figure
    set( fig_handle, 'outerposition', [0, 0, 0.5, 1])%moveFigure to left half of screen
    
    for i = 1:n_plots
        axis_handles{i} = subplot(n_plots, 1, i);
        line_handles{i} = animatedline;
%         ylim([-1.2,1.2])
        xlim([0 t_max])
        ylabel(y_labels{i})
        xticks([]);
%         if i > n_chans
%             ylim([-0.25,1.25]);
%             yticks([0,1]);
%             yticklabels({'OPEN','CLOSE'})
%         else
%             ylim([-3.0, 3.0]);
%         end
        
    end
    linkaxes([axis_handles{:}],'x')
    xlabel('Time (seconds)')
end