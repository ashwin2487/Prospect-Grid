trigger SendEmailOnLeadStageChange on Lead (after update) {
    
    User currUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
    
    List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

    for (Lead l : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(l.Id);

        if (l.Status == 'Create Opportunity' && oldLead.Status != 'Create Opportunity') {
            if (currUser.Email != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { currUser.Email });
                mail.setSubject('Lead Status Updated: Create Opportunity');
                mail.setPlainTextBody(
                    'Dear ' + (currUser.Name != null ? currUser.Name : 'User') + ',\n\n' +
                    'Your lead "' + l.Name + '" has been updated to status "Create Opportunity". You can now proceed with opportunity creation.\n\n' +
                    'Thank you,\n' +
                    'Prospect Grid Team'
                );

                emailsToSend.add(mail);
            }
        }
    }

    if (!emailsToSend.isEmpty()) {
        Messaging.sendEmail(emailsToSend);
    }
}