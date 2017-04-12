clear variables;

% Initialize data
% ===========================================

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

linenumber = size(cr_rgb,1)+1;

marbles_sorted = zeros(1,8);
marbles_needed = zeros(1,8);

consecutive_nothing = 0;

current_code = [];
codes_processed = 0;

% Initialize ev3s e and f
% ===========================================

e = legoev3('usb');
f = legoev3('bt','00165344db01');

color_reader = colorSensor(e);
gate_motor = motor(e,'A');
dispenser_motor = motor(e,'B');
sort_motor = motor(e,'C');

barcode_reader = colorSensor(f);
belt_motor = motor(f,'B');
barcode_motor = motor(f,'C');


starting_sort_rotation = readRotation(sort_motor);
starting_belt_rotation = readRotation(belt_motor);

% Sort all the marbles
% ============================================

while true
    
    % run the dispenser
    dispenser_motor.Speed = -35;
    dispenser_motor.start();
    pause(0.60);
    dispenser_motor.stop(1)
   
    % wait for the marble to hit color reader area
    pause(2);
    
    % get and print color from the color reader
    [r, g, b] = read_rgb(color_reader);
    fprintf('R: %03d, G: %03d, B: %03d\n',r,g,b);
    
    closest = -2; %identity of closest marble
    closest_distance = inf; %the length of the smallest rgb vector
    
    % attempt to identify marble by finding marble most similar in cr_rgb
    for i=1:size(cr_rgb,1)
        distance = (r-cr_rgb(i,1))^2 + (g-cr_rgb(i,2))^2 + (b-cr_rgb(i,3))^2;
        if distance < closest_distance
            closest = cr_rgb(i,4);
            closest_distance = distance;
        end
    end
    
    fprintf('%s\n',types(closest,:));
    
    if (closest_distance > 5)
        % we have new data so we will write it to the main file.
        fprintf('Faraway read! (type %d, %d away, line #%d)\n',closest,closest_distance,linenumber);
        fprintf(rgbfile,'%03d, %03d, %03d, %d;\n',r,g,b,closest); %write new data to file
        cr_rgb = [cr_rgb; r g b closest];
        linenumber = linenumber + 1;
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
                sort_motor.Speed = -2;
            else
                sort_motor.Speed = 2;
            end
            sort_motor.start()
            pause(.05);
            sort_motor.stop();
        end
        
        % open the floodgates!
        open_gate(gate_motor);
    else
        consecutive_nothing = consecutive_nothing + 1;
        if consecutive_nothing >= 3
            open_gate(gate_motor);
        end
    end
    
end

