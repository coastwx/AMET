header <- "
############################ ROSELLE BOX PLOT ##############################
### AMET CODE: AQ_Boxplot_Roselle.R 
###
### THIS FILE CONTAINS CODE TO DRAW A CUSTOMIZED HOURLY BOXPLOT DISPLAY.  It
### draws side-by-side boxplots for the various groups, with median value,
### interquartile and 25% and 75% quartile ranges indicated.  It is designed
### to work with a single network/species and any temporal data (e.g. hourly, 
### daily, or weekly), but will plot a single bar for each simulation. 
### Proided under the boxes are summary statistics for each simulation
###
### Last updated by Wyat Appel: Feb 2020
#############################################################################
"

## get some environmental variables and setup some directories
ametbase	<- Sys.getenv("AMETBASE")        		# base directory of AMET
ametR		<- paste(ametbase,"/R_analysis_code",sep="")    # R directory

## source miscellaneous R input file 
source(paste(ametR,"/AQ_Misc_Functions.R",sep=""))     # Miscellanous AMET R-functions file

### Retrieve units label from database table ###
network 	<- network_names[1]
#units_qs	<- paste("SELECT ",species," from project_units where proj_code = '",run_name1,"' and network = '",network,"'", sep="")
################################################

### Set file names and titles ###
filename_pdf	 <- paste(run_name1,species,pid,"boxplot_roselle.pdf",sep="_")
filename_png 	 <- paste(run_name1,species,pid,"boxplot_roselle.png",sep="_")
filename_bias_pdf <- paste(run_name1,species,pid,"boxplot_roselle_bias.pdf",sep="_")
filename_bias_png <- paste(run_name1,species,pid,"boxplot_roselle_bias.png",sep="_")

if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
title <- get_title(run_names,species,network_names,dates,custom_title)
#################################

## Create a full path to file
filename_pdf		<- paste(figdir,filename_pdf,sep="/")
filename_png		<- paste(figdir,filename_png,sep="/")
filename_bias_pdf	<- paste(figdir,filename_bias_pdf,sep="/")
filename_bias_png        <- paste(figdir,filename_bias_png,sep="/")

run_names <- NULL
legend_names <- NULL
run_names <- run_name1
{
   if ((exists("run_name2")) && (nchar(run_name2) > 0)) {
      run_names <- c(run_names,run_name2)
   }
   if ((exists("run_name3")) && (nchar(run_name3) > 0)) {
      run_names <- c(run_names,run_name3)
   }
   if ((exists("run_name4")) && (nchar(run_name4) > 0)) {
      run_names <- c(run_names,run_name4)
   }
   if ((exists("run_name5")) && (nchar(run_name5) > 0)) {
      run_names <- c(run_names,run_name5)
   }
   if ((exists("run_name6")) && (nchar(run_name6) > 0)) {
      run_names <- c(run_names,run_name6)
   }
}
run_names <- c(run_name1,run_names)

obs_values   <- NULL
mod_values   <- NULL
bias_values  <- NULL
q0.spec1     <- NULL
q0.spec2     <- NULL
q1.spec1     <- NULL
q1.spec2     <- NULL
median.spec1 <- NULL
median.spec2 <- NULL
q3.spec1     <- NULL
q3.spec2     <- NULL
q4.spec1     <- NULL
q4.spec2     <- NULL

nmb        <- NULL
nme        <- NULL
mb         <- NULL
me         <- NULL
corr       <- NULL
rmse       <- NULL
rmse_sys   <- NULL
rmse_unsys <- NULL
index_agr  <- NULL
bias_max   <- NULL
bias_min   <- NULL

