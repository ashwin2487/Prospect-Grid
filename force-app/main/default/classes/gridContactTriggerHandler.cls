public class gridContactTriggerHandler {
    private static Set<Id> gridContactIdsToSnapshot = new Set<Id>();
    private static Map<Id, Grid_Contact__c> oldGridContactMap = new Map<Id, Grid_Contact__c>();
    
    // Before Update Handler
    public static void handleBeforeUpdate(List<Grid_Contact__c> newList, Map<Id, Grid_Contact__c> oldMap) {
        Set<Id> gridContactIds = new Set<Id>();
        
        for (Grid_Contact__c newCon : newList) {
            Grid_Contact__c oldCon = oldMap.get(newCon.Id);
            if (newCon.Contact_Outreach_Owner__c != oldCon.Contact_Outreach_Owner__c) {
                gridContactIdsToSnapshot.add(newCon.Id);
                oldGridContactMap.put(newCon.Id, oldCon);
                gridContactIds.add(newCon.Id);
            }
        }
        
        if (gridContactIds.isEmpty()) return;
        
        Map<Id, List<Contact_Outreach_Snapshot__c>> snapshotMap = new Map<Id, List<Contact_Outreach_Snapshot__c>>();
        
        for (Contact_Outreach_Snapshot__c snap : [
            SELECT Grid_Contact__c, Contact_Outreach_Owner__c,
            Call_Attempt_1__c, Call_Attempt_2__c, Call_Attempt_3__c, Call_Attempt_4__c, Call_Attempt_5__c,
            Contact_LinkedIn_Id__c, Email_1__c, Email_2__c, LinkedIn_Chat_Id__c, LinkedIn_Connection_Status__c,
            LinkedIn_Invitation_Id__c, LinkedIn_Invitation_Sent_Date__c, LinkedIn_Message_1__c, LinkedIn_Message_2__c,
            LinkedIn_Message_Content__c, LinkedIn_Message_Id__c, LM1_TimeStamp__c, LM2_TimeStamp__c, Notes__c,
            Email__c, Phone__c
            FROM Contact_Outreach_Snapshot__c
            WHERE Grid_Contact__c IN :gridContactIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!snapshotMap.containsKey(snap.Grid_Contact__c)) {
                snapshotMap.put(snap.Grid_Contact__c, new List<Contact_Outreach_Snapshot__c>());
            }
            snapshotMap.get(snap.Grid_Contact__c).add(snap);
        }
        
        for (Grid_Contact__c newCon : newList) {
            if (!gridContactIds.contains(newCon.Id)) continue;
            
            newCon.Call_Attempt_1__c = null;
            newCon.Call_Attempt_2__c = null;
            newCon.Call_Attempt_3__c = null;
            newCon.Call_Attempt_4__c = null;
            newCon.Call_Attempt_5__c = null;
            newCon.Email_1__c = 'Not Sent';
            newCon.Email_2__c = 'Not Sent';
            newCon.LinkedIn_Connection_Status__c = 'Not Connected';
            newCon.LinkedIn_Invitation_Id__c = null;
            newCon.LinkedIn_Invitation_Sent_Date__c = null;
            newCon.LinkedIn_Message_1__c = 'Not Sent';
            newCon.LinkedIn_Message_2__c = 'Not Sent';
            newCon.LinkedIn_Message_Content__c = null;
            newCon.LinkedIn_Message_Id__c = null;
            newCon.LM1_TimeStamp__c = null;
            newCon.LM2_TimeStamp__c = null;
            newCon.Notes__c = null;
            
            if (newCon.Contact_Outreach_Owner__c != null && snapshotMap.containsKey(newCon.Id)) {
                for (Contact_Outreach_Snapshot__c snap : snapshotMap.get(newCon.Id)) {
                    if (snap.Contact_Outreach_Owner__c == newCon.Contact_Outreach_Owner__c) {
                        newCon.Call_Attempt_1__c = snap.Call_Attempt_1__c;
                        newCon.Call_Attempt_2__c = snap.Call_Attempt_2__c;
                        newCon.Call_Attempt_3__c = snap.Call_Attempt_3__c;
                        newCon.Call_Attempt_4__c = snap.Call_Attempt_4__c;
                        newCon.Call_Attempt_5__c = snap.Call_Attempt_5__c;
                        newCon.Contact_LinkedIn_Id__c = snap.Contact_LinkedIn_Id__c;
                        newCon.Email_1__c = snap.Email_1__c;
                        newCon.Email_2__c = snap.Email_2__c;
                        newCon.LinkedIn_Chat_Id__c = snap.LinkedIn_Chat_Id__c;
                        newCon.LinkedIn_Connection_Status__c = snap.LinkedIn_Connection_Status__c;
                        newCon.LinkedIn_Invitation_Id__c = snap.LinkedIn_Invitation_Id__c;
                        newCon.LinkedIn_Invitation_Sent_Date__c = snap.LinkedIn_Invitation_Sent_Date__c;
                        newCon.LinkedIn_Message_1__c = snap.LinkedIn_Message_1__c;
                        newCon.LinkedIn_Message_2__c = snap.LinkedIn_Message_2__c;
                        newCon.LinkedIn_Message_Content__c = snap.LinkedIn_Message_Content__c;
                        newCon.LinkedIn_Message_Id__c = snap.LinkedIn_Message_Id__c;
                        newCon.LM1_TimeStamp__c = snap.LM1_TimeStamp__c;
                        newCon.LM2_TimeStamp__c = snap.LM2_TimeStamp__c;
                        newCon.Notes__c = snap.Notes__c;
                        newCon.Email__c = snap.Email__c;
                        newCon.Phone__c = snap.Phone__c;
                        break;
                    }
                }
            }
        }
    }
    
    // After Update Handler
    public static void handleAfterUpdate(List<Grid_Contact__c> updatedList, Map<Id, Grid_Contact__c> oldMap) {
        List<Contact_Outreach_Snapshot__c> snapshotsToInsert = new List<Contact_Outreach_Snapshot__c>();
        
        for (Grid_Contact__c newCon : updatedList) {
            if (gridContactIdsToSnapshot.contains(newCon.Id)) {
                Grid_Contact__c oldCon = oldGridContactMap.get(newCon.Id);
                
                Contact_Outreach_Snapshot__c snapshot = new Contact_Outreach_Snapshot__c();
                snapshot.Grid_Contact__c = oldCon.Id;
                snapshot.Contact_Outreach_Owner__c = oldCon.Contact_Outreach_Owner__c;
                snapshot.Call_Attempt_1__c = oldCon.Call_Attempt_1__c;
                snapshot.Call_Attempt_2__c = oldCon.Call_Attempt_2__c;
                snapshot.Call_Attempt_3__c = oldCon.Call_Attempt_3__c;
                snapshot.Call_Attempt_4__c = oldCon.Call_Attempt_4__c;
                snapshot.Call_Attempt_5__c = oldCon.Call_Attempt_5__c;
                snapshot.Contact_LinkedIn_Id__c = oldCon.Contact_LinkedIn_Id__c;
                snapshot.Email_1__c = oldCon.Email_1__c;
                snapshot.Email_2__c = oldCon.Email_2__c;
                snapshot.LinkedIn_Chat_Id__c = oldCon.LinkedIn_Chat_Id__c;
                snapshot.LinkedIn_Connection_Status__c = oldCon.LinkedIn_Connection_Status__c;
                snapshot.LinkedIn_Invitation_Id__c = oldCon.LinkedIn_Invitation_Id__c;
                snapshot.LinkedIn_Invitation_Sent_Date__c = oldCon.LinkedIn_Invitation_Sent_Date__c;
                snapshot.LinkedIn_Message_1__c = oldCon.LinkedIn_Message_1__c;
                snapshot.LinkedIn_Message_2__c = oldCon.LinkedIn_Message_2__c;
                snapshot.LinkedIn_Message_Content__c = oldCon.LinkedIn_Message_Content__c;
                snapshot.LinkedIn_Message_Id__c = oldCon.LinkedIn_Message_Id__c;
                snapshot.LM1_TimeStamp__c = oldCon.LM1_TimeStamp__c;
                snapshot.LM2_TimeStamp__c = oldCon.LM2_TimeStamp__c;
                snapshot.Notes__c = oldCon.Notes__c;
                snapshot.Email__c = oldCon.Email__c;
                snapshot.Phone__c = oldCon.Phone__c;
                
                snapshotsToInsert.add(snapshot);
            }
        }
        
        if (!snapshotsToInsert.isEmpty()) {
            insert snapshotsToInsert;
        }
    }
    
    // Update Email & Phone
    public static void handleUpdateEmailPhone(List<Grid_Contact__c> updatedList, Map<Id, Grid_Contact__c> oldMap) {
        
        Map<Id, Grid_Contact__c> contactToSourceMap = new Map<Id, Grid_Contact__c>();
        
        List<Cognism_Redeem_ID_Counter__c> counterList = [
            SELECT Id, Used_Count__c, is_Active__c
            FROM Cognism_Redeem_ID_Counter__c
            WHERE is_Active__c = true
            LIMIT 1
        ];
        
        if (counterList.isEmpty()) {
            return;
        }
        
        Cognism_Redeem_ID_Counter__c cognismRedeemCounter = counterList[0];
        Decimal existingUsedCount = (cognismRedeemCounter.Used_Count__c != null) ? cognismRedeemCounter.Used_Count__c : 0;
        Decimal newlyUsedCount = 0;
        
        for (Grid_Contact__c newRecord : updatedList) {
            Grid_Contact__c oldRecord = oldMap.get(newRecord.Id);
            
            if ((newRecord.Email__c != oldRecord.Email__c) || (newRecord.Phone__c != oldRecord.Phone__c)) {
                contactToSourceMap.put(newRecord.Contact__c, newRecord);
            }
            
            if (newRecord.isRedeemIdUsed__c == true && oldRecord.isRedeemIdUsed__c == false) {
                newlyUsedCount++;
            }
        }
        
        if (newlyUsedCount > 0) {
            cognismRedeemCounter.Used_Count__c = existingUsedCount + newlyUsedCount;
            update cognismRedeemCounter;
        }
        
        if (contactToSourceMap.isEmpty()) {
            return;
        }
        
        List<Grid_Contact__c> contactsToUpdate = [
            SELECT Id, Email__c, Phone__c, Contact__c
            FROM Grid_Contact__c
            WHERE Contact__c IN :contactToSourceMap.keySet()
        ];
        
        List<Grid_Contact__c> updates = new List<Grid_Contact__c>();
        
        for (Grid_Contact__c gc : contactsToUpdate) {
            Grid_Contact__c source = contactToSourceMap.get(gc.Contact__c);
            
            // Skip the one that was already updated
            if (gc.Id == source.Id) continue;
            
            Boolean changed = false;
            if (gc.Email__c != source.Email__c) {
                gc.Email__c = source.Email__c;
                changed = true;
            }
            if (gc.Phone__c != source.Phone__c) {
                gc.Phone__c = source.Phone__c;
                changed = true;
            }
            if (changed) {
                updates.add(gc);
            }
        }
        
        if (!updates.isEmpty()) {
            update updates;
        }
    }
    
    public static void handleUpdateLeadStatus(List<Grid_Contact__c> updatedList, Map<Id, Grid_Contact__c> oldMap) {
        // List of outcomes that should trigger a Lead status update
        Set<String> validOutcomes = new Set<String>{
            	'Unresponsive',
                'No Priority at the moment',
                'With Competitor',
                'Not the right stakeholder',    
                'Opportunity already created',
                'Create Opportunity'
        };
                    
        Set<Id> changedGridContactIds = new Set<Id>();
        
        for (Grid_Contact__c newGc : updatedList) {
            Grid_Contact__c oldGc = oldMap.get(newGc.Id);
            if (newGc.Outcome__c != oldGc.Outcome__c &&
                validOutcomes.contains(newGc.Outcome__c)) {
                    changedGridContactIds.add(newGc.Id);
                }
        }
        
        if (changedGridContactIds.isEmpty()) {
            return;
        }
        
        List<Lead> leadsToUpdate = [
            SELECT Id, Grid_Contact__c, Status
            FROM Lead
            WHERE Grid_Contact__c IN :changedGridContactIds
        ];
        
        Map<Id, Grid_Contact__c> gcMap = new Map<Id, Grid_Contact__c>(updatedList);
        
        List<Lead> leadsForUpdate = new List<Lead>();
        
        for (Lead l : leadsToUpdate) {
            Grid_Contact__c relatedGc = gcMap.get(l.Grid_Contact__c);
            if (relatedGc != null && validOutcomes.contains(relatedGc.Outcome__c)) {
                l.Status = relatedGc.Outcome__c;
                leadsForUpdate.add(l);
            }
        }
        
        if (!leadsForUpdate.isEmpty()) {
            update leadsForUpdate;
        }
    }
    
}