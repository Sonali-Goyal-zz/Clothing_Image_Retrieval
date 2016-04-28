% Adapted from the following:

%%%%%%%VERSION 2
%%ANOTHER DESCRIPTION OF GABOR FILTER

%The Gabor filter is basically a Gaussian (with variances sx and sy along x and y-axes respectively)
%modulated by a complex sinusoid (with centre frequencies U and V along x and y-axes respectively) 
%described by the following equation
%%
%                            -1     x' ^     y'  ^             
%%% G(x,y,theta,f) =  exp ([----{(----) 2+(----) 2}])*cos(2*pi*f*x');
%                             2    sx'       sy'
%%% x' = x*cos(theta)+y*sin(theta);
%%% y' = y*cos(theta)-x*sin(theta);

%% Description :

%% I : Input image
%% Sx & Sy : Variances along x and y-axes respectively
%% f : The frequency of the sinusoidal function
%% theta : The orientation of Gabor filter

%% G : The output filter as described above
%% gabout : The output filtered image


Sx = 25;                                        %size of filter
Sy = 25;

gaborfilters = struct([]);

frequencies = linspace(.03, .2, 5);              % frequencies and angles
thetas = 0:pi/4:3*pi/4;
index = 0;
Gs = [];
for i = 1:length(frequencies);
    for j = 1:length(thetas);
        f = frequencies(i);
        theta = thetas(j);
        index = index + 1;
        for x = -fix(Sx):fix(Sx)                 %calculate each pixel of filter
            for y = -fix(Sy):fix(Sy)
                xPrime = x * cos(theta) + y * sin(theta);
                yPrime = y * cos(theta) - x * sin(theta);
                G(fix(Sx)+x+1,fix(Sy)+y+1) = exp(-.5*((xPrime/Sx)^2+(yPrime/Sy)^2))*cos(2*pi*f*xPrime);
            end
        end
        gaborfilters(index).gabor = conj(G);    %save each filter
        Gs = cat(4, Gs, G);
    end
end

save('gaborfilters.mat', 'gaborfilters');
