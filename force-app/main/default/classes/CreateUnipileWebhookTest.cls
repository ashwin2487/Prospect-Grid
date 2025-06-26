@isTest
public class CreateUnipileWebhookTest {

    @testSetup
    static void setupData() {
        // Fetch RecordTypes and map by exact DeveloperName
        List<RecordType> rTypes = [
            SELECT Id, DeveloperName
              FROM RecordType 
             WHERE SObjectType = 'LinkedIn_Account__c'
               AND DeveloperName IN ('Linkedin', 'Google', 'Microsoft')
        ];
        Map<String, Id> rtMap = new Map<String, Id>();
        for (RecordType rt : rTypes) {
            rtMap.put(rt.DeveloperName.toLowerCase(), rt.Id);
        }

        // Insert LinkedIn account
        LinkedIn_Account__c linkedinAcc = new LinkedIn_Account__c(
            User_Name__c      = System.UserInfo.getName(),
            Account_ID__c     = 'acc123',
            RecordTypeId      = rtMap.get('linkedin'),
            Account_Status__c = 'CREATION_SUCCESS',
            Connection_Status__c = 'OK'
        );

        // Insert Google account
        LinkedIn_Account__c googleAcc = new LinkedIn_Account__c(
            User_Name__c      = System.UserInfo.getName(),
            Account_ID__c     = 'acc456',
            RecordTypeId      = rtMap.get('google'),
            Account_Status__c = 'CREATION_SUCCESS',
            Connection_Status__c = 'OK'
        );
        insert new List<LinkedIn_Account__c>{ linkedinAcc, googleAcc };

        // Populate webhook fields to satisfy enable* tests
        linkedinAcc.Webhook_ID__c = 'initialWebhook';
        googleAcc.Email_Tracking_Webhook_Id__c = 'initialEmailTrack';
        googleAcc.Email_new_Email_Webhook_Id__c = 'initialEmailNew';
        update new List<LinkedIn_Account__c>{ linkedinAcc, googleAcc };
    }


    @isTest
    static void testCreateLinkedInWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        CreateUnipileWebhook.createLinkedInWebhook();
        Test.stopTest();

