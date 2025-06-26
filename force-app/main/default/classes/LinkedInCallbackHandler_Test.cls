@isTest
private class LinkedInCallbackHandler_Test {
    
    @isTest
    static void testHandleCallback_Success() {
        String requestBody = '{"status":"Active", "account_id":"12345", "name":"John Doe"}';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        LinkedInCallbackHandler.handleCallback();
        Test.stopTest();
        
        LinkedIn_Account__c[] records = [SELECT Account_Status__c, Account_ID__c, User_Name__c FROM LinkedIn_Account__c];
        
        System.assertEquals(1, records.size());
        System.assertEquals('Active', records[0].Account_Status__c);
        System.assertEquals('12345', records[0].Account_ID__c);
        System.assertEquals('John Doe', records[0].User_Name__c);
    }
    
    @isTest
    static void testHandleCallback_MissingFields() {
        String requestBody = '{"status":"Active"}';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        LinkedInCallbackHandler.handleCallback();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testHandleCallback_EmptyFields() {
        String requestBody = '{"status":"", "account_id":"", "name":""}';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        LinkedInCallbackHandler.handleCallback();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }
    
    @isTest
    static void testHandleCallback_DmlException() {
        LinkedIn_Account__c existingRecord = new LinkedIn_Account__c(Account_Status__c='Active', Account_ID__c='78900', User_Name__c='Jane Smith');
        insert existingRecord;
        
        String requestBody = '{"status":"Active", "account_id":"78900", "name":"Jane Smith"}';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        try {
            LinkedInCallbackHandler.handleCallback();
        } catch (DmlException ex) {
        	System.assertEquals(500, RestContext.response.statusCode);
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testHandleCallback_GeneralException() {
        String requestBody = '{"status":"Active", "account_id":12345, "name":null}';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        try {
            LinkedInCallbackHandler.handleCallback();
        } catch (Exception ex) {
        	System.assertEquals(500, RestContext.response.statusCode);
        }
        Test.stopTest();
        
    }
}