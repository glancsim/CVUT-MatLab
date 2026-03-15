function [sorted_values,sorted_vectors] = sortValuesVectorFn(values,vectors)
%sortVectorAbs
%sort vector by absolute values
% INPUTs
% values = eigen values
% vectors = eigen vectors
% OUTPUTs
% sorted_values = sorted eigen values
% sorted_vectors = sorted eigen vectors
    [~, index] = sort(abs(values));
    sorted_values = values(index);
    sorted_vectors = vectors(:, index);
end

