% test_input.m - Test 7: Prostý nosník
%
% Popis: Nosník podepřený na obou koncích, zatížený uprostřed

%% PRŮŘEZY
sections.id = [20;20;20;20];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0; 2.5; 5; 7.5; 10];      % x coordinates of nodes
nodes.y = [0; 0; 0; 0; 0];           % y coordinates of nodes  
nodes.z = [0; 1; 2; 1;0];           % z coordinates of nodes

%% DISKRETIZACE
ndisc = 5;  % discretization of beams

%% PODPORY - Kloubové podpory na koncích
kinematic.x.nodes = [1; 5];              % node indices with restricted x-direction displacements
kinematic.y.nodes = [1; 5];          % node indices with restricted y-direction displacements
kinematic.z.nodes = [1; 5];          % node indices with restricted z-direction displacements
kinematic.rx.nodes = [1 ; 5];             % node indices with restricted x-direction rotations
kinematic.ry.nodes = [1 ; 5];             % node indices with restricted y-direction rotations
kinematic.rz.nodes = [1 ; 5];         % node indices with restricted z-direction rotations

%% PRVKY
beams.nodesHead = [1; 2; 3; 4];      % elements starting nodes
beams.nodesEnd = [2; 3; 4; 5];       % elements ending nodes
beams.sections = [1; 1; 1; 1];       % section to beams
beams.angles = [0; 0; 0; 0];         % angle of section

%% ZATÍŽENÍ - Zatížení uprostřed
loads.x.nodes = [3];                  % node indices with x-direction forces
loads.x.value = [0];                  % magnitude of the x-direction forces

loads.y.nodes = [3];                 % node indices with y-direction forces
loads.y.value = [-1];               % magnitude of the y-direction forces

loads.z.nodes = [3];                  % node indices with z-direction forces
loads.z.value = [-1];                  % magnitude of the z-direction forces

loads.rx.nodes = [3];                 % node indices with x-direction moments
loads.rx.value = [0];                 % magnitude of the x-direction moments

loads.ry.nodes = [3];                 % node indices with y-direction moments
loads.ry.value = [0];                 % magnitude of the y-direction moments

loads.rz.nodes = [3];                 % node indices with z-direction moments
loads.rz.value = [0];                 % magnitude of the z-direction moments