#Time trouble

xfun::pkg_attach("lubridate","stringr","fs", "tidyr","readr", "here", "tidyr", "tibble", "ggplot2","tidyverse","camtrapR","exiftoolr","rgdal","magick")

#download the tool to rename camera trap images
#https://exiftool.org/

addToPath("C:/Windows/exiftool")
Sys.which("exiftool.exe")

#name the input and output directories

# Define input directory
image_dir <- "E:/"  # Replace with the directory containing your images

#intermediate directory
int_dir <- "E:/int_dir"

#name terminal directory
output_dir <- "E:/output"  

# Create output directory if it doesn't exist
if (!dir.exists(int_dir)) {dir.create(int_dir, recursive = TRUE)}
if (!dir.exists(output_dir)) {dir.create(output_dir, recursive = TRUE)}


#Rename images; within the 'inDir' it will assign the 'child' folders to 'sites' then loop through lesser folders 
#So, in the hierarchy below ~batch1.2 contains folders 280_11 and 280_12, the outDir will have those two folders with no subfolders within--all the images from that site
imageRename(inDir = image_dir, outDir = output_dir, 
            hasCameraFolders = FALSE, keepCameraSubfolders = FALSE, createEmptyDirectories = FALSE, copyImages = TRUE, 
            writecsv = TRUE)

#
#
#
#relabeling files with incorrect times. 

# Get a list of all JPG files in the directory
image_files <- list.files(int_dir, pattern = "\\.JPG$", full.names = TRUE)

# Function to adjust the filename and copy the file to the new directory
adjust_and_save_file <- function(file_path, time_offset, output_dir) {
  # Extract the date-time portion from the filename (assumes the format "YYYY-MM-DD__HH-MM-SS")
  filename <- basename(file_path)
  date_str <- str_extract(filename, "\\d{4}-\\d{2}-\\d{2}__\\d{2}-\\d{2}-\\d{2}")
  
  # Convert the extracted date-time string into a POSIXct object
  wrong_time <- ymd_hms(gsub("__", " ", date_str))  # Correct parsing
  
  # Apply the time offset to the file's timestamp
  new_time <- wrong_time + time_offset
  new_time_str <- format(new_time, "%Y-%m-%d__%H-%M-%S")
  new_filename <- str_replace(filename, date_str, new_time_str)
  output_file <- file.path(output_dir, new_filename)
  file.copy(file_path, output_file, overwrite = TRUE)
  return(new_time)  # Return the new time for confirmation
}

#time displayed (thats incorrect)
camera_time_str <- "2020-01-01 00:00:00"  # Example: Enter the camera's incorrect time
camera_time <- ymd_hms(camera_time_str)

# Enter the time it should be (correct time)
correct_time_str <- "2024-05-23 17:28:00"  # Example: Enter the correct time
correct_time <- ymd_hms(correct_time_str)

# Calculate the time offset (difference between the correct and incorrect time)
time_offset <- correct_time - camera_time

# Adjust the timestamps of all files and copy them to the new directory
for (file in image_files) {
  new_timestamp <- adjust_and_save_file(file, time_offset, output_dir)
  message("Adjusted file: ", file, " to new timestamp: ", new_timestamp, " in ", output_dir)
}
