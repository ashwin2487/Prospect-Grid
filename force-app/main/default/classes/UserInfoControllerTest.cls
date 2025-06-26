@isTest
public class UserInfoControllerTest {
    @testSetup
    static void setupTestData() {    
        // Creating a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'usert',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;
    }

    @isTest
    static void testGetUserDetails() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        System.runAs(testUser) {
            User currentUser = UserInfoController.getUserDetails();
            System.assertNotEquals(null, currentUser);
            System.assertEquals(testUser.Id, currentUser.Id, 'User Id should match the logged-in user');
        }
    }

    @isTest
    static void testGetCurrentUserName() {
        User testUser = [SELECT Id, Name FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        System.runAs(testUser) {
            String userName = UserInfoController.getCurrentUserName();
            System.assertNotEquals(null, userName, 'User name should not be null');
            System.assertEquals(testUser.Name, userName, 'The username should match the logged-in user');
        }
    }

    @isTest
    static void testGetUsers() {
        List<User> activeUsers = UserInfoController.getUsers();
        System.assert(activeUsers.size() > 0, 'There should be at least one active user returned');
    }
}