ob_col_name <- paste(species,"_ob",sep="")
mod_col_name <- paste(species,"_mod",sep="")
num_runs <- length(run_names)
k <- 0
box_loc <- c(1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6)
for (j in 1:num_runs) {
   {
      if (Sys.getenv("AMET_DB") == 'F') {
         outdir              <- "OUTDIR"
         if (j > 2) { outdir <- paste("OUTDIR",j-1,sep="") }
         sitex_info          <- read_sitex(Sys.getenv(outdir),network,run_names[j],species)
         data_exists         <- sitex_info$data_exists
         if (data_exists == "y") {
            aqdat_query.df      <- (sitex_info$sitex_data)
            aqdat_query.df      <- aqdat_query.df[with(aqdat_query.df,order(network,stat_id)),]
            units               <- as.character(sitex_info$units[[1]])
         }
      }
      else {
         query_result    <- query_dbase(run_names[j],network,species)
         aqdat_query.df  <- query_result[[1]]
         data_exists     <- query_result[[2]]
         if (data_exists == "y") { units <- query_result[[3]] }
      }
   }
   {
      if (data_exists == "n") {
         num_runs <- (num_runs-1)
         if (num_runs == 0) { stop("Stopping because num_runs is zero. Likely no data found for query.") }
      }
      else {
         k <- k+1
         aqdat.df <- aqdat_query.df
         obs_values[[k]] <- aqdat.df[[ob_col_name]]
         {
            if (j == 1) {
               legend_names <- network
               mod_values[[k]] <- aqdat.df[[ob_col_name]]
            }
            else {
               legend_names <- c(legend_names,run_names[j])
               mod_values[[k]] <- aqdat.df[[mod_col_name]]
            }
         }
         #######################
         if (k > 1) {
            bias_values[[k-1]] <- aqdat.df[[mod_col_name]]-aqdat.df[[ob_col_name]]
            bias_max <- max(bias_max,bias_values[[k-1]])
            bias_min <- min(bias_min,bias_values[[k-1]])
         }

         ### Find q1, median, q2 for each group of both species ###
         q0.spec1[k] <- quantile(aqdat.df[[ob_col_name]], 0.05, na.rm=T)		# Compute ob 25% quartile
         q0.spec2[k] <- quantile(aqdat.df[[mod_col_name]], 0.05, na.rm=T)	# Compute model 25% quartile
         q1.spec1[k] <- quantile(aqdat.df[[ob_col_name]], 0.25, na.rm=T)		# Compute ob 25% quartile
         q1.spec2[k] <- quantile(aqdat.df[[mod_col_name]], 0.25, na.rm=T)	# Compute model 25% quartile
         median.spec1[k] <- median(aqdat.df[[ob_col_name]],na.rm=T)		# Compute ob median value
         median.spec2[k] <- median(aqdat.df[[mod_col_name]], na.rm=T)		# Compute model median value
         q3.spec1[k] <- quantile(aqdat.df[[ob_col_name]], 0.75, na.rm=T)		# Compute ob 75% quartile
         q3.spec2[k] <- quantile(aqdat.df[[mod_col_name]], 0.75, na.rm=T)	# Compute model 75% quartile
         q4.spec1[k] <- quantile(aqdat.df[[ob_col_name]], 0.95, na.rm=T)		# Compute ob 75% quartile
         q4.spec2[k] <- quantile(aqdat.df[[mod_col_name]], 0.95, na.rm=T)	# Compute model 75% quartile
         ################################################

         #########################################################
         #### Calculate statistics for simulation 1           ####
         #########################################################
         ## Calculate stats using all pairs, regardless of averaging
         data_all.df <- NULL
         stats.df    <- NULL
         data_all.df <- data.frame(network=I(aqdat.df$network),stat_id=I(aqdat.df$stat_id),lat=aqdat.df$lat,lon=aqdat.df$lon,ob_val=aqdat.df[[ob_col_name]],mod_val=aqdat.df[[mod_col_name]])
         stats.df      <- try(DomainStats(data_all.df))      # Compute stats using DomainStats function for entire domain
         nmb[k]        <- round(stats.df$Percent_Norm_Mean_Bias,1)
         nme[k]        <- round(stats.df$Percent_Norm_Mean_Err,1)
         mb[k]         <- round(stats.df$Mean_Bias,2)
         me[k]         <- round(stats.df$Mean_Err,2)
         corr[k]       <- round(stats.df$Correlation,2)
         rmse[k]       <- round(stats.df$RMSE,2)
         rmse_sys[k]   <- round(stats.df$RMSE_systematic,2)
         rmse_unsys[k] <- round(stats.df$RMSE_unsystematic,2)
         index_agr[k]  <- round(stats.df$Index_of_Agree,2)
         #########################################################
      }
   }
}
legend_names_bias <- legend_names[-c(1)]

