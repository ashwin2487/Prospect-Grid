@isTest
public class RetrieveChatStatusBatchTest {

    @testSetup
    static void testData(){
        
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                LastName = 'Test ' + i,
                LinkedIn_Chat_Id__c = 'W3dHzbeNVfys2lJ6XzPMk'+i,
                LM1_TimeStamp__c = '2025-04-01 12:00:00',
                LM2_TimeStamp__c = '2025-04-03 12:00:00',
                LinkedIn_Message_1__c = 'Message Sent',
                LinkedIn_Message_2__c = 'Message Sent'
            ));
        }
        insert contacts;
    }
    
    @isTest
    static void testBatchExecution() {
        
        HttpResponse res = new HttpResponse();
       	res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
		res.setBody('{' +
                '"lastMessage": {' +
                '"seen": 1,' +
                '"seen_by": {' +
                '"SELF": "2025-04-06T12:00:00Z"' +
                '}' +
                '}' +
                '}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));

        Test.startTest();
        RetrieveChatStatusBatch batch = new RetrieveChatStatusBatch();
        Database.executeBatch(batch, 5); 
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT LinkedIn_Message_1__c, LinkedIn_Message_2__c FROM Contact];
        for (Contact con : updatedContacts) {
            System.assertEquals('Message Read', con.LinkedIn_Message_1__c);
            System.assertEquals('Message Read', con.LinkedIn_Message_2__c);
        }
    }
	
    @isTest
    static void testBatchExecutionOnlyMessage1Read() {
        
        HttpResponse res = new HttpResponse();
       	res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
		res.setBody('{' +
                '"lastMessage": {' +
                '"seen": 1,' +
                '"seen_by": {' +
                '"SELF": "2025-04-02T12:00:00Z"' +
                '}' +
                '}' +
                '}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(res));

        Test.startTest();
        RetrieveChatStatusBatch batch = new RetrieveChatStatusBatch();
        Database.executeBatch(batch, 5); 
        Test.stopTest();

        List<Contact> updatedContacts = [SELECT LinkedIn_Message_1__c, LinkedIn_Message_2__c FROM Contact];
        for (Contact con : updatedContacts) {
            System.assertEquals('Message Read', con.LinkedIn_Message_1__c);
            System.assertNotEquals('Message Read', con.LinkedIn_Message_2__c);
        }
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Scheduled Job', '0 0 12 * * ?', new RetrieveChatStatusBatch());
        System.assertNotEquals(null, jobId);
        Test.stopTest();
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        HttpResponse result;
        MockHttpResponseGenerator(HttpResponse res){
			result=res;            
        }
        public HTTPResponse respond(HTTPRequest req) {
            return result;
        }
    }
}