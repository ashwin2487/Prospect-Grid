import { LightningElement, track, wire } from 'lwc';
import createEmailTemplate from '@salesforce/apex/EmailTemplateController.createEmailTemplate';
import getEmailTemplateFolders from '@salesforce/apex/EmailTemplateController.getEmailTemplateFolders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmailTemplates from '@salesforce/apex/EmailTemplateController.getEmailTemplates';
import getMessageTemplates from '@salesforce/apex/EmailTemplateController.getMessageTemplates';
import { refreshApex } from '@salesforce/apex';
import updateTemplate from '@salesforce/apex/EmailTemplateController.updateTemplate';
import deleteEmailTemplateById from '@salesforce/apex/EmailTemplateController.deleteEmailTemplateById';

export default class CreateTemplate extends LightningElement {
    @track isModalOpen = false;
    @track modalType = 'Email';
    @track templateName = '';
    @track templateSubject = '';
    @track templateBody = '';
    @track isSaving = false;
    @track emailFolder = 'prospectGridEmailTemplates';
    @track messageFolder = 'prospectGridMessageTemplates';
    @track emailFolderId = '';
    @track messageFolderId = '';
    @track selectedFolderId = '';
    @track currentFolder = '';
    @track templates = [];
    @track messageTemplates = [];
    @track isViewModalOpen = false;
    @track isEditModalOpen = false;
    @track viewTemplate = {};
    wiredEmailTemplatesResult;
    wiredMessageTemplatesResult;
    @track selectedPlaceholder = '';
    currentInput = '';
    @track currentTemplateId = '';
    @track isDeleteModalOpen = false;

    @track placeholderOptions = [
        { label: 'Contact Full Name', value: '${this.selectedContact.contactName}' || '' },
        { label: 'Contact First Name', value: '${this.selectedContact.contactFirstName}' || '' },
        { label: 'Contact Last Name', value: '${this.selectedContact.contactLastName}' || '' },
        { label: 'Company Name', value: '${this.selectedContact.accountname}' || '' },
        { label: 'Title', value: '${this.selectedContact.title}' || '' },
        { label: 'Outreach Owner', value: '${this.selectedContact.owtreachOwner}' || '' }
    ];

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
            +' '+ placeholderText+' '
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

    get saveButtonLabel() {
        return this.isSaving ? 'Saving...' : 'Save';
    }

    @wire(getEmailTemplates)
    wiredEmailTemplates(result) {
        this.wiredEmailTemplatesResult = result;
        const { data, error } = result;

        if (data) {
            this.templates = data.map(template => ({
                Id: template.Id,
                Name: template.Name,
                Subject: template.Subject,
                Body: template.Body
            }));
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
        } else if (error) {
            console.error('Error fetching message templates:', error);
            this.messageTemplates = [];
        }
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

    openEmailModal() {
        this.modalType = 'Email';
        this.selectedFolderId = this.emailFolderId;
        this.isModalOpen = true;
        this.currentFolder = this.emailFolder;
    }

    openMessageModal() {
        this.modalType = 'Message';
        this.selectedFolderId = this.messageFolderId;
        this.isModalOpen = true;
        this.currentFolder = this.messageFolder;
    }

    handleCloseTemplateModal() {
        this.isModalOpen = false;
        this.templateName = '';
        this.templateSubject = '';
        this.templateBody = '';
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

    handleViewEmailTemplate(event) {
        const selectedId = event.target.dataset.id;
        this.viewTemplate = this.templates.find(template => template.Id === selectedId);
        this.isViewModalOpen = true;
    }

    handleViewMessageTemplate(event) {
        const selectedId = event.target.dataset.id;
        this.viewTemplate = this.messageTemplates.find(template => template.Id === selectedId);
        this.isViewModalOpen = true;
    }

    handleCloseViewModal() {
        this.isViewModalOpen = false;
        this.viewTemplate = {};
    }
    get developerName() {
        return this.templateName
            .trim()
            .replace(/[^a-zA-Z0-9 ]/g, '')
            .replace(/\s+/g, '_');
    }

    async handleSaveTemplate() {
        if (!this.templateName || !this.templateSubject || !this.templateBody) {
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
                folderId: this.selectedFolderId
            });

            if (typeof result !== 'string' || result !== 'Success') {
                throw new Error(result?.message || 'Unexpected error occurred.');
            }

            await refreshApex(this.wiredEmailTemplatesResult);
            await refreshApex(this.wiredMessageTemplatesResult);

            this.showToast('Success', `${this.modalType} template created successfully.`, 'success');
            this.handleCloseTemplateModal();

        } catch (error) {
            console.log('Failed to save:', error);
            this.showToast('Error', error?.body?.message ||  error.message  || 'Failed to create template.', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async handleEditTemplate() {
        if (!this.templateName || !this.templateSubject || !this.templateBody) {
            this.showToast('Error', 'All fields are required.', 'error');
            return;
        }
        this.isSaving = true;

        try {
            const result = await updateTemplate({
                id: this.currentTemplateId,
                name: this.templateName,
                developerName: this.developerName,
                subject: this.templateSubject,
                body: this.templateBody,
                folderId: this.selectedFolderId
            });

            if (typeof result !== 'string' || result !== 'Success') {
                throw new Error(result?.message || 'Unexpected error occurred.');
            }

            await refreshApex(this.wiredEmailTemplatesResult);
            await refreshApex(this.wiredMessageTemplatesResult);

            this.showToast('Success', `${this.modalType} template Updated successfully.`, 'success');
            this.handleCloseEditTemplateModal();

        } catch (error) {
            console.log('Failed to save:', error);
            this.showToast('Error', error.message || 'Failed to Update template.', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleEditEmailTemplate(event) {
        this.currentTemplateId = event.target.dataset.id;
        this.templateName = event.target.dataset.templatename;
        this.templateSubject = event.target.dataset.subject;
        this.templateBody = event.target.dataset.body;
        this.currentFolder = this.emailFolder;
        this.selectedFolderId = this.emailFolderId;
        this.isEditModalOpen = true;
        this.modalType = 'Email';
    }

    handleEditMessageTemplate(event) {
        this.currentTemplateId = event.target.dataset.id;
        this.templateName = event.target.dataset.templatename;
        this.templateSubject = event.target.dataset.subject;
        this.templateBody = event.target.dataset.body;
        this.currentFolder = this.messageFolder;
        this.selectedFolderId = this.messageFolderId;
        this.isEditModalOpen = true;
        this.modalType = 'Message';
    }
    handleCloseEditTemplateModal() {
        this.isEditModalOpen = false;
        this.templateName = '';
        this.templateSubject = '';
        this.templateBody = '';
        this.currentTemplateId = '';
    }

    templateId;
    handleDeleteModalOpen(event) {
        this.templateId = event.target.dataset.id;
        this.isDeleteModalOpen = true;
    }
    closeDeleteModal() {
        this.isDeleteModalOpen = false;
    }

    async handleDeleteTemplate() {
        await deleteEmailTemplateById({ templateId: this.templateId })
            .then(() => {
                this.showToast('Success', `Email template deleted successfully.`, 'success');
                refreshApex(this.wiredEmailTemplatesResult);
                refreshApex(this.wiredMessageTemplatesResult);

                this.closeDeleteModal();
            })
            .catch(error => {
                console.error("Error deleting template:", error);
                this.showToast('Error', error.body.message, 'error');
            });
    }



    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}