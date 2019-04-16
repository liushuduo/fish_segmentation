close all;
clear all;
points = csvread('scan_fish1.csv');
[row, col] = size(points);

mess_factor = 0.02;     %Ƭ�����������ӣ���ֵΪ�����Ŀ�����ȡֵԽС����������Խ��ȷ
angle_factor = 0.5;       %�ǵ������ӣ�ȡֵ0��1��ֵԽС�Ƕȱ仯ԽС����󲽽������Ƕ�1�㣬ȡ0ʱ�������Խ���
dia_factor = 3;         %�Խǵ������ӣ�ȡֵ0��1��ֵԽС�Խ��߱仯ԽС����󲽽�����0.5mm��ȡ0ʱ�������Ƕ�

total_volume = 0;
piece_volume = 100000; %�趨��Ƭ���Ϊ40000��������
err_allowed = piece_volume * mess_factor; %��Ƭ��Ƭ�������
dia_err = 0.05;
cut_begin = 100;        %������λ��
cut_angle = pi / 4;     %�е��Ƕ�

x_resolution = 0.3;
y_resolution = 0.5;
z_scale = 100;  

for i = 1:row
    for j = 1:col
        if points(i, j) == -32768
            points(i, j) = 0;
        else 
            points(i, j) = points(i, j) * 0.72 + 4392;      %���ƫ�ã���λΪ�ٷ�֮һ����
            total_volume = total_volume + points(i, j) / z_scale * y_resolution * x_resolution;
        end
    end
end

% figure;
% mesh(points);
disp(['����������Ϊ��' num2str(total_volume) '��������']);



%��ֵ�˲�
points = medfilt2(points);
fil_total_volume = 0;       %�����˲����������
for i = 1:row
    for j = 1:col
        fil_total_volume = fil_total_volume + points(i, j) / z_scale * y_resolution * x_resolution;
    end
end
disp(['�����˲�����������Ϊ��' num2str(fil_total_volume) '��������']);

%% ��ʼƫ��
for i = 1:row           %�ҵ���ʼƫ��
    row_length = sum(points(i, :)~=0);
    if row_length > 10
        points = points(i:end, :);
        break;
    end
end
[row, col] = size(points);

%% ��ȡ����������Ϣ
%��ȡ����������������������Ϊ��������
points_profile = points(:, sum(points) == max(sum(points)));
profile_col = 1:row;
figure;
plot(profile_col, points_profile);

max_width = max(sum(points~=0, 2));   %���������

%����β�ϲ�����ʼλ�ã���β�˿��С������ȵİٷ�֮��ʮΪ��׼
for i = row:-1:1
    row_length = sum(points(i, :) ~= 0);
    if row_length > max_width * 0.8
        fish_end = i;
        break;
    end
end

cal_points = points;
cal_points(fish_end:row, :) = 0; 

tail_volume = 0;    %β�����
for i = fish_end:row
    for j = 1:col
        tail_volume = tail_volume + points(i, j) / z_scale * y_resolution * x_resolution;
    end
end

% figure;
% mesh(cal_points)

min_cost = 10000;           %�趨��ʼ����С���ۣ���һ��
for begin_cut_angle = pi/6 : pi/90: pi/3
%���ܹ���ͷ�������Ϊ��׼��ȷ����һ�����䵶λ��
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
    
%% �е�һ��
    first_cut_volume = cal_volume(cut, cut_start, cal_points, row, col, x_resolution, y_resolution, z_scale);
%     disp(['��һ���������Ϊ��' num2str(fil_total_volume-first_cut_volume-tail_volume) '��������']);
%     disp(['��һ���Ƕȣ�' num2str(cut_angle/pi*180) '��']);

    %% �е���ʼ��ʼ��
    cuts = cut_start;                                  %���ڴ洢�е��䵶λ��
    cut_angles = cut_angle;                            %�洢�䵶�Ƕ�
    cut_volumes = [];                                  %�洢��Ƭ���
    cut_gap = 0;
    logical cut_finish;
    cut_finish = 0;
    first_cut_start = cut_start;

    %%  ���ȸ���ǰ����ȷ���Խǳ���
    next_cut_start = first_cut_start;
    while(1)
        next_cut = generate_cut(next_cut_start, cut_angle, row, col, y_resolution, z_scale);                   
        next_cut_volume = cal_volume(next_cut, next_cut_start, cal_points, row, col,  x_resolution, y_resolution, z_scale);
        if next_cut_volume < (piece_volume + err_allowed) 
            cut_finish = 1;
        end
        if (first_cut_volume - next_cut_volume) < piece_volume
            next_cut_start = next_cut_start + 1;        
        else                        %��ʱ�Ѿ��ҵ��е�λ��
