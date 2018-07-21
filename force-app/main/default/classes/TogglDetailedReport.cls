/**
 * @Desc	-	Salesforce Connect Custom Adapter using Apex for Toggl API
 * @Date	-	2018-07-01
 * @Author	-	Mike Simpson
 *
 * Forked from example on https://www.jitendrazaa.com/blog/salesforce/implementing-custom-apex-adapter-for-salesforce-connect/
 * */
global class TogglDetailedReport extends DataSource.Connection {
    
    private final String EXT_BASE_API_URL = 'https://toggl.com/api/v8';
    private final String EXT_REPORT_API_URL = 'https://toggl.com/report/api/v2';
    private final String COL_HEADER_ID = 'id';
    private final String COL_HEADER_PID = 'pid';
    private final String COL_HEADER_PROJECT = 'project';
    private final String COL_HEADER_CLIENT = 'client';
    private final String COL_HEADER_START = 'start';
    private final String COL_HEADER_END = 'end';
    private final String COL_HEADER_DURATION = 'dur';
    private final String COL_HEADER_DISPLAYURL = 'DisplayUrl';
    private final String COL_HEADER_EXTERNAL_ID = 'ExternalId'; 
    
    private DataSource.ConnectionParams conParam ;
        
    //Constructor
    global TogglDetailedReport(DataSource.ConnectionParams connectionParams){    
        conParam = connectionParams; 
    }
    
    /**
     * Below method is invoked if global search is used or SOSL issued
     * */
    override global List<DataSource.TableResult> search(DataSource.SearchContext context) {
        List<DataSource.TableResult> results = new List<DataSource.TableResult>();
        for (DataSource.TableSelection tableSelection : context.tableSelections) {
            results.add(DataSource.TableResult.get(tableSelection, getRows( )));
        }
        return results;
    }
    
    /**
     * Abstract Method sync() must be implemented as part of DataSource.Connection class
     * This methos would define Schema of External Object
     * 
     * NOTE : ExternalId and DisplayURL are manadatory column
     * */
    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();
        
        List<DataSource.Column> columns = new List<DataSource.Column>();

        columns.add(DataSource.Column.text(COL_HEADER_PID, 18));
        columns.add(DataSource.Column.text(COL_HEADER_PROJECT,255));
        columns.add(DataSource.Column.text(COL_HEADER_CLIENT, 255));
        columns.add(DataSource.Column.text(COL_HEADER_DISPLAYURL, 1000));
        columns.add(DataSource.Column.text(COL_HEADER_EXTERNAL_ID, 18));
        columns.add(DataSource.Column.text(COL_HEADER_START,20)); 
        columns.add(DataSource.Column.text(COL_HEADER_END,20));
        columns.add(DataSource.Column.integer(COL_HEADER_DURATION,18));
        
        /* Additional fields to be implemented later if required
            columns.add(DataSource.Column.text('tid', 18));
            columns.add(DataSource.Column.text('task', 255));
            columns.add(DataSource.Column.text('uid',18));
            columns.add(DataSource.Column.text('user',255));
            columns.add(DataSource.Column.text('description', 255));
            columns.add(DataSource.Column.text('updated',20));
            columns.add(DataSource.Column.boolean('use_stop'));
            columns.add(DataSource.Column.boolean('is_billable'));
            columns.add(DataSource.Column.text('cur',3));
            columns.add(DataSource.Column.text('tags',255));
        */

        /* Field Reference from API Documentation: https://github.com/toggl/toggl_api_docs/blob/master/reports/detailed.md
            id: time entry id
            pid: project id
            project: project name for which the time entry was recorded
            client: client name for which the time entry was recorded
            tid: task id
            task: task name for which the time entry was recorded
            uid: user id whose time entry it is
            user: full name of the user whose time entry it is
            description: time entry description
            start: start time of the time entry in ISO 8601 date and time format (YYYY-MM-DDTHH:MM:SS)
            end: end time of the time entry in ISO 8601 date and time format (YYYY-MM-DDTHH:MM:SS)
            dur: time entry duration in milliseconds
            updated: last time the time entry was updated in ISO 8601 date and time format (YYYY-MM-DDTHH:MM:SS)
            use_stop: if the stop time is saved on the time entry, depends on user's personal settings.
            is_billable: boolean, if the time entry was billable or not
            billable: billed amount
            cur: billable amount currency
            tags: array of tag names, which assigned for the time entry
        */
        
        tables.add(DataSource.Table.get('DetailedReportItem', 'ExternalId', columns)); 
        return tables;
    }
    
    /**
     * This method is called everytime when SOQL is issued against external Object
     * or while using list view or viewing detail page.
     * 
     * Note : Ideally searching should be done at server side however for sake of 
     * simplicity, we would be using "DataSource.QueryUtils" class provided by
     * Salesforce. In this case, filtering and sorting would be done in Salesforce
     * once response returned by external REST API
     * */
     override global DataSource.TableResult query( DataSource.QueryContext context) {
        if (context.tableSelection.columnsSelected.size() == 1 && context.tableSelection.columnsSelected.get(0).aggregation == DataSource.QueryAggregation.COUNT) {
                List<Map<String,Object>> rows = getRows( );
                List<Map<String,Object>> response = DataSource.QueryUtils.filter(context, getRows( ));
                List<Map<String, Object>> countResponse = new List<Map<String, Object>>();
                Map<String, Object> countRow = new Map<String, Object>();
                countRow.put( context.tableSelection.columnsSelected.get(0).columnName, response.size());
                countResponse.add(countRow);
                return DataSource.TableResult.get(context, countResponse);
        } else {
            List<Map<String,Object>> filteredRows =  DataSource.QueryUtils.filter(context, getRows( ));
            List<Map<String,Object>> sortedRows = DataSource.QueryUtils.sort(context, filteredRows);
            List<Map<String,Object>> limitedRows = DataSource.QueryUtils.applyLimitAndOffset(context, sortedRows);
            return DataSource.TableResult.get(context, limitedRows);
        }
    }
    
    /**
     * Make REST callout to external system and parse the result in required format
     * */
    private List<Map<String,Object>> getRows( ){
        
        List<Map<String, Object>> lstReturnDataset =  new List<Map<String, Object>>();

        // Hardcoded parameters for easy proof of concept
        String workspaceId = '#######'; //***fill before deploying****
        String urlParams = '/details?workspace_id=' + workspaceId + '&since=2018-07-19&until=2018-07-21&user_agent=sfdx_toggl_connect';

        HttpRequest req = new HttpRequest();
        req.setEndPoint('callout:Toggl_Reports'+urlParams); //uses the Toggl_Reports Named Credential
        //req.setEndPoint(EXT_REPORT_API_URL+urlParams); //uses the Toggl_Reports Named Credential
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        
        Map<String, Object> json_resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        
        List<Object> data = (List<Object>)json_resp.get('data');
        
        for(Object detail : data){
            Map<String, Object> detailMap = (Map<String, Object>) detail;
            Map<String, Object> curRow = new Map<String, Object>();
            
            curRow.put(COL_HEADER_EXTERNAL_ID, detailMap.get('id'));
            curRow.put(COL_HEADER_PID,detailMap.get(COL_HEADER_PID));
            curRow.put(COL_HEADER_PROJECT,detailMap.get(COL_HEADER_PROJECT));
            curRow.put(COL_HEADER_CLIENT,detailMap.get(COL_HEADER_CLIENT));
            curRow.put(COL_HEADER_START,detailMap.get(COL_HEADER_START));
            curRow.put(COL_HEADER_END,detailMap.get(COL_HEADER_END));
            curRow.put(COL_HEADER_DURATION,detailMap.get(COL_HEADER_DURATION));
            curRow.put(COL_HEADER_DISPLAYURL,EXT_BASE_API_URL+'/time_entries/'+detailMap.get('id'));
             
            lstReturnDataset.add(curRow);
        }
        
        return lstReturnDataset;
    } 
}