import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import cx_Oracle
import datetime
import base64  
from datetime import timedelta
from Batch_Data_Load import get_portfolio_data
from Batch_Data_Load import get_account_Name
from Categories import assign_to_category
from PIL import Image
from concurrent.futures import ThreadPoolExecutor  # Add this line

#Logging file
file1 = open("streamlit_logs.txt", "a") # append mode

# Set the page layout to "wide" and expand the sidebar by default
st.set_page_config(
    layout="wide",
    initial_sidebar_state="expanded",
    page_icon=r"D:\Extracts\KPIs\New KCB template.png",  # You can set a custom page icon here as well
)

# Add logo at the top right hand of page
t1, t2, t3, t4 = st.columns([0.1+2.3+0.1, 1.3/2, 1.3/2, 0.1])
with t3:
    image0 = Image.open(r"New_KCB_template.png")
    st.image(image0, width=60, use_column_width=False)

# Streamlit app title and description
st.title('Account Daily Balance Analysis Dashboard')
st.markdown('''The purpose of the Deposits stickiness model is for Pricing the Deposits based \
    on the length of time we hold the deposits and the core part of the deposit''')

# Database connection
dbCon = cx_Oracle.connect('REPORTS_USER[DNAENV]/ma#n#d#gT#123#A@//172.17.122.75:1521/EDWHDR') 

# Create a two-column layout, with the first column taking up 1/5 of the screen width
input_column, main_column = st.columns([1, 5])

# Initialize lists to store counts
counts_max = []
counts_min = []
            
# Initialize lists to store results
results = []
# In the input column, to take in user inputs
with input_column:

    # Input for 'n' - Set the number of y-axis splits (n)
    n = st.slider('y-axis splits:', 1, 200, 100, help = "Set the number of y-axis splits (n)")
    #Set the Dates
    # Calculate DATE_RANGE_START as three years before DATE_RANGE_END
    DATE_RANGE_START = st.date_input("Select Start date", datetime.date.today() - timedelta(days=3*365))  # Assuming 1 year = 365 days

    # Set End date as today
    DATE_RANGE_END = st.date_input("Select end date", datetime.date.today())
    
    # In the input column, to take in user inputs
    text_input = st.text_input("Enter account numbers separated by comma")

    # Check if the input string is not empty
    if text_input:
        # Split the input string by comma, filter out empty strings, and convert each part to an integer
        accounts = [int(num.strip()) for num in text_input.split(",") if num.strip()]
        # Display the list of accounts
        st.write("Accounts:", accounts)

        # Initialize lists to store results
        results = []
        #Split the input string by comma, filter out empty strings, and add ' and ' for each Account
        account_string = ", ".join(["'" + item.strip() + "'" for item in text_input.split(",") if item.strip()])

        ###extract all the datav to a dataframe
        Combined_df = get_portfolio_data(account_string, DATE_RANGE_START, DATE_RANGE_END, dbCon)
        Combined_Name_df = get_account_Name(account_string, dbCon)

        ##Convert Object to numeric
        Combined_Name_df['AC_ACCT_ID']= pd.to_numeric(Combined_Name_df['AC_ACCT_ID'])
        Combined_df['CONTRACT_CODE'] = pd.to_numeric(Combined_df['CONTRACT_CODE'])

        # Define a function to process each account
        # Process each account in the batch
        def process_account(account):
            # Filter the DataFrame where 'id' is equal to account number
            df = Combined_df[Combined_df['CONTRACT_CODE'] == account]
            #Name_df = get_account_Name(account, dbCon)
            Name_df = Combined_Name_df[Combined_Name_df['AC_ACCT_ID'] == account] 
            # Perform analysis and display results for each account
            # ...
            #Generate data for date and daily balance for 3 years
            # date_range = df['LAST_WORK_DAY']
            daily_balance = df['BALANCE']
            # Account = df['CONTRACT_CODE'].drop_duplicates().tolist()
            AC_SHORT_NAME = Name_df['AC_SHORT_NAME'].drop_duplicates().tolist()

            # Calculate the maximum and minimum values for y-axis splits
            y_max = max(daily_balance)
            y_min = min(daily_balance)
            Average_Balance = round(np.mean(daily_balance),0)

            # Format Average_Balance with commas
            formatted_average_balance = "{:,.0f}".format(Average_Balance)

            # y_splits = [y_min] + [i * y_max / n for i in range(1, n+1)]

            # Create two sets of y-axis splits
            y_splits_max =[0] + [i * y_max / n for i in range(1, n+1)]
            y_splits_min = [y_min] + [i * y_min / n for i in range(1, n+1)]

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
            
            # Save input to a text file
            Log_Account = str(account)
            timestamp_string = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            # Get user IP address from query parameters
            query_params = st.experimental_get_query_params()
            ip_address = query_params.get("user_ip", ["Unknown"])[0]
            # Log the timestamp, IP address, and account details
            log_entry = f"{timestamp_string} - IP: {ip_address} - Account: {Log_Account}\n"
            with open("streamlit_logs.txt", "a") as file1:
                file1.write(log_entry)
            file1.close()

            # Append results to the lis

            return {
                'Account': account,
                'Account Name': AC_SHORT_NAME,
                'Average Balance':formatted_average_balance,
                'Deposit days': average_count_max,
                'Deposits category': category,
                'Overdraft days': average_count_min,
                'Overdraft category': Overdraft_category
            }

        # Process each account in the batch using multiple threads
        with ThreadPoolExecutor() as executor:
            future_results = {executor.submit(process_account, account): account for account in accounts}
            for future in future_results:
                results.append(future.result())

        # Close the database connection
        dbCon.close()
    else:
        st.write("Please enter account numbers separated by comma.")

    # You can add more input fields as needed
    run_button = st.button("Run Analysis")

    # In the main column, you can display text, results, and plots
    with main_column:

        # Convert the results list into a Pandas DataFrame
        results_df = pd.DataFrame(results)

        # Display results as a table
        st.write(results_df)

        # Add a download button for the results table
        csv = results_df.to_csv(index=False)
        b64 = base64.b64encode(csv.encode()).decode()
        href = f'<a href="data:file/csv;base64,{b64}" download="results.csv">Download CSV File</a>'
        st.markdown(href, unsafe_allow_html=True)
