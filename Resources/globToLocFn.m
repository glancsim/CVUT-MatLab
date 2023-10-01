% Lokalizace
% In: 
% ID        =	kódová čísla lok. matice
% rG        =   globální vektor posunutí 
% Out:
% rL        =	lokální vektor posunutí
% (c) S. Glanc, 2022
function [rL]=globToLocFn(ID,rG)
    n=size(ID,1);
    rL=zeros(12,n);
    for j=1:n
            for i=1:12
                if ID(i)==0
                rL(i,j)=0;
                else
                rL(i,j)=rG(ID(i));   
                end
            end
    end
end



