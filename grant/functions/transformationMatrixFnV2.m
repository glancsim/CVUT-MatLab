% Výpočet délky elementů a vytvoření transformační matice
%
% In: 
%   elements            .vertex         - směrový vektor jednotlivých elementů
%                       .XY             - vektor určující rovinu XY elementu
%                       .nelement       - počet elementů
%
% Out:
% transformationMatrix  .lengths        - délka elementů
%                       .matrices       - transoformační matice pro jednotlivé elementy - cell       
%
% (c) S. Glanc, 2023

function [transformationMatrix]=transformationMatrixFnV2(elements)
lengths=zeros(elements.nelement,1); 
matrices={};
for cp=1:elements.nelement % cislo elementu
    Cx=zeros(3,1);Cy=zeros(3,1);Cz=zeros(3,1);vektorX=zeros(3,1);
    %--------------------------------------------------------------------
    %Cosinus X
    for q=1:3
        vektorX(q)=elements.vertex(cp,q);
    end
    xL=(vektorX(1)^2+vektorX(2)^2+vektorX(3)^2)^0.5;
    lengths(cp)=xL;
%   Normovani
    for q=1:3
        Cx(q)=(vektorX(q))/xL;
    end
   
    
    %--------------------------------------------------------------------
    % Cosinus y
    crossCy=cross(elements.localZ(cp,:)',Cx);
    %Normovani
    yL=((crossCy(1))^2+(crossCy(2))^2+(crossCy(3))^2)^0.5;
    %   Normovani
    for i=1:3
        Cy(i)=crossCy(i)/yL;
    end
    
    %--------------------------------------------------------------------
    % Cosinus z
    crossCz=cross(Cx,Cy);
    %Normovani
    zL=((crossCz(1))^2+(crossCz(2))^2+(crossCz(3))^2)^0.5;
    %   Normovani
    for i=1:3
        Cz(i)=crossCz(i)/zL;
    end
    
    t=zeros(3,3);

    t(1,:)=Cx;
    t(2,:)=Cy;
    t(3,:)=Cz;

    T=zeros(12,12);
    sv3=12/3;
    for c=1:sv3
        for j=1:3
            for i=1:3
            T(i+3*(c-1),j+3*(c-1))=t(i,j);
            end
        end
    end   
    matrices{cp}=T;
end
transformationMatrix.lengths = lengths;
transformationMatrix.matrices = matrices;
end                   