classdef RobotArmControl < matlab.apps.AppBase
    % Robot Arm GUI for Arduino Mega
    % 5 Servos (D3–D7) + 1 Stepper (D8–D11)
    % Safe connection, disconnection, and full servo reset handling.

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        ConnectButton       matlab.ui.control.Button
        DisconnectButton    matlab.ui.control.Button
        HomeButton          matlab.ui.control.Button
        StepperCWButton     matlab.ui.control.Button
        StepperCCWButton    matlab.ui.control.Button
        ServoSliderArray    matlab.ui.control.Slider
        ServoLabelArray     matlab.ui.control.Label
    end

    properties (Access = private)
        a                   % Arduino object
        s                   % Servo objects (cell array)
        servoPins  = {'D3','D4','D5','D6','D7'};     % Servo pins
        stepperPins = {'D8','D9','D10','D11'};       % ULN2003 IN1–IN4
        stepSeq = [1 0 0 0;
                   1 1 0 0;
                   0 1 0 0;
                   0 1 1 0;
                   0 0 1 0;
                   0 0 1 1;
                   0 0 0 1;
                   1 0 0 1];
    end

    methods (Access = private)

        %% --- Connect to Arduino ---
        function ConnectButtonPushed(app, ~)
            try
                % --- Clear any leftovers ---
                delete(instrfindall);
                fclose('all');
                evalin('base','clearvars -except app');
                pause(1);

                % --- Connect ---
                app.a = arduino('COM5','Mega2560','Libraries',{'Servo'});
                disp(' Connected to Arduino Mega on COM5');

                % --- Initialize servos ---
                app.s = cell(1, numel(app.servoPins));
                for i = 1:numel(app.servoPins)
                    try
                        app.s{i} = servo(app.a, app.servoPins{i});
                        writePosition(app.s{i}, 0.5);  % Center (90°)
                        disp([' Servo initialized on ', app.servoPins{i}]);
                    catch ME
                        disp([' Servo init failed on ', app.servoPins{i}, ': ' ME.message]);
                    end
                end

                % --- Configure stepper pins ---
                for i = 1:4
                    configurePin(app.a, app.stepperPins{i}, 'DigitalOutput');
                end

                uialert(app.UIFigure,'Arduino connected successfully!','Connection');

            catch ME
                uialert(app.UIFigure,ME.message,'Connection Error');
            end
        end

        %% --- Disconnect Arduino and free all pins ---
        function DisconnectButtonPushed(app, ~)
            try
                if ~isempty(app.s)
                    for i = 1:numel(app.s)
                        try
                            release(app.s{i}); % free servo pin
                        catch
                        end
                    end
                    app.s = [];
                end
                if ~isempty(app.a)
                    clear app.a;
                    app.a = [];
                end
                delete(instrfindall);
                fclose('all');
                uialert(app.UIFigure,'Arduino disconnected and pins released.','Disconnected');
                disp('All serial and servo handles cleared.');
            catch ME
                uialert(app.UIFigure,ME.message,'Disconnect Error');
            end
        end

        %% --- Servo Slider Change ---
        function ServoSliderValueChanged(app,event,i)
            if isempty(app.a) || isempty(app.s{i}), return; end
            val = event.Value;
            writePosition(app.s{i}, val/180);
            app.ServoLabelArray(i).Text = sprintf('Servo %d: %3.0f°',i,val);
        end

        %% --- Stepper CW ---
        function StepperCWButtonPushed(app,~)
            if isempty(app.a), return; end
            app.runStepper(512,1);
        end

        %% --- Stepper CCW ---
        function StepperCCWButtonPushed(app,~)
            if isempty(app.a), return; end
            app.runStepper(512,-1);
        end

        %% --- Home All Servos ---
        function HomeButtonPushed(app,~)
            if isempty(app.a) || isempty(app.s), return; end
            for i = 1:numel(app.s)
                try
                    writePosition(app.s{i},0.5); % 90 degrees
                    app.ServoLabelArray(i).Text = sprintf('Servo %d: 90°',i);
                    app.ServoSliderArray(i).Value = 90;
                catch
                end
            end
            % Turn off stepper coils
            for p = 1:4
                writeDigitalPin(app.a,app.stepperPins{p},0);
            end
            uialert(app.UIFigure,'All servos centered.','Home Complete');
        end

        %% --- Stepper Routine ---
        function runStepper(app,steps,dir)
            seq = app.stepSeq;
            if dir==-1, seq=flipud(seq); end
            for s = 1:steps
                for i = 1:8
                    for p = 1:4
                        writeDigitalPin(app.a,app.stepperPins{p},seq(i,p));
                    end
                    pause(0.002);
                end
            end
            for p = 1:4
                writeDigitalPin(app.a,app.stepperPins{p},0);
            end
        end
    end

    methods (Access = public)
        %% --- Constructor: Build GUI ---
        function app = RobotArmControl
            app.UIFigure = uifigure('Name','Robot Arm Control','Position',[100 100 540 480]);

            app.ConnectButton = uibutton(app.UIFigure,'push',...
                'Text','Connect Arduino','Position',[50 420 140 30],...
                'ButtonPushedFcn',@(btn,event)ConnectButtonPushed(app,event));

            app.DisconnectButton = uibutton(app.UIFigure,'push',...
                'Text','Disconnect','Position',[210 420 100 30],...
                'ButtonPushedFcn',@(btn,event)DisconnectButtonPushed(app,event));

            app.HomeButton = uibutton(app.UIFigure,'push',...
                'Text','Home All','Position',[340 420 120 30],...
                'ButtonPushedFcn',@(btn,event)HomeButtonPushed(app,event));

            app.StepperCWButton = uibutton(app.UIFigure,'push',...
                'Text','Stepper CW','Position',[120 50 120 30],...
                'ButtonPushedFcn',@(btn,event)StepperCWButtonPushed(app,event));

            app.StepperCCWButton = uibutton(app.UIFigure,'push',...
                'Text','Stepper CCW','Position',[300 50 120 30],...
                'ButtonPushedFcn',@(btn,event)StepperCCWButtonPushed(app,event));

            for i = 1:5
                ypos = 330 - (i-1)*55;
                app.ServoLabelArray(i) = uilabel(app.UIFigure,...
                    'Text',sprintf('Servo %d: 90°',i),...
                    'Position',[40 ypos 80 22]);
                app.ServoSliderArray(i) = uislider(app.UIFigure,...
                    'Position',[130 ypos+10 350 3],...
                    'Limits',[0 180],...
                    'Value',90,...
                    'ValueChangedFcn',@(src,event)ServoSliderValueChanged(app,event,i));
            end
        end
    end
end
