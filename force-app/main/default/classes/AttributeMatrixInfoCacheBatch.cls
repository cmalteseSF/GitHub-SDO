global class AttributeMatrixInfoCacheBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    String matrixRowQuery;
    List<String> errorMessageList = new List<String>();
    String cachePartition;
    Decimal stepSequence;
    String pricingPlanCode;
    vlocity_cmt__PricingPlan__c pricingPlan;
    Map<String, Object> stepParameters;
    Set<String> rangeFields;
    Set<String> rangeAttrs;
    Map<String, Object> rangeAttrMapping = new Map<String, Object>();
    Map<String, Object> rangeFieldMapping = new Map<String, Object>();
    Map<String, Object> productCodeMapping = new Map<String, Object>();
    Map<String, Object> cacheMap = new Map<String, Object>();
    Set<String> productCodeSet = new Set<String>();
    Id matrixVersionId;
    String matrixName;
    Boolean decisionMatrix = false;
    Boolean includeAttrInfoInRangeKeys = false;
    Boolean overlappingRanges = false; 
    Set<String> attrRowInfoKeySet = new Set<String>();

    global AttributeMatrixInfoCacheBatch(Map<String, Object> input) {
        if (!Test.isRunningTest()) {
            cachePartition = PricingPlanHelper.getAttrMatrixInfoCachePartition();
        }
        pricingPlanCode = (String)input.get('PricingPlanCode');
        String sequenceNums = (String)input.get('PricingPlanStepSequenceNumbers');

        if (!Test.isRunningTest() && String.isBlank(cachePartition))
        {
            throw new AttributeMatrixInfoCacheBatchException('AttrMatrixInfoCachePartition configuration setup value is not specified.');
        }
        if (String.isNotBlank(pricingPlanCode))
        {
            List<Decimal> seqNumList = new List<Decimal>();
            if (String.isNotBlank(sequenceNums)) {
                for (String num : sequenceNums.split(',')) {
                    if (String.isNotBlank(num)) {                        
                        seqNumList.add(Decimal.valueOf(num.trim()));
                    }
                }
            }
            List<vlocity_cmt__PricingPlan__c> defaultPricingPlanList = [SELECT Id, Name, vlocity_cmt__Code__c, 
                (SELECT Id, Name, vlocity_cmt__Sequence__c, vlocity_cmt__ImplementationName__c, vlocity_cmt__MethodName__c, vlocity_cmt__IsActive__c, vlocity_cmt__Parameters__c 
                        FROM vlocity_cmt__PricingPlanSteps__r WHERE vlocity_cmt__Sequence__c = :seqNumList) FROM vlocity_cmt__PricingPlan__c WHERE vlocity_cmt__Code__c = :pricingPlanCode];
            if (defaultPricingPlanList != null && !defaultPricingPlanList.isEmpty())
            {
                pricingPlan = defaultPricingPlanList[0];
            }
        }

        if (pricingPlan != null && pricingPlan.vlocity_cmt__PricingPlanSteps__r != null && !pricingPlan.vlocity_cmt__PricingPlanSteps__r.isEmpty())
        {
            if (String.isNotBlank(pricingPlan.vlocity_cmt__PricingPlanSteps__r[0].vlocity_cmt__Parameters__c))
            {
                stepParameters = (Map<String, Object>)JSON.deserializeUntyped(pricingPlan.vlocity_cmt__PricingPlanSteps__r[0].vlocity_cmt__Parameters__c);
            }
        }
        if (stepParameters != null)
        {
            System.debug('stepParameters: ' + JSON.serialize(stepParameters));
            if(input.containsKey('DecisionMatrix'))
            {
                decisionMatrix = Boolean.valueOf((String)stepParameters.get('DecisionMatrix'));
            }  
            Map<String, Object> matrixInfoOutput = new Map<String, Object>();
            PricingPlanHelper.getMatrixInfo(stepParameters, matrixInfoOutput);
            rangeFields = (Set<String>)matrixInfoOutput.get('RangeFields');
            rangeAttrs = (Set<String>)matrixInfoOutput.get('RangeAttributes');
            matrixRowQuery = (String)matrixInfoOutput.get('MatrixRowQuery');
            matrixVersionId = (Id)matrixInfoOutput.get('MatrixVersionId');
            matrixName = (String)matrixInfoOutput.get('MatrixName');
            cacheMap.put('MatrixName', matrixName);
            cacheMap.put('MatrixVersionId', matrixVersionId);
            cacheMap.put('MatrixVersionNumber', matrixInfoOutput.get('MatrixVersionNumber'));
            cacheMap.put('MatrixPriority', matrixInfoOutput.get('MatrixPriority'));
            cacheMap.put('RangeFields', rangeFields);
            cacheMap.put('RangeAttributes', rangeAttrs);
            System.debug('matrixInfoOutput: ' + JSON.serialize(matrixInfoOutput));
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(matrixRowQuery);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        try
        {
            for (SObject sObj : scope)
            {
                PricingPlanHelper.decisionMatrix = decisionMatrix;
                PricingPlanHelper.processMatrixRow(sObj, rangeAttrs, rangeAttrMapping, rangeFields, rangeFieldMapping, 
                                                   productCodeMapping, productCodeSet, includeAttrInfoInRangeKeys, overlappingRanges, attrRowInfoKeySet);
            }
        }
        catch(Exception e)
        {
            errorMessageList.add('Exception caught: ' + e.getMessage());
            System.debug(e);
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        cacheMap.put('ProductCodeSet', productCodeSet);
        cacheMap.put('AttrRowInfoKeySet', attrRowInfoKeySet);
        cacheMap.put('CacheTime', DateTime.now());
        List<vlocity_cmt__CachedApiResponse__c> insertList = new List<vlocity_cmt__CachedApiResponse__c>();
        Cache.OrgPartition orgPart = null;
        if (!Test.isRunningTest()) {
            orgPart = Cache.Org.getPartition(cachePartition);
        }        
        String cacheKey = 'AttrMatrixInfo' + String.valueOf(matrixVersionId);
        if (orgPart != null) {
            orgPart.put(cacheKey, cacheMap);
        }

        Map<String, String> cacheKeys = new Map<String, String>();
        cacheKeys.put(cacheKey, cacheKey);
        for (String prodCode:productCodeSet) {
            cacheKeys.put(String.valueOf(matrixVersionId) + prodCode, PricingPlanHelper.generateCacheKey(String.valueOf(matrixVersionId) + prodCode));
        }

        delete [SELECT Id FROM vlocity_cmt__CachedApiResponse__c where vlocity_cmt__CacheKey__c = :cacheKeys.values()];

        vlocity_cmt__CachedApiResponse__c apiResp = new vlocity_cmt__CachedApiResponse__c();
        apiResp.vlocity_cmt__Code__c = matrixName;
        apiResp.vlocity_cmt__Type__c = 'compiledCalculationMatrix';                  
        apiResp.vlocity_cmt__CacheKey__c = cacheKey;
        apiResp.vlocity_cmt__ApiResponse__c = JSON.serialize(cacheMap);
        apiResp.vlocity_cmt__OverflowSequence__c = 1;
        insertList.add(apiResp);

        for(String prodCode:productCodeSet){
            cacheKey = cacheKeys.get(String.valueOf(matrixVersionId) + prodCode);
            Map<String,Object> subCacheMap = new Map<String,Object>();
            subCacheMap.put('RangeAttrMapping', rangeAttrMapping.get(prodCode));
            subCacheMap.put('RangeFieldMapping', rangeFieldMapping.get(prodCode));
            subCacheMap.put('ProductCodeMapping', productCodeMapping.get(prodCode));
            subCacheMap.put('ProductCode', prodCode);
            subCacheMap.put('CacheTime', DateTime.now());            
            if (orgPart != null) {
                orgPart.put(cacheKey, subCacheMap);
            }                        
            apiResp = new vlocity_cmt__CachedApiResponse__c();
            apiResp.vlocity_cmt__Code__c = matrixName;
            apiResp.vlocity_cmt__Type__c = 'compiledCalculationMatrix';
            apiResp.vlocity_cmt__CacheKey__c = cacheKey;
            apiResp.vlocity_cmt__ApiResponse__c = JSON.serialize(subCacheMap);
            apiResp.vlocity_cmt__OverflowSequence__c = 1;
            insertList.add(apiResp);
        }
        if (!insertList.isEmpty()) {
            insert insertList;
        }        
    }

    global class AttributeMatrixInfoCacheBatchException extends Exception{}
}