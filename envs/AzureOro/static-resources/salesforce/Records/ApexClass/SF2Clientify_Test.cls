@isTest(SeeAllData=true)
public class SF2Clientify_Test {
    
    
    @isTest
    static void testSf2Clientify(){
        
        Test.startTest();
		Contact con = new Contact();
        con.ID_Contacto_Clientify__c = '39555191';
        con.LastName = 'Test';
		insert con;

		Lead le = new Lead();
		le.ID_Contacto_Clientify__c = '39555192';
        le.LastName = 'Test';
        le.Company = 'Test';
		insert le;        
        
		Test.setMock(HttpCalloutMock.class, new mockWSTest());
        
        SF2Clientify.ActionRequest cr = new SF2Clientify.ActionRequest();
        cr.Id = con.Id;
        cr.idClienti = con.ID_Contacto_Clientify__c;
        
        List<SF2Clientify.ActionRequest> l = new List<SF2Clientify.ActionRequest>();
        l.add(cr);
        SF2Clientify.clientifyPutContacts(l);
        
        cr.Id = le.Id;
        cr.idClienti = le.ID_Contacto_Clientify__c;
        
        l.add(cr);
        SF2Clientify.clientifyPutContacts(l);
		Test.stopTest();
    }
    
    
    public class mockWSTest implements HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
        	res.setHeader('Content-Type', 'application/json');
        	res.setBody('{"example":"test"}');
        	res.setStatusCode(200);
        	return res;
		}
	}

}