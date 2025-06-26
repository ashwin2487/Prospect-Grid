@isTest
global class MockLinkedInApiResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"items": [{"id": "1", "name": "Test Company 1", "profile_url": "https://linkedin.com/test1", "industry": "Technology", "headcount": 50}], "cursor": null}');
        return res;
    }
}