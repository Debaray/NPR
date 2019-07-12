%Image Acquisition
I = imread('img/car.jpg');
Iresize = imresize(I, [480 NaN]);%resize image
figure;
subplot(221);imshow(Iresize);title('resized image');
%Pre-Processing
Igray = rgb2gray(Iresize);%rbgtogray
subplot(222);imshow(Igray);title('rgbtogray image');
Ifilter = medianFilter(Igray);%apply median filter
subplot(223);imshow(Ifilter);title('median filtered image');
Iadhisto = adapthisteq(Ifilter);%apply Adaptive Histogram Equalization for contrast enhanchment
subplot(224);imshow(Iadhisto);title('Adaptive Histogram Image');
%Image Binarization
Ibinary = imbinarize(Iadhisto);
figure;
subplot(221);imshow(Ibinary);title('Binary Image');
%Edge Detection by Sobel Operator:
im = edge(Igray, 'sobel');
subplot(222);imshow(im);title('Edge detection by sobel');

%Candidate Plate Area detection by Morphological Opening and Closing Operations:
se = strel('diamond',2);%structural element
imd = imdilate(im,se);
subplot(223);imshow(imd);title('Morphological Dilation Operation');
imf = imfill(imd,'holes');
subplot(224);imshow(imf);title('After filling holes');
ime = imerode(imf, strel('diamond', 10));
figure;
subplot(221);imshow(ime);title('Morphological Erotion Operation');
%Actual Number Plate Area Extraction
Iprops=regionprops(ime,'BoundingBox','Area', 'Image');%image region
area = Iprops.Area;%take image region area
count = numel(Iprops);%count the number of element in Iprops
maxarea= area;%initialize area
boundingBox = Iprops.BoundingBox;%extract bounding box
for i = 1:count
    if(maxarea < Iprops(i).Area)
        maxarea = Iprops(i).Area;
        boundingBox = Iprops(i).BoundingBox;
    end
end
img = imcrop(Igray, boundingBox);
subplot(222);imshow(img);title('Actual Number Plate Area Extraction');
%Extracted Plate Region Enhancement
imc = imcrop(Ibinary, boundingBox);
img_re = imresize(imc, [240 NaN]);
subplot(221);imshow(img_re);title('resized binary croped image');
%Enhanced Plate Region
s_d = strel('diamond',2); 
d1 = imdilate(img_re, s_d);
e1 = imerode(d1, s_d);
op1 = imopen(e1, s_d);
cl1 = imclose(op1, s_d);
target1 = imcomplement(cl1);
target1 = bwareaopen(target1, 650);%remove object that contains less than 700 pixels
subplot(223);imshow(target1);title('Enhanced Plate Region');
%Character Segmentation:
 [h, w] = size(target1);
Charprops=regionprops(target1,'BoundingBox','Area', 'Image');
count = numel(Charprops);

noPlate=[]; % Initializing the variable of number plate string.

for i=1:count
   ow = length(Charprops(i).Image(1,:));
   oh = length(Charprops(i).Image(:,1));
   if ow<(h/2) && oh>(h/3)
       letter=readLetter(Charprops(i).Image); % Reading the letter corresponding the binary image 'N'.
       figure; imshow(Charprops(i).Image);
       noPlate=[noPlate letter]; % Appending every subsequent character in noPlate variable.
   end
end
countChar = 0;
for i = 1: length(noPlate)
    countChar = countChar+1;
end

%Character Recognition
fileID=fopen('character.txt','wt');
fprintf(fileID,'%s\n',noPlate);
fprintf(fileID,'\nTotal Number of Character = %d',countChar);
fclose(fileID);
