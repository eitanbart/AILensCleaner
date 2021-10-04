function vertices = FindVerticesWithHoughLines(semanticNet,img,numOrig)

%% perform Semantic Segmentation to extract a feature map
C = semanticseg(img,semanticNet);
featureMap = (C=='Frame');
% featureMap = (featureMap*255);

%% Find the largest blob, fill in any holes, extract edge from feature map
dim = size(img);
featureMap = ExtractNLargestBlobs(featureMap, 1);
featureMap = imfill(featureMap,'holes');
featureMap = imgaussfilt(double(featureMap),5);
bwFeatureMap = edge(featureMap,'canny');
% hold off
% figure;
% imshow(bwFeatureMap)

%% Find the lines of the outline of the frame using Hough Transform
[H,T,R] = hough(bwFeatureMap);
P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
lines = houghlines(bwFeatureMap,T,R,P,'FillGap',50,'MinLength',3);
gradient=0;
aveX=0;
aveY=0;

for k = 1:length(lines)
    point1=lines(k).point1;
    point2=lines(k).point2;
    aveX=aveX+point1(1)+point2(1);
    aveY=aveY+point1(2)+point2(2);
    xy = [lines(k).point1; lines(k).point2];
    lines(k).dist=pdist(xy,"euclidean");
    gradient=((point1(2)-point2(2))/(0.0000000001+point1(1)-point2(1)));
    lines(k).gradient=gradient;
end

aveX=aveX/(2*length(lines));
aveY=aveY/(2*length(lines));
% figure
% imshow(img)
% hold on
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    point1=lines(k).point1;
    point2=lines(k).point2;
    gradient=lines(k).gradient;
    if abs(gradient)>1 && point1(1)>aveX
        lines(k).color='green';
    elseif abs(gradient)>1 && point1(1)<aveX
        lines(k).color='cyan';
    elseif abs(gradient)<1 && point1(2)<aveY
        lines(k).color='magenta';
    elseif abs(gradient)<1 && point1(2)>aveY
        lines(k).color='yellow';
    else
        'Not found'
    end
%     %plot lines
%     plot(xy(:,1),xy(:,2),'LineWidth',2,'Color',lines(k).color);
%     % Plot beginnings and ends of lines
%     plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%     plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
%     hold on;
end

tab=struct2table(lines);
yArr=double(zeros(4,dim(2)));
sides=["green" "yellow" "cyan" "magenta"];
x=1:dim(2);
% hold on
for i=1:4
    color=sides(i);
    rows=ismember(tab.color,color);
    tabTemp=tab(rows,:);
    if numOrig>height(tabTemp)
        num=height(tabTemp);
    else num=numOrig;
    end

    tabTemp=sortrows(tabTemp,'dist','descend');
    tabTemp=tabTemp(1:num,:);
    gradient=0;
    sumWeight=0;
    pointX=0;
    pointY=0;
    for j=1:height(tabTemp)
        weight=tabTemp(j,:).dist/tabTemp(1,:).dist;
        sumWeight=sumWeight+weight;
        gradient=gradient+weight*tabTemp(j,:).gradient;
        pointX=pointX+weight*(tabTemp(j,:).point1(1)+tabTemp(j,:).point2(1));
        pointY=pointY+weight*(tabTemp(j,:).point1(2)+tabTemp(j,:).point2(2));
    end
    gradient=gradient/sumWeight;


    pointX=pointX/(2*sumWeight);
    pointY=pointY/(2*sumWeight);

    b=pointY-gradient*pointX;
    y=polyval([gradient b],x);
    yArr(i,:)=y;
%     plot(x,y,'r')
%     hold on
end
% hold on

%% Find the intersection of each line
curve=[x;yArr(1,:);x;yArr(2,:);x;yArr(3,:);x;yArr(4,:)];
vertices=double(zeros(4,2));
iteration=1;
for i=1:3
    for j=i:3

        P=InterX(curve(2*i-1:2*i,:),curve(1+2*j:2+2*j,:));
        if length(P)>0 && P(1)<dim(2) && P(2)<dim(1)
            vertices(iteration,:)=P;
            iteration=iteration+1;
        end
    end
end
% vertices=sortrows(vertices,[1 2])

% remove corners off the map
idx = find( (vertices(2,:)<0) | (vertices(1,:)<0) );
vertices(idx,:) = [];
idx  = find((vertices(:,1)>dim(2)) | (vertices(:,2)>dim(1)));
vertices(idx,:) = [];
end
