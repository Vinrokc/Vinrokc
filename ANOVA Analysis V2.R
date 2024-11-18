#####################################################################################################################
#----------------------------------  ANOVE Analysis ----------------------------------
###http://www.sthda.com/english/wiki/one-way-anova-test-in-r
## Author: Rop Vincent Kipchirchir
## Date:    June 2020       
## Tel:    (254) 725666622
## Email1: Vincent.Kipchirchir@absa.africa

rm(list=ls(all=TRUE))
options("scipen" = 1000)

setwd("C:/Users/AB006HT/OneDrive - Absa/My Documents/Credit/PD ANOVA")

#Library

library(dplyr)
library(ggpubr)
library(gplots)
library(ggplot2)
library(plyr)
theme_set(theme_pubr())

#Load Data
library(readr)
my_data <- read_csv("data 2.csv")

#------------------- The final scoring data

my_data <- my_data[,c("DPD_Split", "PD","Model")]

# Show a random sample
set.seed(1234)
dplyr::sample_n(my_data, 10)


# Show the levels
my_data$DPD_Split <- as.factor(my_data$DPD_Split)

my_data$Model <- as.factor(my_data$Model)

levels(my_data$DPD_Split)

levels(my_data$Model)

#If the levels are not automatically in the correct order, re-order them as follow:

my_data$DPD_Split <- ordered(my_data$DPD_Split,
                         levels = c("0 days","1-30 days","31-60 days"))

#Compute summary statistics by groups - count, mean, sd:
d_summary <- group_by(my_data, DPD_Split, Model) %>%
  dplyr::summarise(
        count = n(),
        mean = mean(PD, na.rm = TRUE),
        med = median(PD),
        sd = sd(PD, na.rm = TRUE)
       )


#Separate ANOVA Per Model Used/Loan Type

my_data_KEMortgage <- my_data[my_data$Model == 'KEMortgage' , ]
my_data_KEUnsec <- my_data[my_data$Model == 'KEUnsec' , ]
my_data_KEUnsecScheme <- my_data[my_data$Model == 'KEUnsecScheme' , ]

#Visualize your data
# Box plots
# ++++++++++++++++++++
# Plot PD by DPD_Split and color by DPD_Split

ggboxplot(my_data, x = "DPD_Split", y = "PD", 
          color = "DPD_Split", palette = c("#00AFBB", "#E7B800", "#FC4E07","#7570B3","#E7298A", "#66A61E", "#E6AB02", "#A6761D"),
          order = c("0 days","1-30 days","31-60 days"),
          ylab = "PD", xlab = "DPD_Split",
          main="PD by DPD_Split Box plots")




# Mean plots
# ++++++++++++++++++++
# Plot PD by DPD_Split
# Add error bars: mean_se
# (other values include: mean_sd, mean_ci, median_iqr, ....)
ggline(my_data, x = "DPD_Split", y = "PD", 
       add = c("mean_se", "jitter"), 
       order = c("0 days", "1-30 days","31-60 days"),
       ylab = "PD", xlab = "DPD_Split",
       main="PD by DPD_Split Mean plots with error bars")

#Compute Medians
d_meds <- ddply(my_data, .(DPD_Split,Model), summarise, med = median(PD))

# Box plot
boxplot(PD ~ Model, data = my_data,
        xlab = "Model", ylab = "PD",
        frame = FALSE, col = c( "#FF8C00", "#FC4E07","#F08080","#DC143C", "#F08080", "#FF0000", "#A6761D"),
        main="PD by Model Box plots" )

boxplot(PD ~ DPD_Split, data = my_data,
        xlab = "DPD_Split", ylab = "PD",
        frame = FALSE, col = c( "#FF8C00", "#FC4E07","#F08080","#DC143C", "#F08080", "#FF0000", "#A6761D"),
        main="PD by DPD_Split Box plots" )


ggplot(my_data, aes(DPD_Split, PD, fill=Model)) +
  geom_boxplot() +
  labs(title = "PD by DPD_Split Box plots per Model/ Loan category") +
  theme_pubclean()


# plotmeans
plotmeans(PD ~ DPD_Split, data = my_data, frame = FALSE,
          xlab = "DPD_Split", ylab = "PD",
          main="Mean Plot with 95% CI") 


# Compute the analysis of variance
res.aov <- aov(PD ~ DPD_Split, data = my_data)
# Summary of the analysis
summary(res.aov)


#Tukey multiple pairwise-comparisons
#The function TukeyHD() takes the fitted ANOVA as an argument
TukeyHSD(res.aov)

#OR Multiple comparisons using multcomp package
library(multcomp)
summary(glht(res.aov, linfct = mcp(DPD_Split = "Tukey")))

#OR Pairewise t-test
#The p-values are adjusted by the Benjamini-Hochberg method.
pairwise.t.test(my_data$PD, my_data$DPD_Split,
                p.adjust.method = "BH")

#Check ANOVA assumptions: test validity

#Check the homogeneity of variance assumption
#The residuals versus fits plot can be used to check the homogeneity of variances.
# 1. Homogeneity of variances
plot(res.aov, 1)


#It's also possible to use Bartlett's test or Levene's test to check the homogeneity of variances.
library(car)
leveneTest(PD ~ DPD_Split, data = my_data)

#Check the normality assumption
#Normality plot of residuals.
# 2. Normality
plot(res.aov, 2)

#supported by the Shapiro-Wilk test on the ANOVA residuals
# Extract the residuals
aov_residuals <- residuals(object = res.aov )
# Run Shapiro-Wilk test
shapiro.test(x = aov_residuals )

#Non-parametric alternative to one-way ANOVA test

  kruskal.test(PD ~ DPD_Split, data = my_data)




