W = 1920;
H = 1080;
occupancy = 50;
angle_step_deg = 0.5;
angle_step = angle_step_deg * pi / 180;

rpm = 720;
fps = 60;
run_time = 2;
frames = run_time*fps;

frame_time = 1 / fps;

rps = rpm / 60;
rotation_period = 1 / rps;

angular_freq = 2 * pi / rotation_period;

theta = angular_freq * frame_time;
theta_deg = 180 * theta / pi;
sub_frame_steps = ceil(theta_deg / angle_step_deg);

leds = 20;
offset = 10;
led_separation = 4;
led_radius = 1;

x = 0:led_separation:(led_separation*(leds-1));
x = x + offset;
pixels_per_mm = W / (2 * (max(x) + led_radius));
pixels_per_mm = pixels_per_mm * occupancy / 100;
led_pixel_radius = ceil(led_radius * pixels_per_mm);
mask_range = 1:(2*led_pixel_radius+1);

[led_mask_x, led_mask_y] = meshgrid(mask_range,mask_range);
led_offset_x = mask_range;
led_offset_y = mask_range;
led_mask_x = led_mask_x - 1;
led_mask_y = led_mask_y - 1;
led_mask_x = led_mask_x - led_pixel_radius;
led_mask_y = led_mask_y - led_pixel_radius;
dist = led_mask_x .* led_mask_x +led_mask_y .* led_mask_y;
mask = dist <= (led_pixel_radius*led_pixel_radius);
mask_size = size(mask,2);

XY = [x; zeros(size(x))];

ang = 0;
ang_deg = 0;
origin = [W H] * 0.5;
avg_scale = 16 / sub_frame_steps;
colour = floor(rand(leds,3) * 255);
I_avg = zeros(H,W,3);

weights = 1:sub_frame_steps;
weights = weights ./ sum(weights);
weights = weights * 10;
  
for f = 1:frames    
    ang_sub = ang;    
    
    for sf = 1:sub_frame_steps
        cos_A = cos(ang_sub);
        sin_A = sin(ang_sub);
        ang_sub = ang_sub + angle_step;
        A = [cos_A -sin_A; sin_A cos_A];
        colour_new = floor(rand(leds,3) * 255);
        colour = (0.9*colour + 0.1*colour_new);
        xy = A*XY;
        uv = xy * pixels_per_mm;
        uv = uv + repmat(origin',1,leds);
        uv = floor(uv+0.5);
        
        I = zeros(H,W,3);
        
        
        for led = 1:leds
            
            by = led_offset_y + repmat(uv(2,led) - led_pixel_radius,1,mask_size);
            bx = led_offset_x + repmat(uv(1,led) - led_pixel_radius,1,mask_size);
            
            for chn = 1:3
                I(by,bx,chn) = colour(led,chn);
                I(by,bx,chn) = I(by,bx,chn) .* double(mask);
            end
        end
        
        I_avg = I_avg + weights(sf) .* I;
        %         I_avg = max(I_avg,I);
    end
    

    I = uint8(I_avg);
    numstr = sprintf('%05u', f-1);
    imwrite(I,['render/frame' numstr '.png']);
    figure(1);
    image(I); axis image; axis off; colormap(gray(256));
    
    I_avg = I_avg .* min(weights);
    ang = ang + theta;
    ang_deg = ang_deg + theta_deg;
end
