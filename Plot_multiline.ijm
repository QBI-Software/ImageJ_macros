// macro to make line plots
// will select different colours to plot
// handles 8, 16 and 32 bit images as well as maximal 7 channels

// version 4.1; Solved problem with x-coordinates in scaled images. 
// version 4.2; Thanks to Michael Epping (mailinglist 15-05-2013) the X-scale on  
// the scaled plot is also drawn correctly.
// version 4.3; The plot is now scaled depending on the channels selected by the user.
// The colour for each channel is first detected followed by selection of the
// colours by the user instead of the user has to select channel numbers. 
// Ref: https://www2.le.ac.uk/colleges/medbiopsych/facilities-and-services/cbs/lite/aif/software-1/imagej-macros#Multi colour profile
// Kees Straatman, University of Leicester, 19 January 2014

macro plot_multicolour{
	setTool("line");
	if (isOpen("ROI Manager")) {
     		selectWindow("ROI Manager");
    		 run("Close");
  	}
	inv = false; 		 // To check if LUT is inverted
	p = 0; 			 //Counter for presence of plot
	intensityBottom=0;
	color = "black";
	getVoxelSize(vw, vh, vd, unit);
	
	// Check that there is a line selection
	do{
		type = selectionType();
		if (type!=5){
			title="Warning";
			msg="The macro needs a line selection.\nMake a line selection and click \"OK\"";
			waitForUser(title, msg);
		}
	wait(100);
	}while(type!=5);
	getLine(x1, y1, x2, y2, lineWidth);

	// Parameters for the plot
	dx = (x2-x1)*vw; 
	dy = (y2-y1)*vh;
	maxT=0;
	minT=100000000;
	Stack.getDimensions(width, height, channels, slices, frames);

	if (bitDepth==24){
		if (nSlices>1){
			roiManager("Add");
			run("Make Composite");
			wait(100);  // Line is sometimes not transfered to the new image
			setVoxelSize(vw, vh, vd, unit);
			roiManager("select", 0);
			//wait(100);
			selectWindow("ROI Manager");
			run("Close");
		}else{
			run("Make Composite");
		}
	}

	Stack.getDimensions(width, height, channels, slices, frames); // need to repeat because of creation of new composite
	channel = newArray(channels);
	color=newArray(channels+1);

	// to allow single channel profile in color
	for (i=0; i<channels;i++)
		channel[i]=true;

	for (i=1; i<=channels; i++){
		// Solve problem with inverted images (blobs)
		if (is("Inverting LUT")){
			run("Invert LUT");
			inv=true;
		}
		if (channels>1) Stack.setChannel(i); 
		getLut(reds, greens, blues);
		if ((reds[i]==i)&&(greens[i]==0)&&(blues[i]==0)) color[i] = "red";
		if ((reds[i]==0)&&(greens[i]==i)&&(blues[i]==0)) color[i] = "green";
		if ((reds[i]==0)&&(greens[i]==0)&&(blues[i]==i)) color[i] = "blue";
		if ((reds[i]==0)&&(greens[i]==i)&&(blues[i]==i)) color[i] = "cyan";
		if ((reds[i]==i)&&(greens[i]==0)&&(blues[i]==i)) color[i] = "magenta";
		if ((reds[i]==i)&&(greens[i]==1)&&(blues[i]==0)) color[i] = "yellow";
		if ((reds[i]==i)&&(greens[i]==i)&&(blues[i]==i)) color[i] = "gray";
	}
	if (inv) run("Invert LUT"); // reset inverted image

	// Select channels to plot
	if (channels > 1){
		Dialog.create("channels");
			Dialog.addMessage("Which channels do you want to plot?");
			for (i=0; i<channels;i++){
				Dialog.addCheckbox(color[i+1], true);
			}
		Dialog.show();
		setBatchMode(true);
		for (i=0; i<channels;i++){
			channel[i] = Dialog.getCheckbox();
			
		}
	}

	// Collect data for minimal and maximal values of the selected channels for the plot
	if ((Stack.isHyperstack)||(is("composite"))){
		Stack.getDimensions(width, height, channels, slices, frames); // need to repeat because of creation of new composite
		for (i=1; i<=channels;i++){
			if(channel[i-1]==true){
				Stack.setChannel(i);
				profile = getProfile();
 				for (j=0; j<profile.length; j++){
    					if (maxT<profile[j]) maxT=profile[j];
					if(profile[j]<minT) minT=profile[j];
				}
			}
		}
	}else{
		channels = 1;
		profile = getProfile();
 		for (j=0; j<profile.length; j++){
    			if (maxT<profile[j]) maxT=profile[j];
			if(profile[j]<minT) minT=profile[j];
		}
	}
	intensityTop=maxT;
	intensityBottom=minT;

	// Check if channel is selected. 
	for (i=1; i<=channels; i++){
		if (channels>1) Stack.setChannel(i); 
		if(channel[i-1]==true){
				
			// Plot different colours
			if (p==0){
				profile=getProfile();
				Plot.create("multi Channel Plot", "Distance("+unit+")", "Intensity"); 
				Plot.setLimits(0,sqrt(dx*dx+dy*dy),intensityBottom,intensityTop);
				p=1;
			}

			// Scale the profiles for correct x-coordinates
			run("Plot Profile");
  			Plot.getValues(x, y);
  			close();
			Plot.setColor(color[i]); 
			Plot.add("line",x,y); 
		}
	}
		
}