### Set up axes so that they will be big enough for both data species  that will be added ###
num.groups <- length(unique(aqdat.df$ob_hour))				# Count the number of sites used in each month
y.axis.min <- min(c(-.5,-.5))						# Set y-axis minimum values
y.axis.max.value <- max(c(q4.spec1, q4.spec2))				# Determine y-axis maximum value
y.axis.max <- c(sum((y.axis.max.value * 0.30),y.axis.max.value))	# Add 38% of the y-axis maximum value to the y-axis maximum value
y.axis.min.value <- min(c(q0.spec1, q0.spec2))
y.axis.min <- y.axis.min.value-(0.35*y.axis.max)

if (length(y_axis_max) > 0) {
   y.axis.max <-y_axis_max
}

if (length(y_axis_min) > 0) {
   y.axis.min <- y_axis_min
}

#############################################################################################


##########################################
########## MAKE ROSELLE BOXPLOT ##########
##########################################

y.axis.max.value <- max(c(q4.spec1, q4.spec2))
y.axis.min.value <- min(c(q0.spec1, q0.spec2))
if (length(y_axis_max) > 0) {
   y.axis.max.value <-y_axis_max
}

if (length(y_axis_min) > 0) {
   y.axis.min.value <- y_axis_min
}
y_range 	 <- y.axis.max.value-y.axis.min.value
y.axis.min 	 <- y.axis.min.value-(0.3*y_range)
y.axis.max 	 <- y.axis.max.value+(0.05*y_range*num_runs)
y_label          <- paste(network," ",species," (",units,")",sep="")
y_label_bias     <- paste(network," ",species," Bias (",units,")",sep="")


pdf(filename_pdf, width=8, height=8)						# Set output device with options
{
   par(mai=c(1,1,0.5,0.5))                                                         # Set plot margins
   boxplot_info <- boxplot(mod_values,plot=F)
   boxplot(mod_values,range=0, border="transparent", col=plot_colors, ylim=c(y.axis.min, y.axis.max), xlab="", ylab=y_label, names=legend_names, cex.axis=.8, cex.lab=1.2, cex=1, las=1, boxwex=.4, at=box_loc[1:k],axes=F) # Create boxplot
   axis(2,at=pretty(c(y.axis.min,y.axis.max),n=10))
}
### Put title at top of boxplot ###
title(main=title,cex.main=0.8)
###################################

