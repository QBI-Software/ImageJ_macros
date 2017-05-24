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
roiManager("save", dir + basename + "_ROIset.zip");
n = roiManager("count");
setOption("BlackBackground", false);
roilist = newArray(n+1);
roilabels = newArray(n+1);
//Config settings
run("Set Measurements...", "area perimeter limit display nan redirect=None decimal=3");
run("Set Scale...", "distance=1.5442 known=1 pixel=1.018 unit=micron global");

//Process ROIs (must be manually drawn and added to ROI Manager)
for (i=0; i< n; i++){
	run("Duplicate...", "title=&title");
	selectWindow(title);
	roiManager("Select", i);
	print("clear outside ...");
	setBackgroundColor(255,255,255); //If dark background required, change this to (0,0,0)
	run("Clear Outside");
	seln = getInfo("selection.name");
	print("Selection:", seln);
	roilist[i] = i;
	roilabels[i] = seln;
	roiname = basename + "_"+seln+".tif";
	tiff = dir + filesep + roiname;
	//print("ROI:" + tiff);
	print("running auto crop...");
	run("Auto Crop");	
	print("saving as tiff:" + tiff);
	saveAs("Tiff", tiff);
	findDABcount(seln);
	//run("Close");
	selectWindow(title);
}

//Calculate area measurements
//selectWindow(title);
run("Clear Results");
selectWindow(title);
roiManager("select", roilist);
roiManager("measure");
//Generate Summary table
createSummary();
nameOfSummaryTable = "DABSummary";
IJ.renameResults(nameOfSummaryTable);
selectWindow(nameOfSummaryTable);
saveAs("Text", dir + filesep + basename + "_" + nameOfSummaryTable + ".xls");
//Clean up - uncomment next line for debugging
//run("Close All");

/****** FUNCTIONS ******/
function createSummary(){
	selectWindow("Summary");
	summarylines = split(getInfo(), "\n");
	selectWindow("Results");
	for (i=0; i < summarylines.length -1; i++){
		values = split(summarylines[i+1], "\t");		
		label = getResultLabel(i);
		print("result for " + label);
		count = parseInt(values[1]);
		dabarea = parseFloat(values[2]);
		dabsize = parseFloat(values[3]);
		area = getResult("Area",i);
		density = count/dabarea; 			
		percentarea = 100 * (dabarea/area); 
		//Add to Results table
		setResult("Count", i, count);				//count of DAB +ve cells in ROI
		setResult("DABarea", i, dabarea);			//area of DAB +ve cells in ROI
		setResult("Density", i, density);			//number DAB cells per unit area of ROI - um2
		setResult("PercentArea", i, percentarea);	//percent area of ROI stained with DAB over total ROI area
		setResult("AvgSize", i, dabsize);			//average size of DAB cell somas - um2
		
	}
	
	
}


// For each ROI, count DAB stained cells: assumes ROI has been cropped to new image
function findDABcount(tiff){
	print("Processing ROI:" + tiff);
	//Enhance image
	run("Median...", "radius=2");
	run("Brightness/Contrast...");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	//Detect DAB labeling
	setAutoThreshold("RenyiEntropy dark");
	setThreshold(0, 18);
	run("Convert to Mask");
	run("Options...", "iterations=20 count=5 pad do=Close");
	//Detect labeled neurons
	run("Watershed");
	run("Analyze Particles...", "size=30-Infinity circularity=0.20-1.00 show=[Overlay Masks] display exclude clear include summarize in_situ");
	updateResults();
	//save mask? 
	print("DAB Results saved");//:" + getResultLabel() + "=" + getResult("Count"));
}


