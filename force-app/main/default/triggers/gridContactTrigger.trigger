trigger gridContactTrigger on Grid_Contact__c (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        gridContactTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        gridContactTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        gridContactTriggerHandler.handleUpdateEmailPhone(Trigger.new, Trigger.oldMap);
        gridContactTriggerHandler.handleUpdateLeadStatus(Trigger.new, Trigger.oldMap);
    }
}