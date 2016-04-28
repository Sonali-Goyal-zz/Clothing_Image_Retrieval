function featureScore=getFeatureScore(img1, img2)

gray_img = rgb2gray(img1);
thresh = graythresh(gray_img);
mask = im2bw(gray_img, thresh);
gray_img(mask==1) = 255;

gray_img2 = rgb2gray(img2);
thresh = graythresh(gray_img2);
mask = im2bw(gray_img2, thresh);
gray_img2(mask==1) = 255;

[f,d] = vl_sift(single(gray_img));
[f2,d2] = vl_sift(single(gray_img2));
% disk center: f(1:2)
% scale: f(3)
% orientation: f(4)

[matches, scores] = vl_ubcmatch(d,d2,2.5);

image(img1);
%ind = 1:length(scores);
%sel = matches(ind*2-1);
h1 = vl_plotframe(f);
set(h1,'color','b','linewidth',3);

%image(img2);
%sel2 = matches(ind*2);
%h2 = vl_plotframe(f2(:,sel2));
%set(h2,'color','b','linewidth',3);

[inliers flag bestmodel] = AffinePairwiseRansac(f, f2, matches, true, false);
if (flag ~= -1)
   featureScore = length(inliers)/2;
   return;
end

featureScore = length(scores);

if (featureScore > 0)
temp = sum(scores)/length(scores);
tempScore = 0;
while (tempScore > 1)
    tempScore = tempScore + 1;
    temp = temp/10;
end
featureScore = featureScore + tempScore/100;
end