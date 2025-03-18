% Prevod stop na metry
%
% In: 
%   expo - exponent pro m^2 = 2
%   feet - prevadene cislo
%
% Out:
%   meter - prevedene cislo
%
% (c) S. Glanc, 2022


function [meter]=feetToMeter(feet,expo)
meter=feet*0.3048^expo;
end