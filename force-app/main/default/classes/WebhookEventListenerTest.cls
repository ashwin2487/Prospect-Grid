@isTest
public class WebhookEventListenerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Contact with a LinkedIn IDtestLog
        Contact con = new Contact(
            LastName = 'Test User',
            Contact_LinkedIn_Id__c = 'linkedin_test_123',
            LinkedIn_Message_1__c = 'Message Sent',
            LinkedIn_Message_2__c = 'Message Read'
        );
        insert con;
    }

    @isTest
    static void testHandleEventWithEmptyBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEventListener.handleEvent();

        System.assertEquals(400, res.statusCode);
    }

    @isTest
    static void testHandleMessageReceivedEvent() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';

        String body = JSON.serialize(new Map<String, Object>{
            'event' => 'message_received',
            'sender' => new Map<String, Object>{ 'attendee_provider_id' => 'linkedin_test_123' },
            'chat_id' => 'chat_001',
            'message' => 'Hi there!',
            'timestamp' => '2025-04-20T12:00:00Z'
        });

        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        WebhookEventListener.handleEvent();

        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains('Webhook processed'));
    }

    @isTest
    static void testHandleMessageReadEvent() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';

        String body = JSON.serialize(new Map<String, Object>{
            'event' => 'message_read',
            'chat_id' => 'chat_002',
            'timestamp' => '2025-04-20T14:00:00Z'
        });

        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        WebhookEventListener.handleEvent();

        System.assertEquals(200, res.statusCode);
    }

    @isTest
    static void testUnsupportedEvent() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';

        String body = JSON.serialize(new Map<String, Object>{
            'event' => 'unknown_event'
        });

        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        WebhookEventListener.handleEvent();

        System.assertEquals(200, res.statusCode);
    }

    @isTest
    static void testMalformedJson() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';

        req.requestBody = Blob.valueOf('invalid_json_here');
        RestContext.request = req;
        RestContext.response = res;

        WebhookEventListener.handleEvent();

        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('Processing failed'));
    }
    @isTest
    static void testGetLinkedInAccountId() {
        LinkedIn_Account__c acc = new LinkedIn_Account__c(Account_ID__c = 'acc123');
        insert acc;

        Id result = WebhookEventListener.getLinkedInAccountId('acc123');
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetLinkedInAccountIdBlank() {
        Id result = WebhookEventListener.getLinkedInAccountId('');
        System.assertEquals(null, result);
    }

    @isTest
    static void testGetLinkedInAccountIdNoMatch() {
        Id result = WebhookEventListener.getLinkedInAccountId('nonexistent');
        System.assertEquals(null, result);
    }
}