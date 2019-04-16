close all;
clear all;
points = csvread('scan_fish1.csv');
[row, col] = size(points);

mess_factor = 0.02;     %片质量调整因子，其值为质量的控制误差，取值越小，质量控制越精确
angle_factor = 0.5;       %角调整因子，取值0到1，值越小角度变化越小，最大步进调整角度1°，取0时仅调整对角线
dia_factor = 3;         %对角调整因子，取值0到1，值越小对角线变化越小，最大步进调整0.5mm，取0时进调整角度

total_volume = 0;
piece_volume = 100000; %设定切片体积为40000立方毫米
err_allowed = piece_volume * mess_factor; %单片切片允许误差
dia_err = 0.05;
cut_begin = 100;        %定义起刀位置
cut_angle = pi / 4;     %切刀角度

x_resolution = 0.3;
y_resolution = 0.5;
z_scale = 100;  

for i = 1:row
    for j = 1:col
        if points(i, j) == -32768
            points(i, j) = 0;
        else 
            points(i, j) = points(i, j) * 0.72 + 4392;      %添加偏置，单位为百分之一毫米
            total_volume = total_volume + points(i, j) / z_scale * y_resolution * x_resolution;
        end
    end
end

% figure;
% mesh(points);
disp(['鱿鱼的总体积为：' num2str(total_volume) '立方毫米']);



%中值滤波
points = medfilt2(points);
fil_total_volume = 0;       %经过滤波的鱿鱼体积
for i = 1:row
    for j = 1:col
        fil_total_volume = fil_total_volume + points(i, j) / z_scale * y_resolution * x_resolution;
    end
end
disp(['经过滤波鱿鱼的总体积为：' num2str(fil_total_volume) '立方毫米']);

%% 初始偏移
for i = 1:row           %找到开始偏移
    row_length = sum(points(i, :)~=0);
    if row_length > 10
        points = points(i:end, :);
        break;
    end
end
[row, col] = size(points);

%% 获取鱿鱼特征信息
%获取鱿鱼侧面轮廓，以鱿鱼最长处为侧面轮廓
points_profile = points(:, sum(points) == max(sum(points)));
profile_col = 1:row;
figure;
plot(profile_col, points_profile);

max_width = max(sum(points~=0, 2));   %鱿鱼最大宽度

%查找尾料部分起始位置，以尾端宽度小于最大宽度的百分之八十为基准
for i = row:-1:1
    row_length = sum(points(i, :) ~= 0);
    if row_length > max_width * 0.8
        fish_end = i;
        break;
    end
end

cal_points = points;
cal_points(fish_end:row, :) = 0; 

tail_volume = 0;    %尾料体积
for i = fish_end:row
    for j = 1:col
        tail_volume = tail_volume + points(i, j) / z_scale * y_resolution * x_resolution;
    end
end

% figure;
% mesh(cal_points)

min_cost = 10000;           %设定初始的最小代价，大一点
for begin_cut_angle = pi/6 : pi/90: pi/3
%以能够大头方向最凹点为基准，确定第一刀的落刀位置
    cut_angle = begin_cut_angle;
    for i = 1:row
        row_length = sum(cal_points(i, :) ~= 0);
        row_length_1cm = sum(cal_points(i + 20, :) ~= 0);
        if abs(row_length - row_length_1cm)  < 33.3
            cut_start = i + 5;
            cut = generate_cut(cut_start, cut_angle, row, col, y_resolution, z_scale);
            break;
        end
    end
    
%% 切第一刀
    first_cut_volume = cal_volume(cut, cut_start, cal_points, row, col, x_resolution, y_resolution, z_scale);
%     disp(['第一刀废料体积为：' num2str(fil_total_volume-first_cut_volume-tail_volume) '立方毫米']);
%     disp(['第一刀角度：' num2str(cut_angle/pi*180) '°']);

    %% 切刀开始初始化
    cuts = cut_start;                                  %用于存储切刀落刀位置
    cut_angles = cut_angle;                            %存储落刀角度
    cut_volumes = [];                                  %存储切片体积
    cut_gap = 0;
    logical cut_finish;
    cut_finish = 0;
    first_cut_start = cut_start;

    %%  首先根据前两刀确定对角长度
    next_cut_start = first_cut_start;
    while(1)
        next_cut = generate_cut(next_cut_start, cut_angle, row, col, y_resolution, z_scale);                   
        next_cut_volume = cal_volume(next_cut, next_cut_start, cal_points, row, col,  x_resolution, y_resolution, z_scale);
        if next_cut_volume < (piece_volume + err_allowed) 
            cut_finish = 1;
        end
        if (first_cut_volume - next_cut_volume) < piece_volume
            next_cut_start = next_cut_start + 1;        
        else                        %此时已经找到切刀位置
