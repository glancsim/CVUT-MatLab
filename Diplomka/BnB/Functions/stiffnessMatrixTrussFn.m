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

function [stiffnesMatrix]=stiffnessMatrixTrussFn(inA,inE,inL,inCos,nelem,codeNumbs)
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
        cos=inCos(idElem,:);
        localK = localStiffMatFn(cos).*E*A/L;
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
    
    function A = localStiffMatFn(cos)
            D = [cos -cos;0 0 0 0 0 0];
            A = D' * D;
    end
end