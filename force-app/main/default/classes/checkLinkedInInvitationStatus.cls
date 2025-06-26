global class checkLinkedInInvitationStatus implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name__c , Contact_LinkedIn_Id__c, LinkedIn_Profile__c, Public_Identifier__c, 
                   LinkedIn_Invitation_Sent_Date__c, LinkedIn_Connection_Status__c, 
                   LinkedIn_Invitation_Id__c , LinkedIn_Invitation_Accepted_Date__c
            FROM Grid_Contact__c 
            WHERE Contact_LinkedIn_Id__c != NULL
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Grid_Contact__c> contactList) {
        if (contactList.isEmpty()) return;

        Map<String, Grid_Contact__c> contactMap = new Map<String, Grid_Contact__c>();
        for (Grid_Contact__c con : contactList) {
            if (String.isNotBlank(con.Public_Identifier__c)) {
                contactMap.put(con.Public_Identifier__c, con);
            }
        }

        if (contactMap.isEmpty()) return;

        String linkedInAccountId = getLinkedInAccountId();
        if (linkedInAccountId == null) {
            System.debug('No LinkedIn Account found for the current user.');
            return;
        }

        HttpRequest initialRequest = createHttpRequest(linkedInAccountId);
        List<Map<String, Object>> apiResults = executeApiRequests(new List<HttpRequest>{ initialRequest }, linkedInAccountId);

        List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();

        for (Map<String, Object> relation : apiResults) {
            String publicIdentifier = (String) relation.get('public_identifier');
            if (contactMap.containsKey(publicIdentifier)) {
                Grid_Contact__c con = contactMap.get(publicIdentifier);
                con.LinkedIn_Connection_Status__c = 'Connected';
                con.LinkedIn_Invitation_Accepted_Date__c = Date.today();
                contactsToUpdate.add(con);
                System.debug('Updating contact: ' + con.Name + ' with LinkedIn ID: ' + publicIdentifier);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            try {
                update contactsToUpdate;
                System.debug('Updated ' + contactsToUpdate.size() + ' contacts.');
            } catch (Exception e) {
                System.debug('Failed to update contacts: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('LinkedIn Status Batch Completed');
    }

    private static String getLinkedInAccountId() {
        try {
            List<LinkedIn_Account__c> accounts = [
                SELECT Account_ID__c 
                FROM LinkedIn_Account__c 
                WHERE User_Name__c = :UserInfo.getName() 
                LIMIT 1
            ];
            return accounts.isEmpty() ? null : accounts[0].Account_ID__c;
        } catch (Exception e) {
            System.debug('Error fetching LinkedIn Account: ' + e.getMessage());
            return null;
        }
    }

    private static HttpRequest createHttpRequest(String linkedInAccountId) {
        String endpoint = System.Label.listOfRelationsEndPoint + '?limit=100&account_id=' + linkedInAccountId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }

    private static HttpRequest createNextPageRequest(String cursor, String linkedInAccountId) {
        String endpoint = System.Label.listOfRelationsEndPoint + '?cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8') + '&limit=100&account_id=' + linkedInAccountId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }

    private static List<Map<String, Object>> executeApiRequests(List<HttpRequest> requests, String linkedInAccountId) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        Http http = new Http();

        for (HttpRequest req : requests) {
            while (req != null) {
                try {
                    HttpResponse res = http.send(req);
                    if (res.getStatusCode() == 200) {
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                        if ((String) responseMap.get('object') == 'UserRelationsList') {
                            List<Object> items = (List<Object>) responseMap.get('items');
                            if (items != null) {
                                for (Object item : items) {
                                    if (item instanceof Map<String, Object>) {
                                        resultList.add((Map<String, Object>) item);
                                    }
                                }
                            }
                        }

                        String cursor = (String) responseMap.get('cursor');
                        req = (cursor != null) ? createNextPageRequest(cursor, linkedInAccountId) : null;
                    } else {
                        System.debug('API call failed: ' + res.getStatusCode() + ' - ' + res.getBody());
                        req = null;
                    }
                } catch (CalloutException e) {
                    System.debug('CalloutException: ' + e.getMessage());
                    req = null;
                }
            }
        }

        return resultList;
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new checkLinkedInInvitationStatus(), 100);
    }
}