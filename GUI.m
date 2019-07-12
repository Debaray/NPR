function varargout = GUI(varargin)
% GUI MATLAB code for GUI.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI

% Last Modified by GUIDE v2.5 11-Apr-2019 01:35:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI (see VARARGIN)

% Choose default command line output for GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
global I;
[imname,impath]=uigetfile({'*.jpg;*.png'});
I=imread([impath,'/',imname]);
imshow(I);title('Original image');
Iresize = imresize(I, [480 NaN]);%resize image
axes(handles.axes1);imshow(Iresize);title('Original resized image');
%Pre-Processing
Igray = rgb2gray(Iresize);%rbgtogray
axes(handles.axes3);imshow(Igray);title('rgbtogray image');
Ifilter = medianFilter(Igray);%apply median filter
axes(handles.axes4);imshow(Ifilter);title('median filtered image');
Iadhisto = adapthisteq(Ifilter);%apply Adaptive Histogram Equalization for contrast enhanchment
axes(handles.axes5);imshow(Iadhisto);title('Adaptive Histogram Image');
%Image Binarization
Ibinary = imbinarize(Iadhisto);
%axes(handles.axes7);imshow(Ibinary);title('Binary Image');
%Edge Detection by Sobel Operator:
im = edge(Igray, 'sobel');
axes(handles.axes6);imshow(im);title('Edge detection by sobel');

%Candidate Plate Area detection by Morphological Opening and Closing Operations:
se = strel('diamond',2);%structural element
imd = imdilate(im,se);
axes(handles.axes7);imshow(imd);title('Morphological Dilation Operation');
imf = imfill(imd,'holes');
axes(handles.axes8);imshow(imf);title('After filling holes');
ime = imerode(imf, strel('diamond', 10));
axes(handles.axes9);imshow(ime);title('Morphological Erotion Operation');
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
axes(handles.axes10);imshow(img);title('Actual Number Plate Area Extraction');
%Extracted Plate Region Enhancement
imc = imcrop(Ibinary, boundingBox);
img_re = imresize(imc, [240 NaN]);
%Enhanced Plate Region
s_d = strel('diamond',2); 
d1 = imdilate(img_re, s_d);
e1 = imerode(d1, s_d);
op1 = imopen(e1, s_d);
cl1 = imclose(op1, s_d);
target1 = imcomplement(cl1);
target1 = bwareaopen(target1, 650);%remove object that contains less than 700 pixels
axes(handles.axes11);imshow(target1);title('Enhanced Plate Region');
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
       %figure; imshow(Charprops(i).Image);
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
%fprintf(fileID,'\nTotal Number of Character = %d',countChar);
fclose(fileID);

fid = fopen('character.txt','r');
tline = fscanf(fid,'%s');
fclose(fid);
set(handles.outputText,'String',tline);
