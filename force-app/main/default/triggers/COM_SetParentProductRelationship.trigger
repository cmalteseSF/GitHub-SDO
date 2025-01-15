trigger COM_SetParentProductRelationship on QuoteLineItem (before insert, before update) {

    for (QuoteLineItem QLI:  Trigger.new)
    {
            QLI.COM_ParentQuoteProduct__c = QLI.vlocity_cmt__ParentItemId__c;
        
    }
}