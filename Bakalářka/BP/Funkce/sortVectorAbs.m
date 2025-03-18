function [sorted_vect] = sortVectorAbs(vect)
%sortVectorAbs
%sort vector by absolute values
[~, index] = sort(abs(vect));
sorted_vect = vect(index);
end

