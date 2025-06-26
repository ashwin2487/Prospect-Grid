import { LightningElement, track, api, wire } from 'lwc';
import getUserDetails from '@salesforce/apex/UserInfoController.getUserDetails';
import getUsers from '@salesforce/apex/UserInfoController.getUsers';
import getEmailTemplates from '@salesforce/apex/EmailTemplateController.getEmailTemplates';
import createEmailTemplate from '@salesforce/apex/EmailTemplateController.createEmailTemplate';
import sendEmailWithTemplate1 from '@salesforce/apex/EmailTemplateController.sendEmailWithTemplate1';
import sendEmailWithTemplate2 from '@salesforce/apex/EmailTemplateController.sendEmailWithTemplate2';
import getGrids from '@salesforce/apex/WorkingGridController.getGrids';
import enrichContacts from '@salesforce/apex/WorkingGridController.enrichContacts';
import getContactStatus from '@salesforce/apex/WorkingGridController.getContactStatus';
import SendLinkedInMessage1 from '@salesforce/apex/WorkingGridController.SendLinkedInMessage1';
import SendLinkedInMessage2 from '@salesforce/apex/WorkingGridController.SendLinkedInMessage2';
import sendLinkedInRequest from '@salesforce/apex/WorkingGridController.sendLinkedInRequest';
import updateContactOutreachOwner from '@salesforce/apex/WorkingGridController.updateContactOutreachOwner';
import updateContactOutreachPhone from '@salesforce/apex/WorkingGridController.updateContactOutreachPhone';
import updateContactOutreachEmail from '@salesforce/apex/WorkingGridController.updateContactOutreachEmail';
import updateContactNotes from '@salesforce/apex/WorkingGridController.updateContactNotes';
import updateOutcome from '@salesforce/apex/WorkingGridController.updateOutcome';
import getEmailTemplateFolders from '@salesforce/apex/EmailTemplateController.getEmailTemplateFolders';
import getGridData from '@salesforce/apex/WorkingGridController.getGridData'
import saveCallAttemptOutcome from '@salesforce/apex/WorkingGridController.saveCallAttemptOutcome';
import searchContactsApex from '@salesforce/apex/WorkingGridController.searchContactsApex';
import createContact from '@salesforce/apex/WorkingGridController.createContact';
import sendBulkLinkedInRequests from '@salesforce/apex/gridSetupController.sendBulkLinkedInRequests';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import getMessageTemplates from '@salesforce/apex/EmailTemplateController.getMessageTemplates';
import enrichContactsWithEmailAndPhone from '@salesforce/apex/WorkingGridController.enrichContactsWithEmailAndPhone';
import shouldEnrichContactsVisible from '@salesforce/apex/CognismRedeemController.shouldEnrichContactsVisible';

const columns = [
    { label: 'Name', fieldName: 'name', type: 'text' },
    { label: 'First Name', fieldName: 'firstName', type: 'text' },
    { label: 'Last Name', fieldName: 'lastName', type: 'text' },
    { label: 'Location', fieldName: 'location', type: 'text' },
    { label: 'Company Name', fieldName: 'company', type: 'text' },
    { label: 'Current Position', fieldName: 'currentPosition', type: 'text' },
    // { label: 'LinkedIn URN', fieldName: 'LinkedIn_URN', type: 'text' },
    // { label: 'LinkedIn ID', fieldName: 'Contact_LinkedIn_Id__c', type: 'text' },
    // { label: 'Public Identifier', fieldName: 'Public_Identifier', type: 'text' },
    {
        label: 'Profile URL',
        fieldName: 'profile_url',
        type: 'url',
        typeAttributes: { label: { fieldName: 'profile_url' }, target: '_blank' }
    }
];


export default class ProspectGridWorkingTable extends NavigationMixin(LightningElement) {
    columns = columns;
    searchPerformed = false;
    searchedContacts = [];
    isDisabled = true;
    @track selectedRowsSearchedContacts = [];
    @track searchContactManually = false;
    @track searchedContactsOnLinkedIn = [];
    @track progress = 0;
    @track progressLabel = 'Starting...';
    @track invitationCount = 0; // Tracks invitations sent
    totalContacts = 0; // Total contacts eligible for invitation
    @track userName = '';
    isSaving = false;
    @track companyName = '';
    @track linkedinId = '';
    @track linkedinURN = '';
    @track profileUrl = '';
    @track showEmailTemplateCreator = false;
    @track templateName = '';
    @track templateSubject = '';
    @track templateBody = '';
    @track selectedFolder = '';
    @track folderOptions = [];
    @track userId = '';
    @track showModal = false;
    @track data = [];
    @track kpidata = [];
    @track showMyKPI = false;
    @track showMyOutreach = true;
    @track originalData = [];
    @track showModalSendRequest = false;
    @track isNotesPopupOpen = false;
    @track currentNotes = '';
    @track newNotes = '';
    @track selectedRowId;
    @track selectedRowEmail;
    @track notes;
    showNoDataMessage = false;
    @track showAllOutReach = false;
    @track showButton = true;
    @track buttonLabelShowKPI = 'Show My KPI';
    @track showEmailTemplateModal1 = false;
    @track showEmailTemplateModal2 = false;
    @track templates = [];
    @track messageTemplates = [];
    @track searchKey = '';
    @track gridSuggestions = [];
    @track selectedGrid = '';
    @track gridData = [];
    @track filteredGridData = [];
    @track error;
    selectedUserId = '';
    selectedUserName = '';
    @track contactname = '';
    selectedContactId = '';
    @track showErrorMessage = false;
    @track message = '';
    @track contacts = [];
    @track userOptionsForOwnerChange = [];
    @track userOptions = [];
    selectedOutreachOwner = '';
    selectedLinkedInStatus = '';
    selectedLinkedInMessageStatus = '';
    selectedLinkedInEmailStatus = '';
    selectedLinkedInMessageStatus2 = '';
    selectedLinkedInEmailStatus2 = '';
    @track showLinkedinMessageTemplate1 = false;
    @track showLinkedinMessageTemplate2 = false;
    @track selectedContact = { id: '', name: '' };
    @track linkedinSubject1 = '';
    @track linkedinMessage1 = '';
    @track linkedinSubject2 = '';
    @track linkedinMessage2 = '';
    @track EmailSubject1 = '';
    @track EmailMessage1 = '';
    @track EmailSubject2 = '';
    @track EmailMessage2 = '';
    @track selectedTemplateId = '';
    @track isProcessing = false;
    @track isSearching = false;
    @track isHandleImportDisabled = true;
    wiredEmailTemplatesResult;
    wiredMessageTemplatesResult;
    @track currentFolder = '';
    @track modalType = '';
    @track emailFolder = 'prospectGridEmailTemplates';
    @track messageFolder = 'prospectGridMessageTemplates';
    @track emailFolderId = '';
    @track messageFolderId = '';
    isMessage1Open = false;
    isMessage2Open = false;
    isEmail1Open = false;
    isEmail2Open = false;
    fetchContactStatusIds = [];
    @track showConfirmationModalForSendAllInvitation = false;
    @track isOpenKPIs = false;
    @track KPIsData = [];
    @track KPIsLabel;
    @track showOutreachReport = false;
    @track showEnrichContactsModal = false;
    @track enrichContactsData = [];
    @track selectedEnrichContactIds = [];
    @track isLoading = false;
    @track enrichContactsVisibleBtn = false;

    @track outcomeOptions = [
        { label: 'Unresponsive', value: 'Unresponsive' },
        { label: 'No Priority at the moment', value: 'No Priority at the moment' },
        { label: 'Not the right stakeholder', value: 'Not the right stakeholder' },
        { label: 'With Competitor', value: 'With Competitor' },
        { label: 'Opportunity already created', value: 'Opportunity already created' },
        { label: 'Create Opportunity', value: 'Create Opportunity' }

    ];
    @track callAttemptOptions = [
        { label: 'Call Picked Up', value: 'Call Picked Up' },
        { label: 'Call On Voice Mail', value: 'Call On Voice Mail' },
        { label: 'Call Disconnected', value: 'Call Disconnected' },
        { label: 'Attempt Not Made Yet', value: 'Attempt Not Made Yet' },
    ];
    @track linkedStatusOptions = [
        { label: 'All', value: 'All', type: 'text' },
        { label: 'Not Connected', value: 'Not Connected', type: 'text' },
        { label: 'Invitation Sent', value: 'Invitation Sent', type: 'text' },
        { label: 'Connected', value: 'Connected', type: 'text' },
        { label: 'Invitation Rejected', value: 'Invitation Rejected', type: 'text' },
        { label: 'Cancelled Invitation', value: 'Cancelled Invitation', type: 'text' }
    ];

