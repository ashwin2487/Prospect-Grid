@isTest
public class CustomLoginController_Test {
    @isTest
    static void testConnectToLinkedInUnipile_Success() {
        
        Test.setMock(HttpCalloutMock.class, new CustomHttpResponseMock(200, '{"success": true}'));
        
        String payload = '{"test": "data"}';
        
        Test.startTest();
        String response = CustomLoginController.connectToLinkedInUnipile(payload);
        Test.stopTest();
        
        System.assertEquals('{"success": true}', response);
    }
    
    @isTest
    static void testConnectToLinkedInUnipile_Failure() {
        Test.setMock(HttpCalloutMock.class, new CustomHttpResponseMock(400, '{"error": "Bad Request"}'));
        
        String payload = '{"test": "data"}';
        
        Test.startTest();
        try {
            CustomLoginController.connectToLinkedInUnipile(payload);
            System.assert(false, 'Expected an AuraHandledException but did not occur.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }
    
    private class CustomHttpResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public CustomHttpResponseMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody(responseBody);
            response.setStatusCode(statusCode);
            return response;
        }
	}
    
    @isTest
    static void testShouldLinkedInAccountEnable_True() {
        
        Id rtId=[SELECT Id FROM RecordType WHERE DeveloperName='Linkedin' AND SObjectType='LinkedIn_Account__c' LIMIT 1].Id;
       
        LinkedIn_Account__c acc = new LinkedIn_Account__c(
            RecordTypeId = rtId,
            Account_ID__c = '123456',
            User_Name__c = UserInfo.getName(),
            Account_Status__c = 'CREATION_SUCCESS',
            Connection_Status__c = 'OK'
        );
        insert acc;

        Test.startTest();
        Boolean result = CustomLoginController.shouldLinkedInAccountEnable();
        Test.stopTest();

        System.assertEquals(true, result, 'LinkedIn should be enabled');
    }

    @isTest
    static void testShouldGoogleAccountEnable_False() {
   
        Test.startTest();
        Boolean result = CustomLoginController.shouldGoogleAccountEnable(); // Replace with actual class name
        Test.stopTest();

        System.assertEquals(false, result, 'Google should not be enabled');
    }

    @isTest
    static void testShouldOutlookAccountEnable_True() {
        
        Id rtId=[SELECT Id FROM RecordType WHERE DeveloperName='Google' AND SObjectType='LinkedIn_Account__c' LIMIT 1].Id;
        
        // Insert mock Outlook account
        LinkedIn_Account__c acc = new LinkedIn_Account__c(
            RecordTypeId = rtId,
            Account_ID__c = '78910',
            User_Name__c = UserInfo.getName(),
            Account_Status__c = 'CREATION_SUCCESS',
            Connection_Status__c = 'OK'
        );
        insert acc;

        Test.startTest();
        Boolean result = CustomLoginController.shouldOutlookAccountEnable(); 
        Test.stopTest();

        System.assertEquals(true, result, 'Outlook should be enabled');
    }
}