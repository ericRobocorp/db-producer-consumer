*** Settings ***
Library     Collections
Library     RPA.Robocorp.WorkItems
Library     RPA.Excel.Files
Library     RPA.Tables
Library     RPA.FileSystem
Library     RPA.Database
Library     RPA.Robocorp.Vault
Library     String


*** Variables ***
${TABLE}                workitems    # name of table in your database containing the stored work items
${ORDER_FILE_NAME}=     orders.xlsx


*** Tasks ***
Split orders file
    [Documentation]    Read orders file from input item and split into outputs
    TRY
        Get Work Item File    ${ORDER_FILE_NAME}
    EXCEPT    FileNotFoundError    type=START
        Copy file    devdata/work-items-in/split-orders-file-test-input/orders.xlsx    orders.xlsx
    END
    Open Workbook    ${ORDER_FILE_NAME}
    ${table}=    Read Worksheet As Table    header=True
    ${groups}=    Group Table By Column    ${table}    Name
    Open database connection

    FOR    ${products}    IN    @{groups}
        ${rows}=    Export Table    ${products}
        @{items}=    Create List
        FOR    ${row}    IN    @{rows}
            ${name}=    Set Variable    ${row}[Name]
            ${zip}=    Set Variable    ${row}[Zip]
            Append To List    ${items}    ${row}[Item]
        END
        ${id}=    Store workitems in database    ${name}    ${zip}    ${items}

        # Only the ID of the associated SQL row is stored in Control Room Work Items, all other data is stored in the Database
        ${variables}=    Create Dictionary    id=${id}
        Create Output Work Item    variables=${variables}    save=True
    END
    Close database connection


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

Store workitems in database
    [Documentation]    Generates a random string to be used as the unique ID for the row in the database
    ...    then stores the work item data in the database and returns only the unique ID
    [Arguments]    ${name}    ${zip}    ${items}
    ${id}=    Generate Random String    length=8    chars=[NUMBERS]
    ${str_items}=    Catenate    SEPARATOR=,    @{items}
    ${query}=    Set Variable    '${id}','${name}','${zip}','${str_items}'
    Query    INSERT INTO ${TABLE} (id,name,zip,items) VALUES (${query})
    Log To Console    ${query}
    RETURN    ${id}

Close database connection
    [Documentation]    closes database connection
    Disconnect From Database
