function varargout = DAQ(request, varargin)
%% Matlab Script to Interact with DAQ Card
% Stuart Duffield 10/2021, for ConwayLab at the NIH
% dq = daq("ni"); % define DAQ card as a DataAcquisition
% dq.Rate = 1000; % Define the rate of DataAqcuisition
% addinput(dq,"Dev1","ai0","Voltage"); 
% addinput(dq,"Dev1","ai1","Voltage");
% addinput(dq,"Dev1","ai2","Voltage"); 
% addinput(dq,"Dev1","ai3","Voltage");
% addinput(dq,"Dev1","ai4","Voltage"); 
% addinput(dq,"Dev1","ai5","Voltage");
% addinput(dq,"Dev1","ai6","Voltage"); 
% addinput(dq,"Dev1","ai7","Voltage");
% addoutput(dq,"Dev1","port0/line0","Digital")
% addoutput(dq,"Dev1","port0/line1","Digital")
% addoutput(dq,"Dev1","port0/line2","Digital")
% addoutput(dq,"Dev1","port0/line3","Digital")

%read(dq,"OutputFormat","Matrix");
%write(dq,1);
persistent dq % This allows for the DAQ DataAcquisition object to remain defined between calls.
    switch request
        case 'Init'
            dq = daq("ni"); % define DAQ card as a DataAcquisition
            dq.Rate = 1000; % Define the rate of DataAqcuisition
            addinput(dq,"Dev1","ai0","Voltage"); 
            addinput(dq,"Dev1","ai1","Voltage");
            addinput(dq,"Dev1","ai2","Voltage"); 
            addinput(dq,"Dev1","ai3","Voltage");
            addinput(dq,"Dev1","ai4","Voltage"); 
            addinput(dq,"Dev1","ai5","Voltage");
            addinput(dq,"Dev1","ai6","Voltage"); 
            addinput(dq,"Dev1","ai7","Voltage");
            addoutput(dq,"Dev1","port0/line0","Digital")
            addoutput(dq,"Dev1","port0/line1","Digital")
            addoutput(dq,"Dev1","port0/line2","Digital")
            addoutput(dq,"Dev1","port0/line3","Digital")
            
        case 'GetAnalog'
            analogin = read(dq,"OutputFormat","Matrix");
            [varargout{1:nargout}] = analogin(varargin{:});

        case 'SetBit'
            write(dq,varargin{:})
            
        case 'WaitForTTL' % Need to validate this
            while true
                analogin = read(dq,"OutputFormat","Matrix");
                if abs(analogin(varargin{:})) > .25 % was 2.5 
                    varargout{1} = true;
                    break;
                end
            end
        case 'Close'
            delete(dq)
            clear dq
    end
end





