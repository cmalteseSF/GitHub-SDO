public with sharing class CreateUpdateContractController2 {
     private string contractId {get; set;}
     private String objId {get;set;}
     public CreateUpdateContractController2(ApexPages.StandardController stdController){
       //get current object Id
        objId = ApexPages.currentPage().getParameters().get('Id');     
     }
      
     public PageReference doCreateContract(){ 
       //create contract for this Id
       contractId = vlocity_cmt.ContractServiceResource.createContractWithoutTemplate(objId); 
    PageReference pgRef = new PageReference('/' + contractId );     
    return pgRef;
     
  }
   
   public PageReference doUpdateContracts(){ 
       //create contract for this Id
       String message = vlocity_cmt.ContractServiceResource.updateContract(objId); 
       PageReference pgRef = new PageReference('/' + objId); 
    return pgRef;
     
  }
}