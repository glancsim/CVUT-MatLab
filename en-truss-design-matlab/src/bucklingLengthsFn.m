function Lcr = bucklingLengthsFn(members, nodes, classification, params)
% bucklingLengthsFn  Compute buckling lengths for truss members.
%
% Rules for tubular (CHS) trusses per Tab. 1.29 (Jandera — OK 01):
%
%   Member type    | L_cr in-plane          | L_cr out-of-plane
%   ───────────────┼────────────────────────┼──────────────────────────
%   Top chord      | 0.9 × L_sys            | 0.9 × purlin_spacing
%   Bottom chord   | 0.9 × L_sys            | bracing_spacing
%   Diagonal       | 0.75 × L_sys           | 0.75 × L_sys
%   Vertical       | 0.75 × L_sys           | 0.75 × L_sys
%
% INPUTS:
%   members        - struct with .nodesHead, .nodesEnd (nmembers×1)
%   nodes          - struct with .x, .z (nnodes×1)
%   classification - output of memberClassificationFn
%   params         - struct with:
%     .purlin_spacing   [m]  distance between purlins / top chord nodes
%     .bracing_spacing  [m]  out-of-plane bracing distance for bottom chord
%                            (default = params.truss_spacing)
%     .truss_spacing    [m]  fallback if bracing_spacing not provided
%
% OUTPUTS:
%   Lcr - struct with fields (all nmembers×1 [m]):
%     .in_plane       buckling length in the truss plane
%     .out_of_plane   buckling length out of the truss plane
%     .governing      max(in_plane, out_of_plane) — for CHS (Iy = Iz)
%
% (c) S. Glanc, 2026

if ~isfield(params, 'bracing_spacing')
    params.bracing_spacing = params.truss_spacing;
end

dx   = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
dz   = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);
Lsys = sqrt(dx.^2 + dz.^2);

nmembers = numel(members.nodesHead);
Lcr_in  = zeros(nmembers, 1);
Lcr_out = zeros(nmembers, 1);

for p = 1:nmembers
    t = classification.type(p);
    L = Lsys(p);

    if t == "top_chord"
        Lcr_in(p)  = 0.9 * L;
        Lcr_out(p) = 0.9 * params.purlin_spacing;

    elseif t == "bottom_chord"
        Lcr_in(p)  = 0.9 * L;
        Lcr_out(p) = 1.0 * params.bracing_spacing;

    else   % diagonal or vertical
        Lcr_in(p)  = 0.75 * L;
        Lcr_out(p) = 0.75 * L;
    end
end

Lcr.in_plane     = Lcr_in;
Lcr.out_of_plane = Lcr_out;
Lcr.governing    = max(Lcr_in, Lcr_out);

end
