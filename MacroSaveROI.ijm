/*  MacroSaveROI
 *   This macro extracts one or more ROIs from an image and saves it as filename_<ROIname>.tiff
 *   Developed for QBI
 *   
 *   Steps: 1. Open original image (directly or via Import->Bioformats)
 *          2. Select required image (if multiple channels)
 *          3. Draw ROIs and add to ROI manager (T opens the ROI manager then click Add)
 *          4. Rename ROIs to make clear which selection is which (eg Rhippocampus for right hippocampus) using "Rename" in ROI Manager
 *          5. Run this macro:
 *          	For each ROI, clears around ROI then crops image and saves to a new image with same root filename + ROI name
 *          
 *          
 *   	
 *   Contact: Liz Cooper-Williams, QBI (e.cooperwilliams@uq.edu.au)
 *   
 *   (c)Copyright 2017 QBI Software, The University of Queensland
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *   
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details. 
  */

filesep = File.separator; //"/";  
dir = getInfo("image.directory"); //getDirectory("image");
name = getInfo("image.filename"); 
title = getTitle(); 
exti = indexOf(name,'.tif');
basename = substring(name, 0, exti);
print("Name:", name);
print("Directory:", dir);
print("Title:", title);

n = roiManager("count");
setOption("BlackBackground", false);
for (i=0; i< n; i++){
	run("Duplicate...", "title=&title");
	selectWindow(title);
	roiManager("Select", i);
	print("clear outside ...");
	setBackgroundColor(255,255,255); //If dark background required, change this to (0,0,0)
	run("Clear Outside");
	seln = getInfo("selection.name");
	print("Selection:", seln);
	roiname = basename + "_"+seln+".tif";
	tiff = dir + filesep + roiname;
	print("ROI:" + tiff);
	print("running auto crop...");
	run("Auto Crop");	
	print("saving as tiff:" + tiff);
	saveAs("Tiff", tiff);
	selectWindow(title);
}

