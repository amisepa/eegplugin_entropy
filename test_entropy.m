clear; close all; clc
addpath('C:\Users\IONSLAB\Desktop\eegplugin_entropy')
eeglab

% EEG = pop_biosig('G:\Shared drives\Grants\Post Award Grants\(736) Bial Full-trance 2017\Research\Data\EEG\BDF_files\subj02_1.bdf');
% EEG = pop_chanedit(EEG, 'lookup','C:\\Users\\IONSLAB\\Documents\\MATLAB\\eeglab\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');
% EEG = pop_select(EEG, 'nochannel',{'EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'});
% file_path = 'G:\Shared drives\Science\IDL\5. DATA\muse\eeg\data_raw\sub-0a291a7fbc_ses-02_task-rest_run-01.csv';
% EEG = import_muse(file_path,'eeg');

EEG = pop_loadset('filename','sub-003_task-breathcounting.set','filepath','G:\\Shared drives\\Science\\IDL\\5. DATA\\muse\\eeg\\eeg_clean\\sub-003\\eeg\\');

EEG = pop_chanedit(EEG, 'lookup','C:\\Users\\IONSLAB\\Documents\\MATLAB\\eeglab\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');
% EEG = pop_eegfiltnew(EEG,'locutoff',1);
% EEG = eeg_regepochs(EEG);
EEG = pop_entropy(EEG);


