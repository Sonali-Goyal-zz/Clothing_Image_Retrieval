function batchprocess(directory)

tic;
files = dir([directory '*.tif']);
n = length(files);

run createGaborFilters;
load('gaborfilters.mat');

for i = 1:n;
    if (strcmp(files(i).name, '.') || strcmp(files(i).name,'..'))
        continue;
    end
    I = imread([directory files(i).name]);
    I_b = binarize(I);
    
    g = gaborcoefficients(I, gaborfilters);
    files(i).gabor = g;
    
    I_d = im2double(I);
    c = getColorFeatures(I_d,I_b);
    files(i).color = c;
    
    
    f = fourDesc(I_b);
    files(i).fourier = f;
    
    files(i).image = I;
end

save('imageprops.mat', 'files');
toc;
