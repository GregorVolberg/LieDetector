% =======================
% function[] = cred3fact_experiment()
% Credibility judgements for websites with 
% - true/false information
% - visual aesthetics mimicking high / low quality media outlets
% - high / low quality language style
% ========================

%%  
function[] = cred3fact_experiment()

clear all

% set up paths, responses, monitor, ...
addpath('./func'); 
stimpath = '../stim/';
stimlist = importdata([stimpath, 'stimuli_file_list.mat']);

[vp, msgInstruct, responseHand, rkeys] = get_experimentInfo();
MonitorSelection = 3y; % 6 in EEG, 3 in Gregor's office
MonitorSpecs = getMonitorSpecs(MonitorSelection); % subfunction, gets specification for monitor

%% PTB         
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1); % Sync test will not work with Windows 10
Screen('Preference', 'TextRenderer', 0); 
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
PsychImaging('FinalizeConfiguration');    

%% prepare ViewPixx marker write-out
topLeftPixel = [0 0 1 1];
VpixxMarkerZero = @(windowPointer) Screen('FillRect', windowPointer, [0 0 0], [0 0 1 1]); % viewpixx 
setVpixxMarker  = @(windowPointer, value) Screen('FillRect', windowPointer, [value 0 0], [0 0 1 1]); % viewpixx 

%% Response buttons
KbName('UnifyKeyNames');
TastenCodes  = KbName({[rkeys], 'ESCAPE'}); % [89, 88, 67, 86, 27]
TastenVector = zeros(1,256); TastenVector(TastenCodes) = 1;
timeOut = 1; % one second

%% stimulus size
centCircleSize  = 0.05; % Size of central fixation dot
centCirclePixel = centCircleSize * MonitorSpecs.PixelsPerDegree;
textSize = 30;

%% presentation parameters
ISI                = [1.5 2]; % in seconds
StimulusTime       = 4; % seconds
nCatchTrials       = [10 14];  % [min, max]
diffCatch          = [25 60]; % [min max]
BreakBetweenBlocks = 10; % in seconds

% % use these for testing:
% ISI           = [0.1 0.15]; % in seconds
% StimulusTime  = 0.1; % seconds
% nCatchTrials  = [10 14];  % [min, max]
% diffCatch     = [25 60]; % [min max]
% BreakBetweenBlocks = 3; % in seconds

%% messages
msgStart  = 'Bitte warten Sie, bis die Untersucherin die EEG-Aufnahme gestartet hat.\n\n Das Experiment beginnt bald.';
msgEnd    = '--- Ende des Experiments ---\n\nBitte warten Sie, bis die EEG-Aufnahme gestoppt wurde.';
msgBreak  = 'Ruhen Sie sich aus (10 s)';
msgAnswer = 'Wie glaubwürdig?';

%% results file
cred3F      = [];
timeString  = datestr(clock,30);  
outfilename = ['sub-', vp, '_task-credibilityJudgement.mat'];

