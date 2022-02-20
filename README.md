# Making_EIT_Data_with_EIDORS

※ _This project is licensed under the terms of the MIT license._ ※

Language : Matlab

Before running this code, you have to run specific EIDORS version so that 2D GREIT works.

So, if you want to run it, please [_DOWNLOAD the EIDORS HERE_](https://drive.google.com/file/d/13vq98D0IIuffYSmG_e6PpMnI3igh6yud/view?usp=sharing).

This repo is under construction.

# Tips for Making New Thorax Shape in EIDORS

1. Find appropriate axial lung CT image.

2. Load image with x-axis as linspace(-1,1,num of width pixel) and y-axsis as linspace(reduced ratio,reduced ratio,num of height pixel).

    Ex) If the size of image is 1000×500, then set x-axis as linspace(-1,1,1000) and y-axis as linspace(-0.5,0.5,500).
  
3. Point the thorax boundary. Recommended number of boundary points is 40±5.

4. Point the both lung boundary. Recommended number of single lung points is 20±3.

5. Save points as (x1 y1; x2 y2; ...), and make a structure includes boundary, both lungs points.

6. Go to EIDORS → models → shape_library.mat, and save the structure in shape_library.mat.

7. Load!

  This is the simple example of making user defined shape and load it on code. 
  
    After finished picking points, let's make a structure name __adult__.
  
    Then save thorax boundary points as __adult.boundary__,
      
    right lung points as __adult.right_lung__,
      
    and left lung points as __adult.left_lung__.
      
    Save structure __adult__ in __shape_library.mat__ which exists in the path written above.
    
    Use __shape_library__ function to call your __adult__ file like below;
      
    thorax = shape_library('get','adult','boundary');
    rlung  = shape_library('get','adult','right_lung');
    llung  = shape_library('get','adult','left_lung');
    
If you called your defined shape but it doesn't work, change the shape in function __ng_mk_extruded_model__.
    
When you change smoothing points or small maxh in shape, then it'll work.

    shape = { 0,                % height
        {thorax, rlung, llung}, % contours
        [4,50],                 % perform smoothing with 50 points    ← Change here!
        0.04};                  % small maxh (fine mesh)              ← Change here!
    
    elec_pos = [ 16,            % number of elecs per plane
        1,                      % equidistant spacing
        0]';                    % a single z-plane
    
    elec_shape = [0.05,         % radius
        0,                      % circular electrode
        0.01 ]';                % maxh (electrode refinement)
    
    fmdl = ng_mk_extruded_model(shape, elec_pos, elec_shape);