%             disp(['��Ƭ�����' num2str(first_cut_volume - next_cut_volume) '��������']);
            cut_volumes = first_cut_volume - next_cut_volume;
            [intersection, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);     %���ݵ�һ��ȷ����Ƭ�Խǳ���
            set_dia_length = dia_length / (1 + dia_err);                    %���������һƬ�߶ȵ��ں�Ƭ����˵�һ���ĶԽ���Ӧ���趨�Խ��ߵ�����
%             disp(['��Ƭ�Խ��߳��ȣ��趨�Խǳ��ȣ�' num2str(set_dia_length) '����']);
%             disp(['�ڶ����Ƕȣ�' num2str(cut_angle/pi*180) '��']);
            break;
        end
    end
    cuts = [cuts next_cut_start];
    cut_angles = [cut_angles cut_angle];

    pre_cut_volume = next_cut_volume;
    pre_cut_start = next_cut_start;

    %% ����ǰ����ȷ��֮����е�λ�úͽǶ�
% 
    while(1)   
        next_cut_start = pre_cut_start + cut_gap;          %Ԥ����һ�����䵶λ�ã���ʼ��Ϊ��60���˺������������������
      
        %���ҹ̶��Խ��ߵ��µ�λ��
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

        %��������Ҫ������Ƕ�
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
%                     disp(['��Ƭ�����' num2str(pre_cut_volume - next_cut_volume) '��������']);
                    cut_volumes = [cut_volumes (pre_cut_volume - next_cut_volume)];
                    [intersection, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
%                     disp(['��Ƭ�Խ��߳���' num2str(dia_length) '����']);
                    break;
                end
                next_cut_start = find_cut_byinter(fix(intersection), cut_angle, points_profile, y_resolution, z_scale);
            elseif (piece_volume + err_allowed) < (pre_cut_volume - next_cut_volume)
                cut_angle = cut_angle - pi/180 * angle_factor;
                intersection = intersection - pi/180 * dia_factor;
                if cut_angle <= pi/12
%                     disp(['��Ƭ�����' num2str(pre_cut_volume - next_cut_volume) '��������']);
                    cut_volumes = [cut_volumes (pre_cut_volume - next_cut_volume)];
                    [interseciton, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
%                     disp(['��Ƭ�Խ��߳���' num2str(dia_length) '����']);
                    break;
                end
                next_cut_start = find_cut_byinter(fix(intersection), cut_angle, points_profile, y_resolution, z_scale);          
            else                        %��ʱ�Ѿ��ҵ��е�λ��
%                 disp(['��Ƭ�����' num2str(pre_cut_volume - next_cut_volume) '��������']);
                cut_volumes = [cut_volumes (pre_cut_volume - next_cut_volume)];
                [intersection, dia_length] = cal_dia(cuts(end), next_cut_start, cut_angle, y_resolution, z_scale, points_profile, row);
%                 disp(['��Ƭ�Խ��߳���' num2str(dia_length) '����']);
%                 disp(['��Ƭ�Ƕȣ�' num2str(cut_angle/pi*180) '��']);
                break;
            end
        end

        cut_gap = next_cut_start - pre_cut_start;
        cuts = [cuts next_cut_start];
        cut_angles = [cut_angles cut_angle];

        if cut_finish
%             disp(['��ֹʱ���һƬ���������' num2str(next_cut_volume) '��������']);
%             disp(['β��ȫ�����������' num2str(next_cut_volume+tail_volume) '��������']);
            break;
        end

        pre_cut_start = next_cut_start;
        pre_cut_volume = next_cut_volume;
    end
    
%���ݽǶȱ仯���ѡ����ۺ���
%     cut_divergence = cut_angles - [cut_angles(2:end) cut_angles(1)];
%     cost = sum(cut_divergence(1:end-1).^2);    %������Ķ��δ��ۺ���

%�����и��ֵ���ѡ����ۺ���
    cost = abs(mean(cut_volumes) - piece_volume);
    
    if cost < min_cost 
        min_cost = cost;
        final_cuts = cuts;
        final_cut_angles = cut_angles;
        final_cut_volumes = cut_volumes;
    end
end

%���ƿ��ӻ����
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
     
        