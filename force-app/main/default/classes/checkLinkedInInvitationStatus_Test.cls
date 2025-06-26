@isTest
public class checkLinkedInInvitationStatus_Test {
    
    @isTest
    static void checkLinkedInInvitationStatusTest() {

        LinkedIn_Account__c account = new LinkedIn_Account__c(
            Account_ID__c = 'dummyAccountId',
            User_Name__c = UserInfo.getName()
        );
        insert account;
        
        Contact testContact = new Contact(
            LastName = 'Test',
            Contact_LinkedIn_Id__c = 'dummyLinkedInId',
            Public_Identifier__c = 'testPublicId'
        );
        insert testContact;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        Database.executeBatch(new checkLinkedInInvitationStatus(), 1);
        Test.stopTest();
        
        testContact = [SELECT Id, LinkedIn_Connection_Status__c, LinkedIn_Invitation_Accepted_Date__c FROM Contact WHERE Id = :testContact.Id];
        
        System.assertEquals('Connected', testContact.LinkedIn_Connection_Status__c, 'The connection status should be updated to Connected');
        System.assertNotEquals(null, testContact.LinkedIn_Invitation_Accepted_Date__c, 'The invitation accepted date should be set');
    }
    @isTest 
    static void testSchedulable() {
        Test.startTest();
        String cronExp = '0 0 0 * * ?';
        System.schedule('Test LinkedIn Batch Scheduler', cronExp, new checkLinkedInInvitationStatus());
        Test.stopTest();
    }
 
   private class MockHttpResponseGenerator implements HttpCalloutMock {
    private Integer callCount = 0;

       public HTTPResponse respond(HTTPRequest req) {
           HttpResponse res = new HttpResponse();
           res.setHeader('Content-Type', 'application/json');
           res.setStatusCode(200);
           
           if (callCount == 0) {
               // Ensure the JSON key matches what the batch class is expecting: attendee_provider_id
               String jsonResponse = '{"object": "UserRelationsList", "items": [{"attendee_provider_id": "testPublicId"}], "cursor": "nextCursor"}';
               res.setBody(jsonResponse);
           } else {
               String jsonResponse = '{"object": "UserRelationsList", "items": [], "cursor": null}';
               res.setBody(jsonResponse);
           }
           
           callCount++;
           return res;
       }
	}
}