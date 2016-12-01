function lcmOut = LCMrat(v1,v2)
%LCMRAT gives LCM of 2 non-integer numbers by looking at rational
%approximation (http://www.edugain.com/blog/2011/06/26/lcm-of-fractions/)
%Gary Wolfowicz
[a,b] = rat(v1);
[c,d] = rat(v2);

lcmOut = lcm(b,d);
a = a*lcmOut/b;
c = c*lcmOut/d;

lcmOut = lcm(a,c)/lcmOut;

end

