% test_input.m - Vstupní data pro stability test
%
% Automaticky vygenerováno pomocí extract_input_from_test.m
% Datum: 13-Jan-2026 22:35:03

%% PRŮŘEZY
sections.id = [40; 40; 40; 40];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0.0000; 0.0000; 0.0000; 10.0000; 10.0000];  % x coordinates of nodes
nodes.y = [0.0000; 0.0000; 10.0000; 10.0000; 10.0000];  % y coordinates of nodes
nodes.z = [0.0000; 10.0000; 10.0000; 10.0000; 0.0000];  % z coordinates of nodes

%% DISKRETIZACE
ndisc = 10;  % discretization of beams

%% PODPORY
kinematic.x.nodes = [1; 5];  % node indices with restricted x-direction displacements
kinematic.y.nodes = [1; 5];  % node indices with restricted y-direction displacements
kinematic.z.nodes = [1; 5];  % node indices with restricted z-direction displacements
kinematic.rx.nodes = [1; 5];  % node indices with restricted x-direction rotations
kinematic.ry.nodes = [1; 5];  % node indices with restricted y-direction rotations
kinematic.rz.nodes = [1; 5];  % node indices with restricted z-direction rotations

%% PRVKY
beams.nodesHead.nodes = [1; 2; 3; 4];  % elements starting nodes
beams.nodesEnd.nodes = [2; 3; 4; 5];  % elements ending nodes
beams.sections.nodes = [1; 2; 3; 4];  % section to beams
beams.angles.nodes = [90; 90; 90; 90];  % angle of section

%% ZATÍŽENÍ
loads.x.nodes = [4];  % node indices with x-direction forces
loads.x.value = [-1.0000];  % magnitude of the x-direction forces

loads.y.nodes = [2];  % node indices with y-direction forces
loads.y.value = [1.0000];  % magnitude of the y-direction forces

loads.z.nodes = [3];  % node indices with z-direction forces
loads.z.value = [-1.0000];  % magnitude of the z-direction forces

loads.rx.nodes = [];;  % node indices with rx-direction forces
loads.rx.value = [];;  % magnitude of the rx-direction forces

loads.ry.nodes = [];;  % node indices with ry-direction forces
loads.ry.value = [];;  % magnitude of the ry-direction forces

loads.rz.nodes = [];;  % node indices with rz-direction forces
loads.rz.value = [];;  % magnitude of the rz-direction forces
