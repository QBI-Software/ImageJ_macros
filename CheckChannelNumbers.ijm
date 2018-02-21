/*  CheckChannelNumbers
 *   This macro runs through tiffs and checks whether they have less than 3 channels
 *   Developed for QBI
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

filelist = getFileList(dir);
setBatchMode(true);
print("***Starting macro ...");
for(j=0;j<filelist.length;j++){
	fname = filelist[j];
	/* Specific for Dana's images - change here */
	if (startsWith(fname,"Overlay")){
		continue;
	}
	if (indexOf(fname, ".tif")> 0){
		open(fname);
		Stack.getDimensions(width, height, channels, slices, frames);
		if (channels < 3){
			print("File: "+ fname + " Channels: " + channels);
		}
	}

}
setBatchMode(false);
print("***Finished***");
