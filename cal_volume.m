function cut_volume = cal_volume(cut, cut_start, points, row, col, x_resolution, y_resolution, z_scale)
%计算两个切面之间的鱿鱼体积
%   pre_start为前一刀落刀处，cur_cut为后一刀落刀处

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

