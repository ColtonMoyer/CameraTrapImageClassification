This is a four step process consisting of two r scripts. 

The first script "rename_AND_fix_incorrect_times" uses the exiftool and camtrapR to rename CT images using a consistent file scheme. It is important 
to rename images so that there are not duplicates Example: "IMG_0001" that occur from the application of multiple cameras within a study. When files 
all have unique names they can be moved into mass folders and remain organized. After setting the input directory, the command will loop through each 
camera folder "Stream_1", "Stream_2", "Stream_3" and label each CT image with "Stream_1_20250228_123456" or the Site_Date_Time. 

The second part of script allows for the automated relabeling of incorrect times. This allows for the user to put in the time displayed as well as the
time the camera should show. The script calculates the difference, loops through each image in the directory, and deposits the completed images in the 
terminal folder. 

The second script "ImageClassificationShiny_AND_PullTargetSpp" is a shiny app that allows the users to set keyboard shortcuts for the manual classification 
of camera trap images. As long as the user knows what the keys '1-0' represent they can be customizable within the script on lines 173-182. The script saves 
a .csv after each session, **deleting the images that have been processed as each input is requested**, as such it is important to duplicate the directory 
before running the shiny app. If a misclassification is made, the user can hit the "Oops, go back" button, and the classification scheme will take the last
input entered for that image. Warning messages after closing the app are related to this. The remaining script in this session compiles all the .csv files in
that directory into a master file and cleans the data. 

The second part of the second script is designed to loop through subfolders of the parent directory and pull images of a target species from the classification.
