function elements = discretizationBeamsFn(beams, nodes)
% discretizationBeamsFn  Discretize beams into finite elements.
%
% Each beam is split into beams.disc(p) elements of equal length.
% Interior nodes receive new (sequential) DOF numbers.
%
% INPUTS:
%   beams  - struct with fields: nodesHead, nodesEnd, nbeams, disc,
%            vertex, codeNumbers
%   nodes  - struct with field: dofs
%
% OUTPUTS:
%   elements.codeNumbers - (nelement x 6) global DOF numbers
%   elements.vertex      - (nelement x 2) [Δx, Δz] per element
%   elements.nelement    - total number of elements
%
% (c) S. Glanc, 2026

[~, k] = size(nodes.dofs);   % k = 3  (ux, uz, ry)
k1 = k;
k2 = k + 1;
k3 = 2 * k;

nextDof = max(max(beams.codeNumbers)) + 1;

nelement = sum(beams.disc);
elemVec  = zeros(nelement, 2);
elemCode = zeros(nelement, k3);

eIdx = 0;
for p = 1:beams.nbeams
    c = beams.disc(p);

    % Direction vector per sub-element
    for s = 1:c
        eIdx = eIdx + 1;
        elemVec(eIdx, :) = beams.vertex(p, :) / c;
    end

    % Code numbers for first element of beam p
    base = 1 + sum(beams.disc(1:p-1));
    elemCode(base, 1:k1) = beams.codeNumbers(p, 1:k1);   % head of beam

    if c == 1
        % Single element: end = beam end
        elemCode(base, k2:k3) = beams.codeNumbers(p, k2:k3);
    else
        % Interior node DOFs for end of first element
        for f = k2:k3
            elemCode(base, f) = nextDof;
            nextDof = nextDof + 1;
        end

        % Interior elements
        for h = 2:c-1
            elemCode(base+h-1, 1:k1) = elemCode(base+h-2, k2:k3);
            for f = k2:k3
                elemCode(base+h-1, f) = nextDof;
                nextDof = nextDof + 1;
            end
        end

        % Last element
        elemCode(base+c-1, 1:k1) = elemCode(base+c-2, k2:k3);
        elemCode(base+c-1, k2:k3) = beams.codeNumbers(p, k2:k3);
    end
end

elements.codeNumbers = elemCode;
elements.vertex      = elemVec;
elements.nelement    = nelement;
end
