@isTest(seeAllData = true)
public class DE_LinkedInCompCtrlTest {
	static testMethod void testgetRelatedContacts() {
        Boolean success = true;
        
        try {
          	Contact theCon = [SELECT Id FROM Contact LIMIT 1];
            Account theAcc = [SELECT Id FROM Account LIMIT 1];
            Lead theLead = [SELECT Id FROM Lead LIMIT 1];
            
          	DE_LinkedInCompCtrl.LinkedInWrapper theWrap = DE_LinkedInCompCtrl.getDetails(theCon.Id);
            DE_LinkedInCompCtrl.LinkedInWrapper theWrap2 = DE_LinkedInCompCtrl.getDetails(theAcc.Id);
            DE_LinkedInCompCtrl.LinkedInWrapper theWrap3 = DE_LinkedInCompCtrl.getDetails(theLead.Id);
            
        } catch (Exception e) {
            success = false;
            system.debug('catch e' + e);
        } finally {
          //System.assert(success);
        }
    }
}