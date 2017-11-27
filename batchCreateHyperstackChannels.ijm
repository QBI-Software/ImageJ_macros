/*
 Title: batchCreateHyperstackChannels
 * Macro to process multiple sequences of images in a directory into hyperstacks grouped by matching filename 
 * Modified for use with multiple channels - note that in the test data, the order was initially incorrect - this may not always be the case.
 * Usage Steps:
 * 1. Select input files directory
 * 2. Select output directory
 * 3. Check the basename delimiter - change or accept
 *   (ie it will truncate at this - case-sensitive, eg "_z")
 * 4. Hyperstack files will be written to output directory
 * 5. Troubleshooting: Check Log output window in ImageJ
 * 
 * Modifications:
 * 1. Added option for Snake Tile numbering (see comments below) - filename format is crucial!
 * 2. Added option to use thresholding
 * 3. Removed colorization of channels
 * 4. Merged single channels with autodetection of number of channels
 * 5. MOD Oct2016: Split multichannel images
 * 6. MOD Jul2017: Reversed xy for snaketile numbering, added verbose msgs
 * 7. MOD Oct2017: Option to output to single directory
 * (Contact: Liz Cooper-Williams, QBI e.cooperwilliams@uq.edu.au)
 */

requires("1.51d");

input = getDirectory("Input directory");
output = getDirectory("Output directory");


Dialog.create("Base filename ends at");
suffix = "_z";
Dialog.addString("File suffix: ", suffix, 5);
Dialog.addCheckbox("SnakeTile numbering", 0);
Dialog.addCheckbox("Adjust threshold", 0);
Dialog.addCheckbox("Verbose", 0);
Dialog.addCheckbox("Single directory output", 0);
Dialog.addCheckbox("Top level directory",0);
Dialog.show();
suffix = Dialog.getString();
snt = Dialog.getCheckbox();
print("Snaketile:" + snt);
adjust = Dialog.getCheckbox();
print("Adjust threshold: " + adjust);
verbose = Dialog.getCheckbox();
print("Verbose msgs: " + verbose);
singledir = Dialog.getCheckbox();
print("Single output directory: " + singledir);
toplevel = Dialog.getCheckbox();
start=0;

if (toplevel){
	print("Top level directory");
	dirlist = getFileList(toplevel);
	for (i=0; i < dirlist.length; i++){
		if (File.isDirectory(input + dirlist[i])){
			print("Processing directory:" + input + dirlist[i]);
			processFolder(suffix, snt, adjust, input + dirlist[i],verbose);
		}

	}
	
}else{
	processFolder(suffix, snt, adjust, input,verbose);
}
exit("Finished");

function processFolder(suffix, snt, adjust, input,verbose) {
    print("Starting folder processing: " + input);
	list = getFileList(input);
	print("Total entries in directory:" + list.length);
	multi = hasMultipleChannels(input,verbose);
	if (snt){
		snaketiles = getSnakeTileList(list,verbose);
	}else{
		snaketiles = newArray();
	}
	stacklist = newArray(list.length); //initial stack
	j = 0; //counter per list
	n = 0; //count of hyperstacks
	l = 0; //cumulative list size ie already processed
	filename = "";
	outfilename = "";
	for (i = 0; i < list.length; i++) {
		if (!File.isDirectory(input + list[i])){
			if ((lengthOf(filename) > 0) && startsWith(list[i], filename)){
				j++;
				stacklist[j]= input + list[i];
				
			} else {
				if (j > 0) {
					stacklist = Array.slice(stacklist, 0, j+1);
					if (snaketiles.length > 0){
						outfilename = snaketiles[n];
						print("Setting filename from: " + filename + " to " + outfilename);
						n++;
					}
					processStack(input, stacklist, output, filename, outfilename, adjust, multi,verbose, singledir);
					
					l += stacklist.length;
					stacklist = newArray(list.length - l);
				}
				filename = getRootFilename(suffix, list[i]);
				j = 0;
				
				stacklist[j]= input + list[i];
			}
			//showProgress(i, list.length);
		}else{
			//print("File is directory");
			
		}
	}
	//last one
	if (stacklist.length > 0){
		stacklist = Array.slice(stacklist, 0, j+1);
		//print("Last stack: " + stacklist.length);
		if (snaketiles.length > 0){
			outfilename = snaketiles[n];
			print("Setting filename from: " + filename + " to " + outfilename);
		}
		processStack(input, stacklist, output, filename, outfilename, adjust, multi,verbose, singledir);
	}
}


