# This script will be run by a repbox analysis docker container
# Author: Sebastian Kranz

my.dir.copy = function (from, to, ...) {
    if (!dir.exists(to)) 
        dir.create(to, recursive = TRUE)
    res = file.copy(list.files(from, full.names = TRUE), to, 
        recursive = TRUE, ...)
    invisible(all(res))
}

run = function() {
  io_config = yaml::yaml.load_file("/root/io_config.yml")

  if (isTRUE(io_config$output$encryption)) {
    password = Sys.getenv("REPBOX_ENCRYPT_KEY")
    if (password=="") {
      stop("The io_config.yml specified that the output is encrypted. This requires that you specify the password as a Github Repository Secret with name REPBOX_ENCRYPT_KEY.")
    } 
  } else {
    password=NULL
  }
  
  cat("\nInstall R packages specified in install.R\n")
  source(file.path("~/scripts/install.R"))
  
  cat("\n\nCheck Stata License\n\n")
  license.file = "/usr/local/stata/stata.lic"
  if (!file.exists(license.file)) {
    cat("\nWarning: No Stata license found.\nYou need to specify the license in your Github Repo via a Github action secret variable STATA_LIC.\nPlease read the documentation for the repbox Github action pipeline.\n")
  } else {
    cat("\nStata license found.\n")
  }
  
  cat("\n\nREPBOX ANALYSIS START\n")
  
  # Possibly download files
  if (isTRUE(io_config$art$download)) {
    source(file.path("~/scripts", io_config$art$download_script))
  }
  if (isTRUE(io_config$sup$download)) {
    source(file.path("~/scripts", io_config$sup$download_script))
  }
  
  # Possibly extract encrypted 7z files
  source("~/scripts/encripted_7z.R")
  if (isTRUE(io_config$art$encryption)) {
    extract_all_encrypted_7z("/root/art")
  }
  if (isTRUE(io_config$sup$encryption)) {
    extract_all_encrypted_7z("/root/sup")
  }
  
  # Possibly extract ZIP file for article
  extract_all_zip("/root/art")
  
  
  suppressPackageStartupMessages(library(repboxRun))
  
  # Writen files can be changed and read by all users
  # So different containers can access them
  Sys.umask("000")
  project_dir = "~/projects/project"
  
  start.time = Sys.time()
  cat(paste0("\nAnalysis starts at ", start.time," (UTC)\n"))
  
  # To do: Parse options from run_config.yml
  
  # 
  sup_zip = list.files("/root/sup", glob2rx("*.zip"), ignore.case=TRUE, full.names = TRUE,recursive = TRUE)
  if (length(sup_zip) != 1) {
    cat("\nFiles in /root/sup...\n")
    print(list.files("/root/sup", glob2rx("*"), ignore.case=TRUE, full.names = TRUE,recursive = TRUE))
    stop("After download and extraction of 7z, there must be exactly one ZIP file in the /root/sup directory.")
  }

  pdf_files = list.files("/root/art", glob2rx("*.pdf"), ignore.case=TRUE, full.names = TRUE,recursive = TRUE)
  
  html_files = list.files("/root/art", glob2rx("*.html"), ignore.case=TRUE, full.names = TRUE,recursive = TRUE)
  
  
  project_dir = "/root/projects/project"
  dir.create(project_dir)
  
  # Copy files with meta information (if any exist)
  meta_files = list.files("/root/meta", glob2rx("*.*"), ignore.case=TRUE, full.names = TRUE,recursive = TRUE)
  dir.create(file.path(project_dir,"meta"))
  file.copy(meta_files, file.path(project_dir,"meta"))
  
  
  
  

  try_catch_repbox_problems(project_dir=project_dir, {
    repbox_init_project(project_dir,sup_zip = sup_zip,pdf_files = pdf_files, html_files = html_files)
    
    # Just print some size information
    all.files = list.files(file.path(project_dir, "org"),glob2rx("*.*"),recursive = TRUE, full.names = TRUE)
    org.mb = sum(file.size(all.files),na.rm = TRUE) / 1e6
    cat("\nSUPPLEMENT NO FILES: ", length(all.files), "\n")
    cat("\nSUPPLEMENT UNPACKED SIZE: ", round(org.mb,2), " MB\n")
    
    opts = repbox_run_opts()
    repbox_run_project(project_dir, lang = c("stata","r"), opts=opts)
  })
  system("chmod -R 777 /root/projects")
  
  # Store results as encrypted 7z
  cat("\nStore results as 7z")
  #dir.create("/root/output")
  
  if (isTRUE(io_config$output$encryption)) {
    cat("\n***************************************************************\n
Store results as encrypted 7z\n***************************************************************\n")
    
    paths = paste0("/root/projects/project/", c("reports","repdb","art","repbox","meta","steps","metareg","problems"))
    
    for (p in paths) {
      cat("\nFiles in ",p,":")
      print(list.files(p,recursive = FALSE))
    }
    path = paste0(paths, collapse=" ")
    to.7z(path,"/root/output/results.7z",password = password)
  } else {
    cat("\nStore results\n")
    my.dir.copy("/root/projects/project/reports", "/root/output")
    my.dir.copy("/root/projects/project/repdb", "/root/output")
    
    cat("\nFiles in reports:")
    print(list.files("/root/projects/project/reports",recursive = TRUE))
    cat("\nFiles in output:")
    print(list.files("/root/output/",recursive = TRUE))
  }
  key = Sys.getenv("REPBOX_ENCRYPT_KEY")
  #to.7z("/root/projects/project/reports","/root/output/reports.7z",password = key)
  
  cat(paste0("\nAnalysis finished after ", round(difftime(Sys.time(),start.time, units="mins"),1)," minutes.\n"))
  
  cat("\nMEMORY INFO START\n\n")
  system("cat /proc/meminfo")
  cat("\nMEMORY INFO END\n\n")
  
  
  cat("\n\nREPBOX ANALYSIS END\n")
  
}

run()