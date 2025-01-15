public class DE_LinkedInCompCtrl {

    @AuraEnabled
    public static LinkedInWrapper getDetails(Id recordId){
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        String theQuery = '';
        sObject theRecord;
        List<User> theList = new List<User>();
        if(sObjName == 'Contact'){
            theQuery = 'SELECT Id, Name, Title, Account.Name, LinkedIn_Time_in_role__c, LinkedIn_Area__c, LinkedIn_Industry__c, LinkedIn_Connections__c, COM_Profile_URL__c FROM Contact WHERE Id = :recordId';
            theRecord = Database.query(theQuery);
            List<Linkedin_Contact__c> tempList = [SELECT Id, TeamLink1__c, TeamLink__c FROM Linkedin_Contact__c WHERE TeamLink1__c = :theRecord.Id];
            if(!tempList.isEmpty()){
                for(Integer i=0;i<tempList.size();i++){
                    User tempUser = [SELECT Id, Name, Title, LinkedIn_Industry__c, LinkedIn_Area__C FROM User WHERE Id = :tempList[i].TeamLink__c];
                    theList.add(tempUser);
                }
            }
        }
        else if(sObjName == 'Account'){
            theQuery = 'SELECT Id, Name, LinkedIn_Area__c, LinkedIn_Industry__c, LinkedIn_Connections__c, COM_Profile_URL__c FROM Account WHERE Id = :recordId';
            theRecord = Database.query(theQuery);
            //Added this to make it work for Account
            List<Linkedin_Account__c> tempList = [SELECT Id, Account__c, User__c FROM Linkedin_Account__c WHERE Account__c = :theRecord.Id];
            if(!tempList.isEmpty()){
                for(Integer i=0;i<tempList.size();i++){
                    User tempUser = [SELECT Id, Name, Title, LinkedIn_Industry__c, LinkedIn_Area__C FROM User WHERE Id = :tempList[i].User__c];
                    theList.add(tempUser);
                }
            }
            //End
        }
        else if(sObjName == 'Lead'){
            theQuery = 'SELECT Id, Name, LinkedIn_Time_in_role__c, LinkedIn_Area__c, LinkedIn_Industry__c, LinkedIn_Connections__c, COM_Profile_URL__c FROM Lead WHERE Id = :recordId';
            theRecord = Database.query(theQuery);
            //Added this to make it work for Lead
            List<Linkedin_Lead__c> tempList = [SELECT Id, Lead__c, TeamLink__c FROM Linkedin_Lead__c WHERE Lead__c = :theRecord.Id];
            if(!tempList.isEmpty()){
                for(Integer i=0;i<tempList.size();i++){
                    User tempUser = [SELECT Id, Name, Title, LinkedIn_Industry__c, LinkedIn_Area__C FROM User WHERE Id = :tempList[i].TeamLink__c];
                    theList.add(tempUser);
                }
            }
            //End
        }
        
        LinkedInWrapper theWrapper = new LinkedInWrapper(theRecord, sObjName, theList);
        return theWrapper;
    }
    
    public class LinkedInWrapper{
        @AuraEnabled
        public sObject theObject {get;set;}
        @AuraEnabled
        public String theType {get;set;}
        @AuraEnabled
        public User[] theRelatedList {get;set;}
        
        public LinkedInWrapper(sObject theObj, String theT, User[] theRl){
            this.theObject = theObj;
            this.theType = theT;
            this.theRelatedList = theRl;
        }
    }
}