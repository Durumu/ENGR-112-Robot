function motor_to_rotation(motor,target,speed,time,acc)
if nargin == 2
    speed = 2;
    time = 0.05;
end
if nargin < 5
    acc = 2;
end

current_point = readRotation(motor);
while abs(current_point-target) >= acc
    s = speed;
    if abs(current_point-target) >= acc * 10
        s = min(100,s*3);
    end
    
    if target < current_point
        run_motor(motor,-s,time,0);
    else
        run_motor(motor,s,time,0);
    end
    current_point = readRotation(motor);
end