    @track linkedInMessageStatusOptions = [
        { label: 'All', value: 'All', type: 'text' },
        { label: 'Not Sent', value: 'Not Sent', type: 'text' },
        { label: 'Message Sent', value: 'Message Sent', type: 'text' },
        { label: 'Message Read', value: 'Message Read', type: 'text' },
        { label: 'Message Responded', value: 'Message Responded', type: 'text' }
    ];
    @track linkedInEmailStatusOptions = [
        { label: 'All', value: 'All', type: 'text' },
        { label: 'Not Sent', value: 'Not Sent', type: 'text' },
        { label: 'Email Sent', value: 'Email Sent', type: 'text' },
        { label: 'Email Read', value: 'Email Read', type: 'text' },
        { label: 'Email Responded', value: 'Email Responded', type: 'text' }
    ];
    @track inputKpis = [
        { label: 'LinkedIn Connect Requests', value: '0/0' },
        { label: 'LinkedIn Connections', value: '0/0' },
        { label: '1st LinkedIn Messages', value: '0/0' },
        { label: '2nd LinkedIn Messages', value: '0/0' },
        { label: '1st Email Messages', value: '0/0' },
        { label: '2nd Email Messages', value: '0/0' }
    ];
    @track responseKpis = [
        { label: 'Response Rate LinkedIn', value: 0 },
        { label: 'Response Rate Email', value: 0 }
    ];
    @track callKpis = {
        attempts: 0, outcomes: [
            { label: 'Positive', count: 0, percentage: 0 },
            { label: 'Neutral', count: 0, percentage: 0 },
            { label: 'Negative', count: 0, percentage: 0 }
        ]
    };
    @track outcomeKpis = [
        { label: 'Opportunities Created', count: 0 },
        { label: 'No Priority', count: 0 },
        { label: 'With Competitor', count: 0 },
        { label: 'Unresponsive', count: 0 }
    ];
    @track efficiencyKpis = [
        { label: 'Avg LinkedIn Messages/week', value: 0 },
        { label: 'Avg Email Messages/week', value: 0 },
        { label: 'Avg Call Attempts/week', value: 0 }
    ];
    @track isCallAttemptsPopUpOpen = false;
    @track selectedValue = '';
    @track selectedAttempt = null;
    row = {};
    shouldUpdateEmailMessage1Status = false;
    shouldUpdateEmailMessage2Status = false;
    @track placeholderOptions = [];
    @track summaryGridData = [];
    @track outreachReportcolumn = [
        { label: 'Account', fieldName: 'accountName' },
        { label: 'Contacts in Grid', fieldName: 'contactsInGrid', type: 'number' },
        { label: 'Contacts Reached Out', fieldName: 'contactsReachedOut', type: 'number' },
        { label: 'Positive Response', fieldName: 'positiveResponse', type: 'number' },
        { label: 'Neutral Response', fieldName: 'neutralResponse', type: 'number' },
        { label: 'Negative Response', fieldName: 'negativeResponse', type: 'number' }
    ];
    @track enrichContactsColumns = [
        { label: 'Company', fieldName: 'Current_Company_Name__c' },
        { label: 'Name', fieldName: 'Name__c' },
        { label: 'Title', fieldName: 'Title__c' },
        { label: 'Email', fieldName: 'Email__c' },
        { label: 'Phone', fieldName: 'Phone__c' }
    ];

    /**
     * @param {any} value
     */
    set selectedContact(value) {
        this._selectedContact = value;
        this.updatePlaceholderOptions();
    }

    get selectedContact() {
        return this._selectedContact;
    }

    get sendButtonLabel() {
        return this.isProcessing ? "Sending..." : "Send";
    }


    updatePlaceholderOptions() {
        if (this.selectedContact) {
            this.placeholderOptions = [
                { label: 'Contact Full Name', value: contactName || '' },
                { label: 'Contact First Name', value: contactFirstName || '' },
                { label: 'Contact Last Name', value: contactLastName || '' },
                { label: 'Company Name', value: accountname || '' },
                { label: 'Title', value: title || '' },
                { label: 'Outreach Owner', value: outreachOwner || '' }

            ];

        } else {
            this.placeholderOptions = [];
        }
    }
    currentInput = '';
    adjustOutreachPosition() {
        const componentOne = this.template.querySelector('.custom-card-my-kpi');
        const componentTwo = this.template.querySelector('.custom-my-outreach');
        const viewportHeight = window.innerHeight;

        if (componentTwo) {
            componentTwo.style.height = '';
            componentTwo.style.overflowY = '';
            let newTop = 160;
            if (this.showMyKPI && componentOne) {
                const componentOneHeight = componentOne.offsetHeight;
                newTop += componentOneHeight;
            }
            const maxAvailableHeight = viewportHeight - newTop;
            const componentTwoHeight = componentTwo.offsetHeight;
            if (componentTwoHeight > maxAvailableHeight) {
                componentTwo.style.height = `${maxAvailableHeight}px`;
                componentTwo.style.overflowY = 'auto';
            }
            componentTwo.style.top = `${newTop}px`;
            this.enableTransition(componentTwo);
        }
    }
    enableTransition(component) {
        setTimeout(() => {
            component.style.transition = 'top 0.3s ease, height 0.3s ease';
        }, 0);
    }
    renderedCallback() {
        this.adjustOutreachPosition();
    }
    filterOptions = [
        { label: 'Show My Outreach', value: 'showMyOutReach' },
        { label: 'Show All Outreach', value: 'showAllOutReach' },
    ];
    onCloseShowMyKPI() {
        this.showMyKPI = false;
        this.buttonLabelShowKPI = 'Show My KPI';
    }
    onClickShowKPIButton() {
        this.showMyKPI = !this.showMyKPI;
        this.buttonLabelShowKPI = this.showMyKPI ? 'Hide My KPI' : 'Show My KPI';
        this.adjustOutreachPosition();
    }

    @wire(getGrids)
    wiredGrids({ error, data }) {
        if (data) {
            this.gridSuggestions = [...data]
                .sort((a, b) => a.Name.localeCompare(b.Name))
                .map(grid => ({
                    label: grid.Name,
                    value: grid.Id,
                    outreachOwnerName: grid.Outreach_Owner__r ? grid.Outreach_Owner__r.Name : 'N/A'
                }));
        } else if (error) {
            this.gridSuggestions = [];
        }
    }


    @wire(CurrentPageReference)
    getPageReference(pageRef) {

        if (pageRef && pageRef.state && pageRef.state.c__selectedValue) {
            this.selectedGrid = pageRef.state.c__selectedValue;

            const selectedGridRec = this.gridSuggestions.find(grid => grid.value === this.selectedGrid);

            if (selectedGridRec) {
                this.selectedGridName = selectedGridRec.label;
                this.selectedGridOutreachOwnerName = selectedGridRec.outreachOwnerName;
            }
            this.fetchGridData();
        } else {

        }
    }

    handleGridSelect(event) {
        this.selectedGrid = event.detail.value;

        const selectedGridRecord = this.gridSuggestions.find(grid => grid.value === this.selectedGrid);

        if (selectedGridRecord) {
            this.selectedGrid = selectedGridRecord.value;
            this.selectedGridName = selectedGridRecord.label;
            this.selectedGridOutreachOwnerName = selectedGridRecord.outreachOwnerName;
        } else {

        }

        if (!this.selectedGrid) {

            return;
        }

        this.selectedLinkedInStatus = '';
        this.selectedLinkedInMessageStatus = '';
        this.selectedLinkedInMessageStatus2 = '';
        this.selectedLinkedInEmailStatus = '';
        this.selectedLinkedInEmailStatus2 = '';

        this.fetchGridData();

        this.isOpenKPIs = false;
    }

    fetchGridData() {
        getGridData({ gridIds: [this.selectedGrid] })
            .then(result => {
                if (!result || result.length === 0) {
                    this.gridData = [];
                    this.filteredGridData = [];
                    this.showToast('Warning', 'No data found for the selected grid.', 'warning');
                    return;
                }

                this.KPIsData = result;


                const updatedGridData = result.map(grid => {
                    const contact = grid.contact || {};
                    const linkedInStatus = contact.LinkedIn_Connection_Status__c;
                    const linkedinMessage1Status = contact.LinkedIn_Message_1__c || 'Not Sent';
                    const linkedinMessage2Status = contact.LinkedIn_Message_2__c || 'Not Sent';
                    const emailMessage1Status = contact.Email_1__c || 'Not Sent';
                    const emailMessage2Status = contact.Email_2__c || 'Not Sent';
                    const description = contact.Notes__c || 'No notes available';
                    const newEmailId = contact.Email__c || '';
                    const newPhoneNumber = contact.Phone__c || '';
                    const gridCreatedDate = contact.Grid__r.CreatedDate || Date.now();
                    return {
                        newOwnerId: contact.Contact_Outreach_Owner__c || null,
                        newOwnerName: contact.Contact_Outreach_Owner__r?.Name || 'N/A',
                        newEmailId: newEmailId,
                        newPhoneNumber: newPhoneNumber,
                        accountName: grid.accountName || 'N/A',
                        contact: { ...contact },
                        contactName: contact.Name__c || 'Unknown',
                        title: contact.Title__c || 'N/A',
                        gridConFirstName: contact.FirstName__c || 'N/A',
                        gridConLastName: contact.LastName__c || 'N/A',
                        linkedInProfile: contact.LinkedIn_Profile__c || '',
                        linkedInId: contact.Contact_LinkedIn_Id__c || '',
                        linkedInStatus: linkedInStatus,
                        iconClass1: this.getIconClass1(linkedInStatus),
                        isActionableLinkedIn: linkedInStatus === 'Not Connected' || linkedInStatus === 'Invitation Rejected',
                        linkedinMessage1Status: linkedinMessage1Status,
                        linkedinMessage2Status: linkedinMessage2Status,
                        email1Status: emailMessage1Status,
                        email2Status: emailMessage2Status,

                        iconClass2LinkedInMessage1: this.getIconClass2(linkedinMessage1Status),
                        iconClass2LinkedInMessage2: this.getIconClass2(linkedinMessage2Status),
                        iconClassEmail1: this.getIconClass3(emailMessage1Status),
                        iconClassEmail2: this.getIconClass3(emailMessage2Status),
                        isActionableLinkedInMsg1: linkedinMessage1Status === 'Not Sent',
                        isActionableLinkedInMsg2: linkedinMessage2Status === 'Not Sent',
                        isActionableEmailMsg1: emailMessage1Status === 'Not Sent',
                        isActionableEmailMsg2: emailMessage2Status === 'Not Sent',

                        callAttemptIcon1: this.getIconClassCallAttempt(contact.Call_Attempt_1__c),
                        callAttemptIcon2: this.getIconClassCallAttempt(contact.Call_Attempt_2__c),
                        callAttemptIcon3: this.getIconClassCallAttempt(contact.Call_Attempt_3__c),
                        callAttemptIcon4: this.getIconClassCallAttempt(contact.Call_Attempt_4__c),
                        callAttemptIcon5: this.getIconClassCallAttempt(contact.Call_Attempt_5__c),
                        description: description,
                        conOutcome: contact.Outcome__c,
                        gridCreatedDate: gridCreatedDate
                    };
                });

                this.gridData = [...updatedGridData];
                this.filteredGridData = [...updatedGridData];
            })
            .catch(error => {
                console.log('Error while fetch grid data.', error);
                this.gridData = [];
                this.filteredGridData = [];
                this.showToast('Error', 'Failed to fetch grid data.', 'error');
            });
    }



