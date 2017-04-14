function run_motor(motor,speed,time,brake)
if nargin == 3
    brake = 1;
end

if brake
    
else
    motor.stop();
end
end