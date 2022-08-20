%% Computes entropy on EEGLAB-formatted data.
%
% Cedric Cannard, August 2022

function EEG = pop_entropy(EEG)


% Basic checks and warnings
if nargin < 1, help pop_entropy; return; end
if isempty(EEG.data), error('Cannot process empty dataset.'); end
if isempty(EEG.chanlocs(1).labels), error('Cannot process without channel labels.'); end
% if ~isfield(EEG.chanlocs, 'X') || isempty(EEG.chanlocs(1).X), error("Electrode locations are required. " + ...
%         "Go to 'Edit > Channel locations' and import the appropriate coordinates for your montage"); end
if isempty(EEG.ref), warning(['EEG data not referenced! Referencing is highly recommended ' ...
        '(e.g., CSD-transformation, infinity-, or average- reference)!']); end
if length(size(EEG.data)) == 2
    continuous = true;
else
    continuous = false;
end

% channel_list = {EEG.chanlocs.labels};

% GUI
if nargin < 2
    drawnow;
    eType = {'sample entropy', 'multiscale entropy', 'refined composite multiscale entropy (RCMFE)'};
    fType = {'none', 'bandpass'};
    uigeom = { [1 .25 0.75] [1 .25 2] };
    uilist = {
        {'style' 'text' 'string' 'EEG channel(s):'} {} ...
        {'style' 'pushbutton' 'string' 'List','enable' 'on' ...
        'callback' ['tmpEEG = get(gcbf, ''userdata''); tmpchanlocs = tmpEEG.chanlocs;' ...
        ' [tmp tmpval] = pop_chansel({tmpchanlocs.labels}, ''withindex'', ''on'');' ...
        'set(findobj(gcbf, ''tag'', ''eegchan''), ''string'',tmpval); ' ...
        'clear tmp tmpEEG tmpchanlocs tmpval'] }, ...
        {'Style' 'text' 'String' 'Entropy type:'} {} ...
        {'Style' 'popupmenu' 'String' eType 'Tag' 'etypepop'}  ...
        };
    result = inputgui(uigeom,uilist,'pophelp(''pop_brainheart'')','brainheart EEGLAB plugin',EEG);

    if isempty(result), return; end

    % decode user inputs
    args = {};
    if ~isempty(result{1})
        [~, chanlist] = eeg_decodechan(EEG.chanlocs, result{1});
        args = [ args {'eegchannel'} {chanlist} ];
    end





    args = [args {'ftype'} eType(result{2})];
    args = [args {'wtype'} wtypes(result{3})];
    if ~isempty(result{4})
        args = [args {'warg'} {str2double(result{4})}];
    end
    if ~isempty(result{5})
        args = [args {'forder'} {str2double(result{5})}];
    end
    args = [args {'minphase'} result{6}];
    args = [args {'usefftfilt'} result{7}];
else
    args = varargin;
end



% Callback estimate filter order
function entropytype(obj, evt, wtypes, srate)
    wtype = wtypes{get(findobj(gcbf, 'Tag', 'wtypepop'), 'Value')};
    dev = get(findobj(gcbf, 'Tag', 'devedit'), 'String');
    [forder, dev] = pop_firwsord(wtype, srate, [], dev);
    set(findobj(gcbf, 'Tag', 'forderedit'), 'String', forder);
    set(findobj(gcbf, 'Tag', 'devedit'), 'String', dev);