    get isGridEmpty() {
        return this.filteredGridData.length !== 0;
    }

    handleGridRemove() {
        this.selectedGrid = '';
        this.selectedGridName = '';
        this.searchKey = '';
        this.gridData = [];
        this.filteredGridData = [];
        this.selectedLinkedInStatus = '';
        this.selectedLinkedInMessageStatus = '';
        this.selectedLinkedInMessageStatus2 = '';
        this.selectedLinkedInEmailStatus = '';
        this.selectedLinkedInEmailStatus2 = '';
        this.isOpenKPIs = false;
    }

    get outreachOwnerOptions() {
        if (!this.filteredGridData || this.filteredGridData.length === 0) {
            return [];
        }

        const ownerMap = new Map();
        this.filteredGridData.forEach(record => {
            if (record.newOwnerId && record.newOwnerName) {
                ownerMap.set(record.newOwnerId, record.newOwnerName);
            }
        });

        const options = Array.from(ownerMap.entries()).map(([id, name]) => ({
            label: name,
            value: id
        }));

        return [{ label: 'All', value: 'All' }, ...options];
    }


    handleOpenNotesPopup(event) {
        this.selectedRowId = event.target.dataset.id;
        const row = this.gridData.find(item => item.contact.Id === this.selectedRowId);

        if (row) {
            this.currentNotes = row.description || 'No notes available';
        }

        this.newNotes = '';
        this.isNotesPopupOpen = true;
    }

    handleChangeExistingNotes(event) {
        this.currentNotes = event.detail.value
    }

    handleNotesChange(event) {
        this.newNotes = event.target.value;
    }

    handleSaveNotes() {
        if (!this.currentNotes?.trim()) {
            this.showToast('Error', 'Please enter notes before saving.', 'error');
            return;
        }

        const row = this.gridData.find(item => item.contact.Id === this.selectedRowId);
        if (row && this.currentNotes === row.description) {
            this.showToast('Warning', 'No changes made to notes.', 'warning');
            return;
        }

        updateContactNotes({ contactId: this.selectedRowId, notes: this.newNotes.trim(), ExistNotes: this.currentNotes })
            .then(contact => {
                this.gridData = this.gridData.map(record => {
                    if (record.contact.Id === this.selectedRowId) {
                        return {
                            ...record,
                            description: contact.Notes__c,
                        };
                    }
                    return record;
                });
                this.gridData = [...this.gridData];

                this.currentNotes = contact.Notes__c;
                this.newNotes = '';
                this.showToast('Success', 'Notes updated successfully.', 'success');
                this.fetchContactStatusIds = [];
                this.fetchContactStatusIds = this.selectedRowId;
                this.fetchContactStatus(this.fetchContactStatusIds);
                this.handleCloseNotesPopup();
            })
            .catch(error => {
                this.showToast('Error', `Failed to update notes: ${error.body?.message || 'Unknown error'}`, 'error');
            });
    }

