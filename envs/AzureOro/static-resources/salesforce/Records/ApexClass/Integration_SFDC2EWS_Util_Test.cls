/**
* Class Integration_SFDC2EWS_Util_Test
**
* Generic test class for the Integration_SFDC2EWS_Util class.
* @author: Pedro Pachas
**
**/
@isTest
public class Integration_SFDC2EWS_Util_Test {
	//=====================================================================//
	//============================  CONSTANTS  ============================//
	//=====================================================================//
	public static String SERVICE_NAME      = 'GetContacts';
	public static String APEX_CLASS        = Integration_Util.getRunningClassName();
	public static String APEX_METHOD      = Integration_Util.getRunningMethodName();
	public static String METHOD_NAME       = 'execute';

	public static String RECORDTYPE       = 'Contact';
	public static String SALESFORCE_RECORDTYPE   = 'Contact';
	public static String EXTERNAL_ID_FIELD     = 'Id';

	//=====================================================================//
	//============================  VARIABLES  ============================//
	//=====================================================================//
	static Account account;
	static Contact contact1;
	static Contact contact2;

	static List<RecordWrapper> recordWrappers;

	static Map<String, Set<String>>     externalIDs;
	static Map<String, Map<String, String>> softErrorMap;

	static Integration_Settings__c settings;

	//=====================================================================//
	//============================  UTILITIES  ============================//
	//=====================================================================//

	// Inner class used for testing purposes
	public class RecordWrapper
	{
		public String ID     {get; set;}
		public String NAME     {get; set;}
		public String BIRTHDATE {get; set;}
		public String REPORTSTO {get; set;}
		public BOOLEAN NOCALL   {get; set;}
		public String EMAIL   {get; set;}
		public DECIMAL PHONENUMBER   {get; set;}
		public String ACCOUNTTO   {get; set;}
	}

	@TestSetup
	static void loadData(){
		account = new Account();
		account.Name = 'Account';
		insert account;

		List<Contact> contacts = new List<Contact>();

		contact1 = new Contact();
		contact1.LastName = 'lastname1';
		contact1.AccountId = account.Id;
		contact1.Birthdate = Date.newInstance(1995, 07, 31);
		contacts.add(contact1);

		contact2 = new Contact();
		contact2.LastName = 'lastname2';
		contact2.AccountId = account.Id;
		contact2.Birthdate = Date.newInstance(1997, 11, 1);
		contacts.add(contact2);

		insert contacts;

		externalIDs   = new Map<String, Set<String>>();
		softErrorMap   = new Map<String, Map<String, String>>();

		settings             = new Integration_Settings__c();
		settings.Name           = RECORDTYPE;
		settings.Integration_Process__c = APEX_CLASS;
		settings.Next_Process__c     = APEX_CLASS;
		settings.Next_Process_Delay__c   = '1';
		settings.Log_Level__c       = 'Success';
		insert settings;
	}

	//=====================================================================//
	//==========================  TEST METHODS  ===========================//
	//=====================================================================//


	/**
	 * This test method verifies the functionalities of a full cicle successfully
	 * updating existing records in Salesforce.
	 */
	@isTest
	static void testgetSalesforceFields(){

		Test.startTest();

		List<String> sfFieldNames = Integration_SFDC2EWS_Util.getSalesforceFieldsToExport(RECORDTYPE, APEX_CLASS);
		String query = 'Select ' + String.join(sfFieldNames, ',') + ' from Contact';
		List<sObject> listOfSfRecords = Database.query(query);

		List<Object> recordsToSend = Integration_SFDC2EWS_Util.prepareRecords(listOfSfRecords, RECORDTYPE, SALESFORCE_RECORDTYPE, APEX_CLASS);

		List<String> jsonRecords = new List<String>();
		for(Object rec : recordsToSend) {
			jsonRecords.add(JSON.serialize(rec));
		}
		List<RecordWrapper> parseToWrapper = new List<RecordWrapper>();
		for(String jsonRec : jsonRecords) {
			parseToWrapper.add((RecordWrapper) JSON.deserializeStrict(jsonRec, recordWrapper.class));
		}

		System.debug(JSON.serializePretty(parseToWrapper));

		//Integration_Util.generateLog(SERVICE_NAME, RECORDTYPE, EXTERNAL_ID_FIELD, APEX_METHOD, upsertResults, JSON.serialize(recordWrappers), recordsMap, softErrorMap);

		Test.stopTest();

		System.assertEquals(7, sfFieldNames.size());
		System.assertEquals(2, recordsToSend.size());

	}
	@isTest
	static void testRecordTypes() {
		//=============================  RecordTypeId Mapping  =============================//
		Integration_Mappings__mdt mapping = new Integration_Mappings__mdt(MasterLabel= 'TIPO', Field_Type__c= 'String', Salesforce_Field__c= 'RecordTypeId', Salesforce_Field_Type__c= 'String', Field_Length__c= null, Date_Format__c= '', Date_Separator__c= '', Lookup_SObject__c= '', Lookup_SObject_External_ID__c= '', External_ID__c= false);

		sObject logRecord = Schema.getGlobalDescribe().get('Log__c').newSObject();
		logRecord.put(mapping.Salesforce_Field__c, Schema.SObjectType.Log__c.getRecordTypeInfosByName().get('Outbound').getRecordTypeId());

		Test.startTest();
		Map<String, Object> record = new Map<String, Object>();
		Integration_SFDC2EWS_Util.setRecordTypeInformation('Log__c', 'OBJETO_LOG', logRecord, mapping, record);
		Test.stopTest();

		System.assertEquals(1, record.size());
		System.assert(JSON.serialize(record).containsIgnoreCase('Tipo_Salida'));
	}

	/**
	 * This test method verifies the functionalities of a full cicle successfully
	 * updating existing records in Salesforce.
	 */
	@isTest
	static void testcallWS(){

		Test.startTest();
		Map<String, String> request = new Map<String, String>();
		request.put('Cliente', 'Pepito');
		request.put('Tipo', 'Particular');

		Test.setMock(HttpCalloutMock.class, new mockWSTest());
		HttpResponse response = Integration_SFDC2EWS_Util.callRestWS('NamedCrentialTest', 'testEndpoint', 'POST', request, null, APEX_CLASS, APEX_METHOD);

		Test.stopTest();
		// Log__c logOutbound = [Select Id, recordType.DeveloperName, Endpoint_WS__c, Service_Name__c, Request__c, Server_Response__c, Response_Body__c, Result__c, Callout_Error__c from Log__c];

		System.assert(String.isNotBlank(response.getBody()));
		System.assert(response.getBody().contains('OK'));

		// System.assertNotEquals(null, logOutbound);
		// System.assertEquals('Outbound', logOutbound.recordType.DeveloperName);

	}

	public class mockWSTest implements HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req) {
			System.assert(req.getEndpoint().contains('testEndpoint'));
			System.assertEquals('POST', req.getMethod());
			Map<String, String> response = new Map<String, String>();
			response.put('Status', 'OK');

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody(JSON.serialize(response));
			res.setStatusCode(200);
			return res;
		}
	}
}