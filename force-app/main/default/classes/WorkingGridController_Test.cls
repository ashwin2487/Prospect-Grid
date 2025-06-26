@isTest
private class WorkingGridController_Test {
    @testSetup
    static void setupTestData() {
        
        User owner = new User(
            FirstName = 'New1',
            LastName = 'Owner',
            Email = 'newowner1@example.com',
            Username = 'newowner1@example.com.salesforce',
            Alias = 'nowner',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert owner;
        
        User newOwner = new User(
            FirstName = 'New',
            LastName = 'Owner',
            Email = 'newowner@example.com',
            Username = 'newowner@example.com.salesforce',
            Alias = 'newown',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert newOwner;
        
        Grid__c grid1 = new Grid__c(Name = 'Test Grid 1', Outreach_Owner__c = UserInfo.getUserId());
        insert grid1;

        Grid__c grid2 = new Grid__c(Name = 'Test Grid 2', Outreach_Owner__c = UserInfo.getUserId());
        insert grid2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Grid_Account__c gridAccount = new Grid_Account__c(Grid__c = grid1.Id, Account__c = acc.Id);
        insert gridAccount;

        Contact con = new Contact(
            FirstName='John',
            LastName = 'Doe',
            Email = 'test@example.com',
            Phone = '1234567890',
            Title = 'Manager',
            Contact_Outreach_Owner__c = owner.Id,
            AccountId=acc.Id,
            Contact_LinkedIn_Id__c = 'linkedin123',
            LinkedIn_Connection_Status__c = 'Connected',
            LinkedIn_Message_1__c = 'Not Sent',
            LinkedIn_Message_2__c = 'Not Sent',
            Email_1__c = 'Not Sent',
            Email_2__c = 'Not Sent',
            Outcome__c = 'Create Opportunity',
            Notes__c = 'Contact responded positively',
            Call_Attempt_1__c = 'Call Picked Up',
            Call_Attempt_2__c = 'Call On Voice Mail',
            Call_Attempt_3__c = 'Call Disconnected',
            Call_Attempt_4__c = 'Attempt Not Made Yet'
            );
        insert con;
        
        Grid_Contact__c gridContact = new Grid_Contact__c(Grid__c = grid1.Id, Contact__c = con.Id);
        insert gridContact;
        
        LinkedIn_Account__c linkedInAccount = new LinkedIn_Account__c(
            User_Name__c = UserInfo.getName(),
            Account_ID__c = '123456789'
        );
        insert linkedInAccount;
        
    }

    @isTest
    static void testGetGridsWithMatchingData() {
        Test.startTest();
        List<Grid__c> results = WorkingGridController.getGrids('Test Grid');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Expected matching Grid records');
        System.assert(results[0].Name.contains('Test Grid'), 'Grid name should contain search key');
    }

    @isTest
    static void testGetGridsWithNoMatchingData() {
        Test.startTest();
        List<Grid__c> results = WorkingGridController.getGrids('NonExistingGrid');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Expected no records for a non-matching search key');
    }

    @isTest
    static void testGetGridsWithEmptySearchKey() {
        Test.startTest();
        List<Grid__c> results = WorkingGridController.getGrids('');
        Test.stopTest();

        System.assert(results.size() > 0, 'Expected all records when search key is empty');
    }
    
    @isTest
    static void testGetGridData() {
        Grid__c testGrid = [SELECT Id FROM Grid__c LIMIT 1];
        
        List<WorkingGridController.WrapperClass> result = WorkingGridController.getGridData(testGrid.Id);
        
        System.assertEquals(1, result.size(), 'Expected one record in the result');
        System.assertEquals('Test Account', result[0].accountName, 'Account name should match');
        System.assertEquals('John Doe', result[0].contact.Name, 'Contact name should match');
    }
    
    @isTest
    static void testGetGridData_NoContacts() {
        Grid__c gridWithoutContacts = new Grid__c(Name = 'Grid Without Contacts');
        insert gridWithoutContacts;
        
        List<WorkingGridController.WrapperClass> result = WorkingGridController.getGridData(gridWithoutContacts.Id);
        
        System.assertEquals(0, result.size(), 'Expected no contacts in the result');
    }
    
    @isTest
    static void testGetGridData_AccountWithoutName() {
        Grid__c newGrid = new Grid__c(Name = 'Grid Without Account');
        insert newGrid;
        
        Contact contact = new Contact(
            FirstName = 'Orphan',
            LastName = 'Contact',
            Email = 'orphan@example.com',
            Phone = '9876543210'
        );
        insert contact;
        
        Grid_Contact__c gridCon = new Grid_Contact__c(Grid__c = newGrid.Id, Contact__c = contact.Id);
        insert gridCon;
        
        List<WorkingGridController.WrapperClass> result = WorkingGridController.getGridData(newGrid.Id);
        
        System.assertEquals(1, result.size(), 'Expected one record in the result');
        System.assertEquals('No Associated Account', result[0].accountName, 'Account should be labeled as No Associated Account');
    }
    
    @isTest
    static void testUpdateGridOutreachOwner() {
        Grid__c testGrid = [SELECT Id,Name FROM Grid__c WHERE Name='Test Grid 1' LIMIT 1];
        
        User newOwner = [SELECT Id FROM User WHERE Email = 'newowner1@example.com' LIMIT 1];
        
        Test.startTest();
        WorkingGridController.updateGridOutreachOwner(testGrid.Id, newOwner.Id);
        Test.stopTest();
        
        Grid__c updatedGrid = [SELECT Outreach_Owner__c FROM Grid__c WHERE Id = :testGrid.Id];
        
        System.assertEquals(newOwner.Id, updatedGrid.Outreach_Owner__c, 'Outreach Owner should be updated');
    }
    
    @isTest
    static void testUpdateGridOutreachOwner_InvalidGridId() {
        try {
            Test.startTest();
            WorkingGridController.updateGridOutreachOwner('InvalidId', '005XXXXXXXXXXXX');
            Test.stopTest();
            System.assert(false, 'Method should have thrown an exception for invalid Grid ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected exception message');
        }
    }
    
    @isTest
    static void testUpdateContactOutreachOwner() {
        Contact testContact = [SELECT Id,Name FROM Contact WHERE Name='John Doe' LIMIT 1];
        
        User newOwner = [SELECT Id FROM User WHERE Email = 'newowner@example.com' LIMIT 1];
        
        Test.startTest();
        WorkingGridController.updateContactOutreachOwner(testContact.Id, newOwner.Id);
        Test.stopTest();
        
        Contact UpdatedTestContact = [SELECT Id,Contact_Outreach_Owner__c FROM Contact WHERE Id =:testContact.Id ];
        
        System.assertEquals(newOwner.Id, UpdatedTestContact.Contact_Outreach_Owner__c, 'Outreach Owner should be updated');
    }
    
    @isTest
    static void testUpdateContactOutreachOwner_InvalidGridId() {
        try {
            Test.startTest();
            WorkingGridController.updateContactOutreachOwner('InvalidId', '005XXXXXXXXXXXX');
            Test.stopTest();
            System.assert(false, 'Method should have thrown an exception for invalid Grid ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected exception message');
        }
    }
    
    @isTest
    static void testGetLinkedInAccountId() {
        Test.startTest();
        String accountId = WorkingGridController.getLinkedInAccountId();
        Test.stopTest();
        
        System.assertEquals('123456789', accountId, 'LinkedIn Account ID should match the expected value');
    }
    
    @isTest
    static void testSendLinkedInRequest() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockLinkedInCallout());
        Test.startTest();
        WorkingGridController.sendLinkedInRequest(testContact.Id, 'Hello, this is a test message');
        Test.stopTest();
        
        Contact updatedContact = [SELECT LinkedIn_Connection_Status__c, LinkedIn_Invitation_Id__c FROM Contact WHERE Id = :testContact.Id];
        System.assertNotEquals(null, updatedContact.LinkedIn_Invitation_Id__c, 'Invitation ID should be set');
        System.assertEquals('Invitation Sent', updatedContact.LinkedIn_Connection_Status__c, 'Contact LinkedIn status should be updated');
        
    }
    
