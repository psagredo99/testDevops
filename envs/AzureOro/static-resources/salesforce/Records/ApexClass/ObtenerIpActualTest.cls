@isTest
public with sharing class ObtenerIpActualTest
{
    @isTest static void ComprobarFunciones()
    {
        Ultima_Ip_Obtenida__c cs = new Ultima_Ip_Obtenida__c();
        cs.Valor__c = '2222';
		insert cs;
        
        Test.startTest();
        ObtenerIpActual.obtenerIpActual();
        Test.stopTest();
    }
}