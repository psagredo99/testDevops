global class BatchMergeAccounts implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts
{
    private Map<String,List<String>> accountToMergeMap 	= new Map<String,List<String>>();
    private Map<String,Account> accountMap 				= new Map<String,Account>();
    
    global BatchMergeAccounts(Map<String,List<String>> accountToMergeMap, Map<String,Account> accountMap)
    {
        this.accountToMergeMap 	= accountToMergeMap;
        this.accountMap 		= accountMap;
    }
    
    global Iterable<String> start(Database.BatchableContext BC) 
    {
        System.Debug('******** BatchMergeAccounts Started ***********');
        return accountToMergeMap.keySet();
    } 
    
    global void execute(Database.BatchableContext BC, List<String> scope) 
    {
        System.Debug('******** BatchMergeAccounts execute ***********');
        System.debug('scope: ' + scope.size());
        
        Set<String> SobjectFields 		 = new Set<String>();
        
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
        for(Schema.SObjectField fieldRef : fields.values()) 
        {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            if(fieldResult.isUpdateable()) 
            {
                System.debug('*** Field to Update ***: ' + fieldResult.getname());
                SobjectFields.add(fieldResult.getname());
            }
        }      
        
        
        
        if(scope.size() > 0)
        {
            List<Account> accountOriginalList  = Database.query('SELECT ' + String.join(new List<String>(SobjectFields), ',') + ' FROM Account WHERE Id IN :scope');
			System.debug('*** No. Cuentas ***: ' + accountOriginalList.size());
            System.debug('*** Cuentas ***: ' + accountOriginalList);
            
            
            for(Account masterAccount :accountOriginalList)
            {        
                  Database.MergeResult[] results = Database.merge(masterAccount, accountToMergeMap.get(masterAccount.Id), false);
                  
                  for(Database.MergeResult res : results) 
                  {
                      if (!res.isSuccess()) 
                      {
                        for(Database.Error err : res.getErrors()) 
                        {
                            System.debug(err.getMessage());
                        }                          
                      }
                  }               
            }
            
            accountOriginalList  = Database.query('SELECT ' + String.join(new List<String>(SobjectFields), ',') + ' FROM Account WHERE Id IN :scope');
			System.debug('*** AFTER -- No. Cuentas ***: ' + accountOriginalList.size());
            System.debug('*** AFTER -- Cuentas ***: ' + accountOriginalList);
        }
        
    }
    
    global void finish(Database.BatchableContext BC) 
    {    
        System.Debug ('******** BatchMergeAccounts Finish ***********');
    }     
}