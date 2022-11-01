function varargout = interface(request,params,varargin)
% Interface manager for dealing with both DAQ and Datapixx and Debug modes
switch request
    case "Init"
        if strcmp(params.interface, 'DAQ')
            DAQ('Init')
        elseif strcmp(params.interface,'datapixx')
            params = StartDatapixxADC(params);
        elseif strcmp(params.interface,'debug')
            disp('Starting in debug mode')
        end
        varargout{1} = params;
    case "GiveReward"
        if strcmp(params.interface, 'DAQ')
            params = GiveReward_DAQ(params,varargin{1},varargin{2});
        elseif strcmp(params.interface, 'datapixx')
            params = GiveReward_datapixx(params,varargin{1},varargin{2});
        elseif strcmp(params.interface, 'debug')
            params = GiveReward_debug(params,varargin{1},varargin{2});
        end
        varargout{1} = params; % Make sure the output is the params
    case "StopReward" % Doesn't actually stop reward, just checks if we need to
        if params.juiceOn == true % Is the juice currently on? This segment of code no longer works in GiveReward_DAQ, it now functionally works in StopReward
            if params.juiceEndTime <= varargin{1} % If the current time has exceeded or equals the end juiceTime
                if strcmp(params.interface, 'DAQ')
                    DAQ('SetBit',[0 0 0 0]); % Turn off the juice
                end
                params.juiceOn = false;
            end
        end
        varargout{1} = params; % Make sure the output is the params

            
    case "GetFixation"
        if strcmp(params.interface, 'DAQ')
            [coordinates, volts] = GetFixationCoordinates_daq(params);
        elseif strcmp(params.interface, 'datapixx')
            [coordinates, volts] = GetFixationCoordinates_datapixx(params);
        elseif strcmp(params.interface, 'debug')
            coordinates = [0+params.xOffset,0+params.yOffset];
            volts = [0,0];
        end
        varargout{1} = coordinates;
        varargout{2} = volts;
    case "WaitForTTL"
        if strcmp(params.interface, 'DAQ')
            Wait4ScannerTTL_daq(params);
        elseif strcmp(params.interface, 'datapixx')
            Wait4scannerTTL_datapixx(params);
        elseif strcmp(params.interface, 'debug')
            while true
                [keyIsDown,secs,keyCode] = KbCheck; % Get keyboard inputs
                if keyCode(KbName('space')) % If space is pressed
                    break; % Begin
                end
            end
        end
end

        
        
        
