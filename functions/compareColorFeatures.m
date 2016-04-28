%compare color information between two color feature structure
%   color_score = compareColorFeatures(color1,color2) returns the results
%   as a score range from 0 ~ 100, the score is determined by color
%   difference in CIEDE2000
%   color1 and color2 are the output of 'getColorFeatures.m'
%   color1 is the color palette of the cloth need to be matched. color2 is
%   the color palette from database

function color_score = compareColorFeatures(color1,color2)

% set DE00 limit
deltaC_limit = 50;


if color1.PrimaryColorNo ~= 0 % if there is primary color in color1
    if color2.PrimaryColorNo ~=0 % if there is primary colro in color 2
        DE00_p = deltaC00(color1.PrimaryColorLab(:,1),color2.PrimaryColorLab(:,1));
        color_score = (deltaC_limit - DE00_p)./deltaC_limit;
    elseif color2.SecondaryColorNo ~= 0 % if there is no primary color, but secondary color in color 2
        DE00_p = zeros(color2.SecondaryColorNo,1);
        
        for ii = 1:color2.SecondaryColorNo
            % calculate the color difference between primary color of color
            % 1 and each of secondary color of color 2
            DE00_p(ii) = deltaC00(color1.PrimaryColorLab(:,1),color2.SecondaryColorLab(:,ii));
        end
        
        color_score = 0.5*(deltaC_limit - min(DE00_p))./deltaC_limit;
        
    elseif color2.DecorationColorNo ~= 0 % if no primary and secondary color in color 2, but decoration color
                DE00_p = zeros(color2.DeorationColorNo,1);
        
        for ii = 1:color2.DecortionColorNo
            DE00_p(ii) = deltaC00(color1.PrimaryColorLab(:,1),color2.DecorationColorLab(:,ii));
        end
        
        color_score = 0.1*(deltaC_limit - min(DE00_p))./deltaC_limit;
    else
        color_score = 0;
    end
    
elseif color1.SecondaryColorNo ~= 0 % if there is no primary color in color 1, but secondary color
    color2.TotalColorLab = [color2.PrimaryColorLab,color2.SecondaryColorLab];
    color2.TotalColorNo = size(color2.TotalColorLab,2);
    
    DE00_s = zeros(color1.SecondaryColorNo,1);
    
    for ii = 1:color1.SecondaryColorNo
        DE00_temp = zeros(color2.TotalColorNo,1);
        for jj = 1:color2.TotalColorNo
            
           % calculate the best match of each secondary color in color1 
           DE00_temp(jj) = deltaC00(color1.SecondaryColorLab(:,ii),color2.TotalColorLab(:,jj));  
            
        end
        
        DE00_s(ii) = min(DE00_temp);
        
    end
    
    
    color_score = sum((deltaC_limit - DE00_s)./deltaC_limit)./color1.SecondaryColorNo;
    
    if color2.PrimaryColorNo ~= 0
       color_score = 0.8*color_score; 
    end
    
else
   color_score = 0; 
end


function ret = deltaC00(Lab1,Lab2)

[~,ret] = deltaE00(Lab1,Lab2);


