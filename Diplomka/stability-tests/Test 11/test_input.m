% test_input.m - Test 11: Konzola podél osy Y s pootočeným průřezem
%
% Popis: Jeden prut vetknutý v uzlu 1, volný konec v uzlu 2.
%        Prut leží podél osy Y (x=0, z=0, y měnící se 0→8).
%        Průřez je pootočen o 30° kolem osy prutu.
%        Axiální tlaková síla Fy pro stabilitu + příčná zatížení Fz, Fx.

%% PRŮŘEZY
sections.id = [15];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0.0; 0.0];  % x coordinates of nodes
nodes.y = [0.0; 8.0];  % y coordinates of nodes  (prut podél Y)
nodes.z = [0.0; 0.0];  % z coordinates of nodes

%% DISKRETIZACE
ndisc = 10;  % discretization of beams

%% PODPORY
% Uzel 1 – plné vetknutí, uzel 2 – volný
kinematic.x.nodes  = [1];  % restricted x-displacement
kinematic.y.nodes  = [1];  % restricted y-displacement  (axiální)
kinematic.z.nodes  = [1];  % restricted z-displacement
kinematic.rx.nodes = [1];  % restricted rx-rotation
kinematic.ry.nodes = [1];  % restricted ry-rotation
kinematic.rz.nodes = [1];  % restricted rz-rotation

%% PRVKY
beams.nodesHead = [1];      % elements starting nodes
beams.nodesEnd  = [2];      % elements ending nodes
beams.sections  = [1];      % section to beams
beams.angles    = [30];     % pootočení průřezu o 30° kolem osy Y

%% ZATÍŽENÍ
% Axiální tlaková síla pro stabilitu + příčná zatížení pro lineární deformaci
loads.x.nodes = [2];         % node indices with x-direction forces
loads.x.value = [-0.3000];   % příčná síla Fx (bimomenty / prostorové ohýbání)

loads.y.nodes = [2];         % node indices with y-direction forces
loads.y.value = [-1.0000];   % axiální tlaková síla Fy (pro analýzu stability)

loads.z.nodes = [2];         % node indices with z-direction forces
loads.z.value = [-0.5000];   % příčná síla Fz

loads.rx.nodes = [];         % node indices with rx-direction moments
loads.rx.value = [];

loads.ry.nodes = [];         % node indices with ry-direction moments
loads.ry.value = [];

loads.rz.nodes = [];         % node indices with rz-direction moments
loads.rz.value = [];
