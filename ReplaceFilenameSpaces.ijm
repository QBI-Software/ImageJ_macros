function replaceSpaces(dir, filename){
	if (File.exists(dir + filename)){
		print("File exists:" + dir + filename);

		if (indexOf(filename, " ") > 0){
			print("found space");
			filename1 = replace(filename," ","_");
			print(dir + filename1);
			f1 = dir + filename;
			f2 = dir + filename1;
			if (File.rename(f1,f2) == 1){
				filename = filename1;
				print("New file: " + filename);
			} else{
				print("Didn't work");
			}
			
		}
	}else{
		print("can't find file:" + dir + filename);
	}
	return filename;
}