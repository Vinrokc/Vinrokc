
####################################################################################################
# Clustering Timiza Customers
# Author: Asila Victor
#
####################################################################################################


###############################################
# Importation and Wrangling

setwd("C:\\Users\\AB006HT\\OneDrive - Absa\\My Documents\\Credit\\Timiza FRM Recoveries\\15062020")



#switch scientific options off
options(scipen = 999)

library(readxl)
suppressMessages(library(lubridate))
suppressMessages(library(data.table))
suppressMessages(library(dplyr))
library(dplyr)

# variables to drop
dropColumns <- c("Surname","Forename1","Forename2","Forename3","Salutation","PrimaryID_Type","Postal_Town",
                 "Postal_Country","Emp_date","Postal_Country","Post_code","Physical_Address1",
                 "Physical_Address2","Location_Town","Emp_Type","BusinessDate","Mobile_Number",
                 "Nationality","Postal_Country","SecondaryID_Num","SecondaryID_Type",
                 "OtherID_Num","OtherID_Type","Mobile_Number","Home_Tel_Number","Work_Tel_Number",
                 "Postal_Address1","Postal_Address2","Plot_Num","Location_Country","Date_at_Residence",
                 "PIN_Number","Mobile_Number","Home_Tel_Number","Work_Tel_Number","Postal_Address1",
                 "Postal_Address2","Plot_Num","Location_Country","Date_at_Residence","PIN_Number",
                 "Work_Email","Employer_name","Emp_ind_Type","Lender_Reg_name","Lender_Trading_name",
                 "Lender_Branch_name","Lender_Branch_code","Joint_single_ind","Account_prod_type",
                 "Currency","Perf_NPL_ind","Type_of_Security","MI_CODE","refer_code","product_name")



recoveries_1 <- read_excel("U756CollectionsRecoveries - Closed_15062020_Part 1.xlsx")


recoveries_1 <- recoveries_1[ ,!(names(recoveries_1) %in% dropColumns)]


#save as rds
saveRDS(recoveries_1,"recoveries_1.rds")
rm(recoveries_1)

#####
# import second dataset
recoveries_2 <- read_excel("U756CollectionsRecoveries - Closed_15062020_Part 2.xlsx")

recoveries_2 <- recoveries_2[ ,!(names(recoveries_2) %in% dropColumns)]

#save rds
saveRDS(recoveries_2,"recoveries_2.rds")
rm(recoveries_2)


# import third dataset
recoveries_3 <- read_excel("U756CollectionsRecoveries - Closed_15062020_Part 3.xlsx")

recoveries_3 <- recoveries_3[ ,!(names(recoveries_3) %in% dropColumns)]


saveRDS(recoveries_3,"recoveries_3.rds")
rm(recoveries_3)


# import fourth dataset
recoveries_4 <- read_excel("U756CollectionsRecoveries - Closed_15062020_Part 4.xlsx")

recoveries_4 <- recoveries_4[ ,!(names(recoveries_4) %in% dropColumns)]


saveRDS(recoveries_4,"recoveries_4.rds")
rm(recoveries_4)

# import fifth dataset
recoveries_5 <- read_excel("U756CollectionsRecoveries - Closed_15062020_Part 5.xlsx")

recoveries_5 <- recoveries_5[ ,!(names(recoveries_5) %in% dropColumns)]


saveRDS(recoveries_5,"recoveries_5.rds")
rm(recoveries_5)

# import sixth dataset
recoveries_6 <- read_excel("U756CollectionsRecoveries - Active_15062020.xlsx")

recoveries_6 <- recoveries_6[ ,!(names(recoveries_6) %in% dropColumns)]


saveRDS(recoveries_6,"recoveries_6.rds")
rm(recoveries_6)


####################################################################################################

rm(list = ls())


# import the .rds data
recoveries_1 <- readRDS("recoveries_1.rds")
recoveries_2 <- readRDS("recoveries_2.rds")
recoveries_3 <- readRDS("recoveries_3.rds")
recoveries_4 <- readRDS("recoveries_4.rds")
recoveries_5 <- readRDS("recoveries_5.rds")
recoveries_6 <- readRDS("recoveries_6.rds")

