clc; clear all; close all;

fnames_nino_KCM= dir('../../data/KCM/NINO3/*tsw*.nc');
order=[4,2,6,3,5,1];
forcing_period={'1000 years','1000 years','200 years','100 years','60 years','control'}


numfids = length(fnames_nino_KCM);
for K = 1:numfids
  
  nino_tmp_KCM=squeeze(ncread(strcat('../../data/KCM/NINO3/',fnames_nino_KCM(K).name),'tsw'));
 
  nino_time_KCM(K,1:length(nino_tmp_KCM))=[1:1:length(nino_tmp_KCM)];
  nino_length_time_KCM(K)=length(nino_tmp_KCM);
  
  model_names_tmp(K,:)=strsplit(fnames_nino_KCM(K).name,'_');
  model_names(K,1)=model_names_tmp(K,2);
  
  nino_KCM(K,1:length(nino_tmp_KCM))=nino_tmp_KCM;


end

ct=load('WhiteBlueGreenYellowRed.rgb');
ct=ct/256;

min_scale=2;
max_scale=2000;

line_width=2;
line_style='-';
line_color=[.7 .7 .7];
font_size=16;
font_size_heading=14;
monte_carlo=25;
arrow_size=.8;
Arrow_Head_Size=.4;
Arrow_Density=[15 15];




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Continuous wavelet transform (CWT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NINO3 past1000

plot_nino_past=1;

if plot_nino_past==1

    f=figure(1);
    
    set(f,'Color','white')
    set(f,'Units','centimeters')
    set(f, 'Position', [2 2 20 30])
    ii=1;
    colormap(ct);

    for nn=order
        
        subplot(3,2,ii)
        wt([nino_time_KCM(nn,1:nino_length_time_KCM(nn));nino_KCM(nn,1:nino_length_time_KCM(nn))],'S0',min_scale,'maxscale',max_scale,'Pad',1);
        title(strcat(model_names(nn),' (',forcing_period(ii),')'),'fontsize',font_size);
        ii=ii+1;
        
    end

    [ax,s]=suplabel('wavelet transform NINO3 index KCM experiments','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/KCM_NINO3_cwt','-png','-r150')
    %close(1);

end