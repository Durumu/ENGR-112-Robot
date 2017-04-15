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

rotations = [37,-5,19,-14,9,-25,-37,-52,80];

cr_rgb = load('rgb.txt');

rgbfile = fopen('rgb.txt','a');

line_number = size(cr_rgb,1)+1;

e = legoev3('usb');

color_sensor = colorSensor(e);
touch_sensor = touchSensor(e);

gate_motor = motor(e,'A');
dispenser_motor = motor(e,'B');
sort_motor = motor(e,'C');

marbles_sorted = zeros(1,8);

starting_sort_rotation = readRotation(sort_motor);

starting_dispenser_rotation = readRotation(dispenser_motor);
rotation_amount = 115; %amount to rotate dispenser for 1 marble

% Sort all the marbles
% ============================================

pause(1);

sorting = true;
while sorting
    % run the dispenser for 1 marble worth of rotation
       starting_dispenser_rotation = readRotation(dispenser_motor);
        while (readRotation(dispenser_motor) > (starting_dispenser_rotation - rotation_amount*.75))
            run_motor(dispenser_motor,-75,.01,0);
            while readTouch(touch_sensor)
                pause(.1);
            end
        end
    
    %motor_to_rotation(dispenser_motor,readRotation(dispenser_motor)-rotation_amount,30,.01);
    
    fprintf('Dispenser rotated to %d\n',mod(readRotation(dispenser_motor),rotation_amount));
    
    % wait for the marble to hit color reader area
    pause(1.6);
    
    % get and print color from the color reader
    [r, g, b] = read_rgb(color_sensor);
    fprintf('R: %03d, G: %03d, B: %03d\n',r,g,b);
    
    % attempt to identify marble by finding marble most similar in cr_rgb
    [closest, closest_distance] = find_closest(r,g,b,cr_rgb);
    
    fprintf('Identfied as %s\n',types(closest,:));
    
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
        
        fprintf('Sorting the marble\n');
        
        % move the sorting motor to the right position
        motor_to_rotation(sort_motor,rotations(min(closest,9))+starting_sort_rotation,10,.01,1);
        
        fprintf('Sort rotation: %d (correct: %d)\n',readRotation(sort_motor)-starting_sort_rotation,rotations(min(closest,9)));
        
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

% transferred_file = fopen('C:\Users\Jonathan\Google Drive\Lego Project\marble_count.txt','w');
% for i=1:8
%     fprintf(transferred_file,'%i,',marbles_sorted(i));
% end
fprintf('DONE SORTING\n');

% file output