# Create a clock for i2s module
create_clock -name i2sclk -period 640.000 {audio_top:u_audio_i2s|tcount[4]}
