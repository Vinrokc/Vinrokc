import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import cx_Oracle
import datetime
from datetime import timedelta
from Data_Load import get_portfolio_data
from Categories import assign_to_category
import os
import random
from PIL import Image
from inspect import ArgInfo
from scipy.optimize import root_scalar

#Logging file
file1 = open("streamlit_logs.txt", "a") # append mode

# Set the page layout to "wide" and expand the sidebar by default
st.set_page_config(
    layout="wide",
    initial_sidebar_state="expanded",
    page_icon=r"D:\Extracts\KPIs\New KCB template.png",  # You can set a custom page icon here as well
)


# Add logo at the top right hand of page
# Add logo at the top right hand of page
t1, t2, t3, t4 = st.columns([0.1+2.3+0.1, 1.3/2, 1.3/2, 0.1])
with t3:
    image0 = Image.open(r"New_KCB_template.png")
    st.image(image0, width = 60,
             use_column_width = False)

# Streamlit app title and description
st.title('Account Daily Balance Analysis Dashboard')
st.markdown('''The purpose of the Deposits stickiness model is for Pricing the Deposits based \
    on the legth of time we hold the deposits and the core part of the deposit''')

# Create a two-column layout, with the first column taking up 1/5 of the screen width
input_column, main_column = st.columns([1, 5])

# In the input column, to take in user inputs
with input_column:
   
    # Input for 'n' - Set the number of y-axis splits (n)
    n = st.slider('y-axis splits:', 1, 200, 100, help = "Set the number of y-axis splits (n)")

    # Enter desired Account
    Account = st.number_input(label = "Account number", 
                               value = 1134677545, help = "Enter the Customer's Account")

    
    #Set the Dates
    # Calculate DATE_RANGE_START as three years before DATE_RANGE_END
    DATE_RANGE_START = st.date_input("Select Start date", datetime.date.today() - timedelta(days=3*365))  # Assuming 1 year = 365 days

    # Set End date as today
    DATE_RANGE_END = st.date_input("Select end date", datetime.date.today())

    # Calculate DATE_RANGE_START as three years before DATE_RANGE_END
    #DATE_RANGE_START = st.date_input("Select Start date", DATE_RANGE_END - timedelta(days=3*365))  # Assuming 1 year = 365 days

      # You can add more input fields as needed
    run_button = st.button("Run Analysis")

dbCon = cx_Oracle.connect('REPORTS_USER[DNAENV]/ma#n#d#gT#123#A@//172.17.122.75:1521/EDWHDR') 

df = get_portfolio_data(Account,DATE_RANGE_START, DATE_RANGE_END, dbCon)

#Generate data for date and daily balance for 3 years
date_range = df['LAST_WORK_DAY']
daily_balance = df['BALANCE']
Account = df['CONTRACT_CODE'].drop_duplicates().tolist()

# Calculate the maximum and minimum values for y-axis splits
y_max = max(daily_balance)
y_min = min(daily_balance)
Average_Balance = round(np.mean(daily_balance),0)

# Format Average_Balance with commas
formatted_average_balance = "{:,.0f}".format(Average_Balance)


y_splits = [y_min] + [i * y_max / n for i in range(1, n+1)]


plt.figure(figsize=(12, 6))

# Plot daily balance
plt.plot(date_range, daily_balance, label='Daily Balance')

# Customize y-axis splits
plt.yticks(y_splits)

# Create two sets of y-axis splits
y_splits_max =[0] + [i * y_max / n for i in range(1, n+1)]
y_splits_min = [y_min] + [i * y_min / n for i in range(1, n+1)]

# Initialize lists to store counts
counts_max = []
counts_min = []

# Calculate counts above each y-axis split for both sets
for split_max, split_min in zip(y_splits_max, y_splits_min):
    #days_above_split_max = len([balance for balance in daily_balance if balance > split_max])
    days_above_split_max = len([balance for balance in daily_balance if 0 < balance > split_max])
    days_above_split_min = len([balance for balance in daily_balance if 0 > balance < split_min])
    counts_max.append(days_above_split_max)
    counts_min.append(days_above_split_min)

# Calculate average counts
average_count_max = round(np.mean(counts_max),0)
average_count_min = round(np.mean(counts_min),0)

# Assign the categories
category = assign_to_category(average_count_max)
Overdraft_category = assign_to_category(average_count_min)

# Show plot
plt.title(f'Daily Balance vs Date for {Account}')
plt.xlabel('Date')
plt.ylabel('Daily Balance')
plt.legend()
plt.grid(True)
plt.show()

# Save input to a text file
Log_Account = str(Account)
timestamp_string = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
# Get user IP address from query parameters
query_params = st.experimental_get_query_params()
ip_address = query_params.get("user_ip", ["Unknown"])[0]
# Log the timestamp, IP address, and account details
log_entry = f"{timestamp_string} - IP: {ip_address} - Account: {Log_Account}\n"
with open("streamlit_logs.txt", "a") as file1:
    file1.write(log_entry)
file1.close()

# In the main column, you can display text, results, and plots
with main_column:
    # In the first sub-column, you can display analysis results
    with st.subheader("Stickiness Results"):
        st.subheader("Stickiness Summary")
    
    with st.subheader("Stickiness Results"):
        # Add your analysis results here
        st.write(f"The Average Balance is: {formatted_average_balance}")

    with st.subheader("Stickiness Results"):
        # Add your analysis results here
        st.write(f"Deposit days are: {average_count_max} Categorised as: {category}")

    with st.subheader("Stickiness Results"):
        st.write(f"Overdraft days are: {average_count_min} Categorised as: {Overdraft_category}")

    # In the second sub-column, you can display visualizations (plots)
    with st.subheader("Stickiness summary Plot"):
        # Display the plot
        st.pyplot()

    with st.subheader("Stickiness Results"):
        st.write("Deposits Counts per y-axis splits:")
    with st.subheader("Stickiness Results"):
        st.write(counts_max)

    with st.subheader("Stickiness Results"):
        st.write("Overdraft Counts per y-axis splits:")
    with st.subheader("Stickiness Results"):
        st.write(counts_min)