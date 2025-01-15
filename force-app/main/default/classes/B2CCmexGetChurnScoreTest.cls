/*
* 
* B2CCmexCreateSubscriptionTest
*
* sfiVersion - 238.0
*
* Description: Test class for B2CCmexGetChurnScore apex class
*/

@isTest
private class B2CCmexGetChurnScoreTest {

/*
{
    "usecaseDefinition": "0sIB00000000006MAA",
    "predictionDefinition": "1ORB0000000CcojOAC",
    "inputType": "ExtractedRecordOverrides",
    "insightsSettings": {
        "insightsSettings": {
            "maxSuggestionCount": 3,
            "suggestionImpactMinimumPct": 5
        }
    },
    "featureExtractorId": "0sKB0000000000BMAQ",
    "historyReferencePoint": "lastChange",
    "records": {
        "wrappedList": [
            "a1eB0000000MX5RIAW"
        ]
    },
    "featureExtractionParameters": {
        "featureExtractionParameters": [
            {
                "featureExtractionParametersMapValue": {
                    "recordId": "a1eB0000000MX5RIAW"
                }
            }
        ]
    },
    "enrichPredictionDefinition": true,
    "enrichModelClassification": true,
    "enrichModelFeatures": true,
    "async": false
}
*/
    
    @TestSetup
    static void createTestData()
    {
        Account Acc = new Account(Name='Test Account');
        Insert Acc;
        
        vlocity_cmt__Subscription__c Sub = new vlocity_cmt__Subscription__c(Name='Test Subscription', vlocity_cmt__AccountId__c=Acc.Id, vlocity_cmt__StartDate__c=System.Today() , vlocity_cmt__Status__c='Active', vlocity_cmt__SubscriptionNumber__c='123456');
        insert Sub;
    }
    
    
    @isTest
    static void getChurnScoreTest() {
        
        vlocity_cmt__Subscription__c sub = [Select Id From vlocity_cmt__Subscription__c limit 1];
        List<B2CCmexGetChurnScore.ChurnScoreRequest> requests = new List<B2CCmexGetChurnScore.ChurnScoreRequest>();
        B2CCmexGetChurnScore.ChurnScoreRequest req1 = new B2CCmexGetChurnScore.ChurnScoreRequest();
        req1.subscriptionId = sub.Id;
        req1.usecaseId = '0sIB00000000006MAA';
        req1.goalId = '1ORB0000000CcojOAC';
        requests.add(req1);
        
        ConnectApi.PredictionRequest predictionInputRepresentation = B2CCmexGetChurnScore.createRequest('0sIB00000000006MAA','1ORB0000000CcojOAC', sub.Id);
        
        ConnectApi.PredictionResponse predictionOutputRepresentation = new ConnectApi.PredictionResponse();
        
        Test.startTest();
        ConnectApi.AIAcceleratorConnectFamily.setTestPredictions(predictionInputRepresentation, predictionOutputRepresentation);
        B2CCmexGetChurnScore.getChurnScore(requests);
        Test.stopTest();
    }
    
}