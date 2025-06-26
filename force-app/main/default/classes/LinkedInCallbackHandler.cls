@RestResource(urlMapping='/LinkedInCallbackHandler/*')
global with sharing class LinkedInCallbackHandler {

    @HttpPost
    global static void handleCallback() {
        RestResponse res = RestContext.response;
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            if (!payload.containsKey('status') || !payload.containsKey('account_id') || !payload.containsKey('name')) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"message":"Missing required fields: status, account_id, or name"}');
                return;
            }
            
            String status = (String) payload.get('status');
            String accountId = (String) payload.get('account_id');
            String fullName = (String) payload.get('name');
            
            if (String.isEmpty(status) || String.isEmpty(accountId) || String.isEmpty(fullName)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"message":"Fields status, account_id, and name cannot be empty"}');
                return;
            }

            List<String> parts = fullName.split('&');
            if (parts.size() < 2) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"message":"Invalid name format. Expected username_provider"}');
                return;
            }

            String userNameFromPayload = parts[0];
            String providerName = parts[1].toUpperCase();

            System.debug('Parsed Username: ' + userNameFromPayload);
            System.debug('Parsed Provider: ' + providerName);

            Map<String, Id> providerRecordTypeMap = getProviderRecordTypeIds();

            if (!providerRecordTypeMap.containsKey(providerName)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"message":"Invalid provider type"}');
                return;
            }

            Id recordTypeId = providerRecordTypeMap.get(providerName);

            LinkedIn_Account__c linkedInAccount = new LinkedIn_Account__c();
            linkedInAccount.Account_Status__c = status;
            linkedInAccount.Account_ID__c = accountId;
            linkedInAccount.User_Name__c = userNameFromPayload;
            linkedInAccount.Connection_Status__c = 'OK';
            linkedInAccount.RecordTypeId = recordTypeId;

            insert linkedInAccount;
			LinkedIn_Account_Upsert__e PERecord = new LinkedIn_Account_Upsert__e();
            PERecord.upsert__c = true;
            insert PERecord;
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"message":"LinkedIn account successfully created"}');

        } catch (QueryException qe) {
            System.debug('Query Exception: ' + qe.getMessage());
            res.responseBody = Blob.valueOf('{"message":"User not found for provided username"}');
            res.statusCode = 404;

        } catch (DmlException dmlEx) {          
            System.debug('DML Exception: ' + dmlEx.getMessage());
            res.responseBody = Blob.valueOf('{"message":"Error inserting LinkedIn account record"}');
            res.statusCode = 500;

        } catch (Exception ex) {
            System.debug('General Exception: ' + ex.getMessage());
            res.responseBody = Blob.valueOf('{"message":"Error processing callback"}');
            res.statusCode = 500;
        }
    }

    private static Map<String, Id> getProviderRecordTypeIds() {
        Map<String, Id> providerRecordTypeMap = new Map<String, Id>();
        List<RecordType> recordTypes = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'LinkedIn_Account__c'];

        for (RecordType rt : recordTypes) {
            if (rt.DeveloperName == 'LinkedIn') {
                providerRecordTypeMap.put('LINKEDIN', rt.Id);
            } else if (rt.DeveloperName == 'Google') {
                providerRecordTypeMap.put('GOOGLE', rt.Id);
            } else if (rt.DeveloperName == 'Microsoft') {
                providerRecordTypeMap.put('OUTLOOK', rt.Id);
            }
        }
        
        return providerRecordTypeMap;
    }
}