# Get the 
# Append the .rds data
recoveries <- rbind(recoveries_1,recoveries_2,recoveries_3,recoveries_4,recoveries_5,recoveries_6)

# save the data
saveRDS(recoveries,"recoveries.rds")

ID <- recoveries %>%
  group_by(PrimaryID_Num) %>%
  distinct(PrimaryID_Num)

rm(recoveries_1,recoveries_2,recoveries_3,recoveries_4,recoveries_5,recoveries_6)


# ******** run this ************************************
if(!exists("recoveries")){
  recoveries <- readRDS("recoveries.rds")
}

# # Filter loans disbursed before 1st March 2020
# recoveries <- recoveries %>%
#   filter(Disbursement_date < as.Date("2020-04-17") & Disbursement_date > as.Date("2019-10-17"))

# Confirm
# max(recoveries$Disbursement_date)

# # Import the CRB scrub for Timiza ------------------------------------------------------------------------
# setwd("C:\\Users\\ABDL340\\Documents\\Timiza Borrowing Typologies\\Batch298123-2020-Jun-10-1308\\Output1")
# 
# # Import new scrub
# timiza_grades <- read.csv("Summary.csv")
# 
# # Check and select columns
# head(timiza_grades)
# timiza_grades <- timiza_grades %>%
#   group_by(NATIONALID) %>%
#   select(NATIONALID, SCORE, SCOREGRADE, SCORE_MB, SCOREGRADE_MB)
# 
# # Save as RDS
# saveRDS(timiza_grades, "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\New_crb_grades_fine.rds")
# ---------------------------------------------------------------------------------------------------------

if(!exists("New_crb_grades_fine")){
  crb_grades <- readRDS("C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\New_crb_grades_fine.rds")
}

# Reduce the double score grade to one
crb_grades$SCOREGRADE <- substr(crb_grades$SCOREGRADE,1,1)
crb_grades$SCOREGRADE_MB <- substr(crb_grades$SCOREGRADE_MB,1,1)

crb_grades$NATIONALID <- as.character(crb_grades$NATIONALID)

if(any(duplicated(crb_grades$NATIONALID)) == TRUE){
  Timiza_crb <- crb_grades[!duplicated(crb_grades$NATIONALID), ]
}

suppressMessages(library(plyr))

recoveries$Customer_Age <- round((as.numeric(max(as.Date(recoveries$Disbursement_date,
                                                         format = "%Y-%m-%d")+1, na.rm = T) - as.Date(recoveries$Date_of_Birth,
                                                                                                      format ="%Y-%m-%d")))/365,0)

suppressMessages(library(lubridate))

recoveries$Day <- day(recoveries$Disbursement_date)
recoveries$Time <- format(as.POSIXct(strptime(recoveries$CreatedOn, format = "%Y-%m-%d %H:%M")),format = "%H:%M")
# recoveries$Age_of_Loan <- as.numeric(max(as.Date(recoveries$Disbursement_date,
#                                                  format = "%Y-%m-%d")+1,na.rm=T) - as.Date(recoveries$Disbursement_date,
#                                                                                          format ="%Y-%m-%d"))

recoveries$Limit_Utilization <- round(((recoveries$local_orig_amount/recoveries$CreditLimit)*100),2)

# replacing the infinite values with 100
recoveries$Limit_Utilization[which(!is.finite(recoveries$Limit_Utilization))] <- 100

# capping the limit utilization at 100
recoveries$Limit_Utilization[which(recoveries$Limit_Utilization > 100)] <- 100

# add a few columns
recoveries$clv <- recoveries$Instalment_amount - recoveries$Original_Amount
recoveries$Loan_to_repymtn_ratio <- recoveries$clv/recoveries$local_orig_amount
recoveries$Default <- as.factor(ifelse(recoveries$Overdue_balance > 0,1,0))

# add the repayment days column
recoveries <- recoveries %>%
  mutate(Repayment_days = if_else(Overdue_balance == 0,Latest_pymt_date - Disbursement_date,-10000))

####################################################################################################
## Data Aggregations

# merging with crb data scrub

