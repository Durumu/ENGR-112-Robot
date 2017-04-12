function open_gate(gate_motor)
gate_motor.Speed = -20;
gate_motor.start();
pause(.225);
gate_motor.stop(1);
pause(1);
gate_motor.Speed = 20;
gate_motor.start();
pause(.225)
gate_motor.stop(1);
pause(2)
end