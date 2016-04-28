function ret = sRGB2XYZ(sRGB);

if (size(sRGB,1)~=3) & (size(sRGB,2)==3)
   sRGB = sRGB';
   disp('The input XYZ values were transposed to 3-by-n');
end

% normalize

if length(find(sRGB>2))~=0
   sRGB = sRGB./255;
end
n = size(sRGB,2);

RGB = zeros(3,n);

RGB = ((sRGB <= 0.04045).*(sRGB ./ 12.92) + (sRGB > 0.04045).*(((sRGB + 0.055)./1.055).^2.4));

% RGB2XYZ
matrix = [0.4124,0.3576,0.1805;0.2126,0.7152,0.0722;0.0193,0.1192,0.9505];

ret = matrix * RGB.*100;