# Rename Primary Id in recoveries
names(recoveries)
colnames(recoveries)[6] <- "NATIONALID"
recoveries_crb <- left_join(recoveries,Timiza_crb, by = "NATIONALID",
                            all.x = T)

#remove duplicated values
recoveries_crb <- recoveries_crb %>%
  distinct(Mobile_Loan_Account_number, .keep_all = T)

saveRDS(recoveries_crb,"C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\recoveries_crb.rds")

write.table(recoveries_crb,"C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\recoveries_crb.txt",
            sep = "\t", quote = T, row.names = F)


suppressMessages(library(Hmisc))

# grouped data
today <- as.Date(max(recoveries$Disbursement_date, na.rm = T), format = '%Y-%m-%d') + 1

recoveries_rfm <- recoveries %>%
  group_by(NATIONALID,Client_Number) %>%
  dplyr::summarise(frequency = n(),
                   recency = as.numeric(today - as.Date(max(Disbursement_date, na.rm = T),format='%Y-%m-%d')),
                   loan_value = sum(abs(local_orig_amount)),
                   Avg_Utilization = mean(Limit_Utilization),
                   Max_Utilization = max(Limit_Utilization,na.rm = T),
                   Min_Utilization = min(Limit_Utilization, na.rm = T)) %>%
  # adding segments
  mutate(segm.freq = ifelse(between(frequency, 1, 1), '1',
                            ifelse(between(frequency, 2, 5), '2-5',
                                   ifelse(between(frequency, 6, 10), '6-10',
                                          ifelse(between(frequency, 11, 20), '11-20', '>20'))))) %>%
  mutate(segm.rec = ifelse(between(recency, 0, 30), '0-30 days',
                           ifelse(between(recency, 31, 60), '31-60 days',
                                  ifelse(between(recency, 61, 90), '61-90 days',
                                         ifelse(between(recency,91,120),'91-120 days','>120 days'))))) %>%
  mutate(segm.val = ifelse((loan_value >= 0 & loan_value <= 50000), '0-50K',
                           ifelse((loan_value > 50000 & loan_value <= 100000), '50K-100K',
                                  ifelse((loan_value > 100000 & loan_value <= 500000), '100K-500K',
                                         ifelse((loan_value > 500000 & loan_value <= 1000000),'500K-1M','>1M')))))


# defining order of boundaries
recoveries_rfm$segm.freq <- factor(recoveries_rfm$segm.freq, 
                                   levels = c('>20', '11-20', '6-10', '2-5', '1'),
                                   labels = c('5','4','3','2','1'))

recoveries_rfm$segm.rec <- factor(recoveries_rfm$segm.rec, 
                                  levels = c('>120 days', '91-120 days', '61-90 days', '31-60 days', '0-30 days'),
                                  labels = c('1','2','3','4','5'))

recoveries_rfm$segm.val <- factor(recoveries_rfm$segm.val, 
                                  levels = c('0-50K', '50K-100K', '100K-500K', '500K-1M', '>1M'),
                                  labels = c('1','2','3','4','5'))

recoveries_rfm$FRM <- paste0(recoveries_rfm$segm.freq,recoveries_rfm$segm.rec,recoveries_rfm$segm.val)



# save to rds
# saveRDS(recoveries_rfm,
#        "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\recoveries_rfm.rds")

# filtered data for RFM
FRM <- recoveries_rfm[c("NATIONALID","FRM")]


# Merge aggregated data with crb data
recoveries_rfm_crb <- merge(recoveries_rfm,Timiza_crb, 
                            by =  "NATIONALID", all.x = T)

#saveRDS(recoveries_rfm_crb,"C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\recoveries_rfm_crb.rds")

# FRM Separate Ratings
separated_ratings <- recoveries_rfm_crb[,c("NATIONALID", "Client_Number","segm.freq","segm.rec",
                                           "segm.val","SCOREGRADE_MB")]

write.table(separated_ratings,
            file = "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\separated_ratings.txt",
            sep = "\t",quote = T, row.names = F)

# 3. Get loan count, latest crecdit limit, max dpd, average clv, num dpd less than 15 days,
# debt due

