function sound_singletone(freq,duration)

amp=10 
fs=40000 % sampling frequency
values=0:1/fs:duration;
a=amp*sin(2*pi* freq*values);

sound(a,fs);

end
