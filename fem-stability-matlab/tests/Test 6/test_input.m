% test_input.m - Test 6: Vetknutá konzola
%
% Popis: Konzola vetknutá na jednom konci, zatížená na volném konci

%% PRŮŘEZY
sections.id = [15;15;15;15];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0; 0; 0; 0; 0];           % x coordinates of nodes
nodes.y = [0; 2; 4; 6; 8];           % y coordinates of nodes  
nodes.z = [0; 0; 0; 0; 0];           % z coordinates of nodes

%% DISKRETIZACE
ndisc = 10;  % discretization of beams

%% PODPORY - Vetknutí v bodě 1
kinematic.x.nodes = [1];             % node indices with restricted x-direction displacements
kinematic.y.nodes = [1];             % node indices with restricted y-direction displacements
kinematic.z.nodes = [1];             % node indices with restricted z-direction displacements
kinematic.rx.nodes = [1];            % node indices with restricted x-direction rotations
kinematic.ry.nodes = [1];            % node indices with restricted y-direction rotations
kinematic.rz.nodes = [1];            % node indices with restricted z-direction rotations

%% PRVKY
beams.nodesHead = [1; 2; 3; 4];      % elements starting nodes
beams.nodesEnd = [2; 3; 4; 5];       % elements ending nodes
beams.sections = [1; 1; 1; 1];       % section to beams
beams.angles = [0; 0; 0; 0];         % angle of section

%% ZATÍŽENÍ - Síla na volném konci
loads.y.nodes = [5];             % node indices with x-direction forces
loads.y.value = [-1];             % magnitude of the x-direction forces
loads.x.nodes = [5];             % node indices with y-direction forces
loads.x.value = [-10];             % magnitude of the y-direction forces 
loads.z.nodes = [5];             % node indices with y-direction forces
loads.z.value = [-1];             % magnitude of the y-direction forces 

loads.rx.nodes = [5];          % node indices with x-direction forces
loads.rx.value = [0];          % magnitude of the x-direction forces
loads.ry.nodes = [5];          % node indices with y-direction forces
loads.ry.value = [0];          % magnitude of the y-direction forces 
loads.rz.nodes = [5];          % node indices with z-direction forces
loads.rz.value = [0]; 
