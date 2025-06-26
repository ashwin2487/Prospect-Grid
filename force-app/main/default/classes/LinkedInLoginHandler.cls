public class LinkedInLoginHandler implements Schedulable, Database.AllowsCallouts {

    public void execute(SchedulableContext sc) {
        String LinkedinAccID = getLinkedInAccountId();
        
        if (LinkedinAccID!=null) {
            getLinkedAccountStatus();
        }
    }
    
    public static String getLinkedInAccountId() {
        Id currentUserId = UserInfo.getUserId();
        
        List<LinkedIn_Account__c> linkedinAccounts = [
            SELECT Account_ID__c 
            FROM LinkedIn_Account__c 
            WHERE OwnerId = :currentUserId
            LIMIT 1
        ];
        
        if (linkedinAccounts.isEmpty()) {
            return null;
        }
        
        return linkedinAccounts[0].Account_ID__c;
    }
    
    public static void getLinkedAccountStatus() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(System.Label.getUnipileAccountURL+'/'+getLinkedInAccountId() );
        request.setMethod('GET');
        request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        request.setHeader('accept', 'application/json');
        
        try {
            HttpResponse response = http.send(request);
            System.debug('Response Status: ' + response.getStatus());
            System.debug('Response Body: ' + response.getBody());
            
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            List<Object> sources = (List<Object>) resultMap.get('sources');
        
            if (sources != null && !sources.isEmpty()) {

                Map<String, Object> firstSource = (Map<String, Object>) sources[0];
                String status = (String) firstSource.get('status');
                
                System.debug('Status: ' + status);
                
                if(status!=null && status=='OK'){
                    
                    Id currentUserId = UserInfo.getUserId();
                    List<LinkedIn_Account__c> accounts = [
                        SELECT Id, Account_ID__c 
                        FROM LinkedIn_Account__c 
                        WHERE OwnerId = :currentUserId
                        LIMIT 1
                    ];
                    
                    if (!accounts.isEmpty()) {
                        LinkedIn_Account__c accountRecord = accounts[0];
                        accountRecord.Connection_Status__c = 'OK';
                        update accountRecord;
                    }
                }
                
                
            } else {
                
                Id currentUserId = UserInfo.getUserId();
                    List<LinkedIn_Account__c> accounts = [
                        SELECT Id, Account_ID__c 
                        FROM LinkedIn_Account__c 
                        WHERE OwnerId = :currentUserId
                        LIMIT 1
                    ];
                    
                    if (!accounts.isEmpty()) {
                        LinkedIn_Account__c accountRecord = accounts[0];
                        accountRecord.Connection_Status__c = 'RECONNECTING';
                        update accountRecord;
                    }
            }
                
        } catch(Exception ex) {
            System.debug('Exception during callout: ' + ex.getMessage());
        }
    }
    
}