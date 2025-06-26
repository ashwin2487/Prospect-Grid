@RestResource(urlMapping='/webhookevent/*')
global without sharing class WebhookEventListener {
    
    // Custom exception class (if needed)
    public class WebhookPayloadException extends Exception {}

    @HttpPost
    global static void handleEvent() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Validate request body exists
        if (req.requestBody == null || req.requestBody.size() == 0) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"message":"Empty request body"}');
            return;
        }
        
        // Convert request body to string
        String rawBody = req.requestBody.toString();
        System.debug('Raw Body: ' + rawBody);
        
        try {
            // Deserialize the raw JSON payload into a Map
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(rawBody);
            
            // Log the payload in Salesforce (insert a record into Webhook_Event__c)
            logWebhookPayload(rawBody, (String) payload.get('event'));
            
            // Process the payload based on the event type
            String eventType = (String) payload.get('event');
            if (eventType == 'message_received') {
                handleMessageReceived(payload);
            } else if (eventType == 'message_read') {
                handleMessageRead(payload);
            } else {
                System.debug('Unsupported event type: ' + eventType);
            }
            
            // Respond with success
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"message":"Webhook processed"}');
            
        } catch (Exception e) {
            System.debug('Webhook processing error: ' + e.getMessage());
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"Processing failed: ' + e.getMessage() + '"}');
        }
    }
    
    // Method to log all raw payloads to the Webhook_Event__c custom object
    private static void logWebhookPayload(String rawBody, String eventType) {
        try {
            Webhook_Event__c logRecord = new Webhook_Event__c(
                Name__c = 'Webhook Log ' + String.valueOf(System.now()),
                Raw_Payload__c = rawBody,
                Event_Received__c = eventType
            );
            insert logRecord;
            System.debug('Webhook payload logged successfully.');
        } catch (Exception e) {
            System.debug('Error logging webhook payload: ' + e.getMessage());
        }
    }
    
    public static void handleMessageReceived(Map<String, Object> payload) {
        try {
            // Extract nested sender information
            Map<String, Object> sender = (Map<String, Object>) payload.get('sender');
            String senderLinkedInId = sender != null ? (String) sender.get('attendee_provider_id') : null;
            String chatId = (String) payload.get('chat_id');
            String messageText = (String) payload.get('message');
            String messageTimestamp = (String) payload.get('timestamp');
            
            if (String.isBlank(senderLinkedInId) || String.isBlank(chatId)) {
                System.debug('Missing senderLinkedInId or chatId');
                return;
            }
            
            // Query matching Contacts using the LinkedIn ID
            List<Grid_Contact__c> matchedContacts = [
                SELECT Id, LinkedIn_Message_1__c, LinkedIn_Message_2__c, LinkedIn_Message_Received__c
                FROM Grid_Contact__c 
                WHERE Contact_LinkedIn_Id__c = :senderLinkedInId
            ];
            
            List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
            
            for (Grid_Contact__c con : matchedContacts) {
                Boolean updated = false;
                
                if (con.LinkedIn_Message_1__c != null &&
                    (con.LinkedIn_Message_1__c.containsIgnoreCase('Message Sent') ||
                     con.LinkedIn_Message_1__c.containsIgnoreCase('Message Read'))) {
                    con.LinkedIn_Message_1__c = 'Message Responded';
                    updated = true;
                }
                
                if (con.LinkedIn_Message_2__c != null &&
                    (con.LinkedIn_Message_2__c.containsIgnoreCase('Message Sent') ||
                     con.LinkedIn_Message_2__c.containsIgnoreCase('Message Read'))) {
                    con.LinkedIn_Message_2__c = 'Message Responded';
                    updated = true;
                }
                
                if (updated) {
                    String messageLog = 'Message Received: ' + messageText +
                        '\nTimestamp: ' + messageTimestamp;
                    if (String.isNotBlank(con.LinkedIn_Message_Received__c)) {
                        con.LinkedIn_Message_Received__c += '\n' + messageLog;
                    } else {
                        con.LinkedIn_Message_Received__c = messageLog;
                    }
                    contactsToUpdate.add(con);
                }
            }
            
            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error in handleMessageReceived: ' + e.getMessage());
        }
    }
    
    public static void handleMessageRead(Map<String, Object> payload) {
        System.debug('Received message_read event: ' + JSON.serialize(payload));
        // Future logic for read events can go here
    }
    
    @testVisible
    private static Id getLinkedInAccountId(String accountIdStr) {
        if (String.isBlank(accountIdStr)) return null;
        
        List<LinkedIn_Account__c> matches = [
            SELECT Id
            FROM LinkedIn_Account__c
            WHERE Account_ID__c = :accountIdStr
            LIMIT 1
        ];
        
        return matches.isEmpty() ? null : matches[0].Id;
    }
}