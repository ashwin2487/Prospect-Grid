public with sharing class UserInfoController {
    @AuraEnabled(cacheable=true)
    public static User getUserDetails() {
        return [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
    }
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserName() {
        return [SELECT Name FROM User WHERE Id = :UserInfo.getUserId()].Name;
    }
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = TRUE ORDER BY Name];
    }
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserId() {
        return UserInfo.getUserId();
    }
}