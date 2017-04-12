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
knock_motor = motor(f,'A');
belt_motor = motor(f,'B');
barcode_motor = motor(f,'C');


starting_sort_rotation = readRotation(sort_motor);
starting_dispenser_rotation = readRotation(belt_motor);

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
                run_motor(sort_motor,-2,.05);
            else
                run_motor(sort_motor,-2,.05);
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

% Process all the bar codes
% ============================================

processing_codes = true;
while processing_codes
    [r, g, b] = read_rgb(barcode_reader);
    fprintf('R: %03d, G: %03d, B: %03d\n',r,g,b);
    
    [closest_br, closest_distance_br] = find_closest(r,g,b,barcode_rgb);
    
    disp(closest_br);
    
    if closest_br >= 0
        current_code = [current_code num2str(closest_br)];
    elseif numel(current_code) > 8
        %first = find(current_code=='1',1);
        %fprintf('%s\n',current_code(first+1:numel(current_code)));
        [d1, d2] = decode(current_code);
        
        % print the amount of each marble needed for debug reasons
        fprintf('%s x%d\n%s x%d\n',types(d1.t,:),d1.q,types(d2.t,:),d2.q);
        
        % update the amount of marbles needed with new quantities
        marbles_needed(d1.t) = marbles_needed(d1.t) + d1.q;
        marbles_needed(d2.t) = marbles_needed(d2.t) + d2.q;
        
        current_code = [];
        
        codes = codes + 1;
        if codes == 4
            processing_codes = false;
        end
    else
        current_code = [];
    end
    
    %run barcode motor
    if processing_codes
        run_motor(barcode_motor,-90,.202);
        pause(2);
    end
end

fprintf('DONE PROCESSING BAR CODES\nFINAL COUNTS:\n');

for i=1:8
    if marbles_needed(i) > 0
        fprintf('%s x%d\n',types(i,:),marbles_needed(i));
    end
end

% TODO -- Dispense the marbles...
% ============================================