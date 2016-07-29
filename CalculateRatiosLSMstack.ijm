/*  CalculateRatiosLSMStack
 *   This macro calculates the area of neuron labelling in each channel of an RGB stack
 *   Developed for the Anggono Lab, QBI
 *   
 *   Steps: 1. Opens LSM file and converts to TIFF (saved as tif)
 *          2. Creates a mask over neuron to exclude any background (saved as stack ROIs for soma and whole neuron)
 *          3. Calculates area covered in each channel for each Z of stack (saved as results)
 *          4. Calculates final ratios of each channel (Total, External and Internal labelling respectively)
 *          
 *   Requirements: 
 *   	1. FeatureJ plugin
 *   	2. Options for FeatureJ: check isotropic Gaussian (set in script)
 *   	3. Options for Binary: check black background (set in script)
 *   	
 *   Contact: Liz Cooper-Williams, QBI (e.cooperwilliams@uq.edu.au)
 *   
 *   (c)Copyright 2016 QBI Software, The University of Queensland
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

//MAIN
filesep = File.separator; //"/";  
path = File.openDialog("Select LSM Image");
//open(path); // open the file
dir = File.getParent(path);
name = File.getName(path);
print("File opened:", path);
print("Name:", name);
print("Directory:", dir);
basename = File.nameWithoutExtension();
tifname = basename + ".tif";
tiff = dir + filesep + tifname;
convertLSM_Tiff(path, tiff);
//selectWindow(tifname);
//Soma analysis
print("Creating Soma masks");
createSomaMask(tiff);
List.clear;
print("Analysing Soma");
analyseSoma(tiff);
//Save soma analysis to file
resultsfile = path + ".soma_results";
saveAs("results", resultsfile);
print("Soma results saved: " + resultsfile);
//Neuron analysis
print("Beginning neuron analysis ...");
analysislist = analyseNeuron(tiff, basename);
print("... end neuron analysis");
roifile = dir + filesep + basename + "_roi.zip";
roiManager("save", roifile);
print("Saved ROIs:" + roifile);
List.setList(analysislist);

//Output Ratios
if (List.size > 0){
	print("Compiling summary of analysis");
	int = parseFloat(List.get("internal"));
	ext = parseFloat(List.get("external"));
	tot = parseFloat(List.get("total"));
	sint = parseFloat(List.get("soma_internal"));
	sext = parseFloat(List.get("soma_external"));
	stot = parseFloat(List.get("soma_total"));
	dint = int - sint;
	dext = ext - sext;
	dtot = tot - stot;
	
	ratio1 = int/ext;
	ratio2 = ext/tot;
	ratio3 = sint/sext;
	ratio4 = sext/stot;
	ratio5 = dint/dext;
	ratio6 = dext/dtot;
	//Save to Summary
	nameOfSummaryTable = "Summary";
	tableRef = "[" + nameOfSummaryTable + "]";
	run("Table...", "name=[" + nameOfSummaryTable + "] width=350 height=250");
	if (isOpen(nameOfSummaryTable))
	     print(tableRef, "\\Clear");
	  else
		run("Table...", "name=" + tableRef + " width=350 height=250");
	print(tableRef, "\\Headings:Channel\tAll\tSoma\tDendrites");
	print(tableRef, "Total\t" + tot +"\t" + stot + "\t" + dtot);
	print(tableRef, "External\t" + ext +"\t" + sext + "\t" + dext);
	print(tableRef, "Internal\t" + int +"\t" + sint + "\t" + dint);
	print(tableRef, "Int/Ext\t" + ratio1 +"\t" + ratio3 + "\t" + ratio5);
	print(tableRef, "Ext/Total\t" + ratio2 +"\t" + ratio4 + "\t" + ratio6);
	
	
	//IJ.renameResults(nameOfSummaryTable);
	selectWindow(nameOfSummaryTable);
	saveAs("Text", dir + filesep + File.nameWithoutExtension() + "_" + nameOfSummaryTable + ".xls");
	
	//Select starting image
	if (Stack.isHyperStack){
		Stack.setPosition(1, 1, 1);
	}
	
	//Popup
	rtn = "\n";
	title = "***** Summary Results ******";
	string = rtn + title + rtn + "Filename=" + name + 
		rtn + "Internal/External=" + ratio1 + 
		rtn + "External/Total=" + ratio2 + 
		rtn + "SOMA Internal/External=" + ratio3 + 
		rtn + "SOMA External/Total=" + ratio4 + 
		rtn + "DENDRITES Internal/External=" + ratio5 + 
		rtn + "DENDRITES External/Total=" + ratio6;
	print(string);	
	string = rtn + title + rtn + "Filename=" + name + 
		rtn + "Analysis complete - Files saved:" + 
		rtn + " - Tif converted image" +
		rtn + " - ROIs zip" +
		rtn + " - Particle analysis of soma" +
		rtn + " - Particle analysis of whole cell" + 
		rtn + " - Summary table of ratios";
	print(string);
	
	width=512; height=512;
	Dialog.create("CalculateRatiosLSMStack macro");
	Dialog.addMessage(string);
	Dialog.show();
}else{
	exit("Error: Analysis missing");
	
}


// ***** FUNCTIONS *****
function convertLSM_Tiff(lsmfile, tiff){
	//Open as LSM
	run("LSM...", "open=[" + lsmfile + "]");	
	saveAs("Tiff", tiff);
	print("File saved:", tiff);
	close();
}

function createSomaMask(tiff){
	//print("CreateSomaMask: open tiff:" + tiff);
	open(tiff);
	run("8-bit"); //ensure 8 bit for binary
	//Combine all data so mask will cover all
	run("Make Composite", "display=Color");
	
	//Enhance dim pixels
	run("Window/Level...");
	run("Enhance Contrast", "saturated=0.35");
	setMinAndMax(1, 53);
	call("ij.ImagePlus.setDefault16bitRange", 8);

	//remove background specs
	run("Despeckle", "stack");
	//run("Save"); ?required for later?

	//Create soma mask
	run("Gaussian Blur 3D...", "x=20 y=20 z=2");
	setOption("BlackBackground", true);
	run("Make Binary", "method=Default background=Default calculate only black");
	run("Create Selection");
	roiManager("reset");
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Rename", "soma");
	close(); //close without saving over initial tiff
}

function analyseSoma(tiff){
	//calculate soma results and store
	open(tiff);
	run("Make Binary", "method=Default background=Default calculate black");
	roiManager("Select", 0);
	//Run analysis
	run("Set Measurements...", "area area_fraction stack limit display nan redirect=None decimal=3");
	run("Analyze Particles...", "show=Overlay display clear include summarize in_situ stack");
	updateResults();
	//IJ.renameResults("Soma results");
	//resultsfile = path + ".soma_results";
	//saveAs("results", resultsfile);

	//Parse results for totals
	Stack.getDimensions(width, height, channels, slices, frames);
	labels=newArray("soma_total","soma_external", "soma_internal"); //Check order from LSM
	somalines = split(getInfo(),"\n");
	initval = 0;
	for (j=0; j< labels.length; j++){
		for(i=1+j; i<somalines.length;i=i+channels){
			values = split(somalines[i], "\t");
		  	s = values[0]; //slice
		  	a = parseFloat(values[2]); //area
		  	
		  	if (isNaN(parseFloat(List.get(labels[j])))){
		  		initval = 0;
		  	}else{
		  		initval = parseFloat(List.get(labels[j]));
		  	}
		  	initval = a + initval;
		  	List.set(labels[j], initval);
		}
		print(labels[j] + "=" + List.get(labels[j]));
	}
	close(); //don't save any changes
}
//Private function
function createNeuronMask(basefilename){
	print("Creating neuron mask..." + basefilename);
	//Stack.getDimensions(width, height, channels, slices, frames);
	//enhance
	run("Window/Level...");
	run("Enhance Contrast", "saturated=0.35");
	//make binary
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");
	run("FeatureJ Options", "isotropic progress");
	run("FeatureJ Edges", "compute smoothing=1.0 lower=[] higher=[]");
	run("Make Binary", "method=Huang background=Dark calculate black");
	//create mask
	run("Dilate", "stack");
	run("Dilate", "stack");
	run("Close-", "stack");
	run("Convert to Mask", "method=Huang background=Dark calculate black");
	
	//Add masks to ROImanager = all channels * all z
	print("Adding ROIs="+nSlices);
	//roiManager("reset");
	for(i=1; i<= nSlices; i++){
		setSlice(i);
		run("Create Selection");
		//setKeyDown("alt");
		roiManager("add");
	
	}
	
	
	
}

function analyseNeuron(tiff, basefilename){
	open(tiff);
	createNeuronMask(basefilename);
	//Calulate areas within ROIs
	edges = basefilename + ".tif" + " edges";
	tifname = basefilename + ".tif";
	print("Running image analysis="+edges);
	imageCalculator("Multiply create stack", edges, tifname);
	print("Running image calculator");
	//Assumes masked stack open
	run("Set Measurements...", "area area_fraction stack limit display nan redirect=None decimal=3");
	run("Analyze Particles...", "pixel show=Overlay display clear include summarize in_situ stack");
	updateResults();

	//Calculate Ratios from Results
	lines = split(getInfo(), "\n");
	print("Summarizing Results:"+lines.length);
	Stack.getDimensions(width, height, channels, slices, frames);
	//print ("Channels:" + channels);
	labels=newArray("total","external", "internal"); //Check order from LSM

	initval = 0;
	for (j=0; j< labels.length; j++){
		for(i=1+j; i<lines.length;i=i+channels){
			values = split(lines[i], "\t");
			//print("Line: "+lines[i]);
		  	s = values[0]; //slice
		  	a = parseFloat(values[2]); //area
		  	
		  	if (isNaN(parseFloat(List.get(labels[j])))){
		  		initval = 0;
		  	}else{
		  		initval = parseFloat(List.get(labels[j]));
		  	}
		  	initval = a + initval;
		  	List.set(labels[j], initval);
		}
		print(labels[j] + "=" + List.get(labels[j]));
	}
	print("Summary fields= "+ List.size);
	close();
	return List.getList();
}



