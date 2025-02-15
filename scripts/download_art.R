io_config = yaml::yaml.load_file("/root/io_config.yml")
args = io_config$article$download_args

url = args$url
cat("\nDownload article from ", url,"\n")
options(timeout=args$timeout_sec)
file = paste0("art.",tolower(args$file_type))
download.file(url, file.path("/root/art/", file))
              
