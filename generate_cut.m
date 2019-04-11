function cut_surface = generate_cut(cut_begin, cut_angel, row, col, y_resolution, z_scale)
%�������溯�� cut_beginΪ�е��봫�ʹ�����Ӵ�λ��


cut_surface = zeros(row, col);      %��������
for i = 1:row
        if i >= cut_begin
            cut_surface(i, :) = (i-cut_begin) * y_resolution * tan(cut_angel) * z_scale;
        end
%         if i > cut_begin + 50
%             break;
%         end
end

end

