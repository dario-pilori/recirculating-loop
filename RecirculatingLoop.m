classdef RecirculatingLoop < handle
    %RECIRCULATINGLOOP Recirculating Optical Fiber Loop
    %   This class defines the RecirculatingLoop object, which
    %   characterizes a recirculating optical fiber loop.
    
    %% Read-only properties
    properties (SetAccess = private, GetAccess = public)
        tloop         % propagation delay of each loop (seconds)
        max_loops     % maximum number of loops to measure (integer)
        cur_loop      % current loop
        aom_ppg       % GPIB object of PPG that controls AOMs
        trigger_ppg   % GPIB object of PPG that controls trigger
        initialized = false % true if loop has been initialized successfully
    end
    
    %% Private properties
    properties (Access = private)
        tfill         % time to fill the loop (seconds)
        f_trig        % trigger frequency (Hz)
    end
    
    %% Methods
    methods
        %% Constructor
        function obj = RecirculatingLoop(addr1,addr2,tloop,max_loops)
            %RECIRCULATINGLOOP Initializes the loop
            %   This function initializes a new recirculation loop
            % Parameters:
            % addr1     := GPIB address of first DG535 (loop+fill switch)
            % addr2     := GPIB address of second DG535 (trigger)
            % tloop     := Propagation delay of loop (c/neff*L, seconds )
            % n_loops   := Number of loops to propagate
            validateattributes(addr1,{'numeric'},{'scalar','nonnegative','integer'})
            validateattributes(addr2,{'numeric'},{'scalar','nonnegative','integer'})
            validateattributes(tloop,{'numeric'},{'scalar','positive'})
            validateattributes(max_loops,{'numeric'},{'scalar','positive','integer'})       
            
            obj.initialized = false; % at beginning loop is not initialized
            obj.tloop = tloop;
            obj.max_loops = max_loops;
            obj.tfill = 1.5*obj.tloop; % time to fill the loop
            obj.f_trig = 1/(obj.tfill+max_loops*obj.tloop); % trigger time
            obj.cur_loop = 1; % select first loop by default
            obj.aom_ppg = gpib('ni',0,addr1); % set first PPG GPIB
            obj.trigger_ppg = gpib('ni',0,addr2); % set second PPG GPIB
        end
        
        %% Initialize loop
        function obj = Initialize(obj)
            %INITIALIZE Initialize loop
            %   This function initializes the loop, re-setting the two PPGs
            %   from scratch. Must be run the first time.
            
            %% AOMs PPG
            % Open connection
            fopen(obj.aom_ppg);
            
            fprintf(obj.aom_ppg,'CL'); % clear instrument
            
            % Set to high-impedance load
            fprintf(obj.aom_ppg,'TZ 1,1');
            fprintf(obj.aom_ppg,'TZ 4,1');
            fprintf(obj.aom_ppg,'TZ 7,1');
            
            % Set TTL output
            fprintf(obj.aom_ppg,'OM 1,0');
            fprintf(obj.aom_ppg,'OM 4,0');
            fprintf(obj.aom_ppg,'OM 7,0');
            
            % Set trigger
            fprintf(obj.aom_ppg,'TM 0'); % internal trigger
            fprintf(obj.aom_ppg,['TR 0,',num2str(obj.f_trig,'%f')]); % set trigger frequency
            
            % Set delays
            fprintf(obj.aom_ppg,'DT 2,1,0');
            fprintf(obj.aom_ppg,['DT 3,2,',num2str(obj.tfill,'%E')]);
            fprintf(obj.aom_ppg,'DT 5,2,0');
            fprintf(obj.aom_ppg,'DT 6,3,0');
            
            % Close connection
            fclose(obj.aom_ppg);
            
            %% Trigger PPG
            fopen(obj.trigger_ppg);
            
            fprintf(obj.trigger_ppg,'CL'); % clear instrument
            
            % Set to high-impedance load
            fprintf(obj.trigger_ppg,'TZ 1,1');
            fprintf(obj.trigger_ppg,'TZ 4,1');
            
            % Set TTL output
            fprintf(obj.trigger_ppg,'OM 1,0');
            fprintf(obj.trigger_ppg,'OM 4,0');
            
            % Set trigger
            fprintf(obj.trigger_ppg,'TM 1'); % Set external trigger
            fprintf(obj.trigger_ppg,'TZ 0,1'); % set trigger impedance
            
            % Set delays
            fprintf(obj.trigger_ppg,['DT 2,1,',num2str(obj.tfill+...
                (obj.cur_loop-1+0.05)*obj.tloop,'%E')]);
            fprintf(obj.trigger_ppg,['DT 3,2,',num2str(obj.tloop*0.9,'%E')]);
            
            % Close connection
            fclose(obj.trigger_ppg);
            
            %% Set to initialized
            obj.initialized = true;            
        end
        
        %% Reconfigure loop
        function obj = ReconfigureLoop(obj,tloop,max_loops)
            %RECONFIGURELOOP Change loop parameters
            %   Use this function to change the loop params (tloop and
            %   max_loops)
            validateattributes(tloop,{'numeric'},{'scalar','positive'})
            validateattributes(max_loops,{'numeric'},{'scalar','positive','integer'})
            
            %% Check if loop is OK
            if ~obj.initialized
                error('Loop not initialized; please initialize');
            end
            
            %% Calculate parameters
            obj.initialized = false;
            obj.tloop = tloop;
            obj.max_loops = max_loops;
            obj.tfill = 1.5*obj.tloop; % time to fill the loop
            obj.f_trig = 1/(obj.tfill+max_loops*obj.tloop); % trigger time
            obj.cur_loop = 1; % select first loop by default
            
            %% Set up first PPG
            fopen(obj.aom_ppg);
            fprintf(obj.aom_ppg,['TR 0,',num2str(obj.f_trig,'%f')]); % set trigger frequency
            fprintf(obj.aom_ppg,'DT 2,1,0');
            fprintf(obj.aom_ppg,['DT 3,2,',num2str(obj.tfill,'%E')]);
            fprintf(obj.aom_ppg,'DT 5,2,0');
            fprintf(obj.aom_ppg,'DT 6,3,0');
            fclose(obj.aom_ppg);
            
            %% Set up second PPG
            fopen(obj.trigger_ppg);
            fprintf(obj.trigger_ppg,['DT 2,1,',num2str(obj.tfill+...
                (obj.cur_loop-1+0.05)*obj.tloop,'%E')]);
            fprintf(obj.trigger_ppg,['DT 3,2,',num2str(obj.tloop*0.9,'%E')]);
            fclose(obj.trigger_ppg);
            
            obj.initialized = true;
        end
        
        %% Select loop
        function obj = SelectLoop(obj,cur_loop)
            %SELECTLOOP Select loop
            %   Use this function to select a loop between 0 (B2B) to
            %   max_loops
            validateattributes(cur_loop,{'numeric'},{'scalar','nonnegative',...
                '<=',obj.max_loops})
            
            %% Check if loop is OK
            if ~obj.initialized
                error('Loop not initialized; please initialize');
            end
            
            %% Calculate parameters
            obj.cur_loop = cur_loop; % select first loop by default
                        
            %% Set up second PPG
            fopen(obj.trigger_ppg);
            fprintf(obj.trigger_ppg,['DT 2,1,',num2str(obj.tfill+...
                (obj.cur_loop-1+0.05)*obj.tloop,'%E')]);
            fprintf(obj.trigger_ppg,['DT 3,2,',num2str(obj.tloop*0.9,'%E')]);
            fclose(obj.trigger_ppg);
        end
        
        %% Destructor
        function delete(obj)
            % Delete handles to PPG
            delete(obj.trigger_ppg);
            delete(obj.aom_ppg);
        end
    end
end

