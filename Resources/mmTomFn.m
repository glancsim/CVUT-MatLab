% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   mm - milimeters
%   e - exponent of value
%
% Out:
%   m - meters
%
% (c) S. Glanc, 2022


function [m]=mmTomFn(mm,e)
    m = mm * 10^(-3 * e);
end