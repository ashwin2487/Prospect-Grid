global class cancelInvitationBatchApex implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, LinkedIn_Invitation_Sent_Date__c, LinkedIn_Connection_Status__c, LinkedIn_Invitation_Id__c 
            FROM Grid_Contact__c
            WHERE LinkedIn_Invitation_Sent_Date__c != NULL 
            AND LinkedIn_Invitation_Sent_Date__c <= :System.today().addDays(-30)
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Grid_Contact__c> contactList) {
        List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
        List<String> invitationIds = new List<String>();
        
        for (Grid_Contact__c con : contactList) {
            if (con.LinkedIn_Invitation_Id__c != null) {
                invitationIds.add(con.LinkedIn_Invitation_Id__c);
            }
            Grid_Contact__c curCon = new Grid_Contact__c(
                Id = con.Id,
                LinkedIn_Connection_Status__c = 'Cancelled Invitation',
                LinkedIn_Invitation_Sent_Date__c = null,
                LinkedIn_Invitation_Id__c = null
            );
            contactsToUpdate.add(curCon);
        }
        
        if (!invitationIds.isEmpty()) {
            cancelLinkedInInvitations(invitationIds);
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('LinkedIn Status Batch Completed');    
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new cancelInvitationBatchApex(), 100);
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
        String linkedInAccountId = getLinkedInAccountId();
        
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
                
                if (response.getStatusCode() != 200) {
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