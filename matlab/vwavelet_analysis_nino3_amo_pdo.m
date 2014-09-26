clc; clear all; close all;

fnames_nino_past = dir('../../processed/CMIP5/past1000/Omon/tos/NINO3_annual_mean_detrended/*.nc');
fnames_nino_ctrl = dir('../../processed/CMIP5/piControl/Omon/tos/NINO3_annual_mean_detrended/*.nc');

numfids = length(fnames_nino_past);
for K = 1:numfids
  nino_past(K,:)= squeeze(ncread(strcat('../../processed/CMIP5/past1000/Omon/tos/NINO3_annual_mean_detrended/',fnames_nino_past(K).name),'tas'));
  nino_ctrl(K,:)= squeeze(ncread(strcat('../../processed/CMIP5/piControl/Omon/tos/NINO3_annual_mean_detrended/',fnames_nino_ctrl(K).name),'tas'));
  model_names_tmp(K,:)=strsplit(fnames_nino_past(K).name,'_');
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

plot_mann=0;

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

    export_fig('../../plots/wavelets/NINO3_cwt_past1000_and_piControl','-png','-opengl','-r100')
    close(1);
    
end