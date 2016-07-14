/*
 * Macro to process multiple sequences of images in a directory into hyperstacks grouped by matching filename 
 * Usage Steps:
 * 1. Select input files directory
 * 2. Select output directory
 * 3. Check the basename delimiter - change or accept
 *   (ie it will truncate at this - case-sensitive, eg "_z")
 * 4. Hyperstack files will be written to output directory
 * 5. Troubleshooting: Check Log output window in ImageJ
 * (Contact: Liz Cooper-Williams, QBI e.cooperwilliams@uq.edu.au)
 */

input = getDirectory("Input directory");
output = getDirectory("Output directory");

Dialog.create("Base filename ends at");
suffix = "_z";
Dialog.addString("File suffix: ", suffix, 5);
Dialog.show();
suffix = Dialog.getString();


processFolder(suffix, input);

function processFolder(suffix, input) {
	list = getFileList(input);
	filename = getRootFilename(suffix, list[0]); //initial file
	stacklist = newArray(list.length); //initial stack
	j = 0; //added counter
	l = 0; //cumulative list size ie already processed
	for (i = 0; i < list.length; i++) {
		if(startsWith(list[i], filename)){
			stacklist[i-j]= input + list[i];
			j++;
		} else {
			stacklist = Array.slice(stacklist, 0, j);
			processStack(stacklist, output, filename);
			filename = getRootFilename(suffix, list[i]);
			j = 1;
			l += stacklist.length;
			stacklist = newArray(list.length - l);
			stacklist[i-l]= input + list[i];
		}
		showProgress(i, list.length);
	}
	//last one
	if (stacklist.length > 0){
		//print("Last Process stack");
		processStack(stacklist, output, filename);
	}
}

//If problems with base filename - uncomment print statements to debug
function getRootFilename(suffix, fname){
	//print("Filename:" + fname);
	idx = lastIndexOf(fname, suffix);
	//print("Suffix:" + idx);
	rootfname = substring(fname, 0, idx);
	print("Base Filename:" + rootfname);
	return rootfname;
}

function processStack(input, output, file) {
	outputfile = output + "Stack_" + file + ".tif";
	print("Processing: " + input.length + " files");
	run("Bio-Formats", "open=[" + input[0] + "] color_mode=Default group_files open_files view=Hyperstack stack_order=XYCZT use_virtual_stack axis_1_number_of_images=" + input.length + " axis_1_axis_first_image=1 axis_1_axis_increment=1 contains=[" + file + "] name=[]");
	saveAs("tiff", outputfile);
	close();
	print("Saved to: " + outputfile);
}
