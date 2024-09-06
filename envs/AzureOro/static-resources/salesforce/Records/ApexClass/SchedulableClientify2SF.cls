/**
 * @description       : 
 * @author            : jose.murillo
 * @group             : 
 * @last modified on  : 26-04-2023
 * @last modified by  : jose.murillo
**/

global class SchedulableClientify2SF implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful{
	
     String nextURL;
     Integer recordProcessed;
     public Integer recordProcessedOK;
     public Integer recordProcessedKO;
     Integer recordTotales;
     List<String> clientifyContactListDef = new List<String>();
     Log__c logRecord;
     Clienti_Settings__c clientiSetting;
    
 	 public String query = 'Select ID, Name from Profile WHERE Name = \'Administrador del sistema\'';
    	
     global SchedulableClientify2SF(Log__c logRecord, Integer recordProcessedOK, Integer recordProcessedKO){
         this.logRecord 		= logRecord;
         this.recordProcessedOK = recordProcessedOK;
         this.recordProcessedKO = recordProcessedKO;
     }
    
     global List<String> start(Database.BatchableContext BC) {
        		//Recupera el custom setting del que nos servimos para guardar los datos.
        		if(Test.isRunningTest()){
                    clientiSetting = Clienti_Settings__c.getValues('Test');
                    nextURL = clientiSetting.Next_callout_URL__c;
                }else{
                    clientiSetting = Clienti_Settings__c.getValues('Clientify');
                    nextURL = clientiSetting.Next_callout_URL__c;
                }
         
         		//Si la URL no es null, se llama a ella. 
         		if (nextURL!='null'){
                    clientiSetting.Next_callout_URL__c = nextURL;
                }else{				//Si es null -fue la última- se llama a la raíz de contactos y se resetea el custom Setting.
                    clientiSetting.Next_callout_URL__c = '/v1/contacts/';
                    clientiSetting.Processed_records__c = 0;
                    nextURL = '/v1/contacts/';
                }
         
         		List<String> clientifyContactList = Clientify2SF.clientifyCallGetContactsID(nextURL);
         		List<String> listaNext = new List<String>();
         		listaNext.add(nextURL);
         		clientifyContactListDef.addAll(clientifyContactList);
         		update clientiSetting;
                return listaNext;
     }

     global void execute(Database.BatchableContext BC, List<String> scope) {       
 				
         		Clientify2SF.ContactScopeResult respuesta = Clientify2SF.clientifyCallContacts(nextURL);
         		nextURL = respuesta.nextURL;
         		recordProcessedOK = recordProcessedOK + respuesta.recordProcessedOK;
         		recordProcessedKO = recordProcessedKO + respuesta.recordProcessedKO;
         		logRecord.Result_Description__c = 
                    'Procesados OK: '+ String.valueOf(recordProcessedOK) 
                    +'. Procesados KO: '+ String.valueOf(recordProcessedKO)+'.';
         		
              	//Volvemos a recoger el Custom Setting Actualizado desde la llamada.
                Clienti_Settings__c  clientiSettingBis;
        		if(Test.isRunningTest()){
                    clientiSettingBis = Clienti_Settings__c.getValues('Test');
                }else{
                    clientiSettingBis= Clienti_Settings__c.getValues('Clientify');
                }
         		recordProcessed = clientiSettingBis.Processed_records__c.intValue();
         		recordTotales = clientiSettingBis.Record_count__c.intValue();
         
                if (recordProcessed > recordTotales || nextURL=='null' /*|| recordProcessed>49*/){		//Se capa en recordProcessed para pruebas
                    recordProcessed = 0;
                    clientiSettingBis.Next_callout_URL__c = 'null';
                }else{ 
         			clientiSettingBis.Next_callout_URL__c = nextURL;
                }
         		update clientiSettingBis;
         		upsert logRecord;
    }   

    global void finish(Database.BatchableContext BC){ 	
				
        			//Al final del batch, si la siguiente llamada es nula, la dejamos programada. Si no, llamamos a ella.
        			
                    if(!Test.isRunningTest()){
                            Database.executeBatch(new IntegracionClientify2SF_Contacts_Batch(clientifyContactListDef), 1);
                    }
        			if (nextURL!='null' && recordProcessed<recordTotales && recordProcessed != 0 /*&& recordProcessed <49*/){ //Capado a x+1 registros para pruebas
                            StartTheBatch();
                    }else{
                            ScheduleTheBatch();
                    }
    }
    

    public void StartTheBatch(){
        
                    //Llamada de nuevo al batch con la nueva URL guardada.
            
                    SchedulableClientify2SF batch = new SchedulableClientify2SF(logRecord, recordProcessedOK, recordProcessedKO); 
                    Id batchId = Database.executeBatch(batch,1);
    }
    
    public void ScheduleTheBatch(){
        	
                    //Programamos el batch.
                    if (recordProcessedKO==0){
                        logRecord.Result__c = 'Success';
                    }else{
                        logRecord.Result__c = 'Error';
                    }
        			logRecord.Service_Name__c = 'Integración Clientify Leads: '+String.valueOf(System.now());
        			update logRecord;
                    Integer minutesFromNow = 1410; //Cada 1440 minutos, un día. Tarda 30 minutos.
                    Log__c logRecordBis = new Log__c();
                    SchedulableClientify2SF batchSche = new SchedulableClientify2SF(logRecordBis, 0, 0);
                    if(!Test.isRunningTest()){
                        Id scheId = System.scheduleBatch(batchSche, String.valueOf(System.now()), minutesFromNow, 1);
                    }
        
    }
    
}