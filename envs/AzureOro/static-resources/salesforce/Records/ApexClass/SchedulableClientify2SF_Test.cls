/**
**
**/
@isTest(SeeAllData=true)
public class SchedulableClientify2SF_Test {

	//=====================================================================//
	//============================  VARIABLES  ============================//
	//=====================================================================//
	static Lead lead;
	static Account account;
	static Contact contact1;
	static Contact contact2;
  
    @isTest
	static void testcallClientify(){
        
        
     	Clienti_Settings__c cs = new Clienti_Settings__c();
        cs.Name='Test';
        cs.Next_callout_URL__c='null';
        cs.Processed_records__c=0;
        cs.Record_count__c=0;
     	insert cs;
        
        Log__c logRecord = new Log__c();
        insert logRecord;
        
        Integer ok = 0;
        Integer ko = 0;
        List <String> listaString = new List<String>();
        listaString.add('43902662');
        
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new mockWSTest());
        SchedulableClientify2SF batch = new SchedulableClientify2SF(logRecord, ok, ko); 	
		Id batchId = Database.executeBatch(batch,1);	
        Database.executeBatch(new IntegracionClientify2SF_Contacts_Batch(listaString), 1);
		Test.stopTest();

    }
    
    public class mockWSTest implements HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req) {
			Map<String, String> response = new Map<String, String>();
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count": 26,"next": "null","previous": null,"results":[{"url": "https://api.clientify.net/v1/contacts/43902662/","id": 43902662,"owner": "borja.carrasco@pkf-attest.es","owner_name": "Borja Carrasco Diaz","first_name": "Lander","last_name": "Ortiz Crespo","status": "cold-lead"}], "unsubscribed": false, "related_tasks":[{"id": 47953386969,"status_desc": "Completed","description": "Completed","duration": 0},{"id": 47953386965,"status_desc": "Completed","description": "Completed","duration": 10}], "wall_entries": [{"id": 1358916047,"created": "2023-02-13T18:10:00+01:00","extra": "call_duration: 12.0, call_type: recibida"},{"id": 1358915557,"created": "2023-02-13T18:10:00+01:00","extra": "message_subject: Presentación Salesforce"}] }');
			res.setStatusCode(200);
			return res;
		}
	}
}