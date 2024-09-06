/**
 * @description       : 
 * @author            : jose.murillo
 * @group             : 
 * @last modified on  : 27-04-2023
 * @last modified by  : jose.murillo
**/


global with sharing class SF2Clientify {
    
    /*An invocable variable used as input or output variables in the process builder*/
    global class ActionRequest {
        @InvocableVariable(required = true)
        public String Id;

        @InvocableVariable(required = true)
        public String idClienti;
    }
    
    @InvocableMethod(label='Edit Contact in Clientify' description='Si se invoca esta clase, se actualiza el contacto en Clientify')
    public static void clientifyPutContacts(List <ActionRequest> requests){
        	String idClientify;
        	Id idObj;
        	Boolean converted;
            for (ActionRequest requestObj: requests) {
                  idObj =  requestObj.Id;
                  idClientify = requestObj.idClienti;
            }
        	String objName = idObj.getSObjectType().getDescribe().getName();
        	String integration = '/v1/contacts';
         	integration = integration + '/' + idClientify + '/' ;
        	JSONGenerator jsGen = JSON.createGenerator(true);
            jsGen.writeStartObject(); 
            if (objName=='Contact'){
                for(Contact contactClienti : [SELECT ID, ID_Contacto_Clientify__c, HasOptedOutOfEmail FROM Contact WHERE ID_Contacto_Clientify__c =:idClientify LIMIT 1]){
                      if(contactClienti.HasOptedOutOfEmail==true){
                          jsGen.writeBooleanField('unsubscribed', true); 
                      }else{
                          jsGen.writeBooleanField('unsubscribed', false); 
                      } 
                }
                
            } else if(objName=='Lead'){
                for(Lead leadClienti : [SELECT ID, ID_Contacto_Clientify__c, HasOptedOutOfEmail, isConverted FROM LEAD WHERE ID_Contacto_Clientify__c =:idClientify LIMIT 1]){
                    converted=leadClienti.IsConverted;		//SI ESTA CONVERTIDO NO SE MANDA NADA A CLIENTIFY - IF 
                    if(leadClienti.HasOptedOutOfEmail==true){
                        jsGen.writeBooleanField('unsubscribed', true); 
                                }else{
                        jsGen.writeBooleanField('unsubscribed', false); 
                     } 
            	}
            }
            jsGen.writeEndObject();
            String jsonData = jsGen.getAsString();
            System.debug('json format Data==> ' + jsonData);
            if (converted==false){
                callRestWS(jsonData,integration);			//SOLO MANDAMOS DATOS A CLIENTIFY SI EL LEAD NO ESTA CONVERTIDO
            }
    }
    @future(callout=true)
    public static void callRestWS(String body, String integration){
                 
            String bodyResponse;
            String namedCredential = 'Clientify';
            String endpoint;
        
            Log__c log = new Log__c();
			log.recordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName() .get('Outbound').getRecordTypeId();
			log.Endpoint_WS__c = endpoint + '/' +integration;
			log.Timestamp__c = System.now();
			log.Service_Name__c = integration;
            if(body != null) {
                 String requestBody = JSON.serializePretty(body);
                 log.Request__c = requestBody.length() > 131000 ? requestBody.abbreviate(131072) : requestBody; 
            }
                        
            //Hacemos la llamada Rest a Clientify
            try {
                HttpRequest req = new HttpRequest();
                HttpResponse res = new HttpResponse();
                req.setEndpoint('callout:' + namedCredential + '/' + integration);
                req.setMethod('PUT');
                req.setBody(body);
                req.setTimeout(120000);
                req.setHeader('Content-Type', 'application/json');
                Http httpReq = new Http();
                res = httpReq.send(req);
                bodyResponse = res.getBody();
                log.Server_Response__c = res.getStatusCode() + ': ' + res.getStatus();
                log.Response_Body__c = bodyResponse.length() > 131000 ? bodyResponse.abbreviate(131072) : JSON.serializePretty(bodyResponse);
                log.Result__c = 'Success';
			}
			catch (CalloutException e) {
				log.Result__c = 'Error';
				log.Callout_Error__c = e.getMessage();
				bodyResponse = log.Result__c + ': ' + log.Callout_Error__c;
			}
        	finally {
				insert log;
            }
    }
}