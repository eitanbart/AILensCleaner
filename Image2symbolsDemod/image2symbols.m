function symbols = image2symbols(I, net, numSymbols)

%% segment frame from the image
C = semanticseg(I, net);
featureMap = (C== 'Frame'); % Create a logical matrix of the feature map
numberToExtract = 1;
featureMap = ExtractNLargestBlobs(featureMap, numberToExtract);


%% extract corners 
K = (1/25)*ones(5); % smooth factor
featureMap = conv2(featureMap,K,'same');


[featureMap,J]=find(featureMap>max(featureMap(:))/2);
IJ=[featureMap,J];  
[~,idx]=min(IJ*[1 1; -1 -1; 1 -1; -1 1].');
corners=IJ(idx,:);

%% Apply Perspective Warping followed by cropping of the frame 
movingPoints = [corners(1,2) corners(1,1); corners(3,2),corners(3,1); corners(2,2),corners(2,1); corners(4,2),corners(4,1)];%coordinate of distorted corners 
fixedPoints=[0 0;size(I,1) 0;size(I,1) size(I,2);0 size(I,2)]; %coordinate of image's corners

tform = fitgeotrans(movingPoints,fixedPoints,'projective');
R=imref2d(size(I),[1 size(I,1)],[1 size(I,2)]);
frame=imwarp(I,tform,'OutputView',R);


%% Divide Frames into symbols
[rows columns numberOfColorBands] = size(frame);
blockSizeR = rows/numSymbols; 
blockSizeC = columns/numSymbols; 

wholeBlockRows = floor(rows / blockSizeR);
blockVectorR = [blockSizeR * ones(1, wholeBlockRows), rem(rows, blockSizeR)] ;
blockVectorR = blockVectorR(1:numSymbols);

wholeBlockCols = floor(columns / blockSizeC);
blockVectorC = [blockSizeC * ones(1, wholeBlockCols), rem(columns, blockSizeC)];
blockVectorC = blockVectorC(1:numSymbols);
symbols = mat2cell(frame, blockVectorR, blockVectorC, numberOfColorBands);

