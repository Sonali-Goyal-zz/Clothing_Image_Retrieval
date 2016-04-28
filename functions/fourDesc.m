function desc = fourDesc(mask)
I_d = bwperim(mask);                %get perimeter of mask
perim = find(I_d == 1);             %get most top left point in perimeter
[sx sy] = ind2sub(size(mask), perim(1));   %convert to index
trace = bwtraceboundary(I_d, [sx sy], 'E', 8, Inf, 'clockwise');    %trace boundary from there

samp = round((1:500)*length(trace)/500);   %sample to 500 points
y = trace(samp, 1);
x = trace(samp, 2);
y = y - mean(y);                    %normalize to center
x = x - mean(x);
desc = fft(x + i*y, 500);           %calculate fourier descriptors
desc = desc(2:400);                 %discard DC component and very high freqs
desc = abs(desc)/abs(desc(1));      %normalize magnitudes

