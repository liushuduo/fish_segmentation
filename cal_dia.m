function [intersection, dia_length ] = cal_dia(pre_cut, cur_cut, cut_angle, y_resolution, z_scale, profile, row)
%计算两刀之间的对角线长度
%   此处显示详细说明

for i = cur_cut:row
    height = (i - cur_cut) * y_resolution * tan(cut_angle) * z_scale;   %获取以z尺度为单位的高度
    if height >= profile(i)
        intersection = i;
        dia_length = sqrt(((i - pre_cut) * y_resolution)^2 + (profile(i) / 100)^2);     %对角线长度以mm为单位
        break;
    end
end

end

