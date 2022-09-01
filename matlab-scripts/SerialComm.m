classdef SerialComm < handle
    % This class for connecting to, reading from, and closing the TASKA fingertip sensors
    %
    % Note: It is currently hard-coded for eight sensors (4 IR, 4 baro),
    % but could be adapted for other sensor counts
    %
    % Example usage:
    % TS = TASKASensors;
    % TS.Status.IR or TS.Status.BARO would display IR or baro data,
    % respectively
    %
    % Version: 20210222
    % Author: Tyler Davis
    
    properties
        ARD; COMStr; Status; Ready; Count; 
        DataBuffer;
    end
    
    methods
        function obj = SerialComm(varargin)

            obj.Ready = false;
            
            % Define the structure of your buffer
            % 2 channels * 500 samples @ 1 000 Hz = 500 ms of data
            n_chans = 2;
            n_samples = 500;
            
            obj.DataBuffer = zeros(n_chans, n_samples);
            
            obj.Status.ElapsedTime = nan;
            obj.Status.CurrTime = clock;
            obj.Status.LastTime = clock;
            obj.Count=0;
            
            if nargin
                COMPort=varargin{1};
                init(obj,COMPort);
            else
                init(obj);
            end
        end
        
        function init( obj, varargin)
            if nargin > 1
                COMPort = varargin{1};
                if ~isempty( COMPort)
                    obj.COMStr = sprintf( 'COM%0.0f', COMPort(1));
                end
            else
                devs = getSerialID;
                if ~isempty(devs)
                    COMPort = cell2mat(devs(~cellfun(@isempty,regexp(devs(:,1),'Arduino Uno')),2));
                    if ~isempty(COMPort)
                        obj.COMStr = sprintf('COM%0.0f',COMPort(1));
                    else
                        COMPort = cell2mat(devs(~cellfun(@isempty,regexp(devs(:,1),'USB-SERIAL CH340')),2));
                        if ~isempty(COMPort)
                            obj.COMStr = sprintf('COM%0.0f',COMPort(1));
                        end
                    end
                end
            end
            delete(instrfind('port',obj.COMStr));
            obj.ARD = serialport(obj.COMStr,9600,'Timeout',1); %9600
            configureCallback(obj.ARD,"terminator",@obj.read);
            flush(obj.ARD);
            pause(0.1);
            obj.Ready = true;
        end
        
        function close( obj, varargin)
            if isobject( obj.ARD)
                delete( obj.ARD);
            end
        end
        
        function read(obj,varargin)
            try
                % read data & update status
                obj.Status.Data = sscanf( readline( obj.ARD), '%d %d');
                obj.Status.CurrTime = clock;
                obj.Status.ElapsedTime = etime( obj.Status.CurrTime, obj.Status.LastTime);
                obj.Status.LastTime = obj.Status.CurrTime;
                
                % store data into buffer
                obj.DataBuffer = circshift( obj.DataBuffer, -1, 2);
                obj.DataBuffer( :, end) = obj.Status.Data;
                
                obj.Count=obj.Count+1;
            catch
                disp('Serial communication error!')
            end
        end
        
        function EMG = getEMG( obj, varargin)
            EMG = obj.DataBuffer/1024*5-2.5;
        end

        function [emg, mav_feat, mdf_feat, mnf_feat, rms_feat] = get_feats( obj, varargin)
            temp = obj.DataBuffer/1024*5-2.5;
            temp = temp(1,:); 
            
            emg = temp;
            mav_feat = mean( abs( temp));
            mdf_feat = medfreq( temp);
            mnf_feat = meanfreq( temp);
            rms_feat = rms( temp);
        end
        
        function EMG = getRecentEMG(obj,varargin)
            lastIdx = length(obj.DataBuffer);
            startIdx = lastIdx-obj.Count;
            if startIdx<1
                startIdx=1;
            end
            % - transform digital signal to analog signal
            % - divide by highest value (1024) to normalize signal
            % - multiply by 5 to match the signal recorded by the SpikerShield (0V-5V)
            % - subtract 2.5 V to make the signal zero-centered and undo the
            %   shift introduced by BYB  
            EMG = obj.DataBuffer(:,startIdx:end)/1024*5-2.5;
            obj.Count=0;
        end
    end    
end %class