/**
 * Diagnostic Script - 'Standard Cart APIs Data Setup Validation'
 * @author nishank.mishra@salesforce.com (Nishank Mishra)
 * 
 * Purpose: To identify the common data setup issues which result in incorrect behaviours/errors with Standard Cart
 *      jobs / APIs. The Anonymous Apex invocation will print results as debug logs.
 */

 public class StandardCartAPIsDataSetupValidation
 {
     final DiagLogger logger = new DiagLogger();
     final String namespacePrefix = 'vlocity_cmt__';
     final String pciObjectName = namespacePrefix + 'ProductChildItem__c';
     final String customClassObject = namespacePrefix + 'CustomClassImplementation__c';
     final String ovDefinitionObjectName = namespacePrefix + 'OverrideDefinition__c';
     final String pleObjectName = namespacePrefix + 'PriceListEntry__c';
     final List<String> pciFields = new List<String>{
         'Id',
         namespacePrefix + 'ParentProductId__c',
         namespacePrefix + 'ParentProductId__r.ProductCode',
         namespacePrefix + 'ChildProductId__c',
         namespacePrefix + 'ChildProductId__r.ProductCode',
         namespacePrefix + 'MinimumChildItemQuantity__c',
         namespacePrefix + 'MaximumChildItemQuantity__c'
     };
 
     public void validate()
     {
         logger.start('Root PCI Validation');
         validateRootPCIForAllProducts();
         logger.end('Root PCI Validation');
 
         logger.start('PCI Field Validation');
         validatePCIFields();
         logger.start('PCI Field Validation');
 
         logger.start('Interface Implementation Validation');
         validateInterfaces();
         logger.end('Interface Implementation Validation');
 
         logger.start('PLE Validation');
         validatePLEs();
         logger.end('PLE Validation');
 
         logger.start('Attribute Override Validation');
         validateAttributeOverride();
         logger.end('Attribute Override Validation');
 
         logger.start('Promotion Validation');
         validatePromotions();
         logger.end('Promotion Validation');
 
         logger.flush();
     }
 
     /**
      * @return True if and only if there are no PCIs that have a missing required field
      */
     private Boolean validatePCIFields()
     {
         /* Fetch PCIs with null fields from DB: */
         List<SObject> pcis = fetchFilteredPcis();
         
         if (!pcis.isEmpty()) {
             logger.resultWarning('Following ProductChildItem__c records have a null value in either or both of their ' +
                     'MinimumChildItemQuantity__c and MaximumChildItemQuantity__c fields: ' +
                     JSON.serialize(pcis));
         } else {
             logger.resultInfo('PCI Field Validation Successful.');
         }
         return pcis.isEmpty();
     }
 
     private List<SObject> fetchFilteredPcis() {
         List<String> conditions = new List<String>{
             namespacePrefix + 'MinimumChildItemQuantity__c = null',
             namespacePrefix + 'MaximumChildItemQuantity__c = null'
         };
         String query = 'SELECT ' + String.join(pciFields, ', ') + ' ' +
                        'FROM ' + pciObjectName + ' ' +
                        'WHERE ' + String.join(conditions, ' OR ');
         return Database.query(String.format(query, new List<String>{namespacePrefix}));
     }
 
 
     private Boolean validateRootPCIForAllProducts() 
     {
         String innerQuery = 'SELECT ' + namespacePrefix + 'ParentProductId__c ' +
                        'FROM ' + pciObjectName + ' ' +
                        'WHERE ' + namespacePrefix + 'IsRootProductChildItem__c = true';
         
         String query = 'SELECT Id FROM Product2 WHERE Id Not In (' + innerQuery + ')';
 
         List<SObject> productsWithOutRootPCI = Database.query(String.format(query, new List<String>{namespacePrefix}));
         
         if(!productsWithOutRootPCI.isEmpty()) {
             logger.resultWarning('Products without ProductChildItem__c records found. Please run the Root Product Child Item Upgrade job ' +
             'from Vlocity CMT Administration page');
         } else {
             logger.resultInfo('Root PCI validation Successful.');
         }
         return true;
     }
 
 
     private Boolean validateInterfaces()
     {
         String query = 'SELECT Id, Name, ' + namespacePrefix + 'ClassName__c FROM '  + customClassObject;
 
         String queryWithCondition = query + ' WHERE Name = \'CpqPricingPlanStepSelector\' AND ' + namespacePrefix + 'ClassName__c=\'CpqPricingPlanStepSelector\'';
 
         List<SObject> interfaceRecord = Database.query(queryWithCondition);
 
         if(interfaceRecord.isEmpty()) {
             logger.resultWarning('Interface Implementation record missing for CpqPricingPlanStepSelector. Please run the Interface Implementation merge or restore job.');
         } else {
             logger.resultInfo('Interface Implementation Validation Successful.');
         }
         
         return true;
     }
 
     private Boolean validatePLEs()
     {
         List<String> conditions = new List<String>{
             namespacePrefix + 'ProductId__c != null',
             namespacePrefix + 'PricebookEntryId__c = null'
         };
         String query = 'SELECT Id FROM ' + pleObjectName + ' WHERE ' + String.join(conditions, ' AND ');
         
         List<SObject> pleRecords = Database.query(query);
 
         if(!pleRecords.isEmpty())
         {
             logger.resultWarning('PriceListEntry__c records found without PricebookEntry records. Please run the \'Populate PriceBookEntry in PriceListEntry records\' job ' +
             'from Vlocity CMT Administration page.');
         } else {
             logger.resultInfo('PriceListEntry Validation Successful.');
         }
         return true;
     }
 
     private Boolean validateAttributeOverride()
     {
         List<String> conditions = new List<String> {
             namespacePrefix + 'OverrideType__c = \'Attribute\'',
             namespacePrefix + 'OverriddenAttributeAssignmentId__c = null'
         };
 
         String query = 'Select Id From ' + ovDefinitionObjectName + ' Where ' + String.join(conditions, ' AND ');
 
         List<SObject> ovDefinitionRecords = Database.query(query);
         if(!ovDefinitionRecords.isEmpty())
         {
             logger.resultWarning('Following OverrideDefinition__c records of type \'Attribute\' found with null value for OverriddenAttributeAssignmentId__c field:\n' + 
                 JSON.serialize(ovDefinitionRecords));
         } else {
             logger.resultInfo('Override Definition Validation Successful.');
         }
         return true;
     }
 
 
     private Boolean validatePromotions()
     {
         List<String> conditions = new List<String> {
             namespacePrefix + 'DiscountType__c = null',
             namespacePrefix + 'EffectiveEndDate__c < TODAY',
             namespacePrefix + 'IsActive__c = true'
         };
 
         String query = 'Select Id From ' + namespacePrefix + 'Promotion__c WHERE ' + String.join(conditions, ' AND ');
 
         List<SObject> expiredPromotions = Database.query(query);
         if(!expiredPromotions.isEmpty())
         {
             logger.resultWarning('Following Promotion__c records have expired. Please deactivate them before running the job:\n' + 
                 JSON.serialize(expiredPromotions));
         } else {
             logger.resultInfo('Promotion Validation Successful.');
         }
         return true;
     }
 
     /**
      * Standard Logger for Diagnostic Tools:
      * Each log line should be prepended by "|DIAG_LOG_{EntryType}| {Log message}"
      * EntryType can be one of {START, INPUT_PARAMS, RESULT_INFO, RESULT_WARNING, END}
      * START and END is mandatory, the rest are optional.
      * Messages for WARNING should be semantically useful.
      */
     private class DiagLogger
     {
         private string messageStr = '\n\n';
         public void start(String toolName) { printLog('START', toolName); }
         public void end(String toolName) { printLog('END', toolName + '\n'); }
         public void inputParams(Map<String, Object> inputParams) { printLog('INPUT_PARAMS', inputParams.toString()); }
         public void resultInfo(String logMsg) { printLog('RESULT_INFO', logMsg); }
         public void resultWarning(String logMsg) { printLog('RESULT_WARNING', logMsg); }
 
         private void printLog(String entryType, String logMessage) {
             String formattedMessage = String.format('DIAG_LOG_{0} :{1}', new List<String>{entryType, logMessage});
             messageStr+= formattedMessage + '\n';
         }
 
         private void flush() {
             System.debug(LoggingLevel.INFO,   messageStr);
         }
     }
 }