/*
 * Macro to process multiple sequences of images in a directory into hyperstacks grouped by matching filename 
 * Modified for use with multiple channels - note that in the test data, the order was initially incorrect - this may not always be the case.
 * Usage Steps:
 * 1. Select input files directory
 * 2. Select output directory
 * 3. Check the basename delimiter - change or accept
 *   (ie it will truncate at this - case-sensitive, eg "_z")
 * 4. Hyperstack files will be written to output directory
 * 5. Troubleshooting: Check Log output window in ImageJ
 * (Contact: Liz Cooper-Williams, QBI e.cooperwilliams@uq.edu.au)
 */
requires("1.51d");

input = getDirectory("Input directory");
output = getDirectory("Output directory");

Dialog.create("Base filename ends at");
suffix = "_z";
Dialog.addString("File suffix: ", suffix, 5);
Dialog.show();
suffix = Dialog.getString();
start=0;


processFolder(suffix, input);
exit("Finished");

function processFolder(suffix, input) {
    print("Starting folder processing: " + input);
	list = getFileList(input);
	print("Total entries in directory:" + list.length);
	stacklist = newArray(list.length); //initial stack
	j = 0; //added counter
	l = 0; //cumulative list size ie already processed
	filename = "";
	for (i = 0; i < list.length; i++) {
		if (!File.isDirectory(input + list[i])){
			if ((lengthOf(filename) > 0) && startsWith(list[i], filename)){
				j++;
				stacklist[j]= input + list[i];
				
			} else {
				if (j > 0) {
					stacklist = Array.slice(stacklist, 0, j+1);
					processStack(input,stacklist, output, filename);
					l += stacklist.length;
					stacklist = newArray(list.length - l);
				}
				filename = getRootFilename(suffix, list[i]);
				j = 0;				
				stacklist[j]= input + list[i];
			}
			//showProgress(i, list.length);
		}else{
			print("File is directory");
		}
	}
	//last one
	if (stacklist.length > 0){
		stacklist = Array.slice(stacklist, 0, j+1);
		//print("Last stack: " + stacklist.length);
		processStack(input,stacklist, output, filename);
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
	print("Base Filename:" + rootfname);
	return rootfname;
}

function processStack(inputdir,input, output, file) {
	outputfile = output + "Stack_" + file + ".tif";
	print("Processing: " + input.length + " files");
	bfname = inputdir + file + "_z00<1-" + input.length + ">.tif";
	run("Bio-Formats", "open=[" + input[0] + "] color_mode=Default group_files open_files view=Hyperstack stack_order=XYCZT swap_dimensions use_virtual_stack axis_1_number_of_images=" + input.length + " axis_1_axis_first_image=1 axis_1_axis_increment=1 z_1=9 c_1=3 t_1=1 contains=[" + file + "] name=[" + bfname + "]");
	// Adjust brightness and color channels
	setBatchMode(true);
	if (Stack.isHyperStack){
      print("Stack is HyperStack: Adjusting color");
      //print("Get Dimensions");
      getDimensions(w, h, channels, slices, frames);
      for (t=1; t<=frames; t++) {
	     for (z=1; z<=slices; z++) {
	        for (c=1; c<=channels; c++) {
	           Stack.setPosition(c, z, t);
	           run("Enhance Contrast", "saturated=0.35");
	           if (c == 1){
	           	run("Red");
	           }else if (c == 2){
	           	run("Green");
	           }else{
	           	run("Blue");
	           }
	           
	           wait(20);
	        }
	     }
      }
      Stack.setPosition(1, 1, 1);	
	  setBatchMode(false);
	}
	saveAs("tiff", outputfile);
	close();
	print("Saved to: " + outputfile);
}