//If problems with base filename - uncomment print statements to debug
function getRootFilename(suffix, fname){
	//print("Filename:" + fname);
	idx = lastIndexOf(fname, suffix);
	if (idx < 0){
		exit("Error: Problem with filenames")
	}
	//print("Suffix:" + idx);
	rootfname = substring(fname, 0, idx);
	//print("Base Filename:" + rootfname);
	return rootfname;
}

function getRegex(){
	re = "tile_x0+([0-9])_y0+([0-9]).*$";
	return re;
}

function getFirstFile(inputdir,verbose){
	firstfile="";
	list = getFileList(inputdir);
	if (verbose){
		print("getFirstFile: list=" + list[0]);
	}
	re = getRegex();
	//assumes last file has total rows, cols
	for (i = 0; i < list.length; i++) {
		//includes filepath
		if (matches(list[i],re)){
			firstfile = list[i];
			if (verbose){
				print("First filename:" + firstfile);
			}
			//idx = i;
			i = list.length; //break
			
		}else{
			if (verbose){
				print("Not matched=" + list[i]);
			}
		}
	}
	return firstfile;
}

function getLastFile(list,verbose){
	lastfile="";
	re = getRegex();
	//assumes last file has total rows, cols
	for (i = list.length - 1; i > 0; i--) {
		if (matches(list[i],re)){
			lastfile = list[i];
			if (verbose){
				print("Last filename:" + lastfile);
			}
			idx = i;
			i = 0; //break
			
		}
	}
	return lastfile;
}
//Returns number of channels or O if not multiple
function hasMultipleChannels(inputdir,verbose){
	rtn = 0;
	firstfile = getFirstFile(inputdir,verbose);
	print("Multiplechannels: checkfile=" + inputdir + firstfile);
	open(inputdir + firstfile);
	Stack.getDimensions(width, height, channels, slices, frames);
	print("Channels: " + channels + " Slices: " + slices + " Frames: " + frames);

	if (channels > 1 || slices > 1){
		if (channels > slices){
			rtn = channels;
		}else{
			rtn = slices;
		}
	}
	close();
	return rtn;
}

/* Snake tile numbering
x001_y001, x002_y001, x003_y001, x004_y001
x001_y002, x002_y002, x003_y002, x004_y002
x001_y003, x002_y003, x003_y003, x004_y003
=
Tile001, Tile002, Tile003, Tile004
Tile008, Tile007, Tile006, Tile005
Tile009, Tile010, Tile011, Tile012
*/
function getSnakeTileList(list,verbose){
	outlist = newArray();
	x=0;
	y=0;
	lastfile=getLastFile(list,verbose);
	
	if(lengthOf(lastfile) > 0){
		parts=split(lastfile, "_"); 
		for (j=0; j<parts.length; j++){
			//print(parts[j]);
			if (startsWith(parts[j], "x")){
				x1 = parseInt(substring(parts[j], 1));
				if (x1 > x){
					x = x1;
					print("x=" + x);
				}			
			}
			if (startsWith(parts[j], "y")){
				y1 = parseInt(substring(parts[j], 1));
				if (y1 > y){
					y = y1;
					print("y=" + y);
				}
			}
		}
		
		//determine number rows & columns
		//reversed xy for this process
		print("Rows= " + y + " Cols=" + x);
		//generate numbers
		outlist = newArray(y*x);
		odd = 0;
		ctr=x;
		for (k=0; k < outlist.length; k++){
			if (k%x == 0){
				odd = !odd; //toggle
				ctr = k; 
			}
			if(odd){
				outlist[k] = "Tile" + leftPad(k+1,3);
			}else{
				num = ctr+x-(k%x);
				outlist[k] = "Tile" + leftPad(num,3);
			}
			
		}
		
		snaketilelist= transpose(x, outlist);
		//Reorder to reflect alphanumeric sorted filenames 
		Array.show(snaketilelist);
	}else{
		print("Unexpected filename format - unable to use Snake Tile Numbering");
	}
	return snaketilelist;
	
}


