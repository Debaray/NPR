function [imout1] = medianFilter(inputImage)
image_double = im2double(inputImage);
[rows,cols] = size(image_double);
imout1 = uint8(zeros(rows,cols));

for i = 1:rows
    if i + 2 <= rows
        for j =1:cols
            if j+2 <= cols
                M = inputImage(i:i+2,j:j+2);
                newM = sort(M);
                inputImage(i+1,j+1) = newM(2,2);
            end
        end
    end

end
for i=1:rows
    for j=1:cols
        imout1(i,j) = inputImage(i,j);
    end
end

