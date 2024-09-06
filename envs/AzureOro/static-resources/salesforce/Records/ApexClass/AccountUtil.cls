public class AccountUtil 
{
    
    public static String DELETE_PERMISSION_ERROR 	= 'No tienes permisos para borrar cuentas.';
    public static Id navClientRT 					= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cliente').getRecordTypeId();
    public static Id sfClientRT 					= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Cuenta Potencial').getRecordTypeId();

	public static void handleBeforeDelete(List<Account> accountsToDelete) 
    {
        for (Account acc : accountsToDelete) {
            // Verificar si el campo está relleno
            if (acc.Multicompany_ID__c != null) {
                // Verificar los permisos del usuario
                if (!hasDeletePermission()) {
                    acc.addError(DELETE_PERMISSION_ERROR);
                }
            }
        }
    }
    
    //Comment: method to trigger clients integrated from NAV and in case merge it with "Potential Account"
    //Fecha: 2023-10-09
    //Author: murtiaga
	public static void searchAndMergeAccounts(List<Account> newList) 
    {
        Set<String> integratedNAVClientsIds 		= new Set<String>();
        Set<String> integratedNAVClientsDNIs 		= new Set<String>();
        Map<String,List<String>> accountToMergeMap 	= new Map<String,List<String>>();
        Map<String,Account> accountMap 				= new Map<String,Account>();
        
        
        //TEST MOD DEVOPS  acc.RecordTypeId != ''
        for(Account acc :newList)
        {
          if(acc.RecordTypeId == navClientRT && String.isNotBlank(acc.NIF_CIF__c) && acc.RecordTypeId != '' )
          {
              integratedNAVClientsIds.add(acc.Id);
              
              integratedNAVClientsDNIs.add(acc.NIF_CIF__c);
          }
        }
     
        
        if(integratedNAVClientsDNIs.size() > 0)
        {
            Map<String,List<String>> accountDuplicatedRelationMap = new Map<String,List<String>>();
            List<Account> accountList 	= [SELECT Id, NIF_CIF__c
                                           FROM Account
                                           WHERE RecordTypeId = :sfClientRT AND
                                            	 (NOT Id IN :integratedNAVClientsIds) AND
                                          		 NIF_CIF__c IN :integratedNAVClientsDNIs];
            
            
            for(Account accDuplicated :accountList)
            {
                List<String> duplicateAccountIds = new List<String>(); 
                
                if(accountDuplicatedRelationMap.containsKey(accDuplicated.NIF_CIF__c))
                {
                    duplicateAccountIds = accountDuplicatedRelationMap.get(accDuplicated.NIF_CIF__c);
                }
                
                duplicateAccountIds.add(accDuplicated.Id);
                accountDuplicatedRelationMap.put(accDuplicated.NIF_CIF__c, duplicateAccountIds);
            }
            
            for(Account acc :newList)
            {
              if(acc.RecordTypeId == navClientRT && String.isNotBlank(acc.NIF_CIF__c) && accountDuplicatedRelationMap.containsKey(acc.NIF_CIF__c))
              {
                  accountToMergeMap.put(acc.Id, accountDuplicatedRelationMap.get(acc.NIF_CIF__c));
                  accountMap.put(acc.Id, acc);
              }
            }
            
            if(accountToMergeMap.size() > 0)
            {
                System.debug(accountToMergeMap);
                Database.executeBatch( new BatchMergeAccounts(accountToMergeMap, accountMap), 1);
            }
        }
        
        
    }
    
    public static Boolean hasDeletePermission() {
        // Verificar si el usuario tiene el permiso "Delete Navision Accounts"
        return [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Borrar_Cuentas_Navision' AND AssigneeId = :UserInfo.getUserId()].size() > 0;
    }
    
}