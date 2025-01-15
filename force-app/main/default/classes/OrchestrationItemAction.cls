/**
 * This class exposes a method that can be invoked by Salesforce Process Builder.  It makes an
 * asynchronous callback to an active Orchestration Item that is waiting for any update/completion events (XOM Callout)
 *
 * @author Joe McMaster (jmcmaster@vlocity.com)
 *
 * @version 1.1
 *
 * History
 * =======
 * 1.0 - May 17, 2019 - Initial Version
 * 1.1 - Mar 23, 2022 - Updated as OM endpoint may have changed (requires Content-Type header and order_id in payload)
 *
 */
global with sharing class OrchestrationItemAction {
    
    /**
     * This is a method that can be invoked by the Salesforce Process Builder.
     *
     * @param input  A list of input objects
     * 
     * @return A list of output objects
     */
    @InvocableMethod (label = 'Orchestration Item Callback')
    global static List<OrchestrationItemActionOutput> runIntegrationService(List<OrchestrationItemActionInput> input) {
        
        List<OrchestrationItemActionOutput> output = new List<OrchestrationItemActionOutput>();
        
        Iterator<OrchestrationItemActionInput> iter = input.iterator();
        while (iter.hasNext()) {
        
            OrchestrationItemActionInput actionInput = iter.next();
            if (actionInput.callbackURI != null && !actionInput.callbackURI.equals('') && actionInput.orderId != null && !actionInput.orderId.equals('')) {
                
                Map<String, Object> payload = new Map<String, Object>();
                payload.put('order_id', actionInput.orderId);
                sendCallback(URL.getOrgDomainUrl().toExternalForm() + actionInput.callbackURI, JSON.serialize(payload));
            }
            else System.debug('JOE - Invalid Input.  Action is missing callbackURI or orderId');
        }
        
        return output;
    }    

    /**
     * Makes the actual REST callback
     * 
     * @param url      The callback endpoint
     * @param payload  A payload to send to the callback endpoint
     */
    @future (callout = true)
    private static void sendCallback(String url, String payload) {
        
        System.debug('JOE - Callback Request -> ' + url);
        System.debug('JOE - Callback Payload -> ' + payload);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(payload);
   
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        System.debug('JOE - Callback Response Code -> ' + res.getStatusCode() + ' (' + res.getStatus() + ')');
        System.debug('JOE - Callback Response -> ' + JSON.serialize(res.getBody()));
    }
    
    /**
     * Inner class that defined the input object for this action
     *
     */
    global class OrchestrationItemActionInput {
        
        @InvocableVariable(label='callbackURI')
        global String callbackURI;
        @InvocableVariable(label='orderId')
        global String orderId;
    }

    /**
     * Inner class that defines the output object for this action
     *
     */
    global class OrchestrationItemActionOutput {
        
        @InvocableVariable(label='Output')
        global String output;
    }
}