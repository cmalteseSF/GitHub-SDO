public with sharing class COM_commsIDO_AssetCardController{
@AuraEnabled    
    public static List<COM_commsIDO_AssetCardClass> showAssets3 (Id recordId,    String sortField, String sortOrder, String nullHandling) {
        List<COM_commsIDO_AssetCardClass> assetCards = new List<COM_commsIDO_AssetCardClass>();
        List<Asset> allAssets = new List<Asset>();
        List<vlocity_cmt__VlocityAttachment__c> attach = new List<vlocity_cmt__VlocityAttachment__c>();
            
        String record_id = (String)recordId; 
        String q;
        Integer pos;
        String imageURL;
        String sort_clause = ' ORDER BY ' + sortField + ' '  +  sortOrder + ' ' + nullHandling;
        
        //Based on the object id, get either assets assigned to the account or contact
        if (record_id.substring(0,3) == '001'){

            q = 'SELECT Id, Name,  Image__c, PurchaseDate, Status, Quantity, ParentId, COM_Product_Image_URL__c, COM_Contract_MRC__c,  Product2Id    FROM Asset WHERE AccountId = :recordId '+ sort_clause; 
            System.debug(q);
            allAssets = database.query(q);
            
        } if (record_id.substring(0,3)=='003') {

            
            q = 'SELECT Id, Name, Image__c, PurchaseDate, Status, Quantity, ParentId, COM_Product_Image_URL__c, COM_Contract_MRC__c, Product2Id     FROM Asset WHERE ContactId =:recordId ' + sort_clause;
            //System.debug(q);
            allAssets = database.query(q);
        }
        
        for (Asset a : allAssets){
            
            imageURL='';
            List<COM_Product_Flow__c> prodFlows = new List<COM_Product_Flow__c>();
            
            //If the product image is blank, try to get the image from the Vlocity attachments
            //system.debug(a);
            pos = a.Image__c.indexOf('SDO_no_product_image');
            if (a.Image__c == '' || a.Image__c == null || pos > -1)  {
                //system.debug('Searching for product in Vlocity attachment');
               attach= [SELECT vlocity_cmt__UrlLong__c FROM vlocity_cmt__VlocityAttachment__c WHERE vlocity_cmt__ObjectId__c = :a.Product2Id AND vlocity_cmt__IsDefaultImage__c = true];
               //There should only be 1 default image, but loop through just in case
               //system.debug(attach);
                for (vlocity_cmt__VlocityAttachment__c att : attach){
                    imageURL=att.vlocity_cmt__UrlLong__c;
                }
            } else {
                imageURL = a.COM_Product_Image_URL__c;
            }
            
            prodFlows = [Select Name, COM_Flow_API_Name__c
                From COM_Product_Flow__c where COM_Active__c = true and COM_Product__c =: a.Product2Id];
                        
            COM_commsIDO_AssetCardClass assetCard = new COM_commsIDO_AssetCardClass();
            assetCard.name = a.name;
            assetCard.assetID = a.id;
            assetCard.image = imageURL;
            assetCard.purchaseDate = a.PurchaseDate;
            assetCard.status = a.Status;
            assetCard.quantity = a.Quantity;
            assetCard.parentId = a.ParentId;
            assetCard.product2Id = a.Product2Id;
            assetCard.contractMRC = a.COM_Contract_MRC__c;
            assetCard.productImage = imageURL;
            assetCard.productFlows = prodFlows;
            
            assetCards.add(assetCard);
                
        }
        
        system.debug(assetCards);
        return assetCards;
    }
}