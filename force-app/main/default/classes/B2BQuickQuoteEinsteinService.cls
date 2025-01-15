/*
*********************************************************
Apex Class Name    : B2BQuickQuoteEinsteinService
@description       : This is class used to expose the EinsteinGPT connectAPIs for Quick Quote in ESM
*********************************************************
*/

global with sharing class B2BQuickQuoteEinsteinService implements vlocity_cmt.VlocityOpenInterface, Callable 
{
  
    // Define a map of characters to escape
    private static Map<String, String> escapeMap = new Map<String, String>
    {
            '<' => '&lt;',
            '>' => '&gt;',
            '&' => '&amp;'
            // '"' => '&quot;',     We comment this line to keep double quotes unescaped
            // '\\'' => '&#39;'     We comment this line to keep single quotes unescaped
    };
    
    /*
        The method gets invoked by the IntegrationProcedure
    */
    public Object call(String action, Map<String, Object> args) 
    {
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    /*
        Calls the appropriate method based on the action to be performed
    */
    public Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) 
    {
        try 
        {
            if(methodName.equalsIgnoreCase('sendRequest'))
            {
                sendRequest(input, output, options);
                return true;
            }

            if(methodName.equalsIgnoreCase('setCacheDataForRecommendation'))
            {
                setCacheDataForRecommendation(input, output, options);
                return true;
            }

            if(methodName.equalsIgnoreCase('getCacheDataForRecommendation'))
            {
                getCacheDataForRecommendation(input, output, options);
                return true;
            }

            if(methodName.equalsIgnoreCase('clearCacheDataForRecommendation'))
            {
                clearCacheDataForRecommendation(input, output, options);
                return true;
            }
                
            return false;
        }
        catch (Exception ex)
        {
            System.debug('Exception thrown at invoke ' + ex.getMessage() + '\nException thrown at invoke trace ' + ex.getStackTraceString());
            throw ex;
        }
    }

    private static void logInstrumentation(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        Map<String, Object> ipOutput = (Map<String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService('quickquote_instrumentation', input, options);
    }

    /*
        Makes a ConnectApi call to submit query to EinsteinGPT.
        @param: input -> Request params to be passed to the ConnectApi
        @param: output -> ConnectApi response
    */
    private static void sendRequest(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) 
    {
        try 
        {
            // Create the EinsteinGPT Request
            ConnectApi.EinsteinLlmGenerationsInput generationsInput = new ConnectApi.EinsteinLlmGenerationsInput();

            if(isNotEmpty((String)input.get('context'))) 
            {

                String context = input.get('context').toString();
                if(isNotEmpty((String)input.get('data'))) {
                    String data  = '<data_ba>' + '\n' + input.get('data').toString() + '\n' + '</data_ba>';
                    generationsInput.promptTextorId = context + '\n' + data;
                } else {
                    generationsInput.promptTextorId = context;
                }
            }
            else 
            {
                throw new IllegalArgumentException('Missing Input: <context> and <data>');
            }

            populateGenerationsInputParameters(input, generationsInput);

            // Call the service
            ConnectApi.EinsteinLLMGenerationsOutput generationsOutput = ConnectApi.EinsteinLLM.generateMessages(generationsInput);

            // Consume response
            ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
            
            // encoding/escaping for sanitizing the output. HTML escaping is used as our case is to render output in html page
            Boolean isEscapingRequired = false;
            if(isNotEmpty(input.get('escapeResponse'))) 
            {
                isEscapingRequired = Boolean.valueOf(input.get('escapeResponse'));
            }
            if(isEscapingRequired) 
            {
                String result = escape(response.text);
                output.put('response', result);
            } 
            else 
            {
                output.put('response', response.text);
            }
            logInstrumentation(input,output,options);
        }
        catch (ConnectApi.ConnectApiException ex) 
        {
            output.put('ErrorMessage', ex.getMessage());
            output.put('ErrorCode', ex.getErrorCode());
        }
        catch (Exception ex) 
        {
            output.put('ErrorType', ex.getTypeName());
            output.put('ErrorMessage', ex.getMessage());
        }
    }

    private static String escape(String input) 
    {     
        if(String.isBlank(input)) 
        {
            return input;
        }
        
        // Replace each character in the input string with its escaped counterpart
        for(String character : escapeMap.keySet()) 
        {
            input = input.replace(character, escapeMap.get(character));
        }
        
        return input;
    }

    private static void populateGenerationsInputParameters(Map<String, Object> input, ConnectApi.EinsteinLlmGenerationsInput generationsInput) 
    {
        //Provider
        if(isNotEmpty(input.get('provider'))) 
        {
            generationsInput.provider = (String)input.get('provider');
        }

        //Additional Config for Einstein LLM
        //
        //applicationName(String) | maxTokens(Integer) | model(String) | temperature(Number) | numGenerations(Integer) |
        //enablePiiMasking(Boolean) | stopSequences(Array), frequencyPenalty(Number), presencePenalty(Number), additionalParameters(Map)
        //
        generationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        generationsInput.additionalConfig.applicationName = 'CommsBillingInquiryAssistant';

        if(isNotEmpty((Integer)input.get('maxTokens'))) 
        {
            generationsInput.additionalConfig.maxTokens = (Integer)input.get('maxTokens');
        }

        if(isNotEmpty(input.get('model'))) 
        {
            generationsInput.additionalConfig.model = (String)input.get('model');
        }
        if(isNotEmpty(input.get('temperature'))) 
        {
            generationsInput.additionalConfig.temperature = Double.valueOf(input.get('temperature'));
        }
        if(isNotEmpty(input.get('numGenerations'))) 
        {
            generationsInput.additionalConfig.numGenerations = Integer.valueOf(input.get('numGenerations'));
        }
        if(isNotEmpty(input.get('enablePiiMasking'))) 
        {
            generationsInput.additionalConfig.enablePiiMasking = Boolean.valueOf(input.get('enablePiiMasking'));
        }
        if((input.get('stopSequences') != null) && isNotEmptyList((List<String>)input.get('stopSequences'))) 
        {
            generationsInput.additionalConfig.stopSequences = (List<String>)input.get('stopSequences');
        }
        if(isNotEmpty(input.get('frequencyPenalty'))) 
        {
            generationsInput.additionalConfig.frequencyPenalty = Double.valueOf(input.get('frequencyPenalty'));
        }
        if(isNotEmpty(input.get('presencePenalty'))) 
        {
            generationsInput.additionalConfig.presencePenalty = Double.valueOf(input.get('presencePenalty'));
        }
        if((input.get('additionalParameters') != null) && isNotEmptyMap((Map<String, Object>)input.get('additionalParameters'))) 
        {
            Map<String, Object> additionalParameters = (Map<String, Object>)input.get('additionalParameters');
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            for (String key : additionalParameters.keySet()) 
            {
                ConnectApi.WrappedValue wrappedValue = new ConnectApi.WrappedValue();
                wrappedValue.value = additionalParameters.get(key);
                inputParams.put(key, wrappedValue);
            }
            generationsInput.additionalConfig.additionalParameters = inputParams;
        }
    }

    /*
        Sets the recommendation data in platorm session cache
        @param: input -> Request params coming from integration procedure
        @param: output -> Returns success true 
    */
    private static void setCacheDataForRecommendation(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) 
    {
        if(isNotEmpty((String)input.get('recommendationData')) && isNotEmpty((String)input.get('contextId'))) {
            String contextId = input.get('contextId').toString();
            String recommendationData = input.get('recommendationData').toString();
            String cacheKey = 'local.QuickQuote.' + contextId;
            Cache.Session.put(cacheKey, recommendationData);
            output.put('Success', true);
        }
    }

     /*
        Gets the recommendation data in platorm session cache
        @param: input -> Request params coming from integration procedure
        @param: output -> Returns CachedData node with data or Error node if key is not found 
    */
    private static void getCacheDataForRecommendation(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) 
    {
        if(isNotEmpty((String)input.get('contextId'))) {
            String contextId = input.get('contextId').toString();
            String cacheKey = 'local.QuickQuote.' + contextId;
            if(Cache.Session.contains(cacheKey)) {
                String retrivedData = (String)Cache.Session.get(cacheKey);
                output.put('CacheData', retrivedData);
            } else {
                output.put('Error', 'Context not found');
            }
        }
    }

    /*
        Clears the recommendation data in platorm session cache
        @param: input -> Request params coming from integration procedure
        @param: output -> Returns Success node with true or Error node if key is not found 
    */
    private static void clearCacheDataForRecommendation(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) 
    {
        if(isNotEmpty((String)input.get('contextId'))) {
            String contextId = input.get('contextId').toString();
            String cacheKey = 'local.QuickQuote.' + contextId;
            if(Cache.Session.contains(cacheKey)){
                Cache.Session.remove(cacheKey);
                output.put('Success', true);
            } else {
                output.put('Error', 'Invalid context');
            }
        }
    }

    private static Boolean isNotEmpty(Object input)
    {
        return input != null && input != '';
    }

    private static Boolean isNotEmptyList(List<Object> input)
    {
        return input != null || input.size() != 0;
    }

    private static Boolean isNotEmptyMap(Map<String, Object> input)
    {
        return input != null || input.size() != 0;
    }
}