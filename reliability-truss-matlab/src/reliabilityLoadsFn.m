function loads = reliabilityLoadsFn(loadParams, G_s, G_P, s_roof)
% reliabilityLoadsFn  Assemble nodal forces from random variable realizations.
%
% Replaces loadCombinationsFn for reliability analysis — no partial safety
% factors (γ), only random variable realizations.
%
% INPUTS:
%   loadParams - struct from trussHallInputFn with fields:
%     .top_nodes      (nb×1) node indices for top chord
%     .trib           (nb×1) tributary lengths [m]
%     .truss_spacing  [m]
%     .g_roof         [kN/m²] roof + purlins (without self-weight)
%     .selfWeight     struct .nodes, .values [N] (nominal self-weight forces)
%   G_s    - self-weight RV realization (Normal, mean=1)
%   G_P    - permanent load RV realization (Normal, mean=1)
%   s_roof - snow load on roof [kN/m²] = theta_Q2 * mu1 * C_t * s_g
%
% OUTPUTS:
%   loads - struct compatible with linearSolverFn:
%     .x.nodes, .x.value   (empty — no horizontal loads)
%     .z.nodes, .z.value   [N] vertical nodal forces
%
% (c) S. Glanc, 2026

b    = loadParams.truss_spacing;   % [m]
trib = loadParams.trib;            % [m]
top  = loadParams.top_nodes;

% Permanent load on top chord (roof + purlins, scaled by G_P)
q_perm = G_P * loadParams.g_roof;            % [kN/m²]

% Total downward load on top chord nodes
q_net  = q_perm + s_roof;                    % [kN/m²]
Fz_top = -q_net * b .* trib * 1e3;          % [N], negative = downward

% Self-weight nodal forces (scaled by G_s)
sw = loadParams.selfWeight;
if ~isempty(sw.nodes)
    Fz_sw      = G_s * sw.values;            % [N], already negative
    all_nodes  = [top;    sw.nodes];
    all_values = [Fz_top; Fz_sw];
else
    all_nodes  = top;
    all_values = Fz_top;
end

loads.x.nodes = [];
loads.x.value = [];
loads.z.nodes = all_nodes;
loads.z.value = all_values;

end
