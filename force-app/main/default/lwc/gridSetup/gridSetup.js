import { LightningElement, track, wire } from 'lwc';
import getUserDetails from '@salesforce/apex/UserInfoController.getUserDetails';
import getUsers from '@salesforce/apex/UserInfoController.getUsers';
import getFilteredAccounts from '@salesforce/apex/gridSetupController.getFilteredAccounts';
import getContacts from '@salesforce/apex/gridSetupController.getContacts';
import getProducts from '@salesforce/apex/gridSetupController.getProducts';
import processSelectedAccounts from '@salesforce/apex/gridSetupController.processSelectedAccounts';
import searchLinkedinForCompany from '@salesforce/apex/gridSetupController.searchLinkedinForCompany';
import searchContactsOnLinkedIn from '@salesforce/apex/gridSetupController.searchContactsOnLinkedIn';
import updateSalesforceAccount from '@salesforce/apex/gridSetupController.updateSalesforceAccount';
import createOrUpdateContacts from '@salesforce/apex/gridSetupController.createOrUpdateContacts';
import gridContactProcessing from '@salesforce/apex/gridSetupController.gridContactProcessing';
import searchCompanies from '@salesforce/apex/gridSetupController.searchCompanies';
import searchCompany from '@salesforce/apex/gridSetupController.searchCompany';
import saveNewContact from '@salesforce/apex/gridSetupController.saveNewContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountOwners from '@salesforce/apex/gridSetupController.getAccountOwners';
import sendBulkLinkedInRequests from '@salesforce/apex/gridSetupController.sendBulkLinkedInRequests';
import searchLocation from '@salesforce/apex/gridSetupController.searchLocation';
import searchIndustry from '@salesforce/apex/gridSetupController.searchIndustry';
import searchAccounts from '@salesforce/apex/gridSetupController.searchAccounts';
import createAccount from '@salesforce/apex/gridSetupController.createAccount';
import searchSalesforceIndustry from '@salesforce/apex/gridSetupController.searchSalesforceIndustry';
import { NavigationMixin } from 'lightning/navigation';
import getGrids from '@salesforce/apex/WorkingGridController.getGrids';
import addContactsToExistingGrid from '@salesforce/apex/gridSetupController.addContactsToExistingGrid';
import { refreshApex } from '@salesforce/apex';

const contactColumns = [
    { label: 'Contact Outreach Owner', fieldName: 'contactOutreachOwner', type: 'text' },
    { label: 'First Name', fieldName: 'FirstName', type: 'text' },
    { label: 'Last Name', fieldName: 'LastName', type: 'text' },
    { label: 'Company', fieldName: 'AccountName', type: 'text' },
    { label: 'Title', fieldName: 'Title', type: 'text' },
    { label: 'Location', fieldName: 'Current_Location__c', type: 'text' },
    {
        label: 'LinkedIn Profile', fieldName: 'LinkedIn_Profile__c', type: 'url',
        typeAttributes: { label: { fieldName: 'LinkedIn_Profile__c' }, target: '_blank' }
    }
];

const gridContactColumns = [
    { label: 'Contact ID', fieldName: 'id', type: 'text' },
    { label: 'Name', fieldName: 'name', type: 'text' },
    { label: 'Title', fieldName: 'title', type: 'text' },
    { label: 'Company', fieldName: 'accountName', type: 'text' },
    { label: 'Location', fieldName: 'currentLocation', type: 'text' },
    {
        label: 'LinkedIn',
        fieldName: 'linkedInProfile',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'linkedInProfile' },
            target: '_blank'
        }
    }
];
const contactReceivedColumns = [
    { label: 'Contact OutreachOwner', fieldName: 'selectedContactOutreachOwner', type: 'text' },
    { label: 'Current Company Name', fieldName: 'company', type: 'text' },
    { label: 'Current Position', fieldName: 'currentPosition', type: 'text' },
    { label: 'First Name', fieldName: 'firstName', type: 'text' },
    { label: 'Last Name', fieldName: 'lastName', type: 'text' },
    { label: 'Current Location', fieldName: 'location', type: 'text' },
    {
        label: 'LinkedIn Profile',
        fieldName: 'profile_url',
        type: 'url',
        typeAttributes: { label: { fieldName: 'profile_url' }, target: '_blank' }
    }
];
export default class extends NavigationMixin(LightningElement) {
    debounceTimeout;
    gridContactColumns = gridContactColumns;
    contactReceivedColumns = contactReceivedColumns;
    contactColumns = contactColumns;
    selectedUserId = '';
    selectedContactUserId = '';
    selectedUserName = '';
    selectedContactOutreachOwner = '';
    @track errorMessage;
    @track inputGridName = '';
    @track selectedRowsCreatedContacts = [];
    @track selectedRowsUpdatedContacts = [];
    @track selectedRowsSkippedContacts = [];
    @track GridCreationData = [];
    @track newAccountsList = [];
    @track skippedContactsList = [];
    @track newContacts = [];
    @track newAccounts = [];
    @track createdContactList = [];
    @track updatedContactList = [];
    @track updatedAccounts = [];
    @track updatedContacts = [];
    @track selectedRowsSearchedContacts = [];
    @track conactsSavedInSalesforce = [];
    @track accounts = [];
    @track upDatedAccountInSalesforce = [];
    @track UnipileAccountsResponse = [];
    @track SalesNavigatorAccountsResponse = [];
    @track selectedUnipileAccount = [];
    @track selectedSNAccounts = [];
    @track companyDetails = [];
    @track SNcompanyCreatedAccounts = [];
    @track SNcompanyUpdatedAccounts = []
    @track sendListToUpdateSalesforceAccount = [];
    @track sendListToUpdateSalesNavigatorAccount = [];
    @track searchedContactsOnLinkedIn = [];
    @track contacts = [];
    @track products = [];
    @track grid = [];
    @track selectedRows = [];
    @track selectedRegions = [];
    @track selectedIndustrySN = [];
    @track selectedCompanySN = [];
    @track selectedIndustries = [];
    @track selectedLocation = '';
    @track selectedProductId = [];
    @track seniorityLevelOptions = [];
    @track selectedSeniorityLevel = [];
    @track selectedDepartment = [];
    @track selectedSeniorityLevelList = [];
    @track selectedDepartmentList = [];
    @track filteredOptions = [];
    @track filteredIndustryOptions = [];
    @track filteredIndustrySNOptions = [];
    @track filteredCompanySNOptions = [];
    @track showGridCreationData = false;
    @track showSearchedContactsOnLinkedIn = false;
    @track isModalOpen = false;
    @track showCreatedContacts = false;
    @track isSelectAllAccountsChecked = false;
    @track isSelectAllContactsChecked = false;
    @track selectedAccountId;
    @track showUpdatedAccount = false;
    @track showFoundAccountScreen = false;
    @track showAccountSelectionPageSF = false;
    @track showAccountSelectionPageSN = false;
    @track showLinkedInAccountsScreen = false;
    @track showLinkedInAccountsSNScreen = false;
    @track showContactsScreen = false;
    @track showSetupGridButton = true;
    @track showCompanyDetailsRetreived = false;
    @track showResponseScreen = false;
    @track showLinkedInContactsFound = false;
    @track isLoading = false;
    @track isApplyDisabled = true;
    @track userName = '';
    @track selectedRevenue = '';
    @track selectedHeadCount = '';
    searchTerm;
    searchSNIndustryTerm;
    searchSNCompanyTerm;
    @track searchTermAccount = '';
    @track searchAccounts = '';
    @track gridName = '';
    @track gridId = '';
    @track accountList = [];
    @track contactList = [];
    @track userOptions = [];
    selectedUserId = '';
    @track searchAccountOwner = '';
    @track filteredAccountOwnerOptions = [];
    @track selectedAccountOwner = null;
    allAccountOwners = [];
    filteredCompanyOptions = null;
    filteredCompanyOptions2 = [];
    debounceTimeout;
    @track isReadOnly = true;
    Current_Company_Name__c = '';
    @track showConfirmationModal = false;
    @track isMoreThan100 = false;
    insertedContactIds = [];
    @track selectedHeadCounts = [];
    @track selectedHeadCountsValue = '';
    @track selectedRevenues = [];
    @track selectedRevenueValue = '';
    @track showCreatedAccountDetails = false;
    showSalesforceButton = true;
    showSalesNavigatorButton = true;
    isSnModalOpenOrModal = false;
    @track selectedRelevantContacts = [];
    showSFBtnDisabled = false;
    showSFBtnDisabled = false;
    @track selectedCreatedRows = [];
    @track selectedUpdatedRows = [];
    @track selectedGrid = '';
    @track gridSuggestions = [];
    @track sortBy;
    @track sortDirection;
    @track addConExistingGrid = false;
    @track createNewGridScreen = false;
    wiredGridsResult;
    @track isProcessing = false;


