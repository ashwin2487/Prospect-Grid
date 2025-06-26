@IsTest
public class gridSetupController_Test {
    
    private static List<Id> accountIds = new List<Id>(); 
    
    @TestSetup
    public static void setupTestData(){
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]; 
        User userRec = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'test.user@example.com',
            Username = 'test.user@example.com' + System.currentTimeMillis(),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = userProfile.Id
        );
        insert userRec;
        List<Account> accList = new List<Account>{
            new Account(
                Name = 'Test Account 1',
                AccountNumber = 'ACC123456',
                NumberOfEmployees = null,
                Industry = 'Technology',
                Rating = 'Hot',
                Phone = '123-456-7890',
                Website = NULL,
                AnnualRevenue = 5000000,
                Description = 'Test Account 1 for testing.',
                LinkedIn_Profile__c = null,
                LinkedIn_Id__c = null,
                OwnerId = userRec.Id
            ),
                new Account(
                    Name = 'Test Account 2',
                    AccountNumber = 'ACC789123',
                    NumberOfEmployees = 100,
                    Industry = 'Banking',
                    Rating = 'Warm',
                    Phone = '987-654-3210',
                    Website = 'https://www.testaccount2.com',
                    AnnualRevenue = 2000000,
                    Description = 'Test Account 2 for testing.',
                    LinkedIn_Id__c ='dummyLinkedInId'
                ),
                new Account(
                    Name = 'Test Account 3',
                    AccountNumber = 'ACC555999',
                    NumberOfEmployees = 500,
                    Industry = 'Technology',
                    Rating = 'Cold',
                    Phone = '555-123-4567',
                    Website = 'https://www.testaccount3.com',
                    AnnualRevenue = 10000000,
                    Description = 'Test Account 3 for testing.',
                    OwnerId = userRec.Id
                )
                };
                    insert accList;
        
        
        
        // Insert a LinkedIn_Account__c record for the current running user.
        LinkedIn_Account__c lia = new LinkedIn_Account__c(
            Account_ID__c = 'ZtyH-S1LQQqlLyjxzemjxw',  
            User_Name__c = UserInfo.getName()
        );
        insert lia;
        
        for (Account acc : accList) {
            accountIds.add(acc.Id);
        }    
        
        Contact existingContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Current_Company_Name__c = 'Test Company',
            LinkedInURN__c = 'urn:12345',
            Title = 'Original Title',
            Contact_Outreach_Owner__c = userRec.Id,
            AccountId = accountIds.get(0),
            Contact_LinkedIn_Id__c = 'LinkedIn123',
            LinkedIn_Connection_Status__c = 'Connected'
        );
        insert existingContact;
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = accountIds.get(0),
            Title = 'Engineer',
            Current_Company_Name__c = 'Test Account 2',
            Contact_LinkedIn_Id__c = 'LinkedIn456',
            LinkedIn_Connection_Status__c = 'Not Connected'
        );
        Contact con2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            AccountId =accountIds.get(1),
            Title = 'Manager',
            Current_Company_Name__c = 'Test Company',
            Contact_LinkedIn_Id__c = 'LinkedIn789',
            LinkedIn_Connection_Status__c = 'Not Connected'
        );
        Contact con3 = new Contact(
            FirstName = 'Mike',
            LastName = 'Taylor',
            AccountId = accountIds.get(2),
            Title = 'Developer',
            Current_Company_Name__c = 'Tech Corp',
            Contact_LinkedIn_Id__c=NULL,
            LinkedIn_Connection_Status__c = 'Not Connected'
        );
        insert new List<Contact>{con1, con2, con3};
            
        Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;
     }
    
    @IsTest
    public static void getFilteredAccounts_Test(){
        List<String> industries = new List<String>{'Banking'};  
            
            Map<String, Object> selectedRevenue = new Map<String, Object>{
                'min' => 1000000,
                    'max' => 3000000,
                    'hasGreaterThanOnly' => false
                    };
                        
                        Map<String, Object> selectedHeadCount = new Map<String, Object>{
                            'min' => 50,
                                'max' => 150,
                                'hasGreaterThanOnly' => false
                                };
                                    
        String selectedAccountOwner = UserInfo.getUserId();  
        
        List<Account> accountList = gridSetupController.getFilteredAccounts(
            industries, selectedRevenue, selectedHeadCount, selectedAccountOwner
        );
        
        // Assertions
        System.assertEquals(1, accountList.size(), 'Only one account should match the test filters.');
        
        Account matchedAcc = accountList[0];
        System.assertEquals('Test Account 2', matchedAcc.Name, 'Account name should match.');
        System.assertEquals('Banking', matchedAcc.Industry, 'Industry should match.');
        System.assertEquals(2000000, matchedAcc.AnnualRevenue, 'Annual revenue should match.');
        System.assertEquals(100, matchedAcc.NumberOfEmployees, 'Headcount should match.');
        System.assertEquals(UserInfo.getUserId(), matchedAcc.OwnerId, 'Owner ID should match.');
    }
    
    @IsTest
    public static void getFilteredAccounts_MultipleMatches_Test(){
                          
        List<String> industries = new List<String>{'Technology'};  
        Map<String, Object> selectedRevenue = new Map<String, Object>();
        Map<String, Object> selectedHeadCount = new Map<String, Object>();
        String selectedAccountOwner = '';
        
        List<Account> accountList = gridSetupController.getFilteredAccounts(
            industries, selectedRevenue, selectedHeadCount, selectedAccountOwner
        );
        
        System.assertEquals(2, accountList.size(), 'Two accounts should match the Technology industry filter.');
    }
    
    @isTest
    static void testGetAccountOwners() {
        Test.startTest();
        List<User> accountOwners = gridSetupController.getAccountOwners();
        Test.stopTest();

        System.assertNotEquals(0, accountOwners.size(), 'Account owners should be returned');
    }

    @isTest
    static void testGetContacts() {
        List<Account> accounts = [SELECT Id,Name FROM Account WHERE Name='Test Account 2'  LIMIT 1];
        System.assert(!accounts.isEmpty(), 'Test data for accounts should exist');

        Test.startTest();
        List<Contact> contacts = gridSetupController.getContacts(new List<Id>{accounts[0].Id});
        Test.stopTest();

        System.assertNotEquals(0, contacts.size(), 'Contacts should be returned');
        System.assertEquals('Jane Smith', contacts[0].Name, 'Contact last name should match');
    }

    @isTest
    static void testGetProducts() {
        Test.startTest();
        List<Product2> products = gridSetupController.getProducts();
        Test.stopTest();

        System.assertNotEquals(0, products.size(), 'Products should be returned');
        System.assertEquals('Test Product', products[0].Name, 'Product name should match');
    }
    
    @IsTest
    public static void testSearchLinkedinForCompany_Success() {
        Account testAcc = [SELECT Id, Name, Industry, AnnualRevenue, Website, NumberOfEmployees 
                           FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>{ testAcc.Id };
            
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockLinkedInApiResponse());
        List<Map<String, Object>> results = gridSetupController.searchLinkedinForCompany(accountIds);
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Expected at least one search result');
    }
    
    @IsTest
    static void testSearchLinkedinForCompany_Rejection() {
        Account testAcc = [SELECT Id, Name, Industry, AnnualRevenue, Website, NumberOfEmployees 
                           FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        List<String> accountIds = new List<String>{ testAcc.Id };
            
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockLinkedInApiResponseReject());
        List<Map<String, Object>> results = gridSetupController.searchLinkedinForCompany(accountIds);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Expected no search result due to API rejection');
    }
    
    // Success response mock
    private class MockLinkedInApiResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"items": [{"id": "1", "name": "Test Account 1", "profile_url": "https://linkedin.com/test1"}], "cursor": null}');
            return res;
        }
    }
    
    // API rejection mock
    private class MockLinkedInApiResponseReject implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "API Error: Request rejected"}');
            return res;
        }
    }
    
    @IsTest
    static void testGetIndustryCode_Success() {
        
        Test.setMock(HttpCalloutMock.class, new MockIndustryCodeResponse());
        
        Test.startTest();
        List<String> industryCodes = gridSetupController.getIndustryCode('Technology');
        Test.stopTest();
        
        System.assertNotEquals(null, industryCodes, 'Result should not be null.');
        System.assertEquals(1, industryCodes.size(), 'Should return one industry code.');
        System.assertEquals('techCode1', industryCodes[0], 'Industry code should be techCode1.');
    }
    
    @IsTest
    static void testGetIndustryCode_EmptyIndustry() {
        Test.startTest();
        List<String> industryCodes = gridSetupController.getIndustryCode('');
        Test.stopTest();
        System.assertEquals(0, industryCodes.size(), 'Expected empty list when industry name is empty.');
    }
    
    @IsTest
    static void testGetIndustryCode_Non200Response() {
        
        Test.setMock(HttpCalloutMock.class, new MockIndustryCodeResponseNon200());
        
        Test.startTest();
        List<String> industryCodes = gridSetupController.getIndustryCode('Technology');
        Test.stopTest();
        
        System.assertEquals(0, industryCodes.size(), 'Expected empty list when API returns non-200.');
    }
    
    private class MockIndustryCodeResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"items": [{"id": "techCode1"}]}');
            return res;
        }
    }
    
    private class MockIndustryCodeResponseNon200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "API Error"}');
            return res;
        }
    }
    
    @IsTest
    static void testProcessSelectedAccounts_Success() {
        
        List<gridSetupController.UnipileAccountWrapper> wrappers = new List<gridSetupController.UnipileAccountWrapper>();
        gridSetupController.UnipileAccountWrapper wrapper = new gridSetupController.UnipileAccountWrapper();
        wrapper.id = 'company1';
        wrapper.salesforceAccountName = 'Test SF Account';
        wrapper.salesforceAccountId = '001xx000003DGbNAAW';
        wrappers.add(wrapper);
        
        
        Test.setMock(HttpCalloutMock.class, new MockProcessSelectedAccountsResponse());
        
        Test.startTest();
        List<Map<String, Object>> results = gridSetupController.processSelectedAccounts(wrappers);
        Test.stopTest();
        
        
        System.assertNotEquals(null, results, 'Results should not be null.');
        System.assertEquals(1, results.size(), 'Expected one company detail map.');
        
        Map<String, Object> resultMap = results[0];
        System.assertEquals('company1', resultMap.get('companyId'));
        System.assertEquals('Test Company Name', resultMap.get('companyName'));
        System.assertEquals('Test Company Description', resultMap.get('companyDescription'));
        System.assertEquals('https://linkedin.com/testprofile', resultMap.get('companyProfileUrl'));
        System.assertEquals('https://testcompany.com', resultMap.get('companyWebsite'));
        System.assertEquals(123, resultMap.get('companyEmployeeCount'));
        System.assertEquals('Test SF Account', resultMap.get('salesforceAccountName'));
        System.assertEquals('001xx000003DGbNAAW', resultMap.get('salesforceAccountId'));
    }
    
    private class MockProcessSelectedAccountsResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id": "company1", "name": "Test Company Name", "description": "Test Company Description", "profile_url": "https://linkedin.com/testprofile", "website": "https://testcompany.com", "employee_count": 123}');
            return res;
        }
    }
    
    
    //TODO:
    @IsTest
    static void testUpdateSalesforceAccount_Success() {
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'Test Account 1'];
        
        // Create wrapper with new values
        gridSetupController.SalesforceAccountUpdateWrapper wrapper = new gridSetupController.SalesforceAccountUpdateWrapper();
        wrapper.salesforceAccountId = testAcc.Id;
        wrapper.companyWebsite = 'https://updated.com';
        wrapper.companyEmployeeCount = 500;
        wrapper.companyName = 'Updated Name';
        wrapper.companyId = 'newLinkedInId';
        wrapper.companyProfileUrl = 'https://linkedin.com/updated';
        
        Test.startTest();
        List<Account> updatedAccounts = gridSetupController.updateSalesforceAccount(new List<gridSetupController.SalesforceAccountUpdateWrapper>{wrapper});
        Test.stopTest();
        
        System.assertEquals(1, updatedAccounts.size(), 'One Account should be updated and returned');
        
        Account updatedAcc = [SELECT Website, Name, NumberOfEmployees, LinkedIn_Profile__c, LinkedIn_Id__c 
                              FROM Account 
                              WHERE Id = :testAcc.Id];
        
        System.assertEquals('https://updated.com', updatedAcc.Website, 'Website not updated');
        System.assertEquals('Updated Name', updatedAcc.Name, 'Name not updated');
        System.assertEquals(500, updatedAcc.NumberOfEmployees, 'Employee count not updated');
        System.assertEquals('https://linkedin.com/updated', updatedAcc.LinkedIn_Profile__c, 'LinkedIn URL not updated');
        System.assertEquals('newLinkedInId', updatedAcc.LinkedIn_Id__c, 'LinkedIn ID not updated');
    }
    
    @IsTest
    static void testUpdateSalesforceAccount_NullInput() {
        Test.startTest();
        List<Account> updatedAccounts = gridSetupController.updateSalesforceAccount(null);
        Test.stopTest();
        System.assertEquals(0, updatedAccounts.size(), 'No accounts should be updated for null input.');
    }
    
    
    // Test when no LinkedIn Account exists
    @IsTest
    static void testSearchContactsOnLinkedIn_NoLinkedInAccount() {
        // Delete any LinkedIn_Account__c records.
        List<LinkedIn_Account__c> liAccList = [SELECT Id FROM LinkedIn_Account__c];
        delete liAccList;
        
        List<gridSetupController.UnipileAccountWrapper> selectedAccounts = new List<gridSetupController.UnipileAccountWrapper>();
        gridSetupController.UnipileAccountWrapper wrapper = new gridSetupController.UnipileAccountWrapper();
        wrapper.id = 'dummyId1';
        selectedAccounts.add(wrapper);
        
        List<Map<String, Object>> results = gridSetupController.searchContactsOnLinkedIn(
            selectedAccounts,
            new List<String>{'Manager'},       
            new List<String>{},                
            new List<String>{'Engineering'},   
            new List<String>{},                
            new List<String>{'USA'}            
        );
        
        System.assertEquals(0, results.size(), 'Expected no contacts when LinkedIn Account is missing.');
    }   
    
    
    @IsTest
    public static void testSearchContactsOnLinkedIn_WithData() {
        
        Account dummyAcc = new Account(
            Name = 'Dummy Account for Contacts',
            Website = 'https://dummy.com',
            LinkedIn_Id__c = 'dummyLinkedInId'
        );
        insert dummyAcc;
        
        Contact dummyContact = new Contact(
            FirstName = 'Dummy',
            LastName = 'Test',
            AccountId = dummyAcc.Id,
            Title = 'Manager',            
            Department = 'Engineering',  
            MailingCountry = 'USA'        
        );
        insert dummyContact;
        
        List<gridSetupController.UnipileAccountWrapper> selectedAccounts = new List<gridSetupController.UnipileAccountWrapper>();
        gridSetupController.UnipileAccountWrapper wrapper = new gridSetupController.UnipileAccountWrapper();
        wrapper.salesforceAccountId = dummyAcc.Id;
        selectedAccounts.add(wrapper);
        
        Test.setMock(HttpCalloutMock.class, new MockSearchContactsResponse());
        
        Test.startTest();
        List<Map<String, Object>> results = gridSetupController.searchContactsOnLinkedIn(
            selectedAccounts,
            new List<String>{'Manager'},     // includedSeniorityLevel
            new List<String>{'Intern'},       // excludedSeniorityLevel
            new List<String>{'Engineering'},  // includedDepartment
            new List<String>{'Sales'},        // excludedDepartment
            new List<String>{'USA'}           // selectedRegions
        );
        Test.stopTest();
        
        System.debug('Returned contact list: ' + results);
        System.assert(results.size() > 0, 'Expected at least one contact from the API call.');
        
        Map<String, Object> contact = results[0];
        System.assert(contact.containsKey('LinkedIn_URN'), 'Contact should have LinkedIn_URN.');
        System.assert(contact.containsKey('Contact_LinkedIn_Id__c'), 'Contact should have Contact_LinkedIn_Id__c.');
        System.assert(contact.containsKey('name'), 'Contact should have name.');
        System.assert(contact.containsKey('firstName'), 'Contact should have firstName.');
        System.assert(contact.containsKey('lastName'), 'Contact should have lastName.');
        System.assert(contact.containsKey('location'), 'Contact should have location.');
        System.assert(contact.containsKey('profile_url'), 'Contact should have profile_url.');
        System.assert(contact.containsKey('currentPosition'), 'Contact should have currentPosition.');
        System.assert(contact.containsKey('company'), 'Contact should have company.');
    }
    
    private class MockSearchContactsResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String jsonResponse = '{ "items": [' +
                '{' +
                '"member_urn": "urn:li:member:12345",' +
                '"id": "contact123",' +
                '"name": "John Doe",' +
                '"first_name": "John",' +
                '"last_name": "Doe",' +
                '"location": "USA",' +
                '"public_profile_url": "https://linkedin.com/in/johndoe",' +
                '"current_positions": [' +
                '{' +
                '"role": "Software Engineer",' +
                '"company": "Test Company"' +
                '}' +
                ']' +
                '}' +
                '], "cursor": null }';
            res.setBody(jsonResponse);
            return res;
        }
    } 
    @IsTest
    public static void testGetLinkedInAccountId_ReturnsValue() {
        List<LinkedIn_Account__c> existingAccs = [SELECT Id FROM LinkedIn_Account__c WHERE User_Name__c = :UserInfo.getName()];
        if (!existingAccs.isEmpty()) {
            delete existingAccs;
        }
        LinkedIn_Account__c liAcc = new LinkedIn_Account__c(
            Account_ID__c = 'TestAccountId123',
            User_Name__c = UserInfo.getName()
        );
        insert liAcc;
        
        String ret = gridSetupController.getLinkedInAccountId();
        System.assertEquals('TestAccountId123', ret, 'Expected the inserted Account_ID__c to be returned.');
    }
    @IsTest
    public static void testGetLinkedInAccountId_NoRecord() {
        List<LinkedIn_Account__c> existingAccs = [SELECT Id FROM LinkedIn_Account__c WHERE User_Name__c = :UserInfo.getName()];
        if (!existingAccs.isEmpty()) {
            delete existingAccs;
        }
        
        String ret = gridSetupController.getLinkedInAccountId();
        System.assertEquals(null, ret, 'Expected null when no LinkedIn_Account__c record exists.');
    }
    
    @IsTest
    static void testGetAccountContacts() {
        
        Account testAcc = [SELECT Id, Name, LinkedIn_Id__c FROM Account WHERE Name='Test Account 2' LIMIT 1];
        
        List<gridSetupController.UnipileAccountWrapper> selectedAccounts = new List<gridSetupController.UnipileAccountWrapper>();
        
        gridSetupController.UnipileAccountWrapper wrapper = new gridSetupController.UnipileAccountWrapper();
        
        wrapper.salesforceAccountId = testAcc.Id; 
        selectedAccounts.add(wrapper);
        
        Map<Id, gridSetupController.AccountContactWrapper> resultMap = gridSetupController.getAccountContacts(selectedAccounts);
        
        
        System.assertNotEquals(0, resultMap.size(), 'Expected accountContactMap to contain our test account.');
        System.assert(resultMap.containsKey(testAcc.Id), 'Map should contain the account Id.');
        
        gridSetupController.AccountContactWrapper acw = resultMap.get(testAcc.Id);
        
        System.assertEquals('Test Account 2', acw.accountName, 'The account name should match.');
        System.assertEquals('dummyLinkedInId', acw.linkedInId, 'The LinkedIn Id should match.');
        System.assertEquals(1, acw.contacts.size(), 'Expected one related contact.');
    }
    
    @IsTest
    static void testCreateFilterMap_BothNull() {
        // Both lists are null. Expect an empty map.
        Map<String, Object> result = gridSetupController.createFilterMap(null, null);
        System.assertEquals(0, result.size(), 'Expected empty map when both includeList and excludeList are null.');
    }
    
    @IsTest
    static void testCreateFilterMap_IncludeOnly() {
        // Only includeList is provided.
        List<String> includeList = new List<String>{'Value1', 'Value2'};
            Map<String, Object> result = gridSetupController.createFilterMap(includeList, null);
        
        System.assertEquals(1, result.size(), 'Expected map with one key when only includeList is provided.');
        System.assert(result.containsKey('include'), 'Expected map to contain key "include".');
        System.assertEquals(includeList, (List<String>) result.get('include'), 'Include list does not match.');
    }
    
    @IsTest
    static void testCreateFilterMap_ExcludeOnly() {
        // Only excludeList is provided.
        List<String> excludeList = new List<String>{'ValueA', 'ValueB'};
            Map<String, Object> result = gridSetupController.createFilterMap(null, excludeList);
        
        System.assertEquals(1, result.size(), 'Expected map with one key when only excludeList is provided.');
        System.assert(result.containsKey('exclude'), 'Expected map to contain key "exclude".');
        System.assertEquals(excludeList, (List<String>) result.get('exclude'), 'Exclude list does not match.');
    }
    
    @IsTest
    static void testCreateFilterMap_BothNonEmpty() {
        // Both lists are provided.
        List<String> includeList = new List<String>{'Include1', 'Include2'};
            List<String> excludeList = new List<String>{'Exclude1', 'Exclude2'};
                Map<String, Object> result = gridSetupController.createFilterMap(includeList, excludeList);
        
        System.assertEquals(2, result.size(), 'Expected map with both "include" and "exclude" keys when both lists are non-empty.');
        System.assert(result.containsKey('include'), 'Expected key "include" to be present.');
        System.assert(result.containsKey('exclude'), 'Expected key "exclude" to be present.');
        System.assertEquals(includeList, (List<String>) result.get('include'), 'Include list does not match.');
        System.assertEquals(excludeList, (List<String>) result.get('exclude'), 'Exclude list does not match.');
    }
    
    @IsTest
    static void testCreateFilterMap_BothEmpty() {
        List<String> includeList = new List<String>();
        List<String> excludeList = new List<String>();
        Map<String, Object> result = gridSetupController.createFilterMap(includeList, excludeList);
        
        System.assertEquals(0, result.size(), 'Expected empty map when both lists are empty.');
    }
    
    
    @IsTest
    static void testPrepareHttpRequests_WithValidLinkedInId() {
        
        gridSetupController.AccountContactWrapper wrapper = 
            new gridSetupController.AccountContactWrapper('Test Account', 'TestLinkedInId', new List<Contact>());
        
        Map<Id, gridSetupController.AccountContactWrapper> accountContactMap = new Map<Id, gridSetupController.AccountContactWrapper>();
        Id dummyAccId = '000000000000001';
        accountContactMap.put(dummyAccId, wrapper);
        
        Map<String, Object> seniorityFilter = new Map<String, Object>{ 'include' => new List<String>{'Manager'} };
        Map<String, Object> departmentFilter = new Map<String, Object>{ 'include' => new List<String>{'Engineering'} };
        Map<String, Object> locationFilter = new Map<String, Object>{ 'include' => new List<String>{'USA'} };
                    
        String baseUrl = 'https://unipile.api/endpoint';
        
        List<HttpRequest> requests = gridSetupController.prepareHttpRequests(accountContactMap, baseUrl, seniorityFilter, departmentFilter, locationFilter);
        
        System.assertEquals(1, requests.size(), 'Expected one HTTP request.');
        
        HttpRequest req = requests[0];
        System.assertEquals('POST', req.getMethod(), 'Expected method to be POST.');
        System.assertEquals(baseUrl, req.getEndpoint(), 'Expected endpoint to match baseUrl.');
        
        System.assertEquals(System.Label.apiKeyUNipile, req.getHeader('X-API-KEY'), 'Expected API key header.');
        System.assertEquals('application/json', req.getHeader('Accept'), 'Expected Accept header to be application/json.');
        System.assertEquals('application/json', req.getHeader('Content-Type'), 'Expected Content-Type header to be application/json.');
        
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
        System.assertEquals('sales_navigator', payload.get('api'), 'Expected api value to be sales_navigator.');
        System.assertEquals('people', payload.get('category'), 'Expected category value to be people.');
        System.assertEquals(seniorityFilter, payload.get('seniority'), 'Expected seniority filter to match.');
        System.assertEquals(locationFilter, payload.get('location'), 'Expected location filter to match.');
        System.assertEquals(departmentFilter, payload.get('function'), 'Expected department filter to match.');
        
        Map<String, Object> companyMap = (Map<String, Object>) payload.get('company');
        List<Object> companyInclude = (List<Object>) companyMap.get('include');
        System.assertEquals(1, companyInclude.size(), 'Expected one company id in include.');
        System.assertEquals(wrapper.linkedInId, companyInclude[0], 'Expected company id to match the wrapper\'s linkedInId.');
    }
    
    @IsTest
    static void testPrepareHttpRequests_WithBlankLinkedInId() {
        // Create a dummy AccountContactWrapper with a blank linkedInId.
        gridSetupController.AccountContactWrapper wrapper = 
            new gridSetupController.AccountContactWrapper('Test Account', '', new List<Contact>());
        
        Map<Id, gridSetupController.AccountContactWrapper> accountContactMap = new Map<Id, gridSetupController.AccountContactWrapper>();
        Id dummyAccId = '000000000000002';
        accountContactMap.put(dummyAccId, wrapper);
        
        Map<String, Object> seniorityFilter = new Map<String, Object>{ 'include' => new List<String>{'Manager'} };
        Map<String, Object> departmentFilter = new Map<String, Object>{ 'include' => new List<String>{'Engineering'} };
        Map<String, Object> locationFilter = new Map<String, Object>{ 'include' => new List<String>{'USA'} };
        String baseUrl = 'https://dummy.api/endpoint';
        
        List<HttpRequest> requests = gridSetupController.prepareHttpRequests(accountContactMap, baseUrl, seniorityFilter, departmentFilter, locationFilter);
        
        System.assertEquals(0, requests.size(), 'Expected no HTTP request if linkedInId is blank.');
    }
    
    private class TestExecuteApiRequestsMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (callCount == 1) {
                // First call returns one contact and a non-null cursor.
                String jsonResponse = '{ "items": [' +
                    '{' +
                    '"member_urn": "urn:li:member:111",' +
                    '"id": "contact1",' +
                    '"name": "Contact One",' +
                    '"first_name": "First1",' +
                    '"last_name": "Last1",' +
                    '"location": "Location One",' +
                    '"public_profile_url": "https://linkedin.com/in/contactone",' +
                    '"current_positions": [' +
                    '{ "role": "Engineer", "company": "Company One" }' +
                    ']' +
                    '}' +
                    '], "cursor": "cursor123" }';
                res.setBody(jsonResponse);
            } else if (callCount == 2) {
                // Second call returns one contact and no cursor.
                String jsonResponse = '{ "items": [' +
                    '{' +
                    '"member_urn": "urn:li:member:222",' +
                    '"id": "contact2",' +
                    '"name": "Contact Two",' +
                    '"first_name": "First2",' +
                    '"last_name": "Last2",' +
                    '"location": "Location Two",' +
                    '"public_profile_url": "https://linkedin.com/in/contacttwo",' +
                    '"current_positions": [' +
                    '{ "role": "Manager", "company": "Company Two" }' +
                    ']' +
                    '}' +
                    '], "cursor": null }';
                res.setBody(jsonResponse);
            } else {
                // If called further, return an empty response.
                res.setBody('{ "items": [], "cursor": null }');
            }
            return res;
        }
    }
    
    
    @IsTest
    public static void testExecuteApiRequests_Success() {
        
        HttpRequest dummyReq = new HttpRequest();
        dummyReq.setEndpoint('https://dummy.endpoint');
        dummyReq.setMethod('POST');
        dummyReq.setBody('{}');
        List<HttpRequest> requests = new List<HttpRequest>{ dummyReq };
            
            Test.setMock(HttpCalloutMock.class, new TestExecuteApiRequestsMock());
        
        Test.startTest();
        // Call the method (which is @TestVisible) with maxRequests set higher than the number of simulated calls.
        List<Map<String, Object>> results = gridSetupController.executeApiRequests(requests, 10);
        Test.stopTest();
        
        
        System.assertEquals(2, results.size(), 'Expected two contacts from sequential callouts.');
        
        
        Map<String, Object> contact1 = results[0];
        System.assertEquals('contact1', contact1.get('id'));
        System.assertEquals('Contact One', contact1.get('name'));
        
        Map<String, Object> contact2 = results[1];
        System.assertEquals('contact2', contact2.get('id'));
        System.assertEquals('Contact Two', contact2.get('name'));
    }
    
    private class FailureResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Request failed"}');
            return res;
        }
    }
    
    @IsTest
    public static void testExecuteApiRequests_FailureResponse() {
        HttpRequest dummyReq = new HttpRequest();
        dummyReq.setEndpoint('https://dummy.endpoint');
        dummyReq.setMethod('POST');
        dummyReq.setBody('{}');
        List<HttpRequest> requests = new List<HttpRequest>{ dummyReq };
            
            Test.setMock(HttpCalloutMock.class, new FailureResponseMock());
        
        Test.startTest();
        List<Map<String, Object>> results = gridSetupController.executeApiRequests(requests, 10);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Expected no contacts when response status is not 200.');
    }
    
    @isTest
    static void testCreateNextPageRequest() {
        // Setup test data
        String testCursor = 'testCursor123';
        
        Test.startTest();
        
        HttpRequest request = gridSetupController.createNextPageRequest(testCursor);
        
        Test.stopTest();
        
        System.assertNotEquals(request, null, 'Request should not be null');
        System.assertEquals(request.getMethod(), 'POST', 'HTTP method should be POST');
        System.assert(request.getEndpoint().contains(testCursor), 'Endpoint should contain the cursor');
        System.assert(request.getEndpoint().contains('account_id='), 'Endpoint should contain account_id');
        System.assertNotEquals(request.getHeader('X-API-KEY'), null, 'API Key header should be set');
        System.assertEquals(request.getHeader('Accept'), 'application/json', 'Accept header should be application/json');
        System.assertEquals(request.getHeader('Content-Type'), 'application/json', 'Content-Type header should be application/json');
    }
    
    /*  
     * 
    @isTest
    static void testGetLocationCode_ValidResponse() {
        
        List<String> selectedRegions = new List<String>{'United Kingdom','United States'};
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        Map<String, String> locationMap = gridSetupController.getLocationCode(selectedRegions);
        Test.stopTest();
        
        System.assertEquals(2, locationMap.size(), 'Location map should contain 2 entries');
        System.assertEquals('UK123', locationMap.get('United Kingdom'), 'United Kingdom ID should match');
        System.assertEquals('US456', locationMap.get('United States'), 'United States ID should match');
        
        
    }
    
    @isTest
    public static void testGetLocationCode_EmptyRegions() {
        Test.startTest();
        
        List<String> selectedRegions = new List<String>();
        Map<String, String> locationMap = gridSetupController.getLocationCode(selectedRegions);
        
        System.assertEquals(0, locationMap.size(), 'Location map should be empty for no regions');
        
        Test.stopTest();
    }
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"items": [{"title": "United Kingdom", "id": "UK123"},{"title": "United States", "id": "US456"}]}');
            return response;
        }
    }
    
    */
    
    @isTest
    static void testGetFunctionCode_ValidResponse() {
        Test.startTest();
        
        List<String> functionNames = new List<String>{'Engineering', 'Marketing'};
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseFunctions());
        
        Map<String, String> departmentMap = gridSetupController.getFunctionCode(functionNames);
        
        System.assertEquals(2, departmentMap.size(), 'Department map should contain 2 entries');
        System.assertEquals('ENG123', departmentMap.get('Engineering'), 'Engineering ID should match');
        System.assertEquals('MKT456', departmentMap.get('Marketing'), 'Marketing ID should match');
        
        Test.stopTest();
    }
    private class MockHttpResponseFunctions implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"items": [{"title": "Engineering", "id": "ENG123"},{"title": "Marketing", "id": "MKT456"}]}');
            return response;
        }
    }
    
    //TODO:
    @isTest
    public static void testCreateNewContact() {
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;
        
        User testUser = [SELECT Id FROM User LIMIT 1];
        
        Contact newContact = new Contact(
            FirstName = 'Jitu',
            LastName = 'bhai',
            Current_Company_Name__c = testAccount.Name,
            LinkedInURN__c = 'urn:new12345',
            Contact_Outreach_Owner__c = testUser.Id,
            Title = 'Developer',
            Contact_LinkedIn_Id__c = 'LI123',
            Current_Location__c = 'NYC',
            LinkedIn_Profile__c = 'https://linkedin.com/jane-smith'
        );
        
        Test.startTest();
        Map<String, Object> result = gridSetupController.createOrUpdateContacts(new List<Contact>{newContact});
        Test.stopTest();
        
        List<Contact> newContacts = (List<Contact>) result.get('newContacts');
        System.assertEquals(1, newContacts.size(), '1 new contact should be inserted.');
        System.assertEquals('Jane', newContacts[0].FirstName);
    }

    //TODO:
    @isTest
    public static void testUpdateExistingContact() {
        Account testAccount = new Account(Name = 'Test Account 3');
        insert testAccount;
        
        User testUser = [SELECT Id FROM User LIMIT 1];
        
        Contact existing = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Current_Company_Name__c = testAccount.Name,
            LinkedInURN__c = 'urn:update123',
            Title = 'Engineer',
            Contact_Outreach_Owner__c = testUser.Id,
            Contact_LinkedIn_Id__c = 'LI456',
            Current_Location__c = 'London',
            LinkedIn_Profile__c = 'https://linkedin.com/alice'
        );
        insert existing;
        
        // Modify the title
        existing.Title = 'Senior Engineer';
        
        Test.startTest();
        Map<String, Object> result = gridSetupController.createOrUpdateContacts(new List<Contact>{existing});
        Test.stopTest();
        
        List<Contact> updatedContacts = (List<Contact>) result.get('updatedContacts');
        System.assertEquals(1, updatedContacts.size(), '1 contact should be updated.');
        System.assertEquals('Senior Engineer', updatedContacts[0].Title);
    }

    @isTest
    public static void testSkippedContactDueToMissingFields() {
        User testUser = [SELECT Id FROM User LIMIT 1];
        
        Contact skipped = new Contact(
            FirstName = 'NoLastName',
            LastName = '', // Missing last name triggers skip
            Current_Company_Name__c = 'Unknown Company',
            LinkedInURN__c = 'urn:skip123',
            Contact_Outreach_Owner__c = testUser.Id
        );
        
        Test.startTest();
        Map<String, Object> result = gridSetupController.createOrUpdateContacts(new List<Contact>{skipped});
        Test.stopTest();
        
        List<Map<String, Object>> skippedContacts = (List<Map<String, Object>>) result.get('skippedContacts');
        System.assertEquals(1, skippedContacts.size(), '1 contact should be skipped.');
        System.assertEquals('NoLastName', skippedContacts[0].get('FirstName'));
    }

    
    @isTest
    static void testGridContactProcessing_Success() {
        // Fetch test contacts
        List<Contact> testContacts = [SELECT Id FROM Contact];
        
        // Run the method
        Test.startTest();
        Map<String, Object> result = gridSetupController.gridContactProcessing('Test Grid', 
                                                                               new List<String>{testContacts[0].Id, testContacts[1].Id}, UserInfo.getUserId());
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result.get('newGrid'), 'Grid should be created');
        System.assertEquals(1, ((List<Grid_Account__c>) result.get('newGridAccounts')).size(), 'One account should be linked');
        System.assertEquals(2, ((List<Contact>) result.get('insertedGridContacts')).size(), 'Two contacts should be inserted');
    }
    
    @isTest
    static void testGridContactProcessing_EmptyContactList() {
        
        Test.startTest();
        Map<String, Object> result = gridSetupController.gridContactProcessing('Empty Grid', new List<String>{}, UserInfo.getUserId());
        Test.stopTest();
        
        // Assertions
        System.assertEquals(null, result.get('newGrid'), 'Grid should not be created');
        System.assertEquals(0, ((List<Grid_Account__c>) result.get('newGridAccounts')).size(), 'No accounts should be inserted');
        System.assertEquals(0, ((List<Contact>) result.get('insertedGridContacts')).size(), 'No contacts should be inserted');
    }
    
    @isTest
    static void testGridContactProcessing_DuplicateContacts() {
        // Fetch test contacts
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Run method with duplicate contact IDs
        Test.startTest();
        Map<String, Object> result = gridSetupController.gridContactProcessing('Duplicate Grid', 
                                                                               new List<String>{testContact.Id, testContact.Id}, UserInfo.getUserId());
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result.get('newGrid'), 'Grid should be created');
        System.assertEquals(1, ((List<Contact>) result.get('insertedGridContacts')).size(), 'Only one contact should be inserted');
    }
    
    @isTest
    static void testGridContactProcessing_MultipleContactsSameAccount() {
        // Fetch test contacts from the same account
        List<Contact> testContacts = [SELECT Id FROM Contact WHERE Account.Name = 'Test Account 1'];
        
        // Run method
        Test.startTest();
        Map<String, Object> result = gridSetupController.gridContactProcessing('Same Account Grid', 
                                                                               new List<String>{testContacts[0].Id, testContacts[1].Id}, UserInfo.getUserId());
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result.get('newGrid'), 'Grid should be created');
        System.assertEquals(1, ((List<Grid_Account__c>) result.get('newGridAccounts')).size(), 'Only one account should be linked');
        System.assertEquals(2, ((List<Contact>) result.get('insertedGridContacts')).size(), 'Both contacts should be inserted');
    }
    
    @isTest
    static void testSearchCompanies_ValidSearch() {
        Test.startTest();
       User testUser = [SELECT Id FROM User WHERE Email = 'test.user@example.com' LIMIT 1];
        
        List<Account> result = gridSetupController.searchCompanies('Test', String.valueOf(testUser.Id));
        Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Search should return at least one company');
        System.assert(result.size() <= 10, 'Search should return at most 10 results');
        
        for (Account acc : result) {
            System.assert(acc.Name.toLowerCase().contains('test'), 'All returned accounts should match the search term');
        }
    }
    
    
    @isTest
    static void testSearchCompanies_NoMatch() {
        
        User testUser = [SELECT Id FROM User WHERE Email = 'test.user@example.com' LIMIT 1];
        
        Test.startTest();
        List<Account> result = gridSetupController.searchCompanies('NonExistentCompany', testUser.Id);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Search should return zero results for a non-matching term');
    }
    
    @isTest
    static void testSearchCompanies_InvalidOwner() {
        Test.startTest();
        List<Account> result = gridSetupController.searchCompanies('Tech', 'InvalidOwnerId');
        Test.stopTest();
        
        // Validate that no records are returned
        System.assertEquals(0, result.size(), 'Expected no accounts to be returned for an invalid owner ID');
    }
    
    
    @isTest
    static void testSaveValidContact() {
        User testUser = [SELECT Id FROM User LIMIT 1];
        
        Account testAccount = new Account(
            Name = 'Test Company',
            Industry = 'Technology'
        );
        insert testAccount;
        
        Contact contactData = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Phone = '9876543210',
            Current_Company_Name__c = 'Test Company',
            Contact_LinkedIn_Id__c = 'LinkedIn123',
            Current_Location__c = 'New York',
            LinkedIn_Profile__c = 'linkedin.com/in/johndoe',
            LinkedInURN__c = 'urn:12345',
            Title = 'Software Engineer',
            AccountId = testAccount.Id
        );
        
        Test.startTest();
        Contact savedContact = gridSetupController.saveNewContact(contactData, testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, savedContact, 'Saved contact should not be null');
        System.assertEquals('John', savedContact.FirstName, 'First Name should match');
        System.assertEquals('Doe', savedContact.LastName, 'Last Name should match');
        System.assertEquals(testAccount.Id, savedContact.AccountId, 'Account ID should match');
        System.assertEquals('Software Engineer', savedContact.Title, 'Title should match');
    }
    
    @isTest
    static void testSaveContactWithoutLastName() {
        User testUser = [SELECT Id FROM User LIMIT 1];
        
        try {
            Contact invalidContact = new Contact(
                FirstName = 'Jane',
                Current_Company_Name__c = '',
                LastName = ''
            );
            Test.startTest();
            gridSetupController.saveNewContact(invalidContact, testUser.Id);
            Test.stopTest();
            System.assert(false, 'Expected an exception for missing last name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Last Name and Account Name are required.');
        }
    }
        
    
    @isTest
    static void testSendBulkLinkedInRequests_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LinkedInInviteMock(true));
        
        List<Contact> eligibleContacts = [SELECT Id FROM Contact WHERE LinkedIn_Connection_Status__c = 'Not Connected' AND Contact_LinkedIn_Id__c != NULL];
        
        System.debug('eligibleContacts2'+eligibleContacts);
        List<String> contactIds = new List<String>();
        for (Contact con : eligibleContacts) {
            contactIds.add(con.Id);
        }
        
        Map<String, List<Contact>> result = gridSetupController.sendBulkLinkedInRequests(contactIds);
        
        Test.stopTest();
        
        System.debug('invitationSent: '+result.get('invitationSent'));
        System.debug('pendingContacts: '+result.get('pendingContacts'));
        
        System.assert(result.containsKey('invitationSent'), 'Result map should contain "invitationSent" key.');
        System.assert(result.containsKey('pendingContacts'), 'Result map should contain "pendingContacts" key.');
        
        System.assertEquals(2, result.get('invitationSent').size(), 'Two contacts should have received invitations.');
        
        System.assertEquals(0, result.get('pendingContacts').size(), 'No pending contacts should remain.');
        
        List<Contact> updatedContacts = [SELECT LinkedIn_Connection_Status__c FROM Contact WHERE Id IN :contactIds];
        for (Contact con : updatedContacts) {
            System.assertEquals('Invitation Sent', con.LinkedIn_Connection_Status__c, 'LinkedIn status should be "Invitation Sent"');
        }
    }
    
    @isTest
    static void testSendBulkLinkedInRequests_NoContacts() {
        Test.startTest();
        Map<String, List<Contact>> result = gridSetupController.sendBulkLinkedInRequests(new List<String>());
        Test.stopTest();
        
        System.assert(result.get('invitationSent').isEmpty(), 'No invitations should be sent.');
        System.assert(result.get('pendingContacts').isEmpty(), 'No pending contacts should exist.');
    }
    @isTest
    static void testSendBulkLinkedInRequests_AlreadyConnected() {
        List<Contact> connectedContacts = [SELECT Id FROM Contact WHERE LinkedIn_Connection_Status__c = 'Connected'];
        
        Test.startTest();
        Map<String, List<Contact>> result = gridSetupController.sendBulkLinkedInRequests(new List<String>{connectedContacts[0].Id});
        Test.stopTest();
        
        System.assert(result.get('invitationSent').isEmpty(), 'Contacts already connected should not receive invitations.');
    }
    @isTest
    static void testSendBulkLinkedInRequests_NoLinkedInId() {
        List<Contact> contactsWithoutLinkedInId = [SELECT Id FROM Contact WHERE Contact_LinkedIn_Id__c = NULL];
        
        Test.startTest();
        Map<String, List<Contact>> result = gridSetupController.sendBulkLinkedInRequests(new List<String>{contactsWithoutLinkedInId[0].Id});
        Test.stopTest();
        
        System.assert(result.get('invitationSent').isEmpty(), 'Contacts without LinkedIn ID should not be processed.');
    }
    @isTest
    static void testSendBulkLinkedInRequests_DMLExceptionHandling() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new LinkedInInviteMock(false));
        
        List<Contact> eligibleContacts = [SELECT Id FROM Contact WHERE LinkedIn_Connection_Status__c = 'Not Connected' AND Contact_LinkedIn_Id__c != NULL];
        
        List<String> contactIds = new List<String>();
        for (Contact con : eligibleContacts) {
            contactIds.add(con.Id);
        }
        Map<String, List<Contact>> result = gridSetupController.sendBulkLinkedInRequests(contactIds);
        Test.stopTest();
        
        System.assert(result.get('invitationSent').isEmpty(), 'No invitations should be sent if API fails.');
    }
    @isTest
    static void testSendInvitationSuccess() {
        Account acc=[SELECT Id,Name FROM Account WHERE Name='Test Account 2' LIMIT 1];
        
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Contact_LinkedIn_Id__c = 'LinkedIn123',
            LinkedIn_Connection_Status__c='Not Connected',
            AccountId=acc.Id
        );
        insert testContact;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new LinkedInInviteMock(true));
        Test.stopTest();
        Boolean result = gridSetupController.sendInvitationToLinkedIn(testContact, acc.Id);
        System.debug('Result:'+result);
        
       
        System.assert(result, 'Expected invitation to be sent successfully');
        
    }
    
    @isTest
    static void testSendInvitationFailure() {
        
        Test.setMock(HttpCalloutMock.class, new LinkedInInviteMock(false));
        
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'janesmith@example.com',
            Contact_LinkedIn_Id__c = 'LinkedIn45600'
        );
        insert testContact;
        
        Boolean result = gridSetupController.sendInvitationToLinkedIn(testContact, 'testAccountId');
        
        
        System.assert(!result, 'Expected invitation to fail');
        
        Contact updatedContact = [SELECT LinkedIn_Connection_Status__c, LinkedIn_Invitation_Id__c 
                                  FROM Contact WHERE Id = :testContact.Id];
        
        System.assertNotEquals('Invitation Sent', updatedContact.LinkedIn_Connection_Status__c, 'Status should not be "Invitation Sent"');
        System.assertEquals(null, updatedContact.LinkedIn_Invitation_Id__c, 'Invitation ID should be null');
    }
    
    private class LinkedInInviteMock implements HttpCalloutMock {
        private Boolean isSuccess;
        
        public LinkedInInviteMock(Boolean success) {
            this.isSuccess = success;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (isSuccess) {
                res.setStatusCode(201);
                res.setBody('{"invitation_id": "12345ABC"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error": "Invalid request"}');
            }
            return res;
        }
    }

        @isTest
        static void testSearchLocation_Success() {
            
            Test.startTest();
            
            String mockResponse = '{"items": [{"id": "123", "title": "New York"},{"id": "456", "title": "New Zealand"}]}';
                
            HttpResponse mockHttpResponse = new HttpResponse();
            mockHttpResponse.setBody(mockResponse);
            mockHttpResponse.setStatusCode(200);
            
            HttpCalloutMock mock = new MockHttpResponseGenerator(mockHttpResponse);
            Test.setMock(HttpCalloutMock.class, mock);
            
            Map<String, String> result = gridSetupController.searchLocation('New');
            
            Test.stopTest();
        
            System.assertEquals(2, result.size(), 'Expected 2 locations in the map');
            System.assertEquals('New York', result.get('123'));
            System.assertEquals('New Zealand', result.get('456'));
    }

    @isTest
    static void testSearchLocation_NoLinkedInAccount() {
        Test.startTest();
        HttpResponse mockHttpResponse = new HttpResponse();
        mockHttpResponse.setStatusCode(400);
        mockHttpResponse.setBody('{"error": "No LinkedIn account found"}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockHttpResponse));

        
        Map<String, String> result = gridSetupController.searchLocation('Test');
        
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Expected empty result when no LinkedIn Account ID');
    }

    @isTest
    static void testSearchLocation_ApiFailure() {
        Test.startTest();
        
        // Mock HTTP failure response
        HttpResponse mockHttpResponse = new HttpResponse();
        mockHttpResponse.setStatusCode(500);
        
        HttpCalloutMock mock = new MockHttpResponseGenerator(mockHttpResponse);
        Test.setMock(HttpCalloutMock.class, mock);

        Map<String, String> result = gridSetupController.searchLocation('Test');
        
        Test.stopTest();
        

        System.assertEquals(0, result.size(), 'Expected empty result on API failure');
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
    private HttpResponse response;

    public MockHttpResponseGenerator(HttpResponse response) {
        this.response = response;
    }

    public HttpResponse respond(HttpRequest req) {
        if (response == null) {
            HttpResponse errorResponse = new HttpResponse();
            errorResponse.setStatusCode(400);
            errorResponse.setBody('{"error": "Mock response is null"}');
            return errorResponse;
        }
        return response;
    	}
	}
    
	@isTest
    static void testSearchIndustrySuccess() {
        Test.setMock(HttpCalloutMock.class, new SearchIndustryMock());

        Test.startTest();
        Map<String, String> result = gridSetupController.searchIndustry('tech');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 industries');
        System.assertEquals('Information Technology', result.get('ind123'));
        System.assertEquals('Finance', result.get('ind456'));
    }
    
    private class SearchIndustryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
            
            String mockBody = '{ "items": [ ' +
                '{"id": "ind123", "title": "Information Technology"},' +
                '{"id": "ind456", "title": "Finance"} ] }';
            
            response.setBody(mockBody);
            return response;
        }
	}
    @isTest
    static void testSearchAccountsMethod() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new SearchAccountsMock());

        // Construct test input filterData
        Map<String, Object> filters = new Map<String, Object>{
            'industries' => new List<String>{'Tech', 'Finance'},
            'regions' => new List<String>{'USA'},
            'selectedRevenue' => new Map<String, Object>{'min' => 1000000, 'max' => 10000000},
            'selectedHeadCount' => new Map<String, Object>{'min' => 50, 'max' => 500}
        };

        String filterData = JSON.serialize(filters);

        Test.startTest();
        List<Map<String, Object>> result = gridSetupController.searchAccounts(filterData);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Expected 2 companies in result');
        System.assertEquals('Acme Corp', result[0].get('name'));
        System.assertEquals('Globex Inc', result[1].get('name'));
    }

    private class SearchAccountsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
            
            String mockBody = '{' +
                '"items": [' +
                '{"id": "1", "name": "Acme Corp", "profile_url": "https://example.com", "industry": "Tech", "headcount": 150},' +
                '{"id": "2", "name": "Globex Inc", "profile_url": "https://example2.com", "industry": "Finance", "headcount": 250}' +
                '],' +
                '"cursor": null' +
                '}';
            
            response.setBody(mockBody);
            return response;
        }
    }

    @isTest
    static void testCreateAccounts_InsertAndUpdate() {
        // Insert a custom industry for reference
        Industry__c existingIndustry = new Industry__c(Name__c = 'Tech Startups');
        insert existingIndustry;

        // Insert an existing account to simulate update
        Account existingAcc = new Account(
            Name = 'Old Corp',
            LinkedIn_Id__c = 'old123',
            LinkedIn_Profile__c = 'https://linkedin.com/old',
            NumberOfEmployees = 100,
            Industry = 'Banking'
        );
        insert existingAcc;

        // Create wrapper 1 (New Account)
        gridSetupController.CreateAccountWrapper wrapper1 = new gridSetupController.CreateAccountWrapper();
        wrapper1.id = 'new123';
        wrapper1.name = 'New Corp';
        wrapper1.profile_url = 'https://linkedin.com/new';
        wrapper1.headcount = '250';
        wrapper1.industry = 'Healthcare';

        // Create wrapper 2 (Update existing account)
        gridSetupController.CreateAccountWrapper wrapper2 = new gridSetupController.CreateAccountWrapper();
        wrapper2.id = 'old123';
        wrapper2.name = 'Old Corp Updated';
        wrapper2.profile_url = 'https://linkedin.com/old';
        wrapper2.headcount = '500';
        wrapper2.industry = 'Tech Startups';

        List<gridSetupController.CreateAccountWrapper> wrappers = new List<gridSetupController.CreateAccountWrapper>{wrapper1, wrapper2};

        Test.startTest();
        List<Account> result = gridSetupController.createAccount(wrappers);
        Test.stopTest();

        System.assertEquals(2, result.size());

        // Validate new account
        Account newAcc = [SELECT Name, LinkedIn_Id__c, NumberOfEmployees, Industry__c FROM Account WHERE LinkedIn_Id__c = 'new123' LIMIT 1];
        System.assertEquals('New Corp', newAcc.Name);
        System.assertEquals(250, newAcc.NumberOfEmployees);
        System.assertNotEquals(null, newAcc.Industry__c);

        // Validate updated account
        Account updatedAcc = [SELECT Name, LinkedIn_Id__c, NumberOfEmployees, Industry__c FROM Account WHERE LinkedIn_Id__c = 'old123' LIMIT 1];
        System.assertEquals('Old Corp Updated', updatedAcc.Name);
        System.assertEquals(500, updatedAcc.NumberOfEmployees);
        System.assertEquals(existingIndustry.Id, updatedAcc.Industry__c);
    }

    @isTest
    static void testCreateAccount_WithInvalidHeadcount() {
        gridSetupController.CreateAccountWrapper wrapper = new gridSetupController.CreateAccountWrapper();
        wrapper.id = 'invalid123';
        wrapper.name = 'Bad Headcount Inc';
        wrapper.profile_url = 'https://linkedin.com/bad';
        wrapper.headcount = '12abc'; // invalid
        wrapper.industry = 'Education';

        List<gridSetupController.CreateAccountWrapper> wrappers = new List<gridSetupController.CreateAccountWrapper>{wrapper};

        Test.startTest();
        List<Account> result = gridSetupController.createAccount(wrappers);
        Test.stopTest();

        Account acc = [SELECT Name, LinkedIn_Id__c, NumberOfEmployees FROM Account WHERE LinkedIn_Id__c = 'invalid123' LIMIT 1];
        System.assertEquals('Bad Headcount Inc', acc.Name);
        System.assertEquals(null, acc.NumberOfEmployees); // invalid headcount should not be parsed
    }
    
    @isTest
    static void testSearchSalesforceIndustry() {
        // Insert custom industries
        List<Industry__c> industries = new List<Industry__c>{
            new Industry__c(Name__c = 'Tech Innovations'),
            new Industry__c(Name__c = 'Educational Services'),
            new Industry__c(Name__c = 'Health & Wellness')
        };
        insert industries;

        Test.startTest();
        List<String> results = gridSetupController.searchSalesforceIndustry('tech');
        Test.stopTest();

        System.debug('Matched Industries: ' + results);

        Boolean found = false;
        for (String s : results) {
            if (s.toLowerCase().contains('tech')) {
                found = true;
                break;
            }
        }
        System.assert(found, 'At least one industry should contain "tech"');
    }

    @isTest
    static void testSearchSalesforceIndustry_NoMatch() {
        Test.startTest();
        List<String> results = gridSetupController.searchSalesforceIndustry('zzzznotfound');
        Test.stopTest();
        System.assertEquals(0, results.size(), 'No matches should be returned');
    }

    @isTest
    static void testToStringList() {
        List<Object> inputList = new List<Object>{1, 'two', 3.0, true};
        List<String> expected = new List<String>{'1', 'two', '3.0', 'true'};

        List<String> output = gridSetupController.toStringList(inputList);
        System.assertEquals(expected, output, 'String list should match expected values');
    }

    @isTest
    static void testToStringList_EmptyOrInvalid() {
        List<String> result = gridSetupController.toStringList(null);
        System.assertEquals(0, result.size());

        Object notAList = 'just a string';
        List<String> result2 = gridSetupController.toStringList(notAList);
        System.assertEquals(0, result2.size());
    }
}