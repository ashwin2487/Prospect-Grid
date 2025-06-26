public class CognismRedeemController{
    
    @AuraEnabled
    public static String updateCognismRedeemRecord(String recordId, Integer newRedeemCount, String startDate, String endDate) {
        try {
            
            Cognism_Redeem_ID_Counter__c CRID = [
                SELECT Id, is_Active__c 
                FROM Cognism_Redeem_ID_Counter__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
         
            CRID.is_Active__c = false;
            
            update CRID;
 
            Cognism_Redeem_ID_Counter__c newCRID = new Cognism_Redeem_ID_Counter__c();
            newCRID.is_Active__c = true;
            newCRID.Allocated_Count__c = newRedeemCount;
                
            if (String.isNotBlank(startDate)) {
                newCRID.Start_Date__c = Date.valueOf(startDate);
            }
            
            if (String.isNotBlank(endDate)) {
                newCRID.End_Date__c = Date.valueOf(endDate);
            }
                
            insert newCRID;
            
            return newCRID.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update the redeem count: ' + e.getMessage());
        }
    }
    
    public static void preventRecordCreationIfActiveRecordExist(List<Cognism_Redeem_ID_Counter__c> newRecs) {
        List<Cognism_Redeem_ID_Counter__c> existingActiveRecords = [
            SELECT Id 
            FROM Cognism_Redeem_ID_Counter__c 
            WHERE is_Active__c = true
            LIMIT 1
        ];
        
        if (!existingActiveRecords.isEmpty()) {
            for (Cognism_Redeem_ID_Counter__c rec : newRecs) {
                rec.addError('An active record already exists. Cannot create another one.');
            }
        }
    }
    
    @AuraEnabled
    public static boolean shouldEnrichContactsVisible() {
        List<Cognism_Redeem_ID_Counter__c> existingActiveRecords = [
            SELECT Id, Remaining_Count__c
            FROM Cognism_Redeem_ID_Counter__c 
            WHERE is_Active__c = true
            LIMIT 1
        ];
        
        if (existingActiveRecords.isEmpty()) {
            return true;
        }
        return existingActiveRecords[0].Remaining_Count__c == 0;
    }
    
    
    public static void checkAndNotify(List<Cognism_Redeem_ID_Counter__c> newList, Map<Id, Cognism_Redeem_ID_Counter__c> oldMap, Boolean isUpdate) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        List<User> admins = [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND Email != null];
        List<String> adminEmails = new List<String>();
        
        for (User u : admins) {
            adminEmails.add(u.Email);
        }
        
        String currentUserId = UserInfo.getUserId();
        
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName='Cognism_Redeem_Alert'
            LIMIT 1
        ];
        
        Boolean shouldSendNotification = false;
        Decimal usagePercentage=0;    
        String recName = '';
        for (Cognism_Redeem_ID_Counter__c rec : newList) {
            
            if (rec.Allocated_Count__c != null && rec.Allocated_Count__c > 0) {
                Decimal usagePercent = ((Decimal)rec.Used_Count__c / rec.Allocated_Count__c) * 100;
                Boolean crossedThreshold = usagePercent >= 90;
                Boolean justCrossed = true;
                if (isUpdate && oldMap != null && oldMap.containsKey(rec.Id)) {
                    Cognism_Redeem_ID_Counter__c oldRec = oldMap.get(rec.Id);
                    Decimal oldUsagePercent = 0;
                    if (oldRec.Allocated_Count__c != null && oldRec.Allocated_Count__c > 0) {
                        oldUsagePercent = ((Decimal)oldRec.Used_Count__c / oldRec.Allocated_Count__c) * 100;
                    }
                    justCrossed = oldUsagePercent < 90;
                }
                System.debug('justCrossed'+justCrossed);
                System.debug('crossedThreshold'+crossedThreshold);
                if (crossedThreshold && justCrossed) {
                    shouldSendNotification = true;
                    usagePercentage=usagePercent;
                    recName=rec.Name;
                    
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(adminEmails); 
                    email.setSubject('⚠️ Cognism Usage Alert for ' + rec.Name);
                    email.setPlainTextBody('Used count has reached ' + usagePercent.setScale(2) + '% of the allocated count for record cognism: ' + rec.Name);
                    emailsToSend.add(email);
                }
            }
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
        
        if (shouldSendNotification) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('⚠️ Cognism Usage Alert');
            notification.setBody('Used count has reached' + usagePercentage.setScale(2) + '% of the allocated count for record cognism: ' + recName);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(currentUserId); 
            notification.send(new Set<String>{currentUserId}); 
        }
    }
    
}