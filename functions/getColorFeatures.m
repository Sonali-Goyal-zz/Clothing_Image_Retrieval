function imcolor = getColorFeatures(im_input, ROI_map)


%% initialization
dbg = false;

% get image size %
im_sz = size(im_input);
ROI_sz = size(ROI_map);

% calculate the distance between center and the corner
field_diag = (im_sz(1)^2 + im_sz(2)^2)^0.5/2;

% achieve coordinates of image center
im_ct = im_sz(1:2)./2;

% count the total number of valid pixels of ROI
no_valid_pixels = sum(ROI_map(:));

% check the ROI map size
if (im_sz(1) ~= ROI_sz(1))|(im_sz(2) ~= ROI_sz(2))
    error('The size of the ROI map image is not the same as input image!');
end


%% convert images to CIELAB space and calculate hue angle and chroma for each pixel
% convert the input images to Lab space %
d65_XYZ = [95.047,100,108.883]';
im_XYZ = sRGB2XYZ(reshape(im_input,[im_sz(1)*im_sz(2),3])');
im_Lab = XYZ2Lab(im_XYZ,d65_XYZ); % 3-by-n

% convert ROI_map to the similar data sequence as input image
ROI_map = reshape(ROI_map,[im_sz(1)*im_sz(2),1]);

% achieve hue angle and chroma information
im_Ch = [(im_Lab(2,:).^2 + im_Lab(3,:).^2).^0.5;atan2(im_Lab(3,:),im_Lab(2,:)).*180/pi];

% show histogram of chroma and hue
if dbg
    figure;hist(im_Ch(2,:),120);title('hue angle');
    figure;hist(im_Ch(1,:),10);title('chroma');
end


%% separate the pixels into different bins based on their coordinates in CIELab color space
% set 85 bins (each bin is 9 degree range x 2 lighting level + 5 neutral bins)
no_bin = 85;
hue_angle = [-180:9:180];

% set thresholds for lightness and chroma
lightness_thresh = 50;
chroma_thresh = 5; % below this threshold will be considered as neutral color


% set counter for pixels in each hue bins
im_hue_bin_ct = zeros(no_bin,1);
im_hue_map = zeros(size(ROI_map));
im_hue_map = reshape(im_hue_map,[im_sz(1)*im_sz(2),1]);

% separate each 3 degree of hue angle
for ii = 1:40
    im_hue_bin_ct(ii) = sum((im_Ch(2,:)>hue_angle(ii))&(im_Ch(2,:)<=hue_angle(ii+1))&(im_Ch(1,:) > chroma_thresh)&(im_Lab(1,:) >= lightness_thresh)&(ROI_map(:,1)'==1));
    im_hue_map((im_Ch(2,:)>hue_angle(ii))&(im_Ch(2,:)<=hue_angle(ii+1))&(im_Ch(1,:) > chroma_thresh)&(im_Lab(1,:) >= lightness_thresh)&(ROI_map(:,1)'==1)) = ii;
end

for ii = 41:80
    im_hue_bin_ct(ii) = sum((im_Ch(2,:)>hue_angle(ii-40))&(im_Ch(2,:)<=hue_angle(ii-39))&(im_Ch(1,:) > chroma_thresh)&(im_Lab(1,:) < lightness_thresh)&(ROI_map(:,1)'==1));
    im_hue_map((im_Ch(2,:)>hue_angle(ii-40))&(im_Ch(2,:)<=hue_angle(ii-39))&(im_Ch(1,:) > chroma_thresh)&(im_Lab(1,:) < lightness_thresh)&(ROI_map(:,1)'==1)) = ii;
end

% neutral color

for ii = 81:85
    im_hue_bin_ct(ii) = sum((im_Ch(1,:) <= chroma_thresh)&(im_Lab(1,:) < (ii-80)*20 - 1)&(im_Lab(1,:) >= (ii-81)*20)&(ROI_map(:,1)'==1));
    im_hue_map((im_Ch(1,:) <= chroma_thresh)&(im_Lab(1,:) < (ii-80)*20 - 1)&(im_Lab(1,:) >= (ii-81)*20)&(ROI_map(:,1)'==1)) = ii;
end

% reshape hue map to display it
im_hue_map_rs = reshape(im_hue_map',[im_sz(1),im_sz(2)]);

if dbg
    imtool(im_hue_map_rs./no_bin);
end

%% the 20 bins with most pixels are selected as candidates for further selection

% sort bins based on their pixel numbers
[hue_ct_rank, hue_ct_idx] = sort(im_hue_bin_ct,'descend');

% select first 20 bins
first20hueBins = hue_ct_idx(1:20,1);

% remove background by calculating the average distance to the center of
% the image
coordinates_pixels_bin = cell(20,1);
p10_field_bin = zeros(20,1);
bins_temp = [];
background_thresh = 0.6;

for ii = 1:20
    
    idx_temp = find(im_hue_map == first20hueBins(ii));
    
    if ~isempty(idx_temp)
        idx_x = ceil(idx_temp./im_sz(1));
        idx_y = mod(idx_temp,im_sz(1)) + (mod(idx_temp,im_sz(1))==0);
        p10_field(ii,1) = prctile(((idx_y - im_ct(1)).^2 + (idx_x - im_ct(2)).^2).^0.5./field_diag,10);
        if p10_field(ii,1) < background_thresh
            bins_temp = [bins_temp;first20hueBins(ii)];
        end
        
    end
end

first20hueBins = bins_temp;


% threshold of number of pixels that considered as color features
primary_hue_th = 0.45;
secondary_hue_th = 0.10;
decoration_hue_th = 0.02;

% output color features
primary_color_idx = first20hueBins(im_hue_bin_ct(first20hueBins)./no_valid_pixels > primary_hue_th);
secondary_color_idx = first20hueBins((im_hue_bin_ct(first20hueBins)./no_valid_pixels <= primary_hue_th)&(im_hue_bin_ct(first20hueBins)./no_valid_pixels > secondary_hue_th));
decoration_color_idx = first20hueBins((im_hue_bin_ct(first20hueBins)./no_valid_pixels <= secondary_hue_th)&(im_hue_bin_ct(first20hueBins)./no_valid_pixels > decoration_hue_th));


% preliminary numbers of each category
prePrimaryColorNo = length(primary_color_idx);
preSecondaryColorNo = length(secondary_color_idx);
preDecorationColorNo = length(decoration_color_idx);

% obtain the selected color CIELab values
primary_color_Lab = [];
secondary_color_Lab = [];
decoration_color_Lab = [];


% create palette images for selected colors for future check
color_palette = ones(300,600,3);
DEab_thresh = 10;
exist_color = [];

% select primary color, also avoid those colors too close to exist selected
% colors
PrimaryColorNo = 0;
if ~isempty(primary_color_idx)
    for ii = 1:prePrimaryColorNo
        
        temp_Lab = median(im_Lab(:,im_hue_map == primary_color_idx(ii)),2);
        
        % if the color is too close to exist color, remove it
        if isempty(exist_color)
            exist_color = temp_Lab;
            isvaliddata = 1;
        else
            
            isvaliddata = 1;
            
            for jj = 1:size(exist_color,2)
                [~,DEab] = deltaE00(exist_color(:,jj),temp_Lab);
                if DEab < DEab_thresh
                    isvaliddata = 0;
                end
                
            end
        end
        
        if isvaliddata
            exist_color = [exist_color,temp_Lab];
            PrimaryColorNo = PrimaryColorNo + 1;
            primary_color_Lab = [primary_color_Lab,temp_Lab];
            color_palette(1:100,100*(PrimaryColorNo -1)+1:100*PrimaryColorNo ,1) = temp_Lab(1);
            color_palette(1:100,100*(PrimaryColorNo -1)+1:100*PrimaryColorNo ,2) = temp_Lab(2);
            color_palette(1:100,100*(PrimaryColorNo -1)+1:100*PrimaryColorNo ,3) = temp_Lab(3);
        end
    end
end

clear temp_Lab;

SecondaryColorNo = 0;
if ~isempty(secondary_color_idx)
    for ii = 1:preSecondaryColorNo
        
        temp_Lab = median(im_Lab(:,im_hue_map == secondary_color_idx(ii)),2);
        
        % if the color is too close to exist color, remove it
        if isempty(exist_color)
            exist_color = temp_Lab;
            isvaliddata = 1;
        else
            
            isvaliddata = 1;
            
            for jj = 1:size(exist_color,2)
                [~,DEab] = deltaE00(exist_color(:,jj),temp_Lab);
                if DEab < DEab_thresh
                    isvaliddata = 0;
                end
                
            end
            
            
        end
        
        if isvaliddata
            exist_color = [exist_color,temp_Lab];
            SecondaryColorNo = SecondaryColorNo + 1;
            secondary_color_Lab = [secondary_color_Lab,temp_Lab];
            color_palette(101:200,100*(SecondaryColorNo -1)+1:100*SecondaryColorNo ,1) = temp_Lab(1);
            color_palette(101:200,100*(SecondaryColorNo -1)+1:100*SecondaryColorNo ,2) = temp_Lab(2);
            color_palette(101:200,100*(SecondaryColorNo -1)+1:100*SecondaryColorNo ,3) = temp_Lab(3);
        end
    end
end
clear temp_Lab;

DecorationColorNo = 0;
if ~isempty(decoration_color_idx)
    for ii = 1:preDecorationColorNo
        
        temp_Lab = median(im_Lab(:,im_hue_map == decoration_color_idx(ii)),2);
        
        % if the color is too close to exist color, remove it
        if isempty(exist_color)
            exist_color = temp_Lab;
            isvaliddata = 1;
        else
            
            isvaliddata = 1;
            
            for jj = 1:size(exist_color,2)
                [~,DEab] = deltaE00(exist_color(:,jj),temp_Lab);
                if DEab < DEab_thresh
                    isvaliddata = 0;
                end
                
            end
            
            
        end
        
        if isvaliddata
            exist_color = [exist_color,temp_Lab];
            DecorationColorNo = DecorationColorNo + 1;
            decoration_color_Lab = [decoration_color_Lab,temp_Lab];
            color_palette(201:300,100*(DecorationColorNo -1)+1:100*DecorationColorNo ,1) = temp_Lab(1);
            color_palette(201:300,100*(DecorationColorNo -1)+1:100*DecorationColorNo ,2) = temp_Lab(2);
            color_palette(201:300,100*(DecorationColorNo -1)+1:100*DecorationColorNo ,3) = temp_Lab(3);
        end
    end
end

if dbg
    imwrite(color_palette,'test_palette.tif','tif','ColorSpace','cielab');
end

% wrap the data and output
imcolor.PrimaryColorLab = primary_color_Lab;
imcolor.SecondaryColorLab = secondary_color_Lab;
imcolor.DecorationColorLab = decoration_color_Lab;
imcolor.PrimaryColorNo = PrimaryColorNo;
imcolor.SecondaryColorNo = SecondaryColorNo;
imcolor.DecorationColorNo = DecorationColorNo;
% imcolor.Palette = color_palette;







