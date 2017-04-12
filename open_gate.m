function open_gate(gate_motor)
run_motor(gate_motor,-20,.225);
pause(1);
run_motor(gate_motor,20,.225);
pause(2)
end