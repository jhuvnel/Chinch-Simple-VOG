% test
close all
clear; clc;

path1 = '/Volumes/labdata/Fernandez Brillet/DC Safety Expts/Ch301/20221201/';
path2 = 'BiphasicPulse_2sPerPhase_Sweep';
obj = VideoReader([path1 path2 '.mov']);
NumberOfFrames = obj.NumberOfFrames;

% Set ROI
figure(1);
frame_ex=read(obj,10);
imagesc(frame_ex);
r1 = drawrectangle('Label','Eye','Color',[1 0 0]);
r1 = r1.Position;

previous_centroid = nan(NumberOfFrames,2);

%% 
frame=read(obj,10);
rows=size(frame,1);
cols=size(frame,2);
% Center
cent_rows=round(rows/2);
cent_cols=round(cols/2);
figure(1);
for cnt = 1:NumberOfFrames       
    frame=read(obj,cnt);
    frame = imcrop(frame,r1);
    if size(frame,3)==3
        frame=rgb2gray(frame);
    end
    subplot(212)
    piel=~im2bw(frame,0.19);
    %     --
    piel=bwmorph(piel,'close');
    piel=bwmorph(piel,'open');
    piel=bwareaopen(piel,200);
    piel=imfill(piel,'holes');
    imagesc(piel);
    colormap gray
    % Tagged objects in BW image
    L=bwlabel(piel);
    % Get areas and tracking rectangle
    out_a=regionprops(L,'Centroid','Circularity','BoundingBox');
    % Count the number of objects
    N=size(out_a,1);
    if N < 1 || isempty(out_a) % Returns if no object in the image
        solo_cara=[ ];
        continue
    end
    % ---
    % Select larger area
    circ = [out_a.Circularity];
    [circ_opt pcm]=max(circ);
    num_retry = 0;
    while cnt > 1 && (pdist2(out_a(pcm).Centroid, previous_centroid(cnt-1,:))>130)
        num_retry = num_retry+1;
        [sort_circ,indx_circ] = sort(circ);
        pcm = indx_circ(end-num_retry);
        circ_opt = sort_circ(end-num_retry);
    end
    subplot(211)
    imagesc(frame);
    colormap gray
    hold on
    rectangle('Position',out_a(pcm).BoundingBox,'EdgeColor',[1 0 0],...
        'Curvature', [1,1],'LineWidth',2)
    centro=round(out_a(pcm).Centroid);
    centro=out_a(pcm).Centroid;
    X=centro(1);
    Y=centro(2);
    previous_centroid(cnt,:) = [X,Y];
    plot(X,Y,'g+')
    
    text(X+10,Y,['(',num2str(X),',',num2str(Y),')'],'Color',[1 1 1])
    if X<cent_cols && Y<cent_rows
        title('Top left')
    elseif X>cent_cols && Y<cent_rows
        title('Top right')
    elseif X<cent_cols && Y>cent_rows
        title('Bottom left')
    else
        title('Bottom right')
    end
    hold off
    % --
    drawnow;
end

figure(2)
plot(previous_centroid(:,1),previous_centroid(:,2))
xlim([0 r1(3)])
ylim([0 r1(4)])
set(gca, 'YDir','reverse')