@isTest
public class WebhookEmailEventListenerTest {
    
    @isTest
    static void testHandleEmailSent() {
        Contact testContact = new Contact(
            LastName = 'Test User',
            Email = 'sent@example.com'
        );
        insert testContact;

        String jsonPayload = JSON.serialize(new Map<String, Object>{
            'event' => 'mail_sent',
            'thread_id' => 'thread123',
            'to_attendees' => new List<Object>{
                new Map<String, Object>{ 'identifier' => 'sent@example.com' }
            }
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/webhookemailevent/';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEmailEventListener.handleEvent();

        Contact updatedContact = [SELECT Email1_Thread_Id__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('thread123', updatedContact.Email1_Thread_Id__c);
    }
	
    @isTest
    static void testHandleEmailOpened() {
        Contact testContact = new Contact(
            LastName = 'Test User',
            Email = 'opened@example.com',
            Email1_Tracking_Id__c = 'track123',
            Email_1__c = 'Email Sent'
        );
        insert testContact;

        String jsonPayload = JSON.serialize(new Map<String, Object>{
            'event' => 'mail_opened',
            'tracking_id' => 'track123'
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/webhookemailevent/';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEmailEventListener.handleEvent();

        Contact updatedContact = [SELECT Email_1__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Email Read', updatedContact.Email_1__c);
    }
	
    @isTest
    static void testHandleEmailReceived() {
        Contact testContact = new Contact(
            LastName = 'Test User',
            Email = 'received@example.com',
            Email_1__c = 'Email Read',
            Email1_Thread_Id__c = 'thread123'
        );
        insert testContact;

        String jsonPayload = JSON.serialize(new Map<String, Object>{
            'event' => 'mail_received',
            'thread_id' => 'thread123',
            'from_attendee' => new Map<String, Object>{
                'identifier' => 'received@example.com'
            }
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/webhookemailevent/';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEmailEventListener.handleEvent();

        Contact updatedContact = [SELECT Email_1__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('Email Responded', updatedContact.Email_1__c);
    }
	
    @isTest
    static void testUnsupportedEvent() {
        String jsonPayload = JSON.serialize(new Map<String, Object>{
            'event' => 'unknown_event'
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/webhookemailevent/';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEmailEventListener.handleEvent();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testEmptyRequestBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf('');
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEmailEventListener.handleEvent();

        System.assertEquals(400, RestContext.response.statusCode);
    }
	
    @isTest
    static void testWebhookLogging() {
        String jsonPayload = JSON.serialize(new Map<String, Object>{
            'event' => 'mail_opened',
            'tracking_id' => 'track999'
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/webhookemailevent/';
        RestContext.request = req;
        RestContext.response = res;

        WebhookEmailEventListener.handleEvent();

        List<Webhook_Event__c> logs = [SELECT Id FROM Webhook_Event__c];
        System.assert(!logs.isEmpty(), 'Webhook log should be created.');
    }
    
    @isTest
    static void testGetLinkedInAccountId() {
        LinkedIn_Account__c acc = new LinkedIn_Account__c(Account_ID__c = 'acc123');
        insert acc;

        Id result = WebhookEmailEventListener.getLinkedInAccountId('acc123');
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetLinkedInAccountIdBlank() {
        Id result = WebhookEmailEventListener.getLinkedInAccountId('');
        System.assertEquals(null, result);
    }

    @isTest
    static void testGetLinkedInAccountIdNoMatch() {
        Id result = WebhookEmailEventListener.getLinkedInAccountId('nonexistent');
        System.assertEquals(null, result);
    }
}