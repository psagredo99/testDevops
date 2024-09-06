@isTest
private class BatchMergeAccountsTest {

    @isTest
    static void testBatchMergeAccounts() {

		//GENERATE DATA        
        Account masterAccount = new Account(
            Name = 'Test-NAV',
            BillingStreet = 'prueba1NAV',
            BillingCity = 'prueba1NAV',
            BillingState = 'prueba1NAV',
            BillingPostalCode = 'prueba1NAV',
            BillingCountry = 'prueba1NAV',
            Description = 'prueba1NAV',
            NIF_CIF__c = '27348333E'
        );

        Account childAccount = new Account(
            Name = 'Test-SF',
            BillingStreet = 'prueba2',
            BillingCity = 'prueba2',
            BillingState = 'prueba2',
            BillingPostalCode = 'prueba2',
            BillingCountry = 'prueba2',
            Description = 'prueba2',
            NIF_CIF__c = '27348333E'
        );


        // Insert the test data
        insert new List<Account>{masterAccount, childAccount};

        Map<String, List<String>> accountToMergeMap = new Map<String, List<String>>();
        Map<String, Account> accountMap = new Map<String, Account>();

        // Add test data to the maps
        accountToMergeMap.put(masterAccount.Id, new List<String>{childAccount.Id});
        accountMap.put(masterAccount.Id, masterAccount);
        accountMap.put(childAccount.Id, childAccount);

        // Create and start the batch job
        Test.startTest();

        BatchMergeAccounts batchJob = new BatchMergeAccounts(accountToMergeMap, accountMap);
        Database.executeBatch(batchJob);

        Test.stopTest();

        
        Account masterAccountAfterMerge = [SELECT Name FROM Account WHERE Id = :masterAccount.Id];
        System.assertEquals('Test-NAV', masterAccountAfterMerge.Name);

        List<Account> mergedAccounts = [SELECT Id FROM Account WHERE Id = :childAccount.Id];
        System.assertEquals(0, mergedAccounts.size());
    }
}