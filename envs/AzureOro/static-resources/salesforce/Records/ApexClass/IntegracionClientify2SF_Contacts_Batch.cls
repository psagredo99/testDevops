/**
 * @description       : 
 * @author            : jose.murillo
 * @group             : 
 * @last modified on  : 26-04-2023
 * @last modified by  : jose.murillo
**/

global class IntegracionClientify2SF_Contacts_Batch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {
    
    private List<String> contactIdList;
    Log__c log = new Log__c();
    Clienti_Settings__c clientiSetting = Clienti_Settings__c.getValues('Clientify');
    Integer emailscreados;
	Integer tareascreadas;
    Integer eventoscreados;
    Integer emailscreadosLast;
	Integer tareascreadasLast;
    Integer eventoscreadosLast;
    Lead leadActualizar;
    
    global IntegracionClientify2SF_Contacts_Batch(List<String> contactIdList){
        this.contactIdList = contactIdList;
    }
    
   
    global Iterable<String> start(Database.BatchableContext BC){
        return this.contactIdList;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        
        String integration = '/v1/contacts';
        String bodyResponse;
        Integer i=0;
       	List<Object> listaTasks = new List<Object>();
       	List<Object> listaWall = new List<Object>();
       	List<Object> listaCalls = new List<Object>();
        List<Event> listaEventosCrear = new List<Event>();
        List<Task> listaTareasCrear = new List<Task>();
        List<Task> listaTareasCreadas = new List<Task>();
        List<EmailMessage> listaEmailsCrear = new List<EmailMessage>();
        List<EmailMessage> listaEmailsCreados = new List<EmailMessage>();
        List<EmailMessageRelation> listaEmailRelation = new List<EmailMessageRelation>();
        
        //Recogemos la lista de tareas existentes
        listaTareasCreadas = [SELECT Id, Id_Clientify__c FROM Task];
        List<String> IdClientifyTaskCreados = new List<String>();
        for(Task everyExistingTask : listaTareasCreadas){
                IdClientifyTaskCreados.add(everyExistingTask.Id_Clientify__c);
		}
        
        //Recogemos la lista de emails existentes
        listaEmailsCreados = [SELECT Id, Id_Clientify__c FROM EmailMessage];
        List<String> IdClientifyEmailCreados = new List<String>();
        for(EmailMessage everyExistingEmail : listaEmailsCreados){
                IdClientifyEmailCreados.add(everyExistingEmail.Id_Clientify__c);
		}
        
        //Recogemos la lista de leads existentes en esta iteración
        List<Lead> listaLeads = [SELECT ID, ID_Contacto_Clientify__c, isConverted FROM LEAD WHERE ID_Contacto_Clientify__c IN: scope];
        
        //Por cada contactoClientify hacemos una llamada para buscar tareas y emails relacionados
        for(String idContactoClientify :scope){
            integration = integration + '/' + idContactoClientify + '/' ;
            bodyResponse = Clientify2SF.callRestWS(integration);
            String relatedTask = 'related_tasks';
            String wall = 'wall_entries';
            Id idLead;
            Boolean converted;
            
            //Guardamos el Lead relacionado a las tareas y emails que vamos a guardar
            for(Lead le :listaLeads){
                if(idContactoClientify==le.ID_Contacto_Clientify__c){
                    idLead = le.id;
                    converted = le.IsConverted;
                    System.debug('ID '+idLead);
                }
            }
            
            //Si el body no es nulo y no está convertido el Lead
            if (String.isNotBlank(bodyResponse)){
                
                List<Lead> leadsProcesado = [SELECT ID, HasOptedOutOfEmail FROM LEAD WHERE ID =: idLead];
                if (leadsProcesado.size() > 0){
                    Lead leadProcesado = leadsProcesado[0];
                    Contact contactoProcesado;
                    if (converted == true){
                         contactoProcesado = [SELECT Id, ID_Contacto_Clientify__c FROM Contact WHERE ID_Contacto_Clientify__c =: idContactoClientify];
                    }
                    Map<String, Object> mapaLead = (Map<String, Object>)JSON.deserializeUntyped(bodyResponse);
                  
                    //Actualizamos si está suscrito o no
                    Boolean bool = Boolean.valueOf(mapaLead.get('unsubscribed'));
                    if (bool == true){
                                leadProcesado.HasOptedOutOfEmail = true;
                        		leadProcesado.Integrado_Clientify__c = true;		//Flag de lead integrado, usado para que no salte flujo de vuelta a Clientify
                    }
                    leadActualizar = leadProcesado;
                	listaTasks = (List<Object>)mapaLead.get(relatedTask);
                
                   	for (Object obj : listaTasks) {
                        
                        Task tareaListaTasks = new Task(); 	//Si la duration es 0, tarea.
                        Event eventoTask = new Event(); 	//Si la duration de la actividad es superior a 0, evento.
                        Integer durationTask;
                        String strTasks = JSON.serialize(obj);
                        System.debug('String Tasks: '+strTasks);
                        Map<String, Object> mapaTask = (Map<String, Object>)JSON.deserializeUntyped(strTasks);
                        
                        String idTask = JSON.serialize(mapaTask.get('id'));
                        idTask = idTask.remove('\\').remove('"');
                        System.debug('Id del Task: '+idTask);
                        
                        String nameTask;
                        String statusTask;
                        String descriptionTask;
                        String taskDate;
                        Date dateTask;
                        String taskDueDate;
                        Date dateDueTask;
                        
                      	if (!IdClientifyTaskCreados.contains(idTask)){ 
                            
                            if (strTasks.contains('duration')){
                                    durationTask = Integer.valueOf(mapaTask.get('duration'));
                                    System.debug('Duration del Task: '+durationTask);
                            }
                            
                            //Recogemos su Nombre, Status, Description, Compañía Clienti si lo tiene
                            
                            if (strTasks.contains('name')){
                               nameTask = String.valueOf(mapaTask.get('name'));
                               nameTask = nameTask.remove('\\').remove('"');
                               System.debug('Nombre del Task: '+nameTask);
                            }
                            
                            if (strTasks.contains('status_desc')){
                               statusTask = String.valueOf(mapaTask.get('status_desc'));
                               statusTask = statusTask.remove('\\').remove('"');
                               System.debug('Status del Task: '+statusTask);
                            }
                            
                            if (strTasks.contains('description')){
                               descriptionTask = String.valueOf(mapaTask.get('decription'));
                               if (descriptionTask == null){
                                   descriptionTask = 'Tarea de Clientify';
                               }else{
                                   descriptionTask = descriptionTask.remove('\\').remove('"');
                               }
                               System.debug('Description del Task: '+descriptionTask);
                            }
                                
                            if (strTasks.contains('start_datetime')){
                               taskDate = String.valueOf(mapaTask.get('start_datetime'));
                               taskDate = taskDate.remove('\\').remove('"');
                               dateTask = date.valueOf(taskDate); //Datetime creationdate
                               System.debug('Date del Task: '+taskDate);
                            }
                                
                            if (strTasks.contains('due_date')){
                               taskDueDate = String.valueOf(mapaTask.get('due_date'));
                               taskDueDate = taskDueDate.remove('\\').remove('"');
							   dateDueTask = date.valueOf(taskDueDate); //Datetime duedate
                               System.debug('Date del Task: '+taskDueDate);
                            }
                            
                        	if (durationTask==0){		//Creamos tarea si es la duration es 0
                                tareaListaTasks.Id_Clientify__c = idTask;
                                if (converted ==false){
                                	tareaListaTasks.WhoId = idLead;
                                }else{
                                    tareaListaTasks.WhoId = contactoProcesado.Id;
                                }
                                //WhatId Cuenta y WhoId Contacto si ya está convertido
                                tareaListaTasks.Subject = nameTask;
                                tareaListaTasks.Status = statusTask;
                                tareaListaTasks.Description = descriptionTask;
                                tareaListaTasks.CreatedDate = dateTask;
                                tareaListaTasks.LastModifiedDate = system.now();
                                tareaListaTasks.ActivityDate = dateDueTask;
                                listaTareasCrear.add(tareaListaTasks);
                                
                            }else{						//Si la duration es distinta a 0, creamos evento
                                eventoTask.Id_Clientify__c = idTask;
                                if (converted ==false){
                                	eventoTask.WhoId = idLead;
                                }else{
                                	eventoTask.WhoId = contactoProcesado.Id;
                                }
                                //WhatId Cuenta y WhoId Contacto si ya está convertido
                                eventoTask.Subject = nameTask;
                                eventoTask.Description = statusTask;
                                eventoTask.Description = descriptionTask;
                                eventoTask.CreatedDate = dateTask;
                                eventoTask.LastModifiedDate = dateTask;
                                eventoTask.ActivityDate = dateDueTask;
                                eventoTask.DurationInMinutes = durationTask;
                                listaEventosCrear.add(eventoTask);
                            }
                        }
                    }
                
                	//Recogemos las llamadas o emails relacionados mediante las Wall Entries
                    
                    listaWall = (List<Object>)mapaLead.get(wall);
                
                 	//Para cada una de las Wall Entries guardadas en la lista
                
                   	for (Object obj : listaWall) {
                        Map<String, Object> mapaWall = new Map<String, Object>();
                        Object objWall; 
                        Object objWallId;
                        Object objWallDate;
                        String strWall; 
                        String strWallId;
                        String strWallDate;
                        String strCall;
                        String strCallDuration;
                        String strMsg;
                    	strWall = JSON.serialize(obj);
                        
                 	//Si contiene la palabra 'call' será una llamada que guardamos como Task de tipo call
                        
                        if (strWall.contains('call')){
                            
                            Task tareaListaCall = new Task();
                            mapaWall = (Map<String, Object>)JSON.deserializeUntyped(strWall);
                            System.debug('String Wall: '+strWall);
                            
                            //Recogemos el Id de la WallEntry
                            objWallId = mapaWall.get('id');
                            strWallId = String.valueOf(objWallId);
                            
                            //Recogemos la fecha de la WallEntry
                            objWallDate = mapaWall.get('created');
                            strWallDate = String.valueOf(objWallDate);
                            strWallDate = strWallDate.substringBefore('T');
                            System.debug('Fecha: '+strWallDate);
                            
                            //Recogemos la Info de la WallEntry
                            objWall = mapaWall.get('extra');
                            strCall = JSON.serialize(objWall);
                            strCall = strCall.remove('\\');
                            strCallDuration = strCall.substringBetween('call_duration\": ', '.');
                            strCall = strCall.substringBetween('call_type": "', '"');
                   			System.debug('String Call: '+strCall+' and duration: '+strCallDuration);
                            
                            //La guardamos como tarea tipo llamada
                            if (!IdClientifyTaskCreados.contains(strWallId)){
                                
                                if (strCall=='null'){
                                    tareaListaCall.Subject = 'Llamada desde Clientify.';
                                }else{
                                    tareaListaCall.Subject = 'Llamada '+strCall;
                                }
                                tareaListaCall.Status = 'Completed';
                                tareaListaCall.ActivityDate = date.valueOf(strWallDate);
                                tareaListaCall.Description = 'Llamada con duración de: '+strCallDuration+' minutos.';
                                if (converted==false){
                                	tareaListaCall.WhoId = idLead;
                                }else{
                                	tareaListaCall.WhoId = contactoProcesado.Id;
                                }
                                tareaListaCall.Id_Clientify__c = strWallId;
                                listaTareasCrear.add(tareaListaCall);
        					}
                                    
                        }
                        
                 //Si contiene la palabra 'message_subject' será una llamada que guardamos como EmailMessage
                        
                        if (strWall.contains('message_subject')){
                            
                            Task tareaListaMessage = new Task();
                            mapaWall = (Map<String, Object>)JSON.deserializeUntyped(strWall);
                            System.debug('String Wall: '+strWall);
                            
                            //Recogemos el Id de la WallEntry
                            objWallId = mapaWall.get('id');
                            strWallId = String.valueOf(objWallId);
                            
                            //Recogemos la fecha de la WallEntry
                            objWallDate = mapaWall.get('created');
                            strWallDate = String.valueOf(objWallDate);
                            strWallDate = strWallDate.substringBefore('T');
                            System.debug('Fecha: '+strWallDate);
                            
                            if (!IdClientifyEmailCreados.contains(strWallId)){
                                
                                //Recogemos la Info de la WallEntry
                                objWall = mapaWall.get('extra');
                                strMsg = JSON.serialize(objWall);
                                strMsg = strMsg.replaceAll('u00e1', 'á').replaceAll('u00e9','é').replaceAll('u00ed','í').replaceAll('u00f3', 'ó').replaceAll('u00da', 'ú').replaceAll('u00bf', '¿').replaceAll('u00f1', 'ñ');
                                strMsg = strMsg.remove('\\');
                                String strEmail = strMsg.substringAfter('email": "').substringBefore('"');
                                System.debug('String Email'+strEmail);
                                strMsg = strMsg.remove('\"');
                                String strSbj = strMsg.substringAfter('message_subject: ').substringBefore('}');
                                System.debug('String Message: '+strSbj);
                                
                                //La guardamos como EmailMessage y añadimos a la Lista que será insetada
                                EmailMessage emailMessage = new EmailMessage();
                                emailMessage.status = '3'; // email enviado
                                emailMessage.subject = strSbj;
                                if (converted ==false){
                                	emailMessage.Candidato__c = idLead;
                                }else{
                                	emailMessage.Candidato__c = contactoProcesado.Id;
                                }
                                emailMessage.toAddress = strEmail;
                                emailMessage.Id_Clientify__c = strWallId;
                                emailMessage.MessageDate = DateTime.newInstance(date.valueOf(strWallDate).year(), date.valueOf(strWallDate).month(), date.valueOf(strWallDate).day());
                                listaEmailsCrear.add(emailMessage);
                            }
                        }
                		}
                   	 }    
                	}
            }
        	/*
        	emailscreados = Integer.valueOf(clientiSetting.EmailsCreados__c + listaEmailsCrear.size());
        	tareascreadas = Integer.valueOf(clientiSetting.TasksCreados__c + listaTareasCrear.size() + listaEmailsCrear.size());
        	eventoscreados = Integer.valueOf(clientiSetting.EventosCreados__c + listaEventosCrear.size());
        
        	clientiSetting.EmailsCreados__c = clientiSetting.EmailsCreados__c + listaEmailsCrear.size();
        	System.debug('Emails: '+clientiSetting.EmailsCreados__c+'. En esta ejecución: '+listaEmailsCrear.size());
        	clientiSetting.TasksCreados__c = clientiSetting.TasksCreados__c + listaTareasCrear.size() + listaEmailsCrear.size();
        	System.debug('Tasks: '+clientiSetting.TasksCreados__c+'. En esta ejecución: '+listaTareasCrear.size());
        	clientiSetting.EventosCreados__c = clientiSetting.EventosCreados__c + listaEventosCrear.size();
        
        	update clientiSetting;*/
        	//Insertamos la lista de Emails
            if(!Test.isRunningTest()){
                insert listaEmailsCrear;
            }
        
            //Para cada email de la lista, creamos la relación con su Lead
            for (EmailMessage emmsg: listaEmailsCrear){
                for(Lead lea :listaLeads){
                	if(lea.id==emmsg.Candidato__c){
                    	EmailMessageRelation emr = new EmailMessageRelation();
                        
                        if(lea.isConverted ==false){
                        	emr.relationId = lea.Id;
                        }else{
                        	emr.relationId = lea.ConvertedContactId;
                        }
                        
                        emr.emailMessageId = emmsg.id;
                        emr.relationType = 'FromAddress';
                        listaEmailRelation.add(emr);
                	}
            	}
            }
        	//Insertamos la lista de relaciones de Emails y Tareas
            if(!Test.isRunningTest()){
        	insert listaEmailRelation;
            insert listaTareasCrear;
        	insert listaEventosCrear;
        	//Prueba, no inserta los de la última iteración
        	/*
       		emailscreadosLast = emailscreados + Integer.valueOf(listaEmailsCrear.size());
            tareascreadasLast = tareascreadas + Integer.valueOf(listaTareasCrear.size() + listaEmailsCrear.size());
            eventoscreadosLast = eventoscreados + Integer.valueOf(listaEventosCrear.size());*/
            }
}
      
    global void finish(Database.BatchableContext BC){
            
        update leadActualizar;
       /* if (clientiSetting.Next_callout_URL__c == 'null' && clientiSetting.Processed_records__c != 0){
            Long minutesExecution;
            if(clientiSetting.Last_Sync_Date__c !=null){
                Long lastSyncDateLong = clientiSetting.Last_Sync_Date__c.getTime() ;
                Long currentDTLong = DateTime.now().getTime();
                Long milliseconds = currentDTLong - lastSyncDateLong;
                minutesExecution = (milliseconds/1000)/60;
            }
            	
            List <Lead> listaLeadsCreadasHoy = [SELECT Id, Id_Clientify__c FROM Lead WHERE ID_Contacto_Clientify__c != null AND CreatedDate = LAST_N_DAYS:1];
            List <Task> listaTasksCreadasHoy = [SELECT Id, Id_Clientify__c FROM Task WHERE ID_Clientify__c != null AND LastModifiedDate = LAST_N_DAYS:1];
            List <EmailMessage> listaEmailsCreadasHoy = [SELECT Id, Id_Clientify__c FROM EmailMessage WHERE ID_Clientify__c != null AND CreatedDate = LAST_N_DAYS:1];
            List <Event> listaEventosCreadasHoy = [SELECT Id, Id_Clientify__c FROM Event WHERE ID_Clientify__c != null AND CreatedDate = LAST_N_DAYS:1];
            Integer numeroTareasCreadas = Integer.valueOf(listaTasksCreadasHoy.size()) + Integer.valueOf(listaEmailsCreadasHoy.size());
            log.Result_Description__c = 'Leads creados: ' + String.valueOf(Integer.valueOf(listaLeadsCreadasHoy.size())) 
                         +'. Tareas creadas: ' + String.valueOf(numeroTareasCreadas)
                         +'. Emails creados: ' + String.valueOf(Integer.valueOf(listaEmailsCreadasHoy.size()))
                         +'. Eventos creados: ' + String.valueOf(Integer.valueOf(listaEventosCreadasHoy.size()))
                         +'. Tiempo de ejecución: ' + String.valueOf(minutesExecution)+' minutos.';
            //insert log;
            
            
               	log.Result_Description__c = 'Leads creados: ' + String.valueOf(Integer.valueOf(clientiSetting.Processed_records__c)) 
                         +'. Tareas creadas: ' + String.valueOf(tareascreadasLast)
                         +'. Emails creados: ' + String.valueOf(emailscreadosLast)
                         +'. Eventos creados: ' + String.valueOf(eventoscreadosLast);
                         insert log;
        }*/
                
        
    } 
}