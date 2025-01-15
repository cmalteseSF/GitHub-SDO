/*
* 
* B2CCmexGetChurnScore
*
* sfiVersion - 238.0
*
* Description: Apex Class used to make callout to ai accelerator and get the realtime churn score for a given subscription
*    
*/



global inherited sharing class B2CCmexGetChurnScore
{
    
    @InvocableMethod(
        label='Get Churn Score'
        description='This function returns score for active subscription')
    global static List<ChurnScoreResponse> getChurnScore(List<ChurnScoreRequest> requests)
    {
        List<ChurnScoreResponse> results = new List<ChurnScoreResponse>();
        for(ChurnScoreRequest request : requests){
            ChurnScoreResponse res = new ChurnScoreResponse();
            try {
                res.churnScore = fetchScore(request.subscriptionId, 
                                       request.usecaseId,
                                       request.goalId);

            } catch (Exception ex){
                
            } finally{
                results.add(res);
            }
                
        }
        return results;
    }

    public static Double fetchScore(String subscriptionId, String usecaseId, String goalId){
        
        Double score;
        
        //generate prediction request
        ConnectApi.PredictionRequest predictionInputRepresentation = createRequest(usecaseId, goalId, subscriptionId);
        
        // invoke ai accelerator
        ConnectApi.PredictionResponse predictionOutputRepresentation = ConnectApi.AIAcceleratorConnectFamily.predictions(predictionInputRepresentation);
        System.debug(String.valueOf(predictionOutputRepresentation));
        if(predictionOutputRepresentation.predictions[0]!=null && predictionOutputRepresentation.predictions[0].prediction!=null && predictionOutputRepresentation.predictions[0].prediction.score!=null){
            score = predictionOutputRepresentation.predictions[0].prediction.score;
        }
        
        return score;
    }

    public static ConnectApi.PredictionRequest createRequest(String usecaseId, String goalId, String subscriptionId){
        ConnectApi.PredictionRequest predictionInputRepresentation = new ConnectApi.PredictionRequest();
        predictionInputRepresentation.usecaseDefinition = usecaseId;
        predictionInputRepresentation.predictionDefinition = goalId;
        predictionInputRepresentation.inputType ='ExtractedRecordOverrides';
        
        
        // subscritpion_id recordid
        List<String> ids = new List<String>();
        ids.add(subscriptionId);
        predictionInputRepresentation.records = ids;
        
        // subscritpionid for feature extractor
        Map<String, Object> featureExtractionParams = new Map<String, Object>();
        featureExtractionParams.put('subscription_id', subscriptionId);
        
        ConnectApi.FeatureExtractionParametersFieldMapValue featureExtractionParametersFieldMapValue = new ConnectApi.FeatureExtractionParametersFieldMapValue();
        featureExtractionParametersFieldMapValue.featureExtractionParametersMapValue = featureExtractionParams;
        
        List<ConnectApi.FeatureExtractionParametersFieldMapValue> featureExtractionParametersMapValues = new List<ConnectApi.FeatureExtractionParametersFieldMapValue>();
        featureExtractionParametersMapValues.add(featureExtractionParametersFieldMapValue);
        predictionInputRepresentation.featureExtractionParameters = featureExtractionParametersMapValues;
        
        
        // other properties
        predictionInputRepresentation.async = false;
        predictionInputRepresentation.enableInsightPersistence = false;
        predictionInputRepresentation.enableFeaturePersistence = false;
        
        return predictionInputRepresentation;
     }
    
    global class ChurnScoreRequest {
      @InvocableVariable(label='Subscription Id' description='SubscriptionId for which score needs to be computed' required=true)
      public String subscriptionId;
      @InvocableVariable(label='Usecase Id' description='UsecaseId configured in AiUsecaseDefinition' required=true)
      public String usecaseId;
      @InvocableVariable(label='Goal ID' description='GoalId configured for usecaseId' required=true)
      public String goalId;
    }
    
    global class ChurnScoreResponse {
      @InvocableVariable(label='Churn Score' description='Churn Score for subscription' required=true)
      public Double churnScore;
    }
}