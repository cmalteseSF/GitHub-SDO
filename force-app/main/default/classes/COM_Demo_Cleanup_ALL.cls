/**
    Original authors of this file:
 	    - Lars Helgeson (lars.helgeson@salesforce.com)
  	    - Joe McMaster (joe.mcmaster@salesforce.com)
  
   
 */

public with sharing class COM_Demo_Cleanup_ALL extends COM_Demo_Job 
{

	/** Queues the cleanup job 
     * @return The Job Id
     */    
    @AuraEnabled
    public static Id cleanup_all() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup All', 'Beginning Cleanup Operations');
        // Queue the jobs
        COM_Demo_JobChain jobs = new COM_Demo_JobChain();
        jobs.add(new COM_Demo_Cleanup_ALL());
        // jobs.add(new COM_Demo_CleanupAccounts());
        return jobs.start();
    }

    /** Executes the cleanup job 
     *      @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) 
    {
        try {

            // Working.
            cleanupOrders_all(); 
            cleanupQuotes_all();
            cleanupOpportunities_all();
			cleanupDraftContracts_all();
            cleanupCases_all();
			cleanupAssets_all();
		    cleanupPausedScripts_all(); 
		    cleanupOrchestrationPlans_all();


            
        }
        catch (Exception e) {
            // Error occurred
            COM_DemoSystemEvent.error('Demo Cleanup', 'Error Occured during cleanup -> ' + e.getMessage());
            throw e;
        }
	}

/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
   /**  Cleans up OrderItemAdjustmentSummary  */
   public static void cleanupOrderItemAdjustmentSummary()    {
       COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
       COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up all Order Item Summaries'); 
       List<OrderItemAdjustmentLineSummary> itemsummaries = [SELECT Id FROM OrderItemAdjustmentLineSummary];
       delete itemsummaries; 
       COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + itemsummaries.size() + ' Order Item Adjustment Summaries');
   }


/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
   /**  Cleans up OrderItemSummary  */
   public static void cleanupOrderItemSummary()    {
       COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
       COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up all Order Item Summaries'); 
       List<OrderItemSummary> itemsummaries = [SELECT Id FROM OrderItemSummary];
       delete itemsummaries; 
       COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + itemsummaries.size() + ' Order Item Summaries');
   }
    
/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
   /**  Cleans up OrderItemTaxLineItemSummary  */
   public static void cleanupOrderItemTaxLineItemSummary()    {
       COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
       COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up all Order Item Tax Line Summaries'); 
       List<OrderItemTaxLineItemSummary> taxsummaries = [SELECT Id FROM OrderItemTaxLineItemSummary];
       delete taxsummaries; 
       COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + taxsummaries.size() + ' Order Item Tax Line Summaries');
   }

/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
   /**  Cleans up OrderDeliveryGroupSummary  */
   public static void cleanupOrderDeliveryGroupSummary_all()    {
       COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
       COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up all Order Delivery Groups'); 
       List<OrderDeliveryGroupSummary> summaries = [SELECT Id FROM OrderDeliveryGroupSummary];
       delete summaries; 
       COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + summaries.size() + ' Order Delivery Group Summaries');
   }

/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
    /** Cleans up all Payment Transactions*/
    /** Required for purging some of the SDO orders. */
    public static void cleanupPaymentTransactions()    {
        COM_DemoSystemEvent.info('Demo Cleanup ALL', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup ALL', 'Cleaning up all Payment Transactions');
        List<blng__PaymentTransaction__c> payments = [ SELECT Id FROM blng__PaymentTransaction__c  ];
        delete payments;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + payments.size() +	' Payment Transactions');
    }

/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
    /** Cleans up all Invoices*/
    /** Required for purging some of the SDO orders. */
    public static void cleanupInvoices()    {
        COM_DemoSystemEvent.info('Demo Cleanup ALL', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup ALL', 'Cleaning up all Invoices');
        List<blng__Invoice__c> invoices = [ SELECT Id FROM blng__Invoice__c  ];
        delete invoices;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + invoices.size() +	' Invoices');
    }

/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
  /** Cleans up all Usage Summaries*/
  /** Required for purging some of the SDO orders. */
  public static void cleanupUsageSummaries()  {
      COM_DemoSystemEvent.info('Demo Cleanup ALL', '#################################  ########################');
      COM_DemoSystemEvent.info('Demo Cleanup ALL', 'Cleaning up all Usage Summaries');
      List<blng__UsageSummary__c> summaries = [ SELECT Id FROM blng__UsageSummary__c  ];
      delete summaries;    
      COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + summaries.size() +	' Usage Summaries');
  }

