sort_motor = motor(e,'C'); 
 
barcode_reader = colorSensor(f); 
knock_motor = motor(f,'A'); 
belt_motor = motor(f,'B'); 
barcode_motor = motor(f,'C'); 
 
 
starting_sort_rotation = readRotation(sort_motor); 
starting_belt_rotation = readRotation(belt_motor); 
starting_dispenser_rotation = readRotation(belt_motor); 
 
% Sort all the marbles 
% ============================================ 
 
sorting = true; 
while sorting 
     
    % run the dispenser 
    dispenser_motor.Speed = -35; 
    dispenser_motor.start(); 
    pause(0.60); 
    dispenser_motor.stop(1) 
    % run the dispenser for 1 marble worth of rotation 
    starting_dispenser_rotation = readRotation(dispenser_motor); 
    rotation_amount = 97; %97 degrees is the amount to rotate for 1 marble 
    while (readRotation(dispenser_motor) > (starting_dispenser_rotation-97)) 
        dispenser_motor.Speed = -40; 
        dispenser_motor.start(); 
        pause(.01); 
        dispenser_motor.stop(); 
    end 
    
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