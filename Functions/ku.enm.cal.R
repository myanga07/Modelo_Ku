ku.enm.cal <- function(occ.all, occ.tra, M.var.dir, batch,
                       out.dir, reg.mult, f.clas = "all"){
  
  #Funtion to get free ram 
  get_free_ram <- function(){
    if(Sys.info()[["sysname"]] == "Windows"){
      x <- system2("wmic", args =  "OS get FreePhysicalMemory /Value", stdout = TRUE)
      x <- x[grepl("FreePhysicalMemory", x)]
      x <- gsub("FreePhysicalMemory=", "", x, fixed = TRUE)
      x <- gsub("\r", "", x, fixed = TRUE)
      as.integer(x)
    } else {
      cat("\nOnly supported on Windows OS\n1.6 Gb of the memory will be used for java runnings\n")
      x <- 4000000
    }
  }
  
  #Data
  ##Environmental variables sets
  m <- dir(M.var.dir)
  ms <- paste(M.var.dir, "\\", m, sep = "")
  env <- vector()
  for (i in 1:length(ms)) {
    env[i] <- paste("environmentallayers=", ms[i], sep = "")
  }
  
  ##Species occurrences
  oc <- occ.all
  samp <- paste("samplesfile=", oc, sep = "")
  occ <- occ.tra
  samp1 <- paste("samplesfile=", occ, sep = "")
  
  #Maxent settings
  ##Featire classes combinations
  fea <- c("linear=true quadratic=false product=false threshold=false hinge=false",
           "linear=false quadratic=true product=false threshold=false hinge=false",
           "linear=false quadratic=false product=true threshold=false hinge=false",
           "linear=false quadratic=false product=false threshold=true hinge=false",
           "linear=false quadratic=false product=false threshold=false hinge=true",
           "linear=true quadratic=true product=false threshold=false hinge=false",
           "linear=true quadratic=false product=true threshold=false hinge=false",
           "linear=true quadratic=false product=false threshold=true hinge=false",
           "linear=true quadratic=false product=false threshold=false hinge=true",
           "linear=false quadratic=true product=true threshold=false hinge=false",
           "linear=false quadratic=true product=false threshold=true hinge=false",
           "linear=false quadratic=true product=false threshold=false hinge=true",
           "linear=false quadratic=false product=true threshold=true hinge=false",
           "linear=false quadratic=false product=true threshold=false hinge=true",
           "linear=false quadratic=false product=false threshold=true hinge=true",
           "linear=true quadratic=true product=true threshold=false hinge=false",
           "linear=true quadratic=true product=false threshold=true hinge=false",
           "linear=true quadratic=true product=false threshold=false hinge=true",
           "linear=true quadratic=false product=true threshold=true hinge=false",
           "linear=true quadratic=false product=true threshold=false hinge=true",
           "linear=false quadratic=true product=true threshold=true hinge=false",
           "linear=false quadratic=true product=true threshold=false hinge=true",
           "linear=false quadratic=true product=false threshold=true hinge=true",
           "linear=false quadratic=false product=true threshold=true hinge=true",
           "linear=true quadratic=true product=true threshold=true hinge=false",
           "linear=true quadratic=true product=true threshold=false hinge=true",
           "linear=true quadratic=true product=false threshold=true hinge=true",
           "linear=true quadratic=false product=true threshold=true hinge=true",
           "linear=true quadratic=true product=true threshold=true hinge=true")
  
  names(fea) <- c("l", "q", "p", "t", "h", "lq", "lp", "lt", "lh", "qp", "qt", "qh",
                  "pt", "ph", "th", "lqp", "lqt", "lqh", "lpt", "lph", "qpt", "qph",
                  "qth", "pth", "lqpt", "lqph", "lqth", "lpth", "lqpth")
  
  suppressWarnings(if(f.clas == "all"|f.clas == "basic"|f.clas == "no.t.h"|f.clas == "no.h"|f.clas == "no.t"){
    if(f.clas == "all"){fea <- fea} #for choosing all potential combinations
    if(f.clas == "basic"){fea <- fea[c(1, 6, 16, 25, 29)]} #for choosing combinations ordered for increasing complexity (all fc)
    if(f.clas == "no.t.h"){fea <- fea[c(1:3, 6:7, 10, 16)]} #for choosing all combinations ordered for increasing complexity (no t no h)
    if(f.clas == "no.h"){fea <- fea[c(1:4, 6:8, 10:11, 13, 16:17, 19, 21, 25)]}
    if(f.clas == "no.t"){fea <- fea[c(1:3, 5:7, 9:10, 12, 14, 16, 18, 20, 22, 26)]}
  }else{
    fea <- fea[f.clas]
  })
  
  
  #output directories
  dir.create(out.dir)
  
  #Getting ram to be used
  ram <- paste("-mx", (round((get_free_ram()/1000)*0.5)), "m", sep = "")
    
  #Fixed commands
  ##Intitial command
  in.comm <- paste("java", ram, "-jar maxent.jar", sep = " ")
  
  ##Autofeature
  a.fea <- "autofeature=false"
  
  ##Other maxent settings
  fin.com <- "extrapolate=false doclamp=false replicates=1 replicatetype=Bootstrap responsecurves=false jackknife=false plots=false pictures=false outputformat=raw warnings=false visible=false redoifexists autorun\n"
  fin.com1 <- "extrapolate=false doclamp=false replicates=1 replicatetype=Bootstrap responsecurves=false jackknife=false plots=false pictures=false outputformat=logistic warnings=false visible=false redoifexists autorun\n"
  
  #Final code
  pb <- winProgressBar(title = "Progress bar", min = 0, max = length(reg.mult), width = 300) #progress bar
  sink(paste(batch, ".bat", sep = ""))
  
  for (i in 1:length(reg.mult)) {
    Sys.sleep(0.1)
    setWinProgressBar(pb, i, title = paste( round(i / length(reg.mult) * 100, 0), "% finished"))
    for (j in 1:length(fea)) {
      for (k in 1:length(ms)) {
        subfol <- paste("outputdirectory=", out.dir, "\\",
                        paste("M", reg.mult[i], "F", names(fea)[j], m[k], "all", sep = "_"), sep = "")
        dir.create(paste(out.dir, "/", 
                         paste("M", reg.mult[i], "F", names(fea)[j], m[k], "all", sep = "_"), sep = ""))
        reg.m <- paste("betamultiplier=", reg.mult[i], sep = "")
        cat(paste(in.comm, env[k], samp, subfol, reg.m, a.fea, fea[j], fin.com, sep = " "))
        
        subfol1 <- paste("outputdirectory=", out.dir, "\\",
                        paste("M", reg.mult[i], "F", names(fea)[j], m[k], "cal", sep = "_"), sep = "")
        dir.create(paste(out.dir, "/", 
                         paste("M", reg.mult[i], "F", names(fea)[j], m[k], "cal", sep = "_"), sep = ""))
        cat(paste(in.comm, env[k], samp1, subfol1, reg.m, a.fea, fea[j], fin.com1, sep = " "))
      }
    }
  }
  sink()
  suppressMessages(close(pb))
  
  cat("\nIf asked, allow runing as administrator.")
  shell.exec(file.path(getwd(), paste(batch, ".bat", sep = "")))
  
  cat("\nProcess finished\n")
  cat(paste("A maxent batch file for creating", i * j * k, "calibration models has been written", sep = " "))
  cat(paste("\nCheck your working directory!!!", getwd(), sep = "    "))
}
