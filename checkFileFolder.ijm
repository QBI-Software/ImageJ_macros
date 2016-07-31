input = getDirectory("Input directory");
print("Input dir=" + input);
if (input == "")
      exit("Exiting: Please enter a directory");

      
Dialog.create("Base filename ends at");
suffix = "_z";
Dialog.addString("File suffix: ", suffix, 5);
Dialog.show();
suffix = Dialog.getString();


processFolder(suffix, input);

function processFolder(suffix, input) {
	list = getFileList(input);
	filename = getRootFilename(suffix, list[0]); //initial file
	for (i = 0; i < list.length; i++) {
		if (!File.isDirectory(input + list[i])){
			print("Filename:" + input + list[i]);
			f = open(input+list[i]);
		}else{
			print("Directory");
		}
	}
	//if (!File.exists(input + filename)){
	//	exit("Exiting: This file is not accessible: " + filename);
	//}
}


//If problems with base filename - uncomment print statements to debug
function getRootFilename(suffix, fname){
	
	print("Filename:" + fname);
	idx = lastIndexOf(fname, suffix);
	print("Suffix:" + idx);
	rootfname = substring(fname, 0, idx);
	print("Base Filename:" + rootfname);
	return rootfname;
}

	
