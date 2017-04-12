function run_motor(motor,speed,time,brake)
if nargin == 3
    brake = 1;
end
motor.Speed = speed;
motor.start();
pause(time);
if brake
    motor.stop(1);
else
    motor.stop();
end
end