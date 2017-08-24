function getThresholdColors(){
	run("Color Histogram");
	selectWindow("Results");
	summarylines = split(getInfo(), "\n");
	threshold = newArray(3);
	print("length = ", summarylines.length-1);
	for (i=0; i < summarylines.length-1; i++){
		//values = split(summarylines[i], "\t");
		mean = getResult("mean",i);
		threshold[i]=mean - (mean * 0.1);
		print("result=", i, "=", threshold[i]);
	}
	print("saved ", threshold.length);
	return threshold;
}
