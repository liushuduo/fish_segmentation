function [intersection, dia_length ] = cal_dia(pre_cut, cur_cut, cut_angle, y_resolution, z_scale, profile, row)
%��������֮��ĶԽ��߳���
%   �˴���ʾ��ϸ˵��

for i = cur_cut:row
    height = (i - cur_cut) * y_resolution * tan(cut_angle) * z_scale;   %��ȡ��z�߶�Ϊ��λ�ĸ߶�
    if height >= profile(i)
        intersection = i;
        dia_length = sqrt(((i - pre_cut) * y_resolution)^2 + (profile(i) / 100)^2);     %�Խ��߳�����mmΪ��λ
        break;
    end
end

end

