/*  Colocalization Scatter
 *   This macro analyses the colocalization of neuron labelling in each channel of an RGB stack
 *   Developed for the Anggono Lab, QBI
 *   
 *   Steps: 1. Opens TIFF RGB image
 *          2. Splits channels into Red, Green, Blue (Total, External and Internal labelling respectively)- saved tifs
 *          3. Compares Colocalization of each channel pair with scatter plots of pixel intensities
 *          4. Summarizes coefficients and outputs to Excel file
 *          
 *   Requirements: 
 *   	1. Colocalization Threshold plugin (under Analyze menu)
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
//Load 3 channel image
//labels=newArray("total","external", "internal"); //Check order from LSM
path = File.openDialog("Select TIF Image");
dir = File.getParent(path);
name = File.getName(path);
basename = File.nameWithoutExtension();
filesep =File.separator; //"\\"; //WIndows users - CHANGE THIS TO "/" if MAC or Unix user
open(path);
info = getImageInfo();
Stack.getDimensions(width, height, channels, slices, frames)
print("Info: " + info);
print("Channels: " + channels);
if (channels <= 1){
	run("RGB Stack");
	run("Make Composite", "display=Color");
}
//Split into channels and rename
run("Split Channels");
run("Window/Level...");
run("Enhance Contrast", "saturated=0.35");
rename("Blue");
saveAs(dir + File.separator + "Blue.tif");
selectWindow("C2-"+name);
run("Window/Level...");
run("Enhance Contrast", "saturated=0.35");
rename("Green");
saveAs(dir + File.separator + "Green.tif");
selectWindow("C1-"+name);
run("Window/Level...");
run("Enhance Contrast", "saturated=0.35");
rename("Red");
saveAs(dir + File.separator + "Red.tif");
//Check that images have something in them
labels = checkImages();
combolabels = createCombos(labels);
print(combolabels.length);
// Run "Colocalization Threshold"
//Accepts "Red:Green Red:Blue Green:Blue"
for (i=0; i< combolabels.length; i++){
	channel = combolabels[i];
	idx = indexOf(channel, ":");
	c1 = substring(combolabels[i], 0, idx -1) + ".tif";
	c2 = substring(combolabels[i], idx + 2) + ".tif";
	print("channel=" + channel + " c1=" + c1 + " c2=" + c2);
	open(dir + File.separator + c1 );
	open(dir + File.separator + c2 );
	run("Clear Results");
	
	//if (channelcombos(channel)){ 
		run("Colocalization Threshold", "channel_1=[" + c1 + "] channel_2=[" + c2 + "] use=None channel=[" + channel + "] show use include set pearson's mander's number % % % %");
		selectWindow("Colocalized Pixel Map RGB Image");
		rename(channel + " colocalisation");
		//updateResults();
	//}
}
/*
run("Colocalization Threshold", "channel_1=[Blue] channel_2=[Green] use=None channel=[Green : Blue] show use include set pearson's mander's number % % % %");
selectWindow("Colocalized Pixel Map RGB Image");
rename("Internal-External (Blue-Green) colocalisation");
run("Colocalization Threshold", "channel_1=[Red] channel_2=[Blue] use=None channel=[Red : Blue] show use include set pearson's mander's number % % % %");
selectWindow("Colocalized Pixel Map RGB Image");
rename("Total-Internal (Red-Blue) colocalisation");
*/
//Save Results
selectWindow("Results");
saveAs("Text", dir + filesep + basename + "_ColocalisationResults.xls");

function checkImages(){
	labels=newArray("Red","Green", "Blue"); 
	s1  = "";
	delim = ";";
	setOption("BlackBackground", true);
	setBatchMode(true); 
	for (j=0; j< labels.length; j++){
		selectWindow(labels[j]);
		setAutoThreshold("RenyiEntropy dark");
		run("Analyze Particles...", "pixel show=Overlay display include summarize in_situ");
		//selectWindow(labels[j]);
		//run("Close");
		
	}
	setBatchMode(false); 
	selectWindow("Summary");
	lines = split(getInfo(),"\n");
	//initval = 0;	
	for(i=1; i < lines.length; i++){
		print(lines[i]);
		values = split(lines[i], "\t");
		s = values[0]; //slice
		a = values[1]; //count
		print(s + "=" + a);
		if (a > 0){
			s1 = s1 + s + delim;
		}
	}
	//clearResults
	selectWindow("Results");
	run("Close");
	
	print("Checklabels=" + s1);
	idx = lastIndexOf(s1,delim);
	s = substring(s1,0, idx);
	checkedlabels = split(s,delim); 
	return checkedlabels;
}

function createCombos(labels){
	s = "";
	delim = ";";
	Array.concat(labels, labels[0]);
	for (i=0; i< labels.length; i++){
		for (j=i+1; j< labels.length; j++){
			print(labels[i] + " : " + labels[j]);
			s = s+ labels[i] + " : " + labels[j] + delim;
		}
	}
	idx = lastIndexOf(s,delim);
	s = substring(s,0, idx);
	combolabels = split(s,delim);
	
	return combolabels;
}

function channelcombos(checkme){
	labels=newArray("Red : Green", "Red : Blue", "Green : Blue");
	rtn = 0;
	for (j=0; j< labels.length; j++){
		if(checkme == labels[j]){
			rtn = 1;
			j = labels.length; //break
		}
	}
	return rtn;
}
