function [] = Animate(ModelParameters, AnimateParameters, varargin)
% Generation of an animation
%
%   INPUT
%   - ModelParameters: parameters of the musculoskeletal model,
%   automatically generated by the graphic interface 'GenerateParameters' 
%   - AnimateParameters: parameters of the animation, automatically
%   generated by the graphic interface 'GenerateAnimate'
%   - varargin: number of a frame to only save a figure
%________________________________________________________
%
% Licence
% Toolbox distributed under 3-Clause BSD License
%________________________________________________________
%
% Authors : Antoine Muller, Charles Pontonnier, Pierre Puchaud and
% Georges Dumont
%________________________________________________________

filename = AnimateParameters.filename(1:end-4);

seg_anim = AnimateParameters.seg_anim;
muscles_anim = AnimateParameters.muscles_anim;
mod_marker_anim = AnimateParameters.mod_marker_anim;
exp_marker_anim = AnimateParameters.exp_marker_anim;
external_force_anim = AnimateParameters.external_forces_anim;
external_force_pred = AnimateParameters.external_forces_pred;
solid_inertia_anim = 0;
efforts_prediction = 0;

% Files loading
load('BiomechanicalModel.mat'); %#ok<LOAD>
Human_model = BiomechanicalModel.OsteoArticularModel;
Markers_set = BiomechanicalModel.Markers;
Muscles = BiomechanicalModel.Muscles;
load([filename '/InverseKinematicsResults.mat']); %#ok<LOAD>
q = InverseKinematicsResults.JointCoordinates;
q6dof = InverseKinematicsResults.FreeJointCoordinates;
load([filename '/ExperimentalData.mat']); %#ok<LOAD>
real_markers = ExperimentalData.MarkerPositions;
time = ExperimentalData.Time;

if external_force_anim
    load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
    external_forces = ExternalForcesComputationResults.ExternalForcesExperiments;
end
if external_force_pred
    load([filename '/ExternalForcesComputationResults.mat']); %#ok<LOAD>
    external_forces_pred = ExternalForcesComputationResults.ExternalForcesPrediction;
end
if muscles_anim
    load([filename '/MuscleForcesComputationResults.mat']); %#ok<LOAD>
    Aopt = MuscleForcesComputationResults.MuscleActivations;
end

% exclude non used markers
Markers_set=Markers_set(find([Markers_set.exist])); %#ok<FNDSB>

% Calculs préliminaires
if seg_anim % anatomical position where other segments are attached
    [Human_model] = anat_position_solid_repere(Human_model,find(~[Human_model.mother]));
end
if external_force_anim || efforts_prediction % vector normalization
    lmax_vector_visual = 1; % longueur max du vecteur (en m)
    coef_f_visual=(ModelParameters.Mass*9.81)/lmax_vector_visual;
end

% figure
fig=figure('outerposition',[483,60,456*1.5,466*1.5]);
% xlim(AnimateParameters.xlim);
% ylim(AnimateParameters.ylim);
% zlim(AnimateParameters.zlim);
% view(AnimateParameters.view);

% Vidéo
if numel(varargin)
    f_affich = varargin{1};
else
    f_affich = 1:size(q,2);
end

