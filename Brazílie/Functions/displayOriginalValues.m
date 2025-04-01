function displayOriginalValues(section,EN)
% Display original area values from the file
fprintf('\nOriginal cross-sectional area values:\n');
fprintf('Original section area (A_s): %.6f m² (%.2f mm²)\n', section.A_s, section.A_s * 10^6);
fprintf('Eurocode required area (A_s_EN): %.6f m² (%.2f mm²)\n', EN.A_s_en, EN.A_s_en * 10^6);
fprintf('Original ratio (A_s/A_s_EN): %.4f\n', section.A_s / EN.A_s_en);
end