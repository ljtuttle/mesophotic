#library(rfishbase)
#library(ggpubr)
#library(FSAdata)
library(tidyverse)
library(FSA)
library(nlstools)
library(nmfspalette)
#add these two lines if nmfspalette not installed:
#library(remotes)
#remotes::install_github("nmfs-fish-tools/nmfspalette")

selected.surv.clean <- read.csv("/Users/lillianraz/Downloads/selected_surv_clean.csv", header=TRUE)

#assuming there are at least 5 unique ages in dataset...
if (selected.surv.clean$AGE %>% unique() %>% length() >= 5) {
  # define the type of von b model
  vb <- FSA::vbFuns(param = "Typical")
  # define starting parameters based on the available data
  f.starts <- FSA::vbStarts(LENGTH ~ AGE, data = selected.surv.clean, methLinf = "oldAge")
  # fit a non-linear least squares model based on the data and starting values
  f.fit <- nls(LENGTH ~ vb(AGE, Linf, K, t0), data = selected.surv.clean, start = f.starts)
  # store the fit parameters for later investigation
  f.fit.summary <- summary(f.fit, correlation = TRUE)
  # define the range of age values that will be used to generate points from the fitted model
  # roughly by 0.2 year steps
  newages <- data.frame(AGE = seq(0, 50, length = 250))
  # this function uses the model from f.fit to generate new lengths:
  # predict(f.fit,newdata=newages) #included as LENGTH below
  # make a dataset with the values from the model
  selected.surv.vonb <- data.frame(AGE = seq(1, 50, length = 250), 
                                   LENGTH = predict(f.fit, newdata = newages))
} else {
  print("NOT ENOUGH DATA TO FIT A CURVE")
}


# Growth parameters of `Linf` (Length infinity), `K` (growth coefficient), and  
# `t0` (size at time 0) were estimated using non-linear least square model. 
# The starting point for model building is accomplished using `FSA::vbStarts`. 
# Age and length data sourced from `survdat` and spans all years and survey areas.


# palette
# Check for NA values in YEAR column
if (any(is.na(selected.surv.clean$YEAR))) {
       print("YEAR column contains NA values")
  } else {
# color mapping:
 if (nrow(selected.surv.clean) > 50) {
  fig <- ggplot2::ggplot(
    data = selected.surv.clean,
    ggplot2::aes(
      x = AGE,
      y = LENGTH,
      color = YEAR %>% as.numeric()
    )
  ) +
    ggplot2::geom_jitter(alpha = 0.5) +
    ggplot2::scale_color_gradientn(
      colors = nmfspalette::nmfs_palette("regional")(4),
      name = "Year"
    ) +
    ggplot2::xlim(0, (1.2 * max(selected.surv.clean$AGE))) +
    ggplot2::ylim(0, (1.2 * max(selected.surv.clean$LENGTH, na.rm = TRUE))) +
    ggplot2::xlab("Age (jittered)") +
    ggplot2::ylab("Total length (cm) (jittered)") +
    # ggplot2::ggtitle(species, subtitle = "Length at age") +
    ggplot2::theme_minimal()
  if (nrow(selected.surv.vonb) > 0) {
    fig <- fig +
      ggplot2::geom_line(
        data = selected.surv.vonb,
        inherit.aes = FALSE,
        mapping = ggplot2::aes(
          x = AGE,
          y = LENGTH
        ),
        color = "blue",
        size = 1.4
      )
  }
  print(fig)
} else {
  print("NO DATA")
}
  }
