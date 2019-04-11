function cut_surface = generate_cut(cut_begin, cut_angel, row, col, y_resolution, z_scale)
%产生切面函数 cut_begin为切刀与传送带底面接触位置


cut_surface = zeros(row, col);      %产生表面
for i = 1:row
        if i >= cut_begin
            cut_surface(i, :) = (i-cut_begin) * y_resolution * tan(cut_angel) * z_scale;
        end
%         if i > cut_begin + 50
%             break;
%         end
end

end

