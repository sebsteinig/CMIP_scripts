clc; clear all; close all;

fnames_nino_past = dir('../../processed/CMIP5/past1000/Omon/tos/NINO3_original_resolution_monthly_mean_detrended/*.nc');
fnames_nino_ctrl = dir('../../processed/CMIP5/piControl/Omon/tos/NINO3_original_resolution_monthly_mean_detrended/*.nc');
fnames_amo_past = dir('../../processed/CMIP5/past1000/Omon/tos/AMO_original_resolution_monthly_mean_detrended/*.nc');
fnames_amo_ctrl = dir('../../processed/CMIP5/piControl/Omon/tos/AMO_original_resolution_monthly_mean_detrended/*.nc');

nino_tmp_mann=squeeze(ncread('../../data/observations/Mann_et_al_2009/mann2009_reconstruction_NINO3_0856-1845.nc','tas'));
nino_time_mann(1,1:length(nino_tmp_mann))=[1:1:length(nino_tmp_mann)];
nino_length_time_mann=length(nino_tmp_mann);
nino_mann(1,1:length(nino_tmp_mann))=nino_tmp_mann;


numfids = length(fnames_nino_past);
for K = 1:numfids
  
  nino_tmp_past=squeeze(ncread(strcat('../../processed/CMIP5/past1000/Omon/tos/NINO3_original_resolution_monthly_mean_detrended/',fnames_nino_past(K).name),'tos'));
  nino_tmp_past_annual=NaN(floor(length(nino_tmp_past)/12),1);
  for ii=1:length(nino_tmp_past)/12
       nino_tmp_past_annual(ii,1)=mean(nino_tmp_past((12*ii)-11:12*ii,1));
  end
  
  amo_tmp_past=squeeze(ncread(strcat('../../processed/CMIP5/past1000/Omon/tos/AMO_original_resolution_monthly_mean_detrended/',fnames_amo_past(K).name),'tos'));
  amo_tmp_past_annual=NaN(floor(length(amo_tmp_past)/12),1);
  for ii=1:length(amo_tmp_past)/12
       amo_tmp_past_annual(ii,1)=mean(amo_tmp_past((12*ii)-11:12*ii,1));
  end

  
  nino_tmp_ctrl=squeeze(ncread(strcat('../../processed/CMIP5/piControl/Omon/tos/NINO3_original_resolution_monthly_mean_detrended/',fnames_nino_ctrl(K).name),'tos'));
  nino_tmp_ctrl_annual=NaN(floor(length(nino_tmp_ctrl)/12),1);
  for ii=1:length(nino_tmp_ctrl)/12
       nino_tmp_ctrl_annual(ii,1)=mean(nino_tmp_ctrl((12*ii)-11:12*ii,1));
  end
  
  amo_tmp_ctrl=squeeze(ncread(strcat('../../processed/CMIP5/piControl/Omon/tos/AMO_original_resolution_monthly_mean_detrended/',fnames_amo_ctrl(K).name),'tos'));
  amo_tmp_ctrl_annual=NaN(floor(length(amo_tmp_ctrl)/12),1);
  for ii=1:length(amo_tmp_ctrl)/12
       amo_tmp_ctrl_annual(ii,1)=mean(amo_tmp_ctrl((12*ii)-11:12*ii,1));
  end

  
  nino_time_ctrl(K,1:length(nino_tmp_ctrl_annual))=[1:1:length(nino_tmp_ctrl_annual)];
  nino_length_time_ctrl(K)=length(nino_tmp_ctrl_annual);
  nino_time_past(K,1:length(nino_tmp_past_annual))=[1:1:length(nino_tmp_past_annual)];
  nino_length_time_past(K)=length(nino_tmp_past_annual);

  amo_time_ctrl(K,1:length(amo_tmp_ctrl_annual))=[1:1:length(amo_tmp_ctrl_annual)];
  amo_length_time_ctrl(K)=length(amo_tmp_ctrl_annual);
  amo_time_past(K,1:length(amo_tmp_past_annual))=[1:1:length(amo_tmp_past_annual)];
  amo_length_time_past(K)=length(amo_tmp_past_annual);
  
  nino_past(K,1:length(nino_tmp_past_annual))=nino_tmp_past_annual;
  nino_ctrl(K,1:length(nino_tmp_ctrl_annual))=nino_tmp_ctrl_annual;
  amo_past(K,1:length(amo_tmp_past_annual))=amo_tmp_past_annual;
  amo_ctrl(K,1:length(amo_tmp_ctrl_annual))=amo_tmp_ctrl_annual;
  
  model_names_tmp(K,:)=strsplit(fnames_nino_past(K).name,'_');
  model_names(K,1)=model_names_tmp(K,3);

