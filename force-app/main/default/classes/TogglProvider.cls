/**
 * @Date	-	2018-07-20
 * @Author	-	Mike Simpson
 * @Desc	:	DataSource.Provider class informs Salesforce of the functional and 
 * authentication capabilities that are supported by or required to connect to the external system
 * */
global class TogglProvider extends DataSource.Provider {
     
    override global List<DataSource.AuthenticationCapability> getAuthenticationCapabilities() {
        List<DataSource.AuthenticationCapability> capabilities =  new List<DataSource.AuthenticationCapability>();
        //capabilities.add(DataSource.AuthenticationCapability.OAUTH);
        //capabilities.add(DataSource.AuthenticationCapability.BASIC);
        capabilities.add(DataSource.AuthenticationCapability.ANONYMOUS); // Using Named Credential for authentication
    	return capabilities;
	}
    
    override global List<DataSource.Capability> getCapabilities()
    {
        List<DataSource.Capability> capabilities = new List<DataSource.Capability>();
        capabilities.add(DataSource.Capability.ROW_QUERY);
        capabilities.add(DataSource.Capability.SEARCH); 
        //capabilities.add(DataSource.Capability.ROW_CREATE);
        //capabilities.add(DataSource.Capability.ROW_UPDATE);
        //capabilities.add(DataSource.Capability.ROW_DELETE);
        return capabilities;
    }
    
    override global DataSource.Connection getConnection(DataSource.ConnectionParams connectionParams) {   
        return new TogglDetailedReport(connectionParams);
    } 
} 