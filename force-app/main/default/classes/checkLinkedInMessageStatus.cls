global class checkLinkedInMessageStatus implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name__c, Contact_LinkedIn_Id__c, LinkedIn_Profile__c,Public_Identifier__c, LinkedIn_Invitation_Sent_Date__c, LinkedIn_Connection_Status__c, LinkedIn_Invitation_Id__c , LinkedIn_Invitation_Accepted_Date__c
            FROM Grid_Contact__c WHERE Contact_LinkedIn_Id__c != NULL
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Grid_Contact__c> contactList) {
        if (contactList.isEmpty()) return;
        
        List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
        Map<String, Grid_Contact__c> contactMap = new Map<String, Grid_Contact__c>();
        
        for (Grid_Contact__c con : contactList) {
            contactMap.put(con.Contact_LinkedIn_Id__c, con);
        }
        
        String linkedInAccountId = getLinkedInAccountId();
        if (linkedInAccountId == null) return;
        HttpRequest request = createHttpRequest(contactMap, linkedInAccountId);
        List<String> encodedAttendees = new List<String>();
        for (String attendee : contactMap.keySet()) {
            encodedAttendees.add(EncodingUtil.urlEncode(attendee, 'UTF-8'));
        }
        
        String chatAttendees = String.join(encodedAttendees, ',');
        Datetime tomorrowUtc = Datetime.newInstance(System.today().addDays(1), Time.newInstance(12, 0, 0, 0));
        String formattedDate = EncodingUtil.urlEncode(tomorrowUtc.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), 'UTF-8');
        List<Map<String, Object>> contactDetails = executeApiRequests(new List<HttpRequest>{request}, linkedInAccountId, chatAttendees, formattedDate);
        
        if (!contactDetails.isEmpty()) {
            for (Map<String, Object> contactInfo : contactDetails) {
                String searchkey = (String) contactInfo.get('public_identifier');
                System.debug('public_identifier is: ' + searchkey);
                if (contactMap.containsKey(searchkey)) {
                    Grid_Contact__c con = contactMap.get(searchkey);
                    con.LinkedIn_Connection_Status__c = 'Connected';
                    con.LinkedIn_Invitation_Accepted_Date__c = Date.today();
                    System.debug('Public profile URL is: ' + searchkey + ' for contact ' + con.Name);
                    contactsToUpdate.add(con);
                }
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('LinkedIn Status Batch Completed');    
    }
    
    private static String getLinkedInAccountId() {
        try {
            List<LinkedIn_Account__c> linkedInAccList = [
                SELECT Account_ID__c FROM LinkedIn_Account__c 
                WHERE User_Name__c = :System.UserInfo.getName() LIMIT 1
            ];
            return (!linkedInAccList.isEmpty()) ? linkedInAccList[0].Account_ID__c : null;
        } catch (Exception e) {
            System.debug('Error fetching LinkedIn Account: ' + e.getMessage());
            return null;
        }
    }
    
    private static HttpRequest createHttpRequest(Map<String, Grid_Contact__c> contactMap, String linkedInAccountId) {
        List<String> encodedAttendees = new List<String>();
        for (String attendee : contactMap.keySet()) {
            encodedAttendees.add(EncodingUtil.urlEncode(attendee, 'UTF-8'));
        }
        
        String chatAttendees = String.join(encodedAttendees, ',');
        Datetime tomorrowUtc = Datetime.newInstance(System.today().addDays(1), Time.newInstance(12, 0, 0, 0));
        String formattedDate = EncodingUtil.urlEncode(tomorrowUtc.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), 'UTF-8');
        String baseUrl = System.Label.checkLinkedInmessageStatus + chatAttendees + '/chats?before=' + formattedDate + '&limit=100&account_id=' + linkedInAccountId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl);
        req.setMethod('GET');
        req.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        return req;
    }
    
  private static List<Map<String, Object>> executeApiRequests(List<HttpRequest> requests, String linkedInAccountId, String chatAttendees, String formattedDate) {
    List<Map<String, Object>> chatDetailsList = new List<Map<String, Object>>();
    Http http = new Http();

    for (HttpRequest req : requests) {
        while (req != null) {
            try {
                HttpResponse response = http.send(req);
                System.debug('API Response: ' + response.getBody());
                System.debug('API Status Code: ' + response.getStatusCode());

                if (response.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (responseMap.containsKey('object') && responseMap.get('object') == 'ChatList') {
                        if (responseMap.containsKey('items') && responseMap.get('items') instanceof List<Object>) {
                            for (Object obj : (List<Object>) responseMap.get('items')) {
                                if (obj instanceof Map<String, Object>) {
                                    Map<String, Object> chatData = (Map<String, Object>) obj;
                                    Map<String, Object> extractedData = new Map<String, Object>{
                                        'unread' => chatData.containsKey('unread') ? chatData.get('unread') : null,
                                        'archived' => chatData.containsKey('archived') ? chatData.get('archived') : null,
                                        'read_only' => chatData.containsKey('read_only') ? chatData.get('read_only') : null,
                                        'attendee_provider_id' => chatData.containsKey('attendee_provider_id') ? chatData.get('attendee_provider_id') : null,
                                     	'unread_count'  => chatData.containsKey('unread_count') ? chatData.get('unread_count') : null
                                    };

                                    chatDetailsList.add(extractedData);
                                } else {
                                    System.debug('Skipping non-map object in items: ' + obj);
                                }
                            }
                        } else {
                            System.debug('No valid "items" in API response or incorrect type.');
                        }
                    } else {
                        System.debug('Invalid API response: Expected "ChatList" but received: ' + responseMap.get('object'));
                    }
                    String cursor = (String) responseMap.get('cursor');

                    if (cursor != null) {
                        System.debug('Fetching next page with cursor: ' + cursor);
                        req = createNextPageRequest(cursor, linkedInAccountId, chatAttendees, formattedDate);
                    } else {
                        req = null;
                    }
                } else {
                    System.debug('Request failed: ' + response.getStatusCode() + ' - ' + response.getBody());
                    req = null;
                }
            } catch (CalloutException e) {
                System.debug('HTTP Callout Exception: ' + e.getMessage());
                System.debug('StackTrace: ' + e.getStackTraceString());
                req = null;
            }
        }
    }
    return chatDetailsList;
}
    
    private static HttpRequest createNextPageRequest(String cursor, String linkedInAccountId, String chatAttendees, String formattedDate) {
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return null;
        }
        
        if (String.isBlank(chatAttendees) || String.isBlank(formattedDate)) {
            System.debug('Missing required parameters: chatAttendees or formattedDate.');
            return null;
        }
        String baseUrl = System.Label.checkLinkedInmessageStatus 
            + EncodingUtil.urlEncode(chatAttendees, 'UTF-8') 
            + '/chats?cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8') 
            + '&before=' + formattedDate 
            + '&limit=100&account_id=' + linkedInAccountId;
        HttpRequest nextRequest = new HttpRequest();
        nextRequest.setEndpoint(baseUrl);
        nextRequest.setMethod('GET');
        nextRequest.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        nextRequest.setHeader('Accept', 'application/json');
        nextRequest.setHeader('Content-Type', 'application/json');
        
        System.debug('Next Page Request URL: ' + baseUrl);
        
        return nextRequest;
    }
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new checkLinkedInMessageStatus(), 100);
    }   
}