end

ct=load('WhiteBlueGreenYellowRed.rgb');
ct=ct/256;

%nino_time_past=[1:1:length(nino_tmp_past_annual)];
%amo_time_past=[1:1:length(amo_tmp_past_annual)];



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
    
    colormap(ct);

    for nn=1:7   
        subplot(4,2,nn)
        wt([nino_time_past(nn,1:nino_length_time_past(nn));nino_past(nn,1:nino_length_time_past(nn))],'S0',min_scale,'maxscale',max_scale,'Pad',1);
        title(model_names(nn),'fontsize',font_size);
        xlabel('')
    end
    
        subplot(4,2,8)
        wt([nino_time_mann(1,1:nino_length_time_mann);nino_mann(1,1:nino_length_time_mann(1))],'S0',min_scale,'maxscale',max_scale,'Pad',1);
        title('Mann reconstruction','fontsize',font_size);
        xlabel('')
    

    [ax,s]=suplabel('wavelet transform NINO3 index past1000 experiments','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/NINO3_cwt_past1000','-png','-r150')
    %close(1);

end
%% NINO3 piControl

plot_nino_ctrl=0;

if plot_nino_ctrl==1
    
    f=figure(1);
    
    set(f,'Color','white')
    set(f,'Units','centimeters')
    set(f, 'Position', [2 2 20 30])

    colormap(ct);

    for nn=1:7   
        subplot(4,2,nn)
        wt([nino_time_ctrl(nn,1:nino_length_time_ctrl(nn));nino_ctrl(nn,1:nino_length_time_ctrl(nn))],'S0',min_scale,'maxscale',max_scale,'Pad',1);
        title(model_names(nn),'fontsize',font_size);
    end

    [ax,s]=suplabel('wavelet transform NINO3 index piControl experiments','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/NINO3_cwt_piControl','-png','-r150')
    close(1);

end

%% AMO past1000

plot_amo_past=0;

if plot_amo_past==1

    f=figure(1);
    
    set(f,'Color','white')
    set(f,'Units','centimeters')
    set(f, 'Position', [2 2 20 30])
    
    colormap(ct);

    for nn=1:7   
        subplot(4,2,nn)
        wt([amo_time_past(nn,1:amo_length_time_past(nn));amo_past(nn,1:amo_length_time_past(nn))],'S0',min_scale,'maxscale',max_scale,'Pad',1);
        title(model_names(nn),'fontsize',font_size);
    end

    [ax,s]=suplabel('AMO index past1000 experiments','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/AMO_cwt_past1000','-png','-r150')
    close(1);

end
%% NINO3 piControl

plot_amo_ctrl=0;

if plot_amo_ctrl==1
    
    f=figure(1);
    
    set(f,'Color','white')
    set(f,'Units','centimeters')
    set(f, 'Position', [2 2 20 30])

    colormap(ct);

    for nn=1:7   
        subplot(4,2,nn)
        wt([amo_time_ctrl(nn,1:amo_length_time_ctrl(nn));amo_ctrl(nn,1:amo_length_time_ctrl(nn))],'S0',min_scale,'maxscale',max_scale,'Pad',1);
        title(model_names(nn),'fontsize',font_size);
    end

    [ax,s]=suplabel('AMO index piControl experiments','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/AMO_cwt_piControl','-png','-r150')
    close(1);

end