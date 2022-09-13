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
            params = GiveReward_datapixx(params,varargin{1});
        elseif strcmp(params.interface, 'debug')
            % Set this to disp something if you'd like
        end
        varargout{1} = params; % Make sure the output is the params
    case "GetFixation"
        if strcmp(params.interface, 'DAQ')
            [coordinates, volts] = GetFixationCoordinates_daq(params);
        elseif strcmp(params.interface, 'datapixx')
            [coordinates, volts] = GetFixationCoordinates_datapixx(params);
        elseif strcmp(params.interface, 'debug')
            coordinates = [0,0];
            volts = [0,0];
        end
        varargout{1} = coordinates;
        varargout{2} = volts;
    case "WaitForTTL"
        
