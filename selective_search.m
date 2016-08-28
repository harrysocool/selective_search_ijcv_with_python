function all_boxes = selective_search(image_filenames, output_filename)

addpath('Dependencies');

if(~exist('anigauss'))
    mex Dependencies/anigaussm/anigauss_mex.c Dependencies/anigaussm/anigauss.c -output anigauss
end

if(~exist('mexCountWordsIndex'))
    mex Dependencies/mexCountWordsIndex.cpp
end

if(~exist('mexFelzenSegmentIndex'))
    mex Dependencies/FelzenSegment/mexFelzenSegmentIndex.cpp -output mexFelzenSegmentIndex;
end

colorTypes = {'Hsv', 'Lab', 'RGI', 'H', 'Intensity'};
colorType = colorTypes(1:2); % Single color space for demo

% Here you specify which similarity functions to use in merging
simFunctionHandles = {@SSSimColourTextureSizeFillOrig, @SSSimTextureSizeFill, @SSSimBoxFillOrig, @SSSimSize};
simFunctionHandles = simFunctionHandles(1:2); % Two different merging strategies

% Thresholds for the Felzenszwalb and Huttenlocher segmentation algorithm.
% Note that by default, we set minSize = k, and sigma = 0.8.
k = 350; % controls size of segments of initial segmentation.
minSize = k;
sigma = 0.8;

% Process all images.
all_boxes = {};
for i=1:length(image_filenames)
    idx = 1;
    for n = 1:length(colorTypes)
        colorType = colorTypes{n};
        [boxesT{idx} blobIndIm blobBoxes hierarchy priorityT{idx}] = ...
          Image2HierarchicalGrouping(im, sigma, k, minSize, colorType, simFunctionHandles);
        idx = idx + 1;
    end
    boxes = cat(1, boxesT{:}); % Concatenate boxes from all hierarchies
    priority = cat(1, priorityT{:}); % Concatenate priorities

    % Do pseudo random sorting as in paper
    priority = priority .* rand(size(priority));
    [priority sortIds] = sort(priority, 'ascend');
    boxes = boxes(sortIds,:);
    
    boxes = FilterBoxesWidth(boxes, minBoxWidth);
    boxes = BoxRemoveDuplicates(boxes);

    % Adjust boxes to cancel effect of canonical scaling.
    % boxes = (boxes - 1) * scale + 1;

    boxes = FilterBoxesWidth(boxes, minBoxWidth);
 
    correct_bbs = boxes(:,[2,1,4,3]) - 1;
    all_boxes{i} = correct_bbs;
    display(['No.',int2str(i),' pictures processed, ', int2str(size(correct_bbs,1)), ' boxes']);
end

if nargin > 1
    save(output_filename, 'all_boxes', '-v7');
end
