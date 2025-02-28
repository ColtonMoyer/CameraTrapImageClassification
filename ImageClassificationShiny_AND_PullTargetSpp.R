
#install.packages("xfun","shiny","readr","dplyr")
xfun::pkg_attach("shiny","readr","dplyr","xfun", "tidyr","stringr")

# Set your image directory
#source_dir <- "E:/R/CameraImageClassification/210LMCTrenamed" #on Colton's computer

source_dir <- "E:/output"

# Get all JPEG files from the directory
images <- list.files(source_dir, pattern = "\\.(jpg|jpeg|JPG|JPEG)$", full.names = TRUE)

# Initialize a data frame to store responses
responses <- data.frame(Image = character(), Response = character(), elapsed_time = numeric(), stringsAsFactors = FALSE)

# Track processed images
processed_images <- character()

# Mark the start of the session
session_start_time <- Sys.time()

# UI
ui <- fluidPage(
  tags$head(
    tags$script(HTML("
      $(document).on('keypress', function(e) {
        if (e.which >= 48 && e.which <= 57) {  // Keys '0' to '9'
          Shiny.setInputValue('response', String.fromCharCode(e.which));
          $('#next_image').click(); // Automatically trigger the response save
        }
      });
    "))
  ),
  titlePanel("Please Enter a Number [0-9], Hit Enter"),
  sidebarLayout(
    sidebarPanel(
      actionButton("prev_image", "Oops....Go Back!"),
      actionButton("next_image", "Next Image"),
      textInput("response", "Enter a Number (0-9)", "")
    ),
    mainPanel(
      imageOutput("image", width = "90%", height = "auto")
    )
  )
)

# Server
server <- function(input, output, session) {
  # Reactive value to track the current image index
  current_image_index <- reactiveVal(1)
  
  # Function to save response
  save_response <- function() {
    if (input$response %in% as.character(0:9)) {
      # Calculate elapsed time
      elapsed_time <- as.numeric(difftime(Sys.time(), session_start_time, units = "secs"))
      
      # Store the response along with elapsed time
      responses <<- rbind(responses, data.frame(Image = images[current_image_index()], Response = input$response, elapsed_time = elapsed_time))
      
      # Track processed images
      processed_images <<- c(processed_images, images[current_image_index()])
      # Clear the response input
      updateTextInput(session, "response", value = "")
    }
  }
  
  # Observe the 'next_image' button click
  observeEvent(input$next_image, {
    save_response()  # Save the response before moving to the next image
    
    # Move to the next image
    new_index <- current_image_index() + 1
    if (new_index > length(images)) {
      new_index <- length(images)  # Don't go beyond the last image
    }
    current_image_index(new_index)
    
    # Load the response for the next image if available
    if (new_index <= nrow(responses)) {
      last_response <- responses[new_index, "Response"]
      updateTextInput(session, "response", value = last_response)
    } else {
      updateTextInput(session, "response", value = "")  # Clear if no previous response
    }
  })
  
  # Observe the 'prev_image' button click
  observeEvent(input$prev_image, {
    # Move to the previous image
    new_index <- current_image_index() - 1
    if (new_index < 1) {
      new_index <- 1  # Stay at the first image
    }
    current_image_index(new_index)
    
    # Allow the user to resubmit the previous response if available
    if (new_index <= nrow(responses)) {
      last_response <- responses[new_index, "Response"]
      updateTextInput(session, "response", value = last_response)
    } else {
      updateTextInput(session, "response", value = "")  # Clear if no previous response
    }
  })
  
  # Render the current image
  output$image <- renderImage({
    list(src = images[current_image_index()], contentType = 'image/jpeg', alt = "Image not found",
         width = 900, height = 600)  # Adjust width and height as needed
  }, deleteFile = FALSE)
  
  session$onSessionEnded(function() {
    # Save responses to CSV
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    response_file_name <- file.path(source_dir, paste0("response_", timestamp, ".csv"))
    write.csv(responses, response_file_name, row.names = FALSE)
    
    # Delete processed images if desired
    file.remove(processed_images)
  })
}

# Run the app
shinyApp(ui = ui, server = server)


#How many images did you process and how many are left?
same_dir <- source_dir
start_images <- length(images)
end_images <- length(list.files(same_dir, pattern = "\\.(jpg|jpeg|JPG|JPEG)$", full.names = TRUE))
processed <- (start_images - end_images)
cat("Number of images processed:", processed, "\n") #print the number of images processed
cat("Images remaining:",end_images, "\n") #print remaining images in the directory


#Combine the csv files into one master sheet 
csv_files <- list.files(source_dir, pattern = "response.*\\.csv$", full.names = TRUE) # Get all CSV files with 'response' in their names
print(csv_files)
data_list <- list() # Initialize an empty list to store data frames


for (file in csv_files) { # Read each CSV file and store in the list
  data <- read.csv(file, stringsAsFactors = FALSE)  # Ensure strings are not converted to factors
  data$Image <- as.character(data$Image)  # Convert Image column to character type
  data_list[[file]] <- data
}

combined_data <- bind_rows(data_list)# Combine all data frames into one

final_data <- combined_data %>%
  group_by(Image) %>%
  summarise(Response = last(Response), 
            .groups = 'drop') # Remove duplicates based on the 'Image' column

final_data$Image <- sub("^.*?/", "", final_data$Image) #remove everything before the '/' in the column

write.csv(final_data, file.path(source_dir, "master_CT_class.csv"), row.names = FALSE) #will say denied if the file is open on the computer. 

#remove any issues
final_data <- na.omit(final_data)



#
#
#
#
#This is where you set the animal classificaiton scheme

#reclassify
final_data <- final_data %>%
  mutate(species = recode(Response, 
                          `1` = "animal", 
                          `2` = "deer", 
                          `3` = "raccoon", 
                          `4` = "groundhog", 
                          `5` = "redfox",
                          `6` = "skunk",
                          `7` = "kestrel",
                          `8` = "rabbit",
                          `9` = "vulture",
                          `0` = "none"))

#reclassify SMCT
#final_data <- final_data %>%mutate(species = recode(Response, `1` = "other",  `2` = "peromyscus",  `3` = "vole", `4` = "shrew", 
#                                                    `5` = "raccoon",`6` = "skunk", `7` = "rabbit", `8` = "snake", `9` = "bird",
#                                                    `0` = "none"))

final_data <- final_data %>% rename(response = Response) #rename the response column 
final_data <- final_data %>% mutate(site = sub(".*renamed/", "", Image)) #duplicate image data to new column for parsing 
final_data <- final_data %>% rename(source_location = Image) #rename the source column 
final_data <- final_data %>% separate(site, into = c("site", "date", "time"), sep = "__") #split into site, date, time
final_data <- final_data %>% mutate(time = substr(time, 1, nchar(time) - 4)) #drop the .JPG
final_data <- final_data %>% mutate(burst_location = str_sub(time, -3)) #name the burst location column
final_data <- final_data %>% filter(source_location != "" & !is.na(source_location)) #remove any row with a blank in the first column
final_data <- final_data %>% mutate(image_name = sub(".*renamed/", "", source_location))
final_data$site <- sub("^.*?_", "", final_data$site)

final_data <- final_data %>% filter(species != "NA" & !is.na(species)) #get rid of the rows with no animals (NAs)
head(final_data)
write.csv(final_data, file.path(source_dir, "master_CT_data.csv"), row.names = FALSE)

nrow(final_data)


unique(final_data$site) #what sites within your data have you processed?

#Move by species
#
#
#
#Pull all the images of a target species and put them all in one directory

interesting_species <- final_data %>% filter(grepl("deer", species, ignore.case = TRUE)) #BLACKBEAR, RACCOON, etc. 

# Define parent directory (you should set this to your actual parent directory path)
#parent_dir <- source_dir
source_dir <- "E:/output"
# create a destination directory where you want all the images to be sent to
target_dir <- "E:/ouput/deer"

# Create target directory if it does not exist
if (!dir.exists(target_dir)) {
  dir.create(target_dir)
}

# Loop through all subdirectories in the source directory
subdirs <- list.dirs(source_dir, full.names = TRUE, recursive = TRUE)

# Remove the first element as it is the main directory
subdirs <- subdirs[-1]
list(subdirs)

# Loop through each subdirectory
for (subdir in subdirs) {
  # List all files in the subdirectory
  files <- list.files(subdir, full.names = TRUE)
  
  # Loop through each file in the subdirectory
  for (file in files) {
    # Get the file name (without the path)
    file_name <- basename(file)
    
    # Check if the file name appears in the 'image_name' column of the dataframe
    if (file_name %in% interesting_species$image_name) {
      # Construct the target file path
      target_file <- file.path(target_dir, file_name)
      
      # Move the file to the target directory
      file.rename(file, target_file)
      
      # Optionally print a message to track progress
      message(paste("Moved:", file_name))
    }
  }
}

# View the result of moved files (optional)
length(target_dir)

