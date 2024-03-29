function [final_inliers flag bestmodel] = AffinePairwiseRansac(frames_a1, frames_a2, all_matches, allowCloseCluster, suppress_output)

% Wikipedia
% iterations = 0
% bestfit = nil
% besterr = something really large
% while iterations < k {
%     maybeinliers = n randomly selected values from data
%     maybemodel = model parameters fitted to maybeinliers
%     alsoinliers = empty set
%     for every point in data not in maybeinliers {
%         if point fits maybemodel with an error smaller than t
%              add point to alsoinliers
%     }
%     if the number of elements in alsoinliers is > d {
%         this implies that we may have found a good model
%         now test how good it is
%         bettermodel = model parameters fitted to all points in maybeinliers and alsoinliers
%         thiserr = a measure of how well model fits these points
%         if thiserr < besterr {
%             bestfit = bettermodel
%             besterr = thiserr
%         }
%     }
%     increment iterations
% }
% return bestfit
%

if ~exist('suppress_output', 'var')
    suppress_output = 0;
end

%first decide how many matches we have

MIN_START_VALUES = 4;
num_matches = size(all_matches,2);
if (num_matches < MIN_START_VALUES)
    final_inliers = [];
    bestmodel = [];
    flag = -1;
    return
end    

% Todo? These might have to be changed if the values are different.
Z_OFFSET = 640;
COND_THRESH = 45;

% RANSAC parameters
NUM_START_VALUES = 3;  % only 3 correspondences needed for determining affine model
K = 500;
ERROR_THRESHOLD = 10; % fairly high threshold - this is in number of pixels
D = 1; % additional points must fit any given affine model
N = NUM_START_VALUES;
RADIUS = 30; 
MIN_NUM_OUTSIDE_RADIUS = 1;


%best error, best fit
iteration = 0;
besterror = inf;
bestmodel = [];	
final_inliers = [];
max_inliers = 0;
    
while (iteration < K)


	%start with NUM_START_VALUES unique values 
	uniqueValues = [];
	max_index = size(all_matches, 2);
	while (length(uniqueValues) < NUM_START_VALUES)
		value = ceil(max_index*rand(1,1));  
		if (length(find(value == uniqueValues)) == 0)
			%unique non-zero value		
			uniqueValues = [uniqueValues value];
		end
	end
	

	%uniqueValues are the indices in all_matches	
	maybeinliers = all_matches(:, uniqueValues);  %start with NUM_START_VALUES unique random values

    % make sure points are well distributed
    point_matrix = [frames_a1(:, maybeinliers(1, :)); Z_OFFSET*ones(1, NUM_START_VALUES)];
    if ~exist('allowCloseCluster', 'var')
        allowCloseCluster = 0;
    end
    if ( ~allowCloseCluster && (cond(point_matrix) > COND_THRESH) )            
        iteration = iteration + 1;
        continue;
    end
    
    M_maybemodel = getModel(maybeinliers, frames_a1, frames_a2);  
    
    if (prod(size(M_maybemodel)) == 0)
        iteration = iteration + 1;
        continue;
    end
    
    
    alsoinliers = [];

	%figure out other inliers
	for i = 1:size(all_matches, 2)
		
		temp = find(all_matches(1,i) == maybeinliers(1,:));
		if (length(temp) == 0)
			%this means, point not in maybeinlier
			a1 = frames_a1(1:2, all_matches(1,i));
			a2 = frames_a2(1:2, all_matches(2,i));
			if (getError(M_maybemodel, a1, a2) < ERROR_THRESHOLD )
				alsoinliers = [alsoinliers all_matches(:,i)];
			end		
		end		

    end

    if (size(alsoinliers,2) > 0)
        num = 0;
        dist = [];
        for i = 1:NUM_START_VALUES
            diff =     frames_a1(1:2,  alsoinliers(1, :)) - ...
                repmat(frames_a1(1:2, maybeinliers(1, i)), [1, size(alsoinliers, 2)]);

            dist = [dist; sqrt(sum(diff.^2))];
        end
        num = sum(sum(dist > RADIUS) == NUM_START_VALUES);        

        if (num < MIN_NUM_OUTSIDE_RADIUS)        
            iteration = iteration+1;
            continue;
        end
    end
    
    
	%see how good the model is
    %fprintf('Number of elements in also inliers %d\n', size(alsoinliers,2));

    if (size(alsoinliers,2) > D)

		%this implies that we have found a good model
		%now let's see how good it is
		
		%find new model
		all_inliers = [maybeinliers alsoinliers];
        M_bettermodel = getModel(all_inliers, frames_a1, frames_a2);  

        %the new model could be bad
        if (prod(size(M_bettermodel)) == 0)
            iteration = iteration+1;
            continue;
        end
            
        %find error for the model
		thiserror = getModelError(M_bettermodel,all_inliers, frames_a1, frames_a2);

        if max_inliers < size(all_inliers, 2) | (thiserror < besterror & max_inliers == size(all_inliers, 2))
            bestmodel = M_bettermodel;
            besterror = thiserror;
            final_inliers = all_inliers; 
            max_inliers = size(final_inliers, 2);
        end	
        
	end

	%do it K times
	iteration = iteration + 1;