    handleCloseNotesPopup() {
        this.isNotesPopupOpen = false;
        this.newNotes = '';
    }
    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.handleCloseNotesPopup();
        }
    }
    handleOutcomeChange(event) {
        const contactId = event.target.dataset.id;
        const newOutcome = event.target.value;
        this.data = this.data.map(row => {
            if (row.contact.Id === contactId) {
                return { ...row, outcome: newOutcome };
            }
            return row;
        });
        updateOutcome({ contactId, outcome: newOutcome })
            .then(() => {
                this.showToast('Success', 'Outcome updated successfully!', 'success');

                this.fetchContactStatusIds = [];
                this.fetchContactStatusIds = contactId;
                this.fetchContactStatus(this.fetchContactStatusIds);
            })
            .catch(error => {

                this.showToast('Error', 'Failed to update outcome.', 'error');
            });
    }

    @wire(getUserDetails)
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.Name;
            this.userId = data.Id;
        } else if (error) {

        }
    }
    get cardTitle() {
        return `Hello, ${this.userName} !!!`;
    }
    get myKPITitle() {
        return ` ${this.userName} KPI Data !!!`;
    }
    handleShowModal() {
        this.showModal = true;
    }
    get outreachTitle() {
        return ` ${this.userName} Outreach Data !!!`;
    }
    handleCloseModal() {
        this.showModal = false;
    }
    onClickCallAttempts(event) {
        this.selectedRowId = event.target.dataset.id;
        this.selectedAttempt = event.target.dataset.attempt;

        const row = this.data.find(item => item.contact.Id === this.selectedRowId);
        if (row) {
            this.selectedValue = row[`callAttempt${this.selectedAttempt}`] || '';
        }

        this.isCallAttemptsPopUpOpen = true;
    }

    handleCallAttemptChange(event) {
        this.selectedValue = event.detail.value;
    }

    handleCallAttemptsPopUp() {
        this.isCallAttemptsPopUpOpen = false;
        this.selectedRowId = null;
        this.selectedAttempt = null;
        this.selectedValue = null;
    }

    async handleSaveCallAttemptsPopUp() {

        if (!this.selectedRowId || !this.selectedAttempt || !this.selectedValue) {
            this.showToast('Error', 'Please select a valid call attempt.', 'error');
            return;
        }

        try {
            await saveCallAttemptOutcome({
                contactId: this.selectedRowId,
                attemptNumber: parseInt(this.selectedAttempt, 10),
                outcome: this.selectedValue
            });
            this.fetchContactStatusIds = [];
            this.fetchContactStatusIds = this.selectedRowId;
            this.showToast('Success', 'Call attempt updated successfully!', 'success');
            this.fetchContactStatus(this.fetchContactStatusIds);
            this.isCallAttemptsPopUpOpen = false;
            this.selectedRowId = null;
            this.selectedAttempt = null;
            this.selectedValue = null;
        } catch (error) {
            this.showToast('Error', 'Failed to save call attempt: ' + (error.body?.message || error.message), 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getIconClassCallAttempt(callAttemptOutcome) {
        switch (callAttemptOutcome) {
            case 'Call Picked Up':
                return 'slds-icon-text-success call-attempt-picked-up';
            case 'Call On Voice Mail':
                return 'slds-icon-text-warning call-attempt-voice-mail';
            case 'Call Disconnected':
                return 'slds-icon-text-error call-attempt-disconnected';
            case 'Attempt Not Made Yet':
                return 'slds-icon-text-default call-attempt-not-made';
            default:
                return 'slds-icon-text-default call-attempt-default';
        }
    }



    @wire(getEmailTemplates)
    wiredEmailTemplates(result) {
        this.wiredEmailTemplatesResult = result; // store the full wire result object
        const { data, error } = result;

        if (data) {
            this.templates = data.map(template => ({
                Id: template.Id,
                Name: template.Name,
                Subject: template.Subject,
                Body: template.Body
            }));
            console.log('Fetched templates:', this.templates);
        } else if (error) {
            console.error('Error fetching email templates:', error);
            this.templates = [];
        }
    }

    @wire(getMessageTemplates)
    wiredMessageTemplates(result) {
        this.wiredMessageTemplatesResult = result;
        const { data, error } = result;

        if (data) {
            this.messageTemplates = data.map(template => ({
                Id: template.Id,
                Name: template.Name,
                Subject: template.Subject,
                Body: template.Body
            }));
            console.log('Message Templates:', this.messageTemplates);
        } else if (error) {
            console.error('Error fetching message templates:', error);
            this.messageTemplates = [];
        }
    }


    onClickEmailmessage1(event) {
        this.selectedRowId = '';
        const contactId = event.currentTarget.dataset.id;
        const contactName = event.currentTarget.dataset.contactname;
        const contactFirstName = event.currentTarget.dataset.contactfname;
        const contactLastName = event.currentTarget.dataset.contactlname;
        const outreachOwner = event.currentTarget.dataset.outreachownername;
        const title = event.currentTarget.dataset.title;
        const accountname = event.currentTarget.dataset.accountname;
        const email = event.currentTarget.dataset.email;
        const record = this.filteredGridData.find(rec => rec.contact.Id === contactId);

        if (record && record.email1Status === 'Not Sent') {
            this.selectedContact = {
                id: contactId,
                name: contactName,
                outreachOwner: outreachOwner,
                title: title,
                accountname: accountname,
                contactFirstName: contactFirstName,
                contactLastName: contactLastName
            };
            this.placeholderOptions = [
                { label: 'Contact Full Name', value: contactName || '' },
                { label: 'Contact First Name', value: contactFirstName || '' },
                { label: 'Contact Last Name', value: contactLastName || '' },
                { label: 'Company Name', value: accountname || '' },
                { label: 'Title', value: title || '' },
                { label: 'Outreach Owner', value: outreachOwner || '' },


            ];
            this.selectedRowEmail = email;
            this.selectedRowId = contactId;
            this.showEmailTemplateModal1 = true;
            this.isEmail1Open = true;
        } else {
            this.showToast('info', 'Email 1 Already sent.', 'info');
        }
    }

    handleTemplateSelection3(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedTemplateId = selectedId;
        const selectedTemplate = this.templates.find(t => t.Id === selectedId);

        if (selectedTemplate && this.selectedContact) {
            this.EmailSubject1 = selectedTemplate.Subject
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first Name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact Name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner Name');


            this.EmailMessage1 = selectedTemplate.Body
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first Name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact Name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner Name');

        } else {
            // Optionally handle the case where no template or contact is selected
        }
    }


    async handleSendEmailMessage1() {
        if (!this.selectedRowEmail) {
            this.showToast('Error', 'No email address selected.', 'error');
            return;
        }

        if (!this.EmailSubject1?.trim() || !this.EmailMessage1?.trim()) {
            this.showToast('Error', 'Subject and message cannot be empty.', 'error');
            return;
        }

        if (!this.selectedRowId) {
            this.showToast('Error', 'No contact selected.', 'error');
            return;
        }

        this.isProcessing = true;

        try {
            await sendEmailWithTemplate1({
                email: this.selectedRowEmail,
                targetObjectId: this.userId,
                contactId: this.selectedRowId,
                subject: this.EmailSubject1,
                message: this.EmailMessage1
            });

            this.fetchContactStatusIds = [];
            this.fetchContactStatusIds = this.selectedRowId;
            this.showToast('Success', 'Email sent successfully!', 'success');
            this.fetchContactStatus(this.fetchContactStatusIds);
            this.resetEmailForm(false);

        } catch (error) {
            this.showToast('Error', `Failed to send email. ${error.body?.message || error.message}`, 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    handleCloseEmailMessage1() {
        this.showEmailTemplateModal1 = false;
        this.showEmailTemplateModal2 = false;
        this.selectedContact = '';
        this.selectedRowEmail = '';
        this.selectedTemplateId = '';
        this.EmailSubject1 = '';
        this.EmailMessage1 = '';
        this.EmailSubject2 = '';
        this.EmailMessage2 = '';
        this.selectedRowId = '';
        this.isEmail1Open = false;
        this.isEmail2Open = false;
    }

    onClickEmailmessage2(event) {
        this.selectedRowId = '';
        const contactId = event.currentTarget.dataset.id;
        const contactName = event.currentTarget.dataset.contactname;
        const contactFirstName = event.currentTarget.dataset.contactfname;
        const contactLastName = event.currentTarget.dataset.contactlname;
        const outreachOwner = event.currentTarget.dataset.outreachownername;
        const title = event.currentTarget.dataset.title;
        const accountname = event.currentTarget.dataset.accountname;
        const email = event.currentTarget.dataset.email;
        const record = this.filteredGridData.find(rec => rec.contact.Id === contactId);

        if (record.email1Status === 'Not Sent') {
            this.showToast('info', 'Email 1 Not sent.', 'info');
            return;
        }

        if (record && record.email2Status === 'Not Sent') {
            this.selectedContact = {
                id: contactId,
                name: contactName,
                outreachOwner: outreachOwner,
                title: title,
                accountname: accountname
            };


            this.placeholderOptions = [
                { label: 'Contact Full Name', value: contactName || '' },
                { label: 'Contact First Name', value: contactFirstName || '' },
                { label: 'Contact Last Name', value: contactLastName || '' },
                { label: 'Company Name', value: accountname || '' },
                { label: 'Title', value: title || '' },
                { label: 'Outreach Owner', value: outreachOwner || '' }

            ];
            this.selectedRowEmail = email;
            this.selectedRowId = contactId;
            this.showEmailTemplateModal2 = true;
            this.isEmail2Open = true;
        } else {
            this.showToast('info', 'Email 2 Already sent.', 'info');
        }
    }

    handleTemplateSelection4(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedTemplateId = selectedId;
        const selectedRowId = this.selectedRowId;

        const selectedTemplate = this.templates.find(t => t.Id === selectedId);
        if (selectedTemplate && this.selectedContact) {
            this.EmailSubject2 = selectedTemplate.Subject
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first Name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact Name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner Name');


            this.EmailMessage2 = selectedTemplate.Body
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first Name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact Name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner Name');

        } else {

        }
    }
    async handleSendEmailMessage2() {
        if (!this.selectedRowEmail) {
            this.showToast('Error', 'No email address selected.', 'error');
            return;
        }

        if (!this.EmailSubject2?.trim() || !this.EmailMessage2?.trim()) {
            this.showToast('Error', 'Subject and message cannot be empty.', 'error');
            return;
        }

        this.isProcessing = true;

        try {
            await sendEmailWithTemplate2({
                email: this.selectedRowEmail,
                targetObjectId: this.userId,
                contactId: this.selectedRowId,
                subject: this.EmailSubject2,
                message: this.EmailMessage2
            });

            this.fetchContactStatusIds = [];
            this.fetchContactStatusIds = this.selectedRowId;
            this.showToast('Success', 'Email sent successfully!', 'success');
            this.fetchContactStatus(this.fetchContactStatusIds);
            this.resetEmailForm(false);

        } catch (error) {
            this.showToast('Error', `Failed to send email. ${error.body?.message || error.message}`, 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    resetEmailForm(keepSelection = true) {
        this.showEmailTemplateModal1 = false;
        this.showEmailTemplateModal2 = false;
        this.selectedContact = '';
        this.selectedRowEmail = '';
        this.selectedTemplateId = '';
        this.EmailSubject1 = '';
        this.EmailMessage1 = '';
        this.EmailSubject2 = '';
        this.EmailMessage2 = '';
        this.selectedRowId = '';

        if (!keepSelection) {
            this.selectedRowId = '';
            this.selectedRowEmail = '';
        }
    }


    handleSubjectChange4(event) {
        this.EmailSubject2 = event.target.value;
    }

    handleMessageChange4(event) {
        this.EmailMessage2 = event.target.value;
    }
    getEmailFromRow(selectedRowId) {
        const row = this.data.find(item => item.OwnerId === selectedRowId);
        return row ? row.email : null;
    }
    @wire(getUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {

        }
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handleEditOwner(event) {
        const contactId = event.target.dataset.id;

        this.filteredGridData = this.filteredGridData.map(record => ({
            ...record,
            isEditing: record.contact.Id === contactId,
            newOwnerId: record.newOwnerId || record.contact.Outreach_Owner__c
        }));
    }

    handleEditPhone(event) {
        const contactId = event.target.dataset.id;
        this.filteredGridData = this.filteredGridData.map(record => ({
            ...record,
            isEditingPhone: record.contact.Id === contactId,
            newPhoneNumber: record.newPhoneNumber || ''
        }));
    }

    handleEditEmail(event) {
        const contactId = event.target.dataset.id;
        this.filteredGridData = this.filteredGridData.map(record => ({
            ...record,
            isEditingEmail: record.contact.Id === contactId,
            newEmailId: record.newEmailId || ''
        }));
    }


    handleOwnerChange(event) {
        const contactId = event.target.dataset.id;
        const newOwnerId = event.detail.value;

        this.filteredGridData = this.filteredGridData.map(record => {
            if (record.contact.Id === contactId) {
                return { ...record, newOwnerId, isEditing: true };
            }
            return record;
        });
    }

    handlePhoneChange(event) {
        const contactId = event.target.dataset.id;
        const newPhoneNumber = event.detail.value;

        this.filteredGridData = this.filteredGridData.map(record => {
            if (record.contact.Id === contactId) {
                return { ...record, newPhoneNumber, isEditingPhone: true };
            }
            return record;
        });
    }

    handleEmailChange(event) {
        const contactId = event.target.dataset.id;
        const newEmailId = event.detail.value;

        this.filteredGridData = this.filteredGridData.map(record => {
            if (record.contact.Id === contactId) {
                return { ...record, newEmailId, isEditingEmail: true };
            }
            return record;
        });
    }


    handleCancelEdit(event) {
        const contactId = event.target.dataset.id;
        this.filteredGridData = this.filteredGridData.map(record => ({
            ...record,
            isEditing: record.contact.Id === contactId ? false : record.isEditing,
            isEditingEmail: record.contact.Id === contactId ? false : record.isEditingEmail,
            isEditingPhone: record.contact.Id === contactId ? false : record.isEditingPhone
        }));
    }

    handleSaveOwnerChange(event) {
        const contactId = event.target.dataset.id;
        const updatedRecord = this.filteredGridData.find(record => record.contact.Id === contactId);

        if (!updatedRecord || !updatedRecord.newOwnerId) {

            return;
        }

        updateContactOutreachOwner({ contactId, newOwnerId: updatedRecord.newOwnerId })
            .then(() => {
                const selectedOwner = this.userOptions.find(option => option.value === updatedRecord.newOwnerId);
                const ownerName = selectedOwner ? selectedOwner.label : 'N/A';
                this.gridData = this.gridData.map(record => {
                    if (record.contact.Id === contactId) {
                        return {
                            ...record,
                            newOwnerId: updatedRecord.newOwnerId,
                            newOwnerName: ownerName,
                            isEditing: false
                        };
                    }
                    return record;
                });
                this.fetchGridData();
                this.handleFilterChange({ target: { value: this.selectedOutreachOwner } });

            })
            .catch(error => {

            });
    }

    handleSavePhoneChange(event) {
        const contactId = event.target.dataset.id;
        const updatedRecord = this.filteredGridData.find(record => record.contact.Id === contactId);

        if (!updatedRecord) {

            return;
        }

        const phoneRegex = /^\d+$/;
        if (updatedRecord.newPhoneNumber && !phoneRegex.test(updatedRecord.newPhoneNumber)) {
            this.showToast('error', 'Oops! That doesn\'t look like a valid phone number.', 'error');
            this.filteredGridData = this.filteredGridData.map(record => {
                if (record.contact.Id === contactId) {
                    return { ...record, newPhoneNumber: '' };
                }
                return record;
            });
            return;
        }

        updateContactOutreachPhone({ contactId, newPhoneNumber: updatedRecord.newPhoneNumber })
            .then((updatedContact) => {

                this.gridData = this.gridData.map(record => {
                    if (record.contact.Id === contactId) {
                        return {
                            ...record,
                            newPhoneNumber: updatedContact.Phone__c,
                            isEditingPhone: false,
                        };
                    }
                    return record;
                });

                this.filteredGridData = [...this.gridData];

            })
            .catch(error => {

            });
    }

    handleSaveEmailChange(event) {
        const contactId = event.target.dataset.id;
        const updatedRecord = this.filteredGridData.find(record => record.contact.Id === contactId);

        if (!updatedRecord) {
            console.log('updatedRecord is null', updatedRecord);
            return;
        }

        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

        if (updatedRecord.newEmailId && !emailRegex.test(updatedRecord.newEmailId)) {
            this.showToast('error', 'Oops! That doesn\'t look like a valid email.', 'error');


            this.filteredGridData = this.filteredGridData.map(record => {
                if (record.contact.Id === contactId) {
                    return { ...record, newEmailId: '' };
                }
                return record;
            });

            return;
        }

        updateContactOutreachEmail({ contactId, newEmailId: updatedRecord.newEmailId })
            .then((updatedContact) => {

                this.gridData = this.gridData.map(record => {
                    if (record.contact.Id === contactId) {
                        return {
                            ...record,
                            newEmailId: updatedContact.Email__c,
                            isEditingEmail: false,
                        };
                    }
                    return record;
                });

                this.filteredGridData = [...this.gridData];
            })
            .catch(error => {

            });
    }

    get kpisLabel() {
        return this.isOpenKPIs ? 'Hide KPIs' : 'Show KPIs';
    }

    toggleKPIs() {
        this.isOpenKPIs = !this.isOpenKPIs;
        if (this.isOpenKPIs) {
            this.fetchKPIsData();
        }
    }

    handleCloseKPIsModal() {
        this.isOpenKPIs = false;
    }

    fetchKPIsData() {
        if (!this.selectedGrid) {
            this.showToast('Error', 'No Grid Available', 'error');
            return;
        }
        console.log('KPIsData', this.KPIsData);
        if (!this.KPIsData || !this.KPIsData.length) {
            this.showToast('Warning', 'No data loaded to compute KPIs.', 'warning');
            return;
        }

        const contacts = this.KPIsData.map(r => r.contact);
        this.computeKpis(contacts);
    }

    computeKpis(contacts) {
        const total = contacts.length;

        const reqSent = contacts.filter(c => c.LinkedIn_Connection_Status__c === 'Invitation Sent').length;
        const connected = contacts.filter(c => c.LinkedIn_Connection_Status__c === 'Connected').length;

        const msg1 = contacts.filter(c => c.LinkedIn_Message_1__c === 'Message Sent').length;
        const msg2 = contacts.filter(c => c.LinkedIn_Message_2__c === 'Message Sent').length;
        const msg3 = contacts.filter(c => c.LinkedIn_Message_1__c === 'Message Responded').length;
        const msg4 = contacts.filter(c => c.LinkedIn_Message_2__c === 'Message Responded').length;
        const msg5 = contacts.filter(c => c.LinkedIn_Message_1__c === 'Message Read').length;
        const msg6 = contacts.filter(c => c.LinkedIn_Message_2__c === 'Message Read').length;

        const em1 = contacts.filter(c => c.Email_1__c === 'Email Sent').length;
        const em2 = contacts.filter(c => c.Email_2__c === 'Email Sent').length;
        const em3 = contacts.filter(c => c.Email_1__c === 'Email Responded').length;
        const em4 = contacts.filter(c => c.Email_2__c === 'Email Responded').length;
        const em5 = contacts.filter(c => c.Email_1__c === 'Email Read').length;
        const em6 = contacts.filter(c => c.Email_2__c === 'Email Read').length;


        this.inputKpis = [
            { label: 'LinkedIn Connect Requests Made', value: `${reqSent}/${total}` },
            { label: 'LinkedIn Connections Made', value: `${connected}/${reqSent}` },
            { label: '1st LinkedIn Messages Sent', value: `${msg1}/${total}` },
            { label: '2nd LinkedIn Messages Sent', value: `${msg2}/${total}` },
            { label: '1st Email Messages Sent', value: `${em1}/${total}` },
            { label: '2nd Email Messages Sent', value: `${em2}/${total}` }

        ];

        // Responses
        const messageReply = contacts.reduce((count, contact) => {
            if (contact.LinkedIn_Message_1__c === 'Message Responded') {
                count++;
            }
            if (contact.LinkedIn_Message_2__c === 'Message Responded') {
                count++;
            }
            return count;
        }, 0);


        const emailReply = contacts.reduce((count, contact) => {
            if (contact.Email_1__c === 'Email Responded') {
                count++;
            }
            if (contact.Email_2__c === 'Email Responded') {
                count++;
            }
            return count;
        }, 0);

        this.responseKpis = [
            { label: 'Response Rate Message', value: (msg1 + msg2 + msg3 + msg4 + msg5 + msg6) ? ((messageReply / (msg1 + msg2 + msg3 + msg4 + msg5 + msg6)) * 100).toFixed(2) : '0.00' },
            { label: 'Response Rate Email', value: (em1 + em2 + em3 + em4 + em5 + em6) ? ((emailReply / (em1 + em2 + em3 + em4 + em5 + em6)) * 100).toFixed(2) : '0.00' }
        ];

        const calls = contacts.flatMap(c => [
            c.Call_Attempt_1__c,
            c.Call_Attempt_2__c,
            c.Call_Attempt_3__c,
            c.Call_Attempt_4__c,
            c.Call_Attempt_5__c
        ]).filter(Boolean);

        const positiveStatuses = ['Call Picked Up', 'Call On Voice Mail'];
        const neutralStatuses = ['Attempt Not Made Yet'];
        const negativeStatuses = ['Call Disconnected'];

        const pos = calls.filter(status => positiveStatuses.includes(status)).length;
        const neu = calls.filter(status => neutralStatuses.includes(status)).length;
        const neg = calls.filter(status => negativeStatuses.includes(status)).length;

        this.callKpis = {
            attempts: calls.length,
            outcomes: [
                { label: 'Positive Outcome', count: pos, percentage: calls.length ? ((pos / calls.length) * 100).toFixed(2) : '0.00', variant: 'success' },
                { label: 'Neutral Outcome', count: neu, percentage: calls.length ? ((neu / calls.length) * 100).toFixed(2) : '0.00', variant: 'warning' },
                { label: 'Negative Outcome', count: neg, percentage: calls.length ? ((neg / calls.length) * 100).toFixed(2) : '0.00', variant: 'error' }
            ]
        };

        // Outcome KPIs
        const outcomeMap = contacts.reduce((map, c) => {
            if (c.Outcome__c) {
                map[c.Outcome__c] = (map[c.Outcome__c] || 0) + 1;
            }
            return map;
        }, {});

        this.outcomeKpis = [
            { label: 'Opportunities Created', count: outcomeMap['Create Opportunity'] || 0 },
            { label: 'No Priority', count: outcomeMap['No Priority at the moment'] || 0 },
            { label: 'With Competitor', count: outcomeMap['With Competitor'] || 0 },
            { label: 'Unresponsive', count: outcomeMap['Unresponsive'] || 0 }
        ];

        const lastWeekLinkedInMsgs = contacts.filter(contact => {
            const lm1 = new Date(contact.LM1_TimeStamp__c);
            const lm2 = new Date(contact.LM2_TimeStamp__c);
            const gridCreatedDate = new Date(contact.gridCreatedDate);

            return lm1 >= gridCreatedDate || lm2 >= gridCreatedDate;
        }).length;

        this.efficiencyKpis = [
            { label: 'Avg LinkedIn Messages Sent/week', value: Math.round(lastWeekLinkedInMsgs) },
            { label: 'Avg LinkedIn Email Sent/week', value: Math.round(lastWeekLinkedInMsgs) },
            { label: 'Avg Call Attempts made/week', value: Math.round(lastWeekLinkedInMsgs) },
        ];

    }

    handleFilterChange(event) {
        this.selectedOutreachOwner = event.target.value;

        if (!this.selectedOutreachOwner || this.selectedOutreachOwner === "All") {
            this.filteredGridData = [...this.gridData];
        } else {
            this.filteredGridData = this.gridData.filter(
                record => record.newOwnerId === this.selectedOutreachOwner
            );
        }
    }

    handleFilterChangeForLinkedInStatus(event) {
        this.selectedLinkedInStatus = event.target.value;

        if (!this.selectedGrid || this.selectedGrid == null) {
            this.showToast('error', 'Please select the grid first.', 'error');
            return;
        }

        if (!this.selectedLinkedInStatus || this.selectedLinkedInStatus === "All") {
            this.filteredGridData = [...this.gridData];
        } else {
            this.filteredGridData = this.gridData.filter(
                record => record.linkedInStatus === this.selectedLinkedInStatus
            );
        }
        this.selectedLinkedInMessageStatus = '';
        this.selectedLinkedInMessageStatus2 = '';
        this.selectedLinkedInEmailStatus = '';
        this.selectedLinkedInEmailStatus2 = '';
    }

    handleFilterChangeForLinkedInMessage(event) {
        this.selectedLinkedInMessageStatus = event.target.value;
        if (!this.selectedGrid || this.selectedGrid == null) {
            this.showToast('error', 'Please select the grid first.', 'error');
            return;
        }
        if (!this.selectedLinkedInMessageStatus || this.selectedLinkedInMessageStatus === "All") {
            this.filteredGridData = [...this.gridData];
        } else {
            this.filteredGridData = this.gridData.filter(
                record => record.linkedinMessage1Status === this.selectedLinkedInMessageStatus
            );
        }
        this.selectedLinkedInStatus = '';
        this.selectedLinkedInMessageStatus2 = '';
        this.selectedLinkedInEmailStatus = '';
        this.selectedLinkedInEmailStatus2 = '';
    }

    handleFilterChangeForLinkedInMessage2(event) {
        this.selectedLinkedInMessageStatus2 = event.target.value;
        if (!this.selectedGrid || this.selectedGrid == null) {
            this.showToast('error', 'Please select the grid first.', 'error');
            return;
        }
        if (!this.selectedLinkedInMessageStatus2 || this.selectedLinkedInMessageStatus2 === "All") {
            this.filteredGridData = [...this.gridData];
        } else {
            this.filteredGridData = this.gridData.filter(
                record => record.linkedinMessage2Status === this.selectedLinkedInMessageStatus2
            );
        }
        this.selectedLinkedInStatus = '';
        this.selectedLinkedInMessageStatus = '';
        this.selectedLinkedInEmailStatus = '';
        this.selectedLinkedInEmailStatus2 = '';
    }

    handleFilterChangeForLinkedInEmail(event) {
        this.selectedLinkedInEmailStatus = event.target.value;
        if (!this.selectedGrid || this.selectedGrid == null) {
            this.showToast('error', 'Please select the grid first.', 'error');
            return;
        }
        if (!this.selectedLinkedInEmailStatus || this.selectedLinkedInEmailStatus === "All") {
            this.filteredGridData = [...this.gridData];
        } else {
            this.filteredGridData = this.gridData.filter(
                record => record.email1Status === this.selectedLinkedInEmailStatus
            );
        }
        this.selectedLinkedInStatus = '';
        this.selectedLinkedInMessageStatus = '';
        this.selectedLinkedInMessageStatus2 = '';
        this.selectedLinkedInEmailStatus2 = '';
    }

    handleFilterChangeForLinkedInEmail2(event) {
        this.selectedLinkedInEmailStatus2 = event.target.value;
        if (!this.selectedGrid || this.selectedGrid == null) {
            this.showToast('error', 'Please select the grid first.', 'error');
            return;
        }
        if (!this.selectedLinkedInEmailStatus2 || this.selectedLinkedInEmailStatus2 === "All") {
            this.filteredGridData = [...this.gridData];
        } else {
            this.filteredGridData = this.gridData.filter(
                record => record.email2Status === this.selectedLinkedInEmailStatus2
            );
        }
        this.selectedLinkedInStatus = '';
        this.selectedLinkedInMessageStatus = '';
        this.selectedLinkedInMessageStatus2 = '';
        this.selectedLinkedInEmailStatus = '';
    }

    onClickConnectOnLinkedIn(event) {
        this.selectedContactId = '';
        this.contactname = '';

        const contactId = event.target.dataset.id;
        if (!contactId) {
            this.showToast('error', 'Invalid Contact ID', 'error');
            return;
        }

        const record = this.filteredGridData.find(rec => rec.contact.Id === contactId);
        if (!record) {
            this.showToast('error', 'Contact not found', 'error');
            return;
        }

        const allowedStatuses = ['Not Connected', 'Invitation Rejected'];
        if (allowedStatuses.includes(record.linkedInStatus)) {
            this.selectedContactId = contactId;
            this.contactname = event.target.dataset.contactname;
            this.showModalSendRequest = true;
        } else {
            this.showToast('info', 'LinkedIn Invitation Already Sent.', 'info');
        }
    }


    handleMessageChange(event) {
        this.message = event.target.value;
        if (this.message.trim()) {
            this.showErrorMessage = false;
        }
    }
    get remainingCharacters() {
        return 300 - (this.message ? this.message.length : 0);
    }
    get isSendDisabled() {
        return !this.message || this.message.trim().length === 0;
    }

    async handleSendInvitation() {
        if (!this.message?.trim()) {
            this.showErrorMessage = true;
            return;
        }

        if (!this.selectedContactId) {

            return;
        }

        try {
            const result = await sendLinkedInRequest({
                selectedContactId: this.selectedContactId,
                messageSent: this.message
            });
            this.fetchContactStatusIds = [];
            this.fetchContactStatusIds = this.selectedContactId;
            if (result?.status === 'success') {
                this.showToast('Success', result.message, 'success');
                this.fetchContactStatus(this.fetchContactStatusIds);
                this.showModalSendRequest = false;
                this.selectedContactId = '';
            } else if (result?.status === 'warning') {
                this.showToast('Warning', result.message, 'warning');
                this.showModalSendRequest = false;
                this.selectedContactId = '';
            } else {
                this.showToast('Error', result?.message || 'Failed to send LinkedIn Invitation.', 'error');
                this.showModalSendRequest = false;
                this.selectedContactId = '';
            }
            this.message = '';
        } catch (error) {

            this.showToast('Error', 'An unexpected error occurred.', 'error');
            this.showModalSendRequest = false;
            this.selectedContactId = '';

        }
    }

    fetchContactStatus(contactId = null) {
        this.fetchGridData();
        getContactStatus({ contactId })
            .then((data) => {
                const mergedData = this.KPIsData.map(item => {
                    const updated = data.find(d => d.Id === item.contact.Id);
                    if (updated) {
                        return {
                            ...item,
                            contact: {
                                ...item.contact,
                                ...updated
                            }
                        };
                    }
                    return item;
                });

                this.KPIsData = mergedData;

                this.fetchKPIsData();

                console.log('fetchContactStatus DATA:', data);
                if (!Array.isArray(data) || data.length === 0) {
                    return;
                }
                const contactMap = new Map(data.map(c => [c.Id, c]));

                const updateContactFields = (contact, updatedContact) => ({
                    ...contact,
                    linkedInStatus: updatedContact.LinkedIn_Connection_Status__c,
                    iconClass1: this.getIconClass1(updatedContact.LinkedIn_Connection_Status__c),
                    linkedinMessage1Status: updatedContact.LinkedIn_Message_1__c,
                    iconClass2LinkedInMessage1: this.getIconClass2(updatedContact.LinkedIn_Message_1__c),
                    linkedinMessage2Status: updatedContact.LinkedIn_Message_2__c,
                    iconClass2LinkedInMessage2: this.getIconClass2(updatedContact.LinkedIn_Message_2__c),
                    email1Status: updatedContact.Email_1__c,
                    iconClassEmail1: this.getIconClass3(updatedContact.Email_1__c),
                    email2Status: updatedContact.Email_2__c,
                    iconClassEmail2: this.getIconClass3(updatedContact.Email_2__c),
                    callAttemptIcon1: this.getIconClassCallAttempt(updatedContact.Call_Attempt_1__c),
                    callAttemptIcon2: this.getIconClassCallAttempt(updatedContact.Call_Attempt_2__c),
                    callAttemptIcon3: this.getIconClassCallAttempt(updatedContact.Call_Attempt_3__c),
                    callAttemptIcon4: this.getIconClassCallAttempt(updatedContact.Call_Attempt_4__c),
                    callAttemptIcon5: this.getIconClassCallAttempt(updatedContact.Call_Attempt_5__c),
                    description: updatedContact.Notes__c || 'No notes available',
                    newOwnerId: updatedContact.Contact_Outreach_Owner__r?.Name || 'N/A'
                });

                this.filteredGridData = this.filteredGridData.map(contact => {
                    let updatedContact;

                    if (contactId) {
                        const isMatching = Array.isArray(contactId)
                            ? contactId.includes(contact.contact?.Id)
                            : contact.contact?.Id === contactId;

                        if (isMatching) {
                            updatedContact = contactMap.get(contact.contact?.Id);
                        }
                    } else {
                        updatedContact = contactMap.get(contact.contact?.Id);
                    }

                    return updatedContact ? updateContactFields(contact, updatedContact) : contact;
                });

                this.gridData = [...this.filteredGridData];

            })
            .catch((error) => {
                console.error(error);
                this.showToast('Error', 'Failed to fetch contact statuses.', 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

    getIconClass1(status) {
        const statusClasses = {
            'Not Connected': 'grey-circle',
            'Invitation Sent': 'yellow-circle',
            'Connected': 'green-circle',
            'Invitation Rejected': 'red-circle'
        };
        return statusClasses[status] || 'grey-circle';
    }

    getIconClass2(status) {
        const statusClasses = {
            'Not Sent': 'grey-circle',
            'Message Sent': 'yellow-circle',
            'Message Read': 'blue-circle',
            'Message Responded': 'green-circle'
        };
        return statusClasses[status] || 'grey-circle';
    }
    getIconClass3(status) {
        const statusClasses = {
            'Not Sent': 'grey-circle',
            'Email Sent': 'yellow-circle',
            'Email Read': 'blue-circle',
            'Email Responded': 'green-circle'
        };
        return statusClasses[status] || 'grey-circle';
    }
    onClickLinkedInMessage1(event) {
        this.selectedRowId = '';
        const contactId = event.currentTarget.dataset.id;
        const contactName = event.currentTarget.dataset.contactname;
        const contactFirstName = event.currentTarget.dataset.contactfname;
        const contactLastName = event.currentTarget.dataset.contactlname;
        const outreachOwner = event.currentTarget.dataset.outreachownername;
        const title = event.currentTarget.dataset.title;
        const accountname = event.currentTarget.dataset.accountname;

        const record = this.filteredGridData.find(rec => rec.contact.Id === contactId);

        if (record && record.linkedinMessage1Status === 'Not Sent') {
            this.selectedContact = {
                id: contactId,
                name: contactName,
                outreachOwner: outreachOwner,
                title: title,
                accountname: accountname
            };

            this.placeholderOptions = [
                { label: 'Contact Full Name', value: contactName || '' },
                { label: 'Contact First Name', value: contactFirstName || '' },
                { label: 'Contact Last Name', value: contactLastName || '' },
                { label: 'Company Name', value: accountname || '' },
                { label: 'Title', value: title || '' },
                { label: 'Outreach Owner', value: outreachOwner || '' }
            ];

            this.placeholderOptions = [...this.placeholderOptions];

            this.selectedRowId = contactId;
            this.showLinkedinMessageTemplate1 = false;

            setTimeout(() => {
                this.showLinkedinMessageTemplate1 = true;
                this.isMessage1Open = true;
            }, 0);
        } else {
            this.showToast('info', 'LinkedIn Message 1 Already sent.', 'info');
        }
    }


    handleTemplateSelection1(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedTemplate = this.messageTemplates.find(t => t.Id === selectedId);
    
        if (selectedTemplate && this.selectedContact) {
            this.linkedinSubject1 = selectedTemplate.Subject
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner name');
    
            this.linkedinMessage1 = selectedTemplate.Body
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner name');
    
            // Force reactivity
            this.linkedinSubject1 = `${this.linkedinSubject1}`;
            this.linkedinMessage1 = `${this.linkedinMessage1}`;
        }
    }
    

    handleSubjectChange1(event) {
        this.linkedinSubject1 = event.target.value;
    }

    handleMessageChange1(event) {
        this.linkedinMessage1 = event.target.value;
    }
    handleCloseLinkedinMessage1() {
        this.showLinkedinMessageTemplate1 = false;
        this.linkedinMessage1 = '';
        this.linkedinSubject1 = '';
        this.selectedContact = '';
        this.isMessage1Open = false;
        this.isMessage2Open = false;

    }
    cursorPos = { start: 0, end: 0 };

    handleCursorMove(event) {
        this.currentInput = event.target.dataset.field;
        this.cursorPos = {
            start: event.target.selectionStart,
            end: event.target.selectionEnd
        };
    }

    handlePlaceholderChange(event) {
        const placeholderKey = event.target.value;
        const placeholderText = `${placeholderKey}`;

        const fld = this.template.querySelector(
            `[data-field="${this.currentInput}"]`
        );
        if (!fld) { return; }

        const { start, end } = this.cursorPos;
        const val = fld.value;
        const newVal = val.slice(0, start)
            + ' ' + placeholderText + ' '
            + val.slice(end);


        fld.value = newVal;
        this[this.currentInput] = newVal;

        const newCursor = start + placeholderText.length;
        setTimeout(() => {
            fld.focus();
            fld.setSelectionRange(newCursor, newCursor);
            this.cursorPos = { start: newCursor, end: newCursor };
        }, 0);
    }

    handleSubjectChange11(event) {
        this.EmailSubject1 = event.target.value;
    }

    handleMessageChange11(event) {
        this.EmailMessage1 = event.target.value;
    }

    handleCloseLinkedinMessage2() {
        this.showLinkedinMessageTemplate2 = false;
        this.linkedinMessage2 = '';
        this.linkedinSubject2 = '';
        this.selectedContact = '';

    }
    async handleSendLinkedInMessage1() {
        if (!this.selectedContact || !this.selectedContact.id) {
            this.showToast('Warning', 'Please select a contact before sending a message.', 'warning');
            return;
        }

        if (!this.linkedinMessage1?.trim()) {
            this.showToast('Warning', 'Please enter a valid message.', 'warning');
            return;
        }

        this.isProcessing = true;

        try {
            const result = await SendLinkedInMessage1({
                contactId: this.selectedContact.id,
                message: this.linkedinMessage1,
                subject: this.linkedinSubject1
            });

            this.fetchContactStatusIds = [];
            this.fetchContactStatusIds = this.selectedContact.id;
            this.showToast('Success', result, 'success');
            this.fetchContactStatus(this.fetchContactStatusIds);

            this.showLinkedinMessageTemplate1 = false;
            this.linkedinSubject1 = '';
            this.linkedinMessage1 = '';
            this.linkedinSubject2 = '';
            this.linkedinMessage2 = '';

        } catch (error) {
            this.showToast('Error', 'Failed to send LinkedIn Message.', 'error');
        } finally {
            this.isProcessing = false;
        }
    }


    onClickLinkedInMessage2(event) {
        this.selectedRowId = '';
        const contactId = event.currentTarget.dataset.id;
        const contactName = event.currentTarget.dataset.contactname;
        const contactFirstName = event.currentTarget.dataset.contactfname;
        const contactLastName = event.currentTarget.dataset.contactlname;
        const outreachOwner = event.currentTarget.dataset.outreachownername;
        const title = event.currentTarget.dataset.title;
        const accountname = event.currentTarget.dataset.accountname;

        const record = this.filteredGridData.find(rec => rec.contact.Id === contactId);

        if (!record) {
            this.showToast('error', 'Contact not found.', 'error');
            return;
        }

        if (record.linkedinMessage1Status === 'Not Sent') {
            this.showToast('info', 'LinkedIn Message 1 Not sent.', 'info');
            return;
        }

        if (record.linkedinMessage2Status === 'Not Sent') {
            this.selectedContact = {
                id: contactId,
                name: contactName,
                outreachOwner: outreachOwner,
                title: title,
                accountname: accountname
            };

            this.placeholderOptions = [
                { label: 'Contact Full Name', value: contactName || '' },
                { label: 'Contact First Name', value: contactFirstName || '' },
                { label: 'Contact Last Name', value: contactLastName || '' },
                { label: 'Company Name', value: accountname || '' },
                { label: 'Title', value: title || '' },
                { label: 'Outreach Owner', value: outreachOwner || '' }

            ];
            this.selectedRowId = contactId;
            this.showLinkedinMessageTemplate2 = false;
            setTimeout(() => {
                this.showLinkedinMessageTemplate2 = true;
                this.isMessage2Open = true;
            }, 0);
        } else {
            this.showToast('info', 'LinkedIn Message 2 Already sent.', 'info');
        }
    }


    handleTemplateSelection2(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedTemplate = this.messageTemplates.find(t => t.Id === selectedId);

        if (selectedTemplate && this.selectedContact) {
            this.linkedinSubject2 = selectedTemplate.Subject
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first Name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact Name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner Name');


            let messageBody = selectedTemplate.Body
                .replaceAll('${this.selectedContact.title}', this.selectedContact.title || 'your title')
                .replaceAll('${this.selectedContact.accountname}', this.selectedContact.accountname || 'your company')
                .replaceAll('${this.selectedContact.contactLastName}', this.selectedContact.contactLastName || 'your last name')
                .replaceAll('${this.selectedContact.contactFirstName}', this.selectedContact.contactFirstName || 'your first Name')
                .replaceAll('${this.selectedContact.contactName}', this.selectedContact.name || 'your contact Name')
                .replaceAll('${this.selectedContact.owtreachOwner}', this.selectedContact.outreachOwner || 'your outreach owner Name');

        }
    }

    handleSubjectChange2(event) {
        this.linkedinSubject2 = event.target.value;
    }

    handleMessageChange2(event) {
        this.linkedinMessage2 = event.target.value;
    }

    async handleSendLinkedInMessage2() {
        if (!this.selectedContact || !this.selectedContact.id) {
            this.showToast('Warning', 'Please select a contact before sending a message.', 'warning');
            return;
        }

        if (!this.linkedinMessage2?.trim()) {
            this.showToast('Warning', 'Please enter a valid message.', 'warning');
            return;
        }

        this.isProcessing = true;

        try {
            const result = await SendLinkedInMessage2({
                contactId: this.selectedContact.id,
                message: this.linkedinMessage2,
                subject: this.linkedinSubject2
            });
            this.fetchContactStatusIds = [];
            this.fetchContactStatusIds = this.selectedContact.id;
            this.showToast('Success', result, 'success');
            this.fetchContactStatus(this.fetchContactStatusIds);

            this.showLinkedinMessageTemplate2 = false;
            this.linkedinSubject2 = '';
            this.linkedinMessage2 = '';

        } catch (error) {
            this.showToast('Error', 'Failed to send LinkedIn Message.', 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    get developerName() {
        return this.templateName
            .trim()
            .replace(/[^a-zA-Z0-9 ]/g, '')
            .replace(/\s+/g, '_');
    }

    @wire(getEmailTemplateFolders)
    wiredFolders({ data, error }) {
        if (data) {
            data.forEach(folder => {
                if (folder.Name == this.emailFolder) {
                    this.emailFolderId = folder.Id;
                }
                if (folder.Name == this.messageFolder) {
                    this.messageFolderId = folder.Id;
                }
            });
        } else if (error) {
            this.showToast('Error', 'Failed to load folders', 'error');
            console.error('Folder fetch error', error);
        }
    }

    handleCreateEmailTemplate() {
        this.showEmailTemplateCreator = true;
        this.showEmailTemplateModal1 = false;
        this.showEmailTemplateModal2 = false;
        this.modalType = 'Email';
        this.currentFolder = this.emailFolder;
        this.selectedFolder = this.emailFolderId
    }
    handleCreateMessageTemplate() {
        this.showEmailTemplateCreator = true;
        this.showLinkedinMessageTemplate1 = false;
        this.showLinkedinMessageTemplate2 = false;
        this.modalType = 'Message';
        this.currentFolder = this.messageFolder;
        this.selectedFolder = this.messageFolderId;
    }

    handleCloseTemplateModal() {
        this.isSaving = false;
        this.showEmailTemplateCreator = false;
        this.templateName = '';
        this.templateSubject = '';
        this.templateBody = '';
        this.selectedFolder = '';
        if (this.modalType == 'Email' && this.isEmail1Open) {
            this.showEmailTemplateModal1 = true;
        }
        if (this.modalType == 'Email' && this.isEmail2Open) {
            this.showEmailTemplateModal2 = true;
        }
        if (this.modalType == 'Message' && this.isMessage1Open) {
            this.showLinkedinMessageTemplate1 = true;
        }
        if (this.modalType == 'Message' && this.isMessage2Open) {
            this.showLinkedinMessageTemplate2 = true;
        }
    }

    handleNameChange(event) {
        this.templateName = event.target.value;
    }

    handleSubjectChange(event) {
        this.templateSubject = event.target.value;
    }

    handleBodyChange(event) {
        this.templateBody = event.target.value;
    }

    get saveButtonLabel() {
        return this.isSaving ? 'Saving...' : 'Save';
    }
    async handleSaveTemplate() {
        if (!this.templateName || !this.templateSubject || !this.templateBody || !this.selectedFolder) {
            this.showToast('Error', 'All fields are required.', 'error');
            return;
        }

        this.isSaving = true;

        try {
            const result = await createEmailTemplate({
                name: this.templateName,
                developerName: this.developerName,
                subject: this.templateSubject,
                body: this.templateBody,
                folderId: this.selectedFolder
            });

            if (result !== 'Success') {
                throw new Error(result || 'Unexpected error occurred.');
            }

            this.showToast('Success', 'Email template created successfully.', 'success');

            await refreshApex(this.wiredEmailTemplatesResult);
            await refreshApex(this.wiredMessageTemplatesResult);



            this.handleCloseTemplateModal();

        } catch (error) {
            let errorMessage = error?.body?.message || error.message || 'Failed to create email template.';
            this.showToast('Error', errorMessage, 'error');
            this.isSaving = false;
            this.handleCloseTemplateModal();
        }
    }

    opneSendAllInvitationsConfirmModal() {
        this.showConfirmationModalForSendAllInvitation = true;
    }
    handleSendAllInvitations() {
        const actionableContacts = this.filteredGridData
            .filter(record => record.linkedInStatus === 'Not Connected' || record.linkedInStatus === 'Invitation Rejected')
            .map(record => record.contact.Id);

        if (actionableContacts.length === 0) {
            this.showToast('info', 'No contacts available for sending invitations.', 'info');
            return;
        }

        this.showConfirmationModalForSendAllInvitation = false;

        this.isProcessing = true;
        this.invitationCount = 0;
        this.totalContacts = actionableContacts.length;
        this.progress = 0;
        this.progressLabel = `Processing 0/${this.totalContacts} contacts...`;

        sendBulkLinkedInRequests({ contactIdsToInvite: actionableContacts })
            .then(result => {
                const sentContacts = result.invitationSent || [];
                const pendingContacts = result.pendingContacts || [];

                let processedCount = 0;
                sentContacts.forEach(contact => {
                    processedCount++;
                    this.invitationCount = processedCount;
                    this.progress = Math.round((processedCount / this.totalContacts) * 100);
                    this.progressLabel = `Processing ${processedCount}/${this.totalContacts} contacts...`;
                });

                if (sentContacts.length > 0) {
                    this.showToast('success', `Invitations sent successfully to ${sentContacts.length} contacts.`, 'success');
                }
                if (pendingContacts.length > 0) {
                    this.showToast('warning', `${pendingContacts.length} contacts are pending due to limits.`, 'warning');
                }
                this.fetchContactStatusIds = [];
                this.fetchContactStatusIds = sentContacts;
                console.log('apex to lwc bulk invtation sent ids are ', sentContacts);
                this.fetchContactStatus(this.fetchContactStatusIds);
                this.isProcessing = false;
            }).catch(error => {
                console.log('Failed to send invitations. :', error);
                this.showToast('error', 'Failed to send invitations.', 'error');
                this.isProcessing = false;
            })
    }

    handleCancelSendAllInvitaionModal() {
        this.showConfirmationModalForSendAllInvitation = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }
    handleCompanyNameChange(event) {
        this.companyName = event.target.value;
    }

    async handleSearchContacts() {
        this.isLoading = true;
        if (!this.firstName || !this.lastName || !this.companyName) {
            this.showToast('Error', 'Please enter First Name, Last Name, and Company Name.', 'error');
            return;
        }
        try {

            
            const results = await searchContactsApex({
                firstName: this.firstName,
                lastName: this.lastName,
                companyName: this.companyName
            });

            if (results && results.length > 0) {
                this.searchPerformed = true;
                this.searchedContacts = results.map(contact => ({
                    name: contact.name,
                    firstName: contact.firstName,
                    lastName: contact.lastName,
                    location: contact.location,
                    company: contact.company,
                    currentPosition: contact.currentPosition,
                    LinkedIn_URN: contact.LinkedIn_URN,
                    Contact_LinkedIn_Id__c: contact.Contact_LinkedIn_Id__c,
                    profile_url: contact.profile_url,
                    Public_Identifier: contact.Public_Identifier,
                    companyId: contact.companyId,
                }));
            } else {
                this.searchedContacts = [];
                this.showToast('Info', 'No contacts found.', 'info');
            }
        } catch (error) {
            if (error.body && error.body.message.includes('Please enter a valid company name')) {
                this.showToast('Error', 'Please enter a valid company name.', 'error');
            } else {
                this.showToast('Error', 'Error fetching contacts.', 'error');
            }
        } finally {
            this.isLoading = false;
        }
    }


    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedContact = selectedRows.length > 0 ? selectedRows[0] : null;
        this.isHandleImportDisabled = selectedRows.length === 0;
    }

    async handleImportContact() {
        if (!this.selectedContact) {
            this.showToast('Error', 'Please select a contact to import.', 'error');
            this.isSearching = true;
            return;
        }
        try {
            const payload = {
                firstName: this.selectedContact.firstName || '',
                lastName: this.selectedContact.lastName || '',
                linkedinId: this.selectedContact.Contact_LinkedIn_Id__c || '',
                linkedinURN: this.selectedContact.LinkedIn_URN || '',
                profileUrl: this.selectedContact.profile_url || '',
                companyName: this.selectedContact.company || '',
                location: this.selectedContact.location || '',
                gridId: this.selectedGrid || null,
                currentPosition: this.selectedContact.currentPosition || '',
                publicIdentifier: this.selectedContact.Public_Identifier || '',
                companyId: this.selectedContact.companyId || '',
            };
            const newContact = await createContact(payload);
            this.showToast('Success', 'Contact created successfully!', 'success');
            this.clearFields();
            this.fetchGridData();
            this.searchPerformed = false;
        } catch (error) {
            this.showToast('Error', 'Failed to create contact.', 'error');
        } finally {
            this.isLoading = false;
            this.isHandleImportDisabled = true;
        }
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    clearFields() {
        this.firstName = '';
        this.lastName = '';
        this.linkedinId = '';
        this.linkedinURN = '';
        this.profileUrl = '';
        this.companyName = '';
        this.title = '';
        this.location = '';
    }

    handleClose() {
        this.searchContactManually = false;
        this.searchedContacts = [];
        this.firstName = '';
        this.lastName = '';
        this.searchPerformed = false;
        this.isDisabled = true;
    }
    handleCloseModal() {
        this.showModalSendRequest = false;
    }
    handleAddContactManually() {
        this.searchContactManually = true;
    }
    handleCloseAddContactManually() {
        this.searchContactManually = false;
        this.clearFields();
        this.searchedContacts = [];
    }

    handleCloseEnrichContactsModal() {
        this.showEnrichContactsModal = false;
    }

    handleEnrichContact() {
        this.isLoading = true;

        shouldEnrichContactsVisible()
            .then(result => {
                if (result === true) {
                    this.showToast(
                        'Alert',
                        'Your Cognism redeem count is over. Please contact your system administrator to replenish.',
                        'error'
                    );
                    this.isLoading = false;
                    return;
                }

                return enrichContacts({ gridId: this.selectedGrid })
                    .then(enrichedContcts => {
                        console.log('enrichedContcts:', enrichedContcts);

                        this.showToast(
                            'Success',
                            `${enrichedContcts.length} contacts enriched.`,
                            'success'
                        );

                        this.enrichContactsData = enrichedContcts;
                        this.selectedEnrichContactIds = enrichedContcts.map(c => c.Id);

                        if (enrichedContcts.length > 0) {
                            this.showEnrichContactsModal = true;
                        }

                        this.isLoading = false;
                    })
                    .catch(error => {
                        console.error('Error enriching contacts:', error);
                        this.showToast('Error', error.body?.message || error.message , 'error');
                        this.isLoading = false;
                    });
            })
            .catch(error => {
                console.error('Error checking enrich contacts visibility:', error);
                this.showToast('Error', 'Failed to verify redeem count.', 'error');
                this.isLoading = false;
            });
    }


    get disableGetContactBtn() {
        return this.isLoading || this.selectedEnrichContactIds.length === 0;
    }

    handleEnrichContactSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedEnrichContactIds = selectedRows.map(row => row.Id);
    }

    handleGetEmailAndNumbers() {
        this.isLoading = true;
        enrichContactsWithEmailAndPhone({ gridContactIds: this.selectedEnrichContactIds })
            .then(() => {
                this.showToast('Success', 'Contacts enriched with email and phone.', 'success');
                this.handleCloseEnrichContactsModal();
                this.fetchContactStatusIds = [];
                this.fetchContactStatusIds = this.selectedEnrichContactIds;
                this.fetchContactStatus(this.fetchContactStatusIds);
            })
            .catch(error => {
                console.error('Error enriching emails/phones:', error);
                this.showToast('Error', 'Failed to enrich contacts.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}