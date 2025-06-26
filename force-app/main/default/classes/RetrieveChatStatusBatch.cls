global class RetrieveChatStatusBatch implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, LinkedIn_Chat_Id__c, LM1_TimeStamp__c, LM2_TimeStamp__c, ' +
            'LinkedIn_Message_1__c, LinkedIn_Message_2__c, Attendee_Id__c, Email, Phone, Contact_LinkedIn_Id__c ' +
            'FROM Grid_Contact__c ' +
            'WHERE LinkedIn_Chat_Id__c != null ' +
            'AND LinkedIn_Message_1__c = \'Message Sent\' ' +
            'AND LinkedIn_Message_2__c = \'Message Sent\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Grid_Contact__c> scope) {
        List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
        Integer calloutLimit = Limits.getLimitCallouts();
        Integer calloutsMade = Limits.getCallouts();
        
        for (Grid_Contact__c con : scope) {
            if ((calloutsMade + 1) > calloutLimit) {
                System.debug('Callout limit approaching. Skipping remaining records.');
                break;
            }
            
            if (String.isNotBlank(con.Id) && String.isNotBlank(con.LinkedIn_Chat_Id__c)) {
                Grid_Contact__c result = retrieveChatMessages(con);
                calloutsMade = Limits.getCallouts();
                
                if (result != null) {
                    contactsToUpdate.add(result);
                }
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch completed successfully.');
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RetrieveChatStatusBatch(), 40);
    }
    
    private static Grid_Contact__c retrieveChatMessages(Grid_Contact__c con) {
        String baseUrl = System.Label.readChatsAPIEndPoint;
        String linkedInAccountId = getLinkedInAccountId();
        String formattedDate = Datetime.now().addDays(1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        Boolean hasMorePages = true;
        String cursorParam = '';
        
        while (hasMorePages) {
            HttpRequest req = new HttpRequest();
            String endpoint = baseUrl+
                cursorParam+ 
                '&before='+ formattedDate + 
                '&limit=100' +
                '&account_type=LINKEDIN' +
                '&account_id=' + linkedInAccountId;
            
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            req.setHeader('Accept', 'application/json');
            
            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                    List<Object> items = (List<Object>) resMap.get('items');
                    for (Object item : items) {
                        Map<String, Object> chat = (Map<String, Object>) item;
                        
                        String attendeeProviderId = (String) chat.get('attendee_provider_id');
                        String timestampStr = (String) chat.get('timestamp');
                        
                        if (attendeeProviderId == con.Contact_LinkedIn_Id__c && String.isNotBlank(timestampStr)) {
                            Datetime seenTime = Datetime.valueOfGmt(timestampStr.replace('T', ' ').replace('Z', ''));
                            
                            Datetime lm1 = tryParseDatetime(con.LM1_TimeStamp__c);
                            Datetime lm2 = tryParseDatetime(con.LM2_TimeStamp__c);
                            
                            Boolean updated = false;
                            if (lm2 != null && seenTime > lm2) {
                                con.LinkedIn_Message_1__c = 'Message Read';
                                con.LinkedIn_Message_2__c = 'Message Read';
                                updated = true;
                            } else if (lm1 != null && seenTime > lm1) {
                                con.LinkedIn_Message_1__c = 'Message Read';
                                updated = true;
                            }
                            
                            if (updated) {
                                return con;
                            }
                        }
                    }
                    if (resMap.containsKey('cursor') && resMap.get('cursor') != null) {
                        String encodedCursor = (String) resMap.get('cursor');
                        cursorParam = '&cursor=' + EncodingUtil.urlEncode(encodedCursor, 'UTF-8');
                    } else {
                        hasMorePages = false;
                    }
                } else {
                    hasMorePages = false;
                }
            } catch (Exception e) {
                hasMorePages = false;
                System.debug('Error while calling API: ' + e.getMessage());
            }
        }
        
        return null;
    }
    
    
    private static Datetime tryParseDatetime(String dtStr) {
        if (String.isNotBlank(dtStr) && dtStr.length() >= 19) {
            try {
                return Datetime.valueOfGmt(dtStr.substring(0, 19).replace('T', ' '));
            } catch (Exception e) {
                System.debug('Failed to parse timestamp: ' + dtStr);
            }
        }
        return null;
    }
    /* private Contact fetchAttendeeDetails(String chatId, Id contactId) {
try {
Http http = new Http();
HttpRequest req = new HttpRequest();
req.setEndpoint(System.Label.sendLinkedInMessageURL + '/' + EncodingUtil.urlEncode(chatId, 'UTF-8') + '/attendees');
req.setMethod('GET');
req.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
req.setHeader('Accept', 'application/json');

HttpResponse res = http.send(req);

if (res.getStatusCode() == 200) {
Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

if (responseMap.containsKey('items')) {
List<Object> items = (List<Object>) responseMap.get('items');
if (!items.isEmpty()) {
Map<String, Object> attendee = (Map<String, Object>) items[0];

String attendeeId = (String) attendee.get('id');
String email = null;
String phone = null;

if (attendee.containsKey('specifics')) {
Map<String, Object> specifics = (Map<String, Object>) attendee.get('specifics');
if (specifics.containsKey('contact_info')) {
Map<String, Object> contactInfo = (Map<String, Object>) specifics.get('contact_info');

List<Object> emails = contactInfo.containsKey('emails') ? (List<Object>) contactInfo.get('emails') : new List<Object>();
List<Object> phones = contactInfo.containsKey('phone_numbers') ? (List<Object>) contactInfo.get('phone_numbers') : new List<Object>();

email = !emails.isEmpty() ? (String) emails[0] : null;
phone = !phones.isEmpty() ? (String) phones[0] : null;
}
}

Contact conToUpdate = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
conToUpdate.Attendee_Id__c = attendeeId;
conToUpdate.Email = email;
conToUpdate.Phone = phone;
update conToUpdate;
return conToUpdate;
}
}
}
} catch (Exception ex) {
System.debug('Attendee details fetch exception: ' + ex.getMessage());
}
return null;
}*/
    
    private static String getLinkedInAccountId() {
        List<LinkedIn_Account__c> linkedInAccounts = [
            SELECT Account_ID__c FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() LIMIT 1
        ];
        return linkedInAccounts.isEmpty() ? null : linkedInAccounts[0].Account_ID__c;
    }
}