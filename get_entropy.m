%% Computes entropy on EEGLAB-formatted data.
%
% Cedric Cannard, August 2022

function [ae, se, fe, p, mse, rcmfe, scales] = get_entropy(EEG, entropyType, chanlist, tau, m, coarseType, filtData, n)

ae = [];
se = [];
fe = [];
p = [];
mse = [];
rcmfe = [];
scales = [];

% add path to subfolders
mainpath = fileparts(which('get_entropy.m'));
addpath(fullfile(mainpath, 'functions'));

% Basic checks and warnings
if nargin < 1
    help pop_entropy; return; 
end
if isempty(EEG.data)
    error('Empty dataset.'); 
end
if isempty(EEG.chanlocs(1).labels)
    error('No channel labels.'); 
end
% if ~isfield(EEG.chanlocs, 'X') || isempty(EEG.chanlocs(1).X), error("Electrode locations are required. " + ...
%         "Go to 'Edit > Channel locations' and import the appropriate coordinates for your montage"); end
if isempty(EEG.ref)
    warning(['EEG data not referenced! Referencing is highly recommended ' ...
        '(e.g., CSD-transformation, infinity-, or average- reference)!']); 
end

% Continuous/epoched data
if length(size(EEG.data)) == 2
    continuous = true;
else
    continuous = false; %%%%%%%%%%%%% ADD OPTION TO RUN ON EPOCHED DATA %%%%%%%%%
end

%% 1st GUI to select channels and type of entropy

if nargin == 1
    eTypes = {'Approximate entropy' 'Sample entropy' 'Fuzzy entropy' 'Multiscale entropy' 'Multiscale fuzzy entropy' 'Refined composite multiscale fuzzy entropy (default)'};
    uigeom = { [.5 .9] .5 [.5 .4 .2] .5 [.5 .1] .5 [.5 .1] };
    uilist = {
        {'style' 'text' 'string' 'Entropy type:' 'fontweight' 'bold'} ...
        {'style' 'popupmenu' 'string' eTypes 'tag' 'etype' 'value' 3} ...
        {} ...
        {'style' 'text' 'string' 'Channel selection:' 'fontweight' 'bold'} ...
        {'style' 'edit' 'tag' 'chanlist'} ...
        {'style' 'pushbutton' 'string'  '...', 'enable' 'on' ...
        'callback' "tmpEEG = get(gcbf, 'userdata'); tmpchanlocs = tmpEEG.chanlocs; [tmp tmpval] = pop_chansel({tmpchanlocs.labels},'withindex','on'); set(findobj(gcbf,'tag','chanlist'),'string',tmpval); clear tmp tmpEEG tmpchanlocs tmpval" } ...
        {} ...
        {'style' 'text' 'string' 'Tau (time lag):' 'fontweight' 'bold'} ...
        {'style' 'edit' 'string' '1' 'tag' 'tau'} ...
        {} ...
        {'style' 'text' 'string' 'Embedding dimension:' 'fontweight' 'bold'} ...
        {'style' 'edit' 'string' '2' 'tag' 'm'}  ...
            };
    param = inputgui(uigeom,uilist,'pophelp(''pop_entropy'')','entropy EEGLAB plugin',EEG);
    entropyType = eTypes{param{1}};
    if ~isempty(param{2})
        chanlist = split(param{2});
    else
        chanlist = {EEG.chanlocs.labels}';
    end
    tau  = str2double(param{3});
    m = str2double(param{4});

end


%% 2nd GUI to select additional parameters

if nargin == 1 && contains(entropyType, 'Multiscale')
    cTypes = {'Mean' 'Standard deviation (default)' 'Variance'};
    uigeom = { [.5 .4] .5 .5 };
    uilist = {
        {'style' 'text' 'string' 'Coarse graining method:'} ...
        {'style' 'popupmenu' 'string' cTypes 'tag' 'stype' 'value' 2} ...
        {} ...
        {'style' 'checkbox' 'string' 'Bandpass filter each time scale (default to control for spectral bias)','tag' 'filter','value',1}  ...
            };
    param = inputgui(uigeom,uilist,'pophelp(''pop_entropy'')','entropy EEGLAB plugin',EEG);
    coarseType = cTypes{param{1}};
    filter = logical(param{2});
end

%% 3rd GUI for fuzzy power