for (j in 1:k) {
   {
      if (j == 1) {
         lines(c((box_loc[j]-.15),(box_loc[j]+.15)), c(q0.spec1[j],q0.spec1[j]))				# create horizontal black line below quartile
         lines(c((box_loc[j]-.2),(box_loc[j]+.2)), c(median.spec1[j],median.spec1[j]),col="white",lwd=2)	# Denote median as a white line 
         lines(c((box_loc[j]-.15),(box_loc[j]+.15)), c(q4.spec1[j],q4.spec1[j]))				# create horizontal black line above quartile
         lines(c(box_loc[j],box_loc[j]),c(q0.spec1[j],q1.spec1[j]),col="black",lty=2)			# create vertical black line denoting lower 25 quartile
         lines(c(box_loc[j],box_loc[j]),c(q3.spec1[j],q4.spec1[j]),col="black",lty=2)			# create vertical black line denoting upper 75 quartile
      }
      else {
         ### Second species ###								# As above, except for model values
         lines(c((box_loc[j]-.15),(box_loc[j]+.15)), c(q0.spec2[j],q0.spec2[j]))				# create vertical black line below quartile
         lines(c((box_loc[j]-.2),(box_loc[j]+.2)), c(median.spec2[j],median.spec2[j]),col="white",lwd=2)	# Connect median points with a line
         lines(c((box_loc[j]-.15),(box_loc[j]+.15)), c(q4.spec2[j],q4.spec2[j]))				# create vertical black line above quartile
         lines(c(box_loc[j],box_loc[j]),c(q0.spec2[j],q1.spec2[j]),col="black",lty=2)			# create horizontal black line denoting lower 25 quartile
         lines(c(box_loc[j],box_loc[j]),c(q3.spec2[j],q4.spec2[j]),col="black",lty=2)			# create horizontal black line denoting upper 75 quartile
      }
   }   
   #########################################################################
}

y.rec.top <- y.axis.min+(y_range*.25)
y1 <- y.axis.min+(y_range*.21)
y2 <- y.axis.min+(y_range*.17)
y3 <- y.axis.min+(y_range*.13)
y4 <- y.axis.min+(y_range*.09)
y5 <- y.axis.min+(y_range*.05)
y6 <- y.axis.min+(y_range*.01)

y<-c(y1,y2,y3,y4,y5,y6)

rect(ybottom=y.axis.min,ytop=y.rec.top,xright=box_loc[k]+.5,xleft=0.45,col="gray85")

text(1,y[1], "r" ,font=3,cex=0.8,adj=c(0.5,0))               # write correlation title
text(1,y[2], "RMSE", font=3,cex=0.8,adj=c(0.5,0))            # write RMSE title
text(1,y[3], "NMB",font=3,cex=0.8,adj=c(0.5,0))              # write NMB systematic title
text(1,y[4], "NME",font=3,cex=0.8,adj=c(0.5,0))              # write NME unsystematic title
text(1,y[5], "MB",font=3,cex=0.8,adj=c(0.5,0))               # write MB title
text(1,y[6], "ME",font=3,cex=0.8,adj=c(0.5,0))               # write ME title

for (j in 2:k) {
   text(box_loc[j], y[1], corr[j], cex=0.9,adj=c(0.5,0),col=plot_colors[j])          # write correlation value
   text(box_loc[j], y[2], rmse[j], cex=0.9,adj=c(0.5,0),col=plot_colors[j])          # write RMSE value
   text(box_loc[j], y[3], nmb[j], cex=0.9,adj=c(0.5,0),col=plot_colors[j])           # write NMB value
   text(box_loc[j], y[4], nme[j], cex=0.9,adj=c(0.5,0),col=plot_colors[j])           # write NME value
   text(box_loc[j], y[5], mb[j], cex=0.9,adj=c(0.5,0),col=plot_colors[j])            # write MB value
   text(box_loc[j], y[6], me[j], cex=0.9,adj=c(0.5,0),col=plot_colors[j])            # write ME value
}


##########################################

### Put legend on the plot ###
legend("topleft", legend_names, fill = plot_colors, merge=F, cex=0.8, bty='n')
##############################

### Count number of samples per hour ###
nsamples.table <- table(aqdat.df$ob_hour)
#########################################

### Put text on plot ###
text(x=18,y=y.axis.max,paste("RPO: ",rpo,sep=""),cex=1.2,adj=c(0,0))
text(x=18,y=y.axis.max*0.95,paste("PCA: ",pca,sep=""),cex=1.2,adj=c(0,0))
text(x=18,y=y.axis.max*0.90,paste("Site: ",site,sep=""),cex=1.2,adj=c(0,0))
if (state != "All") {
   text(x=18,y=y.axis.max*0.85,paste("State: ",state,sep=""),cex=1.2,adj=c(0,0))
}

