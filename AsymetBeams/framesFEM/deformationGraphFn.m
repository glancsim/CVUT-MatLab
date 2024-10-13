% Diskretizace prutů - vytvoreni vektorů jednotlivých prutu a vytvoreni   
%   neznamych na mezilehlých elemntech
%
% In: 
%   beams       .nbeams         - počet prutů
%               .nodesHead      - počáteční uzel(id)
%               .disc           - počet prvků na prutu   
%   nodes       .dofs           - neznámé přemístění
%               .x              - souřadnice X
%               .y              - souřadnice Y
%               .z              - souřadnice Z
%               .nnodes         - počet uzlů
%   eigenVector                 - vlastní tvar
%   scale                       - měřítko deformace
%
% Out:
%     graph                     - vykreslená deformace                   
%
% (c) S. Glanc, 2022
function graph = deformationGraphFn(nodes,beams,eigenVector,scale)
id = 1;
nodes.disc.x = nodes.x;
nodes.disc.y = nodes.y;
nodes.disc.z = nodes.z;
for i = 1:beams.nbeams 
    for d = 1:(beams.disc(i)-1)
        nodes.disc.x(nodes.nnodes + id)=nodes.x(beams.nodesHead(i)) + beams.vertex(i,1)/beams.disc(i)*(d);
        nodes.disc.y(nodes.nnodes + id)=nodes.y(beams.nodesHead(i)) + beams.vertex(i,2)/beams.disc(i)*(d);
        nodes.disc.z(nodes.nnodes + id)=nodes.z(beams.nodesHead(i)) + beams.vertex(i,3)/beams.disc(i)*(d);
        id = id+1;
    end
end
nodes.disc.nnodes = numel(nodes.disc.x); 
nodes.disc.dofs = true(nodes.disc.nnodes,6);                % no kinematic boundary conditions
nodes.disc.dofs(1:nodes.nnodes,:) = nodes.dofs;
nodes.disc.codeNumbers = zeros(size(nodes.disc.dofs)) ;
index = 1;
for i = 1:size(nodes.disc.dofs, 1)
    for j = 1:size(nodes.disc.dofs, 2)
        if nodes.disc.dofs(i, j)
            nodes.disc.codeNumbers(i, j) = index;
            index = index+1;
        end
    end
end

for k = 1:nodes.disc.nnodes
        if nodes.disc.codeNumbers(k,1) ~= 0
            nodes.disc.displacements.x(k,1)  = nodes.disc.x(k) + eigenVector(nodes.disc.codeNumbers(k,1))*scale;
        else
            nodes.disc.displacements.y(k,1)  = nodes.disc.y(k);
        end
        if nodes.disc.codeNumbers(k,2) ~= 0
            nodes.disc.displacements.y(k,1)  = nodes.disc.y(k) + eigenVector(nodes.disc.codeNumbers(k,2))*scale;
        else
            nodes.disc.displacements.y(k,1)  = nodes.disc.y(k);
        end
        if nodes.disc.codeNumbers(k,3) ~= 0
            nodes.disc.displacements.z(k,1)  = nodes.disc.z(k) + eigenVector(nodes.disc.codeNumbers(k,3))*scale;
        else
            nodes.disc.displacements.z(k,1)  = nodes.disc.z(k);
        end
end

id = nodes.nnodes+1;

for n = 1:beams.nbeams
    heads(1,n) = beams.nodesHead(n);    
    for d = 1:beams.disc(n)-1     
        heads(d+1,n) = id;
        ends(d,n) = id;
        id = id+1;
    end
    ends(beams.disc(n),n) = beams.nodesEnd(n);
end

heads = heads(:);
ends = ends(:);


% graph = scatter3(nodes.disc.displacements.x, nodes.disc.displacements.y, nodes.disc.displacements.z, 'blue', 'filled', 'o');
xlim([min(nodes.disc.displacements.x)-0.5,max(nodes.disc.displacements.x)+0.5]);  % to avoid tight limits
ylim([min(nodes.disc.displacements.y)-0.5,max(nodes.disc.displacements.y)+0.5]);  % to avoid tight limits
zlim([min(nodes.disc.displacements.z)-0.5,max(nodes.disc.displacements.z)+0.5]);  % to avoid tight limits
graph = plot3([nodes.disc.displacements.x(heads) nodes.disc.displacements.x(ends)]', ...
     [nodes.disc.displacements.y(heads) nodes.disc.displacements.y(ends)]', ...
     [nodes.disc.displacements.z(heads) nodes.disc.displacements.z(ends)]', ...
     'k','LineWidth',3, 'Color', 'red');
end