if nargin == 1 && contains(entropyType, 'Fuzzy')
    uigeom = { [.9 .3] };
    uilist = { {'style' 'text' 'string' 'Fuzzy power:' } ...
        {'style' 'edit' 'string' '2' 'tag' 'n'}  };
    param = inputgui(uigeom,uilist,'pophelp(''pop_entropy'')','entropy EEGLAB plugin',EEG);
    n = str2double(param{1});
end

%% Defaults if something was missed in command line

if ~exist('chanlist','var') || isempty(chanlist)
    disp('No channels were selected: selecting all channels (default)')
    chanlist = {EEG.chanlocs.labels}';
end
if ~exist('entropyType','var') || isempty(entropyType)
    disp('No entropy type selected: selecting Refined composite multiscale fuzzy entropy (default)')
    entropyType = 'Refined composite multiscale fuzzy entropy (default)';
end
if ~exist('tau','var') || isempty(tau)
    disp('No time lag selected: selecting tau = 1 (default).')
    tau = 1;
end
if ~exist('m','var') || isempty(m)
    disp('No embedding dimension selected: selecting m = 2 (default).')
    m = 2;
end
if contains(entropyType, 'Multiscale') && nargin > 4 && nargin < 6
    if ~exist('coarseType','var') || isempty(coarseType)
        disp('No coarse graining method selected: selecting standard deviation (default).')
        coarseType = 'Standard deviation';
    end
    if ~exist('filter','var') || isempty(filter)
        disp('Selecting bandpass filtering at each time scale to control for the spectral bias (default).')
        filtData = true;
    end
end
if contains(entropyType, 'fuzzy') 
    if ~exist('n','var') || isempty(n)
        disp('No fuzzy power selected: selecting n = 2 (default).')
        n = 2;
    end
end

%% Compute entropy depending on choices

% Hardcode r to .15 because data are scaled to have SD of 1
r = .15;
nchan = length(chanlist);

switch entropyType

    case 'Approximate entropy'
        disp('Computing approximate entropy...')
        ae = nan(nchan,1);
        for ichan = 1:nchan
            ae(ichan,:) = approx_entropy(EEG.data(ichan,:), m, r);
            fprintf('   %s: %6.3f \n', EEG.chanlocs(ichan).labels, ae(ichan,:))
        end

    case 'Sample entropy'
        disp('Computing sample entropy...')
        se = nan(nchan,1);
        % t1 = tic;
        if continuous && EEG.pnts <= 34000  % CHECK THRESHOLD
            disp('Computing sample entropy on continuous data (standard method)...')
            disp('If this takes too long, try the fast method (see main_script code)')
            for ichan = 1:nchan
                se(ichan,:) = sample_entropy(EEG.data(ichan,:),m,r,tau);  % standard method
                fprintf('   %s: %6.3f \n', EEG.chanlocs(ichan).labels, se(ichan,:))
            end

        else
            disp('Large continuous data detected, computing sample entropy using the fast method...')
            for ichan = 1:nchan
                se(ichan,:) = sample_entropy_fast(EEG.data(ichan,:),m,r); % fast method
                fprintf('   %s: %6.3f \n', EEG.chanlocs(ichan).labels, se(ichan,:))
            end
        end
        % t2 = toc(t1)
    
    case 'Fuzzy entropy'
        disp('Computing fuzzy entropy...')
        fe = nan(nchan,1);
        for ichan = 1:nchan
            [fe(ichan,:), p(ichan,:)] = fuzzy_entropy(EEG.data(ichan,:),m,r,n,tau);
            fprintf('   %s: %6.3f \n', EEG.chanlocs(ichan).labels, fe(ichan,:))
        end




    case 'Refined composite multiscale fuzzy entropy (default)'

        % number of scale factors to compute (starting at 2)
        nScales = inpdlg('Select fuzzy power: ');
        if isempty(nScales)
            nScales = 30;
        end

        % rcmfe_NN = RCMFE_std(data, 2, .15, 2, 1, nscalesNN);
        [rcmfe, scales] = get_rcmfe(data, m, r, fuzzypower, tau, nScales, EEG.srate);

% [1] H. Azami and J. Escudero, "Refined Multiscale Fuzzy Entropy based on Standard Deviation 
% for Biomedical Signal Analysis", Medical & Biological Engineering & Computing, 2016.


end

%% PLot results

% open convert_3Dto2D for plotting
