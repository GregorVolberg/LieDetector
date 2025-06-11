% =======================
% function[] = liedetect_experiment()
% ========================

%%  
function[] = liedetect_experiment()

clear all
testrun =0;
if testrun
    timeOut = 1;
else
    timeOut = inf;
end

% set up paths, responses, monitor, ...
addpath('./func'); 
stimpath = '../stim/';
[vp, msgmapping, responseHand, ~, self] = get_experimentInfo();
MonitorSelection = 3; % 6 in EEG, 3 in Gregor's office
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
rkeys    = {'y', 'x', 'n', 'm'};
numkeys  = {'1!', '2@', '3#', '4$', '5%'};
KbName('UnifyKeyNames');
ZahlenCodes = KbName(numkeys);
TastenCodes    = KbName({[numkeys], 'ESCAPE'}); % numbers and ESC
NumberVector   = zeros(1,256); NumberVector(TastenCodes) = 1;
TastenCodes    = KbName({[rkeys], 'ESCAPE'}); % response keys and ESC
ResponseVector = zeros(1,256); ResponseVector(TastenCodes) = 1;

%% stimulus size
centCircleSize  = 0.05; % Size of central fixation dot
centCirclePixel = centCircleSize * MonitorSpecs.PixelsPerDegree;
textSize = 30;
targetRect = [0 0 60 60];
vspacing = 20;
yTargetPositions = [1:10]*(targetRect(3)+vspacing);

%% presentation parameters
ISI                = [1.5 2.5]; % in seconds
StimulusTime       = 1;  % seconds
BreakBetweenBlocks = 10; % in seconds
nblocks            = 8;  % number of blocks 
 
%% stimuli
[places, characters, weapons, character_items, weapon_items, place_items] = get_crime_stimuli_and_items();
allChoices     = {places.png, characters.png, weapons.png}; % randomize order?
folders        = {'./stim/places/', './stim/characters/', './stim/weapons/'};

