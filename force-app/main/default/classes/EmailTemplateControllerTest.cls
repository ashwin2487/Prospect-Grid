@isTest
public class EmailTemplateControllerTest {
    
    static Id testTemplateId;
    static Id testUserId;
    static Id testContactId;
    static String testFolderId;
    
    @testSetup 
    static void setupTestData() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;
        testUserId = testUser.Id;

        EmailTemplate testTemplate = new EmailTemplate(
            Name = 'Test Email Template',
            DeveloperName = 'Test_Email_Template',
            Subject = 'Test Subject',
            HtmlValue = '<p>Test Email Body</p>',
            FolderId = UserInfo.getUserId(), 
            TemplateType = 'custom',
            IsActive = true
        );
        insert testTemplate;
        testTemplateId = testTemplate.Id;

        System.runAs(testUser) {
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                Email= 'testuser@example.com',
                Email_1__c = null,
	            Email_2__c = null
            );
            insert testContact;
            testContactId = testContact.Id;
        }
        List<Folder> existingFolder = [SELECT Id FROM Folder WHERE Type = 'Email'];
        testFolderId = String.valueOf(existingFolder[0].Id);
    }
    
    @isTest
    static void testGetEmailTemplates() {
        Test.startTest();
        List<EmailTemplate> templates = EmailTemplateController.getEmailTemplates();
        Test.stopTest();
        
        System.assertNotEquals(0, templates.size(), 'Email templates should be retrieved');
        System.assertEquals('Test Email Template', templates[0].Name, 'Template name should match');
    }
    
    private static Contact createTestContact() {
        Contact con = new Contact(
            LastName = 'Test',
            Email_1__c = '',
            Email_2__c = ''
        );
        insert con;
        return con;
    }
    
   	@isTest
    static void testSendEmailWithTemplate1() {
        // Create test contact
        Contact testCon = createTestContact();
        String testTemplateId = UserInfo.getUserId();  
        String testContactId = testCon.Id;
        
        User currUser = [SELECT Id FROM User LIMIT 1];
        System.runAs(currUser) {
            Test.startTest();
            EmailTemplateController.sendEmailWithTemplate1(
                'recipient@example.com',
                testTemplateId,
                testContactId,
                'Test Subject',
                'Test Message'
            );
            Contact updatedContact = [SELECT Email_1__c FROM Contact WHERE Id = :testContactId];
            System.assertEquals('Email Sent', updatedContact.Email_1__c, 'Email should be updated to "Email Sent"');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSendEmailWithTemplate2() {
        // Create test contact
        Contact testCon = createTestContact();
        String testTemplateId = UserInfo.getUserId();  // using current user's id as a placeholder
        String testContactId = testCon.Id;
        
        User currUser = [SELECT Id FROM User LIMIT 1];
        System.runAs(currUser) {
            Test.startTest();
            EmailTemplateController.sendEmailWithTemplate2(
                'recipient@example.com',
                testTemplateId,
                testContactId,
                'Test Subject',
                'Test Message'
            );
            Contact updatedContact = [SELECT Email_2__c FROM Contact WHERE Id = :testContactId];
            System.assertEquals('Email Sent', updatedContact.Email_2__c, 'Email should be updated to "Email Sent"');
            Test.stopTest();
        }
    }
    
    @isTest
	static void testSendEmailWithTemplate1_MissingRequiredParams() {
    User currUser = [SELECT Id FROM User LIMIT 1];
    System.runAs(currUser) {
        Test.startTest();
        try {
            EmailTemplateController.sendEmailWithTemplate1(
                '', 
                UserInfo.getUserId(), 
                '', 
                'Test Subject', 
                'Test Message'
            );
            // If the exception isn't thrown, fail the test.
            System.assert(false, 'Expected an exception for missing required parameters.');
        	} catch (AuraHandledException e) {
            	System.assert(e.getMessage().contains('Script-thrown exception'), 
                          'Exception should mention missing required parameters');
        	}
        	Test.stopTest();
    	}
	}
    
    @isTest
    static void testSendEmailWithTemplate2_MissingParameters() {
        User currUser = [SELECT Id FROM User LIMIT 1];
    	System.runAs(currUser) {
        Test.startTest();
        try {
            EmailTemplateController.sendEmailWithTemplate2(
                '', 
                UserInfo.getUserId(), 
                '', 
                'Test Subject', 
                'Test Message'
            );

            System.assert(false, 'Expected an exception for missing required parameters.');
        	} catch (AuraHandledException e) {
            	System.assert(e.getMessage().contains('Script-thrown exception'), 
                          'Exception should mention missing required parameters');
        	}
        	Test.stopTest();
    	}
    }
    
    @isTest
	static void testSendEmailWithTemplate1_InvalidContactId() {
    User currUser = [SELECT Id FROM User LIMIT 1];
    System.runAs(currUser) {
        Test.startTest();
        try {
            // Passing a contact ID that doesn't exist.
            EmailTemplateController.sendEmailWithTemplate1(
                'recipient@example.com',
                UserInfo.getUserId(),
                '003000000000000AAA', // Invalid Contact Id
                'Test Subject',
                'Test Message'
            );
            System.assert(false, 'Expected an exception for an invalid Contact ID.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 
                          'Exception should mention invalid contact ID');
        }
        Test.stopTest();
    }
}
    
    @isTest
    static void testSendEmailWithTemplate2_InvalidContactId() {
        User currUser = [SELECT Id FROM User LIMIT 1];
        System.runAs(currUser) {
            Test.startTest();
            try {
                EmailTemplateController.sendEmailWithTemplate2(
                    'recipient@example.com',
                    UserInfo.getUserId(),
                    '003000000000000AAA', 
                    'Test Subject',
                    'Test Message'
                );
                System.assert(false, 'Expected an exception for an invalid Contact ID.');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Script-thrown exception'), 
                              'Exception should mention invalid contact ID');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testSendEmailFailure() {
        Test.startTest();
        try {
            EmailTemplateController.sendEmailWithTemplate1(
                'recipient@example.com', 
                testTemplateId, 
                null, 
                'Test Subject', 
                'Test Message'
            );
            System.assert(false, 'Expected an exception for email sending failure.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmail2Failure() {
        Test.startTest();
        try {
            EmailTemplateController.sendEmailWithTemplate2(
                'recipient@example.com', 
                testTemplateId, 
                null, 
                'Test Subject', 
                'Test Message'
            );
            System.assert(false, 'Expected an exception for email sending failure.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEmailTemplateFolders() {
        Test.startTest();
        List<Folder> folders = EmailTemplateController.getEmailTemplateFolders();
        Test.stopTest();

        System.assertNotEquals(0, folders.size(), 'There should be at least one email template folder.');
    }
    
    @isTest
    static void testCreateEmailTemplate_Success() {
        
        Folder emailFolder = [SELECT Id, Name FROM Folder WHERE Type = 'Email' LIMIT 1];
        System.debug('Using Folder: ' + emailFolder.Name + ' (ID: ' + emailFolder.Id + ')');
        
        Test.startTest();
        String result = EmailTemplateController.createEmailTemplate(
            'Test Template 123',
            'Test_Template_123',
            'Test Subject',
            'This is a test email body.',
            emailFolder.Id
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The email template should be created successfully.');
        
        List<EmailTemplate> templates = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Test Template 123'];
        System.assertEquals(1, templates.size(), 'An email template should be created.');
    }

    @isTest
    static void testCreateEmailTemplate_InvalidFolder() {
        Test.startTest();
        try {
            EmailTemplateController.createEmailTemplate(
                'Invalid Template',
                'Invalid_Template_123',
                'Test Subject',
                'This is a test email body.',
                '00ldL00000A6yLVQAS'
            );
            System.assert(false, 'Expected an exception for an invalid folder ID.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message for invalid folder.');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateEmailTemplate_MissingParameters() {
        Test.startTest();
        try {
            EmailTemplateController.createEmailTemplate('', '', '', '', testFolderId);
            System.assert(false, 'Expected an exception for missing required fields.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected error message for missing fields.');
        }
        Test.stopTest();
    }
}