/*************   NOT CURRENTLY USED.  Needed for purging ALL orders in the org, not just COMMS order  ********/
    /** Update order items 'Contracted' field. */
    /** Required for purging some of the SDO orders. */
    public static void updateOrderItems()  {
        COM_DemoSystemEvent.info('Demo Cleanup ALL', '#################################  ########################');
        COM_DemoSystemEvent.info('Demo Cleanup ALL', 'Cleaning up Order Items');

        // Clear the Contracted field (we can't cleanup order items where its set to true )
        List<OrderItem> itemList = new List<OrderItem>();
        for(OrderItem item : [SELECT Id FROM OrderItem where SBQQ__Contracted__c = true]) {
           itemList.add(item);
        }

        // Set Contracted to false. 
        for (OrderItem item : itemList) item.SBQQ__Contracted__c = false;
        update itemList;    
        COM_DemoSystemEvent.info('Demo Cleanup', 'Updated ' + itemList.size() +	' Order Items');
  }

    /** Cleans up Orders with Draft and Activated status */
    public static void cleanupOrders_all()     {
        COM_DemoSystemEvent.info('Demo Cleanup ALL', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup ALL', 'Cleaning up all Orders');

        // List of orders that have the Contracted field set
        /* Only needed for some of the SDO orders.
            List<Order> contractedOrders = [ SELECT Id FROM Order WHERE SBQQ__Contracted__c  = true ];
            for (Order order : contractedOrders) order.SBQQ__Contracted__c = false;
            update contractedOrders;
		    COM_DemoSystemEvent.info('Demo Cleanup', 'Reset ' + contractedOrders.size() +	' Contracted flags on Orders');
        */

		// Get list of draft Orders to delete
        List<Order> draftOrders = [ SELECT Id FROM Order WHERE Status = 'Draft' and RecordTypeId in (select Id from RecordType 
        where DeveloperName in ('COM_B2B_Sales_Order_SFI', 'MasterOrder', 'SubOrder')) ];
        delete draftOrders;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + draftOrders.size() +	' Draft Orders');

        
		// Get list of activated Orders to delete
        Order[] activatedOrders = [	SELECT Id FROM Order WHERE Status = 'Activated' and RecordTypeId in (select Id from RecordType 
        where DeveloperName in ('COM_B2B_Sales_Order_SFI', 'MasterOrder', 'SubOrder'))];
        
        
		// Set status to Draft on the Activated Orders
        for (Order order : activatedOrders) order.Status = 'Draft';
        update activatedOrders;

		// Delete the Orders
        delete activatedOrders;    
	
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + activatedOrders.size() + ' Activated Orders');
    }

    /**  Cleans up Cases  */
    /**  Not needed.  Comms does not generate any cases. */
    public static void cleanupCases_all()      {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Cases'); 
        List<Case> cases = [SELECT Id FROM Case WHERE RecordTypeId IN (Select Id from RecordType 
        WHERE DeveloperName = 'COM_Case_RT') ];
        delete cases; 
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + cases.size() + ' Cases');
    }

    /**  Cleans up Quotes  */
    public static void CleanupQuotes_all()     {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Quotes'); 
        List<Quote> quotes = [SELECT Id FROM Quote WHERE RecordTypeId 
            IN (Select Id from RecordType WHERE DeveloperName in ('EnterpriseQuote', 'COM_B2B_Sales_SFI')) ];
        delete quotes; 
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + quotes.size() + ' Quotes');
    }

    
      /**  Cleans up Opportunities  */
      public static void CleanupOpportunities_all()       {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
        COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Opportunities'); 
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity 
                                           WHERE AccountId IN 
                                           (Select Id from Account WHERE Name in ('Stardust Enterprises', 'Stardust Ventures - HQ')) ];
        delete opportunities; 
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + opportunities.size() + ' Opportunities');
      }
  
  

	/** Cleans up Contracts with draft status  */
    public static void CleanupDraftContracts_all()     {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Draft Contracts');
        List<Contract> draftContracts = [ SELECT Id FROM Contract WHERE Status = 'Draft' AND AccountId IN (Select Id from Account 
        WHERE Name in ('Harris Photo - HQ', 'Stardust Ventures - HQ')) ];
        delete draftContracts;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + draftContracts.size() + ' Draft Contracts');
	}

	/** Cleans up Assets   */
    public static void CleanupAssets_all() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up all Assets');

        /* Remove all Asset Relationships (we can't cleanup assets that have relationships
        List<AssetRelationship> assetRelationships = new List<AssetRelationship>();
        for(AssetRelationship rel : [SELECT Id, Asset.COM_Golden_Record__c, RelatedAsset.COM_Golden_Record__c FROM AssetRelationship]) {
             assetRelationships.add(rel);
        }
        if (!assetRelationships.isEmpty()) {
            delete assetRelationships;
            COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + assetRelationships.size() + ' Asset Relationships');
        }
        */

        List<Asset> assets = [SELECT Id FROM Asset WHERE RecordTypeId = null];
        delete assets;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + assets.size() + ' Assets');
    }

    /**  Cleans up paused OmniScripts       */
    public static void cleanupPausedScripts_all() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Paused OmniScripts');
        delete [ SELECT Id FROM vlocity_cmt__OmniScriptInstance__c ];
        delete [ SELECT Id FROM vlocity_cmt__VlocityTrackingEntry__c ];
	}

	/** Cleans up Orchestration Plans      */
    public static void cleanupOrchestrationPlans_all() 
    {   
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Orchestration Plans');
        delete [ SELECT Id FROM vlocity_cmt__OrchestrationDependency__c ];
        delete [ SELECT id FROM vlocity_cmt__OrchestrationItem__c ];
        delete [ SELECT id FROM vlocity_cmt__OrchestrationPlan__c ];
        delete [ SELECT id FROM vlocity_cmt__FulfilmentRequestDecompRelationship__c ];
        delete [ SELECT id FROM vlocity_cmt__FulfilmentRequest__c ];
        delete [ SELECT id FROM vlocity_cmt__InventoryItemDecompositionRelationship__c ];
        delete [ SELECT id FROM vlocity_cmt__FulfilmentRequestLine__c ];
        delete [ SELECT id FROM vlocity_cmt__InventoryItem__c ];
	}
}