/**
* Class Integration_SFDC2EWS_Util
**
* Generic utility class to use in Integration processes from Salesforce to External systems.
* @author: Pedro Pachas
**
**/
public with sharing class Integration_SFDC2EWS_Util {

	public static String INTEGRATION_UTIL     = 'Integration_SFDC2EWS_Util';
	public static String INTEGRATION_UTIL_TEST   = 'Integration_SFDC2EWS_Util_Test';

	public static String SERVICE_NAME = 'PostClientes';
	public static String APEX_CLASS = getRunningClassName();
	public static String METHOD_NAME = 'execute';

	public static String RECORDTYPE             = 'Cuenta';
	public static String SALESFORCE_RECORDTYPE  = 'Account';

	/**
	 * This method returns the name of the Apex Class being executed right now.
	 * @return Name of the running Apex Class.
	 */
	public static String getRunningClassName()
	{
		String line = new DmlException().getStackTraceString().substringAfter('\n');

		if (line.startsWith('Class.'))
		{
			line = line.substringAfter('Class.');
		}

		return line.substringBefore(':').substringBeforeLast('.');
	}

	/**
	 * This method builds the call to a rest WS to send records to other systems from a List<Object>
	 * @param	namedCredential		Name of Named credential
	 * @param	integration			Name of integration to connect
	 * @param	method				Method to execute POST/GET whatever
	 * @param	request				Object with the structure request for rest WS
	 * @param	mapHeaders			Map with the information of headers parameters to call
	 * @param	APEXCLASS			Name of the class where this method is called
	 * @param	APEX_METHOD			Name of the method where this method is called
	 * @return	res					HttpResponse record
	 */
	public static HttpResponse callRestWS(String namedCredential, String integration,String method, Object request, Map<String, String> mapHeaders, String APEX_CLASS, String APEX_METHOD) {
		System.debug('request ' + integration + ' : ' + JSON.serializePretty(request));
		String bodyResponse;

		HttpRequest req = new HttpRequest();
		HttpResponse res = new HttpResponse();
		req.setEndpoint('callout:' + namedCredential + '/' + integration);
		req.setMethod(method);
		if(mapHeaders != null && !mapHeaders.isEmpty()) {
			for(String key : mapHeaders.keySet()) {
				req.setHeader(key, mapHeaders.get(key));
			}
			if(!mapHeaders.containsKey('Content-Type')) {
				req.setHeader('Content-Type', 'application/json');
			}
		}
		else {req.setHeader('Content-Type', 'application/json');}
		if(request != null) {
			req.setBody(JSON.serializePretty(request, true));
		}


		//Create log record to store information about callout WS
		String endpoint;
		if(Test.isRunningTest()) {
			endpoint = 'NamedCrentialTest';
		}
		else {
			endpoint = [SELECT Endpoint FROM NamedCredential WHERE DeveloperName = :namedCredential].Endpoint;
		}
        //System.debug(endpoint);

		Log__c log = new Log__c();
		log.recordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName() .get('Outbound').getRecordTypeId();
		log.Endpoint_WS__c = endpoint + '/' +integration;
		log.Timestamp__c = System.now();
		log.Apex_Class_Name__c    = APEX_CLASS;
		log.Apex_Method_Name__c   = APEX_METHOD;
		log.Service_Name__c = integration;
        if(request != null) {
            String requestBody = JSON.serializePretty(request);
			log.Request__c = requestBody.length() > 131000 ? requestBody.abbreviate(131072) : requestBody; 
        }

		try {
			Http http = new Http();
			req.setTimeout(120000);
			res = http.send(req);
			bodyResponse = res.getBody();
			//System.debug('response ' + integration + ' : ' + bodyResponse);

			log.Server_Response__c = res.getStatusCode() + ': ' + res.getStatus();
			log.Response_Body__c = bodyResponse.length() > 131000 ? bodyResponse.abbreviate(131072) : JSON.serializePretty(bodyResponse);
			log.Result__c = 'Success';
		}
		catch (CalloutException e) {
			log.Result__c = 'Error';
			log.Callout_Error__c = e.getMessage();
			bodyResponse = log.Result__c + ': ' + log.Callout_Error__c;
		}
		/*finally {
			insert log;

			List<Attachment> attachments = new List<Attachment>();
			attachments.add(new Attachment( Name = 'Request body.txt', Body = Blob.valueOf(JSON.serializePretty(request)), ParentId = log.Id));
			attachments.add(new Attachment( Name = 'Response Server body.txt', Body = Blob.valueOf(JSON.serializePretty(bodyResponse)), ParentId = log.Id));
			insert attachments;
		}*/

		return res;
	}

	/**
	 * This method return a list of string that contains the salesforce fields to use in a query to get sObjects records
	 */
	public static List<String> getSalesforceFieldsToExport(String RECORDTYPE, String callingClassName) {
		//List to return
		List<String> sfFields = new List<String>();

		List<Integration_Mappings__mdt> mappings = new List<Integration_Mappings__mdt>();
		if (callingClassName.equalsIgnoreCase(INTEGRATION_UTIL_TEST)) {
			mappings.addAll(generateTestMappings());
		}
		else {
			String query = 'Select Salesforce_Field__c, Lookup_SObject_External_ID__c, Salesforce_Field_Type__c from Integration_Mappings__mdt where Object__r.MasterLabel = :RECORDTYPE and Outbound__c = true';
			mappings.addAll((List<Integration_Mappings__mdt>)Database.query(query));
		}

		if(!mappings.isEmpty()) {
			for(Integration_Mappings__mdt recordMap : mappings) {
				if(recordMap.Salesforce_Field_Type__c.containsIgnoreCase('Lookup')) {
					sfFields.add(recordMap.Salesforce_Field__c + '.' + recordMap.Lookup_SObject_External_ID__c);
				}
				else {
					sfFields.add(recordMap.Salesforce_Field__c);
				}
			}
		}
		return sfFields;
	}

	/**
	 * This method will take a generic list of records parsed as "Map<String, Object>" and return a "List<SObject>" ready to be
	 * upserted in the system. Additionally, it will update the "softErrorMap" with warnings if possible.
	 * @param  listOfSfRecords         This is the list of records returned by the web service serialized as Map<String, Object>
	 *                               using JSON.serialize and JSON.deserializeUntyped methods.
	 * @param  RECORDTYPE            The name used as referenced by the Integration Settings.
	 * @param  SALESFORCE_RECORDTYPE The name of the SObject to map.
	 * @return                       Map of "mapped" records ready to be upserted in Salesforce. A specific casting process will
	 *                               be needed in the caller method to allow the upsert itself.
	 */
	public static List<Object> prepareRecords(List<sObject> listOfSfRecords, String RECORDTYPE, String SALESFORCE_RECORDTYPE, String APEX_CLASS) {
		System.debug('[METHOD_ENTRY] prepareRecords FROM CLASS Integration_SFDC2EWS_Util');

		List<Object>                   			recordsMap              = new List<Object>();
		List<Integration_Mappings__mdt>         mappings                = new List<Integration_Mappings__mdt>();

		String EXTERNAL_ID = '';

		if (listOfSfRecords != null && !listOfSfRecords.isEmpty())
		{
			// We retrieve all the integration mappings corresponding to the object type to integrate.
			mappings = getIntegrationMappingsOutbound(RECORDTYPE, APEX_CLASS);

			// We go trough all the salesforce records and we map the corresponding records to send.
			for (sObject sfRecord : listOfSfRecords)
			{
				System.debug('sfRecord: ' + sfRecord);

				Map<String, Object> objeto = mapsObjectFields(SALESFORCE_RECORDTYPE, RECORDTYPE, sfRecord, mappings);

				System.debug('objeto: ' + objeto);

				recordsMap.add((Object) objeto);
			}
		}
		System.debug('recordsMap result: ' + JSON.serializePretty(recordsMap));
		System.debug('[METHOD_EXIT] prepareRecords FROM CLASS Integration_SFDC2EWS_Util');

		return recordsMap;
	}

	/**
	 * This method retrieves the Integration Metadata records with all its fields for an Object with Outbound__c.
	 * @param  RECORDTYPE   Name of the Integration Settings Object.
	 * @return          Fully queried Integration Settings record.
	 */
	public static List<Integration_Mappings__mdt> getIntegrationMappingsOutbound(String RECORDTYPE, String callingClassName)
	{
		System.debug('[METHOD_ENTRY] getIntegrationMappingsOutbound FROM CLASS Integration_SFDC2EWS_Util');
		List<String> fieldList = new List<String>(Integration_Mappings__mdt.sObjectType.getDescribe().fields.getMap().keySet());

		String query = 'Select ' + String.join(fieldList, ',') + ' from Integration_Mappings__mdt where Object__r.MasterLabel = :RECORDTYPE and Outbound__c = true';

		List<Integration_Mappings__mdt> mappings = new List<Integration_Mappings__mdt>();

		if (callingClassName.equalsIgnoreCase(INTEGRATION_UTIL_TEST))
		{
			mappings.addAll(generateTestMappings());
		}
		else
		{
			mappings.addAll((List<Integration_Mappings__mdt>)Database.query(query));
		}
		
		System.debug('mappings result: ' + JSON.serializePretty(mappings));
		System.debug('[METHOD_EXIT] getIntegrationMappingsOutbound FROM CLASS Integration_SFDC2EWS_Util');
		return mappings;
	}

	/**
	 * Method to map the fields of a sObject record to a external object record.
	 * @param  SALESFORCE_RECORDTYPE    Salesforce name of the SObject. Ex: Account, Product2, etc.
	 * @param  RECORDTYPE               Name of the Integration Mappings Object being used.
	 * @param  sfRecord			        The sObject record to be mapped into a external record.
	 * @param  fieldMappings            Integration Mapping list to be used. If not provided the system will fetch them by default.
	 * @return                          A fully mapped SObject record.
	 */
	public static Map<String, Object> mapsObjectFields(String SALESFORCE_RECORDTYPE, String RECORDTYPE, sObject sfRecord, List<Integration_Mappings__mdt> fieldMappings) {
		System.debug('mapsObjectFields');
		//Variable to store the information from sObject record
		Map<String, Object> record = new Map<String, Object>();

		String currentField;

		try {
			List<Integration_Mappings__mdt> mappings = new List<Integration_Mappings__mdt>();

			if (fieldMappings != null) {
				mappings = fieldMappings;
			}
			else {
				mappings = [Select Id, MasterLabel, Field_Type__c, Salesforce_Field__c, Salesforce_Field_Type__c,
									 Lookup_SObject__c, Lookup_SObject_External_ID__c, Field_Length__c, External_ID__c, Date_Format__c,
									 Date_Separator__c
							from Integration_Mappings__mdt
							where Object__r.MasterLabel = :RECORDTYPE
							and Outbound__c = true];
			}

			Boolean mapField = true;

			for (Integration_Mappings__mdt mapping : mappings) {
				mapField = true;

				currentField = mapping.MasterLabel + ' - ' + mapping.Salesforce_Field__c;

				//======================================================================//
				//==============================  LOOKUP  ==============================//
				//======================================================================//

				if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Lookup')) {
					String externalId = '';
					//Get the sObject record of lookup
					sObject lookupRecord = sfRecord.getSobject(mapping.Salesforce_Field__c);
					if(lookupRecord != null) {
						//Get the value of external Id of lookup
						externalId = (String) lookupRecord.get(mapping.Lookup_SObject_External_ID__c);
					}

					record.put(mapping.MasterLabel, externalId);

					mapField = false;
				}

				//======================================================================//
				//==============================  EMAIL  ===============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Email')) {
					record.put(mapping.MasterLabel, (sfRecord.get(mapping.Salesforce_Field__c) == null ? '' : sfRecord.get(mapping.Salesforce_Field__c)));

					mapField = false;
				}

				//======================================================================//
				//==============================  DATE / DATETIME  ================================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Date') || mapping.Salesforce_Field_Type__c.containsIgnoreCase('Datetime')) {
					System.debug('Date: ' + mapping.MasterLabel + ' - ' + sfRecord.get(mapping.Salesforce_Field__c));
					Datetime dateFormat;
					//Get and check if the field has a value
					if(sfRecord.get(mapping.Salesforce_Field__c) != null) {
						//Parse the valur to Datetime record
						dateFormat = (Datetime) sfRecord.get(mapping.Salesforce_Field__c);
					}
					//Check if the value is not null to format with specific string format
					if(dateFormat != null) {
						record.put(mapping.MasterLabel, dateFormat.format(mapping.Date_Format__c));
					}
					else {
						record.put(mapping.MasterLabel, '');
					}

					mapField = false;
				}

				//======================================================================//
				//==============================  STRING  ==============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('String') && mapping.Field_Length__c != null)
				{
					Integer length = Integer.valueOf(mapping.Field_Length__c);
					record.put(mapping.MasterLabel, sfRecord.get(mapping.Salesforce_Field__c) != null && String.isNotBlank((String)sfRecord.get(mapping.Salesforce_Field__c)) ? String.valueOf(sfRecord.get(mapping.Salesforce_Field__c)).trim().abbreviate(length) : '');

					mapField = false;
				}

				//======================================================================//
				//==============================  NUMBER  ==============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Number')) {

					record.put(mapping.MasterLabel, sfRecord.get(mapping.Salesforce_Field__c) == null ? '' : sfRecord.get(mapping.Salesforce_Field__c));

					mapField = false;
				}

				//======================================================================//
				//==============================  BOOLEAN  =============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Boolean')) {

					record.put(mapping.MasterLabel, sfRecord.get(mapping.Salesforce_Field__c));

					mapField = false;
				}

				//======================================================================//
				//==============================  RECORDTYPEID  =============================//
				//======================================================================//

				else if (mapping.Salesforce_Field__c.containsIgnoreCase('RecordTypeId')) {
					setRecordTypeInformation(SALESFORCE_RECORDTYPE, RECORDTYPE, sfRecord, mapping, record);

					mapField = false;
				}


				if (mapField)
				{
					record.put(mapping.MasterLabel, sfRecord.get(mapping.Salesforce_Field__c)!= null ? String.valueOf(sfRecord.get(mapping.Salesforce_Field__c)) : '');
				}
			}

			return record;
		}
		catch (Exception e) {
			//System.AssertEquals(null, e.getLineNumber() + ':' + e.getMessage() + ' / ' + e.getCause());
			System.debug('Field ' + currentField + ': ' + e.getMessage() + ' Linea: ' + e.getLineNumber());
			return null;
		}
	}

	/**
	 * This method set the information of recordtype when mapping record has as Salesforce_field__c equals RecordTypeId.
	 * @param	SALESFORCE_RECORDTYPE	Contains the Api name of object
	 * @param	RECORDTYPE				Contains the name of metadata Integration_Object__mdt record
	 * @param	sfRecord				sObject record to get the recordtypeid
	 * @param	mapping					Contains the information to mapping to external field
	 * @param	record					Map with the information of external record
	 */
	public static void setRecordTypeInformation(String SALESFORCE_RECORDTYPE, String RECORDTYPE, sObject sfRecord, Integration_Mappings__mdt mapping, Map<String, Object> record) {
		//Get the recordtypes record with the information of the mapping
		List<RecordType__mdt> recordTypesList = new List<RecordType__mdt>();
		if(!Test.isRunningTest()) {
			recordTypesList = [Select RecordType_Name__c, MasterLabel from RecordType__mdt where Object__r.MasterLabel = :RECORDTYPE];
		}
		else {
			recordTypesList.add(new RecordType__mdt(RecordType_Name__c = 'Outbound', MasterLabel = 'Tipo_Salida'));
			recordTypesList.add(new RecordType__mdt(RecordType_Name__c = 'Inbound', MasterLabel = 'Tipo_Entrada'));
		}

		//Get information of recordtypes Salesforce sObject
		Map<String, String> rtIdsDeveloperNameSObject = new Map<String, String>();

		//Get information metadata Recordtype
		Map<String, String> metadataRtDeveloperObject = new Map<String, String>();

		if(!recordTypesList.isEmpty()) {
			//Set metadataRtDeveloperObject map with key developerName SF, value MasterLabel
			for(RecordType__mdt metadata : recordTypesList) {
				metadataRtDeveloperObject.put(metadata.RecordType_Name__c, metadata.MasterLabel);
			}

			//Set rtIdsDeveloperNameSObject map with key recordtypeId SF, value recordtype developername
			Map<String, Schema.RecordTypeInfo> recordTypesSf = Schema.getGlobalDescribe().get(SALESFORCE_RECORDTYPE).getDescribe().getRecordTypeInfosByDeveloperName();
			for(Schema.RecordTypeInfo rt : recordTypesSf.values()) {
				rtIdsDeveloperNameSObject.put(rt.getRecordTypeId(), rt.getDeveloperName());
			}
			String recordTypeIdentifier = (String) sfRecord.get(mapping.Salesforce_Field__c);
			record.put(mapping.MasterLabel, metadataRtDeveloperObject.get(rtIdsDeveloperNameSObject.get(recordTypeIdentifier)));
		}
	}

	/**
	 * This method creates some dummy Integration Mapping entries to be used in the
	 * generic test class.
	 * @return [description]
	 */
	public static List<Integration_Mappings__mdt> generateTestMappings()
	{
		List<Integration_Mappings__mdt> testMappings = new List<Integration_Mappings__mdt>();

		//=============================  ID  =============================//
		Integration_Mappings__mdt mapping     = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'ID';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'Id';
		mapping.Salesforce_Field_Type__c     = 'String';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = '';
		mapping.Lookup_SObject_External_ID__c   = '';
		mapping.External_ID__c           = true;
		testMappings.add(mapping);

		//=============================  NAME  =============================//
		mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'NAME';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'LastName';
		mapping.Salesforce_Field_Type__c     = 'String';
		mapping.Field_Length__c          = 80;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = '';
		mapping.Lookup_SObject_External_ID__c   = '';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);

		//=============================  BIRTHDATE  =============================//
		mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'BIRTHDATE';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'Birthdate';
		mapping.Salesforce_Field_Type__c     = 'Date';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = 'yyyy-MM-dd';
		mapping.Date_Separator__c         = '-';
		mapping.Lookup_SObject__c         = '';
		mapping.Lookup_SObject_External_ID__c   = '';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);

		//=============================  ACCOUNT TO  =============================//
		mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'ACCOUNTTO';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'Account';
		mapping.Salesforce_Field_Type__c     = 'Lookup';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = 'Account';
		mapping.Lookup_SObject_External_ID__c   = 'Id';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);

		//=============================  REPORT TO  =============================//
		mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'REPORTSTO';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'ReportsTo';
		mapping.Salesforce_Field_Type__c     = 'Lookup';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = 'Contact';
		mapping.Lookup_SObject_External_ID__c   = 'Id';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);

		//=============================  NO CALL  =============================//
		mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'NOCALL';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'DoNotCall';
		mapping.Salesforce_Field_Type__c     = 'Boolean';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = '';
		mapping.Lookup_SObject_External_ID__c   = '';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);

		//=============================  EMAIL  =============================//
		mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'EMAIL';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'Email';
		mapping.Salesforce_Field_Type__c     = 'Email';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = '';
		mapping.Lookup_SObject_External_ID__c   = '';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);

		return testMappings;
	}
}