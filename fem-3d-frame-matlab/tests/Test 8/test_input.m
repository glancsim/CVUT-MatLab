% test_input.m - Test 8: Portálový rám
%
% Popis: Rám ve tvaru portálu s vodorovným zatížením (vítr)

%% PRŮŘEZY
sections.id = [10; 20; 10];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0; 0; 9; 9];              % x coordinates of nodes
nodes.z = [0; 9; 9; 0];              % y coordinates of nodes  
nodes.y = [0; 0; 0; 0];              % z coordinates of nodes

%% DISKRETIZACE
ndisc = 3;  % discretization of beams

%% PODPORY - Vetknutí v základech
kinematic.x.nodes = [1; 4];          % node indices with restricted x-direction displacements
kinematic.y.nodes = [1; 4];          % node indices with restricted y-direction displacements
kinematic.z.nodes = [1; 4];          % node indices with restricted z-direction displacements
kinematic.rx.nodes = [1; 4];         % node indices with restricted x-direction rotations
kinematic.ry.nodes = [1; 4];         % node indices with restricted y-direction rotations
kinematic.rz.nodes = [1; 4];         % node indices with restricted z-direction rotations

%% PRVKY
beams.nodesHead = [1; 2; 3];         % elements starting nodes
beams.nodesEnd = [2; 3; 4];          % elements ending nodes
beams.sections = [1; 2; 1];          % section to beams (1=sloupy, 2=příčel)
beams.angles = [0; 90; 0];           % angle of section

%% ZATÍŽENÍ - Horizontální zatížení (vítr)
loads.x.nodes = [2; 3];              % node indices with x-direction forces
loads.x.value = [0; 0];              % magnitude of the x-direction forces

loads.y.nodes = [2; 3];                  % node indices with y-direction forces
loads.y.value = [1; 1];                  % magnitude of the y-direction forces

loads.z.nodes = [2; 3];                  % node indices with z-direction forces
loads.z.value = [-1; -1];                  % magnitude of the z-direction forces

loads.rx.nodes = [2; 3];                 % node indices with x-direction moments
loads.rx.value = [0; 0];                 % magnitude of the x-direction moments

loads.ry.nodes = [2; 3];                 % node indices with y-direction moments
loads.ry.value = [0; 0];                 % magnitude of the y-direction moments

loads.rz.nodes = [2; 3];                 % node indices with z-direction moments
loads.rz.value = [0; 0];                 % magnitude of the z-direction moments