function transpose(cols, outlist){
	sorted = newArray(outlist.length);

	c=0;
	for (i=0; i < cols; i++){
		for (k=0; k < outlist.length; k=k+cols){
			sorted[c] = outlist[k+i];
			//print("k="+k + " i=" +i + " k+i=" + k+i);
			c++;
		}
	}
	//Array.show(sorted);
	return sorted;
}
function leftPad(n, width) {
  s =""+n;
  while (lengthOf(s)<width){
      s = "0"+s;
  }
  return s;
}

function runadjustments(){
	setBatchMode(true);
	print("Stack is HyperStack: Adjusting contrast");
	getDimensions(w, h, channels, slices, frames);
	for (t=1; t<=frames; t++) {
	 for (z=1; z<=slices; z++) {
	    for (c=1; c<=channels; c++) {
	       Stack.setPosition(c, z, t);
	       run("Enhance Contrast", "saturated=0.35");
	    }
	 }
	}
		
	setBatchMode(false);
	Stack.setPosition(1, 1, 1);
}

//Create Hyperstack from list
function processStack(inputdir,input, output, file, outfilename, adjust, multi, verbose, singledir) {
	/*Set output filename*/
	if (lengthOf(outfilename) > 0){
		outputfile = output + outfilename + ".tif";
	}else{
		outputfile = output + file + ".tif";
	}
	if (verbose){
		print("Processing: " + input.length + " files");
	}
	if (multi > 0){
		print("Multiple channels - using Bio-formats");

		/*tile_x00<1-4>_y00<1-4>_z0<01-29>.tif*/
		bfname = inputdir + file + "_z00<1-" + input.length + ">.tif";
		if (input.length >=10 && input.length <=99){
			bfname = inputdir + file + "_z0<01-" + input.length + ">.tif";
		}else if (input.length >=100){
			bfname = inputdir + file + "_z<001-" + input.length + ">.tif";
		}
		run("Bio-Formats", "open=[" + input[0] + "] color_mode=Default group_files split_channels open_files view=Hyperstack stack_order=XYCZT swap_dimensions use_virtual_stack axis_1_number_of_images=" + input.length + " axis_1_axis_first_image=1 axis_1_axis_increment=1 z_1=" + input.length + " c_1="+multi+" t_1=1 contains=[" + file + "] name=[" + bfname + "]");
		if (singledir){
			for (c=0; c< multi; c++) {
				chanDir = "C" + c + "_";
				if (verbose){
					print("Channel=" + chanDir);
				}
				
				imageTitle=getTitle();
				if (verbose){
					print("Image title=" + imageTitle);
				}
				i = lastIndexOf(imageTitle,"="); 
				rootImageTitle = substring(imageTitle, 0, i);
				selectWindow(rootImageTitle + "="+c);
				outputfile = output + File.separator + chanDir + outfilename + ".tif";
				if (adjust && Stack.isHyperStack){
					runadjustments();
				}
				saveAs("tiff", outputfile);
				close();
				print("Saved to: " + outputfile);
	
			}
		}else{
			/* Split channels into separate directories */	
			for (c=0; c< multi; c++) {
				chanDir = "ch" + c;
				if (verbose){
					print("Channeldir="+ output+chanDir);
				}
				if (!File.exists(output + chanDir)){
					File.makeDirectory(output + chanDir); 
				}
				imageTitle=getTitle();
				if (verbose){
					print("Image title=" + imageTitle);
				}
				i = lastIndexOf(imageTitle,"="); 
				rootImageTitle = substring(imageTitle, 0, i);
				selectWindow(rootImageTitle + "="+c);
				outputfile = output + chanDir + File.separator + outfilename + ".tif";
				if (adjust && Stack.isHyperStack){
					runadjustments();
				}
				saveAs("tiff", outputfile);
				close();
				print("Saved to: " + outputfile);
	
			}
		}
	}else{
		print("Single channels - using Image sequence");
		if (verbose){
			print("Input:" + input[0] + " Matching: " + file);
		}
		run("Image Sequence...", "open=[" + input[0] + "] file=" + file + " sort use");
		if (adjust && Stack.isHyperStack){
			runadjustments();
		}
		saveAs("tiff", outputfile);
		close();
		print("Saved to: " + outputfile);
	}

}