try
    Priority(1);
    HideCursor;
    [win, MonitorDimension] = Screen('OpenWindow', MonitorSpecs.ScreenNumber, 127); 
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize', win, 18);
    if isfield(MonitorSpecs, 'gammaTable')
        Screen('LoadNormalizedGammaTable', win, MonitorSpecs.gammaTable); % correct gamma
    end   
    [xCenter, yCenter] = RectCenter(MonitorDimension);
    hz = Screen('NominalFrameRate', win);
    frame_s = (1/hz);

    %% prepare blocks, images, and textures
    % 6 source articles x 8 conditions x 10 repetitions = 480 trials
    % 10 blocks with 48 trials each, plus catch trials
    allBlocks    = get_cred3fBlocks(stimlist, nCatchTrials, diffCatch, ISI, frame_s);
    
    % compute fliptime for target
    PTBStimulusTime = StimulusTime - (frame_s * 0.5);
 
    % Construct and start response queue
    KbQueueCreate([],TastenVector);
    KbQueueStart;
    
    % show startup screen and wait for key press (investigator)
    KbQueueFlush;        
    Screen('TextSize', win, textSize);
    DrawFormattedText(win, msgStart, 'center', 'center', [255 255 255]);
    VpixxMarkerZero(win);
    Screen('Flip', win);
    KbQueueWait();

    % show blank for smooth transition to next page
    VpixxMarkerZero(win);
    Screen('Flip', win);
       
    % results table
    fullTable = [];
   %% loop over blocks
    protocol = [];
    for nblock = 1:length(allBlocks)
        
        % read block definition, prepare stimuli
        ablock = allBlocks{nblock};
        [~, textureMat] = get_images_cred3f(ablock, win); 
        
        % show instruction
        Screen('TextSize', win, textSize);
        DrawFormattedText(win, msgInstruct, 'center', 'center', [255 255 255]);
        VpixxMarkerZero(win);
        KbQueueFlush;    
        Screen('Flip', win);
        KbQueueWait();
        
        % show 1s blank screen for smooth page change
        VpixxMarkerZero(win);
        Screen('Flip', win);
        WaitSecs(1);

        % set TargetEnd for first trial so that it starts immediately
        TargetEnd = GetSecs + frame_s - PTBStimulusTime;

        % clear protocolMatrix     
        protocolTable = [];

        %% loop over trials    
        for ntrial = 1:size(ablock, 1)

            % check if ESC is pressed and stop if yes
            checkESC;

            % draw and show fixation
            Screen('gluDisk', win, [0 0 0], xCenter, yCenter, centCirclePixel);
            VpixxMarkerZero(win);
            [FixationStart] = Screen('Flip', win, TargetEnd);
            
            % draw and show target stimulus
            Screen('DrawTexture', win, textureMat(ntrial));  
            setVpixxMarker(win, 1);
            [TargetStart] = Screen('Flip', win, FixationStart + ablock.ISI(ntrial));

            % draw and show first frame of fixation for timing measures
            Screen('gluDisk', win, [0 0 0], xCenter, yCenter, centCirclePixel);
            VpixxMarkerZero(win);
            [TargetEnd] = Screen('Flip', win, TargetStart + PTBStimulusTime);

            % keep track of presentation times   
            fixtime    = TargetStart - FixationStart;
            targettime = TargetEnd - TargetStart;
            
            % in catch trial: show question mark and get response
            if ablock.catch(ntrial)
               DrawFormattedText(win, msgAnswer, 'center', 'center', [255 255 255]);
               VpixxMarkerZero(win);
               [QuestionStart] = Screen('Flip', win, TargetStart + PTBStimulusTime);
               [keyCode, responseTime] = get_timeOutResponse(QuestionStart, timeOut);
                if (~isnan(responseTime)) % ensure same trial length in trials with and without responses
                     WaitSecs(timeOut - responseTime);
                end
                TargetEnd = TargetEnd + frame_s - PTBStimulusTime; 
            else
                keyCode = NaN; responseTime = NaN;
            end

            % compute presentation times
            ftime(ntrial) = fixtime;
            ttime(ntrial) = targettime;
            kcode(ntrial) = keyCode;
            rtime(ntrial) = responseTime;
        end
        
        % copy all trial information into one table
        expdata = table(ftime', ttime', kcode', rtime', 'VariableNames', {'cueTime', 'targetTime', 'keyCode', 'rTime'});
        blcks   = table(zeros(48,1) + nblock, [1:48]', 'VariableNames', {'block', 'trial'});
        protocolTable = [blcks, ablock, expdata];
            
        % write protocol table 
        fullTable = [fullTable; protocolTable];
        clear protocolTable
        
        % show blank screen
        VpixxMarkerZero(win);
        Screen('Flip', win);

            % show break message
            WaitSecs(2);
            if nblock < numel(allBlocks)
                Screen('TextSize', win, textSize);
                DrawFormattedText(win, msgBreak, 'center', 'center', [255 255 255]);
                VpixxMarkerZero(win);
                Screen('Flip', win);
                WaitSecs(BreakBetweenBlocks);
            end

        WaitSecs(1);
    end

% write results and supplementary information to structure
cred3F.experiment         = 'task-credibilityJudgements';
cred3F.participant        = vp;
cred3F.date               = timeString;
cred3F.protocol           = fullTable;
cred3F.response_hand      = responseHand;
cred3F.monitor_refresh    = hz;
cred3F.MonitorDimension   = MonitorDimension;
cred3F.VisionRecorderWorkspace   = 'M1-10-10-EOG.wrksp';

save(outfilename, 'cred3F');

% show ending message
KbQueueFlush; 
Screen('TextSize', win, textSize);
DrawFormattedText(win, msgEnd, 'center', 'center', [255 255 255]);
VpixxMarkerZero(win);
Screen('Flip', win);
KbQueueWait();     

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
Screen('CloseAll');
end