# detach("package:plyr", unload = TRUE)

# run this *********************************************
#detach("package:plyr", unload=TRUE) 
cust_agg <- recoveries %>%
  group_by(NATIONALID) %>%
  dplyr::summarise(Loan_Count = n(),Max_DPD = max(Days_in_arrears),avg_value = mean(Original_Amount),
                   Outsnd_Int = sum(InterestOutstanding),
                   Tot_Orig_amnt = sum(Original_Amount),Tot_Overdue_bal = sum(Overdue_balance),
                   Tot_Pen_Fee = sum(PenaltyfeeOutstanding),Tot_PP_Out=sum(PrincipalOutstanding),
                   Avg_Limit_Utlzn = round(mean(Limit_Utilization),2),
                   Max_Limit_Utlzn = max(Limit_Utilization, na.rm = T),
                   Min_Limit_Utlzn = min(Limit_Utilization, na.rm = T)
  )

# CR_Limit = CreditLimit

cust_cr_limit <- recoveries_crb %>%
  select(NATIONALID,Client_Number,Disbursement_date,CreditLimit,SCOREGRADE_MB) %>%
  arrange(Client_Number,NATIONALID,Disbursement_date) %>%
  group_by(NATIONALID,Client_Number) %>%
  dplyr::summarise(Latest_Date = max(Disbursement_date, na.rm = T),
                   Latest_CR_limit = last(CreditLimit),
                   First_CR_Limit = first(CreditLimit),
                   Latest_CR_Grade = last(SCOREGRADE_MB),
                   Loan_count = n())

cust_cr_limit$Latest_CR_Grade <- as.factor(cust_cr_limit$Latest_CR_Grade)

# saveRDS(cust_cr_limit,
#        "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\cust_cr_limit.rds")


# Limit Growth Rate
cust_cr_limit_growth <- cust_cr_limit%>%
  mutate(Credit_Diff = Latest_CR_limit - First_CR_Limit,
         Limit_Growth = round(Credit_Diff/Loan_count,2),
         Limit_Growth_Rate = round(Limit_Growth/First_CR_Limit,2),
         Latest_RiskGrade = Latest_CR_Grade)


#
# saveRDS(cust_cr_limit_growth,
#         "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\cust_cr_limit_growth.rds")

##########################################################################################################
# Matrix Limits

# reaname latest_RiskGrade
colnames(cust_cr_limit_growth)[colnames(cust_cr_limit_growth) == "Latest_RiskGrade"] <- "Grade"

cust_cr_limit_growth$Grade <- substr(cust_cr_limit_growth$Latest_CR_Grade,1,1)

M_Seg <- recoveries_rfm[,c("NATIONALID","segm.val")]
F_Seg <- recoveries_rfm[,c("NATIONALID","segm.freq")]

FRM_Seg <- recoveries_rfm[,c("NATIONALID","FRM")]

cust_cr_limit_growth <- merge(cust_cr_limit_growth,F_Seg, by = "NATIONALID")
cust_cr_limit_growth <- merge(cust_cr_limit_growth,FRM_Seg, by = "NATIONALID")


cust_cr_limit_growth$segm.freq <- as.numeric(cust_cr_limit_growth$segm.freq)

