public with sharing class CustomLoginController {
    @AuraEnabled
    public static String connectToLinkedInUnipile(String payload) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(System.Label.unipileEndPoint);
        request.setHeader('accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        request.setBody(payload);
        
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                System.debug('Response Body: ' + response.getBody());
                return response.getBody();
            } else {
                throw new CalloutException('Error: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            throw new AuraHandledException('Failed to connect to LinkedIn: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean shouldLinkedInAccountEnable() {
        
       String currentUser = UserInfo.getName();
        
        List<LinkedIn_Account__c> records = [
            SELECT RecordType.Name, Account_ID__c, User_Name__c, Account_Status__c, Connection_Status__c 
            FROM LinkedIn_Account__c 
            WHERE RecordType.Name = 'Linkedin' 
            AND Account_Status__c = 'CREATION_SUCCESS' 
            AND Connection_Status__c = 'OK' 
            AND Account_ID__c != null 
            AND User_Name__c != null 
            AND User_Name__c = :currentUser
        ];
        return !records.isEmpty();
    }
    
    @AuraEnabled
    public static Boolean shouldGoogleAccountEnable() {
        
       String currentUser = UserInfo.getName();
        
        List<LinkedIn_Account__c> records = [
            SELECT RecordType.Name, Account_ID__c, User_Name__c, Account_Status__c, Connection_Status__c 
            FROM LinkedIn_Account__c 
            WHERE RecordType.Name = 'Google' 
            AND Account_Status__c = 'CREATION_SUCCESS' 
            AND Connection_Status__c = 'OK' 
            AND Account_ID__c != null 
            AND User_Name__c != null 
            AND User_Name__c = :currentUser
        ];
        return !records.isEmpty();
    }
    
    @AuraEnabled
    public static Boolean shouldOutlookAccountEnable() {
        
       String currentUser = UserInfo.getName();
        
        List<LinkedIn_Account__c> records = [
            SELECT RecordType.Name, Account_ID__c, User_Name__c, Account_Status__c, Connection_Status__c 
            FROM LinkedIn_Account__c 
            WHERE RecordType.Name = 'Microsoft' 
            AND Account_Status__c = 'CREATION_SUCCESS' 
            AND Connection_Status__c = 'OK' 
            AND Account_ID__c != null 
            AND User_Name__c != null 
            AND User_Name__c = :currentUser
        ];
        return !records.isEmpty();
    }
    
}