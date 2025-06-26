public with sharing class EmailTemplateController {
    
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplate> getEmailTemplates() {
        return [SELECT Id, Name, Subject, Body FROM EmailTemplate WHERE Folder.DeveloperName='prospectGridEmailTemplates' ORDER BY CreatedDate DESC];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplate> getMessageTemplates() {
        return [SELECT Id, Name, Subject, Body FROM EmailTemplate WHERE Folder.DeveloperName ='prospectGridMessageTemplates' ORDER BY CreatedDate DESC];
    }
    

    @AuraEnabled
    public static void sendEmailWithTemplate1(String email, String targetObjectId, String contactId, String subject, String message) {
        Id googelrecordTypeId = providerRecordTypeMap.get('Google');
        Id microsoftrecordTypeId = providerRecordTypeMap.get('Microsoft');
        List<LinkedIn_Account__c> linkedInAccList;
        List<LinkedIn_Account__c> googlelinkedInAcc = [
            SELECT Id, Account_ID__c 
            FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() 
            AND RecordTypeId = :googelrecordTypeId 
            LIMIT 1
        ];
       List<LinkedIn_Account__c> microsoftlinkedInAcc = [
            SELECT Id, Account_ID__c 
            FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() 
            AND RecordTypeId = :microsoftrecordTypeId 
            LIMIT 1
        ];
        if(googlelinkedInAcc.isEmpty()){
            linkedInAccList = microsoftlinkedInAcc;
        }
        if(microsoftlinkedInAcc.isEmpty()){
            linkedInAccList = googlelinkedInAcc;
        }
        string linkedInAcc = linkedInAccList[0]?.Account_ID__c;
        
        System.debug('accountId is ' + linkedInAcc);
        
        if (String.isEmpty(email) || String.isEmpty(targetObjectId) || String.isEmpty(subject) || String.isEmpty(message) || String.isEmpty(linkedInAcc)) {
                throw new AuraHandledException('Missing required parameters: Email, Target Object ID, Subject, or Message.');
            }
        
        Grid_Contact__c curCon;
        
        try {
            if (!String.isEmpty(contactId)) {
                curCon = [SELECT Id, Name__c, Email_1__c, Email1_Tracking_Id__c FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1];
                if (curCon == null) {
                    throw new AuraHandledException('Invalid Contact ID.');
                }
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.label.sendingEmailAPIEndPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-API-KEY', System.label.apiKeyUNipile);
            
            Map<String, Object> payload = new Map<String, Object>{
                'account_id' => linkedInAcc,
                    'subject' => subject,
                    'body' => message,
                    'to' => new List<Object>{
                        new Map<String, String>{
                            'display_name' => (curCon != null ? curCon.Name__c : 'Contact'),
                                'identifier' => email
                                }
                    },
                         'tracking_options' => new Map<String, Boolean>{
                            'opens' => true,
                                'links' => false
                                }
            };
                
                req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String trackingId = (String) responseBody.get('tracking_id');
                System.debug('Tracking ID: ' + trackingId);
                
                if (curCon!= null && curCon.Email_1__c != 'Email Sent' &&  curCon.Email1_Tracking_Id__c == null) {
                    curCon.Email_1__c = 'Email Sent';
                  	curCon.Email1_Tracking_Id__c = trackingId;
                    update curCon;
                }
            } else {
                throw new AuraHandledException('Unipile Email failed: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static void sendEmailWithTemplate2(String email, String targetObjectId, String contactId, String subject, String message) {
        Id googelrecordTypeId = providerRecordTypeMap.get('Google');
        Id microsoftrecordTypeId = providerRecordTypeMap.get('Microsoft');
        List<LinkedIn_Account__c> linkedInAccList;
        List<LinkedIn_Account__c> googlelinkedInAcc = [
            SELECT Id, Account_ID__c 
            FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() 
            AND RecordTypeId = :googelrecordTypeId 
            LIMIT 1
        ];
       List<LinkedIn_Account__c> microsoftlinkedInAcc = [
            SELECT Id, Account_ID__c 
            FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() 
            AND RecordTypeId = :microsoftrecordTypeId 
            LIMIT 1
        ];
        if(googlelinkedInAcc.isEmpty()){
            linkedInAccList = microsoftlinkedInAcc;
        }
        if(microsoftlinkedInAcc.isEmpty()){
            linkedInAccList = googlelinkedInAcc;
        }
        string linkedInAcc = linkedInAccList[0]?.Account_ID__c;
        
        System.debug('accountId is ' + linkedInAcc);
        if (String.isEmpty(email) || String.isEmpty(targetObjectId) || String.isEmpty(subject) || String.isEmpty(message) || string.isEmpty(linkedInAcc)) {
            throw new AuraHandledException('Missing required parameters: Email, Target Object ID, Subject, or Message.');
        }
        
        Grid_Contact__c curCon;
        
        try {
            if (!String.isEmpty(contactId)) {
                curCon = [SELECT Id, Name__c, Email_2__c, Email2_Tracking_Id__c FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1];
                if (curCon == null) {
                    throw new AuraHandledException('Invalid Contact ID.');
                }
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(system.label.sendingEmailAPIEndPoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-API-KEY', system.label.apiKeyUNipile);
            
            Map<String, Object> payload = new Map<String, Object>{
                'account_id' => linkedInAcc,
                    'subject' => subject,
                    'body' => message,
                    'to' => new List<Object>{
                        new Map<String, String>{
                            'display_name' => (curCon != null ? curCon.Name__c : 'Contact'),
                                'identifier' => email
                                }
                    },
                        'tracking_options' => new Map<String, Boolean>{
                            'opens' => true,
                                'links' => false
                                }
            };
                
                req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String trackingId = (String) responseBody.get('tracking_id');
                System.debug('Tracking ID: ' + trackingId);
                
                if (curCon != null && curCon.Email_2__c != 'Email Sent' && curCon.Email2_Tracking_Id__c == null ) {
                    curCon.Email_2__c = 'Email Sent';
                   	curCon.Email2_Tracking_Id__c = trackingId;
                    update curCon;
                }
            } else {
                throw new AuraHandledException('Unipile Email failed: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Folder> getEmailTemplateFolders() {
        return [SELECT Id, Name FROM Folder WHERE Type = 'Email' ORDER BY Name ASC];
    }
    
    @AuraEnabled
    public static String createEmailTemplate(String name, String developerName, String subject, String body, String folderId) {
        try {
            
            if (developerName == null || developerName.trim() == '') {
                throw new AuraHandledException('Developer Name cannot be empty.');
            }
            
            EmailTemplate newTemplate = new EmailTemplate();
            newTemplate.Name = name;
            newTemplate.DeveloperName = developerName;
            newTemplate.Subject = subject;
            newTemplate.Body = body;
            newTemplate.FolderId = folderId;
            newTemplate.TemplateType = 'text';
            insert newTemplate;
            
            return 'Success';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('Error creating email template: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateTemplate(String id, String name, String developerName, String subject, String body, String folderId) {
        try {
            
            if (developerName == null || developerName.trim() == '') {
                throw new AuraHandledException('Developer Name cannot be empty.');
            }
            
            EmailTemplate templateToUpdate = [SELECT Id, Name, DeveloperName, Subject, Body, FolderId FROM EmailTemplate WHERE Id = :id LIMIT 1];
         
            templateToUpdate.Name = name;
            templateToUpdate.DeveloperName = developerName;
            templateToUpdate.Subject = subject;
            templateToUpdate.Body = body;
            templateToUpdate.FolderId = folderId;
            
            update templateToUpdate;
            
            return 'Success';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('Error Updating email template: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String deleteEmailTemplateById(String templateId) {
        try {
            EmailTemplate templateToDelete = [SELECT Id FROM EmailTemplate WHERE Id = :templateId LIMIT 1];
            delete templateToDelete;
            return 'Success';
        } catch (DmlException e) {
            throw new AuraHandledException('Error deleting template: ' + e.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('Error deleting template: ' + ex.getMessage());
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
}