        LinkedIn_Account__c acc = [
            SELECT Webhook_ID__c 
              FROM LinkedIn_Account__c 
             WHERE Account_ID__c = 'acc123' LIMIT 1
        ];
        System.assertEquals('mockWebhook123', acc.Webhook_ID__c);
    }

    @isTest
    static void testCreateEmailTrackingWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        CreateUnipileWebhook.createEmailTrackingWebhook();
        Test.stopTest();

        LinkedIn_Account__c acc = [
            SELECT Email_Tracking_Webhook_Id__c 
              FROM LinkedIn_Account__c 
             WHERE Account_ID__c = 'acc456' LIMIT 1
        ];
        System.assertEquals('mockWebhook123', acc.Email_Tracking_Webhook_Id__c);
    }

    @isTest
    static void testCreateReceivedEmailTrackingWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        CreateUnipileWebhook.createReceivedEmailTrackingWebhook();
        Test.stopTest();

        LinkedIn_Account__c acc = [
            SELECT Email_new_Email_Webhook_Id__c 
              FROM LinkedIn_Account__c 
             WHERE Account_ID__c = 'acc456' LIMIT 1
        ];
        System.assertEquals('mockWebhook123', acc.Email_new_Email_Webhook_Id__c);
    }

    @isTest
    static void testEnableConnectedLinkedInTrackingEvent() {
        Boolean result = CreateUnipileWebhook.enableConnectedLinkedInTrackingEvent();
        System.assertEquals(true, result);
    }

    @isTest
    static void testEnableSentEmailTrackingEvent() {
        Boolean result = CreateUnipileWebhook.enableSentEmailTrackingEvent();
        System.assertEquals(true, result);
    }

    @isTest
    static void testEnableRecieveEmailTrackingEvent() {
        Boolean result = CreateUnipileWebhook.enableRecieveEmailTrackingEvent();
        System.assertEquals(true, result);
    }

    @isTest
    static void testGetProviderRecordTypeIds() {
        Map<String, Id> ids = CreateUnipileWebhook.getProviderRecordTypeIds();
        System.assert(ids.containsKey('LinkedIn'), 'Missing key LinkedIn');
        System.assert(ids.containsKey('Google'),   'Missing key Google');
        System.assert(ids.containsKey('Microsoft'),'Missing key Microsoft');
    }

    @isTest
    static void testCreateLinkedInWebhook_NoAccount() {
        // Remove all LinkedIn records
        Id rtId = CreateUnipileWebhook.getProviderRecordTypeIds().get('LinkedIn');
        delete [SELECT Id FROM LinkedIn_Account__c WHERE RecordTypeId = :rtId];

        String result = CreateUnipileWebhook.createLinkedInWebhook();
        System.assertEquals('No LinkedIn_Account__c record found for current user.', result);
    }

	 @isTest
    static void testCreateLinkedInWebhook_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionGenerator());
        String result = CreateUnipileWebhook.createLinkedInWebhook();
        System.assert(result.startsWith('Error:'));
    }

    @isTest
    static void testCreateEmailTrackingWebhook_NoAccount() {
        // Remove all Google records
        Id rtId = CreateUnipileWebhook.getProviderRecordTypeIds().get('Google');
        delete [SELECT Id FROM LinkedIn_Account__c WHERE RecordTypeId = :rtId];

        String result = CreateUnipileWebhook.createEmailTrackingWebhook();
        System.assertEquals('No LinkedIn_Account__c record found for current user.', result);
    }


    @isTest
    static void testCreateEmailTrackingWebhook_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionGenerator());
        String result = CreateUnipileWebhook.createEmailTrackingWebhook();
        System.assert(result.startsWith('Error:'));
    }

    @isTest
    static void testCreateReceivedEmailTrackingWebhook_NoAccount() {
        // Remove all Google records
        Id rtId = CreateUnipileWebhook.getProviderRecordTypeIds().get('Google');
        delete [SELECT Id FROM LinkedIn_Account__c WHERE RecordTypeId = :rtId];

        String result = CreateUnipileWebhook.createReceivedEmailTrackingWebhook();
        System.assertEquals('No LinkedIn_Account__c record found for current user.', result);
    }


    @isTest
    static void testCreateReceivedEmailTrackingWebhook_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionGenerator());
        String result = CreateUnipileWebhook.createReceivedEmailTrackingWebhook();
        System.assert(result.startsWith('Error:'));
    }

    @isTest
    static void testEnableConnectedLinkedInTrackingEvent_False() {
        LinkedIn_Account__c acc = [SELECT Id, Webhook_ID__c FROM LinkedIn_Account__c WHERE Account_ID__c='acc123'];
        acc.Webhook_ID__c = null;
        update acc;
        Boolean result = CreateUnipileWebhook.enableConnectedLinkedInTrackingEvent();
        System.assertEquals(false, result);
    }

    @isTest
    static void testEnableSentEmailTrackingEvent_False() {
        LinkedIn_Account__c acc = [SELECT Id, Email_Tracking_Webhook_Id__c FROM LinkedIn_Account__c WHERE Account_ID__c='acc456'];
        acc.Email_Tracking_Webhook_Id__c = null;
        update acc;
        Boolean result = CreateUnipileWebhook.enableSentEmailTrackingEvent();
        System.assertEquals(false, result);
    }

    @isTest
    static void testEnableRecieveEmailTrackingEvent_False() {
        LinkedIn_Account__c acc = [SELECT Id, Email_new_Email_Webhook_Id__c FROM LinkedIn_Account__c WHERE Account_ID__c='acc456'];
        acc.Email_new_Email_Webhook_Id__c = null;
        update acc;
        Boolean result = CreateUnipileWebhook.enableRecieveEmailTrackingEvent();
        System.assertEquals(false, result);
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"webhook_id": "mockWebhook123"}');
            res.setStatusCode(201);
            return res;
        }
    }

    private class MockFailureResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"failed"}');
            res.setStatusCode(400);
            return res;
        }
    }

    private class MockExceptionGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('callout failed');
        }
    }
}