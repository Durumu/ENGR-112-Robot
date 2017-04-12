% DECODE will decode a marble binary code, returning two structs with
% t representing type and q representing quantity
function [d1, d2] = decode(s)

d1 = struct;
d1.t = 13; %nothing
d1.q = 0;

d2 = struct;
d2.t = 13; %nothing
d2.q = 0;

sizes = zeros(2,16);
for i=1:16
    sizes(1,i) = mod(i-1,4);
    sizes(2,i) = ceil((i-1) / 4);
end

first = 0;

for i=1:8
    if s(i) == '1'
        first = i;
        break;
    end
end

s = s(first+1:numel(s));

if numel(s) < 8
    return
end

typenum = bin2dec(fliplr(s(1:3)));
sizenum = bin2dec(fliplr(s(4:8)));

d1.t = typenum*2-1;
d1.q = sizes(1,sizenum);

d2.t = typenum*2;
d2.q = sizes(2,sizenum);