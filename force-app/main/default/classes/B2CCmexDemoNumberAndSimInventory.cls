/*
*
*   Description :   This class is used perform get and update operations on number and sim inventory.
*                   Purpose of this class is to demonstrate the various operations on mock inventory and is not part of the solution or implementation.
*
*/
global without sharing class B2CCmexDemoNumberAndSimInventory implements vlocity_cmt.VlocityOpenInterface, Callable{

    public Boolean call(String action, Map<String, Object> args)
    {
        Map<String, Object> inputMap = (Map<String, Object>) args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, inputMap, outputMap, options);
    }
    public Boolean invokeMethod(String methodName, Map<String,Object> input,Map<String,Object> output,Map<String,Object> options){
            try{
                if (methodName.equalsIgnoreCase('restructureAutoAssignmentValues')){
                    restructureAutoAssignmentValues(input,output,options);
                }
                if (methodName.equalsIgnoreCase('getNumberList')){
                    getNumberList(input,output,options);
                }
                if (methodName.equalsIgnoreCase('getSimDetailsList')){
                    getSimDetailsList(input,output,options);
                }
                if (methodName.equalsIgnoreCase('reserveLockNumber')){
                    reserveLockNumber(input,output,options);
                }
                if (methodName.equalsIgnoreCase('updateNumberList')){
                    updateNumberList(input,output,options);
                }
                if (methodName.equalsIgnoreCase('updateSimList')){
                    updateSimList(input,output,options);
                }
                return true;
            }catch(Exception e){
                    return false;
                }
             
    }
    
    public void restructureAutoAssignmentValues(Map<String,Object> inputMap,Map<String,Object> outputMap,Map<String,Object> optionsMap){
        
  
        List<Object> listNumberDetails = (List<Object>)inputMap.get('AutoAssignmentPhoneNumberDetails');
        List<Object> listSimDetails = (List<Object>)inputMap.get('AutoAssignmentSimCardDetails');
        List<Map<String,String>> listAutoassignmentNumberSimDetails = new List<Map<String,String>>();
        
        if(!listNumberDetails.isEmpty() && !listSimDetails.isEmpty() && listNumberDetails.size()==listSimDetails.size()){
            for(Integer i=0; i<listNumberDetails.size(); i++){
                Map<String,String> mapAutoassignmentDetails = new Map<String,String>();
                mapAutoassignmentDetails.put('MSISDN',(String)((Map<String,Object>)listNumberDetails[i]).get('MSISDN'));
                mapAutoassignmentDetails.put('VanityType',(String)((Map<String,Object>)listNumberDetails[i]).get('VanityType'));
                mapAutoassignmentDetails.put('ICCID',(String)((Map<String,Object>)listSimDetails[i]).get('ICCID'));
                mapAutoassignmentDetails.put('IMSI',(String)((Map<String,Object>)listSimDetails[i]).get('IMSI'));
                listAutoassignmentNumberSimDetails.add(mapAutoassignmentDetails);
            }
            if(!listAutoassignmentNumberSimDetails.isEMpty()){
                outputMap.put('AutoassignmentNumberSimDetails',listAutoassignmentNumberSimDetails);
            }
        }
        
        
    }
    
    
    public void getNumberList(Map<String,Object> inputMap,Map<String,Object> outputMap,Map<String,Object> optionsMap){
        
        Integer limitCount = Integer.valueOf(inputMap.get('LimitCount'));
        String status = (String)inputMap.get('Status');
        String numberType = (String)inputMap.get('NumberType');
        
        List<Map<String,String>> listNumberDetails = new List<Map<String,String>>();
        Set<String> setMSISDN = new Set<String>();
        List<VPL_NumberInventory__c> listNumberInventory = [SELECT Id,VPL_Number__c,VPL_Status__c,VPL_Type__c FROM VPL_NumberInventory__c WHERE VPL_Status__c =: status AND VPL_Type__c =: numberType LIMIT: limitCount];
        if(!listNumberInventory.isEmpty()){
            for(Integer i=0; i<listNumberInventory.size(); i++){
                Map<String,String> mapNumberList = new Map<String,String>();
                mapNumberList.put('MSISDN',listNumberInventory[i].VPL_Number__c);
                mapNumberList.put('VanityType',listNumberInventory[i].VPL_Type__c);
                mapNumberList.put('Status',listNumberInventory[i].VPL_Status__c);
                mapNumberList.put('Id',listNumberInventory[i].Id);
                listNumberDetails.add(mapNumberList);
                setMSISDN.add(listNumberInventory[i].VPL_Number__c);
            }
            if(!listNumberDetails.isEMpty()){
                outputMap.put('NumberList',listNumberDetails);
            }
        }
    }
    
    
    public void getSimDetailsList(Map<String,Object> inputMap,Map<String,Object> outputMap,Map<String,Object> optionsMap){
        
        Integer limitCount = Integer.valueOf(inputMap.get('LimitCount'));
        String status = (String)inputMap.get('Status');
        
        List<Map<String,String>> listSimDetails = new List<Map<String,String>>();
        Set<String> setICCID = new Set<String>();
        List<VPL_SimInventory__c> listSimInventory = [SELECT Id, VPL_ICCID__c, VPL_Status__c, VPL_IMSI__c, VPL_Serial_Number__c FROM VPL_SimInventory__c WHERE VPL_Status__c =: status LIMIT: limitCount];
        if(!listSimInventory.isEmpty()){
            for(Integer i=0; i<listSimInventory.size(); i++){
                Map<String,String> mapSimList = new Map<String,String>();
                mapSimList.put('ICCID',listSimInventory[i].VPL_ICCID__c);
                mapSimList.put('IMSI',listSimInventory[i].VPL_IMSI__c);
                mapSimList.put('Status',listSimInventory[i].VPL_Status__c);
                mapSimList.put('SerialNumber',listSimInventory[i].VPL_Serial_Number__c);
                mapSimList.put('Id',listSimInventory[i].Id);
                listSimDetails.add(mapSimList);
                setICCID.add(listSimInventory[i].VPL_ICCID__c);
            }
            if(!listSimDetails.isEMpty()){
                outputMap.put('SimDetailsList',listSimDetails);
            }
        }
    }
    
    
    public void reserveLockNumber(Map<String,Object> inputMap,Map<String,Object> outputMap,Map<String,Object> optionsMap){
        
        Map<String,Object> mapCurrentSelection = (Map<String,Object>)inputMap.get('CurrentSelection');
        Map<String,Object> mapPreviousSelection = new Map<String,Object>();
        if(inputMap.get('PreviousSelection') != null && inputMap.get('PreviousSelection')!=''){
            mapPreviousSelection = (Map<String,Object>)inputMap.get('PreviousSelection');
        }
        
        
        String currentNumber = (String)mapCurrentSelection.get('MSISDN');
        String previousNumber;
        if(!mapPreviousSelection.isEmpty()){
            previousNumber = (String)mapPreviousSelection.get('MSISDN');
        }
        
        outputMap.put('NumberStatus','');
        List<Map<String,String>> listNumberDetails = new List<Map<String,String>>();
        List<VPL_NumberInventory__c> listNumberLock = new List<VPL_NumberInventory__c>();
        List<VPL_NumberInventory__c> listNumberReserve = new List<VPL_NumberInventory__c>();
        
        String query = 'SELECT Id,VPL_Number__c,VPL_Status__c,VPL_Type__c FROM VPL_NumberInventory__c WHERE ';
        
        if(previousNumber != ''){
            query = query + 'VPL_Number__c =:previousNumber OR ';
        }
        
        if(currentNumber != ''){
            query = query + 'VPL_Number__c =:currentNumber';
        }
        
        List<VPL_NumberInventory__c> listNumberInventory = database.query(query);
        if(!listNumberInventory.isEmpty()){
            for(VPL_NumberInventory__c msisdn: listNumberInventory){
                if(msisdn.VPL_Number__c == currentNumber){
                    if(msisdn.VPL_Status__c != 'Locked'){
                        msisdn.VPL_Status__c = 'Locked';
                        listNumberLock.add(msisdn);
                        outputMap.put('NumberStatus','Available');
                    }else{
                        outputMap.put('NumberStatus','Not available');
                        outputMap.put('NumberType',msisdn.VPL_Type__c);
                    }
                }
                if(msisdn.VPL_Number__c == previousNumber){
                    msisdn.VPL_Status__c = 'Reserved';
                    listNumberReserve.add(msisdn);
                }
            }
            if(!listNumberLock.isEMpty()){
                update listNumberLock;
            }
            if(!listNumberReserve.isEMpty()){
                update listNumberReserve;
            }
        }

    }
   
     
    public void updateNumberList(Map<String,Object> inputMap,Map<String,Object> outputMap,Map<String,Object> optionsMap){
        
        String msisdnIntegrationKey = (String)inputMap.get('MSISDNIntegrationKey');
        String status = (String)inputMap.get('Status');
        Set<String> setPhoneNumbers = new Set<String>();
        List<VPL_NumberInventory__c> listUpdatedNumbers = new List<VPL_NumberInventory__c>();
        if(inputMap.get('AttributeDetails')!=null && inputMap.get('AttributeDetails')!=''){
            List<Object> attributeDetails = (List<Object>)inputMap.get('AttributeDetails');
            if(!attributeDetails.isEmpty()){
                for(Object phoneNumberDetails:attributeDetails){
                    Map<String, Object> mapPhoneNumberDetails = (Map<String, Object>)phoneNumberDetails;
                    if(mapPhoneNumberDetails.get('VALUES')!=null){
                        List<Object> listPhoneNumberDetails = (List<Object>)mapPhoneNumberDetails.get('VALUES');
                        for(Object phoneNumberObj:listPhoneNumberDetails){
                            Map<String, Object> phoneNumber = (Map<String, Object>)phoneNumberObj;
                            if((String)((Map<String, Object>)phoneNumberObj).get('IntegrationKey') == msisdnIntegrationKey){
                                setPhoneNumbers.add((String)((Map<String, Object>)phoneNumberObj).get('Value'));
                            }
                        }
                    }
                }
            }
        }else if(inputMap.get('NumberInventoryList')!=null && inputMap.get('NumberInventoryList')!=''){
            List<Object> numberDetails = (List<Object>)inputMap.get('NumberInventoryList');
            if(!numberDetails.isEmpty()){
                for(Object numberDetailsObj:numberDetails){
                    Map<String, Object> mapPhoneNumberDetails = (Map<String, Object>)numberDetailsObj;
                    if(mapPhoneNumberDetails.get('MSISDN')!=null){
                        setPhoneNumbers.add((String)((Map<String, Object>)mapPhoneNumberDetails).get('MSISDN'));
                    }
                }
            }
        }
        if(!setPhoneNumbers.isEmpty()){
            for(VPL_NumberInventory__c phoneNumber: [SELECT Id, VPL_Status__c from VPL_NumberInventory__c WHERE VPL_Number__c IN:setPhoneNumbers]) {
                phoneNumber.VPL_Status__c = status;
                listUpdatedNumbers.add(phoneNumber);
            }  
            update listUpdatedNumbers;
        }
    }
    
    
    
    
    public void updateSimList(Map<String,Object> inputMap,Map<String,Object> outputMap,Map<String,Object> optionsMap){
        
        String status = (String)inputMap.get('Status');
        Set<String> setSimCards = new Set<String>();
        List<VPL_SimInventory__c> listUpdatedSimCards = new List<VPL_SimInventory__c>();
        if(inputMap.get('AttributeDetails')!=null && inputMap.get('AttributeDetails')!=''){
            String imsiIntegrationKey = (String)inputMap.get('IMSIIntegrationKey');
            List<Object> attributeDetails = (List<Object>)inputMap.get('AttributeDetails');
            if(!attributeDetails.isEmpty() && attributeDetails != null){
                for(Object simCardDetails:attributeDetails){
                    Map<String, Object> mapSimCardDetails = (Map<String, Object>)simCardDetails;
                    if(mapSimCardDetails.get('VALUES')!=null){
                        List<Object> listSimCardDetails = (List<Object>)mapSimCardDetails.get('VALUES');
                        for(Object simCardObj:listSimCardDetails){
                            Map<String, Object> simCard = (Map<String, Object>)simCardObj;
                            if((String)((Map<String, Object>)simCardObj).get('IntegrationKey') == imsiIntegrationKey){
                                setSimCards.add((String)((Map<String, Object>)simCardObj).get('Value'));
                            }
                        }
                    }
                }
            }
            }
            if(inputMap.get('SimCardList')!=null && inputMap.get('SimCardList')!=''){
                List<Object> simCardDetails = (List<Object>)inputMap.get('SimCardList');
                if(!simCardDetails.isEmpty()){
                    for(Object simCardDetailsObj:simCardDetails){
                        Map<String, Object> mapSimCardDetails = (Map<String, Object>)simCardDetailsObj;
                        if(mapSimCardDetails.get('IMSI')!=null){
                            setSimCards.add((String)((Map<String, Object>)mapSimCardDetails).get('IMSI'));
                        }
                    }
                }
            }
            if(!setSimCards.isEmpty()){
                    for(VPL_SimInventory__c sim: [SELECT Id, VPL_Status__c from VPL_SimInventory__c WHERE VPL_IMSI__c IN:setSimCards]) {
                        sim.VPL_Status__c = status;
                        listUpdatedSimCards.add(sim);
                    }  
                    update listUpdatedSimCards;
                }
        }
}