    columnsRetreivedCompnayDetails = [
        { label: 'Salesforce Account Id', fieldName: 'salesforceAccountId', type: 'text' },
        { label: 'Salesforce Account Name', fieldName: 'salesforceAccountName', type: 'text' },
        { label: 'LinkedIn Company Id', fieldName: 'companyId', type: 'text' },
        { label: 'LinkedIn Company Name', fieldName: 'companyName', type: 'text' },
        { label: 'LinkedInCompany Website', fieldName: 'companyWebsite', type: 'url', typeAttributes: { label: { fieldName: 'companyWebsite' }, target: '_blank' } },
        { label: 'LinkedIn Headcount', fieldName: 'companyEmployeeCount', type: 'number' },
        { label: 'LinkedIn Profile', fieldName: 'companyProfileUrl', type: 'url', typeAttributes: { label: { fieldName: 'companyProfileUrl' }, target: '_blank' } },
    ];
    departmentOptions = [
        { label: 'Accounting', value: 'Accounting' },
        { label: 'Administrative', value: 'Administrative' },
        { label: 'Arts and Design', value: 'Arts and Design' },
        { label: 'Community and Social Services', value: 'Community and Social Services' },
        { label: 'Education', value: 'Education' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Healthcare Services', value: 'Healthcare Services' },
        { label: 'Human Resources', value: 'Human Resources' },
        { label: 'Information Technology', value: 'Information Technology' },
        { label: 'Legal', value: 'Legal' },
        { label: 'Marketing', value: 'Marketing' },
        { label: 'Media and Communication', value: 'Media and Communication' },
        { label: 'Military and Protective Services', value: 'Military and Protective Services' },
        { label: 'Operations', value: 'Operations' },
        { label: 'Product Management', value: 'Product Management' },
        { label: 'Purchasing', value: 'Purchasing' },
        { label: 'Quality Assurance', value: 'Quality Assurance' },
        { label: 'Real Estate', value: 'Real Estate' },
        { label: 'Research', value: 'Research' },
        { label: 'Sales', value: 'Sales' },
        { label: 'Customer Success and Support', value: 'Customer Success and Support' },

    ];
    seniorityLevelOptions = [
        { label: 'Owner/Partner', value: 'owner/partner' },
        { label: 'CXO', value: 'cxo' },
        { label: 'Vice President', value: 'vice_president' },
        { label: 'Director', value: 'director' },
        { label: 'Experienced Manager', value: 'experienced_manager' },
        { label: 'Entry Level Manager', value: 'entry_level_manager' },
        { label: 'Strategic', value: 'strategic' },
        { label: 'Senior', value: 'senior' },
        { label: 'Entry Level', value: 'entry_level' },
        { label: 'In Training', value: 'in_training' },
    ];
    ContactsLinkedIncolumns = [
        { label: 'Salesforce Account Id', fieldName: 'salesforceAccountId', type: 'text' },
        { label: 'Salesforce Account Name', fieldName: 'salesforceAccountName', type: 'text' },
        { label: 'Contact Name', fieldName: 'Name', type: 'text' },
        { label: 'Title', fieldName: 'Title', type: 'text' },
        { label: 'Email Id', fieldName: 'Email', type: 'text' },
        { label: 'Phone Number', fieldName: 'Phone', type: 'text' },
        { label: 'LinkedIn Company Name', fieldName: 'name', type: 'text' },
        { label: 'LinkedIn Company Id', fieldName: 'id', type: 'text' },
    ];
    updatedAccountColumns = [
        { label: 'Salesforce Account Id', fieldName: 'Id', type: 'text' },
        { label: 'SalesforceAccount Name', fieldName: 'Name', type: 'text' },
        { label: 'Website', fieldName: 'Website', type: 'text', type: 'url', typeAttributes: { label: { fieldName: 'Website' }, target: '_blank' } },
        { label: 'Headcount', fieldName: 'NumberOfEmployees', type: 'number' },
        { label: 'Profile', fieldName: 'LinkedIn_Profile__c', type: 'url', typeAttributes: { label: { fieldName: 'LinkedIn_Profile__c' }, target: '_blank' } },
    ];
    columns = [
        { label: 'Account Owner', fieldName: 'ownerName', type: 'text' },
        { label: 'Salesforce Account Name', fieldName: 'salesforceAccountName', type: 'text' },
        { label: 'LinkedIn Company Name', fieldName: 'name', type: 'text' },
        { label: 'LinkedIn Company Headcount', fieldName: 'headcount', type: 'number' },
        { label: 'LinkedIn Company Profile', fieldName: 'profile_url', type: 'url', typeAttributes: { label: { fieldName: 'profile_url' }, target: '_blank' } },
    ];
    AccountFoundOnSNcolumns = [
        { label: 'LinkedIn Company Name', fieldName: 'name', type: 'text', sortable: true },
        { label: 'Industry', fieldName: 'industry', type: 'text', sortable: true },
        { label: 'LinkedIn Company Headcount', fieldName: 'headcount', type: 'number', sortable: true },
        { label: 'LinkedIn Company Profile', fieldName: 'profile_url', type: 'url', typeAttributes: { label: { fieldName: 'profile_url' }, target: '_blank' } },
    ];
    columnsCreatedOrupdatedAccounts = [
        { label: 'Salesforce Account Id', fieldName: 'Id', type: 'text' },
        { label: 'Salesforce Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Salesforce Industry', fieldName: 'Industry', type: 'text' },
        { label: 'Created Industry', fieldName: 'IndustryName', type: 'text' },
        { label: 'LinkedIn Headcount', fieldName: 'NumberOfEmployees', type: 'number' },
        { label: 'LinkedIn Profile', fieldName: 'LinkedIn_Profile__c', type: 'url', typeAttributes: { label: { fieldName: 'LinkedIn_Profile__c' }, target: '_blank' } },
    ];
    columnsRetreivedSNCompnayDetails = [
        { label: 'LinkedIn Account Id', fieldName: 'id', type: 'text' },
        { label: 'LinkedIn Company Name', fieldName: 'name', type: 'text' },
        { label: 'LinkedInCompany Website', fieldName: 'companyWebsite', type: 'url', typeAttributes: { label: { fieldName: 'companyWebsite' }, target: '_blank' } },
        { label: 'LinkedIn Headcount', fieldName: 'companyEmployeeCount', type: 'number' },
        { label: 'LinkedIn Profile', fieldName: 'companyProfileUrl', type: 'url', typeAttributes: { label: { fieldName: 'companyProfileUrl' }, target: '_blank' } },
    ];
    accountsColumns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Industry', fieldName: 'Industry', type: 'text' },
        { label: 'Revenue', fieldName: 'AnnualRevenue', type: 'currency', typeAttributes: { currencyCode: 'USD' } },
        { label: 'Headcount', fieldName: 'NumberOfEmployees', type: 'number' }
    ];
    accountIndustry = [
        { label: '--None--', value: 'None' },
        { label: 'Agricultre', value: 'Agricultre' },
        { label: 'Apparel', value: 'Apparel' },
        { label: 'Banking', value: 'Banking' },
        { label: 'Biotechnology', value: 'Biotechnology' },
        { label: 'Chemicals', value: 'Chemicals' },
        { label: 'Communications', value: 'Communications' },
        { label: 'Construction', value: 'Construction' },
        { label: 'Consulting', value: 'Consulting' },
        { label: 'Education', value: 'Education' },
        { label: 'Electronics', value: 'Electronics' },
        { label: 'Energy', value: 'Energy' },
        { label: 'Engineering', value: 'Engineering' },
        { label: 'Entertainment', value: 'Entertainment' },
        { label: 'Enviornmental', value: 'Enviornmental' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Food & Bevarage', value: 'Food & Bevarage' },
        { label: 'Government', value: 'Government' },
        { label: 'Healthcare', value: 'Healthcare' },
        { label: 'Hospitality', value: 'Hospitality' },
        { label: 'Insurance', value: 'Insurance' },
        { label: 'Machinery', value: 'Machinery' },
        { label: 'Manufacturing', value: 'Manufacturing' },
        { label: 'Media', value: 'Media' },
        { label: 'Not For Profit', value: 'Not For Profit' },
        { label: 'Recreation', value: 'Recreation' },
        { label: 'Retail', value: 'Retail' },
        { label: 'Shipping', value: 'Shipping' },
        { label: 'Technology', value: 'Technology' },
        { label: 'Telecommunications', value: 'Telecommunications' },
        { label: 'Transportation', value: 'Transportation' },
        { label: 'Utilities', value: 'Utilities' },
        { label: 'Other', value: 'Other' },
    ];
    accountRevenue = [
        { label: 'Less than $1M', value: 'lessThan1M' },
        { label: '$1M to $5M', value: '1MTo5M' },
        { label: '$5M to $10M', value: '5MTo10M' },
        { label: '$10M to $50M', value: '10MTo50M' },
        { label: '$50M to $100M', value: '50MTo100M' },
        { label: '$100M to $500M', value: '100MTo500M' },
        { label: '$500M to $1B', value: '500MTo1B' },
        { label: 'Over $1B', value: 'over1B' },
    ];
    accountHeadCount = [
        { label: '1-10', value: 'range_1_10' },
        { label: '11-50', value: 'range_11_50' },
        { label: '51-200', value: 'range_51_200' },
        { label: '201-500', value: 'range_201_500' },
        { label: '501-1,000', value: 'range_501_1000' },
        { label: '1,001-5,000', value: 'range_1001_5000' },
        { label: '5,001-10,000', value: 'range_5001_10000' },
        { label: '10,001+', value: 'range_10001_plus' },
    ];
    contactsColumns = [
        { label: 'Account Name', fieldName: 'AccountName', type: 'text' },
        { label: 'Contact Name', fieldName: 'Name', type: 'text' },
        { label: 'Title', fieldName: 'Title', type: 'text' },
        { label: 'Email Id', fieldName: 'Email', type: 'text' },
        { label: 'Phone Number', fieldName: 'Phone', type: 'text' }
    ];

    accountFoundColumn = [
        { label: 'Account Name', fieldName: 'Name', type: 'text', sortable: true },
        { label: 'Industry', fieldName: 'Industry', type: 'text', sortable: true },
        { label: 'Revenue', fieldName: 'AnnualRevenue', type: 'currency', typeAttributes: { currencyCode: 'USD' }, sortable: true },
        { label: 'Headcount', fieldName: 'NumberOfEmployees', type: 'number', sortable: true },
        { label: 'Account Owner', fieldName: 'OwnerName', type: 'text', sortable: true }
    ];

    handleshowAccountSelectionPageSF() {
        this.showAccountSelectionPageSF = true;
        this.showSalesforceButton = true;
        this.showSFBtnDisabled = true;
        this.showSalesNavigatorButton = false;
    }

    handleCloseSFSearchPage() {
        this.selectedRegions = [];
        this.searchTerm = '';
        this.searchAccountOwner = '';
        this.filteredAccountOwnerOptions = [];
        this.selectedAccountOwner = null;
        this.allAccountOwners = [];
        this.selectedRevenues = [];
        this.selectedRevenueValue = null;
        this.selectedHeadCounts = [];
        this.selectedHeadCountsValue = null;
        this.searchTerm = '';
        this.searchAccounts = '';
        this.filteredIndustryOptions = [];
        this.selectedIndustries = [];
        this.showAccountSelectionPageSF = false;
        this.showSalesforceButton = true;
        this.showSalesNavigatorButton = true;
        this.showSNBtnDisabled = false;
        this.showSFBtnDisabled = false;
    }
    handleCloseSNSearchPage() {
        this.searchTerm = '';
        this.selectedHeadCounts = [];
        this.selectedHeadCountsValue = null;
        this.selectedRevenues = [];
        this.selectedRevenueValue = null;
        this.selectedRegions = [];
        this.selectedIndustrySN = [];
        this.selectedCompanySN = [];
        this.filteredOptions = [];
        this.searchSNIndustryTerm = '';
        this.searchSNCompanyTerm = '';
        this.showAccountSelectionPageSN = false;
        this.showSalesforceButton = true;
        this.showSalesNavigatorButton = true;
        this.showSNBtnDisabled = false;
        this.showSFBtnDisabled = false;
    }
    handleshowAccountSelectionPageSN() {
        this.showAccountSelectionPageSN = true;
        this.showSalesforceButton = false;
        this.showSalesNavigatorButton = true;
        this.showSNBtnDisabled = true;
    }

    handleReset() {
        this.selectedRegions = [];
        this.searchTerm = '';
        this.searchAccountOwner = '';
        this.filteredAccountOwnerOptions = [];
        this.selectedAccountOwner = null;
        this.allAccountOwners = [];
        this.selectedRevenues = [];
        this.selectedRevenueValue = null;
        this.selectedHeadCounts = [];
        this.selectedHeadCountsValue = null;
        this.searchTerm = '';
        this.searchAccounts = '';
        this.filteredIndustryOptions = [];
        this.selectedIndustries = [];
    }

    handleSortData(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.SalesNavigatorAccountsResponse];

        cloneData.sort((a, b) => {
            let aVal = a[sortedBy];
            let bVal = b[sortedBy];

            aVal = aVal === null || aVal === undefined || aVal === '' ? -Infinity : aVal;
            bVal = bVal === null || bVal === undefined || bVal === '' ? -Infinity : bVal;

            if (typeof aVal === 'string' && isNaN(aVal)) aVal = aVal.toLowerCase();
            if (typeof bVal === 'string' && isNaN(bVal)) bVal = bVal.toLowerCase();

            if (!isNaN(aVal)) aVal = Number(aVal);
            if (!isNaN(bVal)) bVal = Number(bVal);

            return sortDirection === 'asc'
                ? (aVal > bVal ? 1 : -1)
                : (aVal < bVal ? 1 : -1);
        });

        this.SalesNavigatorAccountsResponse = cloneData;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
    }



