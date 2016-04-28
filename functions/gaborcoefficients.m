function features = gaborcoefficients(I, gaborfilters)  %takes RGB image and structure of gabor filters

I_g = double(rgb2gray(I))/255;      %convert image to gray
I_g = double(im2bw(I_g));           %convert image to BW
[h w] = size(I_g);
I_g = I_g(round(h/2 - 30):round(h/2 + 30), round(w/2 - 30):round(w/2 +30));     %take center of image
features = [];

for i = 1:length(gaborfilters);     %for each filter
    G = gaborfilters(i).gabor;      
    
    I_g = conv2(I_g, G, 'same');    %convolve with image
    mew = mean(abs(I_g(:)));        %calculate mean and standard deviation
    sig = std(abs(I_g(:)));
    features = [features mew sig];  %add to features
end