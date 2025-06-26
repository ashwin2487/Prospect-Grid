public with sharing class WebhookCreator {
    
    public static void createWebhook(String accountId, String status, String name) {
        try {
            // Define the webhook endpoint using the system label
            String webhookUrl = System.Label.webhookUnipileEndPoint;

            // Create JSON payload
            Map<String, Object> webhookPayload = new Map<String, Object>();
            webhookPayload.put('source', 'account_status');
            webhookPayload.put('enabled', true);
            webhookPayload.put('name', 'LoginUser');
            webhookPayload.put('account_ids', new List<String>{accountId});
            webhookPayload.put('request_url', 'https://abccorp-1c-dev-ed.develop.my.salesforce-sites.com/services/apexrest/LinkedInCallbackHandler');

            String requestBody = JSON.serialize(webhookPayload);

            // Make HTTP callout
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(webhookUrl);
            request.setMethod('POST');
            request.setHeader('accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            System.debug('Webhook Response: ' + response.getBody());
            if (response.getStatusCode() == 201) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                if (responseBody.containsKey('webhook_id')) {
                    String webhookId = (String) responseBody.get('webhook_id');
                    String webhookStatus = (String) responseBody.get('object');
                    updateLinkedInAccountWithWebhookId(accountId, webhookId, webhookStatus);
                } else {
                    System.debug('Webhook response did not contain webhook_id.');
                }
            } else {
                System.debug('Webhook creation failed. Status Code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }

        } catch (Exception ex) {
            System.debug('Error creating webhook: ' + ex.getMessage() + ' | StackTrace: ' + ex.getStackTraceString());
        }
    }
	
    @testVisible
    private static void updateLinkedInAccountWithWebhookId(String accountId, String webhookId, String webhookStatus) {
        try {
            List<LinkedIn_Account__c> linkedInAccounts = [SELECT Id FROM LinkedIn_Account__c WHERE Account_ID__c = :accountId LIMIT 1];

            if (!linkedInAccounts.isEmpty()) {
                LinkedIn_Account__c linkedInAccount = linkedInAccounts[0];
                linkedInAccount.Webhook_ID__c = webhookId;
                linkedInAccount.Webhook_Status__c = webhookStatus;
                update linkedInAccount;
                System.debug('Successfully updated LinkedIn_Account__c with Webhook ID: ' + webhookId);
            } else {
                System.debug('No LinkedIn_Account__c record found for Account_ID__c: ' + accountId);
            }
        } catch (DmlException dmlEx) {
            System.debug('DML Exception while updating LinkedIn_Account__c: ' + dmlEx.getMessage());
        } catch (Exception ex) {
            System.debug('Unexpected error updating LinkedIn_Account__c: ' + ex.getMessage());
        }
    }
}