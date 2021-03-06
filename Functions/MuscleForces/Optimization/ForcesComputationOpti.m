function [MuscleForcesComputationResults] = ForcesComputationOpti(filename, BiomechanicalModel, AnalysisParameters)
% Computation of the muscle forces estimation step by using an optimization method
%
%	Based on :
%	- Crowninshield, R. D., 1978. 
%	Use of optimization techniques to predict muscle forces. Journal of Biomechanical Engineering, 100(2), 88-92.
%
%   INPUT
%   - filename: name of the file to process (character string)
%   - BiomechanicalModel: musculoskeletal model
%   - AnalysisParameters: parameters of the musculoskeletal analysis,
%   automatically generated by the graphic interface 'Analysis' 
%   OUTPUT
%   - MuscleForcesComputationResults: results of the muscle forces
%   estimation step (see the Documentation for the structure) 
%________________________________________________________
%
% Licence
% Toolbox distributed under 3-Clause BSD License
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________
disp(['Forces Computation (' filename ') ...'])

%% Loading variables
Moment_Arms = BiomechanicalModel.MomentArms;
Muscles = BiomechanicalModel.Muscles;
load([filename '/InverseKinematicsResults']) %#ok<LOAD>
q = InverseKinematicsResults.JointCoordinates;
load([filename '/InverseDynamicsResults']) %#ok<LOAD>
torques = InverseDynamicsResults.JointTorques;

%%  Detection of joints concerned by the muscles
n=0;
for i=1:size(Moment_Arms,1)
    for j=1:size(Moment_Arms,2)
        if ~isnumeric(Moment_Arms{i,j})
           n=n+1;
           art_muscles(n)=i; %#ok<AGROW>
           break
        end
    end
end

%% Computation of muscle forces (optimization)

% Optimisation parameters
F0 = zeros(numel(Muscles),1);
Fmin = zeros(numel(Muscles),1);

Fopt = zeros(numel(Muscles),size(torques,2));
Aopt = zeros(size(Fopt));
Aeq=zeros(numel(art_muscles),numel(Muscles));

options = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','GradConstr','off','TolFun',1e-6);
% options = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','GradConstr','off','TolFun',1e-9,'MaxFunEvals',20000);
% options = optimoptions(@fmincon,'Algorithm','sqp','Display','off','GradObj','off','GradConstr','off','TolFun',1e-9,'MaxFunEvals',100000,'TolX',1e-9,'StepTolerance',1e-15,'FunctionTolerance',1e-10,'MaxIterations',5000);

nb_frame=size(Fopt,2);
h = waitbar(0,['Forces Computation (' filename ')']);
tic
for i=1:size(Fopt,2) % for each frames
%     i
    % computation of muscle moment arms from joint posture
    c=0;
    for m=art_muscles
        c=c+1;
        for j=1:numel(Muscles)
            if isnumeric(Moment_Arms{m,j})
                Aeq(c,j)=0;
            else
                Aeq(c,j) = Moment_Arms{m,j}(q(:,i)) ; % R
            end
        end
    end
    % Joint Torques
    beq=torques(art_muscles,i); % C
    % Fmax
    Fmax = [Muscles.f0]';
    % Optimization
    Fopt(:,i) = AnalysisParameters.Muscles.Costfunction(F0, Aeq, beq, Fmin, Fmax, options, AnalysisParameters.Muscles.CostfunctionOptions, Fmax);
    % Muscular activity
    Aopt(:,i) = Fopt(:,i)./Fmax;
    F0=Fopt(:,i);
    waitbar(i/nb_frame)

end
close(h)
% w=toc; %#ok<NASGU>

MuscleForcesComputationResults.MuscleActivations = Aopt;
MuscleForcesComputationResults.MuscleForces = Fopt;

disp(['... Forces Computation (' filename ') done'])


end