function [Diff] = matrixComparisonFn(K_BP,K_OOFEM,n)
% INPUT
% K_BP = prvni matice k porovnani
% K_OOFEM = druha matice k porovnani
% n = pocet neznamych
% OUTPUT
% Diff = matice s nepresnostmi
for i=1:n
    for j=1:n
        BP = K_BP(i,j);
        OOFEM = K_OOFEM(i,j);
        id = abs(BP - OOFEM);
        acc = abs(BP)/100;
        if id < acc
        Diff(i,j) = 0;
        else
        Diff(i,j) = id;    
        end
    end
end
end

