global class ObtenerIpActual Implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        obtenerIpActual();
    }
    
    @Future(Callout=true)
    public Static void obtenerIpActual()
    {
        //Llamamos para obtener la IP actual del entorno.
        HttpRequest req = new HttpRequest();
        Map<String, Object> mapResponseBody;
        req.setEndpoint('https://api-bdc.net/data/client-ip/');
        req.setMethod('GET');
        Http httpReq = new Http();

        if(!Test.isRunningTest())
        {
            HttpResponse res = httpReq.send(req);
			mapResponseBody = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(res.getBody()));
        }else {
        	mapResponseBody = (Map<String, Object>) JSON.deserializeUntyped('{"ipString": "1111"}');
        }
        
        //Obtenemos el la última ip guardada.
		List<Ultima_Ip_Obtenida__c> cs = [SELECT Valor__c FROM Ultima_Ip_Obtenida__c LIMIT 1];
        
        //Si la ip actual es distinta a la anterior notificamos por correo y la actualizamos.
        IF(!cs.isEmpty() && mapResponseBody.get('ipString') != cs[0].Valor__c)
        {
            //Actualizamos el Custom Setting con la nueva IP.
            cs[0].Valor__c = String.valueOf(mapResponseBody.get('ipString'));
            update cs;
            
            //Preparamos el correo y lo enviamos para notificar la nueva IP.
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            String destinatarios =  System.Label.ObtenerIpActual_Destinatarios;
            String[] splitDestinatarios = destinatarios.split('\\,');

        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Cambio de IP "CRM PKF Attest"');
            mail.setplaintextbody('Cambio de IP de los servidores del CRM de PKF Attest: Nueva IP ' + String.valueOf(mapResponseBody.get('ipString')));
            mail.setToAddresses(splitDestinatarios);
            emailList.add(mail);
            Messaging.sendEmail(emailList);
            
        }
    }
}