end

%bestmodel has the best Model
if (prod(size(bestmodel)) ~= 0)
    % a model was found
    if ~suppress_output
%         fprintf('Error of best_model ~%f pixels\n', besterror);
    end
    flag = 1;

else
    flag = -1;
    final_inliers = [];
    bestmodel = [];
    if ~suppress_output
%         fprintf('No good model found !\n'); 
    end
end



end
function error = getModelError(M ,matches, frames_a1, frames_a2)


        nummatches = size(matches,2);
        error = 0;

        for i = 1:nummatches             
                a1 = frames_a1(1:2, matches(1,i));
                a2 = frames_a2(1:2, matches(2,i));  
                error = error + getError(M, a1, a2);
        end

        error = error/nummatches;



end

function M = getModel(matches, frames_a1, frames_a2)

        %let's go from 1 to 2 -- changed on Apr 28 to be consistent
        %with epipolar and perspective models
       

        singular_thresh = 1e-6;
        scaling_ratio_thresh = 5;
        scale_thresh = 0.005;
        
        % approximate M
        M = zeros(3,3);

        Y = []; X = [];
        
        for i = 1:size(matches,2)
            
            a1 = frames_a1(1:2, matches(1,i));
            a2 = frames_a2(1:2, matches(2,i));
            Y = [Y; a2]; 
            X = [X; a1(1) a1(2) 1 0 0 0; 0 0 0 a1(1) a1(2) 1];
            
        end

        %to check if matrix is singular
        if (1/cond(X) < singular_thresh) 
            M = [];
            return
        end

        M = X\Y;
        %we need to return M - a 3X3 matrix, where the last row is (0 0 1)
        M = [reshape(M, 3,2)'; 0 0 1];
        
        
        %let's add some rules to remove any crazy map

        
        %we definitely cannot have reflection
        [u, s, v] = svd(M(1:2,1:2));
        if (det(u*v') < 0)
            %==> there is a reflection
            M=[];
%            fprintf('Special case to avoid reflection\n');
            return
        end

        %we cannot have crazy ratios of scaling in the two dimensions.
        if (cond(M(1:2,1:2)) > scaling_ratio_thresh)
            %==> the matches are bad
            M=[];
%            fprintf('Special case to avoid crazy scaling ratio\n');
            return
        end
        
        
        %check for crazy zoom
        if (s(1,1) < scale_thresh | s(2,2) < scale_thresh)
           M = []; 
        end
        
        
end


function error = getError(M, a1, a2)

        %a2_model is the value of a2 that comes from the model
        %calculate mapping error
        a2_model  = M*([a1;1]);  %3x1 vector, only the first two values matter
        error = dist(a2, a2_model(1:2));


end

function d =  dist(one, two)
	d = sqrt(sum((one-two).^2));
end

