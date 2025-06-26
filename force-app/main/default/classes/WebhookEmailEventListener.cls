@RestResource(urlMapping='/webhookemailevent/*')
global without sharing class WebhookEmailEventListener {
    public class WebhookPayloadException extends Exception {}
    
    @HttpPost
    global static void handleEvent() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        if (req.requestBody == null || req.requestBody.size() == 0) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"message":"Empty request body"}');
            return;
        }
        String rawBody = req.requestBody.toString();
        System.debug('Raw Body: ' + rawBody);
        
        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(rawBody);
            
            logWebhookPayload(rawBody, (String) payload.get('event'));
            String eventType = (String) payload.get('event');
            if (eventType == 'mail_received') {
                handleEmailReceived(payload);
            } else if (eventType == 'mail_sent') {
                handleEmailSent(payload);
            } else if (eventType == 'mail_opened') {
                handleEmailOpened(payload);
            }  else {
                System.debug('Unsupported event type: ' + eventType);
            }
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"message":"Webhook processed"}');
            
        } catch (Exception e) {
            System.debug('Webhook processing error: ' + e.getMessage());
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"Processing failed: ' + e.getMessage() + '"}');
        }
    }
    
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
    
    public static void handleEmailReceived(Map<String, Object> payload) {
        try {
            Map<String, Object> fromAttendee = (Map<String, Object>) payload.get('from_attendee');
            String threadIdRaw = (String) payload.get('thread_id');
            
            if (fromAttendee == null || String.isBlank(threadIdRaw)) return;
            
            String threadId = threadIdRaw.trim();
            String recipientEmailRaw = (String) fromAttendee.get('identifier');
            if (String.isBlank(recipientEmailRaw)) return;
            
            String recipientEmail = recipientEmailRaw.trim().toLowerCase();
            
            List<Grid_Contact__c> matchedContacts = [
                SELECT Id, Email__c, Email2_Tracking_Id__c, Email_1__c, Email_2__c,
                Email1_Thread_Id__c, Email2_Thread_Id__c
                FROM Grid_Contact__c
                WHERE Email__c != null
            ];
            
            List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
            
            for (Grid_Contact__c con : matchedContacts) {
                if (String.isBlank(con.Email__c)) continue;
                
                String contactEmail = con.Email__c.trim().toLowerCase();
                
                if (contactEmail == recipientEmail) {
                    Boolean updated = false;
                    
                    if (threadId.equals(String.valueOf(con.Email1_Thread_Id__c).trim())) {
                        con.Email_1__c = 'Email Responded';
                        updated = true;
                    } else if (threadId.equals(String.valueOf(con.Email2_Thread_Id__c).trim())) {
                        con.Email_2__c = 'Email Responded';
                        updated = true;
                    }
                    
                    if (updated) {
                        contactsToUpdate.add(con);
                    }
                }
            }
            
            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
            }
            
        } catch (Exception e) {
            System.debug('Error in handleEmailReceived: ' + e.getMessage());
        }
    }
    
    public static void handleEmailSent(Map<String, Object> payload) {
        try {
            List<Object> toAttendeesRaw = (List<Object>) payload.get('to_attendees');
            Set<String> normalizedRecipientEmails = new Set<String>();
            
            if (toAttendeesRaw != null) {
                for (Object o : toAttendeesRaw) {
                    Map<String, Object> attendee = (Map<String, Object>) o;
                    String recipientEmail = (String) attendee.get('identifier');
                    if (!String.isBlank(recipientEmail)) {
                        normalizedRecipientEmails.add(recipientEmail.trim().toLowerCase());
                    }
                }
            }
            
            String threadId = ((String) payload.get('thread_id')).trim();
            
            if (normalizedRecipientEmails.isEmpty() || String.isBlank(threadId)) {
                System.debug('No recipient emails or thread_id found.');
                return;
            }
            
            List<Grid_Contact__c> matchedContacts = [
                SELECT Id, Email__c, Email1_Tracking_Id__c, Email2_Tracking_Id__c,
                Email1_Thread_Id__c, Email2_Thread_Id__c, Email_1__c, Email_2__c
                FROM Grid_Contact__c
                WHERE Email__c != null
            ];
            
            List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
            
            for (Grid_Contact__c con : matchedContacts) {
                if (con.Email__c == null) continue;
                
                String normalizedContactEmail = con.Email__c.trim().toLowerCase();
                
                if (normalizedRecipientEmails.contains(normalizedContactEmail)) {
                    Boolean updated = false;
                    
                    if (String.isBlank(con.Email1_Thread_Id__c) && String.isBlank(con.Email2_Thread_Id__c)) {
                        con.Email1_Thread_Id__c = threadId;
                        con.Email_1__c = 'Email Sent';
                        updated = true;
                    } else if (!String.isBlank(con.Email1_Thread_Id__c) && String.isBlank(con.Email2_Thread_Id__c)) {
                        con.Email2_Thread_Id__c = threadId;
                        con.Email_2__c = 'Email Sent';
                        updated = true;
                    }
                    
                    if (updated) {
                        contactsToUpdate.add(con);
                    }
                }
            }
            
            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
                System.debug('Updated contacts with Email Sent.');
            } else {
                System.debug('No contacts needed update for Email Sent.');
            }
            
        } catch (Exception e) {
            System.debug('Error in handleMessageSent: ' + e.getMessage());
        }
    }
    
    
    public static void handleEmailOpened(Map<String, Object> payload) {
        try {
            String rawTrackingId = (String) payload.get('tracking_id');
            if (String.isBlank(rawTrackingId)) {
                System.debug('No tracking_id found in payload.');
                return;
            }
            String trackingId = rawTrackingId.trim().toLowerCase();
            
            List<Grid_Contact__c> matchedContacts = [
                SELECT Id, Email__c, Email1_Tracking_Id__c, Email2_Tracking_Id__c,
                Email1_Thread_Id__c, Email2_Thread_Id__c, Email_1__c, Email_2__c
                FROM Grid_Contact__c
                WHERE Email1_Tracking_Id__c = :trackingId
                OR Email2_Tracking_Id__c = :trackingId
            ];
            
            List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
            for (Grid_Contact__c con : matchedContacts) {
                Boolean updated = false;
                if (con.Email1_Tracking_Id__c != null && con.Email1_Tracking_Id__c.trim().toLowerCase() == trackingId && con.Email_1__c == 'Email Sent') {
                    con.Email_1__c = 'Email Read';
                    updated = true;
                } else if (con.Email2_Tracking_Id__c != null && con.Email2_Tracking_Id__c.trim().toLowerCase() == trackingId && con.Email_2__c == 'Email Sent') {
                    con.Email_2__c = 'Email Read';
                    updated = true;
                }
                
                if (updated) {
                    contactsToUpdate.add(con);
                }
            }
            
            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
                System.debug('Updated contacts with Email Opened status.');
            } else {
                System.debug('No matching contacts found for tracking ID: ' + trackingId);
            }
            
        } catch (Exception e) {
            System.debug('Error in handleEmailOpened: ' + e.getMessage());
        }
    }
    
}