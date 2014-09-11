clc; clear all; close all;

%cd '../../data/TSI/wavelet_analysis/'

mann_tas_nh=squeeze(ncread('../../data/observations/Mann_et_al_2009/mann2009_reconstruction_NH_mean_anomaly_0856-1845_decadal_running_mean.nc','tas'))';
mann_tas_sh=squeeze(ncread('../../data/observations/Mann_et_al_2009/mann2009_reconstruction_SH_mean_anomaly_0856-1845_decadal_running_mean.nc','tas'))';
mann_tas_global=squeeze(ncread('../../data/observations/Mann_et_al_2009/mann2009_reconstruction_global_mean_anomaly_0856-1845_decadal_running_mean.nc','tas'))';
roth_tsi=squeeze(ncread('../../data/TSI/Roth_and_Joos_2013/TSI_Holocene_Roth_and_Joos_0856-1845.nc','TSI'))';

fnames_nh = dir('../../processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_running_mean_detrended/*.nc');
fnames_sh = dir('../../processed/CMIP5/past1000/Amon/tas/SH_mean_anomaly_decadal_running_mean_detrended/*.nc');
fnames_global = dir('../../processed/CMIP5/past1000/Amon/tas/global_mean_anomaly_decadal_running_mean_detrended/*.nc');
numfids = length(fnames_nh);
for K = 1:numfids
  model_tas_nh(K,:)= squeeze(ncread(strcat('../../processed/CMIP5/past1000/Amon/tas/NH_mean_anomaly_decadal_running_mean_detrended/',fnames_nh(K).name),'tas'));
  model_tas_sh(K,:)= squeeze(ncread(strcat('../../processed/CMIP5/past1000/Amon/tas/SH_mean_anomaly_decadal_running_mean_detrended/',fnames_sh(K).name),'tas'));
  model_tas_global(K,:)= squeeze(ncread(strcat('../../processed/CMIP5/past1000/Amon/tas/global_mean_anomaly_decadal_running_mean_detrended/',fnames_global(K).name),'tas')); 
  model_names_tmp(K,:)=strsplit(fnames_nh(K).name,'_');
  model_names(K,1)=model_names_tmp(K,6);
end

ct=load('WhiteBlueGreenYellowRed.rgb');
ct=ct/256;

time=[856:1:1845];

min_scale=1;
max_scale=800;

line_width=2;
line_style='-';
line_color=[.7 .7 .7];
font_size=16;
font_size_heading=30;
monte_carlo=25;
arrow_size=.8;
Arrow_Head_Size=.4;
Arrow_Density=[15 15];

period_1=87;
period_2=210;

plot_mann=1;

