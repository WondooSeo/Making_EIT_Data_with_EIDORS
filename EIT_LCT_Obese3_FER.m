function EIT_LCT_Obese3_FER()
%% Make folder and set filePath
    if ~exist('.\EIT_LCT_Obese3_FER','dir')
        mkdir('.\EIT_LCT_Obese3_FER');
    end
    EIT_FER_Filepath = '.\EIT_LCT_Obese3_FER';

    if ~exist('.\EIT_LCT_Obese3_FER_Voltage','dir')
        mkdir('.\EIT_LCT_Obese3_FER_Voltage');
    end
    EIT_V_Filepath = '.\EIT_LCT_Obese3_FER_Voltage';

    if ~exist('.\EIT_LCT_Obese3_FER_CP','dir')
        mkdir('.\EIT_LCT_Obese3_FER_CP');
    end
    EIT_CP_Filepath = '.\EIT_LCT_Obese3_FER_CP';

%% Get Contours
    thorax = shape_library('get','lct_obese3','boundary');
    rlung  = shape_library('get','lct_obese3','right_lung');
    llung  = shape_library('get','lct_obese3','left_lung');
    % one could also run:
    % shape_library('get','adult_male');
    % to get all the info at once in a struct
    
    % show the library image
    % figure; shape_library('show','adult_male');
    % print_convert thoraxmdl01a.jpg '-density 100'
    
    shape = { 0,                % height
        {thorax, rlung, llung}, % contours
        [4,40],                 % perform smoothing with 50 points
        0.04};                  % small maxh (fine mesh)
    
    elec_pos = [ 16,            % number of elecs per plane
        1,                      % equidistant spacing
        0]';                    % a single z-plane
    
    elec_shape = [0.05,         % radius
        0,                      % circular electrode
        0.01 ]';                % maxh (electrode refinement)
    
    fmdl = ng_mk_extruded_model(shape, elec_pos, elec_shape);
    % this similar model is also available as:
    % fmdl = mk_library_model('adult_male_16el_lungs');
    % show_fem(fmdl,[0 1]);
    fmdl.nodes(:,1) = fmdl.nodes(:,1) - 0.5*(max(fmdl.nodes(:,1)) + min(fmdl.nodes(:,1)));
    fmdl.nodes(:,2) = fmdl.nodes(:,2) - 0.5*(max(fmdl.nodes(:,2)) + min(fmdl.nodes(:,2)));
    % figure; show_fem(fmdl); axis tight off
    
    [fmdl.stimulation,fmdl.meas_sel] = mk_stim_patterns(16,1,[0,1],[0,1],{'no_meas_current'}, 5);
    
    img = mk_image(fmdl,1);
    vh = fwd_solve(img);
    vRef = vh.meas;
    
    numElement = length(img.fwd_model.elems);
    element = img.fwd_model.elems;
    node = img.fwd_model.nodes;
    
    % -- Save img at compareImg to calculate S
    SImg = img;
    
    % -- Set lung conductivity
    img.elem_data(fmdl.mat_idx{1}) = 1;
    lungElem = [fmdl.mat_idx{2}; fmdl.mat_idx{3}]; % 2 : Right, 3 : Left
    
    sigmaLen = 1000;
    sigmaX = linspace(0,4*pi,sigmaLen);
    amp = linspace(1,1.3,sigmaLen);
    sigma = 0.1*amp.*sin(sigmaX)+0.25;
    
    S = calc_jacobian(SImg);
    S_normal = zeros(size(S));
    for kk = 1:size(S,2)
        S_normal(:,kk) = S(:,kk)/norm(S(:,kk));
    end
    W = diag(1./sum(abs(S'*S_normal)));
    reconSolver = W*S_normal';

    %% Detect Motion Artifact & Calculate VErr
    boundaryNode = unique(img.fwd_model.boundary(:));
    element = img.fwd_model.elems;
    node = img.fwd_model.nodes;
    boundaryLambda = 1e-10;

    boundaryElement = [];
    for iter = 1:length(element)
        for innerIter = 1:length(boundaryNode)
            if element(iter,1) == boundaryNode(innerIter) || element(iter,2) ...
                    == boundaryNode(innerIter) || element(iter,3) == boundaryNode(innerIter)
                boundaryElement = [boundaryElement; iter];
            end
        end
    end

    boundaryElement = sort(unique(boundaryElement));
    numboundaryElement = length(boundaryElement);

    % Pick S columnn and subtract artifact
    realIndexLength = length(vRef);
    boundaryS = zeros(realIndexLength, numboundaryElement);
    % for iter = 1:numboundaryElement
    %     boundaryS(:,iter) = S(:,boundaryElement(iter));
    % end
    boundaryS = S(:,boundaryElement);
    % innerTerm = (boundaryS'*boundaryS + boundaryLambda*eye(numboundaryElement))\boundaryS';
    % innerTerm = boundaryS * innerTerm;
    innerTerm = eye(size(S,1)) - ((boundaryS*boundaryS'+boundaryLambda*eye(size(S,1)))\(boundaryS*boundaryS'));

%% Change triangle mesh to grid mesh
    for i = 1:size(element,1)
        xy(i,:) = mean(node(element(i,1:3),:));
    end

    nPixel = 128;
    margin_FOV = 1.05;
    meshsize = max(max(abs(node)))*margin_FOV;
    ti = -meshsize:(2*meshsize)/(nPixel-1):meshsize;
    [qx,qy] = meshgrid(ti,ti);

    % -- No use area
    % This is for training data
    % img.elem_data(lungElem) = sigma(1);
    % This is for showing data
    % img.elem_data(lungElem) = sigma(350);
    % vkRef = fwd_solve(img);
    % vCRef = vkRef.meas;

    % bodyShpae128 : makes outer body pixels zero (Need for post processing)
    bodyShape = zeros(numElement,1);
    bodyShape(boundaryElement) = 0.7;
    bodyShape128 = scatteredInterpolant(xy(:,1),xy(:,2),bodyShape);
    bodyShape128 = flipud(bodyShape128(qx,qy));
    bodyShape128(find(bodyShape128>0)) = 1;
    bodyShape128 = imcomplement(bodyShape128);

%% Change the collapse area
    for collapseCase = 19:19%19:19
        tempImg = SImg;
        switch collapseCase
    
            % Do nothing, which is normal lung
            case 1            
                targetLungElem = lungElem;
                collapseP = 0;
            
            % Right lung collapse 5%
            case 2
                collapseArea = inline('((x+0.34)/0.32).^2 + ((y+0.46)/0.16).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Right lung collapse 10%
            case 3
                collapseArea = inline('((x+0.31)/0.32).^2 + ((y+0.39)/0.16).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Right lung collapse 15%
            case 4
                collapseArea = inline('((x+0.31)/0.32).^2 + ((y+0.33)/0.16).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
            
            % Right lung collapse 20%
            case 5
                collapseArea = inline('((x+0.31)/0.32).^2 + ((y+0.3)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);    
            
            % Right lung collapse 25%
            case 6
                collapseArea = inline('((x+0.31)/0.35).^2 + ((y+0.27)/0.24).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Left lung collapse 5%
            case 7
                collapseArea = inline('((x-0.34)/0.32).^2 + ((y+0.445)/0.16).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP); 
    
            % Left lung collapse 10%
            case 8
                collapseArea = inline('((x-0.34)/0.32).^2 + ((y+0.38)/0.16).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Left lung collapse 15%
            case 9
                collapseArea = inline('((x-0.4)/0.32).^2 + ((y+0.29)/0.16).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Left lung collapse 20%
            case 10
                collapseArea = inline('((x-0.4)/0.32).^2 + ((y+0.26)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Left lung collapse 25%
            case 11
                collapseArea = inline('((x-0.44)/0.34).^2 + ((y+0.205)/0.23).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Both lung collapse 5%
            case 12
                collapseArea = inline('(x/0.8).^2 + ((y+0.53)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Both lung collapse 10%
            case 13
                collapseArea = inline('(x/0.8).^2 + ((y+0.49)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);   
    
            % Both lung collapse 15%
            case 14
                collapseArea = inline('(x/0.8).^2 + ((y+0.455)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
            
            % Both lung collapse 20%
            case 15
                collapseArea = inline('(x/0.8).^2 + ((y+0.42)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            % Both lung collapse 25%
            case 16
                collapseArea = inline('(x/0.8).^2 + ((y+0.385)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);

            % Both lung collapse 30%
            case 17
                collapseArea = inline('(x/0.8).^2 + ((y+0.347)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);

            % Both lung collapse 35%
            case 18
                collapseArea = inline('(x/0.8).^2 + ((y+0.31)/0.2).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);

            % Both lung collapse 40%
            case 19
                collapseArea = inline('(x/0.8).^2 + ((y+0.288)/0.22).^2 < 1','x','y','z');
                [row, ~] = find(elem_select(tempImg.fwd_model, collapseArea));
                targetLungElem = setdiff(lungElem,row);
                collapseP = 1 - length(targetLungElem) / length(lungElem);
                disp(collapseP);
    
            otherwise
                error('Wrong collapseCase!')
        end

        RLungCollapseElem = intersect(fmdl.mat_idx{2},targetLungElem);
        LLungCollapseElem = intersect(fmdl.mat_idx{3},targetLungElem);
        RCollapseP = 1 - length(RLungCollapseElem) / length(fmdl.mat_idx{2});
        LCollapseP = 1 - length(LLungCollapseElem) / length(fmdl.mat_idx{3});
        disp([RCollapseP, LCollapseP])
        
%% Run FER and save EIT data during sine TV wave
        for iter = 1:sigmaLen
            tempImg.elem_data(targetLungElem) = sigma(iter);
    
            if iter == 1
                saveFig = figure; show_fem(tempImg); axis tight off % → Ok
                saveas(saveFig, ['LCT Obese3 Collapse shape (Collapse case ' num2str(collapseCase) ').bmp'])
                close(saveFig);
                % break; % For save fem model image
            end
    
            vk = fwd_solve(tempImg);
            vCase = vk.meas;
    
            % V = vCRef - vCase;
            V = vRef - vCase;
            % vErr = innerTerm*V;
            % V = V - vErr; % -- CAUTION !!!
            reconResult = reconSolver*innerTerm*V;
    
            % -- Change image into 128*128
            F = scatteredInterpolant(xy(:,1),xy(:,2),reconResult);
            % Need to change the constant for each cases
            gridReconResult = flipud(F(qx,qy)) .* 3;
            gridReconResult(gridReconResult<0) = 0;
            % This makes outer body pixel zero (post processing)
            gridReconResult = gridReconResult .* bodyShape128;
            figure; imagesc(gridReconResult); axis square tight off % Check
    
            % Save 128*128 image & voltage data for training
            imgPath = [EIT_FER_Filepath '\EIT_LCT_Obese3_FER_collapse_case_' num2str(collapseCase) '_' num2str(iter) '.png'];
            imwrite(gridReconResult,imgPath,'PNG'); close;
            VPath = [EIT_V_Filepath '\EIT_LCT_Obese3_FER_Voltage_collapse_case_' num2str(collapseCase) '_' num2str(iter) '.csv'];
            writematrix(V',VPath);
            CPPath = [EIT_CP_Filepath '\EIT_LCT_Obese3_FER_CP_collapse_case_' num2str(collapseCase) '_' num2str(iter) '.csv'];
            writematrix([RCollapseP, LCollapseP],CPPath);
            disp(['LCT Obese3 FER Case ' num2str(collapseCase) ' → ' num2str(iter) ' / ' num2str(sigmaLen) ' Finished ...']);
        end
    end
end




