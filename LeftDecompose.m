function [digits] = LeftDecompose(number, base, nVariable)

% Decompose a number in any base. Base 2 will be used to obtain a list of states with binary
% entries.

quotient = floor(number/base^(nVariable-1));
remainder = number - quotient * base^(nVariable-1);
if remainder == 0            
    digits = [zeros(1, nVariable-1) quotient];
else
    digits = [LeftDecompose(remainder, base, nVariable - 1) quotient];
end

end

