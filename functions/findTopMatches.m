function scores = findTopMatches(filename, files)

% display('Collecting data from database...');
% batchprocess(directory);

I = imread(filename);
I_b = binarize(I);

load('gaborfilters.mat');
g = gaborcoefficients(I, gaborfilters);

I_d = im2double(I);
c = getColorFeatures(I_d,I_b);

f = fourDesc(I_b);

wg = 1; 
wc = 1.7; 
wf = 1; 
wfeat = 1; 

% load('imageprops.mat');
scores = [];
for i = 1:length(files);
    if (strcmp(files(i).name, '.') || strcmp(files(i).name, '..'))
        continue;
    end
    % gabor score
    gc = files(i).gabor;
    scores(i, 1) = norm(g-gc);
    
    % color score
    cc = files(i).color;
    scores(i, 2) = compareColorFeatures(c, cc);
    
    % fourier
    fc = files(i).fourier;
    scores(i, 3) = norm(f -fc);
    
    % feature score
    scores(i, 4) = getFeatureScore(I, files(i).image);
end

scores(:, 1) = -scores(:, 1) + max(scores(:, 1));
scores(:, 3) = -scores(:, 3) + max(scores(:, 3));

scores(:, 1) = wg*scores(:, 1)/max(scores(:, 1));
scores(:, 2) = wc*scores(:, 2)/max(scores(:, 2));
scores(:, 3) = wf*scores(:, 3)/max(scores(:, 3));
scores(:, 4) = wfeat*scores(:, 4)/max(scores(:, 4));

sumscores = sum(scores, 2);

[~, ind] = sort(sumscores, 'descend');
figure(1);
imshow(filename);
for i = 1:4
    figure(i+ 1);
    imshow(files(ind(i)).name);
end