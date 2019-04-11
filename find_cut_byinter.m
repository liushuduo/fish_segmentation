function [ cut_byinter ] = find_cut_byinter(intersection, cut_angle, profile, y_resolution, z_scale)
%���ݽ����ȡ�䵶λ��
%   �˴���ʾ��ϸ˵
length = fix(profile(intersection) / z_scale / tan(cut_angle) / y_resolution);
cut_byinter = intersection - length;
end

