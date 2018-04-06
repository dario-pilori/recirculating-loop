classdef OSA < handle
    %OSA Optical Spectrum Analyzer
    %   This class defines the OSA object, which
    %   characterizes the HP 86142A OSA.
    %   2018 - Dario Pilori <dario.pilori@polito.it>
    
    %% Properties
    properties
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
            
            %% Initialize GPIB object
            obj.gpib_addr = gpib('ni',0,addr); % set scope
            obj.gpib_addr.InputBufferSize = 8008; % set buffer size for 1001 samples
            
            %% Set default options
            fopen(obj.gpib_addr);
            
            fprintf(obj.gpib_addr,'SYS:COMM:GPIB:BUFF ON'); % enable buffer
            fprintf(obj.gpib_addr,'INIT:CONT OFF');         % stop automatic sweep
            query(obj.gpib_addr,'*OPC?');                   % wait to complete all operations
            
            fclose(obj.gpib_addr);
        end
        
        %% Get trace from loop
        function [x,l,RBW] = GetLoopTrace(obj,varargin)
            %GETLOOPTRACE Get a trace from the loop
            %   Use this function to obtain a fresh trace from the
            %   recirculating loop
            %   Optional paramenter: wait time in seconds (default to 1min)
            if nargin>1
                validateattributes(varargin{1},{'numeric'},{'scalar','nonnegative'})
                wait = varargin{1};
            else
                wait = 30;
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
                if ~mod(i,10)
                    waitbar(i/wait);
                end
                pause(1);
            end
            close(l);
            
            % Stop capturing
            query(obj.gpib_addr,'*OPC?');                   % wait to complete all operations
            fprintf(obj.gpib_addr,'INIT:CONT off');
            
            % Close OSA
            fclose(obj.gpib_addr);
            
            % Get trace from scope
            [x,l,RBW] = obj.getOSAtrace(obj.gpib_addr);
        end
        
        %% Destructor
        function delete(obj)
            delete(obj.gpib_addr);
        end
    end
    
    %% Static methods
    methods(Static)
        %% Capture a trace from the OSA
        function [t,l,RBW] = getOSAtrace(g)
            fopen(g);                          % Open connection
            
            %% Get OSA params
            fprintf(g,'FORMat:DATA REAL,64');  % Set data to binary 64-bit floating point
            start = str2double(query(g,'TRAC:DATA:X:STAR? TRA')); % get initial wavelength
            stop = str2double(query(g,'TRAC:DATA:X:STOP? TRA')); % get initial wavelength
            RBW = str2double(query(g,'BAND?'));  % get resolution bandwidth
            N = str2double(query(g,'TRACe:POINts? TRA'));   % get number of points
            if 8*N > g.InputBufferSize
                warning(['Extending GPIB InputBufferSize to ',num2str(8*N)]);
                fclose(g);
                g.InputBufferSize = 8*N;
                fopen(g);
            end
            
            %% Read data
            query(g,'*OPC?');      % wait to complete all operations
            fprintf(g,'TRAC:DATA:Y? TRA');     % Ask for trace
            x = binblockread(g,'uchar');       % Read trace for scope
            fclose(g);                         % Close connection
            
            %% Prepare output
            x = reshape(flipud(reshape(x,8,[])),[],1); % Correct endianness
            t = typecast(uint8(x),'double');           % convert to double
            assert(length(t)==N,'OSA trace length is different than expected.');
            l = linspace(start,stop,N).';              % get wavelength scale
        end
        
        %% Calculate OSNR from OSA trace
        function [OSNR,P_SIG,P_ASE] = measureOsnr_HighRes(x,l,RBW,Rs,ASE_box,varargin)
            %MEASUREOSNR   Simple function to calculate the OSNR
            %   Use this function to evaluate the OSNR from a high-resolution (RBW <<
            %   Rs) optical spectrum.
            %   2018 - Dario Pilori <dario.pilori@polito.it>
            
            %% Calculate params
            f_ax = 299792458./l;                    % frequency axis (Hz)
            x_lin = 10.^(x/10);                     % spectrum in linear scale (mW)
            RBW_f = 299792458/mean(l)^2*RBW;        % resolution bw (Hz)
            assert(Rs>2*RBW_f,'Resolution bandwidth must be much lower than symbol rate');
            
            %% Calculate signal power
            [~,idx] = max(x);
            SIG_box = idx + [1;-1] * floor((Rs/mean(diff(f_ax))-1)/2);
            G_SIG_ASE = sum(x_lin(SIG_box(1):SIG_box(2)))/...
                (SIG_box(2)-SIG_box(1)+1);
            P_SIG_ASE = 10*log10(G_SIG_ASE);    % SIG power over RBW
            
            %% Calculate ASE power
            ws = warning('off','all');  % Turn off warning
            pol = polyfit([l(ASE_box(1):ASE_box(2));l(ASE_box(3):ASE_box(4))],...
                [x(ASE_box(1):ASE_box(2));x(ASE_box(3):ASE_box(4))],1);
            warning(ws); % turn on warning
            P_ASE = polyval(pol,l(idx)); % ASE power over RBW (dBm)
            
            %% Calculate OSNR
            P_SIG = 10*log10(10.^(P_SIG_ASE/10) - 10.^(P_ASE/10)); % Signal power (dBm)
            OSNR = P_SIG-P_ASE;                                   % OSNR over nominal power (dB over Rs)
            
            %% Plot OSNR
            if nargin>5&&varargin{1}
                figure
                hold on
                plot(l*1e9,x)
                plot(l*1e9,P_SIG_ASE*ones(length(l),1),'--')
                plot(l*1e9,(polyval(pol,l)),'--')
                grid on
                xlabel('\lambda (nm)')
                ylabel('Spectrum (dBm)')
                title(['RBW: ',num2str(RBW*1e9),' nm'])
                box on
            end
        end
        
        %% Calculate OSNR from OSA trace
        function [OSNR,P_SIG,P_ASE] = measureOsnr_LowRes(x,l,RBW,Rs,ASE_box,varargin)
            %MEASUREOSNR   Simple function to calculate the OSNR
            %   Use this function to evaluate the OSNR from a
            %   low-resolution (RBW > Rs) optical spectrum.
            %   2018 - Dario Pilori <dario.pilori@polito.it>
            
            %% Calculate params
            RBW_f = 299792458/mean(l)^2*RBW;        % resolution bw (Hz)
            assert(Rs<1.5*RBW_f,'Resolution bandwidth must be greater than symbol rate');
            
            %% Calculate signal power
            [P_SIG_ASE,idx] = max(medfilt1(x,3));  % Signal power + ASEoverRBW (dBm)
            
            %% Calculate ASE power
            ws = warning('off','all');  % Turn off warning
            pol = polyfit([l(ASE_box(1):ASE_box(2));l(ASE_box(3):ASE_box(4))],...
                [x(ASE_box(1):ASE_box(2));x(ASE_box(3):ASE_box(4))],1);
            warning(ws); % turn on warning
            P_ASE = polyval(pol,l(idx)); % ASE power over RBW (dBm)
            
            %% Calculate OSNR
            P_SIG = 10*log10(10.^(P_SIG_ASE/10) - 10.^(P_ASE/10)); % Signal power (dBm)
            OSNR = P_SIG-P_ASE+10*log10(RBW_f/Rs);                                   % OSNR over nominal power (dB over Rs)
            
            %% Plot OSNR
            if nargin>5&&varargin{1}
                figure
                hold on
                plot(l*1e9,x)
                plot(l*1e9,P_SIG_ASE*ones(length(l),1),'--')
                plot(l*1e9,(polyval(pol,l)),'--')
                grid on
                xlabel('\lambda (nm)')
                ylabel('Spectrum (dBm)')
                title(['RBW: ',num2str(RBW*1e9),' nm'])
                box on
            end
        end
    end
end

