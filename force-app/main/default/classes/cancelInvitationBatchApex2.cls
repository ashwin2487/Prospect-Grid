global class cancelInvitationBatchApex2 implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    private Set<String> invitationIds;
    private String linkedInAccountId;

    public cancelInvitationBatchApex2(Set<String> invitationIds) {
        this.invitationIds = invitationIds;
        this.linkedInAccountId = getLinkedInAccountId();
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found. Skipping batch execution.');
            return Database.getQueryLocator([SELECT Id FROM Contact WHERE Id = null]);
        }

        return Database.getQueryLocator([
            SELECT Id, LinkedIn_Invitation_Id__c 
            FROM Contact 
            WHERE LinkedIn_Invitation_Id__c IN :invitationIds
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> contactList) {
        if (contactList.isEmpty()) return;

        List<String> batchInvitationIds = new List<String>();
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact con : contactList) {
            if (String.isNotBlank(con.LinkedIn_Invitation_Id__c)) {
                batchInvitationIds.add(con.LinkedIn_Invitation_Id__c);
            }
            Contact updatedContact = new Contact(
                Id = con.Id,
                LinkedIn_Connection_Status__c = 'Cancelled Invitation',
                LinkedIn_Invitation_Id__c = null
            );
            contactsToUpdate.add(updatedContact);
        }

        if (!batchInvitationIds.isEmpty()) {
            cancelLinkedInInvitations(batchInvitationIds);
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
            System.debug('Updated ' + contactsToUpdate.size() + ' contacts with status "Cancelled Invitation".');
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('LinkedIn Invitation Cancellation Batch Completed.');
    }

    private void cancelLinkedInInvitations(List<String> invitationIds) {
        Integer batchSize = 100;
        Integer totalInvites = invitationIds.size();

        for (Integer i = 0; i < totalInvites; i += batchSize) {
            List<String> chunk = new List<String>();
            
            for (Integer j = i; j < Math.min(i + batchSize, totalInvites); j++) {
                chunk.add(invitationIds[j]);
            }

            processInvitationChunk(chunk);
        }
    }

    private void processInvitationChunk(List<String> invitationChunk) {
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return;
        }

        for (String invitationId : invitationChunk) {
            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                String endpoint = System.Label.sendLinkedinInviteURL + '/sent/' + invitationId + '?account_id=' + linkedInAccountId;
                
                request.setEndpoint(endpoint);
                request.setMethod('DELETE');
                request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
                request.setHeader('Accept', 'application/json');
                
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    System.debug('Successfully canceled invitation: ' + invitationId);
                } else {
                    System.debug('Failed to cancel invitation. Status: ' + response.getStatusCode() + ', Response: ' + response.getBody());
                }
            } catch (Exception e) {
                System.debug('Error while canceling invitation: ' + e.getMessage());
            }
        }
    }

    private static String getLinkedInAccountId() {
        List<LinkedIn_Account__c> linkedInAccounts = [
            SELECT Account_ID__c FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() LIMIT 1
        ];
        return linkedInAccounts.isEmpty() ? null : linkedInAccounts[0].Account_ID__c;
    }
}