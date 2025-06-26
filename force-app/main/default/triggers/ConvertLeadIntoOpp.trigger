trigger ConvertLeadIntoOpp on Lead (after update) {
	List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();

    for (Lead ld : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(ld.Id);

        if (ld.Status == 'Opportunity' && oldLead.Status != 'Opportunity' && !ld.IsConverted) {
            // Get converted status
            LeadStatus convertStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            lc.setDoNotCreateOpportunity(false); 
            lc.setOverwriteLeadSource(false); 

            leadsToConvert.add(lc);
        }
    }

    if (!leadsToConvert.isEmpty()) {
        List<Database.LeadConvertResult> results = Database.convertLead(leadsToConvert, false);
        
        for (Database.LeadConvertResult res : results) {
            if (!res.isSuccess()) {
                System.debug('Lead conversion failed: ' + res.getErrors());
            }
        }
    }
}