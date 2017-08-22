/*  batchROIColocalization
 *   This macro extracts one or more ROIs from an image and saves it as filename_<ROIname>.tiff
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
 *          	c. Processing of each image to detect number of dark stained neurons 
 *          		- note, this is problematic with low contrast images and may give false positives, particularly with wild type - manual count to check
 *          	d. Results are compiled and written to a csv file
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
//setBatchMode(true);

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
			print("Image opened - Adjusting Background: ", title);
			adjustBackground(outputdir);
			//Save as RGB image
			run("Duplicate...", "duplicate");
			run("Stack to RGB");
			rgbimg = outputdir + filesep + basename+ "_RGB.tiff";
			saveAs("Tiff", rgbimg);

			//Return to main
			selectWindow(title);
			if (roiset == true){
				print("Extracting ROIs");
				extractROIImages(outputdir);
			}
			
			//Create masks for each channel add to ROI Manager
			print("Creating masks - added to ROI Manager");
			createMask(outputdir);
			roiManager("save", outputdir + filesep + basename + "_maskROI.zip");
			//Measure
			analysis(outputdir, basename);
			
			//Clear ROI manager - uncomment this if single mode
			//roiManager("reset");
			
			//Clean up windows
			//run("Close All"); 
		}
	}
}


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

function extractROIImages(outputdir){
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
	print("Name:", name);
	print("Directory:", dir);
	print("Title:", title);
	roifile = dir + basename + "_ROIset.zip";
	print("ROIfile" + roifile);
	roiManager("reset");
	if (File.exists(roifile)){
		roiManager("open", roifile);
		n = roiManager("count");
		print("ROIs loaded=" + n);
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
		setBackgroundColor(255,255,255); //If dark background required, change this to (0,0,0)
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

function createMask(outputdir){
	
	for(i=1; i<= nSlices; i++){
		setSlice(i);
		//setThreshold(colorthresholds(i-1), 255);
		setAutoThreshold("RenyiEntropy dark");
		
	    //run("Convert to Mask", "method=RenyiEntropy background=Dark black list");
		run("Despeckle", "slice");
		run("Dilate", "slice");
		run("Dilate", "slice");
		
		if (i==3){
			run("Watershed", "slice"); //DAPI only
		}else{
			run("Dilate", "slice");
		}
		run("Analyze Particles...", "size=30-Infinity circularity=0.20-1.00 show=[Overlay Masks] exclude summarize in_situ slice");
		
		run("Create Selection");
		roiManager("add");
		roiManager("Select", i-1);
		roiManager("Rename", "mask_" + i);
		
	}
	saveAs("TIFF", outputdir + File.separator + "mask_.tiff");
	//imageCalculator("AND create", "M16 20s~B_003.tif (RGB)_RGB.tiff (red)","M16 20s~B_003.tif (RGB)_RGB.tiff (green)");
}


function colocalisation(outputdir){
	//run("Color Histogram");
	//run("Colocalization Threshold", "channel_1=[M16 20s~B_003.tif (RGB) (red)] channel_2=[M16 20s~B_003.tif (RGB) (green)] use=None channel=[Red : Green] show use show include");
	//run("JACoP ", "image=[C1-" + title + "] image=[C2-" + title + "]");
	//run("Colocalization Threshold", "channel_1=[" + c1 + "] channel_2=[" + c2 + "] use=None channel=[" + channel + "] show use include set pearson's mander's number % % % %");
}

function analysis(outputdir,basename){
	print("Analysing ...");
	
	//Get counts and areas for each slice - Summary table
	for(i=1; i<= nSlices; i++){
		setSlice(i);		
		roiManager("Select",i-1);
		run("Analyze Particles...", "size=30-Infinity circularity=0.20-1.00 show=[Overlay Masks] exclude include summarize in_situ slice");

	}

	//Counts of combined RGB
	roiManager("Select", newArray(0,1));
	roiManager("AND");
	setSlice(3);
	
	run("Analyze Particles...", "size=30-Infinity circularity=0.30-1.00 show=[Overlay Masks] exclude include summarize in_situ slice");
	
	updateResults();
	selectWindow("Summary of " + getTitle());
	//Rename this to combinedRGB
	setResult("Label",4,  "CombinedRGB");
	outputfname = outputdir + File.separator + basename + "_results.csv";
	print("Results saved to ", outputfname);
	saveAs("Text", outputfname);
}

function createSummary(basefilename){
	selectWindow("Summary");
	summarylines = split(getInfo(), "\n");
	print("Summary has lines=" + summarylines.length);
	selectWindow("Results");
	resultsidx = 0;
	resultsmax = roiManager("count");
	for (i=1; i < summarylines.length; i++){
		values = split(summarylines[i], "\t");
		if (startsWith(values[0],basefilename) && resultsidx < resultsmax){
			label = getResultLabel(resultsidx);
			print(label);
			if (startsWith(label, basefilename)){
				count = parseInt(values[1]);
				dabarea = parseFloat(values[2]);
				dabsize = parseFloat(values[3]);
				area = getResult("Area",resultsidx);
				density = count/dabarea; 			
				percentarea = 100 * (dabarea/area); 
				//Add to Results table
				setResult("Count", resultsidx, count);				//count of DAB +ve cells in ROI
				setResult("DABarea", resultsidx, dabarea);			//area of DAB +ve cells in ROI
				setResult("Density", resultsidx, density);			//number DAB cells per unit area of ROI - um2
				setResult("PercentArea", resultsidx, percentarea);	//percent area of ROI stained with DAB over total ROI area
				setResult("AvgSize", resultsidx, dabsize);			//average size of DAB cell somas - um2
			}
			resultsidx += 1;
		}
	}
	//ensure only ROIs results 
	IJ.deleteRows(resultsmax,resultsmax);
	
}



