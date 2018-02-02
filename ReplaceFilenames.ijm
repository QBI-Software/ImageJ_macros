/*  replaceFilenames
 *   This macro replaces filename suffixes (or spaces)
 *   Developed for QBI
 *   
 *   Steps: Preparation:
 *   	1. Open original image (directly or via Import->Bioformats - ensure "Split channels" is checked)
 *      2. Select required image (if multiple channels)
 *      3. Draw ROIs and add to ROI manager (T opens the ROI manager then click Add)
 *      4. Rename ROIs to make clear which selection is which (eg RIGHT for right hippocampus) using "Rename" in ROI Manager
 *      5. Save ROIs (select all first then under More>> Save) as same filename and "_ROIset.zip"
 *      
 *      Run this macro (recommend a freshly opened ImageJ):
 *      	1. Select the input directory (should only contain original images and ROI zip files)
 *      	2. Select the output directory
 *      	3. Choose options (suffix for saved ROI file, black bg for clearing option)
 *			4. Batch Processing will run as
 *          	a. For each ROI, clears around ROI then crops image and saves to a new image with same root filename + ROI name
 *          	b. Analysis of area, perimeter of each ROI  (as set by Set Measurements)
 *          	c. (Option) If overlay is checked, an image with the ROI overlaid will also be produced
 *          5. Results 
 *          	a. Statistics are compiled and written to a csv file
 *          	b. Cropped images created per ROI with ROI name
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

dir = getDirectory("Choose source directory");
//create dialog options
Dialog.create("Options");
Dialog.addString("Old suffix", ".roi.tif");
Dialog.addString("New suffix", ".tif");
Dialog.addCheckbox("Replace spaces",0);
Dialog.show();

oldsuffix = Dialog.getString();
newsuffix = Dialog.getString();
spaces = Dialog.getCheckbox();


filelist = getFileList(dir);
for(j=0;j<filelist.length;j++){
	replaceSuffix(dir, filelist[j], oldsuffix,newsuffix);
	if(spaces == true){
		replaceSpaces(dir,filelist[j]);
	}
}

function replaceSpaces(dir, filename){
	if (File.exists(dir + filename)){
		print("File exists:" + dir + filename);

		if (indexOf(filename, " ") > 0){
			print("found space");
			filename1 = replace(filename," ","_");
			print(dir + filename1);
			f1 = dir + filename;
			f2 = dir + filename1;
			if (File.rename(f1,f2) == 1){
				filename = filename1;
				print("New file: " + filename);
			} else{
				print("Didn't work");
			}
			
		}
	}else{
		print("can't find file:" + dir + filename);
	}
	return filename;
}

function replaceSuffix(dir, filename, oldsuffix, newsuffix){
	if (File.exists(dir + filename)){
		//print("File exists:" + dir + filename);
		if (endsWith(filename,oldsuffix)){
			print("File found with suffix: " + filename);
			filename1 = replace(filename,oldsuffix, newsuffix);
			f1 = dir + filename;
			f2 = dir + filename1;
			print("Old File:" + f1);
			if (File.rename(f1,f2) == 1){
				print("New File:" + f2);
			}else{
				print("Name change failed: " + f2);
			}				
			
		}
	}else{
		print("can't find file:" + dir + filename);
	}
	return filename;
}

