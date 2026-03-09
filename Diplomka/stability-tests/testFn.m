function [errors, h, sortedValues] = testFn(sections, nodes, ndisc, kinematic, beams, loads)
% testFn - Univerzální funkce pro spuštění stability testu
%
% Vstupy:
%   sections   - Struktura: sections.id
%   nodes      - Struktura: nodes.x, nodes.y, nodes.z
%   ndisc      - Diskretizace prvků
%   kinematic  - Struktura: kinematic.x/y/z/rx/ry/rz.nodes
%   beams      - Struktura: beams.nodesHead, nodesEnd, sections, angles
%   loads      - Struktura: loads.x/y/z/rx/ry/rz.nodes/value
%
% Výstupy:
%   errors        - Vektor procentuálních chyb oproti OOFEM [%]
%   h             - Handle grafu
%   sortedValues  - Vlastní čísla z MATLAB výpočtu
%
% Použití:
%   test_input;  % Načte proměnné
%   [errors, h, sortedValues] = testFn(sections, nodes, ndisc, kinematic, beams, loads);

%% NASTAVENÍ PRŮŘEZŮ
% --------------------------------------------------------------------------

crossSectionsSet.import = importdata("../sectionsSet.mat");
crossSectionsSet.A = table2array(crossSectionsSet.import.L(:,"A"));
crossSectionsSet.Iz = table2array(crossSectionsSet.import.L(:,"I_y"));
crossSectionsSet.Iy = table2array(crossSectionsSet.import.L(:,"I_z"));
crossSectionsSet.Ip = table2array(crossSectionsSet.import.L(:,"I_t"));

sections_out.id = sections.id;

for i = 1:size(sections_out.id, 1)
    sections_out.A(i, 1)  = crossSectionsSet.A(sections_out.id(i));
    sections_out.Iy(i, 1) = crossSectionsSet.Iy(sections_out.id(i));
    sections_out.Iz(i, 1) = crossSectionsSet.Iz(sections_out.id(i));
    sections_out.Ix(i, 1) = crossSectionsSet.Ip(sections_out.id(i));
    sections_out.E(i, 1)  = 210*10^9;
    sections_out.v(i, 1)  = 0.3;
end

nangles = 90;  % Předpokládaná hodnota (není v inputu)

%% UZLY
% --------------------------------------------------------------------------

nnodes = numel(nodes.x);

%% PODPORY
% --------------------------------------------------------------------------

nodes.dofs = true(nnodes, 6);
nodes.dofs(kinematic.x.nodes, 1) = false;
nodes.dofs(kinematic.y.nodes, 2) = false;
nodes.dofs(kinematic.z.nodes, 3) = false;
nodes.dofs(kinematic.rx.nodes, 4) = false;
nodes.dofs(kinematic.ry.nodes, 5) = false;
nodes.dofs(kinematic.rz.nodes, 6) = false;

%% PRVKY
% --------------------------------------------------------------------------

nr = numel(beams.nodesHead);

beams.disc = ones(nr, 1) * ndisc;

ng = max(max(beams.sections));

%% ZATÍŽENÍ
% --------------------------------------------------------------------------

forceVector = sparse([loads.x.nodes*6-5; loads.y.nodes*6-4; loads.z.nodes*6-3; ...
                      loads.rx.nodes*6-2; loads.ry.nodes*6-1; loads.rz.nodes*6], ...
                     1, ...
                     [loads.x.value; loads.y.value; loads.z.value; ...
                      loads.rx.value; loads.ry.value; loads.rz.value], ...
                     nnodes*6, 1);
                 
f = forceVector(reshape(reshape(nodes.dofs.', [], 1).', 1, [])');

%% PŘÍPRAVA FEM
% --------------------------------------------------------------------------

nodes.ndofs = sum(sum(nodes.dofs));
nodes.nnodes = nnodes;

beams.nbeams = nr;
beams.vertex = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY = XYtoRotBeamsFn(beams, beams.angles);

elements = discretizationBeamsFn(beams, nodes);
elements.XY = XYtoElementFn(beams);
elements.sections = sectionToElementFn(sections_out, beams);
elements.ndofs = max(max(elements.codeNumbers));

%% LINEÁRNÍ ANALÝZA
% --------------------------------------------------------------------------

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix = stiffnessMatrixFn(elements, transformationMatrix);

for i = 1:nr
    lcsModels(i, :) = lcsModelFn([nodes.x(beams.nodesHead(i)) ...
                                   nodes.y(beams.nodesHead(i)) ...
                                   nodes.z(beams.nodesHead(i))], ...
                                  transformationMatrix.matrices{(i-1)*ndisc+1});
end

[endForces.local, displ] = EndForcesFn(stiffnesMatrix, endForces, transformationMatrix, elements);

%% NELINEÁRNÍ ANALÝZA
% --------------------------------------------------------------------------

[geometricMatrix.local, geometricMatrix.global] = geometricMoofemFn(...
    elements.sections.A, ...
    elements.sections.Ix, ...
    transformationMatrix.matrices, ...
    transformationMatrix.lengths, ...
    endForces.local, ...
    elements.ndofs, ...
    elements.nelement, ...
    elements.codeNumbers, ...
    12);

volume = sum(elements.sections.A .* transformationMatrix.lengths);

Results = criticalLoadFn(stiffnesMatrix, geometricMatrix);
[sortedValues, sortedVectors] = sortValuesVectorFn(Results.values, Results.vectors);

%% POROVNÁNÍ S OOFEM
% --------------------------------------------------------------------------

[h, errors] = oofemTestFn(nodes, beams, loads, kinematic, sections_out, sortedValues);

end
