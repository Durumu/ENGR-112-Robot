function [r, g, b] = read_rgb(sensor)
color = readColorRGB(sensor);
r = color(1); g = color(2); b = color(3);
end