#str(cust_cr_limit_growth)
# new_limits <- cust_cr_limit_growth %>%
#   mutate(matrix_limits = ifelse(segm.freq >= 3 & Latest_CR_limit<= 5000 & Grade== "A", Latest_CR_limit*1.5,
#                                 ifelse(segm.freq >= 3 & Latest_CR_limit>5000 & Latest_CR_limit<=10000 & Grade== "A", Latest_CR_limit*1.4,
#                                        ifelse(segm.freq >= 3 & Latest_CR_limit>10000 & Latest_CR_limit<=20000 & Grade== "A",Latest_CR_limit*1.3,
#                                               ifelse(segm.freq >= 3 & Latest_CR_limit>20000 & Grade== "A",Latest_CR_limit*1.2,
#                                                      ifelse(segm.freq >= 3 & Latest_CR_limit<=5000 & Grade== "B",Latest_CR_limit*1.4,
#                                                             ifelse(segm.freq >= 3 & Latest_CR_limit>5000 & Latest_CR_limit<=10000 & Grade== "B",Latest_CR_limit*1.3,
#                                                                    ifelse(segm.freq >= 3 & Latest_CR_limit>10000 & Latest_CR_limit<=20000 & Grade== "B",Latest_CR_limit*1.2,
#                                                                           ifelse(segm.freq >= 3 & Latest_CR_limit>20000 & Grade== "B",Latest_CR_limit*1.1,
#                                                                                  ifelse(segm.freq >= 3 & Latest_CR_limit<=5000 & Grade=="C",Latest_CR_limit*1.3,
#                                                                                         ifelse(segm.freq >= 3 & Latest_CR_limit>5000 & Latest_CR_limit<=10000 & Grade=="C",Latest_CR_limit*1.2,
#                                                                                                ifelse(segm.freq >= 3 & Latest_CR_limit>10000 & Latest_CR_limit<=20000 & Grade=="C",Latest_CR_limit*1.1,
#                                                                                                       ifelse(segm.freq >= 3 & Latest_CR_limit<=5000 & Grade=="D",Latest_CR_limit*1.2,
#                                                                                                              ifelse(segm.freq >= 3 & Latest_CR_limit>5000 & Latest_CR_limit<=10000 & Grade=="D",Latest_CR_limit*1.1,
#                                                                                                                     ifelse(is.na(Grade),Latest_CR_limit*1,
#                                                                                                                            Latest_CR_limit*1)))))))))))))))
# 
# new_limits$matrix_limits[which(is.na(new_limits$matrix_limits))] <- new_limits$Latest_CR_limit[is.na(new_limits$matrix_limits)]
# 
# 
# 
# 
# saveRDS(new_limits,
#         "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\Proposed_Limits_April21.rds")
# 
# write.table(new_limits,
#             "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\Proposed_Limits_April21.txt",
#             sep = "\t",quote = TRUE, row.names = F)

# Latest Credit Score
Cust_CR_Grade <- recoveries_crb %>%
  select(NATIONALID,Disbursement_date,SCORE_MB,SCOREGRADE_MB) %>%
  arrange(NATIONALID,Disbursement_date) %>%
  group_by(NATIONALID) %>%
  dplyr::summarise(Latest_Scoring_Date = max(Disbursement_date, na.rm = T),
                   Latest_CR_Grade = last(SCOREGRADE_MB),
                   Latest_CR_Score = last(SCORE_MB))


# saveRDS(Cust_CR_Grade,
#         "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\Cust_CR_Grade.rds")

# Merging the grouped data

cust_aggregations <- merge(cust_agg,cust_cr_limit, by = "NATIONALID", all.x = T)

cust_aggregations <- merge(cust_aggregations,Cust_CR_Grade, by = "NATIONALID", all.x = T)

cust_aggregations <- merge(cust_aggregations,recoveries_rfm, by = "NATIONALID", all.x = T)


# save
# saveRDS(cust_aggregations,
#         "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\cust_aggregations_crb.rds")

####
# Dashboard data
recoveries_dash <- merge(cust_cr_limit[ ,c("NATIONALID","Latest_CR_limit","Latest_CR_Grade")],
                         FRM, by = "NATIONALID", all.x = T)

recoveries_dash <- merge(recoveries_dash,cust_agg[,c("NATIONALID","Avg_Limit_Utlzn")],
                         by = "NATIONALID")
# 
# recoveries_dash <- merge(recoveries_dash,cust_agg[,c("NATIONALID","Max_DPD")],
#                          by = "NATIONALID")
# 
# recoveries_dash <- merge(recoveries_dash,separated_ratings[,c("NATIONALID","segm.freq", "segm.rec", "segm.val")],
#                          by = "NATIONALID")

write.table(recoveries_dash,
            "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\recoveries_dash.txt",
            sep = "\t",quote = TRUE, row.names = FALSE)

# saveRDS(recoveries_dash, "C:\\Users\\ABDL340\\Documents\\Timiza Refresh\\recoveries_dash_test.rds")
