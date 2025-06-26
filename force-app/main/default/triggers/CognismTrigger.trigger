trigger CognismTrigger on Cognism_Redeem_ID_Counter__c (before insert, before update, after Update) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        CognismRedeemController.preventRecordCreationIfActiveRecordExist(Trigger.new);
    }
    
    if(Trigger.isAfter){
        CognismRedeemController.checkAndNotify(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
    }
}