function [] = Installation()
% Installation function of the Toolbox
%   Run the script with F5 or the press Run button to install the toolbox
%   and verify if you have the compatible toolboxes
%________________________________________________________
%
% Licence
% Toolbox distributed under 3-Clause BSD License
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

%% Check the matlab version
cur_version = version('-release');
cur_version(isletter(cur_version)) = [];
cur_version = str2double(cur_version);

if cur_version>=2018 % the version needs to be at least from 2018.
    disp(['Your Matlab version ' version ' is compatible with CusToM toolbox'])
else
    warning(sprintf('Your Matlab version is too old for CusToM \n you need at least Matlab 9.4.0.813654 (R2018a)'))
end

%% Check the toolboxes
Needed_Toolboxes_for_CusToM= {'Optimization Toolbox';'Parallel Computing Toolbox';'Symbolic Math Toolbox'};
Toolboxes = ver;
Toolboxes_list={Toolboxes.Name}';

Toolboxes_installed = intersect(Needed_Toolboxes_for_CusToM,Toolboxes_list);
Toolboxes_not_available = setdiff(Needed_Toolboxes_for_CusToM,Toolboxes_list);

if isempty(Toolboxes_installed)
    s = ['None of the required Toolboxes are installed to run CuToM' '\n' ...
        'You need the following toolbox to run CusToM:'];
    for ii =1:length(Toolboxes_not_available)
        s=[s '\n' Toolboxes_not_available{ii}];
    end
    error(sprintf(s));
elseif isempty(Toolboxes_not_available)
    disp(' All the required Toolboxes are installed to run CuToM');
    disp(Toolboxes_installed);
else
    disp('Required Toolboxes installed to run CuToM');
    disp(Toolboxes_installed);
    s = ['Toolboxes not installed to run CuToM' '\n' ...
        'You need the following toolbox to run CusToM:'];
    for ii =1:length(Toolboxes_not_available)
        s=[s '\n' Toolboxes_not_available{ii}];
    end
    error(sprintf(s));
end

%% Add to path the folder with all the functions
disp('The functions folder has been added to the current path')
addpath(genpath('Functions'));

disp('You can run a Simulation into the Examples folder or follow the written tutorials in the CusToM documentation')

end