%% Animation frame by frame
cpt = 0; % counter of number of frames to in video
for f=f_affich
    cpt = cpt + 1;
    clf
    %% paramètres figure
    axis equal
    hold on
    set(gca,'visible','off')
    xlim(AnimateParameters.xlim);
    ylim(AnimateParameters.ylim);
    zlim(AnimateParameters.zlim);
    view(AnimateParameters.view);
    
    if seg_anim
        %% direct kinematics
        qf(1,:)=q6dof(6,f);
        qf(2:size(q,1),:)=q(2:end,f);
        qf((size(q,1)+2):(size(q,1)+6),:)=q6dof(1:5,f);
        [Human_model_bis,Muscles_test, Markers_set_test]=ForwardKinematicsAnimation(Human_model,Markers_set,Muscles,qf,find(~[Human_model.mother]),muscles_anim,mod_marker_anim,solid_inertia_anim);

        %% segments
        for j=find([Human_model_bis.Visual])
            pts=Human_model_bis(j).pos_pts_anim;
            for np=1:size(pts,2)
                for npb=np:size(pts,2)
                    plot3(pts(1,[np npb]),pts(2,[np npb]),pts(3,[np npb]),'Color',0.4*[1 1 1],'LineWidth',4);
                end
            end
        end
    
        %% muscles
        if muscles_anim
            % couleur (fonction de l'activation)
            color0 = [0.9 0.9 0.9];
            color1 = [1 0 0];
            color_mus = color0 + Aopt(:,f)*(color1 - color0);
            for mu = 1:numel(Muscles_test)
                if Muscles_test(mu).exist
                    for nb_pts = 1:(size(Muscles_test(mu).pos_pts,2)-1)
                        plot3(Muscles_test(mu).pos_pts(1,[nb_pts nb_pts+1]),Muscles_test(mu).pos_pts(2,[nb_pts nb_pts+1]),Muscles_test(mu).pos_pts(3,[nb_pts nb_pts+1]),'Color',color_mus(mu,:),'LineWidth',1);
                    end
                end
            end
        end
        
    end
    
    %% Markers on the model
    if mod_marker_anim
        for marker = 1:numel(Markers_set_test)
            scatter3(Markers_set_test(marker).pos_anim(1,:),Markers_set_test(marker).pos_anim(2,:),Markers_set_test(marker).pos_anim(3,:),20,'filled','MarkerFaceColor',[255 102 0]/255)
        end
    end
    
    %% Experimental markers
    if exp_marker_anim
        for marker = 1:numel(real_markers)
            scatter3(real_markers(marker).position(f,1),real_markers(marker).position(f,2),real_markers(marker).position(f,3),20,'filled','MarkerFaceColor',[0 153 255]/255)
        end
    end
    
    %% Vectors of external forces issued from experimental data (Vecteurs efforts extérieurs issus de données expérimentales)
    if external_force_anim
        extern_forces_f = external_forces(f).Visual;
        color_vect = [53 210 55]/255;
        for nb_f=1:size(extern_forces_f,2)
            plot3([extern_forces_f(1,nb_f), extern_forces_f(1,nb_f) + extern_forces_f(4,nb_f)/coef_f_visual],...
            [extern_forces_f(2,nb_f), extern_forces_f(2,nb_f) + extern_forces_f(5,nb_f)/coef_f_visual],...
            [extern_forces_f(3,nb_f), extern_forces_f(3,nb_f) + extern_forces_f(6,nb_f)/coef_f_visual],...
            'color', color_vect, 'LineWidth', 2);
        end
    end
    
    %% Vectors of external forces issued from experimental data (Vecteurs efforts extérieurs issus de données expérimentales)
    if external_force_pred
        extern_forces_f = external_forces_pred(f).Visual;
        color_vect = 1-([53 210 55]/255);
        for nb_f=1:size(extern_forces_f,2)
            plot3([extern_forces_f(1,nb_f), extern_forces_f(1,nb_f) + extern_forces_f(4,nb_f)/coef_f_visual],...
            [extern_forces_f(2,nb_f), extern_forces_f(2,nb_f) + extern_forces_f(5,nb_f)/coef_f_visual],...
            [extern_forces_f(3,nb_f), extern_forces_f(3,nb_f) + extern_forces_f(6,nb_f)/coef_f_visual],...
            'color', color_vect, 'LineWidth', 2);
        end
    end
    
    
    %% affichage et sauvegarde (drawing an saving)
    drawnow
    M(cpt) = getframe(fig); %#ok<AGROW>
    
    %% on sauvegarde chaque posture utilisée pour faire la calibration (saving every posture used for calibration)
    if numel(varargin)
        saveas(fig,[filename '_' num2str(f)],'png');
        close(fig);
    end
end 

if ~numel(varargin)
    close all
    v=VideoWriter([filename '.avi']);
    v.FrameRate=1/time(2);
    open(v)
    writeVideo(v,M);
    close(v)
end

end
