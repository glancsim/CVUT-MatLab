%   Seřazení vlastních čísel a tvarů dle absolutní hodnoty
% 
% In:
%   values = eigen values
%   vectors = eigen vectors
% Out:
%   sorted_values = sorted eigen values
%   sorted_vectors = sorted eigen vectors
%
% (c) S. Glanc, 2024
function [sorted_values,sorted_vectors] = sortValuesVectorFn(values,vectors)
    [~, index] = sort(abs(values));
    sorted_values = values(index);
    [sizeValues,~] = size(values);
    for i = 1:sizeValues
        sorted_vectors (:,index(i)) = vectors(:,i);
    end
end

