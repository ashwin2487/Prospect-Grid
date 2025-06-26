public with sharing class gridSetupController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getFilteredAccounts(
        List<String> selectedIndustries,
        Map<String, Object> selectedRevenue,
        Map<String, Object> selectedHeadCount,
        String selectedAccountOwner
    ) {
        String query = 'SELECT Id, Name, Industry, Linkedin_Industry_Name__c, AnnualRevenue, NumberOfEmployees, OwnerId, Owner.Name FROM Account WHERE Id != NULL';
        
        if (selectedIndustries != null && !selectedIndustries.isEmpty()) {
            query += ' AND (Industry IN :selectedIndustries OR Linkedin_Industry_Name__c IN :selectedIndustries)';
        }
        
        List<String> revenueConditions = new List<String>();
        if (selectedRevenue != null) {
            Decimal minRevenue = (selectedRevenue.containsKey('min') && selectedRevenue.get('min') != null)
                ? (Decimal)selectedRevenue.get('min') : null;
            Decimal maxRevenue = (selectedRevenue.containsKey('max') && selectedRevenue.get('max') != null)
                ? (Decimal)selectedRevenue.get('max') : null;
            Boolean hasGreaterThanOnlyRevenue = (Boolean)selectedRevenue.get('hasGreaterThanOnly');
            
            if (hasGreaterThanOnlyRevenue == true) {
                revenueConditions.add('AnnualRevenue > 1000000000');
            }
            
            if (minRevenue != null && maxRevenue != null) {
                revenueConditions.add('(AnnualRevenue >= ' + minRevenue + ' AND AnnualRevenue <= ' + maxRevenue + ')');
            }
        }
        
        List<String> headCountConditions = new List<String>();
        if (selectedHeadCount != null) {
            Integer minHead = (selectedHeadCount.containsKey('min') && selectedHeadCount.get('min') != null)
                ? ((Decimal)selectedHeadCount.get('min')).intValue() : null;
            Integer maxHead = (selectedHeadCount.containsKey('max') && selectedHeadCount.get('max') != null)
                ? ((Decimal)selectedHeadCount.get('max')).intValue() : null;
            Boolean hasGreaterThanOnlyHead = (Boolean)selectedHeadCount.get('hasGreaterThanOnly');
            
            if (hasGreaterThanOnlyHead == true) {
                headCountConditions.add('NumberOfEmployees > 10001');
            }
            
            if (minHead != null && maxHead != null) {
                headCountConditions.add('(NumberOfEmployees >= ' + minHead + ' AND NumberOfEmployees <= ' + maxHead + ')');
            }
        }
        
        if (!revenueConditions.isEmpty()) {
            query += ' AND (' + String.join(revenueConditions, ' OR ') + ')';
        }
        
        if (!headCountConditions.isEmpty()) {
            query += ' AND (' + String.join(headCountConditions, ' OR ') + ')';
        }
        
        if (!String.isBlank(selectedAccountOwner)) {
            query += ' AND OwnerId = :selectedAccountOwner';
        }
        
        System.debug('Final Query: ' + query);
        return Database.query(query);
    }

    
    @AuraEnabled(cacheable=true)
    public static List<User> getAccountOwners() {
        return [SELECT Id, Name FROM User WHERE Id IN (SELECT OwnerId FROM Account)];
    }
    
    @AuraEnabled
    public static List<Contact> getContacts(List<Id> accountId) {
        return [SELECT Account.Name, Id, Name, Title , Email, Phone FROM Contact WHERE AccountId = :accountId];
    }
    
    @AuraEnabled
    public static List<Product2> getProducts() {
        return [SELECT Id, Name FROM Product2];
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> searchLinkedinForCompany(List<String> accountIds, List<String> locations) {
        System.debug('Locations: ' + locations);
        System.debug('LWC to Apex Account Ids Are: ' + accountIds);
        
        String BASE_URL = System.Label.companySearchEndPoint;
        Integer numberOfSearchResults = 100;
        String cursor = null;
        String linkedInAccountId = getLinkedInAccountId();
        
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return null;
        }
        
        List<Map<String, Object>> allResults = new List<Map<String, Object>>();
        Map<String, Account> accountIdMap = new Map<String, Account>();
        
        for (Account curAccount : [
            SELECT Id, Name, AnnualRevenue, Industry,LinkedinUniqueURL__c, LinkedIn_Profile__c, Website, NumberOfEmployees, Owner.Name
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountIdMap.put(curAccount.Id, curAccount);
        }
        
        try {
            for (Account acc : accountIdMap.values()) {
                List<String> industryId = getIndustryCode(acc.Industry);
                String searchKeywords = acc.Name != null ? acc.Name.trim().toLowerCase() : '';
                
                Map<String, Object> annualRevenueFilter = new Map<String, Object>{
                    'min' => 0,
                        'max' => 0,
                        'currency' => 'USD'
                        };
                            Map<String, Object> industryFilter = new Map<String, Object>{ 'include' => industryId };
                                
                                do {
                                    String url = BASE_URL + '?limit=' + numberOfSearchResults + '&account_id=' + linkedInAccountId;
                                    if (cursor != null) {
                                        url += '&cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8');
                                    }
                                    
                                    Map<String, Object> searchCompaniesPayLoad = new Map<String, Object>{
                                        'api' => 'sales_navigator',
                                            'category' => 'companies',
                                            'keywords' => searchKeywords,
                                            'annual_revenue' => annualRevenueFilter
                                            };
                                                
                                  	if (locations != null && !locations.isEmpty()) {
                                        Map<String, Object> locationMap = new Map<String, Object>();
                                        locationMap.put('include', locations);
                                        searchCompaniesPayLoad.put('location', locationMap);
                                    }
                                    
                                    String requestBody = JSON.serialize(searchCompaniesPayLoad);
                                    System.debug('Request Body: ' + requestBody);
                                    
                                    Http http = new Http();
                                    HttpRequest request = new HttpRequest();
                                    request.setEndpoint(url);
                                    request.setMethod('POST');
                                    request.setHeader('accept', 'application/json');
                                    request.setHeader('Content-Type', 'application/json');
                                    request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
                                    request.setBody(requestBody);
                                    
                                    HttpResponse response = http.send(request);
                                    
                                    if (response.getStatusCode() == 200) {
                                        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                                        
                                        if (responseBody.containsKey('items')) {
                                            List<Object> itemsList = (List<Object>) responseBody.get('items');
                                            
                                            for (Object obj : itemsList) {
                                                Map<String, Object> company = (Map<String, Object>) obj;
                                                
                                                String companyName = (String) company.get('name');
                                                if (String.isBlank(companyName)) continue;
                                                
                                                String sanitizedCompanyName = companyName.trim().toLowerCase();
                                                String sanitizedAccountName = acc.Name != null ? acc.Name.trim().toLowerCase() : '';
                                                
                                                if (sanitizedCompanyName.contains(sanitizedAccountName)) {
                                                    String companyProfileUrl = company.containsKey('profile_url') && company.get('profile_url') != null
                                                        ? ((String) company.get('profile_url')).trim().toLowerCase()
                                                        : '';
                                                    String accountLinkedInProfile = acc.LinkedinUniqueURL__c != null
                                                        ? acc.LinkedinUniqueURL__c.trim().toLowerCase()
                                                        : '';
                                                    
                                                    Boolean addCompany = false;
                                                    
                                                    if (!String.isBlank(accountLinkedInProfile)) {
                                                        if (accountLinkedInProfile == companyProfileUrl) {
                                                            addCompany = true;
                                                        }
                                                    } else if (!String.isBlank(companyProfileUrl)) {
                                                        addCompany = true;
                                                    }
                                                    
                                                    
                                                    if (addCompany) {
                                                        allResults.add(new Map<String, Object>{
                                                            'id' => company.get('id'),
                                                                'name' => company.get('name'),
                                                                'profile_url' => companyProfileUrl,
                                                                'industry' => company.get('industry'),
                                                                'headcount' => company.get('headcount'),
                                                                'salesforceAccountId' => acc.Id,
                                                                'ownerName' => acc.Owner.Name,
                                                                'salesforceAccountName' => acc.Name
                                                                });
                                                    }
                                                }
                                            }
                                        }
                                        cursor = responseBody.containsKey('cursor') ? (String) responseBody.get('cursor') : null;
                                        if (cursor == null) break;
                                    } else {
                                        System.debug('API Callout Error: ' + response.getStatusCode() + ' | Response: ' + response.getBody());
                                        cursor = null;
                                    }
                                } while (cursor != null);
            }
            
            System.debug('Search Results: ' + allResults);
            return allResults;
            
        } catch (Exception ex) {
            System.debug('Error making API request: ' + ex.getMessage() + ' | StackTrace: ' + ex.getStackTraceString());
            return new List<Map<String, Object>>();
        }
    }
    
    public static List<String> getIndustryCode(String industryName) {
        String BASE_URL = System.Label.searchParameterEndPoint;
        Integer numberOfSearchResults = 100;
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return null;
        }
        if (String.isNotEmpty(industryName)) {
            String url = BASE_URL + '?limit=' + numberOfSearchResults + '&keywords=' + EncodingUtil.urlEncode(industryName, 'UTF-8') + '&type=INDUSTRY' + '&account_id=' + linkedInAccountId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            Http http = new Http();
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (responseBody.containsKey('items')) {
                    List<Object> items = (List<Object>) responseBody.get('items');
                    List<String> industryIds = new List<String>();
                    for (Object obj : items) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        String industryId = (String) item.get('id');
                        industryIds.add(industryId);
                    }
                    return industryIds;
                }
            }
            
        }
        return new List<String>();
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> processSelectedAccounts(List<UnipileAccountWrapper> selectedAccounts) {
        List<Map<String, Object>> companyDetailsList = new List<Map<String, Object>>();
        Map<String, UnipileAccountWrapper> companyIdUnipileAccountWrapperMap = new Map<String, UnipileAccountWrapper>();
        if (selectedAccounts == null || selectedAccounts.isEmpty()) {
            System.debug('No selected accounts provided.');
            return companyDetailsList;
        }
        
        Set<String> companyIdSet = new Set<String>();
        String BASE_URL = System.Label.retrieveCompanyDetailsEndPoint;
        List<HttpRequest> requests = new List<HttpRequest>();
        
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return null;
        }
        
        for (UnipileAccountWrapper account : selectedAccounts) {
            if (account.id != null) {
                companyIdSet.add(account.id);
                companyIdUnipileAccountWrapperMap.Put(account.id, account);
            }
        }
        
        for (String companyId : companyIdSet) {
            String url = BASE_URL + '/' + EncodingUtil.urlEncode(companyId, 'UTF-8') + '?account_id=' + linkedInAccountId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('Accept', 'application/json');
            requests.add(request);
        }
        
        List<HttpRequest> limitedRequests = new List<HttpRequest>();
        for (Integer i = 0; i < Math.min(requests.size(), 100); i++) {
            limitedRequests.add(requests[i]);
        }
        
        Http http = new Http();
        List<HttpResponse> responses = new List<HttpResponse>();
        
        for (HttpRequest req : limitedRequests) {
            try {
                HttpResponse response = http.send(req);
                responses.add(response);
            } catch (Exception e) {
                System.debug('HTTP request failed: ' + e.getMessage());
            }
        }
        
        List<String> companyIdList = new List<String>(companyIdSet);
        
        for (Integer i = 0; i < responses.size(); i++) {
            HttpResponse response = responses[i];
            String companyId = companyIdList[i];
            if(companyIdUnipileAccountWrapperMap.ContainsKey(companyId)){
                if (response.getStatusCode() == 200) {
                    String responseBody = response.getBody();
                    Map<String, Object> companyData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    Map<String, Object> companyDetails = new Map<String, Object>();
                    
                    companyDetails.put('companyId', companyData.get('id'));
                    companyDetails.put('companyName', companyData.get('name'));
                    companyDetails.put('companyDescription', companyData.get('description'));
                    companyDetails.put('companyProfileUrl', companyData.get('profile_url'));
                    companyDetails.put('companyWebsite', companyData.get('website'));
                    companyDetails.put('companyEmployeeCount', companyData.get('employee_count'));
                    companyDetails.put('salesforceAccountName',companyIdUnipileAccountWrapperMap.get(companyId).salesforceAccountName);
                    companyDetails.put('salesforceAccountId',companyIdUnipileAccountWrapperMap.get(companyId).salesforceAccountId);
                    companyDetailsList.add(companyDetails);
                } else {
                    System.debug('Error: Response for ' + companyId + ' - ' + response.getStatusCode() + ' ' + response.getBody());
                }
            }
        }
        return companyDetailsList;
    }
    
    @AuraEnabled
    public static List<Account> updateSalesforceAccount(List<SalesforceAccountUpdateWrapper> toUpdateAccountList) {
        List<Account> accountToUpdate = new List<Account>();
        List<String> updatedAccountId = new List<String>();
        List<Account> updatedAccount = new List<Account>();
        Map<String, SalesforceAccountUpdateWrapper> salesforceIdLinkedInDetailsMap = new Map<String, SalesforceAccountUpdateWrapper>();
        
        if (toUpdateAccountList == null || toUpdateAccountList.isEmpty()) {
            system.debug('to update account list is :'+toUpdateAccountList);
            return new List<Account>();
        }else{
            for (SalesforceAccountUpdateWrapper wrapper : toUpdateAccountList) {
                if (wrapper.salesforceAccountId != null) {
                    salesforceIdLinkedInDetailsMap.put(wrapper.salesforceAccountId, wrapper);
                }
            }
            
            if (!salesforceIdLinkedInDetailsMap.isEmpty()) {
                system.debug('salesforce id linkedindetails map is :'+salesforceIdLinkedInDetailsMap);
                for (Account curAccount : [SELECT Id, Website, Name, NumberOfEmployees, LinkedIn_Id__c, LinkedIn_Profile__c FROM Account WHERE Id IN :salesforceIdLinkedInDetailsMap.keySet()]) {
                    SalesforceAccountUpdateWrapper wrapper = salesforceIdLinkedInDetailsMap.get(curAccount.Id);
                    if (curAccount.Website == null || curAccount.Website.equalsIgnoreCase(wrapper.companyWebsite) || curAccount.NumberOfEmployees == null 
                        || curAccount.LinkedIn_Profile__c == null || curAccount.LinkedIn_Id__c == null) {

                            Account accObj = new Account();
                            accObj.LinkedIn_Id__c = wrapper.companyId;
                            accObj.Name = wrapper.companyName;
                            accObj.Website = wrapper.companyWebsite;
                            accObj.Id = curAccount.Id;
                            accObj.NumberOfEmployees = wrapper.companyEmployeeCount;
                            accObj.LinkedIn_Profile__c = wrapper.companyProfileUrl;
                            accountToUpdate.add(accObj);
                            updatedAccountId.add(accObj.Id);
                        }
                }
                try {
                    if (!accountToUpdate.isEmpty()) {
                        update accountToUpdate;
                        updatedAccount = [SELECT Id, Website, Name, NumberOfEmployees, LinkedIn_Profile__c FROM Account WHERE Id IN :updatedAccountId];
                        
                    }
                } catch (DmlException e) {
                    return new List<Account>();
                }
            }
            return updatedAccount;
        }        
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> searchContactsOnLinkedIn(
        List<UnipileAccountWrapper> selectedAccounts, 
        List<String> includedSeniorityLevel,
        List<String> excludedSeniorityLevel,
        List<String> includedDepartment,
        List<String> excludedDepartment,
        List<String> selectedRegion
    )         
    {
        List<Map<String, Object>> contactList = new List<Map<String, Object>>();
        
        List<Map<String, Object>> contactDetailsList = new List<Map<String, Object>>();
        Integer numberOfSearchResults = 100;
        Integer maxRequests = 50; 
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            return contactDetailsList;
        }
        
        String baseUrl = System.Label.searchContactsEndPoint + '?limit=' + numberOfSearchResults + '&account_id=' + linkedInAccountId;
        
        if (selectedAccounts == null || selectedAccounts.isEmpty()) {
            return contactDetailsList;
        }
        
        Map<Id, AccountContactWrapper> accountContactMap = getAccountContacts(selectedAccounts);
        
        Map<String, Object> seniorityFilter = createFilterMap(includedSeniorityLevel, excludedSeniorityLevel);
        Map<String, Object> departmentFilter = createDepartmentFilter(includedDepartment, excludedDepartment);
        Map<String, Object> locationFilter = createLocationFilter(selectedRegion);
        
        List<HttpRequest> requests = prepareHttpRequests(accountContactMap, baseUrl, seniorityFilter, departmentFilter, locationFilter);
        
        contactDetailsList = executeApiRequests(requests, maxRequests);
        
        for (Map<String, Object> contact : contactDetailsList) {
            if (contact != null) {
                Map<String, Object> contactMap = new Map<String, Object>();
                contactMap.put('LinkedIn_URN', contact.get('member_urn'));
                contactMap.put('Contact_LinkedIn_Id__c', contact.get('id'));
                contactMap.put('name', contact.get('name'));
                contactMap.put('firstName', contact.get('first_name'));
                contactMap.put('lastName', contact.get('last_name'));
                contactMap.put('location', contact.get('location'));
                contactMap.put('profile_url', contact.get('public_profile_url'));
                
                List<Object> positions = (List<Object>) contact.get('current_positions');
                if (positions != null && !positions.isEmpty()) {
                    Map<String, Object> firstPosition = (Map<String, Object>) positions[0];
                    contactMap.put('currentPosition', firstPosition.get('role'));
                    contactMap.put('company', firstPosition.get('company'));
                } else {
                    contactMap.put('currentPosition', 'N/A');
                    contactMap.put('company', 'N/A');
                }
                contactList.add(contactMap);
            }
        }
        return contactList;
    }
    
    @TestVisible
    private static String getLinkedInAccountId() {
        Id recordtypeid = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'LinkedIn_Account__c' and DeveloperName  = 'Linkedin'].Id;
        List<LinkedIn_Account__c> linkedInAccounts = [
            SELECT Account_ID__c FROM LinkedIn_Account__c 
            WHERE User_Name__c = :System.UserInfo.getName() AND RecordTypeId =: recordtypeid LIMIT 1
        ];
        return linkedInAccounts.isEmpty() ? null : linkedInAccounts[0].Account_ID__c;
    }
    
    @TestVisible
    private static Map<Id, AccountContactWrapper> getAccountContacts(List<UnipileAccountWrapper> selectedAccounts) {
        Set<String> salesforceAccountIdSet = new Set<String>();
        for (UnipileAccountWrapper account : selectedAccounts) {
            if (String.isNotBlank(account.salesforceAccountId)) {
                salesforceAccountIdSet.add(account.salesforceAccountId);
            }
        }
        
        Map<Id, AccountContactWrapper> accountContactMap = new Map<Id, AccountContactWrapper>();
        
        if (!salesforceAccountIdSet.isEmpty()) {
            List<Account> accountsWithContacts = [
                SELECT Id, Name, LinkedIn_Id__c, 
                (SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, Title FROM Contacts) 
                FROM Account 
                WHERE Id IN :salesforceAccountIdSet
            ];
            
            for (Account acc : accountsWithContacts) {
                accountContactMap.put(acc.Id, new AccountContactWrapper(acc.Name, acc.LinkedIn_Id__c, acc.Contacts));
            }
        }
        
        return accountContactMap;
    }
    
    @TestVisible
    private static Map<String, Object> createFilterMap(List<String> includeList, List<String> excludeList) {
        Map<String, Object> filter = new Map<String, Object>();
        if (includeList != null && !includeList.isEmpty()) {
            filter.put('include', includeList);
        }
        if (excludeList != null && !excludeList.isEmpty()) {
            filter.put('exclude', excludeList);
        }
        return filter;
    }
    
    @TestVisible
    private static Map<String, Object> createDepartmentFilter(List<String> includedDepartment, List<String> excludedDepartment) {
        Map<String, String> functionIncludeDepMap = getFunctionCode(includedDepartment);
        Map<String, String> functionExcludeDepMap = getFunctionCode(excludedDepartment);
        Map<String, Object> departmentFilter = new Map<String, Object>();
        
        List<String> includeIds = new List<String>();
        List<String> excludeIds = new List<String>();
        
        for (String dep : includedDepartment) {
            if (functionIncludeDepMap.containsKey(dep)) {
                includeIds.add(functionIncludeDepMap.get(dep));
            }
        }
        for (String dep : excludedDepartment) {
            if (functionExcludeDepMap.containsKey(dep)) {
                excludeIds.add(functionExcludeDepMap.get(dep));
            }
        }
        
        if (!includeIds.isEmpty()) departmentFilter.put('include', includeIds);
        if (!excludeIds.isEmpty()) departmentFilter.put('exclude', excludeIds);
        
        return departmentFilter;
    }
    
    @TestVisible
    private static Map<String, Object> createLocationFilter(List<String> selectedRegions) {
        return selectedRegions.isEmpty() ? new Map<String, Object>() : new Map<String, Object>{ 'include' => selectedRegions };
            }
    
    @TestVisible
    private static List<HttpRequest> prepareHttpRequests(
        Map<Id, AccountContactWrapper> accountContactMap, 
        String baseUrl, 
        Map<String, Object> seniorityFilter, 
        Map<String, Object> departmentFilter, 
        Map<String, Object> locationFilter
    ) {
        List<HttpRequest> requests = new List<HttpRequest>();
        
        for (AccountContactWrapper wrapper : accountContactMap.values()) {
            if (String.isNotBlank(wrapper.linkedInId)) {
                Map<String, Object> payload = new Map<String, Object>{
                    'api' => 'sales_navigator',
                        'category' => 'people',
                        'seniority' => seniorityFilter,
                        'location' => locationFilter,
                        'function' => departmentFilter,
                        'company' => new Map<String, List<String>>{
                            'include' => new List<String>{wrapper.linkedInId}
                        }
                };
                    requests.add(createHttpRequest(baseUrl, payload));
            }
        }
        return requests;
    }
    @TestVisible
    private static List<Map<String, Object>> executeApiRequests(List<HttpRequest> requests, Integer maxRequests) {
        List<Map<String, Object>> contactDetailsList = new List<Map<String, Object>>();
        Http http = new Http();
        Integer requestCount = 0;
        
        for (HttpRequest req : requests) {
            if (requestCount >= maxRequests || Limits.getCpuTime() > 9000) {
                break;
            }
            
            String cursor = null;
            
            do {
                try {
                    HttpResponse response = http.send(req);
                    requestCount++;
                    
                    if (response.getStatusCode() == 200) {
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        if (responseMap.containsKey('items')) {
                            List<Object> items = (List<Object>) responseMap.get('items');
                            for (Object obj : items) {
                                if (obj instanceof Map<String, Object>) {
                                    Map<String, Object> contact = (Map<String, Object>) obj;
                                    contactDetailsList.add(contact);
                                }
                            }
                        }
                        cursor = (String) responseMap.get('cursor');
                        if (cursor != null) {
                            req = createNextPageRequest(cursor);
                        } else {
                            req = null;
                        }
                        
                    } else {
                        req = null;
                    }
                    
                } catch (CalloutException e) {
                    System.debug('HTTP Callout Exception: ' + e.getMessage());
                    req = null;
                }
            } while (req != null && requestCount < maxRequests);
        }
        system.debug('contact details list in executeapi size is :'+contactDetailsList.size());
        return contactDetailsList;
    }
    @TestVisible
    private static HttpRequest createNextPageRequest(String cursor) {
        system.debug('cursor is :' +cursor);
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return null;
        }
        system.debug('LinkedAccountId is :'+linkedInAccountId);
        String BASE_URL = System.Label.searchContactsEndPoint;
        HttpRequest nextRequest = new HttpRequest();
        string updatedUrl = BASE_URL+'?cursor='+cursor+'&account_id='+linkedInAccountId;
        system.debug('updatedUrl is :' +updatedUrl);
        nextRequest.setEndpoint(updatedUrl);
        nextRequest.setMethod('POST');
        nextRequest.setHeader('Content-Type', 'application/json');
        nextRequest.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        nextRequest.setHeader('Accept', 'application/json');
        return nextRequest;
    }    
    
    public static Map<String, String> getFunctionCode(List<String> funcionName) {
        String BASE_URL = System.Label.searchParameterEndPoint;
        String linkedInAccountId = getLinkedInAccountId();       
        
        System.debug('Using LinkedIn Account ID: ' + linkedInAccountId);
        System.debug('functions are: ' + funcionName);
        
        Map<String, String> DepartmentMap = new Map<String, String>();
        
        if (!funcionName.isEmpty()) {
            String url = BASE_URL + '?type=DEPARTMENT&account_id=' + linkedInAccountId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (responseBody.containsKey('items')) {
                    List<Object> items = (List<Object>) responseBody.get('items');
                    
                    for (Object obj : items) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        String title = (String) item.get('title');
                        String departmentId = (String) item.get('id');
                        
                        if (title != null && departmentId != null) {
                            DepartmentMap.put(title, departmentId);
                        }
                    }
                }
            }
        }
        
        return DepartmentMap;
    }
    @TestVisible
    private static HttpRequest createHttpRequest(String url, Map<String, Object> payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        return req;
    }
    public class AccountContactWrapper {
        public String accountName;
        public String linkedInId;
        public List<Contact> contacts;
        
        public AccountContactWrapper(String accountName, String linkedInId, List<Contact> contacts) {
            this.accountName = accountName;
            this.linkedInId = linkedInId;
            this.contacts = contacts;
        }
    }
    public class SalesforceAccountUpdateWrapper {
        @AuraEnabled public String salesforceAccountId { get; set; }
        @AuraEnabled public String salesforceAccountName { get; set; }
        @AuraEnabled public String companyId { get; set; }
        @AuraEnabled public String companyName { get; set; }       
        @AuraEnabled public String companyWebsite { get; set; }   
        @AuraEnabled public Integer companyEmployeeCount { get; set; } 
        @AuraEnabled public String companyProfileUrl { get; set; }     
    }  
    public class UnipileAccountWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String salesforceAccountId { get; set; }        
        @AuraEnabled public String salesforceAccountName { get; set; }
        @AuraEnabled public String name { get; set; }       
        @AuraEnabled public String industry { get; set; }   
        
    }
    @AuraEnabled
    public static Map<String, Object> createOrUpdateContacts(List<Contact> contactList) {
        Map<String, Object> responseMap = new Map<String, Object>();
        System.debug('Input from LWC for contact creation: ' + contactList);
        
        List<Contact> newContacts = new List<Contact>();
        List<Contact> updatedContacts = new List<Contact>();
        List<Contact> skippedContacts = new List<Contact>();
        
        Set<String> companyNames = new Set<String>();
        Set<String> contactURNs = new Set<String>();
        Set<String> contactFullNames = new Set<String>();
        
        for (Contact contact : contactList) {
            if (String.isNotBlank(contact.Current_Company_Name__c)) {
                companyNames.add(contact.Current_Company_Name__c.trim().toLowerCase());
            }
            if (String.isNotBlank(contact.LinkedInURN__c)) {
                contactURNs.add(contact.LinkedInURN__c.trim());
            }
            if (String.isNotBlank(contact.FirstName) && String.isNotBlank(contact.LastName)) {
                contactFullNames.add(contact.FirstName.trim().toLowerCase() + ' ' + contact.LastName.trim().toLowerCase());
            }
        }
        Map<String, Account> existingAccounts = new Map<String, Account>();
        if (!companyNames.isEmpty()) {
            for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN : companyNames]) {
                existingAccounts.put(acc.Name.trim().toLowerCase(), acc);
            }
        }
        
        Map<String, Contact> existingContactsByURN = new Map<String, Contact>();
        if (!contactURNs.isEmpty()) {
            for (Contact con : [SELECT Id, FirstName, LastName, LinkedIn_Profile__c, LinkedIn_Connection_Status__c, 
                                Contact_Outreach_Owner__c, Contact_LinkedIn_Id__c, LinkedInURN__c, 
                                Current_Company_Name__c, Title, Current_Location__c, AccountId 
                                FROM Contact WHERE LinkedInURN__c IN :contactURNs]) {
                                    existingContactsByURN.put(con.LinkedInURN__c.trim(), con);
                                }
        }
        Map<String, Contact> existingContactsByName = new Map<String, Contact>();
        if (!contactFullNames.isEmpty()) {
            for (Contact con : [SELECT Id, FirstName, LastName,Contact_LinkedIn_Id__c,LinkedIn_Connection_Status__c, Contact_Outreach_Owner__c,LinkedIn_Profile__c, LinkedInURN__c, Current_Company_Name__c, Title,Current_Location__c, AccountId
                                FROM Contact]) {
                                    String fullName = con.FirstName.trim().toLowerCase() + ' ' + con.LastName.trim().toLowerCase();
                                    if (!existingContactsByName.containsKey(fullName)) {
                                        existingContactsByName.put(fullName, con);
                                    }
                                }
        }
        
        
        List<Id> allExistingOrUpdatedContactsIds = new List<Id>();
        
        for (Contact contact : contactList) {
            if (String.isBlank(contact.LastName)) {
                skippedContacts.add(contact);
                continue;
            }
            
            String companyKey = contact.Current_Company_Name__c != null ? contact.Current_Company_Name__c.trim().toLowerCase() : null;
            System.debug('companyKey: '+companyKey);
            if (companyKey == null || !existingAccounts.containsKey(companyKey)) {
                System.debug('Skipping contact due to missing or non-existing company: ' + contact);
                skippedContacts.add(contact);
                continue;
            }
            Account linkedAccount = existingAccounts.get(companyKey);
            Contact existingContact = existingContactsByURN.get(contact.LinkedInURN__c);
            if (existingContact == null) {
                existingContact = existingContactsByName.get(contact.FirstName.trim().toLowerCase() + ' ' + contact.LastName.trim().toLowerCase());
            }
            
            if (existingContact != null) {
                Boolean needsUpdate = false;
                
                if (existingContact.Contact_LinkedIn_Id__c != contact.Contact_LinkedIn_Id__c) {
                    existingContact.Contact_LinkedIn_Id__c = contact.Contact_LinkedIn_Id__c;
                    needsUpdate = true;
                }
                if (existingContact.LinkedIn_Profile__c != contact.LinkedIn_Profile__c) {
                    existingContact.LinkedIn_Profile__c = contact.LinkedIn_Profile__c;
                    needsUpdate = true;
                }
                if (existingContact.LinkedInURN__c != contact.LinkedInURN__c) {
                    existingContact.LinkedInURN__c = contact.LinkedInURN__c;
                    needsUpdate = true;
                }
                if (existingContact.Current_Company_Name__c != contact.Current_Company_Name__c) {
                    existingContact.Current_Company_Name__c = contact.Current_Company_Name__c;
                    needsUpdate = true;
                }
                if (existingContact.Current_Location__c != contact.Current_Location__c) {
                    existingContact.Current_Location__c = contact.Current_Location__c;
                    needsUpdate = true;
                }
                if (existingContact.Title != contact.Title) {
                    existingContact.Title = contact.Title;
                    needsUpdate = true;
                }
                if (linkedAccount != null && 
                    (existingContact.AccountId == null || existingContact.AccountId != linkedAccount.Id)) {
                        existingContact.AccountId = linkedAccount.Id;
                        needsUpdate = true;
                    }
                if(existingContact.Contact_Outreach_Owner__c != contact.Contact_Outreach_Owner__c ){
                    existingContact.Contact_Outreach_Owner__c = contact.Contact_Outreach_Owner__c;
                    needsUpdate = true;
                }
                
                
                if (needsUpdate) {
                    updatedContacts.add(existingContact);
                }
                allExistingOrUpdatedContactsIds.add(existingContact.Id);
                
            }
            else {
                newContacts.add(new Contact(
                    FirstName = contact.FirstName,
                    LastName = contact.LastName,
                    Contact_Outreach_Owner__c = contact.Contact_Outreach_Owner__c,
                    Title = contact.Title,
                    Contact_LinkedIn_Id__c = contact.Contact_LinkedIn_Id__c,
                    Current_Location__c = contact.Current_Location__c,
                    LinkedIn_Profile__c = contact.LinkedIn_Profile__c,
                    LinkedInURN__c = contact.LinkedInURN__c,
                    Current_Company_Name__c = contact.Current_Company_Name__c,
                    AccountId = linkedAccount.Id,
                    LinkedIn_Connection_Status__c = 'Not Connected',
                    LinkedIn_Message_1__c='Not Sent',
                    LinkedIn_Message_2__c='Not Sent',
                    Email_1__c = 'Not Sent',
                    Email_2__c = 'Not Sent'
                ));
            }
        }
        List<Id> updatedContactIds = new List<Id>();
        if (!updatedContacts.isEmpty()) {
            try {
                Database.SaveResult[] updateResults = Database.update(updatedContacts, false);
                for (Integer i = 0; i < updateResults.size(); i++) {
                    if (!updateResults[i].isSuccess()) {
                        for (Database.Error error : updateResults[i].getErrors()) {
                            updatedContactIds.add(updatedContacts[i].id);
                            System.debug('Contact update failed: ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Unexpected error during contact update: ' + e.getMessage());
            }
        }
        List<Id> insertedContactIds = new List<Id>();
        List<Contact> insertedContactsToLWC = new List<Contact>();
        
        if (!newContacts.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(newContacts, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        insertedContactIds.add(newContacts[i].Id);
                        insertedContactsToLWC.add(newContacts[i]);
                    } else {
                        for (Database.Error error : results[i].getErrors()) {
                            System.debug('Contact insert failed: ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Unexpected error during contact insertion: ' + e.getMessage());
            }
        }
        List<Contact> insertedNewContacts = new List<Contact>();
        if(insertedContactIds.size()>0){
            insertedNewContacts = [
                SELECT Id, FirstName, LastName, Email, AccountId, Account.Name,Contact_Outreach_Owner__r.Name, Title, Contact_LinkedIn_Id__c , Current_Location__c, LinkedIn_Profile__c , LinkedInURN__c
                FROM Contact where Id IN : insertedContactIds];
        }
        List<Contact> updatedNewContacts = new List<Contact>();
        
        updatedNewContacts = [
            SELECT Id, FirstName, LastName, Email, AccountId, Account.Name, Contact_Outreach_Owner__r.Name ,Title, Contact_LinkedIn_Id__c , Current_Location__c, LinkedIn_Profile__c , LinkedInURN__c
            FROM Contact where Id IN : allExistingOrUpdatedContactsIds];
        
        System.debug('updatedNewContacts'+ updatedNewContacts);
        // Create a Map to store Outreach Owner Names
        Map<Id, String> ownerNames = new Map<Id, String>();
        
        // Fetch all distinct owners
        Set<Id> ownerIds = new Set<Id>();
        for (Contact skippedContact : skippedContacts) {
            if (skippedContact.Contact_Outreach_Owner__c != null) {
                ownerIds.add(skippedContact.Contact_Outreach_Owner__c);
            }
        }
        
        // Query User table to get owner names
        if (!ownerIds.isEmpty()) {
            for (User owner : [SELECT Id, Name FROM User WHERE Id IN :ownerIds]) {
                ownerNames.put(owner.Id, owner.Name);
            }
        }
        
        // Convert skipped contacts into a List of Maps with owner names
        List<Map<String, Object>> skippedContactList = new List<Map<String, Object>>();
        
        for (Contact skippedContact : skippedContacts) {
            Map<String, Object> skippedContactMap = new Map<String, Object>{
                'LinkedInURN__c' => skippedContact.LinkedInURN__c,
                    'FirstName' => skippedContact.FirstName,
                    'LastName' => skippedContact.LastName,
                    'Title' => skippedContact.Title,
                    'Contact_LinkedIn_Id__c' => skippedContact.Contact_LinkedIn_Id__c,
                    'Current_Location__c' => skippedContact.Current_Location__c,
                    'LinkedIn_Profile__c' => skippedContact.LinkedIn_Profile__c,
                    'Current_Company_Name__c' => skippedContact.Current_Company_Name__c,
                    'AccountName' => skippedContact.Account != null ? skippedContact.Account.Name : 'No Account',
                        'Contact_Outreach_Owner_Name' => ownerNames.containsKey(skippedContact.Contact_Outreach_Owner__c) 
                        ? ownerNames.get(skippedContact.Contact_Outreach_Owner__c) 
                        : 'No Owner',
                            'Contact_Outreach_Owner_Id'=>skippedContact.Contact_Outreach_Owner__c
                            };
                                system.debug('contact outreach owner is : '+skippedContact.Contact_Outreach_Owner__c);
            skippedContactList.add(skippedContactMap);
        }
        
        responseMap.put('newContacts', insertedNewContacts);
        responseMap.put('updatedContacts', updatedNewContacts);
        responseMap.put('skippedContacts', skippedContactList);
        
        return responseMap;
    }

    public class ContactWithOwnerWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String outreachOwnerId;
    }

    
    @AuraEnabled
    public static Map<String, Object> gridContactProcessing(String gridName, String selectedContacts, String outreachOwnerId) {

        List<ContactWithOwnerWrapper> contactList = (List<ContactWithOwnerWrapper>) JSON.deserialize(selectedContacts, List<ContactWithOwnerWrapper>.class);

        Map<String, Object> responseMap = new Map<String, Object>();
        List<Grid_Contact__c> toInsertGridContactList = new List<Grid_Contact__c>();
        List<Grid_Account__c> toInsertGridAccountList = new List<Grid_Account__c>();
        Set<Id> processedAccounts = new Set<Id>();
        Set<Id> processedContacts = new Set<Id>();
        List<Lead> leadToCreate=new List<Lead>();
        
        Map<Id, String> contactIdToOwnerMap = new Map<Id, String>();
        Set<Id> gridContactIds = new Set<Id>();
        
        for (ContactWithOwnerWrapper wrapper : contactList) {
            gridContactIds.add(wrapper.Id);
            contactIdToOwnerMap.put(wrapper.Id, wrapper.outreachOwnerId);
        }
        
        Grid__c createGrid = null;
        Id currentGridId;
        
        Map<String, Contact> selectedContactsForGridMap = new Map<String, Contact>();
        
        for (Contact curCon : [SELECT Id, Name, Email, Phone, Title, FirstName, LastName, LinkedIn_Profile__c, 
                               LinkedInURN__c, Current_Company_Name__c, Contact_LinkedIn_Id__c, 
                               Current_Location__c, AccountId, Account.Name
                               FROM Contact WHERE ID IN :gridContactIds]) {
                                   selectedContactsForGridMap.put(curCon.Id, curCon);
                                   processedAccounts.add(curCon.AccountId);
                                   processedContacts.add(curCon.Id);
                               }
        
        if (!selectedContactsForGridMap.isEmpty()) {
            createGrid = new Grid__c();
            createGrid.Name = gridName;
            createGrid.Outreach_Owner__c = outreachOwnerId;
            
            insert createGrid;
            
            currentGridId = createGrid.Id;
        }
        
        for (Contact curCon : selectedContactsForGridMap.values()) {
            if (processedContacts.contains(curCon.Id)) {
                Grid_Contact__c curGridContact = new Grid_Contact__c();
                curGridContact.Grid__c = currentGridId;
                curGridContact.Name__c=curCon.Name;
                curGridContact.FirstName__c=curCon.FirstName;
                curGridContact.LastName__c=curCon.LastName;
                curGridContact.Email__c=curCon.Email;
                curGridContact.Phone__c=curCon.Phone;
                curGridContact.Title__c=curCon.Title;
                curGridContact.Current_Company_Name__c=curCon.Current_Company_Name__c;
                curGridContact.AccountId__c=curCon.AccountId;
                curGridContact.LinkedIn_Profile__c=curCon.LinkedIn_Profile__c;
                curGridContact.LinkedInURN__c=curCon.LinkedInURN__c;
                curGridContact.Current_Location__c=curCon.Current_Location__c;
                curGridContact.Contact_LinkedIn_Id__c=curCon.Contact_LinkedIn_Id__c;
                
                String individualOutreachOwnerId = contactIdToOwnerMap.get(curCon.Id);
                curGridContact.Contact_Outreach_Owner__c = individualOutreachOwnerId;
                
                curGridContact.Contact__c = curCon.Id;
                curGridContact.Call_Attempt_1__c = null;
                curGridContact.Call_Attempt_2__c = null;
                curGridContact.Call_Attempt_3__c = null;
                curGridContact.Call_Attempt_4__c = null;
                curGridContact.Call_Attempt_5__c = null;
                curGridContact.Email_1__c = 'Not Sent';
                curGridContact.Email_2__c = 'Not Sent';
                curGridContact.LinkedIn_Connection_Status__c = 'Not Connected';
                curGridContact.LinkedIn_Invitation_Id__c = null;
                curGridContact.LinkedIn_Invitation_Sent_Date__c = null;
                curGridContact.LinkedIn_Message_1__c = 'Not Sent';
                curGridContact.LinkedIn_Message_2__c = 'Not Sent';
                curGridContact.LinkedIn_Message_Id__c = null;
                curGridContact.LM1_TimeStamp__c = null;
                curGridContact.LM2_TimeStamp__c = null;
                curGridContact.Notes__c = null;                
                toInsertGridContactList.add(curGridContact);
                processedContacts.remove(curCon.Id);
                
                
                Lead newLead = new Lead();
                newLead.FirstName = curCon.FirstName;
                newLead.LastName = curCon.LastName;
                newLead.Email = curCon.Email;
                newLead.Phone = curCon.Phone;
                newLead.Title = curCon.Title;
                newLead.Company = curCon.Current_Company_Name__c != null ? curCon.Current_Company_Name__c : 'Unknown Company';
                newLead.City = curCon.Current_Location__c;
                newLead.LeadSource = 'LinkedIn Outreach'; 
                newLead.OwnerId = individualOutreachOwnerId;
                newLead.Status='Open - Not Contacted';
                newLead.Grid_Contact__c = curGridContact.Id; 
                
                leadToCreate.add(newLead);
            }
            
            if (processedAccounts.contains(curCon.AccountId)) {
                Grid_Account__c curGridAccount = new Grid_Account__c();
                curGridAccount.Grid__c = currentGridId;
                curGridAccount.Account__c = curCon.AccountId;
                toInsertGridAccountList.add(curGridAccount);
                processedAccounts.remove(curCon.AccountId);
            }
        }
        
        if (!toInsertGridAccountList.isEmpty()) {
            insert toInsertGridAccountList;
        }
        
        if (!toInsertGridContactList.isEmpty()) {
            insert toInsertGridContactList;
        }
        
        if(!leadToCreate.isEmpty()){
            insert leadToCreate;
        }
        
        List<Grid_Account__c> insertedAccounts = 
            [SELECT Id, Grid__c, Account__c, Account__r.Name FROM Grid_Account__c WHERE Grid__c = :currentGridId];
        
        List<Grid_Contact__c> insertedContacts = 
            [SELECT Id, Grid__c, Contact__c, Contact__r.Name, Contact__r.Title,Contact__r.Current_Company_Name__c,Contact__r.Account.Name, Contact__r.Current_Location__c,
             Contact__r.LinkedIn_Profile__c,Contact__r.Contact_LinkedIn_Id__c
             FROM Grid_Contact__c WHERE Grid__c = : currentGridId];
        
        Set<Id> contactIds = new Set<Id>();
        for (Grid_Contact__c gridContact : insertedContacts) {
            contactIds.add(gridContact.Contact__c);
        }
        List<Contact> contacts = [SELECT Id, Name, Title, Email, Phone, AccountId, Account.Name ,Current_Company_Name__c,Current_Location__c,LinkedIn_Profile__c,Contact_LinkedIn_Id__c 
                                  FROM Contact WHERE Id IN :contactIds];
        
        responseMap.put('newGridAccounts', insertedAccounts);
        responseMap.put('insertedGridContacts', insertedContacts);
        responseMap.put('newGrid', createGrid);
        
        return responseMap;
    }
    
    
     @AuraEnabled
    public static Map<String, Object> addContactsToExistingGrid(
        Id gridId,
        String selectedContacts,
        String outreachOwnerId
    ) {
        
        List<ContactWithOwnerWrapper> contactList = (List<ContactWithOwnerWrapper>) JSON.deserialize(selectedContacts, List<ContactWithOwnerWrapper>.class);
        
        Map<Id, String> contactToOwnerMap = new Map<Id, String>();
        Set<Id> selectedContactsIds = new Set<Id>();
        
        for (ContactWithOwnerWrapper c : contactList) {
            contactToOwnerMap.put(c.Id, c.outreachOwnerId);
            selectedContactsIds.add(c.Id);
        }
        
        Map<String, Object> responseMap = new Map<String, Object>();
        
        // 1) Load the Grid
        Grid__c existingGrid = [
            SELECT Id, Name
            FROM Grid__c
            WHERE Id = :gridId
            LIMIT 1
        ];
        
        // 2) Determine which of the provided contacts are already on the grid
        Set<Id> selectedIdsSet      = new Set<Id>(selectedContactsIds);
        Set<String> existingContactIds  = new Set<String>();
        for (Grid_Contact__c gc : [
            SELECT Contact__c
            FROM Grid_Contact__c
            WHERE Grid__c     = :gridId
              AND Contact__c IN :selectedIdsSet
        ]) {
            existingContactIds.add(gc.Contact__c);
        }
        
        // 3) Build list of truly new contacts to insert
        List<Id> newContactIds = new List<Id>();
        for (String cid : selectedContactsIds) {
            if (!existingContactIds.contains(cid)) {
                newContactIds.add(Id.valueOf(cid));
            }
        }
        
        // 4) If nothing new, return immediately
        if (newContactIds.isEmpty()) {
            responseMap.put('existingGrid',       existingGrid);
            responseMap.put('existingContacts',   existingContactIds);
            responseMap.put('insertedGridContacts', new List<Grid_Contact__c>());
            responseMap.put('newGridAccounts',      new List<Grid_Account__c>());
            return responseMap;
        }
        
        // 5) Query Contact records for the new contacts
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Name, Email, Phone, Title,
                   Current_Company_Name__c, Current_Location__c,
                   LinkedIn_Profile__c, LinkedInURN__c, Contact_LinkedIn_Id__c,
                   AccountId
            FROM Contact
            WHERE Id IN :newContactIds
        ];
        
        // 6) Collect all related Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : contacts) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
        
        // 7) Find which of those accounts are already on the grid
        Set<Id> existingAccountIds = new Set<Id>();
        for (Grid_Account__c ga : [
            SELECT Account__c
            FROM Grid_Account__c
            WHERE Grid__c     = :gridId
              AND Account__c IN :accountIds
        ]) {
            existingAccountIds.add(ga.Account__c);
        }
        
        // 8) Compute the truly new Account IDs
        Set<Id> newAccountIdsSet = new Set<Id>(accountIds);
        newAccountIdsSet.removeAll(existingAccountIds);
        
        // 9) Build & insert Grid_Account__c for only the new accounts
        List<Grid_Account__c> toInsertAccounts = new List<Grid_Account__c>();
        for (Id acctId : newAccountIdsSet) {
            toInsertAccounts.add(new Grid_Account__c(
                Grid__c    = gridId,
                Account__c = acctId
            ));
        }
        List<Id> newGridAccountIds = new List<Id>();
        if (!toInsertAccounts.isEmpty()) {
            insert toInsertAccounts;
            for (Grid_Account__c ga : toInsertAccounts) {
                newGridAccountIds.add(ga.Id);
            }
        }
        
        // 10) Build & insert Grid_Contact__c for the new contacts
        List<Grid_Contact__c> toInsertContacts = new List<Grid_Contact__c>();
        for (Contact c : contacts) {
            toInsertContacts.add(new Grid_Contact__c(
                Grid__c                       = gridId,
                Contact__c                    = c.Id,
                Name__c                       = c.Name,
                FirstName__c                  = c.FirstName,
                LastName__c                   = c.LastName,
                Email__c                      = c.Email,
                Phone__c                      = c.Phone,
                Title__c                      = c.Title,
                Current_Company_Name__c       = c.Current_Company_Name__c,
                AccountId__c                  = c.AccountId,
                LinkedIn_Profile__c           = c.LinkedIn_Profile__c,
                LinkedInURN__c                = c.LinkedInURN__c,
                Current_Location__c           = c.Current_Location__c,
                Contact_LinkedIn_Id__c        = c.Contact_LinkedIn_Id__c,
                Contact_Outreach_Owner__c     = contactToOwnerMap.get(c.Id),
                Email_1__c                    = 'Not Sent',
                Email_2__c                    = 'Not Sent',
                LinkedIn_Connection_Status__c = 'Not Connected',
                LinkedIn_Message_1__c         = 'Not Sent',
                LinkedIn_Message_2__c         = 'Not Sent'
            ));
        }
        insert toInsertContacts;
        
        // 11) Map each Contact → its newly inserted Grid_Contact__c Id
        Map<Id, Id> contactToGridContactId = new Map<Id, Id>();
        for (Grid_Contact__c gc : [
            SELECT Id, Contact__c
            FROM Grid_Contact__c
            WHERE Grid__c       = :gridId
              AND Contact__c IN :newContactIds
        ]) {
            contactToGridContactId.put(gc.Contact__c, gc.Id);
        }
        
        // 12) Build & insert Lead records pointing to those new Grid_Contact__c
        List<Lead> leadsToInsert = new List<Lead>();
        for (Contact c : contacts) {
            leadsToInsert.add(new Lead(
                FirstName       = c.FirstName,
                LastName        = c.LastName,
                Email           = c.Email,
                Phone           = c.Phone,
                Title           = c.Title,
                OwnerId			= contactToOwnerMap.get(c.Id),
                Company         = c.Current_Company_Name__c != null
                                  ? c.Current_Company_Name__c
                                  : 'Unknown Company',
                City            = c.Current_Location__c,
                LeadSource      = 'LinkedIn Outreach',
                Status          = 'Open - Not Contacted',
                Grid_Contact__c = contactToGridContactId.get(c.Id)
            ));
        }
        insert leadsToInsert;
        
        // 13) Query back only the newly created Grid_Account__c
        List<Grid_Account__c> newGridAccounts = new List<Grid_Account__c>();
        if (!newGridAccountIds.isEmpty()) {
            newGridAccounts = [
                SELECT Id, Account__c, Account__r.Name
                FROM Grid_Account__c
                WHERE Id IN :newGridAccountIds
            ];
        }
        
    
        // 14) Populate response
        responseMap.put('existingGrid',         existingGrid);
        responseMap.put('existingContacts',     existingContactIds);   
        responseMap.put('insertedGridContacts', toInsertContacts);      
        responseMap.put('newGridAccounts',      newGridAccounts);      
        return responseMap;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<Account> searchCompanies(String searchTerm) {
        try {
            
            String searchQuery = '%' + searchTerm + '%';
            List<Account> companies = [SELECT Id, Name FROM Account WHERE Name LIKE : searchQuery LIMIT 10];
            System.debug('searched comanies are :'+companies);
            return companies;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching companies: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static Contact saveNewContact(Contact contactData, String outreachOwner) {
        try {
            String firstName = contactData.FirstName;
            String lastName = contactData.LastName;
            String email = contactData.Email;
            String phone = contactData.Phone;
            String companyName = contactData.Current_Company_Name__c;
            String contactLinkedInId = contactData.Contact_LinkedIn_Id__c;
            String currentLocation = contactData.Current_Location__c;
            String linkedInProfile = contactData.LinkedIn_Profile__c;
            String linkedInURN = contactData.LinkedInURN__c;
            String Title = contactData.Title;
            
            if (String.isBlank(lastName) || String.isBlank(companyName)) {
                throw new AuraHandledException('Last Name and Account Name are required.');
            }
            Id accountId = null;
            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name =: companyName LIMIT 1];
            
            if (!accounts.isEmpty()) {
                accountId = accounts[0].Id;
                system.debug('accountid is :'+accountId);
            }
            Contact newContact = new Contact(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                Phone = phone,
                Contact_LinkedIn_Id__c = contactLinkedInId,
                Current_Location__c = currentLocation,
                LinkedIn_Profile__c = linkedInProfile,
                LinkedInURN__c = linkedInURN,
                AccountId = accountId,
                Title = Title,
                Current_Company_Name__c = companyName,
                Contact_Outreach_Owner__c = outreachOwner,
                LinkedIn_Connection_Status__c = 'Not Connected',
                LinkedIn_Message_1__c='Not Sent',
                LinkedIn_Message_2__c='Not Sent',
                Email_1__c = 'Not Sent',
                Email_2__c = 'Not Sent'
            );
            insert newContact;
            Contact savedContact = [
                SELECT Id, FirstName, LastName, Email, AccountId, Account.Name,Contact_Outreach_Owner__r.Name, Title, Contact_LinkedIn_Id__c , Current_Location__c, LinkedIn_Profile__c , LinkedInURN__c
                FROM Contact WHERE Id = :newContact.Id
            ];
            
            return savedContact;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving contact: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, List<Id>> sendBulkLinkedInRequests(List<String> contactIdsToInvite) {
        Map<String, List<Id>> resultMap = new Map<String, List<Id>>{
            	'invitationSent' => new List<Id>(), 
                'pendingContacts' => new List<Id>(),
                'failedInvitation' => new List<Id>(),
                'notallowedSentInvitation'=> new List<Id>()   
                };
                    
                    if (contactIdsToInvite.isEmpty()) {
                        System.debug('No contact IDs provided.');
                        return resultMap;
                    }
        
        
        
        System.debug('contactIdsToInvite'+contactIdsToInvite);
        
        Id currentUserId = UserInfo.getUserId();
        
        System.debug('contactIdsToInvite'+contactIdsToInvite);
        
        List<Grid_Contact__c> allContacts = new List<Grid_Contact__c>();
        
        List<Id> notallowedSentInvitation = new List<Id>();
        
        List<Grid_Contact__c> queriedContacts = [
            SELECT Id, Name__c, Title__c, AccountId__r.Name, Current_Location__c, LinkedIn_Profile__c, 
            Contact_LinkedIn_Id__c, LinkedIn_Connection_Status__c, Contact_Outreach_Owner__c
            FROM Grid_Contact__c
            WHERE Id IN :contactIdsToInvite AND LinkedIn_Connection_Status__c NOT IN ('Connected', 'Invitation Sent')
        ];
        
        
        for (Grid_Contact__c contact : queriedContacts) {
            if (contact.Contact_Outreach_Owner__c == currentUserId) {
                allContacts.add(contact);
            } else {
                notallowedSentInvitation.add(contact.Id);
            }
        }
        
        
        if (allContacts.isEmpty()) {
            System.debug('No eligible contacts for LinkedIn invitations.');
            return resultMap;
        }
        
        List<Grid_Contact__c> contactsToProcess = new List<Grid_Contact__c>();
        List<Id> pendingContacts = new List<Id>();
        Integer count = 0;
        
        for (Grid_Contact__c con : allContacts) {
            if (count < 100) {
                contactsToProcess.add(con);
            } else {
                pendingContacts.add(con.Id);
            }
            count++;
        }
       
        
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isEmpty(linkedInAccountId)) {
            System.debug('Error: LinkedIn Account ID is missing.');
            return resultMap;
        }
        
        List<Grid_Contact__c> toUpdateGridContact = new List<Grid_Contact__c>();
        for (Grid_Contact__c contact : contactsToProcess) {
            if (!String.isEmpty(contact.Contact_LinkedIn_Id__c)) {
                String invitationId = sendInvitationToLinkedIn(contact, linkedInAccountId);
                if (String.isNotBlank(invitationId)) {
                    contact.LinkedIn_Connection_Status__c = 'Invitation Sent';
                    contact.LinkedIn_Invitation_Id__c = invitationId;
                    contact.LinkedIn_Message_1__c = 'Not Sent';
                    contact.LinkedIn_Message_2__c = 'Not Sent';
                    contact.LinkedIn_Invitation_Sent_Date__c=System.today();
                    toUpdateGridContact.add(contact);
                }else{
                    resultMap.get('failedInvitation').add(contact.Id);
                }
            }else {
                System.debug('Skipping contact with missing LinkedIn ID: ' + contact.Id);
            }
        }
        if(!toUpdateGridContact.isEmpty()){
            update toUpdateGridContact;
        }
        for(Grid_Contact__c curCon : toUpdateGridContact){
            resultMap.get('invitationSent').add(curCon.Id);
        }
        resultMap.put('pendingContacts', pendingContacts);
        resultMap.put('notallowedSentInvitation', notallowedSentInvitation);
        
        return resultMap;
    }
    
    @TestVisible
    private static String sendInvitationToLinkedIn(Grid_Contact__c contact, String accountId) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(System.Label.sendLinkedinInviteURL);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(new Map<String, String>{
                'provider_id' => contact.Contact_LinkedIn_Id__c,
                    'account_id' => accountId
                    }));
            
            // Send the request and get the response
            HttpResponse response = http.send(request);
            
            // Check if the response status code is 201 (Created)
            if (response.getStatusCode() == 201) {
                System.debug('Success Response for ' + contact.Id + ': ' + response.getBody());
                
                // Parse the response body
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                // Check if the response contains 'invitation_id'
                if (responseBody != null && responseBody.containsKey('invitation_id')) {
                    String invitationId = (String) responseBody.get('invitation_id');
                    return invitationId;
                } else {
                    System.debug('Error: Missing or empty `invitation_id` in response for ' + contact.Id);
                }
            } else {
                System.debug('API Error for ' + contact.Id + ': ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception in sendInvitationToLinkedIn for ' + contact.Id + ': ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        
        // Return null if any issue occurs
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> searchLocation(String keyword) {
        Map<String, String> locationMap = new Map<String, String>();
        
        // Fetch LinkedIn Account ID
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return locationMap; // Return an empty map instead of null
        }
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            // Construct API endpoint URL
            String endpointUrl = System.Label.searchParameterEndPoint +
                '?limit=100&keywords=' + EncodingUtil.urlEncode(keyword, 'UTF-8') +
                '&type=LOCATION&account_id=' + linkedInAccountId;
            
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('Location API Response: ' + response.getBody());
                
                Map<String, Object> responseMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (responseMap.containsKey('items')) {
                    List<Object> items = (List<Object>) responseMap.get('items');
                    
                    for (Object obj : items) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        String title = (String) item.get('title');
                        String locationId = (String) item.get('id');
                        
                        if (!String.isBlank(title) && !String.isBlank(locationId)) {
                            locationMap.put(locationId, title);
                        }
                    }
                }
            } else {
                System.debug('Error: API response status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
        return locationMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> searchIndustry(String keyword) {
        Map<String, String> industryMap = new Map<String, String>();
        
        // Fetch LinkedIn Account ID
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return industryMap;
        }
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            // Construct API endpoint URL
            String endpointUrl = System.Label.searchParameterEndPoint +
                '?limit=100&keywords=' + EncodingUtil.urlEncode(keyword, 'UTF-8') +
                '&type=INDUSTRY&account_id=' + linkedInAccountId;
            
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('Location API Response: ' + response.getBody());
                
                Map<String, Object> responseMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (responseMap.containsKey('items')) {
                    List<Object> items = (List<Object>) responseMap.get('items');
                    
                    for (Object obj : items) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        String title = (String) item.get('title');
                        String industryId = (String) item.get('id');
                        
                        if (!String.isBlank(title) && !String.isBlank(industryId)) {
                            industryMap.put(industryId, title);
                        }
                    }
                }
            } else {
                System.debug('Error: API response status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
        return industryMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> searchCompany(String keyword) {
        Map<String, String> companyMap = new Map<String, String>();
        
        if(keyword=='' || keyword==null){
            return companyMap;
        }
        // Fetch LinkedIn Account ID
        String linkedInAccountId = getLinkedInAccountId();
        if (String.isBlank(linkedInAccountId)) {
            System.debug('No LinkedIn Account found for the user.');
            return companyMap;
        }
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            // Construct API endpoint URL
            String endpointUrl = System.Label.searchContactsEndPoint +'?account_id=' + linkedInAccountId;
            
            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('X-API-KEY', System.Label.apiKeyUNipile);
            request.setHeader('accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            
            String requestBody = JSON.serialize(new Map<String, String>{
                'api' => 'classic',
                    'category' => 'companies',
                    'keywords' => keyword
                    });
            request.setBody(requestBody);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('Company Search API Response: ' + response.getBody());
                
                Map<String, Object> responseMap = 
                    (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if (responseMap.containsKey('items')) {
                    List<Object> items = (List<Object>) responseMap.get('items');
                    
                    for (Object obj : items) {
                        Map<String, Object> item = (Map<String, Object>) obj;
                        String name = (String) item.get('name');
                        String companyId = (String) item.get('id');
                        
                        if (!String.isBlank(name) && !String.isBlank(companyId)) {
                            companyMap.put(companyId, name);
                        }
                    }
                }
            } else {
                System.debug('Error: API response status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
        return companyMap;
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> searchAccounts(String filterData) {
        // Deserialize the incoming JSON payload
        Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterData);
        Integer above10001 = 10001;

        // Extract filter lists
        List<String> industries = toStringList(filters.get('industries'));
        List<String> regions    = toStringList(filters.get('regions'));
        List<String> companies  = toStringList(filters.get('companies'));

        // Revenue filters
        Map<String, Object> revenueData = (Map<String, Object>) filters.get('selectedRevenue');
        Integer minRevenue = (Integer) revenueData.get('min');
        Integer maxRevenue = (Integer) revenueData.get('max');

        // Headcount filters
        Map<String, Object> headCountData = (Map<String, Object>) filters.get('selectedHeadCount');
        Integer minHeadCount = (Integer) headCountData.get('min');
        Integer maxHeadCount = (Integer) headCountData.get('max');
        Boolean avoidMaxHeadCount = (minHeadCount == above10001 || maxHeadCount == null);

        String BASE_URL = System.Label.companySearchEndPoint;
        String linkedInAccountId = getLinkedInAccountId();
        Integer pageSize = 100;

        List<Map<String, Object>> allResults = new List<Map<String, Object>>();

        // Common headers
        Map<String, String> headers = new Map<String, String>{
            'Accept'       => 'application/json',
            'Content-Type' => 'application/json',
            'X-API-KEY'    => System.Label.apiKeyUNipile
        };

        // 1. Base search with full filters
        Map<String, Object> baseBody = new Map<String, Object>{
            'api'      => 'sales_navigator',
            'category' => 'companies'
        };
        
        if (!regions.isEmpty()) baseBody.put('location', new Map<String, Object>{ 'include' => regions });
        
        if (!industries.isEmpty()) baseBody.put('industry', new Map<String, Object>{ 'include' => industries });
        // Apply revenue range
        baseBody.put('annual_revenue', new Map<String, Object>{ 'min' => minRevenue, 'max' => maxRevenue, 'currency' => 'USD' });
        //baseBody.put('headcount', new List<Map<String, Object>>{ new Map<String, Object>{ 'min' => minHeadCount, 'max' => maxHeadCount } });
        // Apply headcount filter
       if (avoidMaxHeadCount) {
            baseBody.put('headcount', new List<Map<String, Object>>{ new Map<String, Object>{ 'min' => minHeadCount } });
        } else {
            baseBody.put('headcount', new List<Map<String, Object>>{ new Map<String, Object>{ 'min' => minHeadCount, 'max' => maxHeadCount } });
        }
        // Execute base search
        String payload = JSON.serialize(baseBody);
        system.debug('payload is '+payload);
        allResults.addAll(executeSearch(payload, BASE_URL, linkedInAccountId, headers, pageSize));

        // 2. Company-specific searches: only keyword + zeroed revenue
        if (!companies.isEmpty()) {
            for (String company : companies) {
                Map<String, Object> compBody = new Map<String, Object>{
                    'api'      => 'sales_navigator',
                    'category' => 'companies',
                    'keywords' => company
                };
                compBody.put('annual_revenue', new Map<String, Object>{ 'min' => 0, 'max' => 0, 'currency' => 'USD' });
                String compPayload = JSON.serialize(compBody);
                allResults.addAll(executeSearch(compPayload, BASE_URL, linkedInAccountId, headers, pageSize));
            }
        }
        return allResults;
    }

    private static List<Map<String, Object>> executeSearch(
        String payload,
        String baseUrl,
        String accountId,
        Map<String, String> headers,
        Integer pageSize
    ) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        String cursor = null;
        try {
            do {
                String url = baseUrl + '?limit=' + pageSize + '&account_id=' + accountId;
                if (cursor != null) url += '&cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8');

                HttpRequest req = new HttpRequest();
                req.setEndpoint(url);
                req.setMethod('POST');
                for (String key : headers.keySet()) req.setHeader(key, headers.get(key));
                req.setBody(payload);

                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() != 200) break;

                Map<String, Object> respBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> items = (List<Object>) respBody.get('items');
                if (items != null) {
                    for (Object obj : items) {
                        Map<String, Object> comp = (Map<String, Object>) obj;
                        if (comp.containsKey('name')) {
                            results.add(new Map<String, Object>{
                                'id'          => comp.get('id'),
                                'name'        => comp.get('name'),
                                'profile_url' => comp.get('profile_url'),
                                'industry'    => comp.get('industry'),
                                'headcount'   => comp.get('headcount')
                            });
                        }
                    }
                }

                cursor = (String) respBody.get('cursor');
            } while (cursor != null);
        } catch (Exception ex) {
            System.debug('Search error: ' + ex.getMessage());
        }
        return results;
    }
    
    public class CreateAccountWrapper {
        @AuraEnabled public String id { get; set; }     
        @AuraEnabled public String headcount { get; set; }  
        @AuraEnabled public String profile_url { get; set; }  
        @AuraEnabled public String name { get; set; }       
        @AuraEnabled public String industry { get; set; }   
        
    }
    
    @AuraEnabled
    public static Map<String, List<Account> > createAccount(List<CreateAccountWrapper> selectedAccounts){
        
        List<Account> accountsToInsert = new List<Account>();
        List<Account> accountsToUpdate = new List<Account>();
        Set<String> linkedInIds = new Set<String>();
        Set<String> names = new Set<String>();
        Set<String> profileUrls = new Set<String>();
        Set<String> customIndustryNames = new Set<String>();
        
        Set<String> standardIndustryPicklistSet = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Account.Industry.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            standardIndustryPicklistSet.add(entry.getValue());
        }
        
        for (CreateAccountWrapper record : selectedAccounts) {
            if (String.isNotBlank(record.id)) linkedInIds.add(record.id.trim());
            if (String.isNotBlank(record.name)) names.add(record.name.trim());
            if (String.isNotBlank(record.profile_url)) profileUrls.add(record.profile_url.trim());
            if (String.isNotBlank(record.industry) && !standardIndustryPicklistSet.contains(record.industry.trim())) {
                customIndustryNames.add(record.industry.trim());
            }
        }
        
        Map<String, Account> matchedAccountsMap = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Name, LinkedIn_Id__c, LinkedIn_Profile__c, NumberOfEmployees, Industry, Industry__c, Industry__r.Name__c, Owner.Name
            FROM Account
            WHERE LinkedIn_Id__c IN :linkedInIds
            OR Name IN :names
            OR LinkedIn_Profile__c IN :profileUrls
        ]) {
            if (String.isNotBlank(acc.LinkedIn_Id__c)) {
                matchedAccountsMap.put(acc.LinkedIn_Id__c, acc);
            } else if (String.isNotBlank(acc.Name)) {
                matchedAccountsMap.put(acc.Name, acc);
            } else if (String.isNotBlank(acc.LinkedIn_Profile__c)) {
                matchedAccountsMap.put(acc.LinkedIn_Profile__c, acc);
            }
        }
        
        Map<String, Id> industryNameToIdMap = new Map<String, Id>();
        List<Industry__c> newIndustriesToInsert = new List<Industry__c>();
        
        for (Industry__c ind : [SELECT Id, Name__c FROM Industry__c WHERE Name__c IN :customIndustryNames]) {
            industryNameToIdMap.put(ind.Name__c, ind.Id);
        }
        
        for (String name : customIndustryNames) {
            if (!industryNameToIdMap.containsKey(name)) {
                newIndustriesToInsert.add(new Industry__c(Name__c = name));
            }
        }
        
        if (!newIndustriesToInsert.isEmpty()) {
            insert newIndustriesToInsert;
            for (Industry__c newInd : newIndustriesToInsert) {
                industryNameToIdMap.put(newInd.Name__c, newInd.Id);
            }
        }
        
        for (CreateAccountWrapper record : selectedAccounts) {
            Account acc;
            Boolean isUpdate = false;
            
            if (matchedAccountsMap.containsKey(record.id)) {
                acc = matchedAccountsMap.get(record.id);
                isUpdate = true;
            } else if (matchedAccountsMap.containsKey(record.name)) {
                acc = matchedAccountsMap.get(record.name);
                isUpdate = true;
            } else if (matchedAccountsMap.containsKey(record.profile_url)) {
                acc = matchedAccountsMap.get(record.profile_url);
                isUpdate = true;
            } else {
                acc = new Account();
                acc.LinkedIn_Id__c = record.id;
            }
            
            acc.Name = record.name;
            acc.LinkedIn_Profile__c = record.profile_url;
            
            if (String.isNotBlank(record.headcount)) {
                try {
                    acc.NumberOfEmployees = Integer.valueOf(record.headcount);
                } catch (Exception e) {
                    System.debug('Invalid headcount for ' + record.name + ': ' + record.headcount);
                }
            }
            
            if (String.isNotBlank(record.industry)) {
                String industryTrimmed = record.industry.trim();
                if (standardIndustryPicklistSet.contains(industryTrimmed)) {
                    acc.Industry = industryTrimmed;
                } else if (industryNameToIdMap.containsKey(industryTrimmed)) {
                    acc.Industry__c = industryNameToIdMap.get(industryTrimmed);
                }
            }
            
            if (isUpdate) {
                accountsToUpdate.add(acc);
            } else {
                accountsToInsert.add(acc);
            }
        }
        
        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
            accountsToInsert = [
                SELECT Id, Name, LinkedIn_Id__c, LinkedIn_Profile__c, NumberOfEmployees, Industry, Industry__c, Industry__r.Name__c, Owner.Name
                FROM Account
                WHERE Id IN :accountsToInsert
            ];
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
        
        
        Map<String, List<Account>> result = new Map<String, List<Account>>();
        
        result.put('createdAccount', accountsToInsert);
        result.put('updatedAccount', accountsToUpdate);
        
        return result;
    }
    
    public static List<String> toStringList(Object rawList) {
        List<String> result = new List<String>();
        if (rawList instanceof List<Object>) {
            for (Object item : (List<Object>) rawList) {
                result.add(String.valueOf(item));
            }
        }
        return result;
    }
    
    @AuraEnabled
    public static List<String> searchSalesforceIndustry(String searchTerm) {
        List<String> matchedIndustries = new List<String>();
        Set<String> uniqueMatches = new Set<String>();
        
        String likeTerm = '%' + searchTerm.toLowerCase() + '%';
        
        Schema.DescribeFieldResult fieldResult = Account.Industry.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistEntries) {
            String label = entry.getLabel();
            if (label != null && label.toLowerCase().contains(searchTerm.toLowerCase())) {
                uniqueMatches.add(label);
            }
        }
        
        for (Industry__c ind : [
            
            SELECT Name__c 
            FROM Industry__c 
            WHERE Name__c != null AND Name__c LIKE :likeTerm
            LIMIT 20
        ]) {
            uniqueMatches.add(ind.Name__c);
        }
        
        matchedIndustries.addAll(uniqueMatches);
        matchedIndustries.sort();
        return matchedIndustries;
    }
}