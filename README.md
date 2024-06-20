***※ This project is licensed under the terms of the MIT license. ※***

# Making EIT Data with EIDORS

The goal of this project is to **make custom-made FEM images with MATLAB and EIDORS**.

## What you need to run this codes

Language : Matlab R2021b

> Upper version might be okay, but I warn you not to use the lower version.

Package : [EIDORS](http://eidors3d.sourceforge.net/)

Add-on : Statistics and Machine Learning Toolbox / Simulink / Partial Differential Equation Toolbox / Image Processing Toolbox / Computer Vision Toolbox

> I wrote what I installed when running this project, so please keep in mind that there may be useless add-ons.

## Preparation

Before running this code, you have to run specific EIDORS version so that 2D GREIT works. I have no idea which version works 2D GREIT, but **Netgen v5.0.0 is necessary.**

So, if you want to run it without any hesitation, please [___DOWNLOAD my personal EIDORS 7z file HERE___](https://drive.google.com/file/d/13vq98D0IIuffYSmG_e6PpMnI3igh6yud/view?usp=sharing)(Link moves to my personal Google drive). This version works perfectly on this file. If you encountered setting Netgen bin file path after running code, please write **Netgen v5.0.0 bin folder path**, not v.5.3 folder path.

> Definitely, ***NO virus in my personal 7z file!*** I strongly bet. And I have no idea why there is v.5.3 folder in 7z file, so ignore it please.

But if you have EIDORS with 2D GREIT runnable version, just download shape_library.mat I uploaded above and paste it.

In this shape_library.mat, I added some pointed models(lct_normal1-6, lct_obese1-3). **So if you want to run above .m files, you MUST overwrite "shape_library.mat" I uploaded.**

> I can't remember what lct stands for is. LOL

<!-- Result of the EIT_Run.m : Click [_HERE_](https://drive.google.com/file/d/1v4pvYWG3csWPQuZWVLxhNOmpaHonYyCy/view?usp=sharing) (Move to my personal Google drive, there're no results of Normal 4-6 and Obese 2) -->

***Also, I'm not sure that all of .m files saves same result value because of research. So you have to modify end of codes (save part) if you have to.***

## Results

When you run this codes, they will make the result of EIT images with artificially carved lung elements and the original one. I carved elements of left / right / both lungs with appropriate ratio. You can manage how much elements are carved by manipulating _collapseArea_ inline equation.

I made codes using two methods; FER and GREIT, which has different pros and cons for each method. Or you can use the third method you want by modifying codes yourself.

In my [CAENR project](https://github.com/WondooSeo/Convolutional_AutoEncoder_Neural_Regression), I used these generated EIT images as train / test datasets. You can see the samples on the ***Model architecture*** paragraph image.

> I used GREIT methods on my CAENR project, which result was better than FER method and comfortable to use.

## Tips for Making New Thorax Shape in EIDORS

1. Find appropriate axial lung CT image.
2. Load image with x-axis as linspace(-1, 1, num of width pixel) and y-axsis as linspace(reduced/increased ratio, reduced/increased ratio, num of height pixel).

   _If the size of image is 1000×500, then set x-axis as linspace(-1, 1, 1000) and y-axis as linspace(-0.5, 0.5, 500)._
       
3. Point the thorax boundary. Recommended number of boundary points is 40 ± 5.
4. Point the both lung boundary. Recommended number of single lung points is 20 ± 3.
5. Save points as [ x1 y1; x2 y2; ... ], then make a structure includes thorax and both lungs boundary points.
6. Go to EIDORS → models → shape_library.mat, and append the structure in shape_library.mat.
7. Load!

<div align = 'center'>
       
   ![Pointing](https://user-images.githubusercontent.com/62936579/155882613-af804fc3-5a1f-421d-b775-83e7ba6e0384.png)

   [Fig. 1] How to pointing lung on the CT image
       
</div>

  This is the simple example of making user defined shape and load it on code. 
  
    After finished picking points, let's make a structure name as adult.
  
    Then save thorax boundary points as adult.boundary,
    right lung points as adult.right_lung,
    and left lung points as adult.left_lung.
    
    Save structure adult in shape_library.mat which exists in the path written above.
    
    If you don't have any idea how to save the points, then see any structures in shape_library.mat.
    
    Use shape_library function to call your adult shape like below;
      
    thorax = shape_library('get','adult','boundary');
    rlung  = shape_library('get','adult','right_lung');
    llung  = shape_library('get','adult','left_lung');
    
If you called your defined shape but it doesn't work, change the shape in function __ng_mk_extruded_model__.
    
When you change smoothing points higher than 50, then it'll work. But be aware; choose just appropriate number. **Using large number on smoothing points loads a lot of burden to your computer resources.**

    shape = { 0,                % height
        {thorax, rlung, llung}, % contours
        [4,50],                 % perform smoothing with 50 points    ← Change here!
        0.04};                  % small maxh (fine mesh)              
    
    elec_pos = [ 16,            % number of elecs per plane
        1,                      % equidistant spacing
        0]';                    % a single z-plane
    
    elec_shape = [0.05,         % radius
        0,                      % circular electrode
        0.01 ]';                % maxh (electrode refinement)
    
    fmdl = ng_mk_extruded_model(shape, elec_pos, elec_shape);
    
If you cannot figure it out anyway, please see my code.

<div align = 'center'>

   ![LCT Obese2 Collapse shape (Collapse case 1)](https://user-images.githubusercontent.com/62936579/160920945-ba6b640f-6c1c-4fd6-adf4-f9c002c34bad.png)

   [Fig. 2] FEM result on EIDORS using Fig. 1 image
       
</div>

# Citation

When this codes help your research, I'll be appreciated if you cite this conference paper. This paper is the first announced paper that this custom-made EIT image generation code was used.

 > Won-Doo Seo and Hyeuknam Kwon, "The degree of lung collapse estimation method using convolutional autoencoder and neural regression in electrical impedance tomography," ICBEM-ICEBI-EIT(International Conference on Bioelectromagnetism, Electrical Bioimpedance, and Electrical Impedance Tomography) 2022, Seoul, Republic of Korea, June 29-July 1, 2022.
