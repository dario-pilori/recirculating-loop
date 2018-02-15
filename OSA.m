classdef OSA < handle
    %OSA Optical Spectrum Analyzer
    %   This class defines the OSA object, which
    %   characterizes the HP 86142A OSA.
    
    %% Read-only properties
    properties (SetAccess = private, GetAccess = public)
        gpib_addr         % GPIB address of the OSA
    end
    
    %% Methods
    methods
        %% Constructor
        function obj = OSA(addr)
            %OSA Initializes the OSA
            %   This function initializes a new OSA object
            % Parameters:
            % addr     := GPIB address of HP 86142A OSA
            validateattributes(addr,{'numeric'},{'scalar','nonnegative','integer'})
            
            obj.gpib_addr = gpib('ni',0,addr); % set scope
            obj.gpib_addr.InputBufferSize = 8008; % set buffer size for 1001 samples
        end
        
        %% Reconfigure loop
        function x = GetLoopTrace(obj,varargin)
            %GETLOOPTRACE Get a trace from the loop
            %   Use this function to obtain a fresh trace from the
            %   recirculating loop
            %   Optional paramenter: wait time in seconds (default to 1min)
            if nargin>1
                validateattributes(varargin{1},{'numeric'},{'scalar','nonnegative'})
                wait = varargin{1};
            else
                wait = 60;
            end
            
            % Open OSA
            fopen(obj.gpib_addr);
            
            % Clear max-hold and capture
            fprintf(obj.gpib_addr,'INIT:CONT on');
            fprintf(obj.gpib_addr,'CALCulate1:MAXimum:CLEar');
            fprintf(obj.gpib_addr,'CALCulate1:MAXimum:STATe');
            
            % Wait
            l = waitbar(0,['Waiting ',num2str(wait),' seconds...']);
            for i = 0:wait-1
                waitbar(i/wait);
                pause(1);
            end
            close(l);
            
            % Stop capturing
            fprintf(obj.gpib_addr,'INIT:CONT off');

            % Close OSA
            fclose(obj.gpib_addr);
            
            % Get trace from scope
            x = obj.getOSAtrace(obj.gpib_addr);
        end
        
        %% Destructor
        function delete(obj)
            delete(obj.gpib_addr);
        end
    end
    
    %% Static methods
    methods(Static)
        %% Capture a trace from the OSA
        function t = getOSAtrace(g)      
            fopen(g);                          % Open connection
            fprintf(g,'FORMat:DATA REAL,64');  % Set data to binary 64-bit floating point
            fprintf(g,'TRAC:DATA:Y? TRA');     % Ask for trace
            x = binblockread(g,'uchar');       % Read trace for scope
            fclose(g);                         % Close connection
            x = reshape(flipud(reshape(x,8,[])),[],1); % Correct endianness
            t = typecast(uint8(x),'double');   % convert to double and exit
        end
    end
end