if plot_mann==1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Continuous wavelet transform (CWT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    f=figure(1);
    set(f,'Color','white')
    maximize(1)
    
    colormap(ct);

    for nn=1:11   
        subplot(6,2,nn)
        if nn==1;
            wt([time;mann_tas_nh],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title('Mann (tas NH mean)','fontsize',font_size);
        else
            wt([time;model_tas_nh(nn-1,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title(strcat(model_names(nn-1),' (tas NH mean)'),'fontsize',font_size);
        end
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet transform tas NH mean and Mann et al. tas NH mean','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_NH_mean_tas_NH_mean_cwt','-png','-opengl','-r100')
    close(1);
    
    f=figure(1);
    set(f,'Color','white')
    maximize(1)
    
    colormap(ct);

    for nn=1:11   
        subplot(6,2,nn)
        if nn==1;
            wt([time;mann_tas_sh],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title('Mann (tas SH mean)','fontsize',font_size);
        else
            wt([time;model_tas_sh(nn-1,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title(strcat(model_names(nn-1),' (tas SH mean)'),'fontsize',font_size);
        end
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet transform tas SH mean and Mann et al. tas SH mean','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_SH_mean_tas_SH_mean_cwt','-png','-opengl','-r100')
    close(1);
    
    
    f=figure(1);
    set(f,'Color','white')
    maximize(1)
    
    colormap(ct);

    for nn=1:11   
        subplot(6,2,nn)
        if nn==1;
            wt([time;mann_tas_global],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title('Mann (tas global mean)','fontsize',font_size);
        else
            wt([time;model_tas_global(nn-1,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title(strcat(model_names(nn-1),' (tas global mean)'),'fontsize',font_size);
        end
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet transform tas global mean and Mann et al. tas global mean','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_global_mean_tas_global_mean_cwt','-png','-opengl','-r100')
    close(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Wavelet coherence (WTC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    f=figure(1);
    set(f,'Color','white')
    maximize(1)

    colormap(ct);

    for nn=1:10
        subplot(5,2,nn)
        wtc([time;mann_tas_nh],[time;model_tas_nh(nn,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1,'MonteCarloCount',monte_carlo,'ArrowDensity',Arrow_Density,'ArrowSize',arrow_size,'ArrowHeadSize',Arrow_Head_Size);
        title(strcat(' Mann (tas NH mean) and ',model_names(nn),' (tas NH mean)'),'fontsize',font_size);
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet coherence tas NH mean with Mann et al. tas NH mean','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_NH_mean_tas_NH_mean_wtc','-png','-opengl','-r100')
    close(1);

    f=figure(1);
    set(f,'Color','white')
    maximize(1)

    colormap(ct);

    for nn=1:10
        subplot(5,2,nn)
        wtc([time;mann_tas_sh],[time;model_tas_sh(nn,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1,'MonteCarloCount',monte_carlo,'ArrowDensity',Arrow_Density,'ArrowSize',arrow_size,'ArrowHeadSize',Arrow_Head_Size);
        title(strcat(' Mann (tas SH mean) and ',model_names(nn),' (tas SH mean)'),'fontsize',font_size);
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet coherence tas SH mean with Mann et al. tas SH mean','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_SH_mean_tas_SH_mean_wtc','-png','-opengl','-r100')
    close(1);

    

    f=figure(1);
    set(f,'Color','white')
    maximize(1)

    colormap(ct);

    for nn=1:10
        subplot(5,2,nn)
        wtc([time;mann_tas_global],[time;model_tas_global(nn,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1,'MonteCarloCount',monte_carlo,'ArrowDensity',Arrow_Density,'ArrowSize',arrow_size,'ArrowHeadSize',Arrow_Head_Size);
        title(strcat(' Mann (tas global mean) and ',model_names(nn),' (tas global mean)'),'fontsize',font_size);
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet coherence tas global mean with Mann et al. tas global mean','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_global_mean_tas_global_mean_wtc','-png','-opengl','-r100')
    close(1);

end

plot_TSI=1;

if plot_TSI==1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Continuous wavelet transform (CWT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    f=figure(1);
    set(f,'Color','white')
    maximize(1)
    
    colormap(ct);

    for nn=1:11   
        subplot(6,2,nn)
        if nn==1;
            wt([time;roth_tsi],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title('Roth (TSI)','fontsize',font_size);
        else
            wt([time;model_tas_nh(nn-1,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title(strcat(model_names(nn-1),' (tas NH mean)'),'fontsize',font_size);
        end
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet transform tas NH mean and TSI','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_NH_mean_TSI_cwt','-png','-opengl','-r100')
    close(1);
    
    f=figure(1);
    set(f,'Color','white')
    maximize(1)
    
    colormap(ct);

    for nn=1:11   
        subplot(6,2,nn)
        if nn==1;
            wt([time;roth_tsi],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title('Roth (TSI)','fontsize',font_size);
        else
            wt([time;model_tas_sh(nn-1,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title(strcat(model_names(nn-1),' (tas SH mean)'),'fontsize',font_size);
        end
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet transform tas SH mean and TSI','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_SH_mean_TSI_cwt','-png','-opengl','-r100')
    close(1);
    
    f=figure(1);
    set(f,'Color','white')
    maximize(1)
    
    colormap(ct);

    for nn=1:11   
        subplot(6,2,nn)
        if nn==1;
            wt([time;roth_tsi],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title('Roth (TSI)','fontsize',font_size);
        else
            wt([time;model_tas_global(nn-1,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1);
            title(strcat(model_names(nn-1),' (tas global mean)'),'fontsize',font_size);
        end
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet transform tas global mean and TSI','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_global_mean_TSI_cwt','-png','-opengl','-r100')
    close(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Wavelet coherence (WTC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    f=figure(1);
    set(f,'Color','white')
    maximize(1)

    colormap(ct);

    for nn=1:10
        subplot(5,2,nn)
        wtc([time;roth_tsi],[time;model_tas_nh(nn,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1,'MonteCarloCount',monte_carlo,'ArrowDensity',Arrow_Density,'ArrowSize',arrow_size,'ArrowHeadSize',Arrow_Head_Size);
        title(strcat(' Roth (TSI) and ',model_names(nn),' (tas NH mean)'),'fontsize',font_size);
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet coherence tas NH mean with TSI','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_NH_mean_TSI_wtc','-png','-opengl','-r100')
    close(1);
 
    f=figure(1);
    set(f,'Color','white')
    maximize(1)

    colormap(ct);

    for nn=1:10
        subplot(5,2,nn)
        wtc([time;roth_tsi],[time;model_tas_sh(nn,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1,'MonteCarloCount',monte_carlo,'ArrowDensity',Arrow_Density,'ArrowSize',arrow_size,'ArrowHeadSize',Arrow_Head_Size);
        title(strcat(' Roth (TSI) and ',model_names(nn),' (tas SH mean)'),'fontsize',font_size);
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet coherence tas SH mean with TSI','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_SH_mean_TSI_wtc','-png','-opengl','-r100')
    close(1);

    
    f=figure(1);
    set(f,'Color','white')
    maximize(1)

    colormap(ct);

    for nn=1:10
        subplot(5,2,nn)
        wtc([time;roth_tsi],[time;model_tas_global(nn,:)],'S0',min_scale,'maxscale',max_scale,'Pad',1,'MonteCarloCount',monte_carlo,'ArrowDensity',Arrow_Density,'ArrowSize',arrow_size,'ArrowHeadSize',Arrow_Head_Size);
        title(strcat(' Roth (TSI) and ',model_names(nn),' (tas global mean)'),'fontsize',font_size);
        ylabel('Period [years]','fontsize',font_size)
        h1=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
        h2=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
        set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
        set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
    end

    [ax,s]=suplabel('wavelet coherence tas global mean with TSI','t');
    set(s,'fontsize',font_size_heading)

    export_fig('../../plots/wavelets/tas_global_mean_TSI_wtc','-png','-opengl','-r100')
    close(1);

    
end
