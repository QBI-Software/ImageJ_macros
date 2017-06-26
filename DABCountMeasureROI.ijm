/*  DABCountMeasureROI
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
setBatchMode(true);

//Batch run - if not required can comment out
for(j=0;j<filelist.length;j++){
	inputfile = dir1 + filelist[j];
	if (!File.isDirectory(inputfile)){
		if (endsWith(filelist[j], ".tif")){
			showProgress(j+1, filelist.length);	
			//If normal tiff file - use this: open(dir1 + filelist[j]);
			//If tiled tiff file  - use Bioformats
			run("Bio-Formats", "open=[" + inputfile + "] color_mode=Default group_files split_channels open_files view=Hyperstack stack_order=XYCZT use_virtual_stack contains=[] name=[" + inputfile + "]");
			//?pause
			//Config settings
			setOption("BlackBackground", false);
			run("Set Measurements...", "area perimeter limit display nan redirect=None decimal=3");
			run("Set Scale...", "distance=1.5442 known=1 pixel=1.018 unit=micron global");
			//will default to last opened image - channel C=2
			processCurrentImage(outputdir);
			//Clean up windows
			run("Close All"); 
		}
	}
}

//Single run with image already open - comment out if using Batch run
//processCurrentImage(outputdir);
//run("Close All");
print("\n***********************\nProgram finished\n***********************");


/****** FUNCTIONS ******/
function processCurrentImage(outputdir){
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
	n = roiManager("count");
	print("ROImanager: " + n);
	if (!File.exists(roifile) && n > 0){
		roiManager("save", roifile);
	}else if(n <= 0){
		if (!File.exists(roifile)){
			roifile = dir + basename + "ROIset.zip"; //without underscore
			if (!File.exists(roifile)){
				print("Neither ROI file found - skipping" + roifile);
				return 0;
			}
			roiManager("open", roifile);
			n = roiManager("count");
			print("Existing ROI");
		}
		
	}
	if (n <= 0){
		print("No ROIs found for " + name);
		return 0;
	}else{
		print("ROIs loaded=" + n);
	}
	
	run("Subtract Background...", "rolling=50 light");
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
		findDABcount(seln);
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
	createSummary(basename);
	nameOfSummaryTable = "DABSummary";
	IJ.renameResults(nameOfSummaryTable);
	selectWindow(nameOfSummaryTable);
	saveAs("Text", outputdir + filesep + basename + "_" + nameOfSummaryTable + ".csv");
	//Clear ROI manager - uncomment this if single mode
	roiManager("reset");
	//TODO: Find a way to clear the Summary table
	//tableRef = "[" + nameOfSummaryTable + "]";
	//print(nameOfSummaryTable,"//Clear");
	//IJ.deleteRows(0, 7);
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


// For each ROI, count DAB stained cells: assumes ROI has been cropped to new image
function findDABcount(tiff){
	print("Processing ROI:" + tiff);
	//Enhance image
	run("Subtract Background...", "rolling=50 light");
	run("Median...", "radius=2");
	run("Brightness/Contrast...");
	run("Enhance Contrast", "saturated=0.35"); //NOTE: This enhances contrast amongst provided pixel data - it may give false DAB+ve
	run("Apply LUT");
	//Detect DAB labeling
	setAutoThreshold("RenyiEntropy dark");
	setThreshold(0, 18);
	run("Convert to Mask");
	run("Despeckle");
	run("Close-");
	//run("Options...", "iterations=20 count=5 pad do=Close");
	//Detect labeled neurons
	run("Watershed");
	run("Analyze Particles...", "size=30-Infinity circularity=0.05-1.00 show=[Overlay Masks] display exclude clear include summarize in_situ");
	updateResults();
	//save mask? 
	print("DAB Results saved");//:" + getResultLabel() + "=" + getResult("Count"));
}