%strrep(txt, '#', 'grün')
%% stimulus positions
tPos = cell(1, numel(allChoices));
for ch = 1:numel(allChoices)
    for item = 1:numel(allChoices{ch})
    [tmpim, ~, tmpalpha] = imread([folders{ch}, allChoices{ch}{item}]);
    tmpim(:,:,4) = tmpalpha; % add alpha channel
    im{ch, item} = tmpim;
    end
    xTargetPositions =  [1:numel(allChoices{ch})]*targetRect(3)*2;
    tPos{ch} = CenterRectOnPoint(targetRect, xTargetPositions', ...
                             repmat(yTargetPositions((ch-1)*2+2), 1, numel(xTargetPositions))');
end
tPosPicked = CenterRectOnPoint(targetRect, [[1:numel(allChoices)]*targetRect(3)*2]', ...
                             repmat(yTargetPositions(9), 1, numel(allChoices))');

%% condition list
condition  = char([repmat({'place'}, 1, numel(places.png)), ...
                   repmat({'character'}, 1, numel(characters.png)), ... 
                   repmat({'weapon'}, 1, numel(weapons.png)), ...
                   repmat({'self'}, 1, numel(self.text))]');
featureC   = char([places.con, characters.con, weapons.con, self.con]);
picked(1)  = Sample(1:numel(places)); % place is drawn

%% messages
msgStart  = 'Bitte warte, bis die Untersucherin die EEG-Aufnahme gestartet hat.\n\n Das Experiment beginnt bald.';
msgEnd    = '--- Ende des Experiments ---\n\nBitte warte, bis die EEG-Aufnahme gestoppt wurde.';
msgBreak  = 'Ruhe dich aus (10 s)';
msgInstruct1 = ['Der Mord hat ', places.text{picked(1)}, ' stattgefunden.\n'];
msgInstruct2 = 'Wähle einen Character:\n';
msgInstruct3 = 'Wähle eine Waffe:\n';
msgPicked1   = 'Dein Ort, Character und Waffe:\n';
msgPicked2   = 'Starte das Spiel mit einer Antworttaste!\n';
msgChoose = {msgInstruct1, msgInstruct2, msgInstruct3};

%% results file
liedetect      = [];
timeString  = datestr(clock,30);
outfilename = ['sub-', vp, '_task-lieDetector.mat'];

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
    % compute fliptime for target
    PTBStimulusTime = StimulusTime - (frame_s * 0.5);

    % Construct and start response queue
    KbQueueCreate([],ResponseVector);
    KbQueueStart;
     
    % show startup screen and wait for key press (investigator)
    KbQueueFlush;        
    Screen('TextSize', win, textSize);
    DrawFormattedText(win, msgStart, 'center', 'center', [255 255 255]);
    VpixxMarkerZero(win);
    Screen('Flip', win);
    KbQueueWait();
    
    % show startup screen and wait for key press (participant)
    KbQueueFlush;        
    Screen('TextSize', win, textSize);
    DrawFormattedText(win, msgmapping, 'center', 'center', [255 255 255]);
    VpixxMarkerZero(win);
    Screen('Flip', win);
    KbQueueWait();
    
    KbQueueStop;

    % show blank for smooth transition to next page
    VpixxMarkerZero(win);
    Screen('Flip', win);
       
    % results table
    fullTable = [];
            KbQueueCreate([], NumberVector);
        KbQueueStart;
        KbEventFlush();

        Screen('TextSize', win, textSize);
        k=1;
        DrawFormattedText(win, msgChoose{k}, targetRect(3), yTargetPositions((k-1)*2+1)+targetRect(3)/2, [255 255 255]);
        texturePlace = Screen('MakeTexture', win, im{k, picked(1)});
        Screen('DrawTextures', win, texturePlace,[], tPos{k}(1,:)'); 

        %% choose character and weapon
        for k = 2:3
        numberOfStimuli = sum(~cellfun(@isempty, im(k, :)));
        texture = double(numberOfStimuli);
            for m = 1:numberOfStimuli
            texture(k, m) = Screen('MakeTexture', win, im{k, m});
            end
        Screen('TextSize', win, textSize);
        DrawFormattedText(win, msgChoose{k}, targetRect(3), yTargetPositions((k-1)*2+1)+targetRect(3)/2, [255 255 255]);
        Screen('DrawTextures', win, texture(k, :),[], tPos{k}');  
        KbQueueFlush;    
        t0 = Screen('Flip', win, [], 1);
            keyCode = 0;
            while ~ismember(keyCode, ZahlenCodes(1:numberOfStimuli))
            [keyCode, ~] = get_timeOutResponse(t0, timeOut);
            end
        picked(k) = find(ismember(ZahlenCodes, keyCode));
        end
        KbQueueStop;

   %% loop over blocks
    protocol = [];
    for nblock = 1:nblocks

        if mod(nblock, 2) == 1
            roleC.text = 'Täter';
            roleC.con  = 'offender';
        elseif mod(nblock, 2) == 0
            roleC.text = 'Zeuge';
            roleC.con  = 'attestor';
        end

        %% show chosen character, place, weapon
        % Construct and start new response queue
        KbQueueCreate([], ResponseVector);
        KbQueueStart;
    
        DrawFormattedText(win, msgPicked1, targetRect(3), yTargetPositions(8)+targetRect(3)/2, [255 255 255]);
        for n = 1:3
            tex = Screen('MakeTexture', win, im{n, picked(n)});
            Screen('DrawTexture', win, tex,[], tPosPicked(n,:));  
        end
        txtblock = ['Deine Rolle in diesem Abschnitt: ', roleC.text, '. ', msgPicked2];
        DrawFormattedText(win, txtblock, targetRect(3), yTargetPositions(10)+targetRect(3)/2, [255 255 255]);
        KbQueueFlush;
        Screen('Flip', win);
        
        %% construct condition matrix
        gamepick = zeros(size(condition,1), 1);
        role    = repmat(roleC.con, numel(gamepick), 1);
        gamepick([picked(1), picked(2) + numel(places.png), ...
                  picked(3) + numel(places.png) + numel(characters.png)])=1;
        block = repmat(nblock, numel(gamepick), 1);
        feature_nr = [1:4, 1:4, 1:4, 1:4]';
        
        T = table(block, condition, featureC, feature_nr, gamepick, role);
        T = repmat(T, 3, 1);
        tmpconmat = T(randperm(size(T,1)),:);
        clear conmat items
        
        %% prepare text
        for trl = 1:size(tmpconmat, 1)
            con = deblank(tmpconmat.condition(trl,:));
            switch con
                case 'place'
                   items{trl} = strrep(char(Sample(place_items)), '#', char(places.text(tmpconmat.feature_nr(trl))));
                case 'character'
                   items{trl} = strrep(char(Sample(character_items)), '#', char(characters.text(tmpconmat.feature_nr(trl))));
                case 'weapon'
                   items{trl} = strrep(char(Sample(weapon_items)), '#', char(weapons.text(tmpconmat.feature_nr(trl))));
                case 'self'
                   items{trl} = self.text{tmpconmat.feature_nr(trl)};
            end
        end
        items  = items';
        conmat = [tmpconmat items];

        KbQueueWait();
              
        % clear protocolMatrix     
        protocolTable = [];

        %% loop over trials    
        for ntrial = 1:size(T, 1)

            % check if ESC is pressed and stop if yes
            checkESC;

            % draw and show fixation
            Screen('gluDisk', win, [0 0 0], xCenter, yCenter, centCirclePixel);
            VpixxMarkerZero(win);
            [FixationStart] = Screen('Flip', win);
 
            % prepare and show text
            %wcon = find(ismember({'character', 'place', 'weapon'}, deblank(conmat.condition(ntrial,:))));
            %showText = [msgTrial{wcon}, deblank(conmat.gender(ntrial,:)), ' ', deblank(conmat.filename(ntrial,:)), '.'];
            DrawFormattedText(win, items{ntrial}, 'center', 'center', [255 255 255]);
            setVpixxMarker(win, 1);
            KbQueueFlush;
            [TargetStart] = Screen('Flip', win, FixationStart + ISI(1) + (ISI(2)-ISI(1)).*rand(1)); % random uniform in ISI interval
            
            % get reponse
            [empkeyCode, RT] = get_timeOutResponse(TargetStart, timeOut);
            
            % after keypress, wait for 0.5 sec
            WaitSecs(0.5);

            % compute presentation times
            kCode(ntrial) = empkeyCode;
            rtime(ntrial) = RT;
        end
        
        % copy all trial information into one table
        %expdata = table(ftime', ttime', kcode', rtime', 'VariableNames', {'cueTime', 'targetTime', 'keyCode', 'rTime'});
        %blcks   = table(zeros(48,1) + nblock, [1:48]', 'VariableNames', {'block', 'trial'});
        kCode = table(kCode', 'VariableNames', {'kCode'});
        rtime = table(rtime', 'VariableNames', {'rtime'});
        protocolTable = [conmat, kCode, rtime];
        clear kCode rtime
        
        % write protocol table 
        fullTable = [fullTable; protocolTable];
        clear protocolTable
        
        % show blank screen
        VpixxMarkerZero(win);
        Screen('Flip', win);

            % show break message
            WaitSecs(2);
            if nblock < nblocks
                Screen('TextSize', win, textSize);
                DrawFormattedText(win, msgBreak, 'center', 'center', [255 255 255]);
                VpixxMarkerZero(win);
                Screen('Flip', win);
                WaitSecs(BreakBetweenBlocks);
            end

        WaitSecs(1);
        KbQueueStop;
    end

% write results and supplementary information to structure
liedetect.experiment         = 'task-lieDetection';
liedetect.participant        = vp;
liedetect.date               = timeString;
liedetect.protocol           = fullTable;
liedetect.response_hand      = responseHand;
liedetect.yes_key            = KbName('y');
liedetect.monitor_refresh    = hz;
liedetect.MonitorDimension   = MonitorDimension;

save(outfilename, 'liedetect');

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

