clear;clc;addpath('../Resources/Truss');addpath('../Resources');startup
%------------------------------------------------------------------------
%   INPUTS
%------------------------------------------------------------------------
% Sections
% r = sdpvar(1,2)
% r = [ 10 - rSDP(1) , 10 - rSDP(2) ];
% [~,sizeR] = size(r);
sections.A  = sdpvar(2,1);
sections.E  = [1;1];

%Nodes
nodes.x         = [0;3;0];
nodes.y         = [0;0;0];
nodes.z         = [0;0;3];
nnodes          =  numel(nodes.x)
nodes.dofs      = [ 0 0 0;1 0 1;0 0 0];                  
nodes.dofsNumb  = nodesDofsNumbFn(nodes) ;
nodes.ndofs = sum(sum(nodes.dofs));
nodes.nnodes    = numel(nodes.x);                

%Beams
beams.nodesHead = [1,3];
beams.nodesEnd  = [2,2];
beams.disc      = [1,1];
beams.sections.id  = [1,2];
beams.nbeams  = numel(beams.nodesHead);
beams.ndofs  = nodes.ndofs;
beams.nelement  = beams.nbeams;
beams.vertex = beamVertexFn(beams,nodes);
beams.codeNumbers = codeNumbersFn(beams,nodes);
beams.XY = XYtoBeamsFn(beams);
beams.sections = sectionToBeamFn(sections,beams);

%Load
loads.nodes.id  = [2];
loads.nodes.dir = [3];
loads.value  = [-1];
loads = loadInputFn(loads,nodes);

%------------------------------------------------------------------------
%   SOLVE
%------------------------------------------------------------------------









