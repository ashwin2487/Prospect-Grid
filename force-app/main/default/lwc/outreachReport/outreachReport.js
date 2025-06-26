import { LightningElement, track, wire } from 'lwc';
import getUsers from '@salesforce/apex/UserInfoController.getUsers';
import getGridsByUser from '@salesforce/apex/WorkingGridController.getGridsByUser';
import getGridData from '@salesforce/apex/WorkingGridController.getGridData';

export default class OutreachReport extends LightningElement {
    @track selectedUserIds = [];
    @track selectedGridIds = [];
    @track userOptions = [];
    @track gridSuggestions = [];
    @track outreachReportcolumn = [
        { label: 'Account', fieldName: 'accountName', type: 'text', sortable: true, },
        { label: 'Contacts in Grid', fieldName: 'contactsInGrid', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } },
        { label: 'Contacts Reached Out', fieldName: 'contactsReachedOut', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } },
        { label: 'Positive Response', fieldName: 'positiveResponse', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } },
        { label: 'Neutral Response', fieldName: 'neutralResponse', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } },
        { label: 'Negative Response', fieldName: 'negativeResponse', type: 'number', sortable: true, cellAttributes: { alignment: 'center' } }
    ];
    @track summaryGridData = [];
    @track sortBy = 'accountName';
    @track sortDirection = 'asc';

    @wire(getUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {
            console.error('Error fetching users:', error);
            this.userOptions = [];
        }
    }

    handleUserChange(event) {
        this.selectedUserIds = event.detail.value;
        if (this.selectedUserIds.length === 0) {
            this.gridSuggestions = [];
            this.selectedGridIds = [];
            this.summaryGridData = [];
            return;
        }
        this.getGrids();
    }

    handleGridSelect(event) {
        this.selectedGridIds = event.detail.value;
        if (this.selectedGridIds.length === 0) {
            this.summaryGridData = [];
            return;
        }
        this.getOutreachReportData();
    }


    getGrids() {
        getGridsByUser({ outreachOwners: this.selectedUserIds })
            .then(result => {
                console.log('Fetched grids:', result);
                this.gridSuggestions = result.map(grid => ({
                    label: grid.Name,
                    value: grid.Id
                }));
            })
            .catch(error => {
                this.gridSuggestions = [];
                console.error('Error fetching grids:', error);
            });
    }

    getOutreachReportData() {
        getGridData({ gridIds: this.selectedGridIds })
            .then(result => {
                if (result) {
                    this.summaryGridData = this.processSummaryData(result);
                } else {
                    this.summaryGridData = [];
                }
            })
            .catch(error => {
                console.error('Error fetching grid data:', error);
                this.summaryGridData = [];
            });
    }
    get showResetButton() {
        return this.summaryGridData.length > 0;
    }


    processSummaryData(result) {
        const summaryMap = new Map();

        result.forEach(grid => {
            const account = grid.accountName || 'N/A';
            const contact = grid.contact || {};

            if (!summaryMap.has(account)) {
                summaryMap.set(account, {
                    accountName: account,
                    contactsInGrid: 0,
                    contactsReachedOut: 0,
                    positiveResponse: 0,
                    neutralResponse: 0,
                    negativeResponse: 0
                });
            }

            const summary = summaryMap.get(account);
            summary.contactsInGrid += 1;

            const isReachedOut =
                contact.LinkedIn_Message_1__c !== 'Not Sent' ||
                contact.LinkedIn_Message_2__c !== 'Not Sent' ||
                contact.Email_1__c !== 'Not Sent' ||
                contact.Email_2__c !== 'Not Sent';

            if (isReachedOut) summary.contactsReachedOut += 1;

            const outcome = contact.Outcome__c;

            if (outcome === 'Create Opportunity' || outcome === 'Opportunity already created') summary.positiveResponse += 1;

            else if (outcome === 'Not the right stakeholder' || outcome === 'No Priority at the moment') summary.neutralResponse += 1;

            else if (outcome === 'With Competitor' || outcome === 'Unresponsive') summary.negativeResponse += 1;
        });

        return Array.from(summaryMap.values());
    }

    handleSortData(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;

        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;

        const sortedData = [...this.summaryGridData];

        sortedData.sort((a, b) => {
            let aVal = a[sortedBy];
            let bVal = b[sortedBy];

            aVal = aVal === null || aVal === undefined ? '' : aVal;
            bVal = bVal === null || bVal === undefined ? '' : bVal;

            if (typeof aVal === 'string') aVal = aVal.toLowerCase();
            if (typeof bVal === 'string') bVal = bVal.toLowerCase();

            return sortDirection === 'asc' ? (aVal > bVal ? 1 : -1) : (aVal < bVal ? 1 : -1);
        });

        this.summaryGridData = sortedData;
    }

    handleReset() {
        this.selectedUserIds = [];
        this.selectedGridIds = [];
        this.gridSuggestions = [];
        this.summaryGridData = [];
    }

    get columnTotals() {
        if (!this.summaryGridData || this.summaryGridData.length === 0) {
            return [];
        }

        const totals = {
            totalAccounts: new Set(),
            contactsInGrid: 0,
            contactsReachedOut: 0,
            positiveResponse: 0,
            neutralResponse: 0,
            negativeResponse: 0
        };

        this.summaryGridData.forEach(row => {
            totals.totalAccounts.add(row.accountName);
            totals.contactsInGrid += row.contactsInGrid;
            totals.contactsReachedOut += row.contactsReachedOut;
            totals.positiveResponse += row.positiveResponse;
            totals.neutralResponse += row.neutralResponse;
            totals.negativeResponse += row.negativeResponse;
        });

        return [
            { label: 'Total Accounts', value: totals.totalAccounts.size },
            { label: 'Total Contacts', value: totals.contactsInGrid },
            { label: 'Total Reached Out', value: totals.contactsReachedOut },
            { label: 'Total Positive', value: totals.positiveResponse },
            { label: 'Total Neutral', value: totals.neutralResponse },
            { label: 'Total Negative', value: totals.negativeResponse }
        ];
    }
}