########################

### Convert pdf to png ###
dev.off()
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density ",png_res,"x",png_res," ",filename_pdf," png:",filename_png,sep="")
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_pdf,sep="")
      system(remove_command)
   }
}
##########################

plot_colors_bias <- plot_colors[-1]
y.axis.max <- bias_max
y.axis.min <- bias_min
y_range <- y.axis.max-y.axis.min
y.axis.min <- y.axis.min-(0.3*y_range)
y.axis.max <- y.axis.max+(0.04*y_range*num_runs)
pdf(filename_bias_pdf, width=8, height=8)                                          # Set output device with options
par(mai=c(1,1,0.5,0.5))                                                         # Set plot margins
boxplot_info <- boxplot(bias_values,plot=F)
boxplot(bias_values, col=plot_colors_bias, xlab="", ylab=y_label_bias, ylim=c(y.axis.min, y.axis.max), names=legend_names_bias, cex.axis=.8, cex.lab=1.2, cex=1, las=1, boxwex=.4, at=box_loc[1:k-1],axes=F) # Create boxplot
axis(2,at=pretty(c(y.axis.min,y.axis.max),n=10))
legend("topleft", legend_names_bias, fill = plot_colors_bias, merge=F, cex=0.8, bty='n')
### Put title at top of boxplot ###
title(main=title,cex.main=0.8)
###################################

y.rec.top <- y.axis.min+(y_range*.25)
y1 <- y.axis.min+(y_range*.21)
y2 <- y.axis.min+(y_range*.17)
y3 <- y.axis.min+(y_range*.13)
y4 <- y.axis.min+(y_range*.09)
y5 <- y.axis.min+(y_range*.05)
y6 <- y.axis.min+(y_range*.01)

y<-c(y1,y2,y3,y4,y5,y6)
x<-c(0.6)

rect(ybottom=y.axis.min,ytop=y.rec.top,xright=box_loc[k],xleft=0.45,col="gray85")

text(x[1],y[1], "r" ,font=3,cex=0.8,adj=c(0.5,0))               # write correlation title
text(x[1],y[2], "RMSE", font=3,cex=0.8,adj=c(0.5,0))            # write RMSE title
text(x[1],y[3], "NMB",font=3,cex=0.8,adj=c(0.5,0))              # write NMB systematic title
text(x[1],y[4], "NME",font=3,cex=0.8,adj=c(0.5,0))              # write NME unsystematic title
text(x[1],y[5], "MB",font=3,cex=0.8,adj=c(0.5,0))               # write MB title
text(x[1],y[6], "ME",font=3,cex=0.8,adj=c(0.5,0))               # write ME title

for (j in 1:k) {
   text(box_loc[j],y[1], corr[j+1], cex=0.9,adj=c(0.5,0),col=plot_colors_bias[j])          # write correlation value
   text(box_loc[j],y[2], rmse[j+1], cex=0.9,adj=c(0.5,0),col=plot_colors_bias[j])          # write RMSE value
   text(box_loc[j],y[3], nmb[j+1], cex=0.9,adj=c(0.5,0),col=plot_colors_bias[j])           # write NMB value
   text(box_loc[j],y[4], nme[j+1], cex=0.9,adj=c(0.5,0),col=plot_colors_bias[j])           # write NME value
   text(box_loc[j],y[5], mb[j+1], cex=0.9,adj=c(0.5,0),col=plot_colors_bias[j])            # write MB value
   text(box_loc[j],y[6], me[j+1], cex=0.9,adj=c(0.5,0),col=plot_colors_bias[j])            # write ME value
}   
abline(h=0,col="black")

dev.off()
if ((ametptype == "png") || (ametptype == "both")) {   
   convert_command<-paste("convert -flatten -density ",png_res,"x",png_res," ",filename_bias_pdf," png:",filename_bias_png,sep="")
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_bias_pdf,sep="")
      system(remove_command)
   }
}

