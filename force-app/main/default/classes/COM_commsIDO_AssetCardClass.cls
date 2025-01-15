public class COM_commsIDO_AssetCardClass {
@AuraEnabled
   public string name { get; set;}
        @AuraEnabled
   public Id assetID { get; set;}
   @AuraEnabled
   public string image { get; set; }
    @AuraEnabled
   public date purchaseDate { get;set; }
    @AuraEnabled
   public string status { get;set; }
    @AuraEnabled
   public double quantity { get;set; }
    @AuraEnabled
   public Id parentId { get;set; }
    @AuraEnabled
   public Id product2Id { get;set; }
    @AuraEnabled
   public Decimal contractMRC{ get;set; }
    @AuraEnabled
   public String productImage { get;set; }
    @AuraEnabled
   public List<COM_Product_Flow__c> productFlows { get; set;}
}