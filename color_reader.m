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

linenumber = size(cr_rgb,1)+1;

e = legoev3('usb');
%f = legoev3('bt','00165344db01');

cr = colorSensor(e);
crm = motor(e,'A');
dm = motor(e,'B');
sm = motor(e,'C');

current_code = [];

starting_rotation = readRotation(sm);

marbles_sorted = zeros(1,8);

while true
    starting_rotation_dm = readRotation(dm);
    current_point = starting_rotation_dm;
    while (current_point > (starting_rotation_dm-97))
        current_point = readRotation(dm);
        dm.Speed = -40;
        dm.start()
        pause(.01);
        dm.stop();
    end
    
    color = readColorRGB(cr);
    r = color(1);
    g = color(2);
    b = color(3);
    
    fprintf('R: %03d, G: %03d, B: %03d\n',r,g,b);
    
    closest = -2; %identity of closest
    closest_distance = inf; %closest distance
    
    for i=1:size(cr_rgb,1)
        distance = (r-cr_rgb(i,1))^2 + (g-cr_rgb(i,2))^2 + (b-cr_rgb(i,3))^2;
        if distance < closest_distance
            closest = cr_rgb(i,4);
            closest_distance = distance;
        end
    end
    
    fprintf('%s\n',types(closest,:));
    
    if (closest_distance > 5)
        fprintf('Faraway read! (type %d, %d away, line #%d)\n',closest,closest_distance,linenumber);
        fprintf(rgbfile,'%03d, %03d, %03d, %d;\n',r,g,b,closest);
        cr_rgb = [cr_rgb; r g b closest];
        linenumber = linenumber + 1;
        beep(e);
    end
    
    if (closest < 13) % we didn't get nothing
        if (closest <= 8)
            marbles_sorted(closest) = marbles_sorted(closest) + 1;
        end
        current_point = readRotation(sm);
        while (abs(current_point-(rotations(closest)+starting_rotation)) >= 2)
            current_point = readRotation(sm);
            if ((rotations(closest)+starting_rotation) < current_point)
                sm.Speed = -2;
            else
                sm.Speed = 2;
            end
            sm.start();
            pause(.05);
            sm.stop();
        end
        crm.Speed = -20;
        crm.start();
        pause(.225);
        crm.stop(1);
        pause(1);
        crm.Speed = 20;
        crm.start();
        pause(.225)
        crm.stop(1);
        pause(2)
    else
        
    end
    
    
end

