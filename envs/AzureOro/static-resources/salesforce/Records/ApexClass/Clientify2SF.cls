/**
 * @description       : 
 * @author            : jose.murillo
 * @group             : 
 * @last modified on  : 26-04-2023
 * @last modified by  : jose.murillo
**/

global with sharing class Clientify2SF {

      
 	public static ContactScopeResult clientifyCallContacts(String integration){
        
        	ContactScopeResult returnResult = new ContactScopeResult();
        	returnResult.recordProcessedOK = 0;
        	returnResult.recordProcessedKO = 0;
        
        	//Hacemos la llamada Rest a Clientify con el integration primitivo
        	//integration = '/v1/contacts/?page=234';
        	String bodyResponse = callRestWS(integration);
        	String urlBase;
        	String strLeads;
        	String strNext;
        	String strNextEnd;
        	Integer cuantosLeads = 0;
        	Decimal recordCount;
     		Decimal recordProcessed;
        	DateTime LastSyncDate;
       		List<Object> listaLeads = new List<Object>();
        	List<String> listaEmails = new List<String>();
        	List<String> listaPhones = new List<String>();
        	Clienti_Settings__c clientiSetting;
        	
        	if(Test.isRunningTest()){
        		clientiSetting = Clienti_Settings__c.getValues('Test');
            }else{
        		clientiSetting = Clienti_Settings__c.getValues('Clientify');
            }
        
        	//Si el body que nos devuelve la llamada no es blank, guardamos:
            //Cuantos contactos hay en Clientify (count)
        	//El siguiente endpoint al que hacer la llamda en strNext (next)
            //Y la lista de contactos que tenemos en esta página (results)
        
        	if (String.isNotBlank(bodyResponse)){
                Map<String, Object> mapaLeads = (Map<String, Object>)JSON.deserializeUntyped(bodyResponse);
                
                //De la respuesta, guardamos Count, Next y Results, además de la URLBase de la llamada
                
                recordCount = Decimal.valueOf(String.valueOf(mapaLeads.get('count')));
                strNext = String.valueOf(mapaLeads.get('next'));
                listaLeads = (List<Object>)mapaLeads.get('results');
                clientiSetting.URL_Base__c = urlBase;
                      
                //Si la próxima llamada no es nula, guardamos el final de la URL. Si es nula, lo guardamos como 'null' 
                
                if (String.isBlank(strNext)){
                    strNextEnd = 'null';     
                }else{ 
                	urlBase = strNext.substringBefore('/v');
                  	strNextEnd = strNext.substringAfter(urlBase); // Quitar URL base almacenada en el Custom Setting
                }
                
                //Guardamos el Count y el Next en el Custom Setting
                
                clientiSetting.Record_count__c = recordCount;
         		clientiSetting.Next_callout_URL__c = strNextEnd;
                
                // Solo primera iteración guardamos el Last Sync Date
                
                if (integration=='/v1/contacts/'){
                    LastSyncDate = System.now();
                    clientiSetting.Last_Sync_Date__c = LastSyncDate;
                }
                
                
                //Comprobamos que los registros procesados no sean mayor que los totales, lo que querría decir que es primera llamada
                recordProcessed = clientiSetting.Processed_records__c;
                if (recordProcessed>recordCount){
                    clientiSetting.Processed_records__c = 0;		//Si fuera mayor, reset del Processed Records a 0
                }
            } 
        	
        	//Creamos la lista de leads que se va a insertar
       		List<Lead> listaLeadsInsertar = new List<Lead>();
        	
        	//Lista de leads existentes, de la que extraemos una lista de emails existentes para evitar duplicados
        	List <Lead> listaLeadsExistentes = [SELECT Id, LastName, Email, Id_Contacto_Clientify__c FROM Lead];
        	List<String> leadIdClientify = new List<String>();
        	for(Lead everyExistingLead : listaLeadsExistentes){
                leadIdClientify.add(everyExistingLead.Id_Contacto_Clientify__c);
			}
        
            for (Object objLead : listaLeads) {
                Lead leadInsertar = new Lead(); 	//Creamos el Lead que vamos a rellenar por cada iteración
                cuantosLeads++;						//Contador de Leads recibidos en esta llamada
                //Serializamos de nuevo el objeto lead para poder realizar la búsqueda en el string
                //Guardamos cada campo del Lead que obtenemos de la llamada
                
                strLeads = JSON.serialize(objLead);
                String companyLead = strLeads.substringBetween('company_name":"','"');
                    if (String.isNotBlank(companyLead)){
                		leadInsertar.company = companyLead; 
                    }else{
                        leadInsertar.company = 'Compañía sin definir';
                    }
                String emailLead = strLeads.substringBetween('email":"','"');
                leadInsertar.email = emailLead;
                
                //Comprobamos si hay varios emails en el contacto de Clientify. Si los hay, los guardamos en una lista de Strings.
                
                String variosemails = strLeads.substringBetween('email":"', ']');
                if (String.isNotBlank(variosemails)){
                    do {
   							String variosemailsBis = variosemails.substringAfterLast('email":"');
                        	variosemailsBis = variosemailsBis.substringBefore('"');
                                if (String.isNotBlank(variosemailsBis)){
                                    listaEmails.add(variosEmailsBis);
                                }
                        	variosemails = variosemails.substringBeforeLast('email":"');
					} while (variosemails.contains('email":'));
                }
                
                if (listaEmails.size()>0){
                    leadInsertar.Correos_electronicos_adicionales__c = String.valueOf(listaEmails).substringBetween('(',')');
                    listaEmails.clear();
                }
                
                String idClienti = strLeads.substringAfterLast('id":');
                String idClientify = idClienti.substringBefore(',');
                leadInsertar.ID_Contacto_Clientify__c = idClientify;
                String idCompany = strLeads.substringBetween('companies/','/');
                leadInsertar.ID_Cuenta_Clientify__c = idCompany;
                String firstNameLead = strLeads.substringBetween('first_name":"','"');
                String lastNameLead = strLeads.substringBetween('last_name":"','"');
                
                //Si el contacto viene sin apellido, tratamos de rellenarlo con el nombre. En caso contrario, 'Nombre sin definir'.
                    if(lastNameLead.length()<80 && firstNameLead.length()<40){
                        if (String.isNotBlank(lastNameLead)){
                        
                            leadInsertar.lastname = lastNameLead;
                            leadInsertar.firstname = firstNameLead;
                        }else{
                                if (String.isNotBlank(firstNameLead)){
                                    leadInsertar.lastname = firstNameLead;
                                }else{
                                    leadInsertar.lastname = 'Nombre sin definir';
                                }
                            }
                    }else{
                            leadInsertar.lastname = 'Nombre sin definir';
                        	leadInsertar.description = 'Texto añadido en nombre: '+firstNameLead + lastNameLead;
                    }
                
                //Si el rating es uno tipo Cold/Warm/Hot-Lead, lo filtramos para que sea valor standard
                String ratingLead = strLeads.substringBetween('status":"','"');
                if (ratingLead.contains('lead')){
                    leadInsertar.rating = ratingLead.substringBefore('-');
                }else{
                    leadInsertar.rating = ratingLead;
                }
                
                String titleLead = strLeads.substringBetween('title":"','"');
                leadInsertar.title = titleLead;
				leadInsertar.LeadSource = 'Clientify';         // Source Clientify Siempre
                String phoneLead = strLeads.substringBetween('phone":"','"');
                
                //Si el número comienza por 6 va a ser móvil, si no lo guardamos como teléfono
                if (String.isNotBlank(phoneLead)){      
                    if (phoneLead.startsWith('6') || phoneLead.startsWith('+346') ){
                        leadInsertar.MobilePhone = phoneLead;
                    }else{
                        leadInsertar.phone = phoneLead;
                    }
           		}
                
                //Comprobamos si hay varios teléfonos en el contacto de Clientify. Si los hay, los guardamos en una lista de Strings.    
                String variosphones = strLeads.substringBetween('phone":"', ']');
                if (String.isNotBlank(variosphones)){
                    do {
   							String variosphonesBis = variosphones.substringAfterLast('phone":"');
                        	variosphonesBis = variosphonesBis.substringBefore('"');
                                if (String.isNotBlank(variosphonesBis)){
                                    listaPhones.add(variosphonesBis);
                                }
                        	variosphones = variosphones.substringBeforeLast('phone":"');
					} while (variosphones.contains('phone'));
                }
                
                if (listaPhones.size()>0){
                    leadInsertar.Telefonos_adicionales__c = String.valueOf(listaPhones).substringBetween('(',')');
                    listaPhones.clear();
                }
                
           //Si el idClientify y email(si no es nulo) del lead no está en BBDD, tiene apellido y tiene compañía, campos requeridos, lo podremos insertar en SF
                if (!leadIdClientify.contains(idClientify)){              	
                        if (String.isNotBlank(leadInsertar.lastname) && String.isNotBlank(leadInsertar.company)){
                            listaLeadsInsertar.add(leadInsertar);
                        }
                }
            }

        	//Insertamos la lista de leads de la que hemos obtenido al menos campos requeridos
            
            List<Database.SaveResult> results = Database.insert(listaLeadsInsertar, false);
        	
            for(Database.SaveResult result :results)
            {
                if(result.isSuccess())
                {
                    returnResult.recordProcessedOK++;
                }
                else
                {
                    returnResult.recordProcessedKO++;
                }
                
            }
            //insert listaLeadsInsertar; //Solo activo el insert en caso de querer insertar la Lista, desactivado para pruebas

            //Si hemos obtenido siguiente link al que llamar, deberemos repetir la llamada con ese endpoint
        	clientiSetting.Processed_records__c = clientiSetting.Processed_records__c + cuantosLeads;
            update clientiSetting;
        
        	returnResult.nextURL = strNextEnd;
            return returnResult;
        }
    
 	public static List<String> clientifyCallGetContactsID(String integration){
        
        	//Hacemos la llamada Rest a Clientify con el integration primitivo
        	String bodyResponse = callRestWS(integration);
        	Integer cuantosLeads = 0;
        	String strLeads;
        	Decimal recordCount;
     		Decimal recordProcessed;
        	List<Object> listaLeads = new List<Object>();
        	List<String> clientifyContactList = new List<String>();
        
        	//Si el body que nos devuelve la llamada no es blank, guardamos:
            //La lista de contactos que tenemos en esta página (results)
        	if (String.isNotBlank(bodyResponse)){
                Map<String, Object> mapaLeads = (Map<String, Object>)JSON.deserializeUntyped(bodyResponse);
                listaLeads = (List<Object>)mapaLeads.get('results');
            }
        	
        	//Lista de leads existentes y lista de String en la que guardamos los anteriores IDClientify
        	List <Lead> listaLeadsExistentes = [SELECT Id, LastName, Email, Id_Contacto_Clientify__c FROM Lead];
        	List<String> leadIdClientify = new List<String>();
            if (listaLeadsExistentes.size()>0){
                for(Lead everyExistingLead : listaLeadsExistentes){
                    leadIdClientify.add(everyExistingLead.Id_Contacto_Clientify__c);
                }
            }
        
            for (Object objLead : listaLeads) {
                //Creamos el Lead que vamos a rellenar por cada iteración
                strLeads = JSON.serialize(objLead);
                String idClienti = strLeads.substringAfterLast('id":');
                String idClientify = idClienti.substringBefore(',');
                clientifyContactList.add(idClientify);
            }
        	return clientifyContactList;
        }    
    
    public static string callRestWS(String integration){
                 
                    String bodyResponse;
                    String namedCredential = 'Clientify';
                    String endpoint;
        
        			Log__c log = new Log__c();
					log.recordTypeId = Schema.SObjectType.Log__c.getRecordTypeInfosByDeveloperName() .get('Outbound').getRecordTypeId();
					log.Endpoint_WS__c = endpoint + '/' +integration;
					log.Timestamp__c = System.now();
					log.Service_Name__c = integration;
                        
                    //Hacemos la llamada Rest a Clientify
                    try {
                        HttpRequest req = new HttpRequest();
                        HttpResponse res = new HttpResponse();
                        req.setEndpoint('callout:' + namedCredential + '/' + integration);
                        req.setMethod('GET');
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
                      //insert log;
                    }
                 
                    return bodyResponse;
        }
    
    public class ContactScopeResult 
    {
        public String nextURL;
        public Integer recordProcessedOK;
        public Integer recordProcessedKO;
        
        public ContactScopeResult()
        {
            this.nextURL = '';
            this.recordProcessedOK = 0;
            this.recordProcessedKO = 0;
        }
    }
}