public with sharing class WorkingGridController {
    
    @AuraEnabled(cacheable=true)
    public static List<Grid__c> getGrids() {
        return [
            SELECT Id, Name, Outreach_Owner__c, Outreach_Owner__r.Name, 
            
            (SELECT Account__c, Account__r.Name FROM Grid_Accounts__r),
            (SELECT Contact__c, Contact__r.Name, Contact__r.Title, 
             Contact__r.Email, Contact__r.Phone, 
             Contact__r.LinkedIn_Profile__c,
             Contact__r.Contact_LinkedIn_Id__c,
             Contact__r.Contact_Outreach_Owner__c
             FROM Grid_Contacts__r)
            FROM Grid__c
        ];
    }
    
    @AuraEnabled
    public static List<Grid__c> getGridsByUser(List<String> outreachOwners) {
        return [
            SELECT Id, Name, Outreach_Owner__c, Outreach_Owner__r.Name
            FROM Grid__c WHERE Outreach_Owner__c IN :outreachOwners
        ];
    } 
    
    @AuraEnabled
    public static List<WrapperClass> getGridData(List<Id> gridIds) {
        List<WrapperClass> results = new List<WrapperClass>();
        Map<Id, String> accountMap = new Map<Id, String>();
        
        for (Grid_Account__c acc : [
            SELECT Id, Grid__c, Account__c, Account__r.Name 
            FROM Grid_Account__c
            WHERE Grid__c IN :gridIds
        ]) {
            accountMap.put(acc.Account__c, acc.Account__r.Name);
        }
        
        // Fetch Contacts associated with the multiple Grids
        List<Grid_Contact__c> gridContacts = [
            SELECT Id,
            Contact_Outreach_Owner__r.Name,
            AccountId__r.Name,
            Contact__r.AccountId,
            Call_Attempt_1__c,
            Call_Attempt_2__c,
            Call_Attempt_3__c,
            Call_Attempt_4__c,
            Call_Attempt_5__c,
            Contact__c,
            Contact_LinkedIn_Id__c,
            Contact_Outreach_Owner__c,
            Current_Location__c,
            Email__c,
            Email_1__c,
            Email_2__c,
            Email1_Message_Sent__c,
            Email1_Thread_Id__c,
            Email1_Tracking_Id__c,
            Email2_Thread_Id__c,
            Email2_Tracking_Id__c,
            FirstName__c,
            LastName__c,
            Grid__c,
            Languages__c,
            Level__c,
            LinkedIn_Chat_Id__c,
            LinkedIn_Connection_Status__c,
            LinkedIn_Invitation_Accepted_Date__c,
            LinkedIn_Invitation_Id__c,
            LinkedIn_Invitation_Sent_Date__c,
            LinkedIn_Message_1__c,
            LinkedIn_Message_2__c,
            LinkedIn_Message_Id__c,
            LinkedIn_Message_Received__c,
            LinkedIn_Message_Sent__c,
            LinkedIn_Profile__c,
            LinkedInURN__c,
            LM1_TimeStamp__c,
            LM2_TimeStamp__c,
            Name__c,
            Notes__c,
            Outcome__c,
            Phone__c,
            Public_Identifier__c,
            Title__c,
            Grid__r.CreatedDate
            FROM Grid_Contact__c
            WHERE Grid__c IN :gridIds
        ];
        
        // Map Contacts to Account Names and wrap in custom class
        for (Grid_Contact__c con : gridContacts) {
            String accountName = accountMap.containsKey(con.Contact__r.AccountId) 
                ? accountMap.get(con.Contact__r.AccountId) 
                : 'No Associated Account';
            results.add(new WrapperClass(accountName, con));
        }
        
        System.debug('Total Records Sent to LWC: ' + results.size());
        return results;
    }

    
    public class WrapperClass {
        @AuraEnabled public String accountName;
        @AuraEnabled public Grid_Contact__c contact;
        
        
        public WrapperClass(String accName,Grid_Contact__c contact) {
            this.accountName = accName;
            this.contact = contact;
        }
    }
    @AuraEnabled
    public static void updateGridOutreachOwner(String gridId, String newOwnerId) {
        try {
            Grid__c grid = [SELECT Id, Outreach_Owner__c FROM Grid__c WHERE Id = :gridId LIMIT 1];
            grid.Outreach_Owner__c = newOwnerId;
            update grid;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Grid Outreach Owner: ' + e.getMessage());
        }
    }
    
    @TestVisible
    private static String getLinkedInAccountId() {
        Id recordtypeid = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'LinkedIn_Account__c' and DeveloperName  = 'Linkedin'].Id;
        List<LinkedIn_Account__c> linkedInAccounts = [
            SELECT Account_ID__c FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() AND RecordTypeId =: recordtypeid LIMIT 1
        ];
        return linkedInAccounts.isEmpty() ? null : linkedInAccounts[0].Account_ID__c;
    }
    
    @AuraEnabled
    public static Map<String, String> sendLinkedInRequest(Id selectedContactId, String messageSent) {
        Map<String, String> result = new Map<String, String>();
        
        if (selectedContactId == null || String.isEmpty(messageSent)) {
            result.put('status', 'warning');
            result.put('message', 'Contact ID or message is missing.');
            return result;
        }
        
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isEmpty(linkedInAccountId)) {
            result.put('status', 'warning');
            result.put('message', 'LinkedIn Account ID is missing.');
            return result;
        }
        
        try {
            Grid_Contact__c currentRecord = [
                SELECT Id, Contact_LinkedIn_Id__c, LinkedIn_Connection_Status__c, 
                LinkedIn_Invitation_Id__c, Contact_Outreach_Owner__c
                FROM Grid_Contact__c
                WHERE Id = :selectedContactId
                LIMIT 1
            ];
            
            if (currentRecord.Contact_Outreach_Owner__c != UserInfo.getUserId()) {
                result.put('status', 'warning');
                result.put('message', 'You can only send invitations to contacts assigned to you.');
                return result;
            }
            
            if (String.isEmpty(currentRecord.Contact_LinkedIn_Id__c)) {
                result.put('status', 'warning');
                result.put('message', 'Contact LinkedIn ID is missing.');
                return result;
            }
            
            if (!String.isEmpty(currentRecord.LinkedIn_Invitation_Id__c)) {
                result.put('status', 'warning');
                result.put('message', 'An invitation has already been sent to this contact.');
                return result;
            }
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.sendLinkedinInviteURL);
            request.setTimeout(120000);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('Accept', 'application/json');
            request.setHeader('content-type', 'application/json');
            
            Map<String, String> payload = new Map<String, String>{
                'provider_id' => currentRecord.Contact_LinkedIn_Id__c,
                    'account_id' => linkedInAccountId,
                    'message' => messageSent
                    };
                        request.setBody(JSON.serialize(payload));
            
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            if (statusCode == 201) {
                String invitationId = (String) responseBody.get('invitation_id');
                if (!String.isEmpty(invitationId)) {
                    currentRecord.LinkedIn_Connection_Status__c = 'Invitation Sent';
                    currentRecord.LinkedIn_Invitation_Id__c = invitationId;
                    currentRecord.LinkedIn_Invitation_Sent_Date__c = System.today();
                    
                    try {
                        update currentRecord;
                    } catch (DmlException dmlEx) {
                        result.put('status', 'warning');
                        result.put('message', 'Failed to update contact: ' + dmlEx.getMessage());
                        return result;
                    }
                    
                    result.put('status', 'success');
                    result.put('message', 'LinkedIn invitation sent successfully.');
                    return result;
                } else {
                    result.put('status', 'warning');
                    result.put('message', 'Invitation ID missing in successful response.');
                    return result;
                }
            } else {
                
                String detailMessage = responseBody.containsKey('detail') 
                    ? (String)responseBody.get('detail') 
                    : 'Invitation not sent. Please try again later.';
                
                result.put('status', 'warning');
                result.put('message', detailMessage);
                return result;
            }
            
        } catch (Exception e) {
            result.put('status', 'warning');
            result.put('message', 'Unexpected error: ' + e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static List<Grid_Contact__c> getContactStatus(List<String> contactId) {
        try {
            if (!contactId.isEmpty()) {
                return [SELECT Id, Name__c,Email__c,Phone__c, LinkedIn_Connection_Status__c , LinkedIn_Message_1__c , LinkedIn_Message_2__c, Email_1__c, Email_2__c,
                        Outcome__c,Notes__c, Call_Attempt_1__c,Call_Attempt_2__c,Call_Attempt_3__c,Call_Attempt_4__c,Call_Attempt_5__c
                        FROM Grid_Contact__c
                        WHERE Id IN : contactId 
                        WITH SECURITY_ENFORCED];
            }
            return [SELECT Id, Name__c,Email__c,Phone__c, LinkedIn_Connection_Status__c , LinkedIn_Message_1__c , LinkedIn_Message_2__c, Email_1__c, Email_2__c,
                    Outcome__c,Notes__c, Call_Attempt_1__c,Call_Attempt_2__c,Call_Attempt_3__c,Call_Attempt_4__c,Call_Attempt_5__c
                    FROM Grid_Contact__c where Id = null
                    WITH SECURITY_ENFORCED];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching contact status: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateContactOutreachOwner(String contactId, String newOwnerId) {
        try {
            Grid_Contact__c contact = [SELECT Id, Contact_Outreach_Owner__c FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1 FOR UPDATE];
            contact.Contact_Outreach_Owner__c = newOwnerId;
            update contact;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Contact Outreach Owner: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Grid_Contact__c updateContactOutreachPhone(String contactId, String newPhoneNumber) {
        try {
            Grid_Contact__c contact = [SELECT Id, Phone__c FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1 FOR UPDATE];
            contact.Phone__c = newPhoneNumber;
            update contact;
            return contact;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating Contact Outreach Phone: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Grid_Contact__c updateContactOutreachEmail(String contactId, String newEmailId) {
        try {
            
            Grid_Contact__c gridContact = [SELECT Id, Email__c FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1 FOR UPDATE];
            gridContact.Email__c = newEmailId;
            
            update gridContact;
            
            return gridContact;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating contact email: ' + e.getMessage());
        }
    }
    
    public class ContactOwnerChangeWrapper {
        @AuraEnabled public Contact contact;
        @AuraEnabled public String accountName;
        
        public ContactOwnerChangeWrapper(Contact c) {
            this.contact = c;
            this.accountName = c.Account != null ? c.Account.Name : 'N/A';
        }
    }
    
    @AuraEnabled
    public static String SendLinkedInMessage1(Id contactId, String message, String subject) {
        if (contactId == null) {
            return 'Error: Contact ID is null';
        }
        
        try {
            String api = 'sales_navigator';
            Grid_Contact__c curCon = [
                SELECT Id, Name__c, Contact__r.Name, Contact_LinkedIn_Id__c, LinkedIn_Message_Content__c,
                LinkedIn_Message_1__c, LinkedIn_Chat_Id__c, LM1_TimeStamp__c
                FROM Grid_Contact__c
                WHERE Id = :contactId
            ];
            
            if (String.isEmpty(curCon.Contact_LinkedIn_Id__c)) {
                return 'Error: Contact does not have a LinkedIn ID';
            }
            
            String linkedInAccountId = getLinkedInAccountId();
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.label.sendLinkedInMessageURL);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.label.apiKeyUNipile);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            
            ChatRequest chatRequest = new ChatRequest(
                curCon.Contact_LinkedIn_Id__c,
                linkedInAccountId,
                message,
                subject
            );
            
            request.setBody(JSON.serialize(chatRequest));
            HttpResponse response = http.send(request);
            String responseBody = response.getBody();
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                
                if (responseMap.containsKey('chat_id') && responseMap.containsKey('message_id')) {
                    String chatId = String.valueOf(responseMap.get('chat_id'));
                    String messageId = String.valueOf(responseMap.get('message_id'));
                    
                    String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
                    String formattedMessage =
                        'LinkedIn Message 1 Subject (Sent: ' + timestamp + '): ' + subject + '\n' +
                        'LinkedIn Message 1 Content (Sent: ' + timestamp + '): ' + message;
                    
                    curCon.LinkedIn_Chat_Id__c = chatId;
                    curCon.LinkedIn_Message_Content__c = formattedMessage;
                    curCon.LinkedIn_Message_1__c = 'Message Sent';
                    curCon.LM1_TimeStamp__c = timestamp;
                    update curCon;                    
                    return 'Success: Message sent to ' + curCon.Name__c +
                        ' | Chat ID: ' + chatId +
                        ' | Message ID: ' + messageId;
                } else {
                    return 'Error: Unexpected response - ' + responseBody;
                }
            } else {
                return 'Error: ' + response.getStatusCode() + ' - ' + responseBody;
            }
        } catch (Exception e) {
            return 'Error: Exception occurred - ' + e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String SendLinkedInMessage2(Id contactId, String message, String subject) {
        if (contactId == null) {
            System.debug('LWC to Apex: Contact ID for sending message is null');
            return 'Error: Contact ID is null';
        }
        
        try {
            Grid_Contact__c curCon = [SELECT Id, Name__c, LinkedIn_Message_Content__c, LinkedIn_Invitation_Id__c, Contact_LinkedIn_Id__c , LinkedIn_Message_2__c,
                                      LinkedIn_Chat_Id__c 
                                      FROM Grid_Contact__c WHERE Id = :contactId];
            
            if (String.isEmpty(curCon.Contact_LinkedIn_Id__c)) {
                System.debug('LWC to Apex: Contact LinkedIn ID is missing');
                return 'Error: Contact does not have a LinkedIn ID';
            }
            
            String linkedInAccountId = getLinkedInAccountId();
            
            String LinkedInChatId=curCon.LinkedIn_Chat_Id__c;
            
            Http http = new Http();
            
            HttpRequest request = new HttpRequest();
            request.setTimeout(120000);
            request.setEndpoint(System.label.sendLinkedInMessageURL+'/'+LinkedInChatId+'/messages' );
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.label.apiKeyUNipile);
            request.setHeader('content-type', 'application/json');
            request.setHeader('Accept', 'application/json');
            
            ChatRequest chatRequest = new ChatRequest(
                curCon.Contact_LinkedIn_Id__c,
                linkedInAccountId,
                message,
                subject
            );
            
            String requestBody = JSON.serialize(chatRequest);
            request.setBody(requestBody);
            
            HttpResponse response = http.send(request);
            String responseBody = response.getBody();
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                System.debug('Success Response for LinkedIn Message 2: ' + responseBody);
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                
                if (responseMap != null && responseMap.containsKey('object') && responseMap.containsKey('message_id')) {
                    
                    String messageId = String.valueOf(responseMap.get('message_id'));
                    
                    String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
                    String formattedMessage = 
                        '\n\nLinkedIn Message 2 Subject (Sent: ' + timestamp + '): ' + subject + '\n' +
                        'LinkedIn Message 2 Content (Sent: ' + timestamp + '): ' + message;
                    
                    curCon.LinkedIn_Message_Id__c = messageId;
                    curCon.LinkedIn_Message_Content__c += formattedMessage;
                    curCon.LinkedIn_Message_2__c = 'Message Sent';
                    curCon.LM2_TimeStamp__c = timestamp;
                    
                    update curCon;
                    
                    return 'Success: Message sent to ' + curCon.Name__c + 
                        ' | Message ID: ' + messageId;
                } else {
                    return 'Error: Unexpected success response - ' + responseBody;
                }
            } else {
                System.debug('Error Response: ' + response.getStatusCode() + ' - ' + responseBody);
                return 'Error: ' + response.getStatusCode() + ' - ' + responseBody;
            }
        } catch (Exception e) {
            System.debug('Exception Occurred: ' + e.getMessage());
            return 'Error: Exception occurred - ' + e.getMessage();
        }
    }
    
    @AuraEnabled
    public static Grid_Contact__c updateContactNotes(Id contactId, String notes, String ExistNotes) {
        try{
            
            Grid_Contact__c contact = [SELECT Id, Notes__c FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1];
            
            String timestamp = '(' + Datetime.now().format('yyyy-MM-dd') + '): ';
            
            String existingNotes = ExistNotes;

            String updatedNotes;
            if (String.isNotBlank(notes)) {
                
                updatedNotes = String.isEmpty(existingNotes)
                    ? timestamp + notes
                    : existingNotes + '\n\n' + timestamp + notes;
                
            } else {
                updatedNotes = existingNotes;
            }
            contact.Notes__c = updatedNotes;
            
            update contact;
            
            return contact;
            
        }catch (Exception e) {
            throw new AuraHandledException('Error updating Contact Outreach Phone: ' + e.getMessage());
        } 
    }
    
    @AuraEnabled
    public static void updateOutcome(String contactId, String outcome) {
        try {
            // Step 1: Update the outcome on Grid_Contact__c
            Grid_Contact__c contactToUpdate = [
                SELECT Id, Outcome__c
                FROM Grid_Contact__c
                WHERE Id = :contactId
                LIMIT 1
            ];
            contactToUpdate.Outcome__c = outcome;
            update contactToUpdate;
            
            List<Lead> relatedLeads = [
                SELECT Id, Status
                FROM Lead
                WHERE Grid_Contact__c = :contactId
            ];
            
            for (Lead lead : relatedLeads) {
                lead.Status = outcome;
            }
            
            if (!relatedLeads.isEmpty()) {
                update relatedLeads;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    

    
    public class ChatRequest {
        public String attendees_ids;
        public String account_id;
        public String text;
        public String subject;
        public Map<String, Object> linkedin;
        
        public ChatRequest(String attendeesIds, String accountId, String messageText, String messageSubject) {
            this.attendees_ids = attendeesIds;
            this.account_id = accountId;
            this.text = messageText;
            this.subject = messageSubject;
            this.linkedin = new Map<String, Object>{
                'api' => 'sales_navigator',
                    'inmail' => true};
                        }
    }
    public class EmailRequest {
        public String account_id;
        public String subject;
        public String body;
        public Map<String, String> fromSender; // Temporary key name to avoid Apex conflict
        public List<Map<String, String>> to;
        
        public EmailRequest(String accountId, String emailSubject, String emailBody, Map<String, String> fromSender, List<Map<String, String>> toRecipients) {
            this.account_id = accountId;
            this.subject = emailSubject;
            this.body = emailBody;
            this.fromSender = fromSender; // Temporary variable
            this.to = toRecipients;
        }
    }
    
    public static void sendEmail(String contactId, String subject, String message) {
        String endpointUrl = System.Label.sendingEmailAPIEndPoint;
        String apiKey = System.Label.apiKeyUNipile;
        String linkedInAccountId = getLinkedInAccountId();
        if (linkedInAccountId == null) return;
        
        Contact curCon = [SELECT Id, Name, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('X-API-KEY', apiKey);
        
        // Define the sender (from)
        Map<String, String> fromSender = new Map<String, String>{
            'display_name' => 'HyperLink Infosystem',
                'identifier' => 'ashwinh.hyperlinkinfosystem@gmail.com'
                };
                    
                    // Define 'to' and 'cc' recipient lists
                    List<Map<String, String>> toRecipients = new List<Map<String, String>>{
                        new Map<String, String>{ 'display_name' => curCon.Name, 'identifier' => curCon.Email }
                    };
                        
                        // Create the email request object
                        EmailRequest emailReq = new EmailRequest(
                            linkedInAccountId,
                            subject,
                            message,
                            fromSender,
                            toRecipients
                        );
        
        // Convert to JSON and rename "fromSender" to "from"
        String requestBody = JSON.serialize(emailReq);
        requestBody = requestBody.replace('"fromSender":', '"from":');
        
        req.setBody(requestBody);
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        } catch (CalloutException e) {
            System.debug('HTTP Callout Exception: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void saveCallAttemptOutcome(Id contactId, Integer attemptNumber, String outcome) {
        try {
            Grid_Contact__c contactToUpdate = [SELECT Id, Call_Attempt_1__c, Call_Attempt_2__c, Call_Attempt_3__c, 
                                               Call_Attempt_4__c, Call_Attempt_5__c 
                                               FROM Grid_Contact__c WHERE Id = :contactId LIMIT 1];
            
            // Dynamically set the corresponding call attempt field
            if (attemptNumber == 1) {
                contactToUpdate.Call_Attempt_1__c = outcome;
            } else if (attemptNumber == 2) {
                contactToUpdate.Call_Attempt_2__c = outcome;
            } else if (attemptNumber == 3) {
                contactToUpdate.Call_Attempt_3__c = outcome;
            } else if (attemptNumber == 4) {
                contactToUpdate.Call_Attempt_4__c = outcome;
            } else if (attemptNumber == 5) {
                contactToUpdate.Call_Attempt_5__c = outcome;
            }
            
            update contactToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving call attempt: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Map<String, Object>> searchContactsApex(String firstName, String lastName, String companyName) {
        List<Map<String, Object>> extractedContacts = new List<Map<String, Object>>();
        Integer searchLimit = 100;
        if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(companyName)) {
            throw new AuraHandledException('Error: First Name, Last Name, and Company Name are required for search.');
        }
        

        List<Grid_Contact__c> existingContacts = [
            SELECT Id, Name__c, FirstName__c, LastName__c, 
                   Current_Location__c, LinkedIn_Profile__c, Title__c,
                   Contact_LinkedIn_Id__c, LinkedInURN__c, Public_Identifier__c,
                   Current_Company_Name__c, AccountId__r.Name
            FROM Grid_Contact__c 
            WHERE FirstName__c = :firstName.trim() 
            AND LastName__c = :lastName.trim() 
            AND AccountId__r.Name = :companyName.trim()
        ];

        if (!existingContacts.isEmpty()) {
            for (Grid_Contact__c contact : existingContacts) {
                Map<String, Object> contactMap = new Map<String, Object>();
                contactMap.put('LinkedIn_URN', contact.LinkedInURN__c);
                contactMap.put('Contact_LinkedIn_Id__c', contact.Contact_LinkedIn_Id__c);
                contactMap.put('name', contact.Name__c);
                contactMap.put('firstName', contact.FirstName__c);
                contactMap.put('lastName', contact.LastName__c);
                contactMap.put('location', contact.Current_Location__c);
                contactMap.put('profile_url', contact.LinkedIn_Profile__c);
                contactMap.put('Public_Identifier', contact.Public_Identifier__c);
                contactMap.put('currentPosition', contact.Title__c);
                contactMap.put('company', contact.Current_Company_Name__c);
                extractedContacts.add(contactMap);
            }
            
            return extractedContacts;
        }
        
        
        String linkedInAccountId = getLinkedInAccountId();
        String baseUrl = System.Label.searchContactsEndPoint;
        String apiUrl = baseUrl + '?limit=' + searchLimit + '&account_id=' + linkedInAccountId;
        String apiKey = System.Label.apiKeyUNipile;
        String companyId = searchCompanyOnLinkedIn(companyName, linkedInAccountId, apiKey);
        if (String.isBlank(companyId)) {
            throw new AuraHandledException('Please enter a valid company name.');
        }
        
        try {
            Map<String, Object> requestBodyMap = new Map<String, Object>{
                'api' => 'sales_navigator',
                    'category' => 'people',
                    'first_name' => firstName,
                    'last_name' => lastName,
                    'company' => new Map<String, Object>{
                        'include' => new List<String>{companyId}
                    }
            };
                
                String requestBody = JSON.serialize(requestBodyMap);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('POST');
            req.setHeader('X-API-KEY', apiKey);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(requestBody);
            Http http = new Http();
            HttpResponse res;
            
            try {
                res = http.send(req);
            } catch (Exception calloutEx) {
                throw new AuraHandledException('Callout Error: ' + calloutEx.getMessage());
            }
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                if (responseMap.containsKey('items')) {
                    List<Object> contactDetailsList = (List<Object>) responseMap.get('items');
                    
                    for (Object obj : contactDetailsList) {
                        Map<String, Object> contact = (Map<String, Object>) obj;
                        if (contact != null) {
                            Map<String, Object> contactMap = new Map<String, Object>();
                            contactMap.put('LinkedIn_URN', contact.get('member_urn'));
                            contactMap.put('Contact_LinkedIn_Id__c', contact.get('id'));
                            contactMap.put('name', contact.get('name'));
                            contactMap.put('firstName', contact.get('first_name'));
                            contactMap.put('lastName', contact.get('last_name'));
                            contactMap.put('location', contact.get('location'));
                            contactMap.put('profile_url', contact.get('public_profile_url'));
                            contactMap.put('Public_Identifier', contact.get('public_identifier'));
                            List<Object> positions = (List<Object>) contact.get('current_positions');
                            if (!positions.isEmpty()) {
                                Map<String, Object> firstPosition = (Map<String, Object>) positions[0];
                                contactMap.put('currentPosition', firstPosition.get('role'));
                                contactMap.put('company', firstPosition.get('company'));
                                contactMap.put('companyId', firstPosition.get('company_id'));
                            } else {
                                contactMap.put('currentPosition', 'N/A');
                                contactMap.put('company', 'N/A');
                                contactMap.put('companyId', 'N/A');
                            }
                            extractedContacts.add(contactMap);
                        }
                    }
                }
            } else {
                System.debug('LinkedIn API Error Response: ' + res.getBody());
                throw new AuraHandledException('LinkedIn API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error fetching contacts: ' + e.getMessage());
            throw new AuraHandledException('Error fetching contacts: ' + e.getMessage());
        }
        
        return extractedContacts;
    }
    private static String searchCompanyOnLinkedIn(String companyName, String linkedInAccountId, String apiKey) {
        String companySearchUrl = System.Label.companySearchEndPoint + '?limit=1&account_id=' + linkedInAccountId;
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'api' => 'sales_navigator',
                'category' => 'companies',
                'keywords' => companyName
                };
                    
                    String requestBodyJson = JSON.serialize(requestBody);
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(companySearchUrl);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', apiKey);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setBody(requestBodyJson);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (responseBody.containsKey('items') && !((List<Object>) responseBody.get('items')).isEmpty()) {
                    Map<String, Object> companyData = (Map<String, Object>) ((List<Object>) responseBody.get('items'))[0];
                    
                    return companyData.containsKey('id') ? (String) companyData.get('id') : null;
                }
            }
        } catch (Exception ex) {
            System.debug('Error searching for company: ' + ex.getMessage());
        }
        
        return null;
    }
    
    @AuraEnabled
    public static Contact createContact(
        String firstName, 
        String lastName, 
        String linkedinId, 
        String linkedinURN, 
        String profileUrl, 
        String companyName, 
        String location, 
        String currentPosition, 
        Id gridId,
        String publicIdentifier,
        String companyId
    ) {
        Id accountIdToUse;
        String BASE_URL = System.Label.retrieveCompanyDetailsEndPoint;
        String API_KEY = System.Label.apiKeyUNipile;
        
        String linkedInAccountId = getLinkedInAccountId();
        Map<String, Object> companyData;
        
        if (!String.isBlank(companyId)) {
            try {
                String url = BASE_URL + '/' + EncodingUtil.urlEncode(companyId, 'UTF-8') + '?account_id=' + linkedInAccountId;
                HttpRequest req = new HttpRequest();
                req.setEndpoint(url);
                req.setMethod('GET');
                req.setHeader('X-API-KEY', API_KEY);
                req.setHeader('Accept', 'application/json');
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    companyData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    String fetchedCompanyName = (String) companyData.get('name');
                    String fetchedProfileUrl = (String) companyData.get('profile_url');
                    
                    List<Account> matchedAccounts = [
                        SELECT Id 
                        FROM Account 
                        WHERE Name = :fetchedCompanyName 
                        OR LinkedIn_Profile__c = : fetchedProfileUrl
                        LIMIT 1
                    ];
                    
                    if (!matchedAccounts.isEmpty()) {
                        accountIdToUse = matchedAccounts[0].Id;
                        
                        // 🔗 Link existing account to grid
                        if (gridId != null) {
                            insert new Grid_Account__c(
                                Grid__c = gridId,
                                Account__c = accountIdToUse
                            );
                        }
                        
                    } else {
                        Account newAccount = new Account(
                            Name = fetchedCompanyName,
                            Description = (String) companyData.get('description'),
                            LinkedIn_Id__c = companyId,
                            LinkedIn_Profile__c = fetchedProfileUrl,
                            Website = (String) companyData.get('website'),
                            NumberOfEmployees = (companyData.get('employee_count') != null) 
                            ? Integer.valueOf(String.valueOf(companyData.get('employee_count')))
                            : null
                        );
                        insert newAccount;
                        accountIdToUse = newAccount.Id;
                        
                        // 🔗 Link new account to grid
                        if (gridId != null) {
                            insert new Grid_Account__c(
                                Grid__c = gridId,
                                Account__c = accountIdToUse
                            );
                        }
                    }
                } else {
                    System.debug('Company API call failed: ' + res.getStatusCode() + ' - ' + res.getBody());
                }
            } catch (Exception e) {
                System.debug('Exception during company API call: ' + e.getMessage());
            }
        }
        
        Contact newContact = new Contact(
            FirstName = firstName,
            LastName = lastName,
            AccountId = accountIdToUse,
            Title = currentPosition
        );
        
        insert newContact;
        
        if (gridId != null) {
            insert new Grid_Contact__c(
                Grid__c = gridId,
                Contact__c = newContact.Id,
                Name__c = newContact.FirstName+newContact.LastName,
                LinkedIn_Connection_Status__c = 'Not Connected',
                LinkedIn_Message_1__c = 'Not Sent',
                LinkedIn_Message_2__c = 'Not Sent',
                Email_1__c = 'Not Sent',
                Email_2__c = 'Not Sent',
                Contact_LinkedIn_Id__c = linkedinId,
                LinkedInURN__c = linkedinURN,
                LinkedIn_Profile__c = profileUrl,
                Current_Company_Name__c = companyName,
                Current_Location__c = location,
                Title__c = currentPosition,
                Public_Identifier__c = publicIdentifier,
                AccountId__c = accountIdToUse
            );
        }
        
        return newContact;
    }
    @AuraEnabled
    public static List<Grid_Contact__c> enrichContacts(String gridId) {
        List<Grid_Contact__c> currentGridContactList = new List<Grid_Contact__c>();
        List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
        
        // Check if the gridId is not blank
        if (String.isNotBlank(gridId)) {
            currentGridContactList = [
                SELECT Id, LinkedIn_Profile__c, Title__c, Name__c, FirstName__c, LastName__c, 
                Current_Company_Name__c, Current_Location__c, Cognism_Redeem_ID__c, Email__c, Phone__c
                FROM Grid_Contact__c 
                WHERE Grid__c = :gridId
            ];
        }
        
        // If we have contacts to process
        if (!currentGridContactList.isEmpty()) {
            String apiUrl = Label.cognismEnrichAPIURL;
            String token = Label.cognismAPITokenKey;
            
            Http http = new Http();
            
            for (Grid_Contact__c contact : currentGridContactList) {
                if (String.isNotBlank(contact.Email__c) && String.isNotBlank(contact.Phone__c)) {
                    continue;
                }
                
                Map<String, Object> requestBody = new Map<String, Object> {
                    'firstName' => contact.FirstName__c,
                        'lastName' => contact.LastName__c,
                        'location' => contact.Current_Location__c,
                        'title' => contact.Title__c,
                        'linkedinUrl' => contact.LinkedIn_Profile__c,
                        'companyName' => contact.Current_Company_Name__c
                        };
                            
                HttpRequest req = new HttpRequest();
                req.setEndpoint(apiUrl);
                req.setMethod('POST');
                req.setHeader('Authorization', 'Bearer ' + token);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(requestBody));
                
                try {
                    HttpResponse res = http.send(req);
                    if (res.getStatusCode() == 200 && String.isNotBlank(res.getBody())) {
                        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        if (parsed.containsKey('results')) {
                            List<Object> results = (List<Object>) parsed.get('results');
                            if (!results.isEmpty()) {
                                Map<String, Object> result = (Map<String, Object>) results[0];
                                if (result.containsKey('redeemId')) {
                                    String redeemId = (String) result.get('redeemId');
                                    contact.Cognism_Redeem_ID__c = redeemId;
                                    contactsToUpdate.add(contact);
                                }
                            }
                        }
                    } else {
                        String errorMsg = res.getStatusCode() == 401 ? 
                            'Unauthorized. Your Cognism redeem count might be over Or Please contact your System admin' :
                        'Enrichment failed. Status: ' + res.getStatusCode();
                        throw new AuraHandledException(errorMsg);
                    }
                } 
                catch (AuraHandledException ahe) {
                    throw ahe; 
                } 
                catch (Exception ex) {
                    System.debug('Callout error for contact ' + contact.Id + ': ' + ex.getMessage());
                }

            }
            
            if (!contactsToUpdate.isEmpty()) {
                try {
                    update contactsToUpdate;
                } catch (DmlException dmlEx) {
                    System.debug('Failed to update contacts: ' + dmlEx.getMessage());
                }
            }
            return contactsToUpdate;
        }
        
        return null;
    }
    
    @AuraEnabled
    public static void enrichContactsWithEmailAndPhone(List<String> gridContactIds) {
        
        String apiToken = Label.cognismAPITokenKey;
        String apiUrl = Label.cognismRedeemAPIURL;
        
        if (gridContactIds == null || gridContactIds.isEmpty()) {
            return;
        }
        
        // Query all relevant contacts
        List<Grid_Contact__c> contactList = [
            SELECT Id, Email__c, Cognism_Redeem_ID__c, Phone__c
            FROM Grid_Contact__c
            WHERE Id IN :gridContactIds
        ];
        
        List<Grid_Contact__c> contactsToUpdate = new List<Grid_Contact__c>();
        
        for (Grid_Contact__c contact : contactList) {
            String redeemId = contact.Cognism_Redeem_ID__c;
            
            if (String.isNotBlank(redeemId)) {
                try {
                    // Prepare request body
                    Map<String, Object> requestBody = new Map<String, Object>();
                    requestBody.put('redeemIds', new List<String>{redeemId});
                    String jsonRequestBody = JSON.serialize(requestBody);
                    
                    // Set up HTTP request
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(apiUrl);
                    req.setMethod('POST');
                    req.setHeader('Authorization', 'Bearer ' + apiToken);
                    req.setHeader('Content-Type', 'application/json');
                    req.setBody(jsonRequestBody);
                    
                    Http http = new Http();
                    HttpResponse res = http.send(req);
                    
                    if (res.getStatusCode() == 200) {
                        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        List<Object> results = (List<Object>) responseBody.get('results');
                        
                        if (!results.isEmpty()) {
                            Map<String, Object> contactInfo = (Map<String, Object>) results[0];
                            
                            if (contactInfo.containsKey('email')) {
                                Map<String, Object> emailObj = (Map<String, Object>) contactInfo.get('email');
                                contact.Email__c = (String) emailObj.get('address');
                            }
                            
                            if (contactInfo.containsKey('mobilePhoneNumbers')) {
                                List<Object> phones = (List<Object>) contactInfo.get('mobilePhoneNumbers');
                                if (!phones.isEmpty()) {
                                    Map<String, Object> phoneObj = (Map<String, Object>) phones[0];
                                    contact.Phone__c = (String) phoneObj.get('number');
                                }
                            }
                            contact.isRedeemIdUsed__c=true;
                            
                            contactsToUpdate.add(contact);
                        }
                    } else {
                        System.debug('Error from API: ' + res.getStatusCode() + ' - ' + res.getBody());
                    }
                } catch (Exception e) {
                    System.debug('Exception for contact ' + contact.Id + ': ' + e.getMessage());
                }
            } else {
                System.debug('No Redeem ID for contact: ' + contact.Id);
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    
}