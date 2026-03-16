function oofem = oofemInputFn(nodes, beams, loads, kinematic, sections, filename)
    % Initialize and discretize nodes
    pos = 0;
    disc_nodes = zeros(sum(beams.disc - 1), 3);  % Preallocate for efficiency
    
    for p = 1:beams.nbeams
        nodeHeadId = beams.nodesHead(p);
        nodeEndId = beams.nodesEnd(p);
        
        % Precompute difference and fraction to avoid repetition
        delta = (beams.vertex(p,:)' ./ beams.disc(p));
        headPos = [nodes.x(nodeHeadId); nodes.y(nodeHeadId); nodes.z(nodeHeadId)];
        
        for s = 1:(beams.disc(p)-1)
            disc_nodes(pos + s, :) = headPos + delta * s;
        end
        
        pos = pos + (beams.disc(p) - 1);  % Update position outside loop
    end
    
    % Concatenate original and discretized nodes
    oofem.nodes = [[nodes.x, nodes.y, nodes.z]; disc_nodes];
    
    % Initialize variables for the beam part
    pos = nodes.nnodes;  % Replace nnodes with nodes.nnodes
    beamId = 0;
    disc_beam = zeros(sum(beams.disc) - beams.nbeams, 2);  % Preallocate
    
    for p = 1:beams.nbeams
        nodeHead = beams.nodesHead(p);
        nodeEnd = beams.nodesEnd(p);
        n_disc = beams.disc(p);

       
        
        beamId = beamId + 1;
        pos = pos + 1;
        disc_beam(beamId, :) = [nodeHead, pos];  % First segment     
        disc_XY(beamId, :) = [oofem.nodes(nodeHead,:)] + beams.XY(p,:);
        for s = 2:(n_disc-1)
            beamId = beamId + 1;
            disc_beam(beamId, :) = [pos, pos + 1];  % Interior segments
            disc_XY(beamId, :) = [oofem.nodes(pos,:)] + beams.XY(p,:);
            pos = pos + 1;
        end
        beamId = beamId + 1;
        disc_beam(beamId, :) = [pos, nodeEnd];  % Final segment
        disc_XY(beamId, :) = [oofem.nodes(pos,:)] + beams.XY(p,:);
    end
    oofem.beams = disc_beam;
    oofem.refNode = disc_XY;
    
    % Initialize section discretization
    % Build per-beam sectionProp so oofem.py correctly maps set p -> cross-section p.
    % (oofem.py assigns set p to SimpleCS p; without this, beams sharing a section type
    %  would each get a different SimpleCS from sections.id ordering.)
    pos = 0;
    for p = 1:beams.nbeams
        n_disc = beams.disc(p);
        stype = beams.sections(p);   % 1-based index into sections.*
        disc_section.Id(p) = p;      % each beam gets its own cross-section number
        disc_section.range(p,:) = [pos + 1, pos + n_disc];
        perBeamSections.A(p,1)  = sections.A(stype);
        perBeamSections.Iy(p,1) = sections.Iy(stype);
        perBeamSections.Iz(p,1) = sections.Iz(stype);
        perBeamSections.Ix(p,1) = sections.Ix(stype);
        perBeamSections.E(p,1)  = sections.E(stype);
        perBeamSections.v(p,1)  = sections.v(stype);
        pos = pos + n_disc;
    end
    oofem.sections = disc_section;

    % Load discretization
   
    for l = 1:size(loads.x.nodes, 1)
        if isempty(loads.x.nodes)
            disc_loads.X(l, :) = [[],[]];    
        else
            disc_loads.X(l, :) = [loads.x.nodes(l), loads.x.value(l)];
        end
    end

    for l = 1:size(loads.y.nodes, 1)
        if isempty(loads.y.nodes)
            disc_loads.Y(l, :) = [[],[]];    
        else
            disc_loads.Y(l, :) = [loads.y.nodes(l), loads.y.value(l)];
        end
    end
    
    for l = 1:size(loads.z.nodes, 1)
        if isempty(loads.z.nodes)
            disc_loads.Z(l, :) = [[],[]];    
        else
            disc_loads.Z(l, :) = [loads.z.nodes(l), loads.z.value(l)];
        end
    end

    for l = 1:size(loads.rx.nodes, 1)
        if isempty(loads.rx.nodes)
            disc_loads.RX(l, :) = [0,0];    
        else
            disc_loads.RX(l, :) = [loads.rx.nodes(l), loads.rx.value(l)];
        end
    end
    
    for l = 1:size(loads.ry.nodes, 1)
        if isempty(loads.ry.nodes)
            disc_loads.RY(l, :) = [0,0];
        else
            disc_loads.RY(l, :) = [loads.ry.nodes(l), loads.ry.value(l)];
        end
    end

    for l = 1:size(loads.rz.nodes, 1)
        if isempty(loads.rz.nodes)
            disc_loads.RZ(l, :) = [0,0];
        else
            disc_loads.RZ(l, :) = [loads.rz.nodes(l), loads.rz.value(l)];
        end
    end
    
    oofem.loads = disc_loads;
    
    % Add kinematic and section properties to oofem
    oofem.kinematic = kinematic;
    oofem.sectionProp = perBeamSections;  % per-beam so oofem.py set p -> SimpleCS p is correct
    
    % Save the oofem structure to a .mat file
    save(filename, 'oofem');
end

