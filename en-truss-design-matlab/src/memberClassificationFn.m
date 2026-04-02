function classification = memberClassificationFn(members, nodes)
% memberClassificationFn  Classify truss members by structural role.
%
% Classification is based on member angle and z-position:
%   angle < 15 deg AND mean z < half max z  → bottom chord
%   angle < 15 deg AND mean z >= half max z → top chord
%   angle > 75 deg                           → vertical
%   otherwise                                → diagonal
%
% INPUTS:
%   members  - struct with .nodesHead, .nodesEnd (nmembers×1)
%   nodes    - struct with .x, .z (nnodes×1)
%
% OUTPUTS:
%   classification - struct with fields:
%     .type        - (nmembers×1) string array: 'top_chord', 'bottom_chord',
%                                 'vertical', 'diagonal'
%     .is_top      - logical (nmembers×1)
%     .is_bottom   - logical (nmembers×1)
%     .is_vertical - logical (nmembers×1)
%     .is_diagonal - logical (nmembers×1)
%
% (c) S. Glanc, 2026

nmembers = numel(members.nodesHead);

dx = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
dz = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);

% Angle from horizontal (0=horizontal, 90=vertical).
% min(a, 180-a) makes it direction-independent: members defined right-to-left
% are treated the same as left-to-right.
angle_deg = abs(atan2d(dz, dx));
angle_deg = min(angle_deg, 180 - angle_deg);

mean_z = (nodes.z(members.nodesHead) + nodes.z(members.nodesEnd)) / 2;
z_threshold = max(nodes.z) / 2;

% If members.sections is provided, use section index to identify chords:
%   section 1 → top chord
%   section 2 → bottom chord
%   section 3 → web (diagonal or vertical distinguished by angle)
% This makes classification robust for irregular trusses where z_threshold
% may not cleanly separate the two chords.
use_sections = isfield(members, 'sections') && ~isempty(members.sections);

type = strings(nmembers, 1);

for p = 1:nmembers
    if use_sections
        s = members.sections(p);
        if s == 1
            type(p) = "top_chord";
        elseif s == 2
            type(p) = "bottom_chord";
        elseif angle_deg(p) > 75
            type(p) = "vertical";
        else
            type(p) = "diagonal";
        end
    else
        if angle_deg(p) > 75
            type(p) = "vertical";
        elseif angle_deg(p) < 15
            if mean_z(p) < z_threshold
                type(p) = "bottom_chord";
            else
                type(p) = "top_chord";
            end
        else
            type(p) = "diagonal";
        end
    end
end

classification.type        = type;
classification.is_top      = type == "top_chord";
classification.is_bottom   = type == "bottom_chord";
classification.is_vertical = type == "vertical";
classification.is_diagonal = type == "diagonal";

end
