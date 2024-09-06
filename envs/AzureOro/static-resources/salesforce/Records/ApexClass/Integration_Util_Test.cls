/** 
* Class Integration_Util_Test
**
* Generic test class for the Integration_Util class.
* @author: Aritz Uriarte
**
**/
@isTest
public class Integration_Util_Test
{
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
		public String NOCALL   {get; set;}
		public String EMAIL   {get; set;}
		public String NUMERIC   {get; set;}
	}

	public static void generateData()
	{
		account = new Account();
		account.Name = 'Account';
		insert account;

		List<Contact> contacts = new List<Contact>();
		
		contact1 = new Contact();
		contact1.LastName = 'lastname1';
		contact1.AccountId = account.Id;
		contacts.add(contact1);

		contact2 = new Contact();
		contact2.LastName = 'lastname2';
		contact2.AccountId = account.Id;
		contacts.add(contact2);

		insert contacts;

		recordWrappers = new List<RecordWrapper>();

		RecordWrapper recordWrapper = new RecordWrapper();
		recordWrapper.ID     = contact1.Id;
		recordWrapper.NAME     = 'Last Name 1';
		recordWrapper.BIRTHDATE = '1987-09-12';
		recordWrapper.REPORTSTO = contact2.Id;
		recordWrapper.NOCALL   = Integration_Util.BOOLEAN_TRUE_VALUE;
		recordWrapper.EMAIL   = 'test@test.com';
		recordWrapper.NUMERIC   = '123';
		recordWrappers.add(recordWrapper);

		recordWrapper       = new RecordWrapper();
		recordWrapper.ID    = contact2.Id;
		recordWrapper.NAME     = 'Last Name 2';
		recordWrapper.BIRTHDATE = '1987-09-12';
		//recordWrapper.REPORTSTO   = '';
		recordWrapper.NOCALL   = Integration_Util.BOOLEAN_TRUE_VALUE;
		recordWrapper.EMAIL   = 'test@test.com';
		recordWrapper.NUMERIC   = '123';
		recordWrappers.add(recordWrapper);

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
	static void testUpsertAllSuccess()
	{
		generateData();

		Test.startTest();

		List<Map<String, Object>> deserializedRecords = Integration_Util.deserializeRecords(recordWrappers);

		Map<String, SObject> recordsMap = Integration_Util.prepareRecords(deserializedRecords, RECORDTYPE, SALESFORCE_RECORDTYPE, APEX_CLASS, externalIDs, softErrorMap);

		List<Contact> contactList = new List<Contact>((List<Contact>)recordsMap.values());

		List<Database.UpsertResult> upsertResults = Database.upsert(contactList);

		Integration_Util.generateLog(SERVICE_NAME, RECORDTYPE, EXTERNAL_ID_FIELD, APEX_METHOD, upsertResults, JSON.serialize(recordWrappers), recordsMap, softErrorMap);

		Test.stopTest();

		Map<Id, Contact> contactMap = new Map<Id, Contact>([Select Id, FirstName, LastName, BirthDate, Email, DoNotCall
								from Contact]);

		System.assertEquals('Last Name 1', contactMap.get(contact1.Id).LastName);
		System.assertEquals(Integration_Util.getDate('1987-09-12', '-', 'yyyy-MM-dd'), contactMap.get(contact1.Id).BirthDate);
		System.assertEquals(true, contactMap.get(contact1.Id).DoNotCall);
		System.assertEquals('test@test.com', contactMap.get(contact1.Id).Email);

		System.assertEquals('Last Name 2', contactMap.get(contact2.Id).LastName);
		System.assertEquals(Integration_Util.getDate('1987-09-12', '-', 'yyyy-MM-dd'), contactMap.get(contact2.Id).BirthDate);
		System.assertEquals(true, contactMap.get(contact2.Id).DoNotCall);
		System.assertEquals('test@test.com', contactMap.get(contact2.Id).Email);

		List<Log__c> logs = [Select Id, Result__c from Log__c];

		System.assertNotEquals(null, logs);
		System.assertEquals(1, logs.size());
		System.assertEquals('Success', logs[0].Result__c);
	}

	/**
	 * This test method checks the behaviour of the integration methods with warnings.
	 * There are invalid "External ID" values for Lookup fields and the mapObjectFields
	 * method clears the erroneous field before upserting.
	 */
	@isTest
	static void testUpsertAllWarning()
	{
		generateData();

		recordWrappers[1].REPORTSTO = '123456';

		Set<String> recordIDs = new Set<String>();
		recordIDs.add(contact1.Id);
		recordIDs.add(contact2.Id);

		externalIDs.put('REPORTSTO', recordIDs);

		Test.startTest();

		List<Map<String, Object>> deserializedRecords = Integration_Util.deserializeRecords(recordWrappers);

		Map<String, SObject> recordsMap = Integration_Util.prepareRecords(deserializedRecords, RECORDTYPE, SALESFORCE_RECORDTYPE, APEX_CLASS, externalIDs, softErrorMap);

		List<Contact> contactList = new List<Contact>((List<Contact>)recordsMap.values());

		List<Database.UpsertResult> upsertResults = Database.upsert(contactList);

		Integration_Util.generateLog(SERVICE_NAME, RECORDTYPE, EXTERNAL_ID_FIELD, APEX_METHOD, upsertResults, JSON.serialize(recordWrappers), recordsMap, softErrorMap);

		Test.stopTest();

		System.assert(!softErrorMap.isEmpty());

		Map<Id, Contact> contactMap = new Map<Id, Contact>([Select Id, FirstName, LastName, BirthDate, Email, DoNotCall
								from Contact]);

		System.assertEquals('Last Name 1', contactMap.get(contact1.Id).LastName);
		System.assertEquals(Integration_Util.getDate('1987-09-12', '-', 'yyyy-MM-dd'), contactMap.get(contact1.Id).BirthDate);
		System.assertEquals(true, contactMap.get(contact1.Id).DoNotCall);
		System.assertEquals('test@test.com', contactMap.get(contact1.Id).Email);

		System.assertEquals('Last Name 2', contactMap.get(contact2.Id).LastName);
		System.assertEquals(Integration_Util.getDate('1987-09-12', '-', 'yyyy-MM-dd'), contactMap.get(contact2.Id).BirthDate);
		System.assertEquals(true, contactMap.get(contact2.Id).DoNotCall);
		System.assertEquals('test@test.com', contactMap.get(contact2.Id).Email);

		List<Log__c> logs = [Select Id, Result__c from Log__c];

		System.assertNotEquals(null, logs);
		System.assertEquals(1, logs.size());
		System.assertEquals('Warning', logs[0].Result__c);
	}

	@isTest
	static void testRecordTypesInbound() {
		//=============================  RecordTypeId Mapping  =============================//
		Integration_Mappings__mdt mapping = new Integration_Mappings__mdt(MasterLabel= 'TIPO', Field_Type__c= 'String', Salesforce_Field__c= 'RecordTypeId', Salesforce_Field_Type__c= 'String', Field_Length__c= null, Date_Format__c= '', Date_Separator__c= '', Lookup_SObject__c= '', Lookup_SObject_External_ID__c= '', External_ID__c= false);

		sObject logRecord = Schema.getGlobalDescribe().get('Log__c').newSObject();

		Test.startTest();
		Map<String, Object> record = new Map<String, Object>();
		record.put('TIPO', 'Tipo_Entrada');
		Integration_Util.setRecordTypeInformation('Log__c', 'OBJETO_LOG', logRecord, mapping, record);
		Test.stopTest();

		System.assertEquals(1, record.size());
		System.assert(JSON.serialize(logRecord).containsIgnoreCase('RecordTypeId'));
		System.assertNotEquals(null, logRecord.get('RecordTypeId'));
	}

	/**
	 * Test method to check the "getSettings" method.
	 */
	@isTest
	static void testGetSettings()
	{
		generateData();

		Test.startTest();

		settings = Integration_Util.getSettings(RECORDTYPE);

		Test.stopTest();

		System.assertNotEquals(null, settings);
		System.assertEquals(0, settings.Buffer_days__c);
		System.assertEquals(0, settings.Offset__c);
		System.assertEquals(1, settings.Limit__c);
	}

	/**
	 * Test method to check the behaviour of the "deleteAllRecords" method.
	 */
	@isTest
	static void testDeleteAllRecords()
	{
		generateData();

		Set<String> recordIDs = new Set<String>();
		recordIDs.add(contact1.Id);
		recordIDs.add(contact2.Id);

		Test.startTest();

		Integration_Util.deleteAllRecords(SALESFORCE_RECORDTYPE, 'Id', recordIDs, '');

		Test.stopTest();

		List<Contact> contacts = new List<Contact>([Select Id from Contact]);

		// 2020-04-01 ronald.nunez: Comentado, en este entorno por cada cuenta se crea un contacto, por lo que este assert no nos vale.
		//System.assertEquals(0, contacts.size());
	}

	/**
	 * Test method to verify the behaviour of the "getAllRecords" method.
	 */
	@isTest
	static void testGetAllRecords()
	{
		generateData();

		Set<String> lastNames = new Set<String>();
		lastNames.add('lastname1');
		lastNames.add('lastname2');

		Test.startTest();
		
		Map<String, SObject> recordMap = Integration_Util.getALLRecords(SALESFORCE_RECORDTYPE, 'LastName', lastNames, '');

		Test.stopTest();

		System.assertEquals(2, recordMap.size());
		System.assertEquals(contact1.Id, ((Contact)(recordMap.get(contact1.LastName))).Id);
		System.assertEquals(contact2.Id, ((Contact)(recordMap.get(contact2.LastName))).Id);
	}

	/**
	 * Test method to check the behaviour of the "mergeRecords" method.
	 */
	@isTest
	static void testMergeRecords()
	{
		generateData();

		List<Integration_Mappings__mdt> mappings = Integration_Util.getIntegrationMappings(RECORDTYPE, APEX_CLASS);
		Map<String, Integration_Mappings__mdt> fieldMappings = new Map<String, Integration_Mappings__mdt>();

		for (Integration_Mappings__mdt mapping : mappings)
		{
		fieldMappings.put(mapping.Salesforce_field__c, mapping);
		}

		List<Contact> recordsToMerge = new List<Contact>();
		recordsToMerge.add(new Contact(LastName = 'Last Name 1', Email = 'test@test.com'));
		recordsToMerge.add(new Contact(FirstName = 'First Name 1', Phone = '555555555', ReportsToId = contact1.Id, ReportsTo = new Contact(Id = contact1.Id)));

		Contact resultRecord = new Contact();

		Test.startTest();
		
		SObject mergedRecord = Integration_Util.mergeRecords(recordsToMerge, resultRecord, fieldMappings);

		Test.stopTest();

		System.assertEquals(6, mergedRecord.getPopulatedFieldsAsMap().keySet().size());
		System.assertEquals('First Name 1', mergedRecord.get('FirstName'));
		System.assertEquals('Last Name 1', mergedRecord.get('LastName'));
		System.assertEquals('test@test.com', mergedRecord.get('Email'));
		System.assertEquals('555555555', mergedRecord.get('Phone'));
		System.assertEquals(contact1.Id, mergedRecord.get('ReportsToId'));
	}
}