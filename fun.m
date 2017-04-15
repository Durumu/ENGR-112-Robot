clear variables;

e = legoev3('usb');
sort_motor = motor(e,'C');
starting_sort_rotation = readRotation(sort_motor);

while true
    fprintf('%d\n',readRotation(sort_motor)-starting_sort_rotation);
end