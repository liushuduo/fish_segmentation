function cut_volume = cal_volume(cut, cut_start, points, row, col, x_resolution, y_resolution, z_scale)
%������������֮����������
%   pre_startΪǰһ���䵶����cur_cutΪ��һ���䵶��

cut_volume = 0;
for j = 1:col
    for i = cut_start:row
        if  cut(i, j) < points(i, j)
            cut_volume = cut_volume + cut(i, j) * y_resolution * x_resolution /z_scale;
        else 
            cut_volume = cut_volume + points(i, j) * y_resolution * x_resolution /z_scale;
        end
    end
end

end

