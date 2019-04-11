function [ cut_byinter ] = find_cut_byinter(intersection, cut_angle, profile, y_resolution, z_scale)
%根据交点获取落刀位置
%   此处显示详细说
length = fix(profile(intersection) / z_scale / tan(cut_angle) / y_resolution);
cut_byinter = intersection - length;
end

