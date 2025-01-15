public with sharing class SlackChannelMenuCtrl {
    
    // Query for all items in a specific accession
    @AuraEnabled
    public static List<Slack_Channel__c> getChannels(String recordId) {
        return [SELECT Id, Account__c, Button_Label__c, Slack_Channel_URL__c, Description__c, Display_Order__c, Name FROM Slack_Channel__c WHERE Account__c =: recordId ORDER BY Display_Order__c ASC];  
    }
    
}