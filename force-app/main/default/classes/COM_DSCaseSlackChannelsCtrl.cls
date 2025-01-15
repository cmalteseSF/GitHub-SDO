public class COM_DSCaseSlackChannelsCtrl {

    // Look for Case Matches
    @AuraEnabled
    public static List<Slack_Channel__c> getChannels(String recordId) {
        return [SELECT Id, COM_Case__c, Button_Label__c, Slack_Channel_URL__c, Description__c, Display_Order__c, Name FROM Slack_Channel__c WHERE COM_Case__c =: recordId OR Account__c =: recordId ORDER BY Display_Order__c ASC];
    }
    
    
    
}