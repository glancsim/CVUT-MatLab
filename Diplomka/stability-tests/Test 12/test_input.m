% test_input.m - Test 12: Prostorový L-rám
%
% Popis: Dva pruty v prostoru tvořící tvar L.
%        Prut 1 leží podél osy X (uzel 1 → uzel 2).
%        Prut 2 leží podél osy Z (uzel 2 → uzel 3).
%        Uzly 1 a 3 jsou plně vetknuty. Uzel 2 je volný.
%        Různé průřezy pro každý prut.
%        Svislá tlaková síla + vodorovná + příčná (prostorová odezva).

%% PRŮŘEZY
sections.id = [20; 15];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0.0; 4.0; 4.0];  % x coordinates of nodes
nodes.y = [0.0; 0.0; 0.0];  % y coordinates of nodes
nodes.z = [0.0; 0.0; 5.0];  % z coordinates of nodes

%% DISKRETIZACE
ndisc = 10;  % discretization of beams

%% PODPORY
% Uzly 1 a 3 – plné vetknutí; uzel 2 – volný
kinematic.x.nodes  = [1; 3];  % restricted x-displacement
kinematic.y.nodes  = [1; 3];  % restricted y-displacement
kinematic.z.nodes  = [1; 3];  % restricted z-displacement
kinematic.rx.nodes = [1; 3];  % restricted rx-rotation
kinematic.ry.nodes = [1; 3];  % restricted ry-rotation
kinematic.rz.nodes = [1; 3];  % restricted rz-rotation

%% PRVKY
% Beam 1: vodorovný prut  1 → 2  (podél X, délka 4 m)
% Beam 2: svislý prut     2 → 3  (podél Z, délka 5 m)
beams.nodesHead = [1; 2];    % elements starting nodes
beams.nodesEnd  = [2; 3];    % elements ending nodes
beams.sections  = [1; 2];    % section to beams (různé průřezy)
beams.angles    = [0; 0];    % angle of section

%% ZATÍŽENÍ
% Zatížení v uzlu 2 – kombinace osového tlaku + příčných sil (prostorová odezva)
loads.x.nodes = [2];         % node indices with x-direction forces
loads.x.value = [0.5000];    % vodorovná síla podél X (ohýbá svislý prut)

loads.y.nodes = [2];         % node indices with y-direction forces
loads.y.value = [-0.2000];   % příčná síla podél Y (prostorové zatížení)

loads.z.nodes = [2];         % node indices with z-direction forces
loads.z.value = [-1.0000];   % svislá tlaková síla Fz (axialní v prutu 2)

loads.rx.nodes = [];         % node indices with rx-direction moments
loads.rx.value = [];

loads.ry.nodes = [];         % node indices with ry-direction moments
loads.ry.value = [];

loads.rz.nodes = [];         % node indices with rz-direction moments
loads.rz.value = [];
