/*  batchROIColocalization
 *   This macro extracts one or more ROIs from an image (optional), analyses colocalisation between 3 channels and saves results and images as output
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
 *      	3. Batch Processing will run as
 *          	a. For each ROI, clears around ROI then crops image and saves to a new image with same root filename + ROI name
 *          	b. Analysis of area, perimeter of each ROI
 *          	c. Processing of each image to detect neurons as blob segments - analysed for count, area
 *              d. Combined masks between channels 1, 2, 3 to detect object colocalisation
 *          4. Results 
 *          	a. Statistics are compiled and written to a csv file
 *          	b. RGB image and Combined mask image created and Mask ROI set saved per channel
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
Dialog.create("Image type options");
Dialog.addCheckbox("Fluorescent microscopy", 0);
Dialog.addCheckbox("TIFF images", 0);
Dialog.addCheckbox("Extract ROIs", 0);
Dialog.show();
blackbg = Dialog.getCheckbox();
tiffimg = Dialog.getCheckbox();
roiset = Dialog.getCheckbox();
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
			if (tiffimg == true){
				open(inputfile);
			}else{
				run("Bio-Formats", "open=[" + inputfile + "] color_mode=Default split_channels open_files view=Hyperstack stack_order=XYCZT use_virtual_stack contains=[] name=[" + inputfile + "]");
			}
			//get Image refs
			title = getTitle();
			basename = File.nameWithoutExtension;
			print("***Image opened: ", title);
			print("Adjusting Background");
			adjustBackground(outputdir);
			
			//Extract ROIs
			if (roiset == true){
				print("Extracting ROIs");
				extractROIImages(outputdir, blackbg);
			}
			//Save as RGB image
			selectWindow(title);
			run("Duplicate...", "duplicate");
			run("Stack to RGB");
			rgbimg = outputdir + filesep + basename+ "_RGB.tiff";
			saveAs("Tiff", rgbimg);

			//Segment cells from each channel as masks
			selectWindow(title);
			print("Creating masks...");
			roiidx = createMask(outputdir, blackbg);
			roiManager("save", outputdir + filesep + basename + "_maskROI.zip");
			print("Masks saved to zip");
			//Count all cells from each channel
			print("Counting cells from each channel...");
			analysis(outputdir, basename+ "_RGB.tiff", roiidx);
			
			//Clear ROI manager - uncomment this if single mode
			roiManager("reset");
			
			//Clean up windows
			run("Close All"); 
		}
	}
}

setBatchMode(false);

print("\n***********************\nProgram finished\n***********************");


/****** FUNCTIONS ******/
function adjustBackground(outputdir){
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



function extractROIImages(outputdir, blackbg){
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
	roifile = dir + basename + "_ROIset.zip";
	print("ROIfile: " + roifile);
	roiManager("reset");
	if (File.exists(roifile)){
		roiManager("open", roifile);
		n = roiManager("count");
		print("ROIs loaded=" + n);
	}
	else{
		print("ROI zip not detected");
		return 0;
	}
	//run("Subtract Background...", "rolling=50 dark");
	roilist = newArray(n+1);
	roilabels = newArray(n+1);
	run("Clear Results");
	
	
	selectWindow(title);
	//Process ROIs (must be manually drawn and added to ROI Manager)
	for (i=0; i< n; i++){
		run("Duplicate...", "title=&title");	
		roiManager("Select", i);
		print("clear outside ...");
		if (blackbg){
			setBackgroundColor(0,0,0);
		}else{
			setBackgroundColor(255,255,255); 
		}
		run("Clear Outside");
		seln = getInfo("selection.name");
		print("Selection:", seln);
		roilist[i] = i;
		roilabels[i] = seln;
		roiname = basename + "_"+seln+".tif";
		tiff = outputdir + filesep + roiname;
		//print("ROI:" + tiff);
		print("running auto crop...");
		run("Auto Crop");	
		print("saving as tiff:" + tiff);
		saveAs("Tiff", tiff);
		//findDABcount(seln);
		selectWindow(title);
	}
	
	//Calculate area measurements to Results table
	//selectWindow(title);
	run("Clear Results");
	selectWindow(title);
	print("ROIlist: " + roilist.length);
	roiManager("select", roilist);
	roiManager("measure");
	//Generate Summary table
	//createSummary(basename);
	nameOfSummaryTable = "ROISummary";
	IJ.renameResults(nameOfSummaryTable);
	selectWindow(nameOfSummaryTable);
	saveAs("Text", outputdir + filesep + basename + "_" + nameOfSummaryTable + ".csv");
	//Clear ROI manager - uncomment this if single mode
	roiManager("reset");
}

function createMask(outputdir, blackbg){
	
	for(i=1; i<= nSlices; i++){
		setSlice(i);
		roiidx = newArray(4);
		if (blackbg){
			bg = 'Dark';
		}else{
			bg = 'Light';
		}
		setAutoThreshold("RenyiEntropy " + bg);
		if (i != 2){
			setThreshold(45, 255); //TODO: need to set more dynamically
		}
		run("Convert to Mask", "method=RenyiEntropy background=" + bg + " calculate only black list");
		run("Despeckle", "slice");
		run("Dilate", "slice");
		if (i != 2){
			run("Gaussian Blur...", "sigma=4 slice");
			run("Find Edges", "slice");
			run("Make Binary", "method=Moments background=" + bg + " calculate black list");
			run("Fill Holes", "slice");
			
			if (i==3){
				run("Watershed", "slice"); //DAPI only
			}
		}
		print("Mask created - now adding to ROI manager");
		run("Create Selection");
		roiManager("add");
		roiManager("Select", i-1);
		roiManager("Rename", "mask_" + i);
		roiManager("remove slice info")
		roiidx[i-1]=roiManager("index");
		
	}
	//Create combined mask with channels 1 and 3
	roiManager("Select", newArray(0,2));
	roiManager("AND");
	roiManager("Add");
	roiManager("Rename", "RBcombined");
	roiidx[i-1]=roiManager("index");
	roiManager("Deselect");
	//selectWindow(getTitle());
	//run("Create Selection");
	//saveAs("TIFF", outputdir + File.separator + "mask.tiff");
	print("ROI idx: ", join(roiidx,","));
	return roiidx;
}

//Analyse RGB image created above with masks - TODO sort this out
function analysis(outputdir,basename, roiidx){
	print("Analysing ...");
	selectWindow(basename);
	run("RGB Stack");
	
	//Get counts and areas for each slice - Summary table
	for(i=1; i<= nSlices; i++){
		setSlice(i);		
		roiManager("Select",roiidx[i-1]);
		setAutoThreshold("Otsu dark");
		run("Analyze Particles...", "size=50-Infinity circularity=0.20-1.00 show=[Overlay Masks] exclude include summarize in_situ slice");

	}
	//Count for combined
	setSlice(1);
	roiManager("Select", 0);
	setAutoThreshold("Otsu dark");
	setThreshold(35, 255); 
	run("Analyze Particles...", "size=50-Infinity circularity=0.20-1.00 show=[Overlay Masks] exclude include summarize in_situ slice");
	
	//Save results
	nameOfSummaryTable = "CountSummary";
	IJ.renameResults(nameOfSummaryTable);
	selectWindow(nameOfSummaryTable);
	saveAs("Text", outputdir + File.separator + basename + "_" + nameOfSummaryTable + ".csv");
	
}


//TODO: Colocalize via segmentation not pixel
function colocalisation(outputdir){
	//run("Color Histogram");
	//run("Colocalization Threshold", "channel_1=[M16 20s~B_003.tif (RGB) (red)] channel_2=[M16 20s~B_003.tif (RGB) (green)] use=None channel=[Red : Green] show use show include");
	//run("JACoP ", "image=[C1-" + title + "] image=[C2-" + title + "]");
	//run("Colocalization Threshold", "channel_1=[" + c1 + "] channel_2=[" + c2 + "] use=None channel=[" + channel + "] show use include set pearson's mander's number % % % %");
}




