%% Reset workspace
try
    uno.close;
catch
end
clear all; 
clc;

%% Establish connection with Arduino
% Pass COM port number as argument to bypass automatic connection.
[uno, uno_connected] = connect_board();

%% Plotting in real time
% SET UP PLOT
n_chans = 1;
n_feats = 5;

[fig, animated_lines, t_max, t_min] = initialize_figure(n_chans, n_feats);

% INITIALIZATION
[data, features, data_idx, features_idx, prev_sample, prev_timestamp] = initialize_data_structures(60e3, n_feats);
t_data = [0];
t_features = [];
pause(0.5)

tic

% Run until time is out or figure closes
while( ishandle(fig))
    % SAMPLE ARDUINO
    try
        emg = uno.getRecentEMG; % value range: [-2.5:2.5]; length range: [1:buffer length]
        if isempty(emg)
            pause(0.0111111)
        else
            [~, new_samples] = size(emg); % how many samples were received
            data( :, data_idx:data_idx + new_samples - 1) = emg(1,:); % adds new EMG data to the data vector
            data_idx = data_idx + new_samples; %update sample count
            features_idx = features_idx + 1;
        end
    catch
        disp("Data acquisition: FAILED")
    end

    if ~isempty(emg) && data_idx > 300
        % UPDATE timestamp
        timestamp = toc; 
        % CALCULATE FEATURES
        try
            [mav_feat, rms_feat] = compute_amplitude_feats(data(:, data_idx-300: data_idx-1));

            features( 1, features_idx) = mav_feat;
            features( 2, features_idx) = rms_feat;
            features( 3, features_idx) = 3;
            features( 4, features_idx) = 4;
            features( 5, features_idx) = 5;
                       
        catch
            disp('Something broke in your code!')
        end

%         t_features(features_idx) = timestamp;
%         tempStart = t_data(end);
%         t_data( prev_sample:data_idx-1) = linspace( tempStart, timestamp, new_samples);
        
        % UPDATE PLOT
        [t_max, t_min] = update_figure(animated_lines, timestamp, data, features, prev_sample, data_idx, features_idx, t_max, t_min);

        prev_timestamp = timestamp;
        prev_sample = data_idx;
    end
end
%% Plot the data and control values from the most recent time running the system
% finalPlot(data, features, t_data, t_features)

%% close the arduino serial connection before closing MATLAB
uno.close;
disp('Board connection: TERMINATED')
%% save data to file
raw_data = data(1:data_idx-1);