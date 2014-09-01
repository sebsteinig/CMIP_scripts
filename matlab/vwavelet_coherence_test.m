clc; clear all; close all;

%cd '../../data/TSI/wavelet_analysis/'

roth=load('../../data/TSI/wavelet_analysis/roth.txt');
vieira=load('../../data/TSI/wavelet_analysis/vieira.txt');
steinhilber09=load('../../data/TSI/wavelet_analysis/steinhilber09.txt');
steinhilber12=load('../../data/TSI/wavelet_analysis/steinhilber12.txt');
sbf=load('../../data/TSI/wavelet_analysis/SBF.txt');
db=load('../../data/TSI/wavelet_analysis/DB.txt');
mea=load('../../data/TSI/wavelet_analysis/MEA.txt');
vk=load('../../data/TSI/wavelet_analysis/VK.txt');

ct=load('WhiteBlueGreenYellowRed.rgb');
ct=ct/256;

roth_running=roth;
roth_tmp=moving_average(roth(:,2),11);
roth_running(:,2)=roth_tmp;
roth_5=roth_running(4:5:end,:);
roth_10=roth_running(6:10:end,:);
roth_22=roth_running(18:22:end,:);

steinhilber12(:,2)=steinhilber12(:,2)+1365.57;
steinhilber12(:,1)=1950-steinhilber12(:,1);
steinhilber12=flipud(steinhilber12);

steinhilber09(:,2)=steinhilber09(:,2)+1365.57;
steinhilber09(:,1)=1950.5-steinhilber09(:,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Continuous wavelet transform (CWT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tlim_left=[min([roth(1,1) vieira(1,1) steinhilber09(1,1) steinhilber12(1,1)]) max([roth(end,1) vieira(end,1) steinhilber09(end,1) steinhilber12(end,1)])];
tlim_right=[min([sbf(1,1) db(1,1) mea(1,1) vk(1,1)]) max([sbf(end,1) db(end,1) mea(end,1) vk(end,1)])];

min_scale_left=2;
max_scale_left=4000;

min_scale_right=2;
max_scale_right=400;

line_width=2;
line_style='--';
line_color='k';
font_size=16;

period_1=87;
period_2=210;
period_3=1000;

%figure(1)
%maximize(1)

colormap(ct);

cwt_data_left={roth,vieira,steinhilber09,steinhilber12};
cwt_names_left={'Roth et al. (2012)','Vieira et al. (2011)','Steinhilber et al. (2009)','Steinhilber et al. (2012)'};

% % left panel side
% for nn=1:4   
%     subplot(4,2,(nn*2)-1)
%     wt(cell2mat(cwt_data_left(nn)),'S0',min_scale_left,'maxscale',max_scale_left,'Pad',1);
%     title(cwt_names_left(nn),'fontsize',font_size);
%     set(gca,'xlim',tlim_left,'fontsize',font_size);
%     ylabel('Period','fontsize',font_size)
%     h1=line([-10000 2000],[log2(period_1) log2(period_1)],[0 0]);
%     h2=line([-10000 2000],[log2(period_2) log2(period_2)],[0 0]); 
%     h3=line([-10000 2000],[log2(period_3) log2(period_3)],[0 0]); 
%     set(h1,'linewidth',line_width,'linestyle',line_style,'color',line_color)
%     set(h2,'linewidth',line_width,'linestyle',line_style,'color',line_color)
%     set(h3,'linewidth',line_width,'linestyle',line_style,'color',line_color)
% end
% 
% cwt_data_right={sbf,db,mea,vk};
% cwt_names_right={'SBF','DB','MEA','VK'};
% 
% % right panel side
% 
% for nn=1:4   
%     subplot(4,2,nn*2)
%     wt(cell2mat(cwt_data_right(nn)),'S0',min_scale_right,'maxscale',max_scale_right,'Pad',1);
%     title(cwt_names_right(nn),'fontsize',font_size);
%     set(gca,'xlim',tlim_right,'fontsize',font_size);
%     ylabel('Period','fontsize',font_size)
%     h4=line([800 2000],[log2(period_1) log2(period_1)],[0 0]);
%     h5=line([800 2000],[log2(period_2) log2(period_2)],[0 0]); 
%     h6=line([800 2000],[log2(period_3) log2(period_3)],[0 0]); 
%     set(h4,'linewidth',line_width,'linestyle',line_style,'color',line_color)
%     set(h5,'linewidth',line_width,'linestyle',line_style,'color',line_color)
%     set(h6,'linewidth',line_width,'linestyle',line_style,'color',line_color)  
% end
% 
% export_fig('../../../plots/wavelets/cwt','-png','-opengl','-r100')
% close(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Cross wavelet transform (XWT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(2)
maximize(2)

xwt_data_left={vieira,steinhilber09,steinhilber12};
xwt_data_left_reference={roth_10,roth_5,roth_22};
xwt_names_left={'XWT between Roth and Vieira','XWT between Roth and Steinhilber (2009)','XWT between Roth and Steinhilber (2012)'};

for nn=1:3
    subplot(4,2,(nn*2)-1)
    xwt(cell2mat(xwt_data_left_reference(nn)),cell2mat(xwt_data_left(nn)),'S0',min_scale_left,'maxscale',max_scale_left,'Pad',1,'ArrowDensity',[20 20],'ArrowSize',.5,'ArrowHeadSize',.4)
    title(xwt_names_left(nn),'fontsize',font_size);
end

xwt_data_right={sbf,db,mea,vk};
xwt_data_right_reference={roth,roth,roth,roth};
xwt_names_right={'XWT between Roth and SBF','XWT between Roth and DB','XWT between Roth and MEA','XWT between Roth and VK'};

for nn=1:4
    subplot(4,2,nn*2)
    xwt(cell2mat(xwt_data_right_reference(nn)),cell2mat(xwt_data_right(nn)),'S0',min_scale_right,'maxscale',max_scale_right,'Pad',1,'ArrowDensity',[20 20],'ArrowSize',.5,'ArrowHeadSize',.4)
    title(xwt_names_right(nn),'fontsize',font_size);
end

export_fig('../../../plots/wavelets/xwt','-png','-opengl','-r100')
close(2);
    