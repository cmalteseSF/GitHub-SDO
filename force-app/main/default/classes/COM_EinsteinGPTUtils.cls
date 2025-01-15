/**
 * This is a handy set of utilities to interact with EinsteinGPT from OmniStudio
 * 
 * @author Joe McMaster (joe.mcmaster@salesforce.com)
 * @version 1.0
 * 
 * History
 * -------
 * Aug  8, 2023 - Initial Version
 * 
 */
global with sharing class COM_EinsteinGPTUtils implements vlocity_cmt.VlocityOpenInterface, Callable {

    /**
     * Standard entry point for OmniStudio Standard
     *
     * @param action  - The action/method to execute
     * @param args    - The input, output, and options arguments
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
     public Object call(String action, Map<String, Object> args) {

        return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
     }
     
    /*
     * Standard entry point for OmniStudio for Vlocity
     */
     global Boolean InvokeMethod( String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        
        try {
            
            if (methodName.equals('question')) {
                question(input, output, options);
                return true;
            }
        } 
        catch (Exception e) {

            output.put('Method', methodName);
            output.put('Error', e.getMessage());
            output.put('ErrorLine', e.getLineNumber());

            System.debug(LoggingLevel.ERROR, e.getMessage());       
        }

        return false;
    }

    private void question(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        
        String context = input.get('context').toString();
        String prompt  = input.get('question').toString();

        // Create the EinsteinGPT Request
        ConnectApi.EinsteinLlmGenerationsInput generationsInput = new ConnectApi.EinsteinLlmGenerationsInput();
        generationsInput.promptTextorId = context + '\n' + prompt;        
        generationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        //generationsInput.additionalConfig.applicationName = 'CommsBillingInquiryAssistant';  // required in 248
        generationsInput.additionalConfig.applicationName = 'EinsteinGPTPlayground';  // works in 246
        generationsInput.additionalConfig.maxTokens = 1024;

        // Call the service
        ConnectApi.EinsteinLLMGenerationsOutput generationsOutput = ConnectApi.EinsteinLLM.generateMessages(generationsInput);

        // Consume response
        ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
        System.debug('Response: ' + response.text);        

        output.put('response', response.text);
    }    
}