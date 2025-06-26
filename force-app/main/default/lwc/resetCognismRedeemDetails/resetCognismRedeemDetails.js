import { api, LightningElement, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateCognismRedeemRecord from '@salesforce/apex/CognismRedeemController.updateCognismRedeemRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class ResetCognismRedeemDetails extends LightningElement {
    @api recordId;
    @track newCognismRedeemCount;
    @track startDate;
    @track endDate;

    handleInputChange(event) {
        this.newCognismRedeemCount = event.target.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleReset() {
        const value = this.newCognismRedeemCount?.toString().trim();

        if (!value) {
            this.showToast('Error', 'Please enter a valid number for the new cognism redeem count.', 'error');
            return;
        }

        const parsedValue = Number(value);

        if (Number.isNaN(parsedValue) || !Number.isInteger(parsedValue)) {
            this.showToast('Error', 'Please enter a valid integer number for the new cognism redeem count.', 'error');
            return;
        }

        if (!this.startDate || !this.endDate) {
            this.showToast('Error', 'Please select both start and end dates.', 'error');
            return;
        }

        if (this.endDate < this.startDate) {
            this.showToast('Error', 'End date must be after start date.', 'error');
            return;
        }

        try {
            const newRecordId = await updateCognismRedeemRecord({
                recordId: this.recordId,
                newRedeemCount: parsedValue,
                startDate: this.startDate,
                endDate: this.endDate
            });

            this.dispatchEvent(new CloseActionScreenEvent());

            this.showToast('Success', 'Cognism redeem count updated successfully.', 'success');

            setTimeout(() => {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newRecordId,
                        objectApiName: 'Cognism_Redeem_ID_Counter__c',
                        actionName: 'view'
                    }
                });
            }, 300);

        } catch (error) {
            console.error('Error updating record:', error);
            this.showToast('Error', error.body.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }
}