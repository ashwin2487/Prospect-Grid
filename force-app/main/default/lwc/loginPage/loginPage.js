import { LightningElement, track } from 'lwc';
import connectToLinkedInUnipile from '@salesforce/apex/CustomLoginController.connectToLinkedInUnipile';
import getCurrentUserName from '@salesforce/apex/UserInfoController.getCurrentUserName';
import shouldLinkedInAccountEnable from '@salesforce/apex/CustomLoginController.shouldLinkedInAccountEnable';
import shouldGoogleAccountEnable from '@salesforce/apex/CustomLoginController.shouldGoogleAccountEnable';
import shouldOutlookAccountEnable from '@salesforce/apex/CustomLoginController.shouldOutlookAccountEnable';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LoginPage extends LightningElement {
    @track successMessage = '';
    @track errorMessage = '';
    @track userName = '';
    isLoading = false;
    responseData;
    isDisabledLinkedin = false;
    isDisabledGoogle = false;
    isDisabledOutlook = false;

    connectedCallback() {
        getCurrentUserName()
            .then((result) => {
                this.userName = result;
            })
            .catch((error) => {
                console.error('Error fetching user name:', error);
            });

        shouldLinkedInAccountEnable()
            .then((result) => {
                this.isDisabledLinkedin = result
            })
            .catch((error) => {
                console.log('Error fetching LinkedIn Account Data:', error);
            });

        shouldGoogleAccountEnable()
            .then((result) => {
                this.isDisabledGoogle = result;
            
            })
            .catch((error) => {
                console.log('Error fetching Gmail Account Data:', error);
            });

        shouldOutlookAccountEnable()
            .then((result) => {
                this.isDisabledOutlook = result;
            })
            .catch((error) => {
                console.log('Error fetching Outlook Account Data:', error);
            }); 

    }

    async connectToProvider(provider) {
        this.isLoading = true;
        this.successMessage = '';
        this.errorMessage = '';
        const now = new Date();
        const twelveHoursFromNow = new Date(now);
        twelveHoursFromNow.setHours(now.getHours() + 12);
        const twelveHoursFromNowISO = twelveHoursFromNow.toISOString();
        const payload = JSON.stringify({
            sync_limit: {
                MESSAGING: {
                    chats: twelveHoursFromNowISO,
                    messages: twelveHoursFromNowISO
                },
                MAILING: 'NO_HISTORY_SYNC'
            },
            type: 'create',
            providers: [provider],
            disabled_options: ['proxy', 'sync_limit', 'cookie_auth', 'autoproxy'],
            disabled_features: ['linkedin_recruiter'],
            api_url: 'https://api4.unipile.com:13455',
            expiresOn: twelveHoursFromNowISO,
            name: this.userName + '&' + provider,
            success_redirect_url: 'https://abccorp-1c-dev-ed.develop.lightning.force.com/lightning/n/Login_Page',
            failure_redirect_url: 'https://abccorp-1c-dev-ed--c.develop.vf.force.com/apex/InMaintenance',
            bypass_success_screen: true,
            notify_url: 'https://abccorp-1c-dev-ed.develop.my.salesforce-sites.com/services/apexrest/LinkedInCallbackHandler'
        });

        try {
            const response = await connectToLinkedInUnipile({ payload });
            this.responseData = JSON.parse(response);

            if (this.responseData?.url) {
                window.location.href = this.responseData.url;
            } else {
                this.successMessage = `Connected to ${provider}, but no redirect URL found.`;
            }
        } catch (error) {
            this.errorMessage = `Error connecting to ${provider}: ${error.body?.message || error.message}`;
        } finally {
            this.isLoading = false;
        }
    }

    connectToLinkedIn() {
        const result = shouldLinkedInAccountEnable();
        console.log('REsult:', result);
        if (result){
            this.showToast('Warning', 'Google Account is already connected.', 'warning');
            return;
        }
        this.connectToProvider('LINKEDIN');
    }

    async connectToGmail() {
        const resultGoogle = await shouldGoogleAccountEnable();
        const resultOutlook = await shouldOutlookAccountEnable();
        if (resultOutlook) {
            this.showToast('Warning', 'Outlook Account is already connected.', 'warning');
            return;
        }
        if (resultGoogle) {
            this.showToast('Warning', 'Google Account is already connected.', 'warning');
            return;
        }
        this.connectToProvider('GOOGLE');
    }
    async connectToOutlook() {
        const resultGoogle = await shouldGoogleAccountEnable();
        const resultOutlook = await shouldOutlookAccountEnable();

        if (resultGoogle) {
            this.showToast('Warning','Google Account is already connected.','warning');
            return;
        }
        if (resultOutlook) {
            this.showToast('Warning','Outlook Account is already connected.','warning');
            return;
        }
        this.connectToProvider('OUTLOOK');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}