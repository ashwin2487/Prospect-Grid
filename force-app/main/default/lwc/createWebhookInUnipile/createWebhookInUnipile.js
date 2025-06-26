import { LightningElement, track } from 'lwc';
import createLinkedInWebhook from '@salesforce/apex/CreateUnipileWebhook.createLinkedInWebhook';
import createEmailTrackingWebhook from '@salesforce/apex/CreateUnipileWebhook.createEmailTrackingWebhook';
import createReceivedEmailTrackingWebhook from '@salesforce/apex/CreateUnipileWebhook.createReceivedEmailTrackingWebhook';
import enableConnectedLinkedInTrackingEvent from '@salesforce/apex/CreateUnipileWebhook.enableConnectedLinkedInTrackingEvent';
import enableRecieveEmailTrackingEvent from '@salesforce/apex/CreateUnipileWebhook.enableRecieveEmailTrackingEvent';
import enableSentEmailTrackingEvent from '@salesforce/apex/CreateUnipileWebhook.enableSentEmailTrackingEvent';
import createMiscrosoftEmailTrackingWebhook from '@salesforce/apex/CreateUnipileWebhook.createMiscrosoftEmailTrackingWebhook';
import createMiscrosoftReceivedEmailTrackingWebhook from '@salesforce/apex/CreateUnipileWebhook.createMiscrosoftReceivedEmailTrackingWebhook';
import enableSentEmailOutlookTrackingEvent from '@salesforce/apex/CreateUnipileWebhook.enableSentEmailOutlookTrackingEvent';
import enableRecieveEmailOutlookTrackingEvent from '@salesforce/apex/CreateUnipileWebhook.enableRecieveEmailOutlookTrackingEvent';
import shouldGoogleAccountEnable from '@salesforce/apex/CustomLoginController.shouldGoogleAccountEnable';
import shouldOutlookAccountEnable from '@salesforce/apex/CustomLoginController.shouldOutlookAccountEnable';
import shouldLinkedInAccountEnable from '@salesforce/apex/CustomLoginController.shouldLinkedInAccountEnable';

export default class CreateWebhookInUnipile extends LightningElement {
    @track responseMessage;
    @track isLinkedTrackingEnabled = false;
    @track isSentEmailTrackingEnabled = false;
    @track isReceiveEmailTrackingEnabled = false;
    @track isSentEmailOutlookTrackingEnabled = false;
    @track isReceiveEmailOutlookTrackingEnabled = false;
    isOutlookCreated = false;
    isGoogleCreated=false;
    isLinkedInCreated=false;

    handleCreateLinkedInWebhook() {
        createLinkedInWebhook()
            .then(result => {
                this.responseMessage = 'Webhook Created: ' + result;
                return enableConnectedLinkedInTrackingEvent();
            })
            .then(result => {
                this.isLinkedTrackingEnabled = result;
            })
            .catch(error => {
                console.error('LinkedIn Webhook Error:', error);
                this.responseMessage = 'Error: ' + (error.body ? error.body.message : error.message);
            });
    }

    handleCreateSentEmailTrackingWebhook() {
        createEmailTrackingWebhook()
            .then(result => {
                this.responseMessage = 'Webhook Created: ' + result;
                return enableSentEmailTrackingEvent();
            })
            .then(result => {
                this.isSentEmailTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Sent Email Webhook Error:', error);
                this.responseMessage = 'Error: ' + (error.body ? error.body.message : error.message);
            });
    }

    handleCreateReceivedEmailWebhook() {
        createReceivedEmailTrackingWebhook()
            .then(result => {
                this.responseMessage = 'Webhook Created: ' + result;
                return enableRecieveEmailTrackingEvent();
            })
            .then(result => {
                this.isReceiveEmailTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Received Email Webhook Error:', error);
                this.responseMessage = 'Error: ' + (error.body ? error.body.message : error.message);
            });
    }

    connectedCallback() {
        enableConnectedLinkedInTrackingEvent()
            .then(result => {
                this.isLinkedTrackingEnabled = result;
            })
            .catch(error => {
                console.error('LinkedIn Tracking Init Error:', error);
            });

        enableSentEmailTrackingEvent()
            .then(result => {
                this.isSentEmailTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Sent Email Tracking Init Error:', error);
            });

        enableRecieveEmailTrackingEvent()
            .then(result => {
                this.isReceiveEmailTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Received Email Tracking Init Error:', error);
            });
        enableSentEmailOutlookTrackingEvent()
            .then(result => {
                this.isSentEmailOutlookTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Sent Email Tracking Outlook Init Error:', error);
            });
        enableRecieveEmailOutlookTrackingEvent()
            .then(result => {
                this.isReceiveEmailOutlookTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Received Email Tracking Outlook Init Error:', error);
            }); 
            
        shouldLinkedInAccountEnable()
            .then((result) => {
                this.isLinkedInCreated = result 
            })
            .catch((error) => {
                console.log('Error fetching LinkedIn Account Data:', error);
        });

        shouldGoogleAccountEnable()
            .then((result) => {
                this.isGoogleCreated = result 
            })
            .catch((error) => {
                console.log('Error fetching LinkedIn Account Data:', error);
        });

        shouldOutlookAccountEnable()
            .then((result) => {
                this.isOutlookCreated = result 
            })
            .catch((error) => {
                console.log('Error fetching LinkedIn Account Data:', error);
        });
    }
    handleCreateSentOutlookEmailTrackingWebhook() {
        createMiscrosoftEmailTrackingWebhook()
            .then(result => {
                this.responseMessage = 'Webhook Created: ' + result;
                return enableSentEmailOutlookTrackingEvent();
            })
            .then(result => {
                this.isSentEmailOutlookTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Sent Email Webhook Error:', error);
                this.responseMessage = 'Error: ' + (error.body ? error.body.message : error.message);
            });
    }
    handleCreateReceivedEmailOutlookWebhook() {
        createMiscrosoftReceivedEmailTrackingWebhook()
            .then(result => {
                this.responseMessage = 'Webhook Created: ' + result;
                return enableRecieveEmailOutlookTrackingEvent();
            })
            .then(result => {
                this.isReceiveEmailOutlookTrackingEnabled = result;
            })
            .catch(error => {
                console.error('Received Email Webhook Error:', error);
                this.responseMessage = 'Error: ' + (error.body ? error.body.message : error.message);
            });
    }
}