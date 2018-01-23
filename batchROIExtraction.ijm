/*  batchROIExtraction
 *   This macro extracts one or more ROIs from an image in TIF or OME.TIF format including 3 channels and saves results and images as output
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


filesep = File.separator; //"/";
dir1 = getDirectory("Choose source directory");
outputdir = getDirectory("Choose output directory");
filelist = getFileList(dir1);

//create dialog options
Dialog.create("Options");
Dialog.addString("ROI file suffix", "_ROIset.zip");
Dialog.addCheckbox("Black background",0);
Dialog.addCheckbox("Adjust background",0);
Dialog.addCheckbox("Generate overlays",0);
Dialog.show();
roiset = Dialog.getString();
blackbg = Dialog.getCheckbox();
adjustbg = Dialog.getCheckbox();
overlay = Dialog.getCheckbox();

print("OPTIONS: Black bg=" + blackbg + " Adjust bg=" + adjustbg + " Overlays=" + overlay);

//Config settings
setOption("BlackBackground", blackbg);
run("Set Measurements...", "area perimeter integrated area_fraction stack limit display add nan decimal=3");
//run("Set Scale...", "distance=1.5442 known=1 pixel=1.018 unit=micron global");
setBatchMode(true);

//Batch run - if not required can comment out
for(j=0;j<filelist.length;j++){
	inputfile = dir1 + filelist[j];
	if (!File.isDirectory(inputfile)){
		if (endsWith(filelist[j], ".tif")){
			showProgress(j+1, filelist.length);	
			//If normal tiff file - use this: open(dir1 + filelist[j]);
			//If tiled tiff file  - use Bioformats
			if (endsWith(filelist[j], ".ome.tif")){
				run("Bio-Formats", "open=[" + inputfile + "] color_mode=Default split_channels open_files view=Hyperstack stack_order=XYCZT use_virtual_stack contains=[] name=[" + inputfile + "]");
			}else{
				open(inputfile);
			}
			//get Image refs
			title = getTitle();
			basename = File.nameWithoutExtension;
			print("***Image opened: ", title);	
			
			//Extract ROIs
			print("Extracting ROIs");
			extractROIImages(outputdir, blackbg, roiset, adjustbg, overlay);

			//Clean up windows
			run("Close All"); 
		}
	}
}

setBatchMode(false);

print("\n***********************\nProgram finished\n***********************");


/****** FUNCTIONS ******/
function adjustBackground(){
	//Check for multi-channel
	Stack.getDimensions(width, height, channels, slices, frames);
	print("Channels: " + channels + " Slices: " + slices + " Frames: " + frames);
	
	for (t=1; t<=frames; t++) {
		 for (z=1; z<=slices; z++) {
		    for (c=1; c<=channels; c++) {
		       Stack.setPosition(c, z, t);
		       run("Subtract Background...", "rolling=50");
		       run("Window/Level...");
		       resetMinAndMax();
		       run("Enhance Contrast", "saturated=0.35");
		       //run("Apply LUT");
		    }
		 }
	}
	
	
}



function extractROIImages(outputdir, blackbg, roiset, adjustbg, overlay){
	dir = getInfo("image.directory"); //getDirectory("image");
	if (lengthOf(outputdir) <=0){
		outputdir = dir;
	}
	name = getInfo("image.filename"); 
	title = getTitle(); 
	if (indexOf(name, ".ome.tif")> 0){
		exti = indexOf(name,'.ome.tif');
	}else{
		exti = indexOf(name,'.tif');
	}
	
	basename = substring(name, 0, exti);
	print("Name: ", name);
	print("Directory: ", dir);
	print("Title: ", title);
	roifile = dir + basename + roiset;
	roisingle = dir + basename + ".roi";
	print("ROIfile: " + roifile);
	roiManager("reset");
	if (File.exists(roifile)){
		roiManager("open", roifile);
		n = roiManager("count");
		print("ROIs loaded=" + n);
	} else if (File.exists(roisingle)){
		roiManager("open", roifile);
		n = roiManager("count");
		print("Single ROI loaded=" + n);
	} else {
		print("ROI zip or single roi not detected - check filename match");
		print("ROIfile: " + roifile);
		print("ROIsingle: " + roisingle);
		return 0;
	}
	run("Clear Results");	
	if (blackbg == true){
		setBackgroundColor(0,0,0);
		print("setting bg to black");
	}else{
		setBackgroundColor(255,255,255); 
		print("setting bg to white");
	}
	selectWindow(title);
	Stack.getDimensions(width, height, channels, slices, frames);
	//Process ROIs (must be manually drawn and added to ROI Manager)
	for (i=0; i< n; i++){
		selectWindow(title);
		run("Duplicate...", "duplicate");	
		roiManager("Select", i);
		print("clear outside ...");
		if (channels > 1){
			run("Clear Outside", "stack");
		}else{
			run("Clear Outside");
		}

		seln = getInfo("selection.name");
		print("Selection:", seln);
		roiname = basename + "_"+seln+".tif";
		tiff = outputdir + filesep + roiname;
		print("running auto crop...");
		run("Auto Crop");
		if (adjustbg == true){
			print("Adjusting Background");
			adjustBackground();
		}	
		roiManager("Select", i);
		roiManager("measure");
		saveAs("Tiff", tiff);
		print("ROI saved:" + tiff);
	}

	//Generate Overlay Images
	if (overlay == true){
		selectWindow(title);
		run("Stack to Images");
		// Add all rois
		setOption("ExpandableArrays", true);
		rois = newArray;
		for (j=0;j<n;j++){
			rois[j] = j;
		}
		roiManager("Select", rois);		
		roiManager("Set Color", "red");
		roiManager("Set Line Width", 20);
		run("Flatten");
		olay = outputdir + "Overlay_" + basename + ".tif";
		saveAs("Tiff", olay);
		print("Overlay saved:" + olay);		
	}
	
	//Save area measurements to CSV
	nameOfSummaryTable = "ROISummary";
	IJ.renameResults(nameOfSummaryTable);
	selectWindow(nameOfSummaryTable);
	saveAs("Text", outputdir + filesep + basename + "_" + nameOfSummaryTable + ".csv");
	//Clear ROI manager - uncomment this if single mode
	roiManager("reset");
}



