% Výpočet délky elementů a vytvoření transformační matice
%
% In: 
% elements.vertex =       směrový vektor jednotlivých elementů
% elements.XY =     vektor určující rovinu XY elementu
% elements.nelement =    počet elementů
%
% Out:
% transformationMatrix.lengths =       délka elementů
% transformationMatrix.matrices =transoformační matice pro jednotlivé elementy - cell       
%
% (c) S. Glanc, 2022

function [matrices,lengths]=transMatrixTrussFn(nelem,nodesHead,nodesEnd,nodes)
%--------------------------------------------------------------------
%    Příprava paměti
%--------------------------------------------------------------------
    vertex = zeros(nelem,3);
    lengths=[]; 
    matrices={};
%--------------------------------------------------------------------
%     Vertex
%--------------------------------------------------------------------
    
    for cp = 1:nelem
        vertex(cp,1) = nodes.x(nodesEnd(cp)) - nodes.x(nodesHead(cp));
        vertex(cp,2) = nodes.y(nodesEnd(cp)) - nodes.y(nodesHead(cp));
        vertex(cp,3) = nodes.z(nodesEnd(cp)) - nodes.z(nodesHead(cp));

%--------------------------------------------------------------------
%     XY vertex
%--------------------------------------------------------------------   
        if vertex(cp,1) == 0 && vertex(cp,3) == 0 
            XY(cp,:) = [1 0 0];
        else
            XY(cp,:) = [0 1 0];
        end
%--------------------------------------------------------------------
%     Cosinus X
%--------------------------------------------------------------------
        for q=1:3
            vektorX(q)=vertex(cp,q);
        end
        xL=(vektorX(1)^2+vektorX(2)^2+vektorX(3)^2)^0.5;
        lengths(cp)=xL;
    %   Normovani
        for q=1:3
            Cx(q)=(vektorX(q))/xL;
        end

%--------------------------------------------------------------------
    % Cosinus z
%--------------------------------------------------------------------        
        crossCz=cross(Cx,XY(cp,:));
        %Normovani
        zL=((crossCz(1))^2+(crossCz(2))^2+(crossCz(3))^2)^0.5;
        %   Normovani
        for i=1:3
            Cz(i)=crossCz(i)/zL;
        end

%--------------------------------------------------------------------
    % Cosinus y
%--------------------------------------------------------------------
        crossCy=cross(Cz,Cx);
        %Normovani
        yL=((crossCy(1))^2+(crossCy(2))^2+(crossCy(3))^2)^0.5;
        %   Normovani
        for i=1:3
            Cy(i)=crossCy(i)/yL;
        end

        t=zeros(3,3);

        t(1,:)=Cx;
        t(2,:)=Cy;
        t(3,:)=Cz;

        T=zeros(6,6);
        sv3=6/3;
        for c=1:sv3
            for j=1:3
                for i=1:3
                T(i+3*(c-1),j+3*(c-1))=t(i,j);
                end
            end
        end   
        matrices{cp}=T;
    end
end                   