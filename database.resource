*** Settings ***
Library     RPA.Database
Library     RPA.Robocorp.Vault


*** Variables ***
${TABLE}    workitems    # name of the table that holds work item data


*** Keywords ***
Open database connection
    [Documentation]    opens a connection to a database (mysql in this case)
    ...    connection data is stored in the Control Room Vault
    ${db_info}=    Get Secret    mysql_data
    Connect To Database    pymysql
    ...    ${db_info}[database]
    ...    ${db_info}[username]
    ...    ${db_info}[password]
    ...    ${db_info}[location]

Close database connection
    [Documentation]    closes database connection
    Disconnect From Database
