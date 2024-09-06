@isTest
public class AccountUtilTest {
    @isTest
    static void testDeleteAccountWithoutPermission() {
        // Crear cuentas con campos rellenos y vacíos para pruebas
        List<Account> accountsToInsert = new List<Account>();
        accountsToInsert.add(new Account(Name = 'Prueba Trigger con multicompany ID', Multicompany_ID__c = '123456'));
        accountsToInsert.add(new Account(Name = 'Prueba Trigger sin multicompany ID', Multicompany_ID__c = null));
        insert accountsToInsert;

        // Intentar borrar cuentas con el campo lleno y vacío sin permisos
        Test.startTest();
        try {
            delete accountsToInsert;
        } catch (DmlException e) {
            String errorMessage = AccountUtil.DELETE_PERMISSION_ERROR;
            System.assertEquals(errorMessage, e.getDmlMessage(0));
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteAccountWithoutMulticompany() {
        // Crear cuentas sin Multicompany ID
        Account accountWithoutMulticompany = new Account(Name = 'Prueba Trigger sin multicompany ID', Multicompany_ID__c = null);
        insert accountWithoutMulticompany;

        // Intentar borrar cuentas sin Multicompany ID con permisos
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            delete accountWithoutMulticompany;
        }
        Test.stopTest();
    }

    
}