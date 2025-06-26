public class InactiveCognismAccountEndDateExceed implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Date today = Date.today();

        List<Cognism_Redeem_ID_Counter__c> recordsToDeactivate = [
            SELECT Id, is_Active__c, End_Date__c
            FROM Cognism_Redeem_ID_Counter__c
            WHERE is_Active__c = true
            AND End_Date__c != null
            AND End_Date__c < :today
        ];

        for (Cognism_Redeem_ID_Counter__c record : recordsToDeactivate) {
            record.is_Active__c = false;
        }

        if (!recordsToDeactivate.isEmpty()) {
            update recordsToDeactivate;
        }
    }
    
}