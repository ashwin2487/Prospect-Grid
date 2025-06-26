public with sharing class CreateUnipileWebhook {
    
    private class WebhookResponse {
        public String webhook_id;
    }
    
    @AuraEnabled
    public static String createLinkedInWebhook() {
        Id recordTypeId = providerRecordTypeMap.get('LinkedIn');
        try {
            
            List<LinkedIn_Account__c> linkedInAccounts = [
                SELECT Id, Account_ID__c FROM LinkedIn_Account__c 
                WHERE User_Name__c = :System.UserInfo.getName() AND recordTypeId =: recordTypeId LIMIT 1
            ];
            
            if (linkedInAccounts.isEmpty()) {
                return 'No LinkedIn_Account__c record found for current user.';
            }
            
            LinkedIn_Account__c account = linkedInAccounts[0];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.webhooksCreationAPIEndPoint);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            WebhookPayload payload = new WebhookPayload(account.Account_ID__c);
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                WebhookResponse res = (WebhookResponse) JSON.deserialize(response.getBody(), WebhookResponse.class);
                account.Webhook_ID__c = res.webhook_id;
                update account;
                
                return 'Webhook created successfully. ID: ' + res.webhook_id;
            } else {
                return 'Failed to create webhook. Status: ' + response.getStatusCode() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    public class WebhookPayload {
        public String source = 'messaging';
        public String request_url = System.Label.webhookRequestURL;
        public String format = 'json';
        public List<String> account_ids;
        public Boolean enabled = true;
        public List<String> events = new List<String>{ 'message_received', 'message_read' };
            public List<Map<String, String>> headers = new List<Map<String, String>>{
                new Map<String, String>{ 'key' => 'Content-Type', 'value' => 'application/json' }
            };
                
                public WebhookPayload(String accountId) {
                    this.account_ids = new List<String>{ accountId };
                        }
    }
    @AuraEnabled
    public static String createEmailTrackingWebhook() {
        Id recordTypeId = providerRecordTypeMap.get('Google');
        try {
            
            List<LinkedIn_Account__c> linkedInAccounts = [
                SELECT Id, Account_ID__c FROM LinkedIn_Account__c 
                WHERE User_Name__c = :System.UserInfo.getName() AND recordTypeId =: recordTypeId LIMIT 1
            ];
            
            if (linkedInAccounts.isEmpty()) {
                return 'No LinkedIn_Account__c record found for current user.';
            }
            
            LinkedIn_Account__c account = linkedInAccounts[0];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.webhooksCreationAPIEndPoint);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            WebhookEmailTrackingPayload payload = new WebhookEmailTrackingPayload(account.Account_ID__c);
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                WebhookResponse res = (WebhookResponse) JSON.deserialize(response.getBody(), WebhookResponse.class);
                account.Email_Tracking_Webhook_Id__c = res.webhook_id;
                update account;
                
                return 'Webhook created successfully. ID: ' + res.webhook_id;
            } else {
                return 'Failed to create webhook. Status: ' + response.getStatusCode() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    public class WebhookEmailTrackingPayload {
        public String source = 'email_tracking';
        public String request_url = System.Label.webhookEmailEventRequestURL;
        public String format = 'json';
        public List<String> account_ids;
        public Boolean enabled = true;
        public List<String> events = new List<String>{ 'mail_opened'};
            public List<Map<String, String>> headers = new List<Map<String, String>>{
                new Map<String, String>{ 'key' => 'Content-Type', 'value' => 'application/json' }
            };
                
                public WebhookEmailTrackingPayload(String accountId) {
                    this.account_ids = new List<String>{ accountId };
                        }
    }

    @AuraEnabled
    public static String createReceivedEmailTrackingWebhook() {
        Id recordTypeId = providerRecordTypeMap.get('Google');
        try {
            // Fetch LinkedIn account
            List<LinkedIn_Account__c> linkedInAccounts = [
                SELECT Id, Account_ID__c FROM LinkedIn_Account__c 
                WHERE User_Name__c = : System.UserInfo.getName() AND recordTypeId =: recordTypeId LIMIT 1
            ];
            
            if (linkedInAccounts.isEmpty()) {
                return 'No LinkedIn_Account__c record found for current user.';
            }
            
            LinkedIn_Account__c account = linkedInAccounts[0];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.webhooksCreationAPIEndPoint);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            WebhookReceivedEmailTrackingPayload payload = new WebhookReceivedEmailTrackingPayload(account.Account_ID__c);
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                WebhookResponse res = (WebhookResponse) JSON.deserialize(response.getBody(), WebhookResponse.class);
                account.Email_new_Email_Webhook_Id__c = res.webhook_id;
                update account;
                
                return 'Webhook created successfully. ID: ' + res.webhook_id;
            } else {
                return 'Failed to create webhook. Status: ' + response.getStatusCode() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    public class WebhookReceivedEmailTrackingPayload {
        public String source = 'email';
        public String request_url = System.Label.webhookEmailEventRequestURL;
        public String format = 'json';
        public List<String> account_ids;
        public Boolean enabled = true;
        public List<String> events = new List<String>{'mail_received','mail_sent'};
            public List<Map<String, String>> headers = new List<Map<String, String>>{
                new Map<String, String>{ 'key' => 'Content-Type', 'value' => 'application/json' }
            };
                
                public WebhookReceivedEmailTrackingPayload(String accountId) {
                    this.account_ids = new List<String>{ accountId };
                        }
    }
    
    private static Map<String, Id> providerRecordTypeMap = new Map<String, Id>{
        'LinkedIn' => [SELECT Id FROM RecordType WHERE SObjectType = 'LinkedIn_Account__c' AND DeveloperName = 'LinkedIn' LIMIT 1].Id,
            'Google' => [SELECT Id FROM RecordType WHERE SObjectType = 'LinkedIn_Account__c' AND DeveloperName = 'Google' LIMIT 1].Id,
            'Microsoft' => [SELECT Id FROM RecordType WHERE SObjectType = 'LinkedIn_Account__c' AND DeveloperName = 'Microsoft' LIMIT 1].Id
            };
                
                public static Map<String, Id> getProviderRecordTypeIds() {
                    return providerRecordTypeMap;
                }
    
    @AuraEnabled
    public static boolean enableConnectedLinkedInTrackingEvent(){
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
            AND Webhook_ID__c !=null
        ];
        
        return !records.isEmpty();
    }    
    @AuraEnabled
    public static boolean enableSentEmailTrackingEvent(){
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
            AND Email_Tracking_Webhook_Id__c !=null
        ];
        
        return !records.isEmpty();
    }   
    @AuraEnabled
    public static boolean enableRecieveEmailTrackingEvent(){
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
            AND Email_new_Email_Webhook_Id__c !=null
        ];
        
        return !records.isEmpty();
    }
    @AuraEnabled
    public static String createMiscrosoftEmailTrackingWebhook() {
        Id recordTypeId = providerRecordTypeMap.get('Microsoft');
        try {
            
            List<LinkedIn_Account__c> linkedInAccounts = [
                SELECT Id, Account_ID__c FROM LinkedIn_Account__c 
                WHERE User_Name__c = :System.UserInfo.getName() AND recordTypeId =: recordTypeId LIMIT 1
            ];
            
            if (linkedInAccounts.isEmpty()) {
                return 'No LinkedIn_Account__c record found for current user.';
            }
            
            LinkedIn_Account__c account = linkedInAccounts[0];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.webhooksCreationAPIEndPoint);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            WebhookOutlookEmailTrackingPayload payload = new WebhookOutlookEmailTrackingPayload(account.Account_ID__c);
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                WebhookResponse res = (WebhookResponse) JSON.deserialize(response.getBody(), WebhookResponse.class);
                account.Email_Tracking_Webhook_Id__c = res.webhook_id;
                update account;
                
                return 'Webhook created successfully. ID: ' + res.webhook_id;
            } else {
                return 'Failed to create webhook. Status: ' + response.getStatusCode() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    public class WebhookOutlookEmailTrackingPayload {
        public String source = 'email_tracking';
        public String request_url = System.Label.webhookEmailEventRequestURL;
        public String format = 'json';
        public List<String> account_ids;
        public Boolean enabled = true;
        public List<String> events = new List<String>{ 'mail_opened'};
            public List<Map<String, String>> headers = new List<Map<String, String>>{
                new Map<String, String>{ 'key' => 'Content-Type', 'value' => 'application/json' }
            };
                
                public WebhookOutlookEmailTrackingPayload(String accountId) {
                    this.account_ids = new List<String>{ accountId };
                        }
    }

    @AuraEnabled
    public static String createMiscrosoftReceivedEmailTrackingWebhook() {
        Id recordTypeId = providerRecordTypeMap.get('Microsoft');
        try {
            // Fetch LinkedIn account
            List<LinkedIn_Account__c> linkedInAccounts = [
                SELECT Id, Account_ID__c FROM LinkedIn_Account__c 
                WHERE User_Name__c = : System.UserInfo.getName() AND recordTypeId =: recordTypeId LIMIT 1
            ];
            
            if (linkedInAccounts.isEmpty()) {
                return 'No LinkedIn_Account__c record found for current user.';
            }
            
            LinkedIn_Account__c account = linkedInAccounts[0];
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.webhooksCreationAPIEndPoint);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            WebhookReceivedMiscrosoftEmailTrackingPayload payload = new WebhookReceivedMiscrosoftEmailTrackingPayload(account.Account_ID__c);
            request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                WebhookResponse res = (WebhookResponse) JSON.deserialize(response.getBody(), WebhookResponse.class);
                account.Email_new_Email_Webhook_Id__c = res.webhook_id;
                update account;
                
                return 'Webhook created successfully. ID: ' + res.webhook_id;
            } else {
                return 'Failed to create webhook. Status: ' + response.getStatusCode() + ' - ' + response.getBody();
            }
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    public class WebhookReceivedMiscrosoftEmailTrackingPayload {
        public String source = 'email';
        public String request_url = System.Label.webhookEmailEventRequestURL;
        public String format = 'json';
        public List<String> account_ids;
        public Boolean enabled = true;
        public List<String> events = new List<String>{'mail_received','mail_sent'};
            public List<Map<String, String>> headers = new List<Map<String, String>>{
                new Map<String, String>{ 'key' => 'Content-Type', 'value' => 'application/json' }
            };
                
                public WebhookReceivedMiscrosoftEmailTrackingPayload(String accountId) {
                    this.account_ids = new List<String>{ accountId };
                        }
    }
    
    @AuraEnabled
    public static boolean enableRecieveEmailOutlookTrackingEvent(){
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
            AND Email_new_Email_Webhook_Id__c !=null
        ];
        
        return !records.isEmpty();
    }
    @AuraEnabled
    public static boolean enableSentEmailOutlookTrackingEvent(){
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
            AND Email_Tracking_Webhook_Id__c !=null
        ];
        
        return !records.isEmpty();
    }
    
}