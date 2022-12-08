% EMG Feature Visulizer
% Author: Fredi Mino
% Date: 08-25-2022
% Latest Version: https://github.com/Fredware/emg-fatigue.git

%% Reset workspace
try
    uno.close;
catch
end
clear all; 
clc;

%% Establish connection with Arduino
% Pass COM port number as argument to bypass automatic connection.
[uno, ~] = connect_board();

%% Workspace setup
fs = 1000; % Hz

% figure parameters
n_chans = 1; % emg signals
n_feats = 5; % non-emg signals
[fig, animated_lines, t_max, t_min] = initialize_figure(n_chans, n_feats);

% data storage parameters
data_buff_len = 60*fs; % seconds * fs
[data, features, data_idx, features_idx, prev_sample, prev_timestamp] = initialize_data_structures(data_buff_len, n_feats);
t_data = [0];
t_features = [];

% task configuration parameters
task_period = 4; %seconds
idle_period = 2; %seconds

% feature calculation parameters
mav_win_len = 300; %samples
mdf_win_len = 500; %samples
largest_win_len = max([mav_win_len, mdf_win_len]); 

%% Real-time plotting
% Run until figure closes
while( ishandle(fig))
    pause(0.0111111) % pause to avoid callback overload
    try
        emg = uno.getRecentEMG; % value range: [-2.5:2.5]; length range: [1:buffer length]
        if ~isempty(emg)
            [~, new_samples] = size(emg); % count new samples
            data( :, data_idx:data_idx + new_samples - 1) = emg(1,:); % adds new samples to the data vector
            data_idx = data_idx + new_samples; % update index for inserting future samples
            features_idx = features_idx + 1;
        end
    catch
        disp("Data Acquisition: FAILED")
    end
    
    % Ensure buffer has enough data to compute features
    if ~isempty(emg) && data_idx > largest_win_len
        timestamp = (data_idx - 1) / fs; % compute time in seconds for the plot
        try
            % compute time-domain features
            [mav_feat, rms_feat] = compute_amplitude_feats(data(:, data_idx-mav_win_len: data_idx-1));
            features( 1, features_idx) = mav_feat;
            features( 2, features_idx) = rms_feat;

            % update task indicator
            if mod(timestamp, task_period)/ idle_period > 1
                task_indicator = 1;
            else
                task_indicator = 0;
            end
            features( 3, features_idx) = task_indicator;
            
            % compute frequency-domain features only while performing task 
            if task_indicator > 0
                signal = data(:, data_idx-mdf_win_len: data_idx-1);
                features( 4, features_idx) = meanfreq( signal, fs);
                features( 5, features_idx) = medfreq( signal, fs);
            else
                features( 4, features_idx) = 0;
                features( 5, features_idx) = 0;
            end
        catch
            disp("Feature Extraction: FAILED")
        end

        % synchronize calculated features with the most recent sample
        t_features(features_idx) = timestamp;
        
        % append datapoints to the plot
        [t_max, t_min] = update_figure(animated_lines, timestamp, data, features, prev_sample, data_idx, features_idx, t_max, t_min);

        % update book-keeping variables
        prev_timestamp = timestamp;
        prev_sample = data_idx;
    end
end

%% Plot the data and control values from the most recent time running the system
data_table = timetable(data(:,1:data_idx-1)', 'SampleRate', fs);
data_table =  renamevars(data_table, "Var1", "sEMG");

features_table = timetable((features(:, 1:length(t_features)))','RowTimes', seconds(t_features'));
features_table = splitvars(features_table);
features_table = renamevars(features_table, ["Var1_1", "Var1_2", "Var1_3", "Var1_4", "Var1_5"], ["MAV", "RMS", "Cue", "Mean Frequency", "Median Frequency"]);
features_table = rmmissing(features_table);

full_table = synchronize(data_table, features_table, 'union', 'linear');

subplot(3,1,1)
scaling_factor = max(full_table.sEMG);

plot(full_table.Time, full_table.sEMG)
hold on
plot(full_table.Time, scaling_factor*full_table.Cue, 'r--')
hold off

legend(["sEMG", "Cue"])
ylim([-1.1*scaling_factor 1.1*scaling_factor])
grid on

subplot(3,1,2)
scaling_factor = max(full_table.RMS);
plot(full_table.Time, full_table{:, 2:3})
hold on
plot(full_table.Time, scaling_factor*full_table.Cue, 'r--')
hold off

legend([full_table.Properties.VariableNames(2:3), "Cue"])
ylim([-0.1*scaling_factor 1.1*scaling_factor])
grid on

subplot(3,1,3)
scaling_factor = max(full_table.("Median Frequency"));
plot(full_table.Time, full_table{:, 5:6})
hold on
plot(full_table.Time, scaling_factor*full_table.Cue, 'r--')
hold off

legend([full_table.Properties.VariableNames(5:6), "Cue"])
ylim([-0.1*scaling_factor 1.1*scaling_factor])
grid on

%% Terminate serial connection before closing MATLAB
uno.close;
disp('Board Connection: TERMINATED')

%% Save data to file for offline analysis
raw_data = data(1:data_idx-1);