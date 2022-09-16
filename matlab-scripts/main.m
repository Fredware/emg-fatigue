%% Reset workspace
try
    uno.close;
catch
end
clear main; 
clc;

%% Establish connection with Arduino
% Pass COM port number as argument to bypass automatic connection.
[uno, uno_connected] = connect_board();

%% Plotting in real time
% SET UP PLOT
[fig, animated_lines, t_max, t_min] = plotSetup1ch(n_chans = 1, n_feats=5);

% INITIALIZATION
[data, features, data_idx, features_idx, prev_sample, prev_timestamp] = init1ch();
t_data = [0];
t_features = [];
pause(0.5)

tic

% Run until time is out or figure closes
while( ishandle(fig)) 
    % SAMPLE ARDUINO
    try
        emg = uno.getRecentEMG; % values returned will be between -2.5 and 2.5 , will be a 1 x up to 330
        if ~isempty(emg)
            [~, new_samples] = size(emg); % helps to know how much more data was received
            data( :, data_idx:data_idx + new_samples - 1) = emg(1,:); % adds new EMG data to the data vector
            data_idx = data_idx + new_samples; %update sample count
            features_idx = features_idx + 1;
        end
    catch
    end

    if ~isempty(emg)
        % UPDATE timestamp
        timestamp = toc; 
        % CALCULATE FEATURES
        try
            [emg_feat, mav_feat, mdf_feat, mnf_feat, rms_feat] = uno.get_feats;
            
            features( 1, features_idx) = mav_feat;
            features( 2, features_idx) = rms_feat;
            features( 3, features_idx) = mdf_feat;
            features( 4, features_idx) = mnf_feat;
                       
        catch
            disp('Something broke in your code!')
        end

        t_features(features_idx)=timestamp;
        tempStart = t_data(end);
        t_data( prev_sample:data_idx-1) = linspace( tempStart, timestamp, new_samples);
        
        % UPDATE PLOT
        [t_max, t_min] = updatePlot1ch(animated_lines, timestamp, data, features, prev_sample, data_idx, features_idx, t_max, t_min);

        prev_timestamp = timestamp;
        prev_sample = data_idx;
    end
end
%% Plot the data and control values from the most recent time running the system
finalPlot(data,features,t_data,t_features)

%% close the arduino serial connection before closing MATLAB
uno.close;
%% save data to file
raw_data = data(1:data_idx-1);