% Prevod palcu na metry
%
% In: 
%   expo - exponent pro m^2 = 2
%   inch - prevadene cislo
%
% Out:
%   meter - prevedene cislo
%
% (c) S. Glanc, 2022


function [meter]=inchToMeter(inch,expo)
meter=inch*0.0254^expo;
end