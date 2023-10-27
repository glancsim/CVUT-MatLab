% Vytvoření lokálních a globálních matic tuhosti
%
% In: 
% elements.sections.A =             plocha průřezu
% transformationMatrix.matrices =    transoformační matice pro jednotlivé elementy 
% transformationMatrix.lengths =           délka elementů
% elements.sections.E =           Youngův modul pružnosti
% elements.nelement =        počet elementů
% elements.ndofs =   počet neznámých vnitřních sil/posunů
% elements.codeNumbers =     kódová čísla elementů
% 
% 
% Out:
% stiffnesMatrix.local =    lokální matice tuhosti - cell
% stiffnesMatrix.global =   globální matice tuhosti       
%
% (c) S. Glanc, 2023

function [stiffnesMatrix]=stiffnessMatrixTrussFn(inA,inE,inL,inT,nelem,codeNumbs)
    %========================================================================
    %Příprava paměti počítače
    %========================================================================
    ndofs = max(max(codeNumbs));
    globalStiffnessMatrix=double2sdpvar(zeros(ndofs ,ndofs));
%     globalStiffnessMatrix=(zeros(ndofs ,ndofs));
    localStiffnessMatrix{nelem}=[];
    psv = 3;
    psv2 = psv *2;
    %========================================================================
    %Výpočet
    %========================================================================
    for idElem=1:nelem % cislo elementu
        A=inA(idElem);
        E=inE(idElem);
        L=inL(idElem);
        T=inT{idElem};
        T_t=T';
        %=========================================================================
        %Matice tuhosti
        %=========================================================================
        localK  = localStiffMatFn(E/L)*A;
        localStiffnessMatrix{idElem}=localK;
        localK=T_t*localK*T;
        %========================================================================
        %Assembly
        %========================================================================
        codes=codeNumbs(idElem,:);
        for i=1:psv2
            if codes(i)>0
                for j=1:psv2
                    if codes(j)>0
                    globalStiffnessMatrix(codes(i),codes(j))=globalStiffnessMatrix(codes(i),codes(j))+localK(i,j);
                    end
                end
            end
        end
    end
    
    stiffnesMatrix = globalStiffnessMatrix;
%     stiffnesMatrix.local = localStiffnessMatrix;
    
    function A = localStiffMatFn(k)
        % Definujte rozměry matice a hodnotu k
        n = 6;  % Počet řádků a sloupců matice

        % Vytvoření řídké matice s hodnotami na specifických pozicích
        row_indices = [1, 1, 4, 4];
        col_indices = [1, 4, 1, 4];
        values = [k, -k, k, -k];

        A = sparse(row_indices, col_indices, values, n, n);

        % Vytvořená matice A bude mít rozměr 6x6 a vypadat následovně:
        %   k   0   0   0   0   -k
        %   0   0   0   0   0    0
        %   0   0   0   0   0    0
        %   0   0   0   k   0    0
        %   0   0   0   0   0    0
        %  -k   0   0   0   0    0
    end
end