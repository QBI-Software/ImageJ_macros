/*  batchConvertOMETiff
 *   This macro converts OME-TIFF to TIFF with 3 channels
 *   Developed for QBI (c) 2017
 *   
 *      
 *      Run this macro (recommend a freshly opened ImageJ):
 *      	1. Select the input directory (should only contain original images)
 *      	2. Select the output directory
 *      	3. Batch Processing will run as
 *          	a. Opens with BioFormats in Composite mode
 *          	b. Converts to RGB then separates channels
 *          	c. Saves to Tiff
 *    Note: will preserve original grayscale      
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

filesep = File.separator; 
dir1 = getDirectory("Choose input directory");
outputdir = getDirectory("Choose output directory");
filelist = getFileList(dir1);

setBatchMode(true);

//Batch run - if not required can comment out
for(j=0;j<filelist.length;j++){
	inputfile = dir1 + filelist[j];
  	if (!File.isDirectory(inputfile)){
		if (endsWith(filelist[j], ".ome.tif")){
			print("Input:", filelist[j]);
			showProgress(j+1, filelist.length);	
			run("Bio-Formats", "open=[" + inputfile + "] color_mode=Composite view=Hyperstack stack_order=XYCZT use_virtual_stack contains=[] name=[" + inputfile + "]");
  			  			
  			//Config settings
			setOption("BlackBackground", true);
			//run("Channels Tool...");
			run("Stack to RGB");
  			run("RGB Stack");		
			outname = replace(filelist[j], ".ome.tif",".tif");
			print("Output:", outname);
			saveFile(outputdir + filesep + outname);
			//Clean up windows
			run("Close All"); 
		}
	}
}
  
  

showStatus("Finished");
setBatchMode(false);

function saveFile(outFile) {
	saveAs("Tiff", outFile);
   //run("Bio-Formats Exporter", "save=[" + outFile + "] compression=LZW");
}