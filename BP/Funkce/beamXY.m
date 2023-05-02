function XY = beamXY(beam,nodes)
    for i = 1:beam.nbeam;
        if beam.vertex(i,1) == 0
            XY(i,:)     = [ -1 0 0 ];
        else
            XY(i,:)     = [ 0 1 0 ];
        end
    end
end