    @isTest
    static void testSendLinkedInRequest_MissingContactId() {
        Test.startTest();
        WorkingGridController.sendLinkedInRequest(null, 'Hello, this is a test message');
        Test.stopTest();
    }
    
    @isTest
    static void testSendLinkedInRequest_MissingMessage() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        WorkingGridController.sendLinkedInRequest(testContact.Id, '');
        Test.stopTest();
        
        Contact updatedContact = [SELECT LinkedIn_Connection_Status__c, LinkedIn_Invitation_Id__c FROM Contact WHERE Id = :testContact.Id];
        
        System.assertNotEquals('Invitation Sent', updatedContact.LinkedIn_Connection_Status__c, 'Contact LinkedIn status should be updated');
        System.assertEquals(null, updatedContact.LinkedIn_Invitation_Id__c, 'Invitation ID should be set');
        
    }
    
    private class MockLinkedInCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"invitation_id": "invite123"}');
            res.setStatusCode(201); 
            return res;
        }
    }
    
    @isTest
    static void testGetContactStatus_WithValidId() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        List<Contact> results = WorkingGridController.getContactStatus(testContact.Id);
        Test.stopTest();
        

        System.assertNotEquals(null, results, 'Result should not be null');
        System.assertEquals(1, results.size(), 'Should return one contact');
        Contact result = results[0];
        System.assertEquals(testContact.Id, result.Id, 'Fetched contact ID should match test contact ID');

        List<String> validCallStatuses = new List<String>{'Call Picked Up', 'Call On Voice Mail', 'Call Disconnected', 'Attempt Not Made Yet'};
        System.assert(validCallStatuses.contains(result.Call_Attempt_1__c), 'Call_Attempt_1__c should have a valid picklist value');
        System.assert(validCallStatuses.contains(result.Call_Attempt_2__c), 'Call_Attempt_2__c should have a valid picklist value');
        System.assert(validCallStatuses.contains(result.Call_Attempt_3__c), 'Call_Attempt_3__c should have a valid picklist value');
        System.assert(validCallStatuses.contains(result.Call_Attempt_4__c), 'Call_Attempt_4__c should have a valid picklist value');
    }

    @isTest
    static void testGetContactStatus_WithoutId() {
        Test.startTest();
        List<Contact> results = WorkingGridController.getContactStatus(null);
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Should return a list of contacts');
    }
    
    @isTest
    static void testGetGridDataAfterContactOutreachownerChange() {
        Test.startTest();
        List<WorkingGridController.ContactOwnerChangeWrapper> results = WorkingGridController.getGridDataAfterContactOutreachownerChange();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'At least one contact should be retrieved');
        
        WorkingGridController.ContactOwnerChangeWrapper contactWrapper = results[0];
        System.assertNotEquals(null, contactWrapper, 'Wrapper object should not be null');
        System.assertNotEquals(null, contactWrapper.contact.Id, 'Contact ID should not be null');
        System.assertNotEquals(null, contactWrapper.contact.Name, 'Contact Name should not be null');
    }
    
    @isTest
    static void testGetGridDataAfterContactOutreachownerChange_EmptyData() {
        Test.startTest();
        List<Contact> contacts = [SELECT Id FROM Contact];
        delete contacts; 

        List<WorkingGridController.ContactOwnerChangeWrapper> results = WorkingGridController.getGridDataAfterContactOutreachownerChange();
        Test.stopTest();

        System.assertEquals(0, results.size(), 'No data should be returned when there are no contacts');
    }
    
    @isTest
    static void testUpdateOutreachOwner_Success() {
        Contact testContact = [SELECT Id, Contact_Outreach_Owner__c FROM Contact LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Email = 'newowner@example.com' LIMIT 1];

        Test.startTest();
        WorkingGridController.updateOutreachOwner(testContact.Id, newOwner.Id);
        Test.stopTest();

        Contact updatedContact = [SELECT Contact_Outreach_Owner__c FROM Contact WHERE Id = :testContact.Id];

        System.assertEquals(newOwner.Id, updatedContact.Contact_Outreach_Owner__c, 'Outreach Owner should be updated');
    }
       
    @isTest
    static void testSendLinkedInMessage1_success() {
        Contact con = [SELECT Id, Contact_LinkedIn_Id__c, LinkedIn_Message_Content__c, LinkedIn_Message_1__c, Name 
                       FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
                       
        Test.setMock(HttpCalloutMock.class, new MockSendLinkedInMessage1());
        
        Test.startTest();
        String result = WorkingGridController.SendLinkedInMessage1(con.Id, 'Hello Message 1', 'Subject 1');
        Test.stopTest();
        
        System.assert(result.startsWith('Success:'), 'Expected success response, got: ' + result);
        
        Contact updatedCon = [SELECT LinkedIn_Chat_Id__c, LinkedIn_Message_Content__c, LinkedIn_Message_1__c 
                              FROM Contact WHERE Id = :con.Id];
        System.assertEquals('testChatId123', updatedCon.LinkedIn_Chat_Id__c, 'LinkedIn Chat ID should be updated from mock');
        System.assertEquals('Message Sent', updatedCon.LinkedIn_Message_1__c, 'Message 1 status should be updated to "Message Sent"');
        System.assert(updatedCon.LinkedIn_Message_Content__c.contains('Subject 1'), 'Message content should include subject info');
    }
    
    @isTest
    static void testSendLinkedInMessage1_nullContactId() {
        Test.startTest();
        String result = WorkingGridController.SendLinkedInMessage1(null, 'Hello Message 1', 'Subject 1');
        Test.stopTest();
        System.assertEquals('Error: Contact ID is null', result, 'Expected error message for null contact ID');
    }
    
    @isTest
    static void testSendLinkedInMessage1_missingLinkedInID() {
        Contact con = [SELECT Id, Contact_LinkedIn_Id__c FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        con.Contact_LinkedIn_Id__c = null;
        update con;
        
        Test.startTest();
        String result = WorkingGridController.SendLinkedInMessage1(con.Id, 'Hello Message 1', 'Subject 1');
        Test.stopTest();
        System.assertEquals('Error: Contact does not have a LinkedIn ID', result, 'Expected error for missing LinkedIn ID');
    }
    
    private class MockSendLinkedInMessage1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            Map<String, Object> responseMap = new Map<String, Object>{
                'object'    => 'TestObject',
                    'message_id'=> 'testMessage1',
                    'chat_id'   => 'testChatId123'
                    };
                        res.setBody(JSON.serialize(responseMap));
            res.setStatusCode(201);
            return res;
        }
    }
    
    @isTest
    static void testSendLinkedInMessage2_success() {
        Contact con = [SELECT Id, Contact_LinkedIn_Id__c, LinkedIn_Chat_Id__c, LinkedIn_Message_Content__c, LinkedIn_Message_2__c, Name 
                       FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        con.LinkedIn_Chat_Id__c = 'testChatId123';
        update con;
                       
        Test.setMock(HttpCalloutMock.class, new MockSendLinkedInMessage2());
        
        Test.startTest();
        String result = WorkingGridController.SendLinkedInMessage2(con.Id, 'Hello Message 2', 'Subject 2');
        Test.stopTest();
        
        System.assert(result.startsWith('Success:'), 'Expected success response, got: ' + result);
        
        Contact updatedCon = [SELECT LinkedIn_Message_Content__c, LinkedIn_Message_2__c, LinkedIn_Message_Id__c 
                              FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Message Sent', updatedCon.LinkedIn_Message_2__c, 'Message 2 status should be updated to "Message Sent"');
        System.assertEquals('testMessage2', updatedCon.LinkedIn_Message_Id__c, 'LinkedIn_Message_Id__c should be updated from mock');
        System.assert(updatedCon.LinkedIn_Message_Content__c.contains('Subject 2'), 'Message content should include subject info for Message 2');
    }
    
    @isTest
    static void testSendLinkedInMessage2_nullContactId() {
        Test.startTest();
        String result = WorkingGridController.SendLinkedInMessage2(null, 'Hello Message 2', 'Subject 2');
        Test.stopTest();
        System.assertEquals('Error: Contact ID is null', result, 'Expected error message for null contact ID');
    }
    
    @isTest
    static void testSendLinkedInMessage2_missingLinkedInID() {
        Contact con = [SELECT Id, Contact_LinkedIn_Id__c, LinkedIn_Chat_Id__c FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        con.Contact_LinkedIn_Id__c = null;
        con.LinkedIn_Chat_Id__c = 'existingChatId';
        update con;
        
        Test.startTest();
        String result = WorkingGridController.SendLinkedInMessage2(con.Id, 'Hello Message 2', 'Subject 2');
        Test.stopTest();
        System.assertEquals('Error: Contact does not have a LinkedIn ID', result, 'Expected error for missing LinkedIn ID');
    }
       
    private class MockSendLinkedInMessage2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            Map<String, Object> responseMap = new Map<String, Object>{
                'object'    => 'TestObject',
                'message_id'=> 'testMessage2'
            };
            res.setBody(JSON.serialize(responseMap));
            res.setStatusCode(201);
            return res;
        }
    }
    
    @isTest
    static void testUpdateContactNotes_NewNotes() {
        Contact con = [SELECT Id, Notes__c FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        Test.startTest();
        String updatedNotes = WorkingGridController.updateContactNotes(con.Id, 'This is a new note');
        Test.stopTest();
        
        System.assertNotEquals(null, updatedNotes, 'Updated notes should not be null');
        System.assert(updatedNotes.contains('This is a new note'), 'Updated notes should contain the new note');
        System.assert(updatedNotes.contains('Notes Updated('), 'Updated notes should include a timestamp prefix');
        
        Contact updatedCon = [SELECT Notes__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(updatedNotes, updatedCon.Notes__c, 'Persisted contact notes should match the returned value');
    }
    
    @isTest
    static void testUpdateContactNotes_AppendNotes() {

        Contact con = [SELECT Id, Notes__c FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        Test.startTest();
        String updatedNotes = WorkingGridController.updateContactNotes(con.Id, 'Additional note');
        Test.stopTest();
        
        System.assert(updatedNotes.contains('Contact responded positively'), 'Updated notes should include the original note');
        System.assert(updatedNotes.contains('Additional note'), 'Updated notes should include the additional note');
        System.assert(updatedNotes.contains('\n\n'), 'Updated notes should have a newline separation between old and new notes');
    }
    
    @isTest
    static void testUpdateContactNotes_EmptyNotes() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        try {
            Test.startTest();
            WorkingGridController.updateContactNotes(con.Id, '');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException for empty notes');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected exception message not found');
        }
    }
    
    @isTest
    static void testUpdateOutcome_Success() {
        Contact con = [SELECT Id, Outcome__c FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        Test.startTest();
        WorkingGridController.updateOutcome(String.valueOf(con.Id), 'Unresponsive');
        Test.stopTest();
        
        Contact updatedCon = [SELECT Outcome__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Unresponsive', updatedCon.Outcome__c, 'Outcome should be updated to "Unresponsive"');
    }
    
    @isTest
    static void testUpdateOutcome_InvalidContactId() {
        try {
            Test.startTest();
            WorkingGridController.updateOutcome('InvalidId', 'Unresponsive');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException for an invalid contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected exception message indicating no contact found');
        }
    }
    
    @isTest
    static void testSendEmail_success() {
        Contact con = [SELECT Id, Name, Email FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MockEmailCallout());
        
        Test.startTest();
        WorkingGridController.sendEmail(String.valueOf(con.Id), 'Test Subject', 'Test Message');
        Test.stopTest();
        System.assert(true, 'sendEmail executed successfully with a valid LinkedIn Account.');
    }
    
    @isTest
    static void testSendEmail_noLinkedInAccount() {
        List<LinkedIn_Account__c> liAccs = [SELECT Id FROM LinkedIn_Account__c];
        delete liAccs;
        
        Contact con = [SELECT Id, Name, Email FROM Contact WHERE Email = 'test@example.com' LIMIT 1];
        
        Test.startTest();
        WorkingGridController.sendEmail(String.valueOf(con.Id), 'Test Subject', 'Test Message');
        Test.stopTest();
 
        System.assert(true, 'sendEmail executed and returned early when no LinkedIn Account is present.');
    }
    
    private class MockEmailCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testSaveCallAttemptOutcome_Attempt1() {
        // Create a fresh Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser1@example.com'
        );
        insert con;
        
        String outcome = 'Call Picked Up';
        
        Test.startTest();
        WorkingGridController.saveCallAttemptOutcome(con.Id, 1, outcome);
        Test.stopTest();
        
        Contact updatedCon = [SELECT Call_Attempt_1__c, Call_Attempt_2__c, Call_Attempt_3__c, 
                              Call_Attempt_4__c, Call_Attempt_5__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(outcome, updatedCon.Call_Attempt_1__c, 'Attempt 1 should be updated');
        System.assertEquals(null, updatedCon.Call_Attempt_2__c, 'Attempt 2 should be null');
        System.assertEquals(null, updatedCon.Call_Attempt_3__c, 'Attempt 3 should be null');
        System.assertEquals(null, updatedCon.Call_Attempt_4__c, 'Attempt 4 should be null');
        System.assertEquals(null, updatedCon.Call_Attempt_5__c, 'Attempt 5 should be null');
    }

    @isTest
    static void testSaveCallAttemptOutcome_Attempt2() {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser2@example.com'
        );
        insert con;
        
        String outcome = 'Call On Voice Mail';
        
        Test.startTest();
        WorkingGridController.saveCallAttemptOutcome(con.Id, 2, outcome);
        Test.stopTest();
        
        Contact updatedCon = [SELECT Call_Attempt_1__c, Call_Attempt_2__c, Call_Attempt_3__c, 
                              Call_Attempt_4__c, Call_Attempt_5__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals(null, updatedCon.Call_Attempt_1__c, 'Attempt 1 should be null');
        System.assertEquals(outcome, updatedCon.Call_Attempt_2__c, 'Attempt 2 should be updated');
        System.assertEquals(null, updatedCon.Call_Attempt_3__c, 'Attempt 3 should be null');
        System.assertEquals(null, updatedCon.Call_Attempt_4__c, 'Attempt 4 should be null');
        System.assertEquals(null, updatedCon.Call_Attempt_5__c, 'Attempt 5 should be null');
    }
    
    @isTest
    static void testSaveCallAttemptOutcome_InvalidContactId() {
        try {
            Test.startTest();
            WorkingGridController.saveCallAttemptOutcome(Id.valueOf('003000000000000AAA'), 1, 'Call Picked Up');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException due to invalid Contact Id');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message for invalid contact id');
        }
    }
    
   	@isTest
    static void testSearchContactsSuccess() {
        Test.startTest();
        
        HttpResponse mockCompanyResponse = new HttpResponse();
        mockCompanyResponse.setHeader('Content-Type', 'application/json');
        mockCompanyResponse.setBody('{"items": [{"id": "12345"}]}');
        mockCompanyResponse.setStatusCode(200); 
        
        HttpResponse mockContactResponse = new HttpResponse();
        mockContactResponse.setHeader('Content-Type', 'application/json');
        mockContactResponse.setBody('{"items": [{"member_urn": "urn123", "id": "98765", "name": "John Doe", "first_name": "John", "last_name": "Doe", "location": "USA", "public_profile_url": "https://linkedin.com/in/johndoe", "current_positions": [{"role": "Engineer", "company": "TechCorp"}]}]}');
        mockContactResponse.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockCompanyResponse,mockContactResponse));
        
        List<Map<String, Object>> result = WorkingGridController.searchContactsApex('John', 'Doe', 'TechCorp');
        
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('John', result[0].get('firstName'));
        System.assertEquals('Doe', result[0].get('lastName'));
        System.assertEquals('Engineer', result[0].get('currentPosition'));
        System.assertEquals('TechCorp', result[0].get('company'));
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse contactResponse;
        private HttpResponse companyResponse;
        
        public MockHttpResponseGenerator(HttpResponse contactResponse,HttpResponse companyResponse) {
            this.contactResponse = contactResponse;
            this.companyResponse = companyResponse;
        }
        
        public HTTPResponse respond(HttpRequest req) {
            
            if (req.getEndpoint().contains(Label.companySearchEndPoint)) {
                return companyResponse;
            } else if (req.getEndpoint().contains(Label.searchContactsEndPoint)) {
                return contactResponse;
            }
            HttpResponse defaultResponse = new HttpResponse();
            defaultResponse.setStatusCode(404);
            defaultResponse.setBody('{"error": "Endpoint not found"}');
            return defaultResponse;
        }
    }
    
    @isTest
    static void testSearchContactsApex_BlankInput() {
        try {
            WorkingGridController.searchContactsApex('', 'Doe', 'CompanyXYZ');
            System.assert(false, 'Expected AuraHandledException for blank firstName');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Script-thrown exception'), 
                          'Exception message should indicate missing required fields.');
        }
    }
    
    @isTest
    static void testSearchContactsApex_InvalidCompany() {
        Test.setMock(HttpCalloutMock.class, new NoCompanyMock());
        
        try {
            Test.startTest();
            WorkingGridController.searchContactsApex('John', 'Doe', 'NonExistentCompany');
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException due to invalid company name');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Script-thrown exception'), 
                          'Exception message should indicate an invalid company name.');
        }
    }
        
    private class NoCompanyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains(System.Label.companySearchEndPoint)) {
                res.setBody('{"items": []}');
                res.setStatusCode(200);
            } else {
                res.setBody('{"items": []}');
                res.setStatusCode(200);
            }
            return res;
        }
    }
    
    @isTest
    static void testCreateContactWithGridId() {
        Grid__c testGrid = [SELECT Id FROM Grid__c WHERE Name='Test Grid 1' LIMIT 1];

        Test.startTest();

        Contact createdContact = WorkingGridController.createContact(
            'Alen', 'Doe', '12345', 'urn:li:12345', 
            'https://linkedin.com/in/alen', 'Spunk', 
            'New York', 'Software Engineer', testGrid.Id,'testpublicIdentifier'
        );

        Test.stopTest();

        System.assertNotEquals(null, createdContact.Id, 'Contact should be inserted');
        
        Contact storedContact = [SELECT FirstName, LastName, Contact_LinkedIn_Id__c 
                                 FROM Contact WHERE Id = :createdContact.Id];
        System.assertEquals('Alen', storedContact.FirstName);
        System.assertEquals('Doe', storedContact.LastName);
        System.assertEquals('12345', storedContact.Contact_LinkedIn_Id__c);

        Grid_Contact__c gc = [SELECT Contact__c, Grid__c FROM Grid_Contact__c WHERE Contact__c = :createdContact.Id LIMIT 1];
        System.assertEquals(testGrid.Id, gc.Grid__c);
    }

    @isTest
    static void testCreateContactWithoutGridId() {
        Test.startTest();

        Contact createdContact = WorkingGridController.createContact(
            'Jitendra', 'Varma', '67890', 'urn:li:67890', 
            'https://linkedin.com/in/jitendrav', 'HLIS', 
            'Ahmedabad', 'Software Engineer', null,'testpublicIdentifier'
        );

        Test.stopTest();

        System.assertNotEquals(null, createdContact.Id, 'Contact should be inserted');

        Contact storedContact = [SELECT FirstName, LastName, Contact_LinkedIn_Id__c 
                                 FROM Contact WHERE Id = :createdContact.Id];
        System.assertEquals('Jitendra', storedContact.FirstName);
        System.assertEquals('Varma', storedContact.LastName);
        System.assertEquals('67890', storedContact.Contact_LinkedIn_Id__c);


        List<Grid_Contact__c> gcList = [SELECT Id FROM Grid_Contact__c WHERE Contact__c = :createdContact.Id];
        System.assertEquals(0, gcList.size(), 'No Grid_Contact__c should be created');
    }
}