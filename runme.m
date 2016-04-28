% main functions to match clothes from pre-built database

clear all
close all
clc

addpath database
addpath womenstops
addpath womensshoes
addpath menspolo
addpath functions

run('./vlfeat-0.9.9/toolbox/vl_setup');

[filename, pathname] = uigetfile('*.*','Select Target Image','multiselect','off');


prompt = {'Polos,Shoes or Tops'};
dlg_title = 'Select Database';
num_lines = 1;
def = {'Polos'};

answer = inputdlg(prompt,dlg_title,num_lines,def);


directory = pwd;

switch answer{1}
    case 'Polos'
        load Polos
        
    case 'Shoes'
        load Shoes
        
    case 'Tops'
        load Tops
        
    otherwise
        error('the database selected is not supported!');
end

findtopMatches([pathname,filename],files);





