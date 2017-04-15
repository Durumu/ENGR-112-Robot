function motor_to_rotation(motor,target,speed,time,acc)
if nargin < 5
    acc = 2;
end

current_point = readRotation(motor);
while abs(current_point-target) >= acc
    s = speed;
    if abs(current_point-target) >= 5*acc + 15
        if s > 0
            s = max(s*5,100);
        else
            s = min(s*5,-100);
        end
    end
    
    if target < current_point
        run_motor(motor,-s,time,0);
    else
        run_motor(motor,s,time,0);
    end
    current_point = readRotation(motor);
end