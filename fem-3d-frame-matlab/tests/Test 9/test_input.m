% test_input.m - Test 9: Prostorová pyramida
%
% Popis: Pyramida s čtvercovou základnou a vrcholem nahoře

%% PRŮŘEZY
sections.id = [15; 25; 10; 12];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0; 4; 4; 0; 2];           % x coordinates of nodes
nodes.y = [0; 0; 4; 4; 2];           % y coordinates of nodes  
nodes.z = [0; 0; 0; 0; 5];           % z coordinates of nodes (vrchol ve výšce 5)

%% DISKRETIZACE
ndisc = 10;  % discretization of beams

%% PODPORY - Vetknutí v rozích základny
kinematic.x.nodes = [1; 2; 3; 4];    % node indices with restricted x-direction displacements
kinematic.y.nodes = [1; 2; 3; 4];    % node indices with restricted y-direction displacements
kinematic.z.nodes = [1; 2; 3; 4];    % node indices with restricted z-direction displacements
kinematic.rx.nodes = [1; 2; 3; 4];   % node indices with restricted x-direction rotations
kinematic.ry.nodes = [1; 2; 3; 4];   % node indices with restricted y-direction rotations
kinematic.rz.nodes = [1; 2; 3; 4];   % node indices with restricted z-direction rotations

%% PRVKY - 4 diagonální prvky od rohů k vrcholu
beams.nodesHead = [1; 2; 3; 4];      % elements starting nodes
beams.nodesEnd = [5; 5; 5; 5];       % elements ending nodes (všechny ke vrcholu)
beams.sections = [1; 1; 2; 2];       % section to beams
beams.angles = [45; 45; 45; 45];     % angle of section

%% ZATÍŽENÍ - Zatížení na vrcholu
loads.x.nodes = [5];                  % node indices with x-direction forces
loads.x.value = [0];                  % magnitude of the x-direction forces

loads.y.nodes = [5];                  % node indices with y-direction forces
loads.y.value = [0];                  % magnitude of the y-direction forces

loads.z.nodes = [5];                 % node indices with z-direction forces
loads.z.value = [-25];               % magnitude of the z-direction forces

loads.rx.nodes = [5];                 % node indices with x-direction moments
loads.rx.value = [0];                 % magnitude of the x-direction moments

loads.ry.nodes = [5];                 % node indices with y-direction moments
loads.ry.value = [0];                 % magnitude of the y-direction moments

loads.rz.nodes = [5];                 % node indices with z-direction moments
loads.rz.value = [0];                 % magnitude of the z-direction moments
