@isTest
public class WebhookCreator_Test {
    
    @isTest
    static void testCreateWebhook_Success() {
        LinkedIn_Account__c testAccount = new LinkedIn_Account__c(Account_ID__c = 'A001');
        insert testAccount;
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(201);
        mockResponse.setBody('{"webhook_id": "12345", "object": "active"}');
        
        HttpCalloutMock mock = new WebhookMock(mockResponse);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest(); 
        WebhookCreator.createWebhook('A001', 'Active', 'TestWebhook');
        Test.stopTest(); 

        LinkedIn_Account__c updatedAccount = [SELECT Webhook_ID__c, Webhook_Status__c FROM LinkedIn_Account__c WHERE Account_ID__c = 'A001' LIMIT 1];
        System.assertEquals('12345', updatedAccount.Webhook_ID__c, 'Webhook ID should match the mock response');
        System.assertEquals('active', updatedAccount.Webhook_Status__c, 'Webhook status should match the mock response');
    }
    
    @isTest
    static void testCreateWebhook_Failure() {
        Test.startTest();
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"error": "Invalid request"}');
        
        HttpCalloutMock mock = new WebhookMock(mockResponse);
        Test.setMock(HttpCalloutMock.class, mock);
        
        WebhookCreator.createWebhook('A002', 'Inactive', 'TestWebhookFailure');
        
        List<LinkedIn_Account__c> records = [SELECT Id FROM LinkedIn_Account__c WHERE Account_ID__c = 'A002'];
        System.assertEquals(0, records.size());
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateLinkedInAccountWithWebhookId_NoRecord() {
        WebhookCreator.updateLinkedInAccountWithWebhookId('A003', '67890', 'inactive');

        List<LinkedIn_Account__c> records = [SELECT Id FROM LinkedIn_Account__c WHERE Account_ID__c = 'A003'];
        System.assertEquals(0, records.size(), 'No records should be updated if no matching Account_ID__c exists');
    }

    @isTest
    static void testUpdateLinkedInAccountWithWebhookId_Success() {
        LinkedIn_Account__c testAccount = new LinkedIn_Account__c(Account_ID__c = 'A004');
        insert testAccount;

        Test.startTest();
        WebhookCreator.updateLinkedInAccountWithWebhookId('A004', '99999', 'active');
        Test.stopTest();

        LinkedIn_Account__c updatedAccount = [SELECT Webhook_ID__c, Webhook_Status__c FROM LinkedIn_Account__c WHERE Account_ID__c = 'A004' LIMIT 1];
        System.assertEquals('99999', updatedAccount.Webhook_ID__c, 'Webhook ID should be updated');
        System.assertEquals('active', updatedAccount.Webhook_Status__c, 'Webhook status should be updated');
    }

    
    private class WebhookMock implements HttpCalloutMock {
        private HttpResponse mockResponse;
        
        public WebhookMock(HttpResponse response) {
            this.mockResponse = response;
        }
        
        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}