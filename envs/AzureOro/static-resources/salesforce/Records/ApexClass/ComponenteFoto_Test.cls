/**
 * @description       : 
 * @author            : iker.lougedo
 * @group             : 
 * @last modified on  : 30-03-2023
 * @last modified by  : iker.lougedo
**/
@isTest
public with sharing class ComponenteFoto_Test
{
    @testSetup static void setup()
    {

        Account acc = new Account
        (
            Name = 'Test Account',
            Description = 'https://pbs.twimg.com/profile_images/1311763847775125516/mvBRhlDs_400x400.jpg'
           
        );
        insert acc;

        Contact con = new Contact
        (
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id
        );
        insert con;
    }

    @isTest static void ComprobarFunciones()
    {
        Contact con = [SELECT Id FROM Contact WHERE Name = 'Test Contact' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
     
        Test.startTest();
        ComponenteFoto.obtenerIdCampo(con.id,'Contact','AccountId');
        ComponenteFoto.obtenerDatosFoto(acc.Id,'Account','Description','Name');
        ComponenteFoto.obtenerDatosFoto(acc.Id,'Account','Description', null);
        ComponenteFoto.obtenerCampos('Account','GC_ComponenteFoto');
        Test.stopTest();
    }

}