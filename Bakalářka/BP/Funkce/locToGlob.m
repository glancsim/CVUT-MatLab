% Lokalizace z lokálních na globální
% In: 
% ID        =	kódová čísla lok. matice
% KL        =   lokální matice tuhosti
% Out:
% KG        =	globální matice tuhosti
% (c) S. Glanc, 2022
function [KG]=locToGlob(ID,KL)
    n=size(ID,1);
    KG=zeros(n,n);  
    for i=1:12
        if ID(i)>0
            for j=1:12
                if ID(j)>0
                KG(ID(i),ID(j))=KG(ID(i),ID(j))+KL(i,j);
                end
            end
        end
    end
end




