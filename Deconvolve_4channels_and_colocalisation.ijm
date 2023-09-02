// ImageJ macro to batch remove out of nucleus intensities based on DAPI mask
// then deconvolve images using theoretical PSF
// then measure colocalisation between green and red, green and fed as well as red and far red channels in 3D
// requires Coloc2 and Iterative Deconvolve 3D plugins
// requires the PFS files to be located in the root folder an
// select 2 directory for output
// after deconvolution, corresponding channels are merged in one multi-channel image

//########################
macro "Batch Coloc" 
	{
	
	dir1 = getDirectory("Choose Source Directory ");
	dir2 = getDirectory("Choose Results Directory ");
	
	// read in file listing from source directory
	list = getFileList(dir1);
	
	setBatchMode(true);
	// loop over the files in the source directory
	
	for (i=0; i<list.length; i++)
		{
		if (endsWith(list[i], ".tif"))
			{
			filename = dir1 + list[i];
			imagename = list[i];		
			open(filename);
			rename("image");
			run("Split Channels");
			selectWindow("C4-image");
			rename("DAPI");
			selectWindow("C3-image");
			rename("rawGreen");
			selectWindow("C2-image");
			rename("rawRed");
			selectWindow("C1-image");
			rename("rawAF647");
			selectWindow("DAPI");
			
			//generate DAPI mask
			setAutoThreshold("Otsu dark stack");
			run("Convert to Mask", "method=Otsu background=Dark calculate black");
			run("Options...", "iterations=1 count=1 black do=[Fill Holes] stack");
			run("Options...", "iterations=3 count=1 black do=Dilate stack");
			run("Divide...", "value=255.000 stack");
			
			//remove the signal outside nucleus
			imageCalculator("Multiply create stack", "rawRed","DAPI");
			rename("redBGremove");
			imageCalculator("Multiply create stack", "rawGreen","DAPI");
			rename("greenBGremove");
			imageCalculator("Multiply create stack", "rawAF647","DAPI");
			rename("AF647BGremove");

			// Deconvolution
			open(dir1+"PSF_488_SPE_63x.tiff");
			rename("PFSgreen");
			open(dir1+"PSF_561_SPE_63x.tiff");
			rename("PFSred");
			open(dir1+"PSF_635_SPE_63x.tiff");
			rename("PFSfarRed");
			run("Iterative Deconvolve 3D", "image=[redBGremove] point=PFSgreen output=Deconvolved normalize show log perform detect wiener=0.000 low=1 z_direction=1 maximum=5 terminate=0.010");
			rename("deconvRed");
			run("8-bit");
			run("Iterative Deconvolve 3D", "image=[greenBGremove] point=PFSred output=Deconvolved normalize show log perform detect wiener=0.000 low=1 z_direction=1 maximum=5 terminate=0.010");
			rename("deconvGreen");	
			run("8-bit");		
			run("Iterative Deconvolve 3D", "image=[AF647BGremove] point=PFSfarRed output=Deconvolved normalize show log perform detect wiener=0.000 low=1 z_direction=1 maximum=5 terminate=0.010");
			rename("deconvAF647");	
			run("8-bit");

//

			// Restore threshold of DAPI-mask, DAPI-mask will be used in deconvolution
			selectWindow("DAPI");
			run("Duplicate...", "title=DAPI-mask duplicate");
			setThreshold(1, 255);
			run("Convert to Mask", "method=Default background=Default black");

			
			// Colocalisation analysis between red and far red channels
			run("Coloc 2", "channel_1=deconvRed channel_2=deconvAF647 roi_or_mask=DAPI-mask threshold_regression=Bisection display_shuffled_images li_histogram_channel_1 li_histogram_channel_2 spearman's_rank_correlation manders'_correlation 2d_intensity_histogram psf=3 costes_randomisations=3");
			// save results
			selectWindow("Log");
			saveAs("Text", dir2 + imagename+ "-coloc_Red_AF647_results.txt");
			run("Close");

			// Colocalisation analysis between green and far red channels
			run("Coloc 2", "channel_1=deconvGreen channel_2=deconvAF647 roi_or_mask=DAPI-mask threshold_regression=Bisection display_shuffled_images li_histogram_channel_1 li_histogram_channel_2 spearman's_rank_correlation manders'_correlation 2d_intensity_histogram psf=3 costes_randomisations=3");
			selectWindow("Log");
			saveAs("Text", dir2 + imagename+ "-coloc_Green_AF647_results.txt");
			run("Close");
			
			// Colocalisation analysis between red and green channels
			run("Coloc 2", "channel_1=deconvGreen channel_2=deconvRed roi_or_mask=DAPI-mask threshold_regression=Bisection display_shuffled_images li_histogram_channel_1 li_histogram_channel_2 spearman's_rank_correlation manders'_correlation 2d_intensity_histogram psf=3 costes_randomisations=3");
			selectWindow("Log");
			saveAs("Text", dir2 + imagename+ "-coloc_Green_Red_results.txt");
			run("Close");
			
			// save  deconvolved images
			run("Merge Channels...", "c1=deconvRed c2=deconvGreen c3=DAPI-mask c6=deconvAF647 create");
			saveAs("Tiff", dir2 + imagename + "-deconv.tif");

			
			// close the rest
			close('*');
			
			
			}
		}
	}


			
