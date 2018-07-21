# Salesforce Connect Custom Apex Adapter Example - Toggl

This is an example of how to use Salesforce Connect to seamlessly integrate data from [Toggl](https://toggl.com) without storing any data in Salesforce itself. Please keep in mind that Salesforce Connect is a significant PAID add on to your standard contract. Please read [the consideration page](https://help.salesforce.com/articleView?id=platform_connect_considerations.htm&type=5) before starting your project using this feature set.

This example was significantly modified from an example provided on [Jitendra Zaa's blog](https://www.jitendrazaa.com/blog/salesforce/implementing-custom-apex-adapter-for-salesforce-connect/).

## Preview/Test in SFDX Scratch Org
1) Make manual updates for credentials and workspace id
    - workspaceId in TogglDetailedReport.cls (line 131)
        - *Optional - Update parameters (line 132)*
    - In Toggl_Reports.namedCredential-meta.xml
        - update the "username" value to your toggl api key.
        - leave "password" as is.
2) Create scratch org and push code
3) Add current user to permission set
    ```
    $ sfdx force:user:permset:assign -n Toggl_Users
    ```
4) Navigate to "Detailed Report Items" tab and view data to validate it is working as intended
    - Optional - you can also run a SOQL query to return data
    ```
    SELECT Id, ExternalId, Project_Id__c, Project_Name__c, Client_Name__c, Start_Time__c, End_Time__c, Duration__c, DisplayUrl From DetailedReportItem__x LIMIT 10
    ```
</br>

![Data](https://user-images.githubusercontent.com/3085186/43039722-8f9afecc-8d01-11e8-9dd0-34bc538ee04b.png)