classdef Attenuator < handle
    %ATTENUATOR Optical Attenuator
    %   This class defines the Attenuator object, which
    %   characterizes the Agilent N7764A attenuator.
    %   Copyright (c) 2018 Dario Pilori, Politecnico di Torino <d.pilori@inrim.it>
    %   SPDX-License-Identifier: MIT
    
    %% Properties
    properties
        visa_addr         % VISA address of the attenuator
    end
    
    %% Private properties
    properties (SetAccess = private, GetAccess = public)
        channel = 5       % channel to set attenuation
        attenuation = 0   % current attenuation
    end
    
    %% Methods
    methods
        %% Constructor
        function obj = Attenuator(addr,varargin)
            %OSA Initializes the OSA
            %   This function initializes a new OSA object
            % Parameters:
            % addr     := GPIB address of HP 86142A OSA
            
            %% Get channel
            if nargin>2
                validateattributes(varargin{1},{'numeric'},{'integer','scalar'});
                obj.channel = varargin{1};
            end
            
            %% Initialize object
            obj.visa_addr  = visa('agilent',addr); % set scope
            fopen(obj.visa_addr);                  % open it
            
            %% Set attenuation
            obj.attenuation = ...
                str2double(query(obj.visa_addr,[':INP',num2str(obj.channel),':ATT?']));
            
            %% Close it
            fclose(obj.visa_addr);
        end
        
        %% Set attenuation
        function SetAttenuation(obj,att)
            %SETATTENUATION Set a specific attenuation
            validateattributes(att,{'numeric'},{'scalar','nonnegative'})
            
            % Open VISA
            fopen(obj.visa_addr);
            
            % Set attenuation
            obj.attenuation = att;
            fprintf(obj.visa_addr,[':INP',num2str(obj.channel),':ATT '...
                num2str(obj.attenuation),' dB']);
            
            % Close VISA
            fclose(obj.visa_addr);
        end
        
        %% Set channel
        function SetChannel(obj,ch)
            %SETCHANNEL Set a specific channel
            validateattributes(ch,{'numeric'},{'scalar','integer'})
            
            % Set channel
            obj.channel = ch;
            
            % Open VISA
            fopen(obj.visa_addr);
            
            % Set attenuation
            obj.attenuation = ...
                str2double(query(obj.visa_addr,[':INP',num2str(obj.channel),':ATT?']));
            
            % Close VISA
            fclose(obj.visa_addr);
        end

        %% Destructor
        function delete(obj)
            fclose(obj.visa_addr);
            delete(obj.visa_addr);
        end
    end 
end

