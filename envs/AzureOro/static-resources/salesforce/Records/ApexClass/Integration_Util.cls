/**
* Class Integration_Util
**
* Generic utility class to use in Integration processes.
* @author: Aritz Uriarte
**
**/
public without sharing class Integration_Util
{
	public static String INTEGRATION_UTIL     = 'Integration_Util';
	public static String INTEGRATION_UTIL_TEST   = 'Integration_Util_Test';

	public static String BOOLEAN_TRUE_VALUE   = 'true';

	//========================================================================================================================//
	//======================================================  GENERIC  =======================================================//
	//========================================================================================================================//

	/**
	 * This method receives a generic List of elements and deserializes each element into a
	 * Map<String, Object> structure. This method is needed to feed parameters to the "prepareRecords"
	 * method.
	 * @param  listOfRecords List of elements to deserialize.
	 * @return               Returns a List of Map<String, Object> which are the deserialized
	 *                       elements of the List.
	 */
	public static List<Map<String, Object>> deserializeRecords(List<Object> listOfRecords)
	{
		List<Map<String, Object>> deserializedRecords = new List<Map<String, Object>>();

		String JSONLine;
		Map<String, Object> integrationRecord;

		if (listOfRecords != null && !listOfRecords.isEmpty())
		{
			for (Object record : listOfRecords)
			{
				JSONLine            = JSON.serialize(record);
				integrationRecord   = (Map<String, Object>)JSON.deserializeUntyped(JSONLine);
				deserializedRecords.add(integrationRecord);
			}
		}

		return deserializedRecords;
	}

	/**
	 * This method will take a generic list of records parsed as "Map<String, Object>" and return a "List<SObject>" ready to be
	 * upserted in the system. Additionally, it will update the "softErrorMap" with warnings if possible.
	 * @param  listOfRecords         This is the list of records returned by the web service serialized as Map<String, Object>
	 *                               using JSON.serialize and JSON.deserializeUntyped methods.
	 * @param  RECORDTYPE            The name used as referenced by the Integration Settings.
	 * @param  SALESFORCE_RECORDTYPE The name of the SObject to map.
	 * @param  externalIDs           Map of lookup fields and external IDs for such fields to verify before mapping.
	 * @param  softErrorMap          Map of warning errors (lookup fields left blank due to incorrect external IDs). It is only going
	 *                               to be fulfilled if a valid "externalIDs" map is provided.
	 * @return                       Map of "mapped" records ready to be upserted in Salesforce. A specific casting process will
	 *                               be needed in the caller method to allow the upsert itself.
	 */
	public static Map<String, SObject> prepareRecords(List<Map<String, Object>> listOfRecords, String RECORDTYPE, String SALESFORCE_RECORDTYPE, String APEX_CLASS, Map<String, Set<String>> externalIDs, Map<String, Map<String, String>> softErrorMap)
	{
		System.debug('[METHOD_ENTRY] prepareRecords FROM CLASS Integration_Util');

		Map<String, SObject>                    recordsMap              = new Map<String, SObject>();
		List<Integration_Mappings__mdt>         mappings                = new List<Integration_Mappings__mdt>();
		Map<String, Integration_Mappings__mdt>  salesfoceFieldMappings  = new Map<String, Integration_Mappings__mdt>();

		String EXTERNAL_ID = '';

		if (listOfRecords != null && !listOfRecords.isEmpty())
		{
			// We retrieve all the integration mappings corresponding to the object type to integrate.
			for (Integration_Mappings__mdt mapping:getIntegrationMappings(RECORDTYPE, APEX_CLASS))
			{
				if (mapping.External_ID__c)
				{
					EXTERNAL_ID             = mapping.MasterLabel;
				}

				mappings.add(mapping);
				salesfoceFieldMappings.put(mapping.Salesforce_Field__c, mapping);
			}

			// We go trough all the records provided by the webservice and we map the corresponding fields.
			for (Map<String, Object> cRecord : listOfRecords)
			{
				System.debug('cRecord: ' + cRecord);
				System.debug(cRecord.get(EXTERNAL_ID));

				sObject objeto = mapObjectFields(SALESFORCE_RECORDTYPE, RECORDTYPE, cRecord, externalIDs, softErrorMap, mappings, EXTERNAL_ID);

				System.debug('objeto: ' + objeto);

				string externalId = String.valueOf(cRecord.get(EXTERNAL_ID));

				recordsMap.put(externalId, objeto);
			}
		}

		return recordsMap;
	}

	/**
	 * Method to map the fields of a generic record to a SObject record.
	 * @param  SALESFORCE_RECORDTYPE    Salesforce name of the SObject. Ex: Account, Product2, etc.
	 * @param  RECORDTYPE               Name of the Integration Mappings Object being used.
	 * @param  integrationRecord        The record to be mapped into a SObject record.
	 * @param  externalIDs              Map of lookup fields and external IDs for such fields to verify before mapping.
	 * @param  softErrorMap             Map of warning errors (lookup fields left blank due to incorrect external IDs). It is only going
	 *                                  to be fulfilled if a valid "externalIDs" map is provided.
	 * @param  fieldMappings            Integration Mapping list to be used. If not provided the system will fetch them by default.
	 * @param  externalID               The name of the field containing the External ID.
	 * @return                          A fully mapped SObject record.
	 */
	public static SObject mapObjectFields(String SALESFORCE_RECORDTYPE, String RECORDTYPE, Map<String, Object> integrationRecord, Map<String, Set<String>> externalIDs,
											Map<String, Map<String, String>> softErrorMap, List<Integration_Mappings__mdt> fieldMappings, String externalID) {
		System.debug('mapObjectFields');

		String currentField;

		try{
			List<Integration_Mappings__mdt> mappings = new List<Integration_Mappings__mdt>();

			if (fieldMappings != null)
			{
				mappings = fieldMappings;
			}
			else
			{
				mappings = [Select Id, MasterLabel, Field_Type__c, Salesforce_Field__c, Salesforce_Field_Type__c,
									 Lookup_SObject__c, Lookup_SObject_External_ID__c, Field_Length__c, External_ID__c, Date_Format__c,
									 Date_Separator__c
							from Integration_Mappings__mdt
							where Object__r.MasterLabel = :RECORDTYPE
							and Inbound__c = true];
			}

			// We first retrieve the field that contains the ID of the record to use it in
			// soft error log reports.
			String EXTERNAL_ID = '';

			if (String.isNotBlank(externalID))
			{
				EXTERNAL_ID = externalID;
			}
			else
			{
				for (Integration_Mappings__mdt mapping : mappings)
				{
					if (mapping.External_ID__c)
					{
						EXTERNAL_ID = mapping.MasterLabel;
						break;
					}
				}
			}

			sObject record = Schema.getGlobalDescribe().get(SALESFORCE_RECORDTYPE).newSObject();

			Boolean mapField = true;

			for (Integration_Mappings__mdt mapping : mappings)
			{
				mapField = true;

				currentField = mapping.MasterLabel + ' - ' + mapping.Salesforce_Field__c;

				//======================================================================//
				//==============================  LOOKUP  ==============================//
				//======================================================================//

				if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Lookup'))
				{
					if (externalIDs.containsKey(mapping.MasterLabel))
					{
						if (String.isNotBlank(String.valueof(integrationRecord.get(mapping.MasterLabel))) &&
							externalIDs.get(mapping.MasterLabel).contains(String.valueof(integrationRecord.get(mapping.MasterLabel))))
						{
							SObject lookupRecord = Schema.getGlobalDescribe().get(mapping.Lookup_SObject__c).newSObject();
							lookupRecord.put(mapping.Lookup_SObject_External_ID__c, integrationRecord.get(mapping.MasterLabel));
							record.putSObject(mapping.Salesforce_Field__c, lookupRecord);
						}
						else
						{
							// If there is a field validation to be made and there is a soft error, we will add this exception to
							// the corresponding soft error map
							if (softErrorMap.get(mapping.MasterLabel) == null)
							{
								softErrorMap.put(mapping.MasterLabel, new Map<String, String>());
							}

							String softErrorMessage = mapping.Salesforce_Field__c + ': ' + integrationRecord.get(mapping.MasterLabel) + ' not found.';

							softErrorMap.get(mapping.MasterLabel).put(String.valueof(integrationRecord.get(EXTERNAL_ID)), softErrorMessage);
						}

					}
					else if (String.isNotBlank(String.valueof(integrationRecord.get(mapping.MasterLabel))))
					{
						SObject lookupRecord = Schema.getGlobalDescribe().get(mapping.Lookup_SObject__c).newSObject();
						lookupRecord.put(mapping.Lookup_SObject_External_ID__c, integrationRecord.get(mapping.MasterLabel));
						record.putSObject(mapping.Salesforce_Field__c, lookupRecord);
					}

					mapField = false;
				}

				//======================================================================//
				//==============================  EMAIL  ===============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Email'))
				{
					mapField = (integrationRecord.get(mapping.MasterLabel) == null) ? true : validateEmail(String.valueOf(integrationRecord.get(mapping.MasterLabel)));
				}

				//======================================================================//
				//==============================  DATE  ================================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Date'))
				{
					System.debug('Date: ' + mapping.MasterLabel + ' - ' + integrationRecord.get(mapping.MasterLabel));

					if (String.isNotBlank((String)integrationRecord.get(mapping.MasterLabel)))
					{
						Date integrationDate;

						try
						{
							integrationDate = getDate((String)integrationRecord.get(mapping.MasterLabel), mapping.Date_Separator__c, mapping.Date_Format__c);
						}
						catch (Exception ex)
						{
							System.debug(' Error Field ' + currentField + ': ' + ex.getMessage());
						}

						if (integrationDate != null)
						{
							record.put(mapping.Salesforce_Field__c, integrationDate);
						}
					}

					mapField = false;
				}

				//======================================================================//
				//==============================  STRING  ==============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('String') && mapping.Field_Length__c != null)
				{
					Integer length = Integer.valueOf(mapping.Field_Length__c);
					record.put(mapping.Salesforce_Field__c, String.valueOf(integrationRecord.get(mapping.MasterLabel)).trim().abbreviate(length));

					mapField = false;
				}

				//======================================================================//
				//==============================  NUMBER  ==============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Number') /*&& mapping.Field_Length__c != null*/)
				{
					//Integer length = Integer.valueOf(mapping.Field_Length__c);
					//record.put(mapping.Salesforce_Field__c, String.valueOf(integrationRecord.get(mapping.MasterLabel)).abbreviate(length));
					record.put(mapping.Salesforce_Field__c, Decimal.valueOf(String.valueOf(integrationRecord.get(mapping.MasterLabel))));

					mapField = false;
				}

				//======================================================================//
				//==============================  BOOLEAN  =============================//
				//======================================================================//

				else if (mapping.Salesforce_Field_Type__c.containsIgnoreCase('Boolean'))
				{
					//System.debug(mapping.Salesforce_Field__c + ': ' + mapping.Salesforce_Field_Type__c);
					//System.debug(integrationRecord.get(mapping.MasterLabel));

					record.put(mapping.Salesforce_Field__c, (String.valueOf(integrationRecord.get(mapping.MasterLabel))).equalsIgnoreCase(BOOLEAN_TRUE_VALUE));

					mapField = false;
				}

				//======================================================================//
				//==============================  RECORDTYPEID  =============================//
				//======================================================================//

				else if (mapping.Salesforce_Field__c.containsIgnoreCase('RecordTypeId')) {

					setRecordTypeInformation(SALESFORCE_RECORDTYPE, RECORDTYPE, record, mapping, integrationRecord);

					mapField = false;
				}

				//System.debug('Integration_Util: ' + mapping.Salesforce_Field__c + ': ' + mapping.Salesforce_Field_Type__c);

				if (mapField)
				{
					record.put(mapping.Salesforce_Field__c, String.valueOf(integrationRecord.get(mapping.MasterLabel)));
				}
			}

			return record;
		}
		catch (Exception e)
		{
			//System.AssertEquals(null, e.getLineNumber() + ':' + e.getMessage() + ' / ' + e.getCause());
			System.debug('Field ' + currentField + ': ' + e.getMessage());
			return null;
		}
	}

	/**
	 * This method set the information of recordtype when mapping record has as Salesforce_field__c equals RecordTypeId.
	 * @param	SALESFORCE_RECORDTYPE	Contains the Api name of object
	 * @param	RECORDTYPE				Contains the name of metadata Integration_Object__mdt record
	 * @param	record					sObject record to set the recordtypeid
	 * @param	mapping					Contains the information to mapping to external field
	 * @param	integrationRecord		Map with the information of external record
	 */
	public static void setRecordTypeInformation(String SALESFORCE_RECORDTYPE, String RECORDTYPE, sObject record, Integration_Mappings__mdt mapping, Map<String, Object> integrationRecord) {
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
			//Set metadataRtDeveloperObject map with key MasterLabel, value developerName SF
			for(RecordType__mdt metadata : recordTypesList) {
				metadataRtDeveloperObject.put(metadata.MasterLabel, metadata.RecordType_Name__c);
			}

			//Set rtIdsDeveloperNameSObject map with key recordtype developername, value recordtypeId SF
			Map<String, Schema.RecordTypeInfo> recordTypesSf = Schema.getGlobalDescribe().get(SALESFORCE_RECORDTYPE).getDescribe().getRecordTypeInfosByDeveloperName();
			for(Schema.RecordTypeInfo rt : recordTypesSf.values()) {
				rtIdsDeveloperNameSObject.put(rt.getDeveloperName(), rt.getRecordTypeId());
			}
			String recordTypeToMapping = (String) integrationRecord.get(mapping.MasterLabel);
			record.put(mapping.Salesforce_Field__c, rtIdsDeveloperNameSObject.get(metadataRtDeveloperObject.get(recordTypeToMapping)));
			System.debug('recordTypeToMapping: ' + recordTypeToMapping);
			System.debug('metadataRtDeveloperObject.get(recordTypeToMapping): ' + metadataRtDeveloperObject.get(recordTypeToMapping));
			System.debug('rtIdsDeveloperNameSObject.get(metadataRtDeveloperObject.get(recordTypeToMapping)): ' + rtIdsDeveloperNameSObject.get(metadataRtDeveloperObject.get(recordTypeToMapping)));
			System.debug('record: ' + JSON.serializePretty(record));
		}
	}

	/**
	 * This method creates a Date from a String.
	 * @param  dateString The String containing the Date definition.
	 * @param  separator  The character used to separate Date elements in the dateString.
	 * @param  format     The pattern used in dateString to define the Date value.
	 *                    Ex: yyyy-MM-dd, yy-MM-dd, etc.
	 * @return            [description]
	 */
	public static Date getDate(String dateString, String separator, String format)
	{
		System.debug('[METHOD_ENTRY] getDate FROM CLASS Integration_Util');

		String day = '';
		String month = '';
		String year = '';

		String firstYearDigits = String.valueOf(System.today().year()).left(2);

		if (String.isNotBlank(dateString))
		{
			List<String> dateStringSplit = dateString.split(separator);
			List<String> formatSplit     = format.split(separator);

			Integer i = 0;

			for (String dateElement : formatSplit)
			{
				if (dateElement.equalsIgnoreCase('dd'))
				{
					if (Integer.valueOf(dateStringSplit[i]) > 0 && Integer.valueOf(dateStringSplit[i]) < 32)
					{
						day = dateStringSplit[i];
					}
				}
				else if (dateElement.equalsIgnoreCase('MM'))
				{
					if (Integer.valueOf(dateStringSplit[i]) > 0 && Integer.valueOf(dateStringSplit[i]) < 13)
					{
						month = dateStringSplit[i];
					}
				}
				else if (dateElement.equalsIgnoreCase('yyyy'))
				{
					year = dateStringSplit[i];
				}
				else if (dateElement.equalsIgnoreCase('yy'))
				{
					year = firstYearDigits + dateStringSplit[i];
				}

				i++;
			}

			if (String.isNotBlank(day) && String.isNotBlank(month) && String.isNotBlank(year))
			{
				return Date.valueOf(year + '-' + month + '-' + day);
			}
		}

		return null;
	}

	/**
	 * Method to validate whether a String is a valid email address or not.
	 * @param  email The string to validate.
	 * @return       True if the String is a valid email address.
	 */
	public static Boolean validateEmail(String email)
	{
		Boolean res = true;

		// source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
		Pattern MyPattern = Pattern.compile(emailRegex);
		Matcher MyMatcher = MyPattern.matcher(email);

		if (!MyMatcher.matches() || email.containsIgnoreCase('-.') || email.containsIgnoreCase('.-'))
		{
			res = false;
		}

		return res;
	}

	/**
	 * This method takes multiple partially-mapped SObject records and merges them into a single one.
	 * @param  recordsToMerge List of partially mapped SObject records representing a single record in Salesforce.
	 * @param  resultRecord   The original SObject record to use as the main record.
	 * @param  fieldMappings  Map of Integration Mapping records to use in the merging process.
	 * @return                A fully mapped SObject record.
	 */
	public static SObject mergeRecords(List<SObject> recordsToMerge, SObject resultRecord, Map<String, Integration_Mappings__mdt> fieldMappings)
	{
		for (SObject recordToMerge:recordsToMerge)
		{
			if (recordToMerge != null)
			{
				Map<String, Object> fieldMap = recordToMerge.getPopulatedFieldsAsMap();

				for (String field:fieldMap.keySet())
				{
					Integration_Mappings__mdt mapping = fieldMappings.get(field);

					if (mapping != null && mapping.Salesforce_Field_Type__c.equalsIgnoreCase('Lookup'))
					{
						SObject lookupRecord = Schema.getGlobalDescribe().get(mapping.Lookup_SObject__c).newSObject();
						lookupRecord.put(mapping.Lookup_SObject_External_ID__c, ((SObject)fieldMap.get(field)).get(mapping.Lookup_SObject_External_ID__c));
						resultRecord.putSObject(mapping.Salesforce_Field__c, lookupRecord);
					}
					else
					{
						resultRecord.put(field, recordToMerge.get(field));
					}
				}
			}
		}

		return resultRecord;
	}

	/**
	 * This method fetches all the external IDs of a given SObject type
	 * @param  externalIDs  Map of external IDs.
	 * @param  objectName   Name of the SObject to query.
	 * @param  fieldName    Name of the field you want to retrieve.
	 * @param  externalID   Name of external ID.
	 * @return              Map of ID and Set of external IDs.
	 */
	public static void putExternalIDs (Map<String, Set<String>> externalIDs, String objectName, String fieldName, String externalID, List<Map<String, Object>> deserializedRecords )
	{
		System.debug('[METHOD_ENTRY] putExternalIDs FROM CLASS Integration_Util');

				//Preparamos el Set<Id> de los registros con los que lanzar la query.
				Set<String> idsToQuery = new Set<String>();

				for(Map<String, Object> record : deserializedRecords)
				{
						if (String.isNotBlank(String.valueOf(record.get(fieldName))))
						{
								idsToQuery.add(String.valueOf(record.get(fieldName)));
						}
				}

				System.debug('putExternalIDs - idsToQuery: ' + idsToQuery);

		// Incluimos en el Set los IDs Externos de los Productos
		Set<String> setIds = new Set<String>();

		String query = 'Select ' + externalID + ' from ' + objectName + ' where ' + externalID + ' =: idsToQuery'; // !=  null';

		List<SObject> results = Database.query(query);

		Map<String, SObject> resultMap = new Map<String, SObject>();

		for (SObject record : results)
		{
			setIds.add((String)record.get(externalID));
		}

		externalIDs.put(fieldName, setIds);

		System.debug('EXTERNAL ID : ' + externalIDs);

		System.debug('[METHOD_EXIT] putExternalIDs FROM CLASS Integration_Util');
	}

	/**
	 * This method fetches all the existing records within Salesforce of a given SObject type based
	 * on a set of IDs. You must specify the field you want to retrieve.
	 * @param  objectName   Name of the SObject to query.
	 * @param  fieldName    Name of the field you want to retrieve.
	 * @param  recordIDs    Set of record IDs to fetch.
	 * @param  recordTypeID Optional parameter to delimit the query to a given recordtype.
	 * @return              Map of ID and SObject with the results.
	 */
	public static Map<String, SObject> getALLRecords(String objectName, String fieldName, Set<String> recordIDs, String recordTypeID)
	{
		String field = fieldName.equalsIgnoreCase('Id') ? '' : ', ' + fieldName;

		String query = 'Select Id' + field + ' from ' + objectName + ' where ' + fieldName + ' in :recordIDs';

		if (String.isNotBlank(recordTypeID))
		{
			query += ' and RecordTypeId = \'' + recordTypeID + '\'';
		}

		List<SObject> results = Database.query(query);

		Map<String, SObject> resultMap = new Map<String, SObject>();

		for (SObject record : results)
		{
			resultMap.put((String)(record.get(fieldName)), record);
		}

		return resultMap;
	}

	/**
	 * This method deletes all the records that have a specific field within the values defined
	 * in a set of Strings.
	 * @param objectName   Name of the SObject to delete.
	 * @param fieldName    Name of the field to use as a filter.
	 * @param recordIDs    Set of Strings to use in the filter of the query.
	 * @param recordTypeID Optional parameter to limit the query to a given recordtype.
	 */
	public static void deleteAllRecords(String objectName, String fieldName, Set<String> recordIDs, String recordTypeID)
	{
		String query = 'Select Id from ' + objectName + ' where ' + fieldName + ' in :recordIDs';

		if (String.isNotBlank(recordTypeID))
		{
			query += ' and RecordTypeId = \'' + recordTypeID + '\'';
		}

		List<SObject> results = Database.query(query);

		delete results;
	}

	/**
	 * Method to generate a Log__c record in Salesforce.
	 * @param  serviceName       Name of the Apex class being logged.
	 * @param  recordType        Name of the Integration Settings object being processed.
	 * @param  method            Name of the Apex class method being logged.
	 * @param  upsertResults     List of results provided by a Database.upsert sentence.
	 * @param  serverResponse    Response provided by the webservice if applicable.
	 * @param  mapUpsert         Map of the records being upserted.
	 * @param  softErrorMessages Map of soft errors, check prepareRecords for more details.
	 * @return                   Returns
	 *                              OK: everything was upserted successfully in the system and there
	 *                                  were no soft errors in the process.
	 *                              WARNING: everything was upserted successfully in the system and there
	 *                                  were soft errors in the process.
	 *                              ERROR: there was an error while upserting records and some records might
	 *                                  not have been upserted in the system.
	 */
	public static String generateLog(String serviceName, String recordType, String externalIDField, String method, List<Database.UpsertResult> upsertResults,
									 String serverResponse, Map<String, SObject> mapUpsert, Map<String, Map<String, String>> softErrorMessages)
	{

		Integration_Settings__c settings = [Select Id, Log_Level__c from Integration_Settings__c where Name = :recordType limit 1];

		if (String.isBlank(settings.Log_Level__c))
		{
			settings.Log_Level__c = 'Success';
			update settings;
		}

		String finalResult = 'Success';

		Integer totalCount   = 0;
		Integer successCount = 0;
		Integer warningCount = 0;
		Integer errorCount   = 0;

		String result = '/*****************  ' + recordType + '  *****************/\n';

		Integer i = 0;
		String EXTERNAL_ID;
		String RECORDTYPE_ERROR;

		for (SObject record : mapUpsert.values())
		{

			EXTERNAL_ID = (String)(record.get(externalIDField));

			totalCount++;

			if (upsertResults[i].isSuccess())
			{
				Boolean warning = false;

				for (Map<String, String> softError : softErrorMessages.values())
				{
					if (softError.containsKey(EXTERNAL_ID))
					{
						warning = true;
						break;
					}
				}

				if (warning && settings.Log_Level__c != 'Error')
				{
					result += EXTERNAL_ID + ': ';

					for (Map<String, String> softError : softErrorMessages.values())
					{
						if (softError.containsKey(EXTERNAL_ID))
						{
							result += softError.get(EXTERNAL_ID) + '. ';
						}
					}
					result += '\n';

					finalResult = finalResult == 'Success' ? 'Warning' : finalResult;

					warningCount++;
				}
				else if (settings.Log_Level__c == 'Success')
				{
					result += 'success' + '\n';

					successCount++;
				}
			}
			else
			{
				result += EXTERNAL_ID + ': ';
				result += String.valueOf(upsertResults[i].getErrors()) + '\n';
				finalResult = 'Error';

				errorCount++;
			}

			i++;
		}

		Log__c log                = new Log__c();
		log.recordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName() .get('Inbound').getRecordTypeId();
		log.Service_Name__c       = serviceName;
		log.Apex_Class_Name__c    = INTEGRATION_UTIL;
		log.Apex_Method_Name__c   = method;
		log.Timestamp__c          = System.now();
		log.Total_Records__c      = totalCount;
		log.Successful_Records__c = successCount;
		log.Warning_Records__c    = warningCount;
		log.Error_Records__c      = errorCount;
		log.Result_Description__c = result.abbreviate(131072);
		log.Result__c             = finalResult;

		System.Debug('## log result: ' + log.Result_Description__c);

		if (settings.Log_Level__c == 'Success' ||
			settings.Log_Level__c == 'Warning' && finalResult == 'Warning' ||
			finalResult == 'Error')
		{
			insert log;
			List<Attachment> attachments = new List<Attachment>();

			insert new Attachment(  Name = 'Server Response.txt',
									Body = Blob.valueOf(serverResponse),
									ParentId = log.Id);

			Attachment results = new Attachment();
			results.Body = Blob.valueOf(result);
			results.Name = 'Results.txt';
			results.ParentId = log.Id;
			attachments.add(results);

			insert attachments;
		}

		return log.Result__c;
	}

	/**
	 * This method retrieves the Integration Settings record with all its fields.
	 * @param  name Name of the Integration Settings Object.
	 * @return      Fully queried Integration Settings record.
	 */
	public static Integration_Settings__c getSettings(String name)
	{
		System.debug('getSettings: ' + name);

		List<String> fieldList = new List<String>(Integration_Settings__c.sObjectType.getDescribe().fields.getMap().keySet());

		String query = 'Select ' + String.join(fieldList, ',') + ' from Integration_Settings__c where Name = :name limit 1';

		List<Integration_Settings__c> settings = (List<Integration_Settings__c>)Database.query(query);

		if (settings != null && !settings.isEmpty())
		{
			Integration_Settings__c setting = settings[0];
			initializeSettings(setting);
			return setting;
		}
		else
		{
			 return null;
		}
	}

	/**
	 * This method initializes certain fields of an Integration Setting if they are
	 * set to null values.
	 * @param settings The Integration Settings record to initialize.
	 */
	public static void initializeSettings(Integration_Settings__c settings)
	{
		// We initialize the increment null values to 0 and then we check whether all of them are 0, if so, we
		// set the default settings of Month_increment__c = 1
		if (settings.Buffer_days__c == null)
		{
			settings.Buffer_days__c = 0;
		}

		// We now calculate the parameters needed to sent a request to the server based on dates and limits/offsets
		if (settings.Offset__c == null)
		{
			settings.Offset__c = 0;
		}

		if (settings.Limit__c == null)
		{
			settings.Limit__c = 1;
		}

	}

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
	 * This method returns the name of the Apex Class Method being executed right now.
	 * @return Name of the running Apex Class Method.
	 */
	public static String getRunningMethodName()
	{
		String line = new DmlException().getStackTraceString().substringAfter('\n');

		return line.substringBefore(':').substringAfterLast('.');
	}

	/**
	 * This method retrieves the Integration Metadata records with all its fields for an Object.
	 * @param  RECORDTYPE   Name of the Integration Settings Object.
	 * @return          Fully queried Integration Settings record.
	 */
	public static List<Integration_Mappings__mdt> getIntegrationMappings(String RECORDTYPE, String callingClassName)
	{
		List<String> fieldList = new List<String>(Integration_Mappings__mdt.sObjectType.getDescribe().fields.getMap().keySet());

		String query = 'Select ' + String.join(fieldList, ',') + ' from Integration_Mappings__mdt where Object__r.MasterLabel = :RECORDTYPE and Inbound__c = true';

		List<Integration_Mappings__mdt> mappings = new List<Integration_Mappings__mdt>();

		if (callingClassName.equalsIgnoreCase(INTEGRATION_UTIL_TEST))
		{
			mappings.addAll(generateTestMappings());
		}
		else
		{
			mappings.addAll((List<Integration_Mappings__mdt>)Database.query(query));
		}

		return mappings;
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

		//=============================  ASSISTANT NAME  =============================//
		/*mapping                 = new Integration_Mappings__mdt();
		mapping.MasterLabel           = 'NUMERIC';
		mapping.Field_Type__c           = 'String';
		mapping.Salesforce_Field__c       = 'AssistantName';
		mapping.Salesforce_Field_Type__c     = 'Number';
		mapping.Field_Length__c          = null;
		mapping.Date_Format__c           = '';
		mapping.Date_Separator__c         = '';
		mapping.Lookup_SObject__c         = '';
		mapping.Lookup_SObject_External_ID__c   = '';
		mapping.External_ID__c           = false;
		testMappings.add(mapping);*/

		return testMappings;
	}
}