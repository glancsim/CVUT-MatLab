% Prirazeni vektoruXY jednotlivým elementům prutu
%
% In: 
%   beams.disc - diskretizace prutu
%   numberOfBeam - pocet prutu
%   beamVectorXY - vektor v rovině XY pro jednotlivé pruty   
%
% Out:
%   elementVectorXY - vektor v rovině XY pro jednotlivé elementy     
%
% Ověřeno geometrickým zobrazením pootočeného LCSka 9.12.2024
% (c) S. Glanc, 2022


function [XY]=XYtoRotBeamsFn(beams,angles)
    for b = 1:beams.nbeams
        theta = deg2rad(angles(b));
        Rx = [
            1, 0, 0;
            0, cos(theta), -sin(theta);
            0, sin(theta), cos(theta)
        ];

        % Normalizace vektoru X
        K = beams.vertex(b,:) / norm(beams.vertex(b,:));
        % Úhel otočení (v radianech)
        alpha = deg2rad(angles(b));

        if beams.vertex(b,1) == 0 && beams.vertex(b,2) == 0 
            % Výpočet kolmého vektoru k svislé rovině
            Y = cross(beams.vertex(b,:), [1, 0, 0]);
            % Normalizace výsledného vektoru (volitelné)
            Y = -Y / norm(Y);
            XY(b,:) = Y * cos(alpha) + cross(K, Y) * sin(alpha) + K * dot(K, Y) * (1 - cos(alpha));
        else
            % Výpočet kolmého vektoru k svislé rovině
            Y = cross(beams.vertex(b,:), [0, 0, 1]);
            % Normalizace výsledného vektoru (volitelné)
            Y = -Y / norm(Y);
            XY(b,:) = Y * cos(alpha) + cross(K, Y) * sin(alpha) + K * dot(K, Y) * (1 - cos(alpha));
        end
    end
end