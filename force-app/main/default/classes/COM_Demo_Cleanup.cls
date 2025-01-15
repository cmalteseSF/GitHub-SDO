/**
    Original authors of this file:
 	    - Lars Helgeson (lars.helgeson@salesforce.com)
  	    - Joe McMaster (joe.mcmaster@salesforce.com)
  
   
 */

public with sharing class COM_Demo_Cleanup extends COM_Demo_Job 
{

	/** Queues the cleanup job 
     * @return The Job Id
     */    
    @AuraEnabled
    public static Id cleanup() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', 'Beginning Cleanup Operations');
        // Queue the jobs
        COM_Demo_JobChain jobs = new COM_Demo_JobChain();
        jobs.add(new COM_Demo_Cleanup());
        // jobs.add(new COM_Demo_CleanupAccounts());
        return jobs.start();
    }

    /** Executes the cleanup job 
     *      @param context  The Queueable Context
     */
    public override void executeJob(QueueableContext context) 
    {
        try {
            cleanupOrders(); 
			cleanupCases(); 
            cleanupQuotes();
            cleanupOpportunities();
            cleanupContacts();
            cleanupContracts();
			cleanupAssets();			
			cleanupPausedScripts(); 

			cleanupOrchestrationPlans();   
            
            cleanupCustomerInteractions();
            cleanupCustomerInteractionTopics();   
            cleanupSubscription();   
            cleanupRecommendation(); 
            
            COM_DemoSystemEvent.info('Demo Cleanup', '\n\nCleanup Completed.');
        }
        catch (Exception e) {
            // Error occurred
            COM_DemoSystemEvent.error('Demo Cleanup', 'Error Occured during cleanup -> ' + e.getMessage());
            throw e;
        }
	}

    /** Cleans up Orders with Draft and Activated status */
    public static void cleanupOrders()     {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Orders');

		// Get list of draft Orders to delete

        // Is there a reason I'm deleting only certain order types ???
        //  
        List<Order> draftOrders = [ SELECT Id FROM Order WHERE Status = 'Draft' AND COM_Golden_Record__c = false ];
            //and RecordTypeId in (select Id from RecordType 
            //where DeveloperName in ('COM_B2B_Sales_Order_SFI', 'MasterOrder', 'SubOrder', 'GroupCart', 'EnterpriseOrder', 'StandardOrder'))  ];
        delete draftOrders;    

		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + draftOrders.size() +	' Draft Orders');

		// Get list of activated Orders to delete
        Order[] activatedOrders = [	SELECT Id FROM Order WHERE Status = 'Activated' AND COM_Golden_Record__c = false ];
            //and RecordTypeId in (select Id from RecordType 
            //where DeveloperName in ('COM_B2B_Sales_Order_SFI', 'MasterOrder', 'SubOrder', 'GroupCart', 'EnterpriseOrder', 'StandardOrder')) ];
        
		// Set status to Draft on the Activated Orders
        for (Order order : activatedOrders) order.Status = 'Draft';
        update activatedOrders;

		// Delete the Orders
        delete activatedOrders;    
	
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + activatedOrders.size() + ' Activated Orders');
    }

    /**  Cleans up Cases  */
    public static void cleanupCases()     {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Cases'); 
        List<Case> cases = [SELECT Id FROM Case WHERE COM_Golden_Record__c = false AND RecordTypeId IN (Select Id from RecordType 
        WHERE DeveloperName = 'COM_Case_RT')];
        delete cases; 
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + cases.size() + ' Cases');
    }

    /**  Cleans up Quotes  */
    public static void CleanupQuotes()     {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Quotes'); 
        List<Quote> quotes = [SELECT Id FROM Quote WHERE COM_Golden_Record__c = false 
        AND RecordTypeId IN (Select Id from RecordType WHERE DeveloperName in ('EnterpriseQuote', 'COM_B2B_Sales_SFI', 'WorkingCart'))  ];
        delete quotes; 
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + quotes.size() + ' Quotes');
    }

    
      /**  Cleans up Opportunities  */
      public static void CleanupOpportunities() 
      {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
        COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Opportunities'); 
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE COM_Golden_Record__c = false  
        AND RecordTypeId IN (Select Id from RecordType WHERE DeveloperName in ('COM_B2B_Sales_Oppty', 'COMESM_Sales_Opportunity'))  ];
        delete opportunities; 
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + opportunities.size() + ' Opportunities');
      }
  
	/** Cleans up Contacts  */
    public static void cleanupContacts() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Contacts');
        List<Contact> Contacts = [ SELECT Id FROM Contact 
                WHERE COM_Golden_Record__c = false 
                AND AccountId IN (Select Id from Account WHERE Name in ('Harris Photo - HQ', 'Stardust Ventures - HQ', 'Stardust Enterprises'))
        ];
        delete Contacts;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + Contacts.size() + '  Contracts');
	}


	/** Cleans up Contracts  */
    public static void cleanupContracts() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Contracts');
        List<Contract> Contracts = [ SELECT Id FROM Contract 
                WHERE COM_Golden_Record__c = false 
                AND AccountId IN (Select Id from Account 
                WHERE Name in ('Harris Photo - HQ', 'Stardust Ventures - HQ', 'Stardust Enterprises'))
        ];
        delete Contracts;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + Contracts.size() + '  Contracts');
	}
  

	/** Cleans up Contracts with draft status  */
    public static void CleanupDraftContracts() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Contracts');
        List<Contract> draftContracts = [ SELECT Id FROM Contract WHERE Status = 'Draft' 
                AND COM_Golden_Record__c = false 
                AND AccountId IN (Select Id from Account 
                WHERE Name in ('Harris Photo - HQ', 'Stardust Ventures - HQ'))
        ];
        delete draftContracts;    
		COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + draftContracts.size() + ' Draft Contracts');
	}

	/** Cleans up Assets   */
    public static void CleanupAssets() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up non-persistent Assets');

        // Remove all Asset Relationships (we can't cleanup assets that have relationships)
        List<AssetRelationship> assetRelationships = new List<AssetRelationship>();
        for(AssetRelationship rel : [SELECT Id, Asset.COM_Golden_Record__c, RelatedAsset.COM_Golden_Record__c FROM AssetRelationship]) {
            if (!rel.Asset.COM_Golden_Record__c && !rel.RelatedAsset.COM_Golden_Record__c) assetRelationships.add(rel);
        }
        if (!assetRelationships.isEmpty()) {
            delete assetRelationships;
            COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + assetRelationships.size() + ' Asset Relationships');
        }

        List<Asset> assets = [SELECT Id, Product2.Name FROM Asset 
                WHERE COM_Golden_Record__c = false];
        delete assets;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + assets.size() + ' Assets');
    }

    /**  Cleans up paused OmniScripts       */
    public static void cleanupPausedScripts() 
    {
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Paused OmniScripts');
        delete [ SELECT Id FROM vlocity_cmt__OmniScriptInstance__c ];
        delete [ SELECT Id FROM vlocity_cmt__VlocityTrackingEntry__c ];
	}

    	/** Cleans up Orchestration Plans      
         * NOT CURRENTLY USED
        */
        public static void cleanupOrchestrationPlansORIG() 
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

    /*************************************************************************************************************/
	/** Cleans up Orchestration Plans      */
    public static void cleanupOrchestrationPlans() 
    {   
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Orchestration Plans');

        // Build object sets for deletion
        List<vlocity_cmt__OrchestrationPlan__c>      orchPlans = [SELECT Id FROM vlocity_cmt__OrchestrationPlan__c       WHERE vlocity_cmt__OrderId__r.COM_Golden_Record__c = false];
        List<vlocity_cmt__OrchestrationItem__c>      orchItems = [SELECT Id FROM vlocity_cmt__OrchestrationItem__c       WHERE vlocity_cmt__OrchestrationPlanId__c IN :orchPlans];
        List<vlocity_cmt__OrchestrationDependency__c> orchDeps = [SELECT Id FROM vlocity_cmt__OrchestrationDependency__c WHERE vlocity_cmt__OrchestrationItemId__c IN :orchItems];
        List<vlocity_cmt__FulfilmentRequest__c>            frs = [SELECT Id FROM vlocity_cmt__FulfilmentRequest__c       WHERE vlocity_cmt__orchestrationPlanId__c IN :orchPlans];
        List<vlocity_cmt__FulfilmentRequestLine__c>       frls = [SELECT Id FROM vlocity_cmt__FulfilmentRequestLine__c   WHERE vlocity_cmt__FulfilmentRequestID__c IN: frs];
        List<vlocity_cmt__FulfilmentRequestDecompRelationship__c >   frdRels = [SELECT Id FROM vlocity_cmt__FulfilmentRequestDecompRelationship__c    WHERE vlocity_cmt__DestinationFulfilmentRequestId__c IN :frs OR vlocity_cmt__SourceFulfilmentRequestId__c IN :frs];
        List<vlocity_cmt__InventoryItem__c>                         invItems = [SELECT Id FROM vlocity_cmt__InventoryItem__c                          WHERE Id IN (SELECT vlocity_cmt__InventoryItemId__c FROM vlocity_cmt__FulfilmentRequestLine__c WHERE Id IN :frls)];
        List<vlocity_cmt__InventoryItemDecompositionRelationship__c> invRels = [SELECT Id FROM vlocity_cmt__InventoryItemDecompositionRelationship__c WHERE vlocity_cmt__DestinationInventoryItemId__c IN :invItems OR vlocity_cmt__SourceInventoryItemId__c IN :invItems];
        
        delete orchDeps;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + orchDeps.size() + ' Orchestration Dependendcies');

        delete orchItems;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + orchItems.size() + ' Orchestration Items');
                
        delete orchPlans;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + orchPlans.size() + ' Orchestration Plans');

        delete frdRels;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + frdRels.size() + ' Fulfillment Request Decomp Relationships');

        delete frs;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + frs.size() + ' Fulfillment Request Lines');

        delete invRels;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + invRels.size() + ' Inventory Item Decomp Relationships');

        delete frls;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + frls.size() + ' Fulfillment Request Lines');

        delete invItems;
        COM_DemoSystemEvent.info('Demo Cleanup', 'Deleted ' + invItems.size() + ' Inventory Items');






	}


	/** Cleans up vlocity_cmt__CustomerInteraction__c      */
    public static void cleanupCustomerInteractions() 
    {   
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Customer Interactions');
        delete [ SELECT Id FROM vlocity_cmt__CustomerInteraction__c where COM_Golden_Record__c = false ];
	}


	/** Cleans up vlocity_cmt__CustomerInteractionTopic__c      */
    public static void cleanupCustomerInteractionTopics() 
    {   
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Customer Interaction Topic');
        delete [ SELECT Id FROM vlocity_cmt__CustomerInteractionTopic__c where COM_Golden_Record__c = false ];
	}

	/** Cleans up vlocity_cmt__Subscription__c      */
    public static void cleanupSubscription() 
    {   
        COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
		COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Subscription');
        delete [ SELECT Id FROM vlocity_cmt__Subscription__c where COM_Golden_Record__c = false ];
	}

    	/** Cleans up Recommendation      */
        public static void cleanupRecommendation() 
        {   
            COM_DemoSystemEvent.info('Demo Cleanup', '#################################  ########################');
            COM_DemoSystemEvent.info('Demo Cleanup', 'Cleaning up Recommendation');
            delete [ SELECT Id FROM Recommendation where COM_Golden_Record__c = false ];
        }
    
}