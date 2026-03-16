function forces = parseOofemInternalForcesFn(filename, nelement)
% parseOofemInternalForcesFn - Parse OOFEM output file for element internal forces
%
% Reads the "local end forces" lines from the beam element output section of
% OOFEM's test.out file.
%
% Inputs:
%   filename - Path to OOFEM output file (e.g., 'test.out')
%   nelement - Number of discretized elements to extract
%
% Output:
%   forces - (12 x nelement) matrix of local end forces per element
%            forces(:,i) = [N1 Vy1 Vz1 T1 My1 Mz1  N2 Vy2 Vz2 T2 My2 Mz2]
%            Ordering matches MATLAB localEndForces from EndForcesFn:
%              DOFs 1-6:  end 1 [Fx, Fy, Fz, Mx, My, Mz]
%              DOFs 7-12: end 2 [Fx, Fy, Fz, Mx, My, Mz]

forces = zeros(12, nelement);

fid = fopen(filename, 'r');
if fid == -1
    error('parseOofemInternalForcesFn: Cannot open file: %s', filename);
end

currentElement = 0;
expectForces   = false;

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line), break; end

    % Detect "beam element N (" line
    tok = regexp(line, 'beam element\s+(\d+)\s*\(', 'tokens');
    if ~isempty(tok)
        currentElement = str2double(tok{1}{1});
        if currentElement > nelement
            break;
        end
        expectForces = true;
        continue;
    end

    % Read "  local end forces  ..." line
    if expectForces && contains(line, 'local end forces')
        vals = sscanf(line(strfind(line, 'local end forces') + length('local end forces') : end), '%f');
        if numel(vals) >= 12
            forces(:, currentElement) = vals(1:12);
        end
        expectForces = false;
    end
end

fclose(fid);
end