%             disp(['切片体积：' num2str(first_cut_volume - next_cut_volume) '立方毫米']);
            cut_volumes = first_cut_volume - next_cut_volume;
            [intersection, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);     %根据第一刀确定切片对角长度
            set_dia_length = dia_length / (1 + dia_err);                    %由于鱿鱼第一片高度低于后几片，因此第一刀的对角线应当设定对角线的上限
%             disp(['此片对角线长度（设定对角长度）' num2str(set_dia_length) '毫米']);
%             disp(['第二刀角度：' num2str(cut_angle/pi*180) '°']);
            break;
        end
    end
    cuts = [cuts next_cut_start];
    cut_angles = [cut_angles cut_angle];

    pre_cut_volume = next_cut_volume;
    pre_cut_start = next_cut_start;

    %% 根据前两刀确定之后的切刀位置和角度
% 
    while(1)   
        next_cut_start = pre_cut_start + cut_gap;          %预判下一刀的落刀位置，初始认为是60，此后依次以最新情况迭代
      
        %查找固定对角线的下刀位置
        while(1)
            [intersection, dia_len] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
            if dia_len < set_dia_length * (1 - dia_err)
                next_cut_start = next_cut_start + 1;
            elseif dia_len > set_dia_length * (1 + dia_err)
                next_cut_start = next_cut_start - 1;
            else
                break;
            end
        end

        %根据质量要求调整角度
        while(1)
            next_cut = generate_cut(next_cut_start, cut_angle, row, col, y_resolution, z_scale);                   
            next_cut_volume = cal_volume(next_cut, next_cut_start, cal_points, row, col,  x_resolution, y_resolution, z_scale);
            if next_cut_volume < (piece_volume + err_allowed) 
                cut_finish = 1;
            end
            if (pre_cut_volume - next_cut_volume) < (piece_volume - err_allowed) 
                cut_angle = cut_angle + pi/180 * angle_factor;
                intersection = intersection + dia_factor;
                if cut_angle >= pi/2
%                     disp(['切片体积：' num2str(pre_cut_volume - next_cut_volume) '立方毫米']);
                    cut_volumes = [cut_volumes (pre_cut_volume - next_cut_volume)];
                    [intersection, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
%                     disp(['此片对角线长度' num2str(dia_length) '毫米']);
                    break;
                end
                next_cut_start = find_cut_byinter(fix(intersection), cut_angle, points_profile, y_resolution, z_scale);
            elseif (piece_volume + err_allowed) < (pre_cut_volume - next_cut_volume)
                cut_angle = cut_angle - pi/180 * angle_factor;
                intersection = intersection - pi/180 * dia_factor;
                if cut_angle <= pi/12
%                     disp(['切片体积：' num2str(pre_cut_volume - next_cut_volume) '立方毫米']);
                    cut_volumes = [cut_volumes (pre_cut_volume - next_cut_volume)];
                    [interseciton, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
%                     disp(['此片对角线长度' num2str(dia_length) '毫米']);
                    break;
                end
                next_cut_start = find_cut_byinter(fix(intersection), cut_angle, points_profile, y_resolution, z_scale);          
            else                        %此时已经找到切刀位置
%                 disp(['切片体积：' num2str(pre_cut_volume - next_cut_volume) '立方毫米']);
                cut_volumes = [cut_volumes (pre_cut_volume - next_cut_volume)];
                [intersection, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
%                 disp(['此片对角线长度' num2str(dia_length) '毫米']);
%                 disp(['切片角度：' num2str(cut_angle/pi*180) '°']);
                break;
            end
        end

        cut_gap = next_cut_start - pre_cut_start;
        cuts = [cuts next_cut_start];
        cut_angles = [cut_angles cut_angle];

        if cut_finish
%             disp(['终止时最后一片余料体积：' num2str(next_cut_volume) '立方毫米']);
%             disp(['尾部全部余料体积：' num2str(next_cut_volume+tail_volume) '立方毫米']);
            break;
        end

        pre_cut_start = next_cut_start;
        pre_cut_volume = next_cut_volume;
    end
    
%根据角度变化情况选择代价函数
%     cut_divergence = cut_angles - [cut_angles(2:end) cut_angles(1)];
%     cost = sum(cut_divergence(1:end-1).^2);    %两刀差的二次代价函数

%根据切割均值情况选择代价函数
    cost = abs(mean(cut_volumes) - piece_volume);
    
    if cost < min_cost 
        min_cost = cost;
        final_cuts = cuts;
        final_cut_angles = cut_angles;
        final_cut_volumes = cut_volumes;
    end
end

%绘制可视化结果
figure;
mesh(points);
hold on
for cut_index = 1:length(final_cuts)
    cut = zeros(row, col) * nan;
    for i = 1:row
        if i >= final_cuts(cut_index)
            cut(i, :) = (i - final_cuts(cut_index)) * y_resolution * tan(final_cut_angles(cut_index)) * z_scale;
        end
        if i > final_cuts(cut_index) + 100
             break;
        end
    end
    mesh(cut);
end
     
        