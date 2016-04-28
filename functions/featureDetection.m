%run('../vlfeat-0.9.9/toolbox/vl_setup');

img = imread('./WomenShoes/CoachKeeleySneaker.tif');
img2 = imread('./WomenShoes/CoachKeeleySneaker2.tif');
img3 = imread('./WomenShoes/SteveMaddenShoes_RazzzleSandals.tif');
img2 = imread('./WomenShoes/CalvinKleinShoes_JackySandals.tif');
gray_img = rgb2gray(img);
gray_img2 = rgb2gray(img2);
gray_img3 = rgb2gray(img3);
%image(img);

thresh = graythresh(gray_img);
mask = im2bw(gray_img, thresh);
gray_img(mask==1) = 255;

thresh = graythresh(gray_img2);
mask = im2bw(gray_img2, thresh);
gray_img2(mask==1) = 255;

thresh = graythresh(gray_img3);
mask = im2bw(gray_img3, thresh);
gray_img3(mask==1) = 255;

score = getFeatureScore(gray_img, gray_img2);
score2 = getFeatureScore(gray_img, gray_img3);
fprintf('score = %i\n', score);
fprintf('score2 = %i\n', score2);