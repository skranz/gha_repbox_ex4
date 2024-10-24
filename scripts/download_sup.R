io_config = yaml::yaml.load_file("/root/io_config.yml")
args = io_config$sup$download_args

url = args$url
cat("\nDownload supplement from ", url,"\n")
options(timeout=args$timeout_sec)
file = paste0("sup.",tolower(args$file_type))
download.file(url, file.path("/root/sup/", file))
              
