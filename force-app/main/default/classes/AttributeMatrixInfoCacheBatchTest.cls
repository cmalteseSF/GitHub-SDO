@isTest
private class AttributeMatrixInfoCacheBatchTest {
    
    private static void setupCalcMatrixData()
    {
        insert new vlocity_cmt__TriggerSetup__c(Name = 'AllTriggers', vlocity_cmt__IsTriggerOn__c = true);
        SObject parentSobj = new vlocity_cmt__CalculationMatrix__c(Name = 'AttributeMatrixInfoCacheBatchTestMatrix');
        insert parentSobj;

        SObject versionSobj = new vlocity_cmt__CalculationMatrixVersion__c(Name = 'AttributeMatrixInfoCacheBatchTestMatrix Version', vlocity_cmt__VersionNumber__c = 5,
                vlocity_cmt__IsEnabled__c = false, vlocity_cmt__CalculationMatrixId__c = parentSobj.Id,
                vlocity_cmt__StartDateTime__c = DateTime.now().addDays(-10), vlocity_cmt__EndDateTime__c = DateTime.now().addDays(10),vlocity_cmt__Priority__c = 5);
        insert versionSobj;

        //Populating Headers
        List<SObject> sObjList = new List<SObject>();

        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"Source Product Name\",\"label\":null,\"headerType\":\"Input\",\"displayOrder\":1,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"Source Product Code\",\"label\":null,\"headerType\":\"Input\",\"displayOrder\":2,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"Characteristic Name\",\"label\":null,\"headerType\":\"Input\",\"displayOrder\":3,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"Characteristic Value\",\"label\":null,\"headerType\":\"Input\",\"displayOrder\":4,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"Quantity\",\"label\":null,\"headerType\":\"Input\",\"displayOrder\":5,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"TargetProductName\",\"label\":null,\"headerType\":\"Output\",\"displayOrder\":6,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"MRC\",\"label\":null,\"headerType\":\"Output\",\"displayOrder\":7,\"dataType\":\"Text\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id, Name = 'Header',
                vlocity_cmt__InputData__c ='{\"listValues\":null,\"name":\"NRC\",\"label\":null,\"headerType\":\"Output\",\"displayOrder\":8,\"dataType\":\"Text\"}'
        ));

        insert sObjList;
        sObjList.clear();

        //Populating Row Data
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id,
                vlocity_cmt__InputData__c = '{\"Quantity\":\"1-10\",\"Characteristic Value\":\"Xfinity\",\"Characteristic Name\":"Provider\",\"Source Product Code\":\"VLO-PHN-0005\",\"Source Product Name\":\"Consumer Landline\"}',
                vlocity_cmt__OutputData__c = '{\"NRC\":\"105\",\"MRC\":\"50\",\"TargetProductName\":\"Path3\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id,
                vlocity_cmt__InputData__c = '{\"Quantity\":\"11-20\",\"Characteristic Value\":\"Xfinity\",\"Characteristic Name\":"Provider\",\"Source Product Code\":\"VLO-PHN-0005\",\"Source Product Name\":\"Consumer Landline\"}',
                vlocity_cmt__OutputData__c = '{\"NRC\":\"115\",\"MRC\":\"100\",\"TargetProductName\":\"Path3\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id,
                vlocity_cmt__InputData__c = '{\"Quantity\":\"1-10\",\"Characteristic Value\":\"Verizon\",\"Characteristic Name\":"Provider\",\"Source Product Code\":\"VLO-PHN-0005\",\"Source Product Name\":\"ConsumerLandline\"}',
                vlocity_cmt__OutputData__c = '{\"NRC\":\"125\",\"MRC\":\"300\",\"TargetProductName\":\"Path3\"}'
        ));
        sObjList.add(new vlocity_cmt__CalculationMatrixRow__c(vlocity_cmt__CalculationMatrixVersionId__c = versionSobj.Id,
                vlocity_cmt__InputData__c = '{\"Quantity\":\"11-20\",\"Characteristic Value\":\"Verizon\",\"Characteristic Name\":"Provider\",\"Source Product Code\":\"VLO-PHN-0005\",\"Source Product Name\":\"Consumer Landline\"}',
                vlocity_cmt__OutputData__c = '{\"NRC\":\"135\",\"MRC\":\"600\",\"TargetProductName\":\"Path3\"}'
        ));

        insert sObjList;
        sObjList.clear();

        // Enable the matrix version after adding the matrix rows
        update new vlocity_cmt__CalculationMatrixVersion__c(Id = versionSobj.Id, vlocity_cmt__IsEnabled__c = true);

        //Create Calculation Procedure
        vlocity_cmt__CalculationProcedure__c calcProcedure = new vlocity_cmt__CalculationProcedure__c(Name='AttributePricingDemoProcedureTest');
        insert calcProcedure;

        // Create Procedure Version
        vlocity_cmt__CalculationProcedureVersion__c procVersion = new vlocity_cmt__CalculationProcedureVersion__c(Name='Test Pricing Procedure', vlocity_cmt__VersionNumber__c=5, vlocity_cmt__IsEnabled__c=false,
                vlocity_cmt__CalculationProcedureId__c=calcProcedure.Id, vlocity_cmt__StartDateTime__c = DateTime.now().addDays(-5), vlocity_cmt__EndDateTime__c = DateTime.now().addDays(5), vlocity_cmt__Priority__c=5);
        insert procVersion;

        // Create the Pricing Plan
        vlocity_cmt__PricingPlan__c plan = new vlocity_cmt__PricingPlan__c(Name = 'Default Pricing Plan', vlocity_cmt__Code__c = 'DEFAULT_PRICING_PLAN', vlocity_cmt__IsActive__c = true);
        insert plan;

        // Create the pricing plan ABP step
        vlocity_cmt__PricingPlanStep__c planStep1 = new vlocity_cmt__PricingPlanStep__c(Name = 'Test Matrix', vlocity_cmt__ImplementationName__c = 'CustomPricingPlanStepImpl', 
        vlocity_cmt__IsActive__c = true, vlocity_cmt__MethodName__c = 'GetMatrixPrice', vlocity_cmt__Sequence__c = 1.0, vlocity_cmt__PricingPlanId__c = plan.Id,
        vlocity_cmt__Parameters__c = '{"ProcedureName":"Test Pricing Procedure","MatrixName":"AttributeMatrixInfoCacheBatchTestMatrix","DecisionMatrix":"False"}');
        insert planStep1;

        // Create Pricing Variables
        vlocity_cmt__PricingVariable__c oneTimeStdPriceVar = new vlocity_cmt__PricingVariable__c(Name = 'One Time Std Price', vlocity_cmt__Code__c = 'OT_STD_PRC',vlocity_cmt__Aggregation__c = 'Unit',
        vlocity_cmt__ChargeType__c='One-time',vlocity_cmt__IsActive__c = true,vlocity_cmt__Scope__c = 'Line',vlocity_cmt__SubType__c = 'Standard',vlocity_cmt__Type__c = 'Price',
        vlocity_cmt__ValueType__c='Pricing Element',vlocity_cmt__CurrencyType__c='Currency');
        sObjList.add(oneTimeStdPriceVar);

        vlocity_cmt__PricingVariable__c mrcPriceVar = new vlocity_cmt__PricingVariable__c(Name = 'Recurring Monthly Std Price', vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC',vlocity_cmt__Aggregation__c = 'Unit',
        vlocity_cmt__ChargeType__c='Recurring', vlocity_cmt__RecurringFrequency__c ='Monthly',vlocity_cmt__IsActive__c = true,vlocity_cmt__Scope__c = 'Line',vlocity_cmt__SubType__c = 'Standard',vlocity_cmt__Type__c = 'Price',
        vlocity_cmt__ValueType__c='Pricing Element',vlocity_cmt__CurrencyType__c='Currency');        
        sObjList.add(mrcPriceVar);

        insert sObjList;
        sObjList.clear();

        //Creating PricingVariableBinding
        vlocity_cmt__PricingVariableBinding__c pvb1 = new vlocity_cmt__PricingVariableBinding__c(Name='One Time Std Price - OrderItem',vlocity_cmt__DestinationSObjectType__c='OrderItem',
        vlocity_cmt__DestinationFieldApiName__c = 'vlocity_cmt__OneTimeCharge__c', vlocity_cmt__PricingVariableId__c = oneTimeStdPriceVar.Id);
        sObjList.add(pvb1);
        vlocity_cmt__PricingVariableBinding__c pvb2 = new vlocity_cmt__PricingVariableBinding__c(Name='Recurring Monthly Std Price - OrderItem',vlocity_cmt__DestinationSObjectType__c='OrderItem',
        vlocity_cmt__DestinationFieldApiName__c = 'vlocity_cmt__RecurringCharge__c', vlocity_cmt__PricingVariableId__c = mrcPriceVar.Id);
        sObjList.add(pvb2);

        insert sObjList;
        sObjList.clear();
    }

    private static void setupLookupTableData()
    {
        SObject parentSobj = (SObject)Type.forName('CalculationMatrix').newInstance();
        parentSobj.put('Name', 'AttributePricingMatrixTest');
        parentSobj.put('Type', 'Standard');
        insert parentSobj;

        //Populating Headers
        List<SObject> sObjList = new List<SObject>();
        SObject headerCharName =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerCharName.put('CalculationMatrixId', parentSobj.Id);
        headerCharName.put('Name', 'CharacteristicName');
        headerCharName.put('ApiName', 'CharacteristicName');
        headerCharName.put('ColumnType', 'Input');
        headerCharName.put('DataType', 'Text');
        headerCharName.put('DisplaySequence', 1);
        sObjList.add(headerCharName);

        SObject headerSourceProdCode =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerSourceProdCode.put('CalculationMatrixId', parentSobj.Id);
        headerSourceProdCode.put('Name', 'SourceProductCode');
        headerSourceProdCode.put('ApiName', 'SourceProductCode');
        headerSourceProdCode.put('ColumnType', 'Input');
        headerSourceProdCode.put('DataType', 'Text');
        headerSourceProdCode.put('DisplaySequence', 2);
        sObjList.add(headerSourceProdCode);

        SObject headerSourceProdName =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerSourceProdName.put('CalculationMatrixId', parentSobj.Id);
        headerSourceProdName.put('Name', 'SourceProductName');
        headerSourceProdName.put('ApiName', 'SourceProductName');
        headerSourceProdName.put('ColumnType', 'Input');
        headerSourceProdName.put('DataType', 'Text');
        headerSourceProdName.put('DisplaySequence', 3);
        sObjList.add(headerSourceProdName);

        SObject headerCharValue =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerCharValue.put('CalculationMatrixId', parentSobj.Id);
        headerCharValue.put('Name', 'CharacteristicValue');
        headerCharValue.put('ApiName', 'CharacteristicValue');
        headerCharValue.put('ColumnType', 'Input');
        headerCharValue.put('DataType', 'Text');
        headerCharValue.put('DisplaySequence', 4);
        sObjList.add(headerCharValue);

        SObject headerQuantity =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerQuantity.put('CalculationMatrixId', parentSobj.Id);
        headerQuantity.put('Name', 'Quantity');
        headerQuantity.put('ApiName', 'Quantity');
        headerQuantity.put('ColumnType', 'Input');
        headerQuantity.put('DataType', 'Text');
        headerQuantity.put('DisplaySequence', 5);
        sObjList.add(headerQuantity);

        SObject headerTargetProductName =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerTargetProductName.put('CalculationMatrixId', parentSobj.Id);
        headerTargetProductName.put('Name', 'TargetProductName');
        headerTargetProductName.put('ApiName', 'TargetProductName');
        headerTargetProductName.put('ColumnType', 'Output');
        headerTargetProductName.put('DataType', 'Text');
        headerTargetProductName.put('DisplaySequence', 6);
        sObjList.add(headerTargetProductName);

        SObject headerMRC =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerMRC.put('CalculationMatrixId', parentSobj.Id);
        headerMRC.put('Name', 'MRC');
        headerMRC.put('ApiName', 'MRC');
        headerMRC.put('ColumnType', 'Output');
        headerMRC.put('DataType', 'Text');
        headerMRC.put('DisplaySequence', 7);
        sObjList.add(headerMRC);

        SObject headerNRC =  (SObject)Type.forName('CalculationMatrixColumn').newInstance();
        headerNRC.put('CalculationMatrixId', parentSobj.Id);
        headerNRC.put('Name', 'NRC');
        headerNRC.put('ApiName', 'NRC');
        headerNRC.put('ColumnType', 'Output');
        headerNRC.put('DataType', 'Text');
        headerNRC.put('DisplaySequence', 8);
        sObjList.add(headerNRC);
        insert sObjList;
        sObjList.clear();

        SObject versionSobj = (SObject)Type.forName('CalculationMatrixVersion').newInstance();
        versionSobj.put('Name', 'AttributePricingMatrixTest Version');
        versionSobj.put('VersionNumber', 5);
        versionSobj.put('IsEnabled', false);
        versionSobj.put('CalculationMatrixId', parentSobj.Id);
        versionSobj.put('StartDateTime', DateTime.now().addDays(-10));
        versionSobj.put('EndDateTime', DateTime.now().addDays(10));
        versionSobj.put('Rank', 5);
        insert versionSobj;

        //Populating Row Data

        SObject decisionRow5 =  (SObject)Type.forName('CalculationMatrixRow').newInstance();
        decisionRow5.put('CalculationMatrixVersionId', versionSobj.Id);
        decisionRow5.put('InputData', '{\"Quantity\":\"1-10\",\"CharacteristicValue\":\"Xfinity\",\"CharacteristicName\":"Provider\",\"SourceProductCode\":\"VLO-PHN-0005\",\"SourceProductName\":\"Consumer Landline\"}');
        decisionRow5.put('OutputData', '{\"NRC\":\"105\",\"MRC\":\"50\",\"TargetProductName\":\"Path3\"}');
        sObjList.add(decisionRow5);

        SObject decisionRow6 =  (SObject)Type.forName('CalculationMatrixRow').newInstance();
        decisionRow6.put('CalculationMatrixVersionId', versionSobj.Id);
        decisionRow6.put('InputData', '{\"Quantity\":\"11-20\",\"CharacteristicValue\":\"Xfinity\",\"CharacteristicName\":"Provider\",\"SourceProductCode\":\"VLO-PHN-0005\",\"SourceProductName\":\"Consumer Landline\"}');
        decisionRow6.put('OutputData', '{\"NRC\":\"115\",\"MRC\":\"100\",\"TargetProductName\":\"Path3\"}');
        sObjList.add(decisionRow6);

        SObject decisionRow7 =  (SObject)Type.forName('CalculationMatrixRow').newInstance();
        decisionRow7.put('CalculationMatrixVersionId', versionSobj.Id);
        decisionRow7.put('InputData', '{\"Quantity\":\"1-10\",\"CharacteristicValue\":\"Verizon\",\"CharacteristicName\":"Provider\",\"SourceProductCode\":\"VLO-PHN-0005\",\"SourceProductName\":\"ConsumerLandline\"}');
        decisionRow7.put('OutputData', '{\"NRC\":\"125\",\"MRC\":\"300\",\"TargetProductName\":\"Path3\"}');
        sObjList.add(decisionRow7);

        SObject decisionRow8 =  (SObject)Type.forName('CalculationMatrixRow').newInstance();
        decisionRow8.put('CalculationMatrixVersionId', versionSobj.Id);
        decisionRow8.put('InputData', '{\"Quantity\":\"11-20\",\"CharacteristicValue\":\"Verizon\",\"CharacteristicName\":"Provider\",\"SourceProductCode\":\"VLO-PHN-0005\",\"SourceProductName\":\"Consumer Landline\"}');
        decisionRow8.put('OutputData', '{\"NRC\":\"135\",\"MRC\":\"600\",\"TargetProductName\":\"Path3\"}');
        sObjList.add(decisionRow8);

        insert sObjList;
        sObjList.clear();

        SObject calMatrixVersion =  (SObject)Type.forName('CalculationMatrixVersion').newInstance();
        calMatrixVersion.put('Id', versionSobj.Id);
        calMatrixVersion.put('IsEnabled', true);
        update calMatrixVersion;

        SObject calcProcedure =  (SObject)Type.forName('CalculationProcedure').newInstance();
        calcProcedure.put('Name', 'AttributePricingDemoProcedureTest');
        insert calcProcedure;

        SObject procVersion =  (SObject)Type.forName('CalculationProcedureVersion').newInstance();
        procVersion.put('Name', 'Test Pricing Procedure');
        procVersion.put('VersionNumber', 5);
        procVersion.put('IsEnabled', false);
        procVersion.put('CalculationProcedureId', calcProcedure.Id);
        procVersion.put('StartDateTime', DateTime.now().addDays(-5));
        procVersion.put('EndDateTime', DateTime.now().addDays(5));
        procVersion.put('Rank', 5);
        insert procVersion;

        // Create the Pricing Plan
        vlocity_cmt__PricingPlan__c plan = new vlocity_cmt__PricingPlan__c(Name = 'Default Pricing Plan', vlocity_cmt__Code__c = 'DEFAULT_PRICING_PLAN', vlocity_cmt__IsActive__c = true);
        insert plan;

        // Create the pricing plan ABP step
        vlocity_cmt__PricingPlanStep__c planStep1 = new vlocity_cmt__PricingPlanStep__c(Name = 'Test Matrix', vlocity_cmt__ImplementationName__c = 'CustomPricingPlanStepImpl', 
        vlocity_cmt__IsActive__c = true, vlocity_cmt__MethodName__c = 'GetMatrixPrice', vlocity_cmt__Sequence__c = 1.0, vlocity_cmt__PricingPlanId__c = plan.Id,
        vlocity_cmt__Parameters__c = '{"ProcedureName":"Test Pricing Procedure","MatrixName":"AttributePricingMatrixTest","DecisionMatrix":"True"}');
        insert planStep1;

        // Create Pricing Variables
        vlocity_cmt__PricingVariable__c oneTimeStdPriceVar = new vlocity_cmt__PricingVariable__c(Name = 'One Time Std Price', vlocity_cmt__Code__c = 'OT_STD_PRC',vlocity_cmt__Aggregation__c = 'Unit',
        vlocity_cmt__ChargeType__c='One-time',vlocity_cmt__IsActive__c = true,vlocity_cmt__Scope__c = 'Line',vlocity_cmt__SubType__c = 'Standard',vlocity_cmt__Type__c = 'Price',
        vlocity_cmt__ValueType__c='Pricing Element',vlocity_cmt__CurrencyType__c='Currency');
        sObjList.add(oneTimeStdPriceVar);

        vlocity_cmt__PricingVariable__c mrcPriceVar = new vlocity_cmt__PricingVariable__c(Name = 'Recurring Monthly Std Price', vlocity_cmt__Code__c = 'REC_MNTH_STD_PRC',vlocity_cmt__Aggregation__c = 'Unit',
        vlocity_cmt__ChargeType__c='Recurring', vlocity_cmt__RecurringFrequency__c ='Monthly',vlocity_cmt__IsActive__c = true,vlocity_cmt__Scope__c = 'Line',vlocity_cmt__SubType__c = 'Standard',vlocity_cmt__Type__c = 'Price',
        vlocity_cmt__ValueType__c='Pricing Element',vlocity_cmt__CurrencyType__c='Currency');        
        sObjList.add(mrcPriceVar);

        insert sObjList;
        sObjList.clear();

        //Creating PricingVariableBinding
        vlocity_cmt__PricingVariableBinding__c pvb1 = new vlocity_cmt__PricingVariableBinding__c(Name='One Time Std Price - OrderItem',vlocity_cmt__DestinationSObjectType__c='OrderItem',
        vlocity_cmt__DestinationFieldApiName__c = 'vlocity_cmt__OneTimeCharge__c', vlocity_cmt__PricingVariableId__c = oneTimeStdPriceVar.Id);
        sObjList.add(pvb1);
        vlocity_cmt__PricingVariableBinding__c pvb2 = new vlocity_cmt__PricingVariableBinding__c(Name='Recurring Monthly Std Price - OrderItem',vlocity_cmt__DestinationSObjectType__c='OrderItem',
        vlocity_cmt__DestinationFieldApiName__c = 'vlocity_cmt__RecurringCharge__c', vlocity_cmt__PricingVariableId__c = mrcPriceVar.Id);
        sObjList.add(pvb2);

        insert sObjList;
        sObjList.clear();
    }

    @isTest
    private static void testLargeCalcMatrix()
    {
        setupCalcMatrixData();

        Test.startTest();

        Map<String, Object> input = new Map<String, Object>();
        input.put('PricingPlanCode','DEFAULT_PRICING_PLAN');
        input.put('PricingPlanStepSequenceNumbers','1');
        AttributeMatrixInfoCacheBatch batch = new AttributeMatrixInfoCacheBatch(input);
        Id batchId = Database.executeBatch(batch);

        Test.stopTest();

        List<SObject> cmr = Database.query('SELECT Id, Name, vlocity_cmt__ApiResponse__c, vlocity_cmt__CacheKey__c, vlocity_cmt__Code__c FROM vlocity_cmt__CachedAPIResponse__c');
        System.debug(JSON.serialize(cmr));
        System.assert(cmr.size() > 0, 'No CachedApiResponse__c records generated.');
    }

    @isTest
    private static void testLargeLookupTable()
    {
        try {
            SObject calculationMatrixBPO = (SObject)Type.forName('CalculationMatrix').newInstance();
        }
        catch(Exception ex){
            return;
        }
        setupLookupTableData();
        
        Test.startTest();

        Map<String, Object> input = new Map<String, Object>();
        input.put('PricingPlanCode','DEFAULT_PRICING_PLAN');
        input.put('PricingPlanStepSequenceNumbers','1');
        AttributeMatrixInfoCacheBatch batch = new AttributeMatrixInfoCacheBatch(input);
        Id batchId = Database.executeBatch(batch);

        Test.stopTest();

        List<SObject> cmr = Database.query('SELECT Id, Name, vlocity_cmt__ApiResponse__c, vlocity_cmt__CacheKey__c, vlocity_cmt__Code__c FROM vlocity_cmt__CachedAPIResponse__c');
        System.debug(JSON.serialize(cmr));
        System.assert(cmr.size() > 0, 'No CachedApiResponse__c records generated.');
    }
}