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


barcode_rgb = [
    300,300,250, 0;
    47, 58, 32, 1;
    85,93, 69,-1];

rotations = [620,367,538,290,451,195,100,0];
marble_order = [8,7,6,4,2,5,3,1];


e = legoev3('usb');

barcode_sensor = colorSensor(e);

knock_motor = motor(e,'A');
belt_motor = motor(e,'B');
barcode_motor = motor(e,'C');

current_code = [];
codes_processed = 0;

starting_belt_rotation = readRotation(belt_motor);
starting_knock_rotation = readRotation(knock_motor);

marbles_needed = ones(1,8);%[0 0 0 1 0 1 0 0];%

% Process all the bar codes
% ============================================

processing_codes = false;%true;
while processing_codes
    [r, g, b] = read_rgb(barcode_sensor);
    fprintf('R: %03d, G: %03d, B: %03d\n',r,g,b);
    
    [closest_br, closest_distance_br] = find_closest(r,g,b,barcode_rgb);
    
    disp(closest_br);
    
    if closest_br >= 0
        current_code = [current_code num2str(closest_br)];
    elseif numel(current_code) > 8
        first = find(current_code=='1',1);
        fprintf('%s\n',current_code(first+1:numel(current_code)));
        [d1, d2] = decode(current_code);
        
        % print the amount of each marble needed for debug reasons
        fprintf('%s x%d\n%s x%d\n',types(d1.t,:),d1.q,types(d2.t,:),d2.q);
        
        % update the amount of marbles needed with new quantities
        marbles_needed(d1.t) = marbles_needed(d1.t) + d1.q;
        marbles_needed(d2.t) = marbles_needed(d2.t) + d2.q;
        
        current_code = [];
        
        codes_processed = codes_processed + 1;
        if codes_processed == 1%4
            processing_codes = false;
        end
    else
        current_code = [];
    end
    
    pause(0.75);
    
    %run barcode motor
    if processing_codes
        %rotate the barcode reader the correct amount
        rotation_amount = 96;
        starting_barcode_rotation = readRotation(barcode_motor);
        while (readRotation(barcode_motor) > (starting_barcode_rotation-rotation_amount))
            run_motor(barcode_motor,-40,.01);
        end
    end
    
    pause(0.75);
end

fprintf('DONE PROCESSING BAR CODES\nFINAL COUNTS:\n');

for i=1:8
    if marbles_needed(i) > 0
        fprintf('%s x%d\n',types(i,:),marbles_needed(i));
    end
end

while exists('C:\Users\jackp\Google Drive\Lego Project\marble_count.txt','file') ~= 2
    pause(1);
    fprintf('waiting...\n');
end

% TODO -- Dispense the marbles...
% ============================================

% while true
%     fprintf('%d\n',readRotation(belt_motor)-starting_belt_rotation);
% end

dispensing = true;
for i=marble_order
    while (marbles_needed(i) > 0) && dispensing         
        %move to the place of the marble
        motor_to_rotation(belt_motor,rotations(i)+starting_belt_rotation,40,0.03,3);
        
        fprintf('%d\n',readRotation(belt_motor)-starting_belt_rotation);
        
        %knock that fucker right out
        rotation_amount = 200;
        
        while (readRotation(knock_motor) > (starting_knock_rotation-rotation_amount))
            run_motor(knock_motor,-100,.01,0);
        end
        while (readRotation(knock_motor) < (starting_knock_rotation))
            run_motor(knock_motor,70,.01);
        end
        
        % we don't need any more of those bad boys
        marbles_needed(i) = marbles_needed(i) - 1;
    end
end

motor_to_rotation(belt_motor,starting_belt_rotation,40,0.03,2);