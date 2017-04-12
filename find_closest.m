function [closest, closest_distance] = find_closest(r,g,b,rgb_list)

closest = 0;
closest_distance = inf;
for i=1:size(rgb_list,1)
    % treating r,g,b as a point in 3-space, distance is equal to the dot
    % product of the vector of the differences between the r, g, b values 
    % of the point found and the point we are comparing it to with itself
    distance = (r-rgb_list(i,1))^2 + (g-rgb_list(i,2))^2 + (b-rgb_list(i,3))^2;
    if distance < closest_distance
        closest = rgb_list(i,4);
        closest_distance = distance;
    end
end

end