    @wire(getUserDetails)
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.Name;
            this.userId = data.Id;
            this.selectedUserId = this.userId;
        } else if (error) {

        }
    }
    @wire(getUsers)
    wiredUsers({ error, data }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
            if (this.userId && this.userOptions.some(option => option.value === this.userId)) {
                this.selectedUserId = this.userId;
            }
        } else if (error) {

        }
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handleAccountsSearch(event) {
        this.searchAccounts = event.target.value?.toLowerCase() || '';

        if (this.searchAccounts) {
            searchSalesforceIndustry({ searchTerm: this.searchAccounts })
                .then(result => {

                    this.filteredIndustryOptions = result.map(industryName => ({
                        label: industryName,
                        value: industryName
                    }));
                })
                .catch(error => {

                    this.filteredIndustryOptions = [];
                });
        } else {
            this.filteredIndustryOptions = [];
        }
    }

    renderedCallback() {
        this.fetchAccountOwners();
    }

    fetchAccountOwners() {
        getAccountOwners()
            .then(result => {
                this.allAccountOwners = result.map(user => ({
                    label: user.Name,
                    value: user.Id
                }));
            })
            .catch(error => {

            });
    }

    handleAccountOwnerSearch(event) {
        this.searchAccountOwner = event.target.value.toLowerCase();
        this.filteredAccountOwnerOptions = this.allAccountOwners.filter(owner =>
            owner.label.toLowerCase().includes(this.searchAccountOwner)
        );
    }

    handleAccountOwnerSelect(event) {
        const selectedId = event.currentTarget.dataset.value;
        this.selectedAccountOwner = this.allAccountOwners.find(owner => owner.value === selectedId);
        this.filteredAccountOwnerOptions = [];
        this.searchAccountOwner = '';
    }

    handleAccountOwnerRemove() {
        this.selectedAccountOwner = null;
    }
    handleIndustrySelect(event) {
        const selectedValue = event.target.dataset.label;
        if (selectedValue) {
            this.selectedIndustries = [...new Set([...this.selectedIndustries, selectedValue])];
        }

        this.searchAccounts = '';
        this.filteredIndustryOptions = [];
    }

    handleIndustryRemove(event) {
        const industryToRemove = event.currentTarget.dataset.value;
        this.selectedIndustries = this.selectedIndustries.filter(industry => industry !== industryToRemove);
    }

    handleAccountRevenue(event) {
        this.selectedRevenueValue = event.target.value;
        if (this.selectedRevenueValue) {
            const revenueOption = this.accountRevenue.find(
                option => option.value === this.selectedRevenueValue
            );
            if (revenueOption && !this.selectedRevenues.some(option => option.value === revenueOption.value)) {
                this.selectedRevenues = [...this.selectedRevenues, revenueOption];
            }
        }
    }

    handleRevenueRemove(event) {
        const valueToRemove = event.target.dataset.value;
        this.selectedRevenues = this.selectedRevenues.filter(option => option.value !== valueToRemove);

        if (this.selectedRevenues.length === 0) {
            this.selectedRevenueValue = null;
        }
    }

    handleAccountHeadCount(event) {
        this.selectedHeadCountsValue = event.target.value;
        if (this.selectedHeadCountsValue) {
            const headCountOption = this.accountHeadCount.find(
                option => option.value === this.selectedHeadCountsValue
            );
            if (headCountOption && !this.selectedHeadCounts.some(option => option.value === headCountOption.value)) {
                this.selectedHeadCounts = [...this.selectedHeadCounts, headCountOption];
            }
        }
    }

    handleAccountHeadCountRemove(event) {
        const valueToRemove = event.target.dataset.value;
        this.selectedHeadCounts = this.selectedHeadCounts.filter(option => option.value !== valueToRemove);

        if (this.selectedHeadCounts.length === 0) {
            this.selectedHeadCountsValue = null;
        }
    }

    handleSearchAccountClick = async () => {
        if (this.selectedIndustries.length === 0 || this.selectedAccountOwner.length === 0) {
            this.showToast('Error', 'Please complete all required field');
            return;
        }

        try {
            const selectedIndustries = this.selectedIndustries || [];
            const selectedAccountOwner = this.selectedAccountOwner ? this.selectedAccountOwner.value : null;

            const revenueRange = this.getMinMaxFromSelections(this.selectedRevenues, 'revenue');
            const headCountRange = this.getMinMaxFromSelections(this.selectedHeadCounts, 'headcount');

            const filters = {
                selectedIndustries,
                selectedAccountOwner,
                selectedRevenue: {
                    min: revenueRange.min,
                    max: revenueRange.max,
                    hasGreaterThanOnly: revenueRange.hasGreaterThanOnly
                },
                selectedHeadCount: {
                    min: headCountRange.min,
                    max: headCountRange.max,
                    hasGreaterThanOnly: headCountRange.hasGreaterThanOnly
                }
            };

            const result = await getFilteredAccounts(filters);
            console.log('Filtered Accounts:', result);

            this.accounts = result.map(account => ({
                ...account,
                OwnerName: account.Owner?.Name || '',
                Industry: account.Industry || account.Linkedin_Industry_Name__c || '',
                AnnualRevenue: account.AnnualRevenue ?? 0
            }));

            this.errorMessage = '';
            this.showAccountSelectionPageSF = false;
            this.showLinkedInAccountsScreen = false;
            this.showContactsScreen = false;
            this.showFoundAccountScreen = true;
            this.showCompanyDetailsRetreived = false;

        } catch (error) {
            this.errorMessage = error.message || 'Unable to fetch accounts. Please try again later.';
            this.showFoundAccountScreen = false;
        }
    };

    handleSortAccounts(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.accounts];

        cloneData.sort((a, b) => {
            let aVal = a[sortedBy];
            let bVal = b[sortedBy];

            aVal = aVal === null || aVal === undefined || aVal === '' ? -Infinity : aVal;
            bVal = bVal === null || bVal === undefined || bVal === '' ? -Infinity : bVal;

            if (typeof aVal === 'string' && isNaN(aVal)) aVal = aVal.toLowerCase();
            if (typeof bVal === 'string' && isNaN(bVal)) bVal = bVal.toLowerCase();

            if (!isNaN(aVal)) aVal = Number(aVal);
            if (!isNaN(bVal)) bVal = Number(bVal);

            return sortDirection === 'asc'
                ? (aVal > bVal ? 1 : -1)
                : (aVal < bVal ? 1 : -1);
        });

        this.accounts = cloneData;
        this.sortBy = sortedBy;
        this.sortDirection = sortDirection;
    }


    getMinMaxFromSelections(selections, type) {
        if (!selections || selections.length === 0) {
            return { min: null, max: null, hasGreaterThanOnly: false };
        }

        const MAX_INT = 2147483647;

        const RANGE_MAP = {
            revenue: {
                'lessThan1M': [0, 1000000],
                '1MTo5M': [1000000, 5000000],
                '5MTo10M': [5000000, 10000000],
                '10MTo50M': [10000000, 50000000],
                '50MTo100M': [50000000, 100000000],
                '100MTo500M': [100000000, 500000000],
                '500MTo1B': [500000000, 1000000000],
                'over1B': [1000000000, MAX_INT],
            },
            headcount: {
                'range_1_10': [1, 10],
                'range_11_50': [11, 50],
                'range_51_200': [51, 200],
                'range_201_500': [201, 500],
                'range_501_1000': [501, 1000],
                'range_1001_5000': [1001, 5000],
                'range_5001_10000': [5001, 10000],
                'range_10001_plus': [10001, MAX_INT],
            }
        };

        let min = null;
        let max = null;
        let hasGreaterThanOnly = false;

        for (const sel of selections) {
            const range = RANGE_MAP[type][sel.value];
            if (!range) continue;

            const isGreaterThanOnly = (
                (type === 'revenue' && sel.value === 'over1B') ||
                (type === 'headcount' && sel.value === 'range_10001_plus')
            );

            if (isGreaterThanOnly) {
                hasGreaterThanOnly = true;
                continue;
            }

            if (min === null || range[0] < min) min = range[0];
            if (max === null || range[1] > max) max = range[1];
        }

        return { min, max, hasGreaterThanOnly };
    }



    handleRowSelectionSearchContacts(event) {
        const selectedRows = event.detail.selectedRows;

        this.selectedRows = selectedRows.map(row => row.Id);

        this.accounts = this.accounts.map(account => ({
            ...account,
            isSelected: this.selectedRows.includes(account.Id)
        }));

        this.isSelectAllAccountsChecked = this.selectedRows.length === this.accounts.length;
    }


    handleSelectAllAccountChange(event) {
        const isSelected = event.target.checked;
        this.accounts = this.accounts.map(account => ({ ...account, isSelected: isSelected }));
        this.selectedRows = isSelected ? this.accounts.map(account => account.Id) : [];
        this.isSelectAllAccountsChecked = isSelected;
    }

    updateSelectAllCheckbox() {
        const totalAccounts = this.accounts.length;
        const selectedAccounts = this.accounts.filter(account => account.isSelected).length;
        this.isSelectAllAccountsChecked = totalAccounts > 0 && selectedAccounts === totalAccounts;
    }

    handleSearchContactsClick() {
        if (this.selectedRows.length > 0) {
            getContacts({ accountId: this.selectedRows })
                .then((result) => {
                    this.contacts = result.map(contact => ({
                        ...contact,
                        AccountName: contact.Account ? contact.Account.Name : '',
                        isSelected: false
                    }));
                    this.showAccountSelectionPageSF = false;
                    this.showLinkedInAccountsScreen = false;
                    this.showFoundAccountScreen = false;
                    this.showContactsScreen = true;
                    this.showCompanyDetailsRetreived = false;
                })
                .catch((error) => {

                });
        } else {
            alert('Please select an account first.');
        }
    }

    connectedCallback() {
        this.fetchProducts();
    }

    fetchProducts() {
        getProducts()
            .then((result) => {
                this.products = result.map(product => ({
                    label: product.Name,
                    value: product.Id
                }));
            })
            .catch((error) => {

            });
    }

    handleProductTypeChange(event) {
        const contactId = event.target.dataset.id;
        const selectedProductId = event.target.value;

        this.contacts = this.contacts.map(contact =>
            contact.Id === contactId ? { ...contact, selectedProductId } : contact
        );
    }

    handleRowSelection(event) {
        const contactId = event.target.dataset.id;
        const isSelected = event.target.checked;

        this.contacts = this.contacts.map(contact =>
            contact.Id === contactId ? { ...contact, isSelected: isSelected } : contact
        );

        this.selectedRows = this.contacts.filter(contact => contact.isSelected).map(contact => contact.Id);
        this.updateSelectAllContactsCheckbox();
    }

    updateSelectAllContactsCheckbox() {
        const totalContacts = this.contacts.length;
        const selectedContacts = this.contacts.filter(contact => contact.isSelected).length;
        this.isSelectAllContactsChecked = totalContacts > 0 && selectedContacts === totalContacts;
    }
    async handleSearchLinkedIn() {

        if (this.selectedRegions.length === 0) {
            this.showToast('Warning', 'Please select at least one locaion.', 'Warning');
            return;
        }

        this.isLoading = true;

        if (!this.selectedRows || this.selectedRows.length === 0) {
            this.showToast('Error', 'No rows selected. Please select rows to add.', 'error');
            this.isLoading = false;
            return;
        }
        const selectedRegionIds = this.selectedRegions.map(region => region.id);
        console.log('accountids are: ', this.selectedRows);
        console.log('locations are ', this.selectedRegions);
        this.showAccountSelectionPageSF = false;
        this.showFoundAccountScreen = false;
        this.showContactsScreen = false;
        this.showLinkedInAccountsScreen = true;
        this.showCompanyDetailsRetreived = false;

        try {
            const result = await searchLinkedinForCompany({ accountIds: this.selectedRows, locations: selectedRegionIds });

            this.isLoading = false;

            if (result && result.length > 0) {
                this.UnipileAccountsResponse = result;
                this.selectedRows = [];
            } else {
                this.showToast('Info', 'No matching companies found.', 'info');
            }
        } catch (error) {
            this.isLoading = false;
            this.showToast('Error', 'Unable to fetch accounts. Please try again later.', 'error');
        }
    }

    handleUnipileAcctRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows.map(row => row.id);

        this.selectedUnipileAccount = this.UnipileAccountsResponse.filter(account =>
            this.selectedRows.includes(account.id)
        );


    }

    handleSNAcctRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows.map(row => row.id);
        this.selectedSNAccounts = this.SalesNavigatorAccountsResponse.filter(account =>
            this.selectedRows.includes(account.id)
        );

    }



    handleShowCompanyDetails() {
        this.isLoading = true;

        this.showCompanyDetailsRetreived = true;
        this.showAccountSelectionPage = false;
        this.showFoundAccountScreen = false;
        this.showContactsScreen = false;
        this.showLinkedInAccountsScreen = false;

        processSelectedAccounts({ selectedAccounts: this.selectedUnipileAccount })
            .then(result => {
                this.isLoading = false;
                this.companyDetails = result;
                this.selectedRows = [];
            })
            .catch(error => {

            });
    }
    handleUpdateOrCreateAccount() {
        this.showCreatedAccountDetails = true;
        this.isLoading = true;
        this.showAccountSelectionPageSN = false;
        this.showLinkedInAccountsSNScreen = false;
        createAccount({ selectedAccounts: this.selectedSNAccounts })
            .then(result => {
                this.SNcompanyCreatedAccounts = result.createdAccount.map(account => {
                    return {
                        ...account,
                        ownerName: account?.Owner?.Name,
                        IndustryName: account.Industry__r ? account.Industry__r.Name__c : 'N/A',
                        id: account.LinkedIn_Id__c,
                        salesforceAccountId: account.Id,
                        salesforceAccountName: account.Name,
                        name: account.Name,
                        headcount: account.NumberOfEmployees,
                        profile_url: account.LinkedIn_Profile__c
                    };
                });

                this.SNcompanyUpdatedAccounts = result.updatedAccount.map(account => {
                    return {
                        ...account,
                        ownerName: account?.Owner?.Name,
                        IndustryName: account.Industry__r ? account.Industry__r.Name__c : 'N/A',
                        id: account.LinkedIn_Id__c,
                        salesforceAccountId: account.Id,
                        salesforceAccountName: account.Name,
                        name: account.Name,
                        headcount: account.NumberOfEmployees,
                        profile_url: account.LinkedIn_Profile__c
                    };
                });
                this.selectedRows = [];
                this.selectedRegions = [];
                this.selectedSNAccounts = [];
            })
            .catch(error => {
                console.log('Error while processed Accounts:', error);
            })
            .finally(() => {
                this.isLoading = false;
            })
            ;
    }

    handleRowSelectionCreated(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedCreatedRows = selectedRows.map(row => row.id);
        this.updateSelectedSNAccounts(); // refresh full list
    }

    handleRowSelectionUpdated(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedUpdatedRows = selectedRows.map(row => row.id);
        this.updateSelectedSNAccounts();
    }

    updateSelectedSNAccounts() {
        const createdAccounts = this.SNcompanyCreatedAccounts.filter(account =>
            this.selectedCreatedRows?.includes(account.id)
        );
        const updatedAccounts = this.SNcompanyUpdatedAccounts.filter(account =>
            this.selectedUpdatedRows?.includes(account.id)
        );

        this.selectedSNAccounts = [...createdAccounts, ...updatedAccounts];
    }

    handleClickSearchContactsOnSalesNavForSN() {
        if (!this.selectedSNAccounts || this.selectedSNAccounts.length === 0) {
            this.showToast('info', 'No accounts selected. Please choose at least one to continue.', 'info');
            return;
        }
        console.log('selectedSNAccounts', this.selectedSNAccounts);
        this.showCreatedAccountDetails = false;
        this.isSNModalOpen = true;
        this.isSnModalOpenOrModal = true;
    }

    handleBackToModal() {
        if (this.isSnModalOpenOrModal) {
            this.isSNModalOpen = true;
        } else {
            this.isModalOpen = true;
        }
        this.showLinkedInContactsFound = false;
    }
    handleRetrievedAccountUpdate(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows.map(row => row.companyId);

        this.sendListToUpdateSalesforceAccount = this.companyDetails.filter(account =>
            this.selectedRows.includes(account.companyId)
        );
    }
    handleRetrievedSNAccountUpdate(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows.map(row => row.companyId);

        this.sendListToUpdateSalesNavigatorAccount = this.companyDetails.filter(account =>
            this.selectedRows.includes(account.companyId)
        );
    }
    async handleUpdateSalesforceAccount() {
        if (this.sendListToUpdateSalesforceAccount.length === 0) {
            this.showToast('Error', 'No Account Details available.', 'error');
            return;
        }

        const companyDetailsForUpdate = this.sendListToUpdateSalesforceAccount;
        try {
            const result = await updateSalesforceAccount({ toUpdateAccountList: JSON.stringify(companyDetailsForUpdate) });

            if (result) {
                this.showAccountSelectionPageSF = false;
                this.showLinkedInAccountsScreen = false;
                this.showContactsScreen = false;
                this.showFoundAccountScreen = false;
                this.showCompanyDetailsRetreived = false;
                this.showUpdatedAccount = true;
                this.upDatedAccountInSalesforce = result;
                this.showToast('Success', 'Accounts updated successfully.', 'success');
            } else {
                this.showToast('Error', 'Failed to update accounts.', 'error');
            }
        } catch (error) {

            this.showToast('Error', 'An error occurred while updating accounts.', 'error');
        }
    }
    handleSearchContactsOnLinkedIn() {
        this.isModalOpen = true;
        this.showCompanyDetailsRetreived = false;
        this.showAccountSelectionPageSF = false;
        this.showFoundAccountScreen = false;
        this.showContactsScreen = false;
        this.showLinkedInAccountsScreen = false;
        this.showLinkedInContactsFound = false;
    }

    handleSeniorityLevelChange(event) {
        this.selectedSeniorityLevel = Array.isArray(event.detail.value) ? event.detail.value : [event.detail.value];
        this.isApplyDisabled = false;
    }

    handleDepartmentChange(event) {
        this.selectedDepartment = Array.isArray(event.detail.value) ? event.detail.value : [event.detail.value];
        this.isApplyDisabled = false;
    }
    handleClickSearchContactsOnSalesNav() {
        this.isModalOpen = true;
        this.showUpdatedAccount = false;
    }

    @wire(searchLocation, { keyword: '$searchTerm' })
    wiredLocations({ error, data }) {

        if (data) {

            this.filteredOptions = Object.entries(data).map(([id, title]) => ({
                id,
                title
            }));

            this.filteredOptions.sort((a, b) => {
                const scoreA = this.getMatchScore(a.title, this.searchTerm);
                const scoreB = this.getMatchScore(b.title, this.searchTerm);
                return scoreB - scoreA;
            });
        } else if (error) {
            this.filteredOptions = [];

        }
    }

    handleRegionSearch(event) {
        const searchKey = event.target.value?.trim() || '';

        clearTimeout(this.debounceTimeout);

        this.debounceTimeout = setTimeout(() => {
            this.searchTerm = searchKey;
        }, 300);
    }

    getMatchScore(title, searchTerm) {
        if (!searchTerm) return 0;

        const lowerTitle = title.toLowerCase();
        const lowerSearchTerm = searchTerm.toLowerCase();

        const firstWord = lowerTitle.split(' ')[0];

        let score = 0;

        if (firstWord.startsWith(lowerSearchTerm)) {
            score += 2;
        }

        const matchCount = (firstWord.match(new RegExp(lowerSearchTerm, 'g')) || []).length;
        score += matchCount;

        return score;
    }

    handleRegionSelect(event) {
        this.isApplyDisabled = false;

        const selectedId = event.currentTarget.dataset.value;
        const selectedTitle = event.currentTarget.dataset.label;
        if (!this.selectedRegions) {
            this.selectedRegions = [];
        }
        if (!this.selectedRegions.some(region => region.id === selectedId)) {
            this.selectedRegions = [...this.selectedRegions, { id: selectedId, title: selectedTitle }];
        }


        this.searchTerm = '';
        this.filteredOptions = [];
    }

    handleRegionRemove(event) {
        const regionToRemove = event.currentTarget.dataset.value;

        if (this.selectedRegions && this.selectedRegions.length > 0) {
            this.selectedRegions = this.selectedRegions.filter(region => region.id !== regionToRemove);
        }
        this.isApplyDisabled = this.selectedRegions.length === 0;
    }


    async applySelectedFilters() {
        this.isLoading = true;

        if (!this.selectedSeniorityLevel.length || !this.selectedDepartment.length || !this.selectedRegions.length) {
            this.isLoading = false;
            this.showToast('Error', 'Please select at least one job title, one department, and one region.', 'error');
            return;
        }

        const regionIds = this.selectedRegions.map(region => region.id);
        this.selectedUnipileAccount = this.selectedUnipileAccount || [];
        this.selectedSeniorityLevelList = Array.from(new Set([...this.selectedSeniorityLevelList, ...this.selectedSeniorityLevel]));
        const excludedSeniorityLevel = this.seniorityLevelOptions
            .map(option => option.value)
            .filter(level => !this.selectedSeniorityLevelList.includes(level));

        this.selectedDepartmentList = Array.from(new Set([...this.selectedDepartmentList, ...this.selectedDepartment]));
        const excludedDepartment = this.departmentOptions
            .map(option => option.value)
            .filter(dep => !this.selectedDepartmentList.includes(dep));
        this.isLoading = true;
        this.showToast('Success', 'Filters applied successfully!', 'success');

        try {
            const result = await searchContactsOnLinkedIn({
                selectedAccounts: this.selectedUnipileAccount,
                includedSeniorityLevel: this.selectedSeniorityLevelList,
                excludedSeniorityLevel: excludedSeniorityLevel,
                includedDepartment: this.selectedDepartmentList,
                excludedDepartment: excludedDepartment,
                selectedRegion: regionIds
            });

            if (!result || result.length === 0) {
                this.showToast('Info', 'No contacts found.', 'info');
                this.searchedContactsOnLinkedIn = [];
                this.showSearchedContactsOnLinkedIn = false;
            } else {
                this.showLinkedInContactsFound = true;
                this.isModalOpen = false;
                this.searchedContactsOnLinkedIn = [...result];
            }
        } catch (error) {
            this.showToast('Error', error?.body?.message || error.message || 'An unknown error occurred.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async applySelectedFiltersForSN() {
        this.isLoading = true;

        if (!this.selectedSeniorityLevel.length || !this.selectedDepartment.length || !this.selectedRegions.length) {
            this.isLoading = false;
            this.showToast('Error', 'Please select at least one job title, one department, and one region.', 'error');
            return;
        }

        const regionIds = this.selectedRegions.map(region => region.id);
        this.selectedSNAccounts = this.selectedSNAccounts.flat() || [];
        this.selectedSeniorityLevelList = Array.from(new Set([...this.selectedSeniorityLevelList, ...this.selectedSeniorityLevel]));
        const excludedSeniorityLevel = this.seniorityLevelOptions
            .map(option => option.value)
            .filter(level => !this.selectedSeniorityLevelList.includes(level));

        this.selectedDepartmentList = Array.from(new Set([...this.selectedDepartmentList, ...this.selectedDepartment]));
        const excludedDepartment = this.departmentOptions
            .map(option => option.value)
            .filter(dep => !this.selectedDepartmentList.includes(dep));
        this.isLoading = true;
        this.showToast('Success', 'Filters applied successfully!', 'success');

        try {
            const result = await searchContactsOnLinkedIn({
                selectedAccounts: this.selectedSNAccounts,
                includedSeniorityLevel: this.selectedSeniorityLevelList,
                excludedSeniorityLevel: excludedSeniorityLevel,
                includedDepartment: this.selectedDepartmentList,
                excludedDepartment: excludedDepartment,
                selectedRegion: regionIds
            });

            if (!result || result.length === 0) {
                this.showToast('Info', 'No contacts found.', 'info');
                this.searchedContactsOnLinkedIn = [];
                this.showSearchedContactsOnLinkedIn = false;
            } else {
                this.showLinkedInContactsFound = true;
                this.isSNModalOpen = false;
                this.searchedContactsOnLinkedIn = [...result];
            }
        } catch (error) {
            this.showToast('Error', error?.body?.message || error.message || 'An unknown error occurred.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
    get selectedContactsCount() {
        return this.selectedRowsSearchedContacts.length;
    }

    handleRetrievedContactsSelection(event) {
        this.selectedRowsSearchedContacts = event.detail.selectedRows.map(row => row.LinkedIn_URN);
    }

    handleGlobalOwnerSelection(event) {
        this.selectedContactUserId = event.detail.value;
        const selectedUser = this.userOptions.find(user => user.value === this.selectedContactUserId);
        this.selectedContactOutreachOwner = selectedUser ? selectedUser.label : 'N/A';
    }

    handleApplyOwnerSelection() {
        if (!this.selectedContactUserId || this.selectedRowsSearchedContacts.length === 0) {
            this.showToast('Error', 'Please select contacts and an outreach owner before applying.', 'error');
            return;
        }

        const selectedUser = this.userOptions.find(user => user.value === this.selectedContactUserId);
        const selectedUserName = selectedUser ? selectedUser.label : 'N/A';

        this.searchedContactsOnLinkedIn = this.searchedContactsOnLinkedIn.map(contact => {
            if (this.selectedRowsSearchedContacts.includes(contact.LinkedIn_URN)) {
                return {
                    ...contact,
                    selectedContactUserId: this.selectedContactUserId,
                    selectedContactOutreachOwner: selectedUserName
                };
            }
            return contact;
        });

        const updatedSelectedContacts = this.searchedContactsOnLinkedIn.filter(
            contact => this.selectedRowsSearchedContacts.includes(contact.LinkedIn_URN)
        );

        const contactMap = new Map(this.selectedRelevantContacts.map(contact => [contact.LinkedIn_URN, contact]));

        updatedSelectedContacts.forEach(contact => {
            contactMap.set(contact.LinkedIn_URN, contact);
        });

        this.selectedRelevantContacts = Array.from(contactMap.values());

        this.selectedRowsSearchedContacts = [];

        this.showToast('Success', 'Outreach Owner applied successfully.', 'success');
    }


    handleImportContacts() {
        this.isLoading = true;

        if (this.selectedRelevantContacts.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please assign owner to at least one contact to import.',
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
            this.isLoading = false;
            return;
        }

        if (!this.selectedContactUserId) {
            this.showToast('Error', 'No contact outreach owner selected.', 'error');
            this.isLoading = false;
            return;
        }

        console.log('this.selectedRelevantContacts', this.selectedRelevantContacts.flat());

        const seenURNs = new Set();

        const contactsToInsert = this.selectedRelevantContacts
            .flat()
            .filter(contact => {
                const urn = contact.LinkedIn_URN;
                if (!urn || seenURNs.has(urn)) return false;
                seenURNs.add(urn);
                return true;
            })
            .map(contact => ({
                FirstName: contact.firstName,
                LastName: contact.lastName,
                Contact_LinkedIn_Id__c: contact.Contact_LinkedIn_Id__c,
                LinkedInURN__c: contact.LinkedIn_URN,
                LinkedIn_Profile__c: contact.profile_url,
                Current_Company_Name__c: contact.company,
                Title: contact.currentPosition,
                Current_Location__c: contact.location,
                Contact_Outreach_Owner__c: contact.selectedContactUserId
            }));


        console.log('contactsToInsert', contactsToInsert);

        if (contactsToInsert.some(contact => !contact.Contact_Outreach_Owner__c)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Some selected contacts do not have an assigned Outreach Owner. Please apply an owner before importing.',
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
            this.isLoading = false;
            return;
        }

        createOrUpdateContacts({ contactList: contactsToInsert })
            .then(response => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contacts imported successfully!',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.showLinkedInContactsFound = false;
                this.processResponse(response);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An error occurred while importing contacts. Please try again.' + error,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    handleCompanyNameChange(event) {
        if (!event.target) {
            return;
        }

        const recordId = event.target.dataset.id;
        if (!recordId) {
            return;
        }

        const searchTerm = event.target.value || '';

        if (searchTerm.length > 2) {
            this.searchAccountsForSkippedContacts(recordId, searchTerm);
        } else {
            this.clearCompanyOptions(recordId);
        }
    }
    handleInputFocus(event) {
        const recordId = event.target.dataset.id;
        this.skippedContactsList = this.skippedContactsList.map(contact => {
            if (contact?.LinkedInURN__c === recordId) {
                return { ...contact, isReadOnly: false, Current_Company_Name__c: '' };
            }
            return contact;
        });
    }
    searchAccountsForSkippedContacts(recordId, searchTerm) {

        searchCompanies({ searchTerm })
            .then(result => {
                if (!Array.isArray(result)) {
                    return;
                }

                this.skippedContactsList = this.skippedContactsList.map(contact => {
                    if (contact?.LinkedInURN__c === recordId) {
                        return {
                            ...contact,
                            filteredCompanyOptions: result.map(account => ({
                                label: account.Name,
                                value: account.Id
                            }))
                        };
                    }
                    return contact;
                });
            })
            .catch(error => {
                console.log('ERROR: search Accounts For Skipped Contacts', error);
                this.clearCompanyOptions(recordId);
            });
    }

    handleSelectCompany(event) {
        const recordId = event.currentTarget?.dataset?.id;
        const selectedAccountId = event.currentTarget?.dataset?.value;
        const selectedCompanyName = event.currentTarget?.dataset?.label;

        if (!recordId || !selectedAccountId || !selectedCompanyName) {
            return;
        }

        if (!Array.isArray(this.skippedContactsList)) {
            return;
        }

        this.skippedContactsList = this.skippedContactsList.map(contact => {
            if (contact?.LinkedInURN__c === recordId) {
                return {
                    ...contact,
                    Current_Company_Name__c: selectedCompanyName,
                    CompanyId: selectedAccountId,
                    isReadOnly: true,
                    filteredCompanyOptions: null,
                };
            }
            return contact;
        });
    }


    handleEdit(event) {
        const recordId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.updateContactState(recordId, field, value);
        this.updateContactState(recordId, 'isEditing', true);
    }

    handleSaveContact(event) {

        const recordId = event.target.dataset.id;
        const accountOwner = this.selectedContactUserId;
        const contactToSave = this.skippedContactsList.find(contact => contact?.LinkedInURN__c === recordId);

        if (!accountOwner) {
            return;
        }
        if (!contactToSave) return;

        this.updateContactState(recordId, 'isSaving', true);
        this.updateContactState(recordId, 'saveError', '');

        saveNewContact({ contactData: contactToSave, outreachOwner: accountOwner })
            .then(response => {

                if (!response) {
                    throw new Error('Invalid response from server');
                }

                const processedContact = {
                    ...response,
                    AccountName: response.Account.Name,
                    contactOutreachOwner: response.Contact_Outreach_Owner__r
                        ? response.Contact_Outreach_Owner__r.Name
                        : 'No Owner'
                };

                this.createdContactList = [...this.createdContactList, processedContact].filter(
                    (contact, index, self) => index === self.findIndex(c => c.Id === contact.Id)
                );

                this.skippedContactsList = this.skippedContactsList.map(contact =>
                    contact?.LinkedInURN__c === recordId
                        ? { ...contact, ...processedContact, isSaved: true, isSaving: false, isEditingCompany: false, filteredCompanyOptions: null, }
                        : contact
                );
            })
            .catch(error => {
                this.updateContactState(recordId, 'isSaving', false);
                this.updateContactState(recordId, 'saveError', 'The contact already exists Or Invalid Company.');
            });
    }

    handleCancelEdit(event) {
        const recordId = event.target.dataset.id;

        this.skippedContactsList = this.skippedContactsList.map(contact =>
            contact?.LinkedInURN__c === recordId
                ? { ...contact, isEditingCompany: false, isReadOnly: true, filteredCompanyOptions: null }
                : contact
        );
    }

    clearCompanyOptions(recordId) {
        this.updateContactState(recordId, 'filteredCompanyOptions', null);
    }
    updateContactState(recordId, field, value) {
        this.skippedContactsList = this.skippedContactsList.map(contact =>
            contact.LinkedInURN__c === recordId ? { ...contact, [field]: value } : contact
        );
    }

    processResponse(response) {
        console.log("RESPONSE:", response);
        if (!response || typeof response !== 'object') {
            return;
        }

        this.createdContactList = (response.newContacts || []).map(contact => ({
            ...contact,
            AccountName: contact.Account ? contact.Account.Name : 'No Account',
            contactOutreachOwner: contact.Contact_Outreach_Owner__r ? contact.Contact_Outreach_Owner__r.Name : 'No Owner',

        }));

        console.log('response.updatedContacts: ', response.updatedContacts);
        this.updatedContactList = (response.updatedContacts || []).map(contact => ({
            ...contact,
            AccountName: contact.Account ? contact.Account.Name : 'No Account',
            contactOutreachOwner: contact.Contact_Outreach_Owner__r ? contact.Contact_Outreach_Owner__r.Name : 'No Owner',

        }));

        this.skippedContactsList = (response.skippedContacts || []).map(contact => ({
            ...contact,
            AccountName: contact.Account ? contact.Account.Name : 'No Account',
            contactOutreachOwner: contact.Contact_Outreach_Owner_Name ? contact.Contact_Outreach_Owner_Name : 'No Owner',
        }));

        this.showResponseScreen = true;
        this.showLinkedInContactsFound = false;
    }

    connectedCallback() {
        this.selectedRowsCreatedContacts = this.createdContactList
            .filter(contact => contact.Contact_Outreach_Owner__c)
            .map(contact => contact.Id);
    }

    @track updatedSelectedContactObjects = [];
    @track createdSelectedContactObjects = [];
    @track skippedSelectedContactObjects = [];

    handleCreatedContactSelection(event) {
        const selectedRowsCreatedContacts = event.detail.selectedRows;


        this.selectedRowsCreatedContacts = selectedRowsCreatedContacts.map(row => row.Id);

        this.createdSelectedContactObjects = selectedRowsCreatedContacts.map(row => ({
            Id: row.Id,
            outreachOwnerId: row.Contact_Outreach_Owner__c
        }));

        console.log('createdSelectedContactObjects', this.createdSelectedContactObjects);
    }

    handleUpdatedContactSelection(event) {
        const selectedRowsUpdatedContacts = event.detail.selectedRows;



        this.selectedRowsUpdatedContacts = selectedRowsUpdatedContacts.map(row => row.Id);

        this.updatedSelectedContactObjects = selectedRowsUpdatedContacts.map(row => ({
            Id: row.Id,
            outreachOwnerId: row.Contact_Outreach_Owner__c
        }));
        console.log('updatedSelectedContactObjects', this.updatedSelectedContactObjects);
    }

    handleSkippedContactSelection(event) {
        const selectedRowsSkippedContacts = event.detail.selectedRows;

        this.selectedRowsSkippedContacts = selectedRowsSkippedContacts.map(row => row.Id);

        this.skippedSelectedContactObjects = selectedRowsSkippedContacts.map(row => ({
            Id: row.Id,
            outreachOwnerId: row.Contact_Outreach_Owner__c
        }));
    }

    handleGridNameInsert(event) {
        this.inputGridName = event.target.value;
    }

    async handleSelectedContactsAddToGrid() {
        this.isLoading = true;

        if (!this.inputGridName || this.inputGridName.trim() === '') {
            this.showToast('Error', 'Grid Name is required.', 'error');
            this.isLoading = false;
            this.showResponseScreen = true;
            return;
        }

        if (!this.selectedUserId) {
            this.showToast('Error', 'Please select an Outreach Owner.', 'error');
            this.isLoading = false;
            this.showResponseScreen = true;
            return;
        }

        const selectedContactsIds = [
            ...(this.updatedSelectedContactObjects || []),
            ...(this.createdSelectedContactObjects || []),
            ...(this.skippedSelectedContactObjects || [])
        ];

        console.log('selectedContactsIds', selectedContactsIds);
        if (selectedContactsIds.length === 0) {
            this.showToast('Error', 'No contacts selected.', 'error');
            this.isLoading = false;
            this.showResponseScreen = true;
            return;
        }

        this.showGridCreationData = true;

        try {
            const result = await gridContactProcessing({
                gridName: this.inputGridName,
                selectedContacts: JSON.stringify(selectedContactsIds),
                outreachOwnerId: this.selectedUserId,
            });

            if (!result || Object.keys(result).length === 0) {
                this.showToast('Info', 'No contacts found.', 'info');
                this.showGridCreationData = false;
                this.isLoading = false;
                return;
            }


            this.gridName = result.newGrid?.Name || 'Unnamed Grid';
            this.gridId = result.newGrid?.Id || '';

            this.accountList = [];
            this.contactList = (result.insertedGridContacts || []).map(con => ({
                id: con.Id,
                name: con.Contact__r?.Name || 'Unknown Contact',
                title: con.Contact__r?.Title || 'N/A',
                accountName: con.Contact__r?.Account?.Name || con.Contact__r?.Account__r?.Name || 'N/A',
                currentLocation: con.Contact__r?.Current_Location__c || 'N/A',
                linkedInProfile: con.Contact__r?.LinkedIn_Profile__c || 'N/A',
                contactLinkedInId: con.Contact__r?.Contact_LinkedIn_Id__c || 'N/A'
            }));


            this.createNewGridScreen = false;

            setTimeout(() => {
                if (this.contactList.length > 100) {
                    this.showToast('Success', `Contacts added to Grid: ${this.gridName} successfully!`, 'success');
                    this.isMoreThan100 = true;
                    this.showConfirmationModal = true;
                } else if (this.contactList.length > 0 && this.contactList.length < 100) {
                    this.showToast('Success', `Contacts added to Grid: ${this.gridName} successfully!`, 'success');
                    this.isMoreThan100 = false;
                    this.showConfirmationModal = true;
                }
            }, 1000);


        } catch (error) {
            this.showToast('Error', error?.body?.message || error?.message || 'An unknown error occurred.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async sendInvitations() {
        this.isProcessing = true;
        try {
            const contactIdsToInvite = this.contactList
                .filter(contact => contact.id)
                .map(contact => contact.id);

            if (contactIdsToInvite.length === 0) {
                this.showToast('Info', 'No contacts to send invitations.', 'info');
                return;
            }
            const result = await sendBulkLinkedInRequests({ contactIdsToInvite });

            if (result && result.pendingContacts) {
                this.pendingContacts = result.pendingContacts;
            } else {
                this.pendingContacts = [];
            }

            let message = `Invitations sent successfully to ${result.invitationSent.length} contacts.`;

            if (this.pendingContacts.length > 0) {
                message += ` ${this.pendingContacts.length} contacts are pending.`;
            }

            if (result.notallowedSentInvitation && result.notallowedSentInvitation.length > 0) {
                message += ` ${result.notallowedSentInvitation.length} contact are not allowed to sent invitation to you.`;
            }

            this.showToast('Success', message, 'success');

        } catch (error) {
            this.showToast('Error', 'Failed to send LinkedIn invitations', 'error');
        } finally {
            this.isProcessing = false;
        }
    }


    handleCancel() {
        this.showConfirmationModal = false;
        this.showResponseScreen = true;
    }

    handleConfirm() {
        this.showConfirmationModal = false;
        this.sendInvitations();
    }

    navigateToWorkingGrid() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Working_Table'
            },
            // state: {
            //     c__selectedValue: this.gridId,
            // }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    handleCloseFinalGridScreen() {
        this.showGridCreationData = false;
        this.handleCloseResponseScreen();
    }
    handleBackCompanyDetailsRetreived() {
        this.showLinkedInContactsFound = false;
        this.showAccountSelectionPageSF = false;
        this.showLinkedInAccountsScreen = true;
        this.showContactsScreen = false;
        this.showFoundAccountScreen = false;
        this.showCompanyDetailsRetreived = false;
        this.companyDetails = [];
    }
    handleBackSNCompanyDetailsRetreived() {
        this.showCreatedAccountDetails = false;
        this.showLinkedInAccountsSNScreen = true;
    }
    closeModal() {
        this.showFoundAccountScreen = false;
        this.showLinkedInAccountsScreen = false;
        this.showLinkedInContactsFound = false;
        this.showCompanyDetailsRetreived = false;
        this.showContactsScreen = false;
        this.showUpdatedAccount = false;
        this.isModalOpen = false;
        this.selectedSeniorityLevel = [];
        this.selectedDepartment = [];
        this.selectedRegions = [];
        this.upDatedAccountInSalesforce = [];
        this.companyDetails = [];
        this.UnipileAccountsResponse = [];
        this.isSelectAllAccountsChecked = false;
        this.isSelectAllContactsChecked = false;
        this.showAccountSelectionPageSF = true;
        this.showSFBtnDisabled = false;

    }
    closeSNModal() {
        this.isSNModalOpen = false;
        this.showAccountSelectionPageSN = false;
        this.showAccountSelectionPageSN = false;
        this.showSalesforceButton = true;
        this.showSalesNavigatorButton = true;
        this.showSNBtnDisabled = false;
        this.filteredIndustrySNOptions = [];
        this.filteredCompanySNOptions = [];
        this.SalesNavigatorAccountsResponse = [];
        this.selectedHeadCounts = [];
        this.selectedHeadCountsValue = null;
        this.selectedRevenues = [];
        this.selectedRevenueValue = null;
        this.selectedRegions = '';
        this.selectedIndustrySN = [];
        this.selectedCompanySN = [];
        this.searchSNIndustryTerm = '';
        this.searchSNCompanyTerm = '';
        this.showLinkedInAccountsSNScreen = false;
        this.selectedSNAccounts = [];
        this.selectedRows = [];
        this.SNcompanyCreatedAccounts = [];
        this.SNcompanyUpdatedAccounts = []
        this.showCreatedAccountDetails = false;

    }
    handleBackModal() {
        this.isModalOpen = false;
        this.selectedSeniorityLevel = [];
        this.selectedDepartment = [];
        this.showUpdatedAccount = true;
        this.selectedSNAccounts = [];
    }
    handleBackSNModal() {
        this.isSNModalOpen = false;
        this.selectedSeniorityLevel = [];
        this.selectedDepartment = [];
        this.showCreatedAccountDetails = true;
    }

    showFoundAccountScreenClose() {
        this.showSalesforceButton = true;
        this.showSalesNavigatorButton = false
        this.showSNBtnDisabled = false;
        this.showAccountSelectionPageSF = true;
        this.searchAccountOwner = '';
        this.filteredAccountOwnerOptions = [];
        this.selectedAccountOwner = null;
        this.allAccountOwners = [];
        this.selectedRevenues = [];
        this.selectedRevenueValue = null;
        this.selectedHeadCounts = [];
        this.selectedHeadCountsValue = null;
        this.searchTerm = '';
        this.searchAccounts = '';
        this.filteredIndustryOptions = [];
        this.selectedIndustries = [];
        this.showLinkedInContactsFound = false;
        this.showLinkedInAccountsScreen = false;
        this.showContactsScreen = true;
        this.showFoundAccountScreen = false;
        this.showCompanyDetailsRetreived = false;
    }

    handleCloseShowUpdatedAccount() {
        this.showCompanyDetailsRetreived = true;
        this.showUpdatedAccount = false;
        this.upDatedAccountInSalesforce = [];
    }
    handleBackToSearchContactModal() {
        this.isSNModalOpen = false;

        this.showCreatedAccountDetails = true;
    }
    handleGoTOContactsFound() {
        this.showAccountSelectionPageSF = false;
        this.showLinkedInContactsFound = false;
        this.showLinkedInAccountsScreen = false;
        this.showContactsScreen = true;
        this.showFoundAccountScreen = false;
        this.showCompanyDetailsRetreived = false;
        this.showUpdatedAccount = false;
    }
    handleBackClickLinkedInAccountsScreen() {
        this.errorMessage = '';
        this.showAccountSelectionPageSF = false;
        this.showLinkedInContactsFound = false;
        this.showFoundAccountScreen = true;
        this.showContactsScreen = false;
        this.showLinkedInAccountsScreen = false;
        this.showCompanyDetailsRetreived = false;
        this.UnipileAccountsResponse = [];
    }
    handleBackClickLinkedInSNAccountsScreen() {
        this.showLinkedInAccountsSNScreen = false;
        this.showAccountSelectionPageSN = true;
    }

    handleBackClickContactsScreen() {
        this.showContactsScreen = false;
        this.showLinkedInContactsFound = false;
        this.showAccountSelectionPageSF = true;
        this.showSFBtnDisabled = false;
        this.showFoundAccountScreen = true;
        this.showLinkedInAccountsScreen = false;
        this.showCompanyDetailsRetreived = false;
    }

    handleCloseResponseScreen() {
        this.showResponseScreen = false;
        this.showAccountSelectionPageSF = true;
        this.showSFBtnDisabled = false;
        selectedUserId = '';
        selectedContactUserId = '';
        selectedUserName = '';
        selectedContactOutreachOwner = '';
        this.errorMessage;
        this.inputGridName = '';
        this.selectedRowsCreatedContacts = [];
        this.selectedRowsUpdatedContacts = [];
        this.selectedRowsSkippedContacts = [];
        this.GridCreationData = [];
        this.newAccountsList = [];
        this.skippedContactsList = [];
        this.newContacts = [];
        this.newAccounts = [];
        this.createdContactList = [];
        this.updatedContactList = [];
        this.updatedAccounts = [];
        this.updatedContacts = [];
        this.selectedRowsSearchedContacts = [];
        this.conactsSavedInSalesforce = [];
        this.accounts = [];
        this.upDatedAccountInSalesforce = [];
        this.UnipileAccountsResponse = [];
        this.selectedUnipileAccount = [];
        this.companyDetails = [];
        this.sendListToUpdateSalesforceAccount = [];
        this.searchedContactsOnLinkedIn = [];
        this.contacts = [];
        this.products = [];
        this.grid = [];
        this.selectedRows = [];
        this.selectedRegions = [];
        this.selectedIndustries = [];
        this.selectedRevenues = [];
        this.filteredIndustrySNOptions = [];
        this.filteredCompanySNOptions = [];
        this.selectedHeadCounts = []
        this.selectedLocation = '';
        this.selectedProductId = [];
        this.seniorityLevelOptions = [];
        this.selectedSeniorityLevel = [];
        this.selectedDepartment = [];
        this.selectedSeniorityLevelList = [];
        this.selectedDepartmentList = [];
        this.filteredIndustryOptions = [];
        this.showGridCreationData = false;
        this.showSearchedContactsOnLinkedIn = false;
        this.isModalOpen = false;
        this.showCreatedContacts = false;
        this.isSelectAllAccountsChecked = false;
        this.isSelectAllContactsChecked = false;
        this.selectedAccountId;
        this.showUpdatedAccount = false;
        this.showFoundAccountScreen = false;
        this.showLinkedInAccountsScreen = false;
        this.showContactsScreen = false;
        this.showSetupGridButton = true;
        this.showCompanyDetailsRetreived = false;
        this.showResponseScreen = false;
        this.showLinkedInContactsFound = false;
        this.isLoading = false;
        this.isApplyDisabled = true;
        this.userName = '';
        this.selectedRevenue = '';
        this.selectedHeadCount = '';
        this.searchTerm = '';
        this.searchTermAccount = '';
        this.searchAccounts = '';
        this.gridName = '';
        this.accountList = [];
        this.contactList = [];
        this.userOptions = [];
        selectedUserId = '';
        this.searchAccountOwner = '';
        this.filteredAccountOwnerOptions = [];
        this.selectedAccountOwner = null;
        allAccountOwners = [];
        filteredCompanyOptions = null;
        debounceTimeout;
        this.isReadOnly = true;
        Current_Company_Name__c = '';
        this.isSnModalOpenOrModal = false;
        this.selectedSeniorityLevelList = [];
        this.selectedDepartmentList = [];
    }

    @wire(searchIndustry, { keyword: '$searchSNIndustryTerm' })
    wiredIndustries({ error, data }) {
        if (data) {
            this.filteredIndustrySNOptions = Object.entries(data).map(([id, title]) => ({
                id,
                title
            }));

            this.filteredIndustrySNOptions.sort((a, b) => {
                const scoreA = this.getMatchScore(a.title, this.searchSNIndustryTerm);
                const scoreB = this.getMatchScore(b.title, this.searchSNIndustryTerm);
                return scoreB - scoreA;
            });
        } else if (error) {
            this.filteredIndustrySNOptions = [];

        }
    }

    handleSNIndustrySearch(event) {
        const searchKey = event.target.value?.trim() || '';

        clearTimeout(this.debounceTimeout);

        this.debounceTimeout = setTimeout(() => {
            this.searchSNIndustryTerm = searchKey;
        }, 300);
    }

    @wire(searchCompany, { keyword: '$searchSNCompanyTerm' })
    wiredCompany({ error, data }) {
        if (data) {
            this.filteredCompanySNOptions = Object.entries(data).map(([id, name]) => ({
                id,
                name
            }));

            this.filteredCompanySNOptions.sort((a, b) => {
                const scoreA = this.getMatchScore(a.name, this.searchSNCompanyTerm);
                const scoreB = this.getMatchScore(b.name, this.searchSNCompanyTerm);
                return scoreB - scoreA;
            });
        } else if (error) {
            this.filteredCompanySNOptions = [];

        }
    }

    handleSNCompanySearch(event) {
        const searchKey = event.target.value?.trim() || '';

        clearTimeout(this.debounceTimeout);

        this.debounceTimeout = setTimeout(() => {
            this.searchSNCompanyTerm = searchKey;
        }, 300);
    }


    handleSNIndustrySelect(event) {

        const selectedId = event.currentTarget.dataset.value;
        const selectedTitle = event.currentTarget.dataset.label;

        if (!this.selectedIndustrySN) {
            this.selectedIndustrySN = [];
        }

        if (!this.selectedIndustrySN.some(region => region.id === selectedId)) {
            this.selectedIndustrySN = [...this.selectedIndustrySN, { id: selectedId, title: selectedTitle }];
        }
        this.searchSNIndustryTerm = null;
        this.filteredIndustrySNOptions = [];
    }

    handleSNCompanySelect(event) {
        const selectedId = event.currentTarget.dataset.value;
        const selectedTitle = event.currentTarget.dataset.label;

        if (!this.selectedCompanySN) {
            this.selectedCompanySN = [];
        }
        if (!this.selectedCompanySN.some(region => region.id === selectedId)) {
            this.selectedCompanySN = [...this.selectedCompanySN, { id: selectedId, name: selectedTitle }];
        }

        this.searchSNCompanyTerm = '';
        this.filteredCompanySNOptions = [];
    }

    handleSNIndustryRemove(event) {
        const industryToRemove = event.currentTarget.dataset.value;

        if (this.selectedIndustrySN && this.selectedIndustrySN.length > 0) {
            this.selectedIndustrySN = this.selectedIndustrySN.filter(industry => industry.id !== industryToRemove);
        }
        this.isApplyDisabled = this.selectedIndustrySN.length === 0;
    }

    handleSNCompanyRemove(event) {
        const companyToRemove = event.currentTarget.dataset.value;

        if (this.selectedCompanySN && this.selectedCompanySN.length > 0) {
            this.selectedCompanySN = this.selectedCompanySN.filter(company => company.id !== companyToRemove);
        }
        this.isApplyDisabled = this.selectedCompanySN.length === 0;
    }
    handleSNSearchReset() {
        this.selectedHeadCounts = [];
        this.selectedHeadCountsValue = null;
        this.selectedRevenues = [];
        this.selectedRevenueValue = null;
        this.selectedRegions = '';
        this.selectedIndustrySN = [];
        this.selectedCompanySN = [];
        this.searchSNIndustryTerm = '';
        this.searchSNCompanyTerm = '';
        this.filteredCompanySNOptions = [];
    }


    handleSearchSNAccountClick() {
        if (this.selectedRevenues.length == 0 || this.selectedHeadCounts == 0 || this.selectedRegions == 0 || this.selectedIndustrySN.length == 0) {
            this.showToast('error', 'Kindly fill in all mandatory fields.', 'error');
            return;
        }
        const revenueRange = this.calculateRevenueRange(this.selectedRevenues);
        const headCountRange = this.calculateHeadCountRange(this.selectedHeadCounts);


        const payload = {
            industries: this.selectedIndustrySN.map(item => item.id),
            regions: this.selectedRegions.map(item => item.id),


            selectedRevenue: {
                min: revenueRange.min,
                max: revenueRange.max,
            },

            selectedHeadCount: {
                min: headCountRange.min,
                max: headCountRange.max,
            },

            companies: this.selectedCompanySN.map(comp => comp.name)

        };

        this.isLoading = true;
        this.showAccountSelectionPageSN = false;
        this.showLinkedInAccountsSNScreen = true;

        searchAccounts({ filterData: JSON.stringify(payload) })
            .then(result => {

                if (result) {
                    const selectedCompanySNSet = new Set(this.selectedCompanySN);

                    result.sort((a, b) => {
                        const aSelected = selectedCompanySNSet.has(a.name);
                        const bSelected = selectedCompanySNSet.has(b.name);

                        if (aSelected === bSelected) return 0;
                        return aSelected ? -1 : 1;
                    });
                    this.isLoading = false;
                    this.SalesNavigatorAccountsResponse = result;
                    this.selectedRows = '';
                } else {
                    this.showToast('Info', 'No matching companies found.', 'info');
                }
            })
            .catch(error => {

                this.errorMessage = 'Something went wrong during account search.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    calculateRevenueRange(selectedRevenues) {
        let minRevenue = Number.MAX_SAFE_INTEGER;
        let maxRevenue = Number.MIN_SAFE_INTEGER;

        selectedRevenues.forEach(revenue => {
            const label = revenue.label;

            if (label.includes('Less than')) {
                const match = label.match(/\$([\d.]+)([MB])/);
                if (match) {
                    let max = parseFloat(match[1]);
                    if (match[2] === 'B') max *= 1000;
                    minRevenue = Math.min(minRevenue, 0);
                    maxRevenue = Math.max(maxRevenue, max);
                }
            } else if (label.includes('Over') && selectedRevenues.length === 1) {
                minRevenue = 1001;
                maxRevenue = 1001;
            } else if (label.includes('Over') && selectedRevenues.length > 1) {
                const match = label.match(/\$([\d.]+)([MB])\s+to\s+\$([\d.]+)([MB])/);
                if (match) {
                    let min = parseFloat(match[1]);
                    if (match[2] === 'B') min *= 1000;
                    minRevenue = Math.min(minRevenue, min);
                }
                maxRevenue = 1001;
            } else {
                const match = label.match(/\$([\d.]+)([MB])\s+to\s+\$([\d.]+)([MB])/);
                if (match) {
                    let min = parseFloat(match[1]);
                    let max = parseFloat(match[3]);

                    if (match[2] === 'B') min *= 1000;
                    if (match[4] === 'B') max *= 1000;

                    minRevenue = Math.min(minRevenue, min);
                    maxRevenue = Math.max(maxRevenue, max);
                }
            }
        });

        console.log('MIN R:', minRevenue, 'MAX R:', maxRevenue);
        return {
            min: minRevenue === Number.MAX_SAFE_INTEGER ? null : Math.floor(minRevenue),
            max: maxRevenue === Number.MIN_SAFE_INTEGER ? null : Math.floor(maxRevenue)
        };
    }


    calculateHeadCountRange(selectedHeadCounts) {
        let minHeadCount = Number.MAX_SAFE_INTEGER;
        let maxHeadCount = Number.MIN_SAFE_INTEGER;
        let hasPlusRange = false;

        // Detect if '+' is selected
        selectedHeadCounts.forEach(headCount => {
            if (headCount.label.includes('+')) {
                hasPlusRange = true;
            }
        });

        selectedHeadCounts.forEach(headCount => {
            const label = headCount.label.replace(/,/g, '');

            if (label.includes('+')) {
                if (selectedHeadCounts.length === 1) {
                    minHeadCount = 10001;
                } else {
                    const min = parseInt(label.match(/\d+/)[0]);
                    minHeadCount = Math.min(minHeadCount, min);
                    // Don't set max
                }
            } else {
                const match = label.match(/(\d+)-(\d+)/);
                if (match) {
                    const min = parseInt(match[1]);
                    const max = parseInt(match[2]);
                    minHeadCount = Math.min(minHeadCount, min);

                    if (!hasPlusRange) {
                        maxHeadCount = Math.max(maxHeadCount, max);
                    }
                }
            }
        });

        const finalMin = minHeadCount === Number.MAX_SAFE_INTEGER ? null : minHeadCount;
        const finalMax = hasPlusRange ? null : (maxHeadCount === Number.MIN_SAFE_INTEGER ? null : maxHeadCount);

        console.log('MIN:', finalMin, 'MAX:', finalMax);

        return {
            min: finalMin,
            max: finalMax
        };
    }



    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    @wire(getGrids)
    wiredGrids(result) {
        this.wiredGridsResult = result;
        if (result.data) {
            this.gridSuggestions = [...result.data]
                .sort((a, b) => a.Name.localeCompare(b.Name))
                .map(grid => ({
                    label: grid.Name,
                    value: grid.Id,
                    outreachOwnerName: grid.Outreach_Owner__r ? grid.Outreach_Owner__r.Name : 'N/A'
                }));
        } else if (result.error) {
            this.gridSuggestions = [];
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
    }

    async handleSelectedContactsAddToExistingGrid() {
        this.isLoading = true;

        if (!this.selectedGrid || this.selectedGridName.trim() === '') {
            this.showToast('Error', 'Please select a Grid.', 'error');
            this.isLoading = false;
            return;
        }

        const selectedContactsIds = [
            ...(this.updatedSelectedContactObjects || []),
            ...(this.createdSelectedContactObjects || []),
            ...(this.skippedSelectedContactObjects || [])
        ];

        if (selectedContactsIds.length === 0) {
            this.showToast('Error', 'No contacts selected.', 'error');
            this.isLoading = false;
            return;
        }

        try {
            const result = await addContactsToExistingGrid({
                gridId: this.selectedGrid,
                selectedContacts: JSON.stringify(selectedContactsIds),
                outreachOwnerId: this.selectedUserId,
            });


            if (!result || Object.keys(result).length === 0) {
                this.showToast('Info', 'No contacts found.', 'info');
                return;
            }

            const addedCount = result.insertedGridContacts?.length || 0;
            const existingCount = result.existingContacts?.length || 0;


            this.gridName = result.existingGrid.Name || 'Unnamed Grid';

            this.accountList = (result.gridAccounts || []).map(acc => ({
                id: acc.Account__c,
                name: acc.Account__r?.Name || 'Unknown Account'
            }));
            this.contactList = (result.insertedGridContacts || []).map(con => ({
                id: con.Id,
                name: con.Name__c || 'Unknown Contact',
                title: con.Title__c || 'N/A',
                accountName: con.Current_Company_Name__c || 'N/A',
                currentLocation: con.Current_Location__c || 'N/A',
                linkedInProfile: con.LinkedIn_Profile__c || 'N/A',
                contactLinkedInId: con.Contact_LinkedIn_Id__c || 'N/A'
            }));

            let message = `${addedCount} contact(s) added to grid successfully.`;
            if (existingCount > 0) {
                message += ` ${existingCount} contact(s) were already in the grid.`;
            }

            this.showToast('Success', message, 'success');
            this.addConExistingGrid = false;

            if (addedCount > 0) {
                this.isMoreThan100 = addedCount > 100;
                this.showConfirmationModal = true;
            }

        } catch (error) {
            this.showToast('Error', error?.body?.message || error.message || 'An unknown error occurred.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleBackForContactsProccessed() {
        this.showResponseScreen = false;
        this.showLinkedInContactsFound = true;
    }

    handleAddToNewGrid() {
        this.createNewGridScreen = true;
        this.addConExistingGrid = false;
    }
    async handleAddToExistingGrid() {
        await refreshApex(this.wiredGridsResult);
        this.addConExistingGrid = true;
        this.createNewGridScreen = false;
    }
    handleGoToWorkingTable() {
        this.navigateToWorkingGrid();
    }
    handleCloseAddGridTemplate() {
        this.createNewGridScreen = false;
        this.addConExistingGrid = false;
    }
}