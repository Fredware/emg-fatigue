%% test for emg electrodes through arduino connection
try
    uno.close;
catch
end
clear all; clc;
%% Section 1: Set Up Virtual Environment (MuJoCo)
% You should have MuJoCo open with a model loaded and running before
% starting this code!  If your code is crashing during this section, try
% the following: Close MuJoCo, Open MuJoCo, Open Model, Play MuJoCo, Run
% MATLAB Code.

[model_info, movements,command, selectedDigits_Set1, selectedDigits_Set2, VREconnected] = connect_hand;

%% connect to arduino
[uno, ArduinoConnected]=connect_ard1ch();% can put the comport number in as an argument to bypass automatic connection, useful if more than one arduino uno is connected

%% Plot (and control) in real time

% SET UP PLOT
[fig, animatedLines, t_max, t_min] = plotSetup1ch();

% INITIALIZATION
[data, control, data_idx, control_idx, prev_sample, prev_timestamp] = init1ch();
t_data = [0];
t_control = [];
pause(0.5)

tic

while( ishandle(fig)) %run until time is out or figure closes
    % SAMPLE ARDUINO
    try
        emg = uno.getRecentEMG; % values returned will be between -2.5 and 2.5 , will be a 1 x up to 330
        if ~isempty(emg)
            [~,new_samples] = size(emg); % helps to know how much more data was received
            data( :, data_idx:data_idx + new_samples - 1) = emg(1,:); % adds new EMG data to the data vector
            data_idx = data_idx + new_samples; %update sample count
            control_idx = control_idx + 1;
        end
    catch
    end

    if ~isempty(emg)
        % UPDATE timestamp
        timestamp = toc; 
        % CALCULATE CONTROL VALUES
        try
            %% start of your code
            [emg_feat, mav_feat, mdf_feat, mnf_feat, rms_feat] = uno.get_feats;
            
%             control( 1, control_idx) = mav_feat;
%             control( 1, control_idx) = mdf_feat;
            control( 1, control_idx) = mnf_feat;
%             control( 1, control_idx) = rms_feat;
            
            %% end of your code
            
        catch
            disp('Something broke in your code!')
        end
        t_control(control_idx)=timestamp;
        tempStart = t_data(end);
        t_data(prev_sample:data_idx-1)=linspace(tempStart,timestamp,new_samples);
        % UPDATE PLOT
        [t_max, t_min] = updatePlot1ch(animatedLines, timestamp, data, control, prev_sample, data_idx, control_idx, t_max, t_min);

        % UPDATE HAND
        if(VREconnected) %if connected
            status = updateHand(control, control_idx, command, selectedDigits_Set1, selectedDigits_Set2);
        end
        prev_timestamp = timestamp;
        prev_sample = data_idx;
    end
end
%% Plot the data and control values from the most recent time running the system
finalPlot(data,control,t_data,t_control)

%% close the arduino serial connection before closing MATLAB
uno.close; 