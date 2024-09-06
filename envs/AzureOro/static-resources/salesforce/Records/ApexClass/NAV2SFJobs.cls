public class NAV2SFJobs {
    
    @AuraEnabled
    public static Object getJobsForAccount(String accountId) 
    {  
        String APEX_CLASS 			= Integration_Util.getRunningClassName();
        String APEX_METHOD 			= Integration_Util.getRunningMethodName();
        List<Object> listaJobs 		= new List<Object>();
        
        String namedCredential 		= 'Navision';
        
        List<Parametro_Integracion__mdt> endpointParmList = [Select Valor__c From Parametro_Integracion__mdt WHERE DeveloperName LIKE 'NAV_JOBS_ENDPOINT'];
        
        if(endpointParmList.size() > 0)
        {
            String NavID = [Select Id, Multicompany_ID__c from Account where id = :accountId].Multicompany_ID__c;
            //String integration = 'NAV-ATTEST-SALESFORCE/ODataV4/Company(\'030-ITC\')/jobSF?$filter=CustomerMulticompanyID%20eq%20'+NavID;
            String integration = endpointParmList[0].Valor__c + NavID;
            String method = 'GET';
            String bodyResponse;
           
            HttpResponse response = Integration_SFDC2EWS_Util.callRestWS(namedCredential, integration, method, null, null, APEX_CLASS, APEX_METHOD);
            
            bodyResponse = response.getBody();
            
            System.debug('Estamos buscando el body response: '+bodyResponse);
            if (String.isNotBlank(bodyResponse)){
                Map<String, Object> mapaJobs = (Map<String, Object>)JSON.deserializeUntyped(bodyResponse);
                listaJobs = (List<Object>)mapaJobs.get('value');
                System.debug(listaJobs);
            } 
        }
        
        return listaJobs;
        
    }   
}