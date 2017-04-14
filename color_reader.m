clear variables;

types = [
    'large white glass '; % 1
    'small white glass '; % 2
    'large red glass   '; % 3
    'small red glass   '; % 4
    'large blue glass  '; % 5
    'small blue glass  '; % 6
    'steel             '; % 7
    'HDPE plastic      '; % 8
    'large yellow glass'; % 9
    'small yellow glass'; %10
    'large green glass '; %11
    'small green glass '; %12
    'nothing           '];%13

rotations = [32,0,20,-12,10,-22,-32,-45,45,45,45,45,45];

cr_rgb = load('eabc_rgb.txt');

rgbfile = fopen('eabc_rgb.txt','a');

line_number = size(cr_rgb,1)+1;

e = legoev3('usb');

color_reader = colorSensor(e);

gate_motor = motor(e,'A');
dispenser_motor = motor(e,'B');
sort_motor = motor(e,'C');

starting_rotation = readRotation(sm);

marbles_sorted = zeros(1,8);
 
starting_sort_rotation = readRotation(sort_motor);
starting_dispenser_rotation = readRotation(dispenser_motor); 
 
% Sort all the marbles 
% ============================================ 
 
sorting = true; 
while sorting 
    
    % run the dispenser for 1 marble worth of rotation
    starting_dispenser_rotation = readRotation(dispenser_motor);
    rotation_amount = 97; %97 degrees is the amount to rotate for 1 marble
    while (readRotation(dispenser_motor) > (starting_dispenser_rotation-97))
        run_motor(dispenser_motor,-40,.01);
    end
   
    % wait for the marble to hit color reader area
    pause(2);
    
    % get and print color from the color reader
    [r, g, b] = read_rgb(color_reader);
    fprintf('R: %03d, G: %03d, B: %03d\n',r,g,b);
    
    % attempt to identify marble by finding marble most similar in cr_rgb
    [closest, closest_distance] = find_closest(r,g,b,cr_rgb);
    
    fprintf('%s\n',types(closest,:));
    
    if (closest_distance > 5)
        % we have new data so we will write it to the main file.
        fprintf('Faraway read! (type %d, %d away, line #%d)\n',closest,closest_distance,line_number);
        fprintf(rgbfile,'%03d, %03d, %03d, %d;\n',r,g,b,closest); %write new data to file
        cr_rgb = [cr_rgb; r g b closest];
        line_number = line_number + 1;
        beep(e); % alert us of faraway read
    end
    
    if (closest < 13) 
        % identified as a marble, not as nothing, so the streak is broken
        consecutive_nothing = 0;
        
        if (closest <= 8)
            % one of the marbles we are looking for, increment its position
            % in marbles_sorted
            marbles_sorted(closest) = marbles_sorted(closest) + 1;
        end
        
        % move the sorting motor to the right position
        current_point = readRotation(sort_motor);
        while (abs(current_point-(rotations(closest)+starting_sort_rotation)) >= 2)
            current_point = readRotation(sort_motor);
            if ((rotations(closest)+starting_sort_rotation) < current_point)
                run_motor(sort_motor,-2,.05);
            else
                run_motor(sort_motor,2,.05);
            end
        end
        
        % open the floodgates!
        open_gate(gate_motor);
    elseif sum(marbles_sorted) > 5 % we might be done sorting if we get a nothing in the middle
        consecutive_nothing = consecutive_nothing + 1;
        if (consecutive_nothing == 3) % if we got 3 nothing in a row
            open_gate(gate_motor);
        elseif consecutive_nothing > 3
            sorting = false; % we are done sorting
        end
    end
    
end

fprintf('DONE SORTING\n');

% file output