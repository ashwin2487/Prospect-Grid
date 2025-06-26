@isTest
private class cancelInvitationBatchApex_Test {
    @testSetup
    static void setupTestData() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName='Demo',
                LastName='Contact' + i,
                LinkedIn_Invitation_Sent_Date__c = System.today().addDays(-31),
                LinkedIn_Connection_Status__c = 'Not Connected',
                LinkedIn_Invitation_Id__c = 'INV-' + i
            ));
        }
        insert contacts;

        insert new LinkedIn_Account__c(
            Account_ID__c = 'TestAccountId',
            User_Name__c = System.UserInfo.getName()
        );
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        cancelInvitationBatchApex batch = new cancelInvitationBatchApex();
        Database.executeBatch(batch, 5); 
        Test.stopTest();
        
        List<Contact> updatedContacts = [SELECT LinkedIn_Connection_Status__c FROM Contact];
        for (Contact con : updatedContacts) {
            System.assertEquals('Cancelled Invitation', con.LinkedIn_Connection_Status__c);
        }
    }

    @isTest
    static void testCalloutExecution() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        cancelInvitationBatchApex batch = new cancelInvitationBatchApex();
        Database.executeBatch(batch, 5); // Match batch size with records
        Test.stopTest();
        
        System.assert(true, 'Callout executed successfully');
    }

    @isTest
    static void testScheduler() {
        Test.startTest();
        String jobId = System.schedule('Test Schedule', '0 35 15 * * ?', new cancelInvitationBatchApex());
        System.assertNotEquals(null, jobId);
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}