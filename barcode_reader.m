clear;
% a marble struct t value represents one of these types
%types = ['LW';'SW';'LR';'SR';'LB';'SB';'ST';'HD'];

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
     58, 69, 42, 1;
     45, 45, 34, 1;
    120,140, 100,-1];
    
counts = zeros(1,8);
codes = 0;

e2 = legoev3('usb');

dm = motor(e2,'A'); % dispenses the marbles

cbm = motor(e2,'B'); % makes the conveyor belt go

br = colorSensor(e2);
brm = motor(e2,'C'); % pushes the barcodes through

current_code = [];

starting_position = readRotation(cbm);


% %Barcode 

while true
    color = readColorRGB(br);
    fprintf('R:%03d G:%03d B:%03d\n',color(1),color(2),color(3));
    
    closest = -2; %identity of closest
    closest_distance = inf; %closest distance
    
    for i=1:size(barcode_rgb,1)
        distance = (color(1)-barcode_rgb(i,1))^2 + (color(2)-barcode_rgb(i,2))^2 + (color(3)-barcode_rgb(i,3))^2;
        if distance < closest_distance
            closest = barcode_rgb(i,4);
            closest_distance = distance;
        end
    end
    
    disp(closest);
    
    if closest >= 0
        current_code = [current_code num2str(closest)];
    elseif numel(current_code) > 8
        first = find(current_code=='1',1);
        fprintf('%s\n',current_code(first+1:numel(current_code)));
        [d1, d2] = decode(current_code);
        
        fprintf('%s x%d\n%s x%d\n',types(d1.t,:),d1.q,types(d2.t,:),d2.q);
        counts(d1.t) = counts(d1.t) + d1.q;
        counts(d2.t) = counts(d2.t) + d2.q;
        
        current_code = [];
        
        codes = codes + 1;
        if codes == 4
            break
        end
    else
        current_code = [];
    end
    
    %run motor
    
    brm.Speed = -90;
    brm.start();
    pause(.202);
    brm.stop(1);
    
    pause(2);
end

fprintf('\nFINAL COUNTS\n================\n');

for i=1:13
    if counts(i) > 0
        fprintf('%s x%d\n',types(i,:),counts(i));
    end
end



cbm.Speed = 30;
cbm.start();
pause(3);
cbm.stop(1);

relative_position = (readRotation(cbm) - starting_position);

disp(relative_position);