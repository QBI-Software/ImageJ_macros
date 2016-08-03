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
/*sample data

External/Total (dendrite) = 0.884
External/Total (soma) = 0.074
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
//Set options for measurements and thresholding
run("Set Measurements...", "area mean integrated median stack limit display nan redirect=None decimal=3");
call("ij.plugin.frame.ThresholdAdjuster.setMode", "Over/Under");
List.clear;
//Soma analysis
print("Creating Soma masks");
createSomaMask(tiff);
print("Analysing Soma");
analyseSoma(tiff);
//Save soma analysis to file
resultsfile = path + ".soma_results";
saveAs("results", resultsfile);
print("Soma results saved: " + resultsfile);
//Neuron analysis
print("Neuron analysis");
analysislist = analyseNeuron(tiff, basename);
//Save ROIs to a file
roifile = dir + filesep + basename + "_roi.zip";
roiManager("save", roifile);
print("Saved ROIs:" + roifile);
//Organize results
List.setList(analysislist);
generateSummaryTable(dir, basename);
exit();

// *************************** FUNCTIONS **************************************************************
function generateSummaryTable(dir, basename){
//Output Ratios
if (List.size > 0){
	reports = newArray("AREA", "DENSITY", "COUNT");
	for(i=0; i< reports.length; i++){
		print("Compiling summary of analysis: " + reports[i]);
		report = toLowerCase(reports[i]);
		int = parseFloat(List.get("internal_" + report));
		ext = parseFloat(List.get("external_" + report));
		tot = parseFloat(List.get("total_" + report));
		sint = parseFloat(List.get("soma_internal_" + report));
		sext = parseFloat(List.get("soma_external_" + report));
		stot = parseFloat(List.get("soma_total_" + report));
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
		nameOfSummaryTable = "Summary: " + reports[i];
		tableRef = "[" + nameOfSummaryTable + "]";
		//run("Table...", "name=[" + nameOfSummaryTable + "] width=350 height=250");
		if (isOpen(nameOfSummaryTable)){
		     print(tableRef, "\\Clear");
		}else{
			run("Table...", "name=" + tableRef + " width=350 height=250");
		}
		print(tableRef, "\\Headings:Channel\tAll\tSoma\tDendrites");
		print(tableRef, "Total " + report + "\t" + tot +"\t" + stot + "\t" + dtot);
		print(tableRef, "External " + report + "\t" + ext +"\t" + sext + "\t" + dext);
		print(tableRef, "Internal " + report + "\t" + int +"\t" + sint + "\t" + dint);
		print(tableRef, "Int/Ext " + report + "\t" + ratio1 +"\t" + ratio3 + "\t" + ratio5);
		print(tableRef, "Ext/Total " + report + "\t" + ratio2 +"\t" + ratio4 + "\t" + ratio6);
		
		
		//IJ.renameResults(nameOfSummaryTable);
		selectWindow(nameOfSummaryTable);
		saveAs("Text", dir + filesep + basename + "_" + reports[i] + ".xls");
		
		//Select starting image
		if (Stack.isHyperStack){
			Stack.setPosition(1, 1, 1);
		}
		
		//Popup
		rtn = "\n";
		title = "***** Ratio Results: " + reports[i] + " ******";
		string = rtn + title + rtn + "Filename=" + name + 
			rtn + "Internal/External=" + ratio1 + 
			rtn + "External/Total=" + ratio2 + 
			rtn + "SOMA Internal/External=" + ratio3 + 
			rtn + "SOMA External/Total=" + ratio4 + 
			rtn + "DENDRITES Internal/External=" + ratio5 + 
			rtn + "DENDRITES External/Total=" + ratio6;
		print(string);	
	}
	
	string = rtn + "**************************" + rtn + "Filename=" + name + 
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
	//run("Window/Level...");
	run("Enhance Contrast", "saturated=0.35");
	//setMinAndMax(1, 53);
	//call("ij.ImagePlus.setDefault16bitRange", 8);

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



//Private function
function createNeuronMask(basefilename){
	print("Creating neuron mask..." + basefilename);
	//Stack.getDimensions(width, height, channels, slices, frames);
	//enhance
	//run("Window/Level...");
	run("Enhance Contrast", "saturated=0.4");
	//run("Make Composite", "display=Color"); //collapse channels
	//Denoise image
	//run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack"); 
	//Find edges with FeatureJ
	run("FeatureJ Options", "isotropic progress");
	run("FeatureJ Edges", "compute smoothing=1.0 lower=[] higher=[]");
	//run("Despeckle", "stack");
	//make binary
	run("Options...", "iterations=1 count=1 black do=Nothing"); //Binary options
	run("Make Binary", "method=Huang background=Dark calculate black");
	//create mask
	run("Dilate", "stack");
	run("Dilate", "stack");
	run("Close-", "stack");	
	run("Subtract Background...", "rolling=10 create disable stack"); //Cleans up outliers
	run("Convert to Mask", "method=Huang background=Dark calculate black");
	//Add masks to ROImanager = all channels * all z
	print("Adding ROIs="+nSlices);
	//roiManager("reset");
	for(i=1; i<= nSlices; i++){
		setSlice(i);
		run("Create Selection");
		run("Fill ROI holes");
		//setKeyDown("alt");
		roiManager("add");
	
	}
	combineChannelROIs();
	

}

//Reduce to one mask per z (combine channels)
function combineChannelROIs(){
	Stack.getDimensions(width, height, channels, slices, frames);
	print("Channels: " + channels + " Slices: " + slices + " Frames: " + frames);
	i = 1;
	j = 0;
	remove = channels * slices;
	todelete = newArray(remove);
	for(z=1; z <= slices; z++){
			s1 = i+1;
			s2 = i+2;
			roiManager("Select", newArray(i,s1,s2));
			roiManager("AND");
			roiManager("Add");
			roiManager("Rename", "z-" + z);
			todelete[j] = s1;
			todelete[j+1] = s2;
			j = j + 2;
			//todelete = Array.concat(todelete, newArray(s1,s2));
			i = i + 3;
		}
	//cleanup
	n = roiManager("count");
	print("n0="+n);
	oarray = Array.getSequence(n);
	oarray = Array.slice(oarray,j+slices+1,n);
	todelete = Array.trim(todelete,j);
	todelete = Array.concat(todelete, oarray);
	roiManager("Select", todelete);
	//Array.show(todelete);
	roiManager("Delete");
}

function analyseSoma(tiff){
	//calculate soma results and store
	open(tiff);
	print("Slices:" + nSlices);
	roiManager("Select",0);
	print("select ROI: " + Roi.getName);
	setAutoThreshold("Default dark stack");
	//setThreshold(79, 255); //?too specific
	run("Analyze Particles...", "show=Overlay display clear include summarize in_situ stack");
	updateResults();
	IJ.renameResults("Soma results");
	//Counts
	counts = countParticles(0.03,0.50 );
	if (counts.length ==3){
		List.set("soma_total_count", counts[0]);
		List.set("soma_external_count", counts[1]);
		List.set("soma_internal_count", counts[2]);
	}
	//Parse results for totals
	selectWindow("Soma results");
	//Extract from summary: idx: area = 2 OR integrated density (=area * mean gray value) = 6
	//AREA DIMENSIONS
	labels=newArray("soma_total_area","soma_external_area", "soma_internal_area"); //Check channel order
	analysislist = parseResults(labels, List.getList(),"area");
	List.setList(analysislist);
	labels=newArray("soma_total_density","soma_external_density", "soma_internal_density");	
	analysislist = parseResults(labels, List.getList(),"density");
	List.setList(analysislist);
	
	close(); //don't save any changes
}

function analyseNeuron(tiff, basefilename){
	open(tiff);
	id = getImageID();
	createNeuronMask(basefilename);
	//Calulate areas within ROIs
	//edges = basefilename + ".tif" + " edges";
	tifname = basefilename + ".tif";
	print("Running image analysis="+tifname);
	run("Clear Results");	
	//Select masks per z-plane to compare channels
	selectImage(id);
	Stack.getDimensions(width, height, channels, slices, frames);
	print("Channels: " + channels + " Slices: " + slices + " Frames: " + frames);
	threshold = newArray( 76,51,19);

	s=1;
	n = roiManager("count");
	setOption("BlackBackground", true);
	for (c=1; c <= slices; c++){
		roiManager("Select",c);
		run("Make Inverse");
		print("select ROI: " + c + " " + Roi.getName);
		for(z=0; z < channels; z++){		
			print("channel: " + z + " - select slice: " + s);
			setSlice(s);
			setAutoThreshold("Default dark stack");
			//setThreshold(threshold[z], 255);
			run("Analyze Particles...", "show=Overlay display include in_situ summarize"); //no size limit
			updateResults();
			s = s+1;
		}
	}
	IJ.renameResults("All results");
	//Counts
	counts = countParticles(0.03,0.50 );
	if (counts.length ==3){
		List.set("total_count", counts[0]);
		List.set("external_count", counts[1]);
		List.set("internal_count", counts[2]);
	}
	//Parse Results
	selectWindow("All results");
	labels=newArray("total_area","external_area", "internal_area"); //Check order from LSM
	analysislist = parseResults(labels, List.getList(),"area");
	List.setList(analysislist);
	labels=newArray("total_density","external_density", "internal_density");	
	analysislist = parseResults(labels, List.getList(),"density");
	List.setList(analysislist);
	print("Summary fields= "+ List.size);
	//close();
	return List.getList();
}

function countParticles(min,max){
	print("Counting particles from " + min + " to " + max);
	counts = newArray(0,0,0);
	selectWindow("Results");
	//Count punta"size=0.03-0.50 circularity=0.80-1.00
	for(i=0; i < nResults; i++){
		size = parseFloat(getResult("Area",i));
		idx = parseInt(getResult("Ch",i)) - 1;
		if (size >= min && size <= max){
			counts[idx]++;
		}
	}
	//Array.show("Counts",counts);
	
	return counts;
}

//Extract from summary: idx: area = 2 OR integrated density (=area * mean gray value) = 6
function parseResults(labels, analysislist,type){
	List.setList(analysislist);
	lines = split(getInfo(), "\n");
	print("Summarizing Results:"+lines.length);
	//print("First line:" + lines[0]);
	Stack.getDimensions(width, height, channels, slices, frames);
	initval = 0;
	for (j=0; j< labels.length; j++){
		for(i=1+j; i<lines.length;i=i+channels){
			values = split(lines[i], "\t");
			s = values[0]; //slice
			if (type=="area"){
		  		a = parseFloat(values[2]); 
			}else if(type =="density"){
				//calculate integrated Density: area * mean pixel value
				//Note cannot use IntDens column as it is sum of means
				a = parseFloat(values[2]) * parseFloat(values[5]);
			}
		  	
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
	return List.getList();
}



