function ret = XYZ2Lab(XYZ,XYZn)

%Get the number of samples
n = size(XYZ,2);

%Calculate the ratio of XYZ and XYZn
ratio = diag(1./XYZn)*XYZ;

%Allocate the space of Lab
ret = zeros(3,n);
ff = zeros(3,n);

%Calculate f(x)
ff = ((ratio>0.008856).*(ratio.^(1/3)) + (ratio<=0.008856).*(ratio*7.787 + 16/116));

%Put the data into the return variable
ret(1,:) = 116*ff(2,:) - 16;
ret(2,:) = 500*(ff(1,:) - ff(2,:));
ret(3,:) = 200*(ff(2,:) - ff(3,:));
