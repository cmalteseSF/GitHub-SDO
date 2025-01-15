/**
 * This will provide some useful utilities related to Vlocity CPQ
 * 
 * 
 * @author Joe McMaster (jmcmaster@vlocity.com)
 * @version 1.2
 * 
 * History
 * -------
 * v1.0 - May  4, 2020 - Initial Version built for B2B Demo to improve CPQ performance
 * v1.1 - Nov 23, 2021 - Added buildMemberHierarchy and buildLineItemHierarchy methods
 * v2.1 - Nov 30, 2021 - Added support for groups
 * 
 */
global with sharing class commsBase_CPQUtils implements vlocity_cmt.VlocityOpenInterface {
    
    public class CpqUtilException extends Exception {}

    // Methods & Parameters
    public static final String PARAM_LINE_ITEM_ID      = 'lineItemId';
    public static final String PARAM_CART_ID           = 'cartId';
    public static final String PARAM_FIELD_NAMES       = 'fieldNames';       // can be a single field name or list of field names
    public static final String PARAM_FIELD_VALUES      = 'fieldValues';      // can be a single field value or list of field values
    public static final String PARAM_ATTRIBUTE_CODES   = 'attributeCodes';   // can be a single attribute code or list of attribute codes
    public static final String PARAM_ATTRIBUTE_VALUES  = 'attributeValues';  // can be a single attribute value or list of attribute values

    // Line Item Fields
    private static final String FIELD_JSON_ATTRIBUTE  = 'vlocity_cmt__JSONAttribute__c';
    private static final String FIELD_BILLING_ACCOUNT = 'vlocity_cmt__BillingAccountId__c';
    private static final String FIELD_SERVICE_ACCOUNT = 'vlocity_cmt__ServiceAccountId__c';
    private static final String FIELD_ROOT_ITEM_ID    = 'vlocity_cmt__RootItemId__c';
    private static final String FIELD_PARENT_ITEM_ID  = 'vlocity_cmt__ParentItemId__c';

    /**
     * Top level call
     *
     * @param methodName  The method to call in this class
     * @param inputMap    The input data provided in the call to this method
     * @param outputMap   The output object where any results will be stored
     * @param optionsMap  Any options to aid in the execution of this class
     *
     * @returns true if the method completes successfully, false otherwise
     */ 
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> optionsMap) {
        
        try {
        
            if (methodName.equalsIgnoreCase('updateLineItem'))  updateLineItem(inputMap, outputMap, optionsMap);
            else if (methodName.equalsIgnoreCase('inheritAccounts')) inheritAccounts(inputMap, outputMap, optionsMap);
            else if (methodName.equalsIgnoreCase('buildLineItemHierarchy')) buildLineItemHierarchy(inputMap, outputMap, optionsMap);
            else if (methodName.equalsIgnoreCase('buildGroupAndMemberHierarchy')) buildGroupAndMemberHierarchy(inputMap, outputMap, optionsMap);
            else {

                // Unknown Method
                System.debug(LoggingLevel.WARN, commsBase_CPQUtils.class.getName() + ' - Unknown Method (' + methodName + ')');
                outputMap.put('error', commsBase_CPQUtils.class.getName() + ' - Unknown Method (' + methodName + ')');
                return false;
            }
        }
        catch (Exception e) {

            outputMap.put('error', commsBase_CPQUtils.class.getName() + ' - ' + e.getMessage());

            System.debug(LoggingLevel.ERROR, commsBase_CPQUtils.class.getName() + ' - ' + e.getMessage() + '\n' + e.getStackTraceString());
            
            return false;
        }

        // Assume everything is A-Ok!
        return true;
    }

    /**
     * Re-constitutes the group and member hierarchy from a list of line items (typically returned by a DataRaptor)
     * Each entry in the flat list must contain the following fields at a minimum:
     *  -MemberId or GroupId (i.e. derived from vlocity_cmt__QuoteMemberId__c, etc.)
     *  -MemberName or GroupName (i.e. )
     *  -RecurringTotal
     *  -OneTimeTotal
     * 
     * All other fields will be maintained in the resulting heirarchy
     * 
     * @param inputMap   - The input data provided in the call to this method
     * @param outputMap  - The output object where any results will be stored
     * @param optionsMap - Any options to aid in the execution of this class
     * 
     */ 
    global void buildGroupAndMemberHierarchy(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> optionsMap) {

        Map<Id, Object> members = new Map<Id, Object>();

        // Build the complete line item hierarchy for all items
        buildLineItemHierarchy(inputMap, outputMap, optionsMap);
        List<Object> heirarchy = (List<Object>)outputMap.remove('lineItems');

        // If we are dealing with Groups, group the data
        if (hasGroups(heirarchy)) outputMap.put('hierarchy', buildGroupHierarchy(heirarchy));
        else outputMap.put('hierarchy', buildMemberHierarchy(heirarchy));        
    }

    /**
     * Determines if any of the line items are part of a Group (i.e. QuoteGroup, etc.)
     * 
     * @param lineItems  The line items to examine
     * 
     * @return true if any line item is part of a group
     */
    private Boolean hasGroups(List<Object> lineItems) {

        // Determine if we are dealing with Groups (i.e. look for any line item associated to a group)
        for (Integer i=0; i<lineItems.size(); i++) {

            Map<String, Object> lineItem = (Map<String, Object>)lineItems.get(i);

            String gid = (String)lineItem.get('GroupId');
            if (gid != null && !gid.equals('')) return true;
        }

        return false;
    }

    /**
     * Re-constitutes the group hierarchy from a list of line items (typically returned by a DataRaptor)
     * Each entry in the flat list must contain the following fields at a minimum:
     *  -GroupId (i.e. derived from vlocity_cmt__QuotGroupId__c)
     *  -GroupName (i.e. derived from vlocity_cmt__QuoteGroupId__r.Name)
     *  -RecurringTotal
     *  -OneTimeTotal
     * 
     * All other fields will be maintained in the resulting heirarchy
     * 
     * @param lineItemHierarchy - The line items to 
     * 
     * @return The Groups (i.e. QuoteMembers)
     * 
     */ 
    global List<Object> buildGroupHierarchy(List<Object> lineItemHierarchy) {

        Map<String, Object> groups = new Map<String, Object>();

        // Now go through the root level items and group them
        for (Integer i=0; i<lineItemHierarchy.size(); i++) {

            Map<String, Object> rootLI = (Map<String, Object>)lineItemHierarchy.get(i);

            String gid = (String)rootLI.get('GroupId');
            String rootItemListName = ((Id)rootLI.get('Id')).getSobjectType().getDescribe().getName() + 'Root';
            
            if (gid != null) {

                // See if we've already encountered this group
                Map<String, Object> grp = (Map<String, Object>)groups.get(gid);
                if (grp == null) {

                    // Create a new entry for this group
                    grp = new Map<String, Object>();
                    grp.put('MemberId', gid);                        // We use MemberId instead of GroupId as the new label as the ESM PDF template expects it
                    grp.put('MemberName', rootLI.get('GroupName'));  // We use MemberName instead of GroupName as the new label as the ESM PDF template expects it
                    grp.put('RecurringTotal', 0);
                    grp.put('OneTimeTotal', 0);
                    
                    // Add the list of Root Line Items
                    grp.put(rootItemListName, new List<Object>());
                    groups.put(gid, grp);
                }

                // Add this root line item to the group
                ((List<Object>)grp.get(rootItemListName)).add(rootLI);
                if (rootLI.containsKey('OneTimeTotal')) grp.put('OneTimeTotal', (Double)grp.get('OneTimeTotal') + (Double)rootLI.get('OneTimeTotal'));
                if (rootLI.containsKey('RecurringTotal')) grp.put('RecurringTotal', (Double)grp.get('RecurringTotal') + (Double)rootLI.get('RecurringTotal'));
            }
            else {

                // We've encountered a line item with no group so we will put it in a special "No Group" bucket
                Map<String, Object> nogroup = (Map<String, Object>)groups.get('No Group');
                if (nogroup == null) {

                    // Create a new entry for this group
                    nogroup = new Map<String, Object>();
                    nogroup.put('MemberId', null);          // We use MemberId instead of GroupId as the new label as the ESM PDF template expects it
                    nogroup.put('MemberName', 'No Group');  // We use MemberName instead of GroupName as the new label as the ESM PDF template expects it
                    nogroup.put('RecurringTotal', 0);
                    nogroup.put('OneTimeTotal', 0);
                    
                    // Add the list of Root Line Items
                    nogroup.put(rootItemListName, new List<Object>());
                    groups.put('No Group', nogroup);
                }

                // Add this root line item to the group
                ((List<Object>)nogroup.get(rootItemListName)).add(rootLI);
                if (rootLI.containsKey('OneTimeTotal')) nogroup.put('OneTimeTotal', (Double)nogroup.get('OneTimeTotal') + (Double)rootLI.get('OneTimeTotal'));
                if (rootLI.containsKey('RecurringTotal')) nogroup.put('RecurringTotal', (Double)nogroup.get('RecurringTotal') + (Double)rootLI.get('RecurringTotal'));
            }
        }

        return groups.values();
    }

    /**
     * Re-constitutes the member hierarchy from a list of line items (typically returned by a DataRaptor)
     * Each entry in the flat list must contain the following fields at a minimum:
     *  -MemberId (i.e. derived from vlocity_cmt__QuoteMemberId__c)
     *  -MemberName (i.e. derived from vlocity_cmt__QuoteMemberId__r.Name)
     *  -RecurringTotal
     *  -OneTimeTotal
     * 
     * All other fields will be maintained in the resulting heirarchy
     * 
     * @param lineItemHierarchy - The line items to 
     * 
     * @return The Members (i.e. QuoteMembers)
     * 
     */ 
    global List<Object> buildMemberHierarchy(List<Object> lineItemHierarchy) {

        Map<String, Object> members = new Map<String, Object>();

        // Now go through the root level items and group them by member Id
        for (Integer i=0; i<lineItemHierarchy.size(); i++) {

            Map<String, Object> rootLI = (Map<String, Object>)lineItemHierarchy.get(i);

            String mid = (String)rootLI.get('MemberId');
            if (mid != null) {

                String rootItemListName = ((Id)rootLI.get('Id')).getSobjectType().getDescribe().getName() + 'Root';

                // See if we've already encountered this member
                Map<String, Object> member = (Map<String, Object>)members.get(mid);
                if (member == null) {

                    // Create a new entry for this member
                    member = new Map<String, Object>();
                    member.put('MemberId', mid);
                    member.put('MemberName', rootLI.get('MemberName'));
                    member.put('RecurringTotal', 0);
                    member.put('OneTimeTotal', 0);
                    
                    // Add the list of Root Line Items
                    member.put(rootItemListName, new List<Object>());
                    members.put(mid, member);
                }

                // Add this root line item to the member
                ((List<Object>)member.get(rootItemListName)).add(rootLI);
                if (rootLI.containsKey('OneTimeTotal')) member.put('OneTimeTotal', (Double)member.get('OneTimeTotal') + (Double)rootLI.get('OneTimeTotal'));
                if (rootLI.containsKey('RecurringTotal')) member.put('RecurringTotal', (Double)member.get('RecurringTotal') + (Double)rootLI.get('RecurringTotal'));
            }
        }

        return members.values();
    }

    /**
     * Re-constitutes the line item heirarchy from a flat list of line items (typically returned by a DataRaptor)
     * Each entry in the flat list must contain the following fields at a minimum:
     *  -Id
     *  -vlocity_cmt__RootItemId__c
     *  -vlocity_cmt__ParentItemId__c
     * 
     * All other fields will be maintained in the resulting heirarchy
     * 
     * @param inputMap   - The input data provided in the call to this method
     * @param outputMap  - The output object where any results will be stored
     * @param optionsMap - Any options to aid in the execution of this class
     * 
     */ 
    global void buildLineItemHierarchy(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> optionsMap) {
    
        List<Object> hierarchy = new List<Object>();

        if (inputMap.containsKey('lineItems')) {

            // handle single entry or a list
            Object liObj = inputMap.get('lineItems');

            List<Object> flatLIs;
            if (liObj instanceof List<Object>) flatLIs = (List<Object>)liObj;
            else {
                flatLIs = new List<Object>();
                flatLIs.add(liObj);
            }

            // Identify all root level line items
            List<Object> rootLines = getRootLineItems(flatLIs);

            // Build the hierarchy for each line item
            for(Integer i=0; i<rootLines.size(); i++) {

                Map<String, Object> rootLI = (Map<String, Object>)rootLines.get(i);

                // Build a new representation of the root line item with a any child line items
                Map<String, Object> lineItem = rootLI.clone();
                addChildren(lineItem, flatLIs);
                hierarchy.add(lineItem);
            }
        }

        outputMap.put('lineItems', hierarchy);
    }

    /**
     * Returns all the root level items in a given list.  Each entry in the list
     * must contain the following field to determine if it is a root level item or not
     * -vlocity_cmt__ParentItemId__c
     * 
     * @param lineItems  The list of line items
     * 
     * @return The list of root level line items
     */
    private List<Object> getRootLineItems(List<Object> lineItems) {

        List<Object> rootItems = new List<Object>();

        // Identify all root level line items
        for(Integer i=0; i<lineItems.size(); i++) {

            Map<String, Object> li = (Map<String, Object>)lineItems.get(i);

            Id pid = (Id)li.get(FIELD_PARENT_ITEM_ID);
            if (pid == null) rootItems.add(li);
        }

        return rootItems;
    }

    /**
     * Locates any child line items and adds them to the parent line item
     * 
     * @param parentLineItem  The parent line item to which any children will be added
     * @param lineItems       The list containing any child line items
     * 
     */
    private void addChildren(Map<String, Object> parentLineItem, List<Object> lineItems) {

        // Identify any children
        String parentId = (String)parentLineItem.get('Id');
        
        for (Integer i=0; i < lineItems.size(); i++) {
        
            Map<String, Object> li = (Map<String, Object>)lineItems.get(i);

            if (li.containsKey(FIELD_PARENT_ITEM_ID) && parentId.equalsIgnoreCase((String)li.get(FIELD_PARENT_ITEM_ID))) {
                
                // Found a child, add it to the heirarchy
                String childListName = ((Id)li.get('Id')).getSobjectType().getDescribe().getName() + 'Child';                
                if (!parentLineItem.containsKey(childListName)) parentLineItem.put(childListName, new List<Map<String, Object>>());

                Map<String, Object> childItem = li.clone();
                ((List<Object>)parentLineItem.get(childListName)).add(childItem);

                // Add any further children to this child item
                addChildren(childItem, lineItems);
            }
        }
    }

    /**
     * Configures fields and/or attributes on a line item.  This method bypasses 
     * the standard CPQ APIs and sets values directly.  It expects the following input.
     * This examples shows how single values can be provided (i.e. Quantity = 2) or lists
     * of values (ATT-DEV-CL = Black, ATT-DEV-SZ = 128GB).  The attribute category code is optional.
     * 
     * {
     *   "lineItemId": "8023h000000c8ywAAA",
     *   "fieldNames": "Quantity",
     *   "fieldValues": 2,
     *   "attributeCodes": ["ATT-CAT-001::ATT-DEV-CL", "ATT-DEV-SZ"],
     *   "attributeValues": ["Black", "128GB"]
     * }
     *
     * @param inputMap   - The input data provided in the call to this method
     * @param outputMap  - The output object where any results will be stored
     * @param optionsMap - Any options to aid in the execution of this class
     * 
     * @throws CpqUtilException if any problems occur trying to update the field(s) and/or attribute(s)
     */ 
    global void updateLineItem(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> optionsMap) {

        Id lineItemId;
        List<String> fieldNames  = new List<String>();
        List<String> fieldValues = new List<String>();
        List<String> attributeCodes  = new List<String>();
        List<String> attributeValues = new List<String>();

        // Extract the input arguments
        // Line Item Id
        lineItemId = commsBase_DemoUtils.getMandatoryId(PARAM_LINE_ITEM_ID, inputMap);
        if (String.isBlank(lineItemId)) throw new CpqUtilException('Missing Input Map parameter "' + PARAM_LINE_ITEM_ID + '"');

        // Fields to update - we will accept a single field name or list of names
        Object obj = inputMap.get(PARAM_FIELD_NAMES);
        if (obj instanceof String) fieldNames.add((String)obj);
        else if (obj instanceof List<Object>) {
            
            List<Object> objList = (List<Object>)obj;
            for(Object o: objList) fieldNames.add((String)o);
        }

        // Field Value(s) to update - we will accept a single field value or list of values
        obj = inputMap.get(PARAM_FIELD_VALUES);
        if (obj instanceof String) fieldValues.add((String)obj);
        else if (obj instanceof List<Object>) {
            
            List<Object> objList = (List<Object>)obj;
            for(Object o: objList) fieldValues.add((String)o);
        }

        // Confirm we have an equal number of fields and values
        if (fieldNames.size() != fieldValues.size()) throw new CpqUtilException('Mismatch in number of fields (' + fieldNames.size() + ') compared to number of values (' + fieldValues.size() + ')');

        // Attribute Code(s) to update - we will accept a single attribute code or list of codes
        obj = inputMap.get(PARAM_ATTRIBUTE_CODES);
        if (obj instanceof String) attributeCodes.add((String)obj);
        else if (obj instanceof List<Object>) {
            
            List<Object> objList = (List<Object>)obj;
            for(Object o: objList) attributeCodes.add((String)o);
        }
    
        // Attribute Value(s) to update - we will accept a single attribute value or list of values
        obj = inputMap.get(PARAM_ATTRIBUTE_VALUES);
        if (obj instanceof String) attributeValues.add((String)obj);
        else if (obj instanceof List<Object>) {
            
            List<Object> objList = (List<Object>)obj;
            for(Object o: objList) attributeValues.add((String)o);
        }

        // Confirm we have an equal number of attribute codes and values
        if (attributeCodes.size() != attributeValues.size()) throw new CpqUtilException('Mismatch in number of attribute codes (' + attributeCodes.size() + ') compared to number of attribute values (' + attributeValues.size() + ')');        
        
        // Build the SOQL Query for the Line Item
        String fieldQuery = '';
        for (String fname: fieldNames) {
            if (!String.isBlank(fieldQuery)) fieldQuery += ', ';
            fieldQuery += fname;
        }
        if (!attributeCodes.isEmpty()) {
            if (!String.isBlank(fieldQuery)) fieldQuery += ', ';
            fieldQuery += FIELD_JSON_ATTRIBUTE;
        }

        // Query for the line item
        SObject[] lineItem = Database.query('SELECT ' + fieldQuery + ' FROM ' + commsBase_DemoUtils.getType(lineItemId) + ' WHERE Id=\'' + lineItemId + '\' LIMIT 1'); 
        if (!lineItem.isEmpty()) {
            
            // Update any fields
            for(Integer i=0; i<fieldNames.size(); i++) lineItem[0].put(fieldNames.get(i), fieldValues.get(i));

            // Update any attributes
            if (!attributeCodes.isEmpty()) {
            
                String json = (String)lineItem[0].get(FIELD_JSON_ATTRIBUTE);
                if (!String.isBlank(json)) {

                    // Decode Attribute JSON and update
                    Map<String, Object> jsonAttributes = (Map<String, Object>)System.JSON.deserializeUntyped(json);
                    updateAttributes(attributeCodes, attributeValues, jsonAttributes);

                    lineItem[0].put(FIELD_JSON_ATTRIBUTE, System.JSON.serialize(jsonAttributes));
                }
                else throw new CpqUtilException('No configurable attributes were found on line item ' + lineItemId);
            }

            // Commit Changes
            update lineItem[0];
        }
        else throw new CpqUtilException('No line item with Id = ' + lineItemId + ' was found');
    }

    /**
     * Updates one or more attributes in the attribute JSON of a Line Item
     *
     * @param attributeCodes  List of attribute codes to update
     * @param attributeValues List of attribute values to update
     * @param jsonAttributes  The JSON blob containing a line items attributes
     * 
     * @throws CpqUtilException if any problems occur trying to update the attribute(s)
     */
    private void updateAttributes(List<String> attributeCodes, List<String> attributeValues, Map<String, Object> jsonAttributes) {

        // Update all the attributes
        for (Integer i=0; i<attributeCodes.size(); i++) {

            Map<String, Object> attribute = findAttribute(attributeCodes[i], jsonAttributes);
            if (attribute == null) throw new CpqUtilException('Attribute Code "' + attributeCodes[i] + '" was not found on line item');

            // How we update will depend on the attribute type
            Map<String, Object> runtimeInfo = (Map<String, Object>)attribute.get('attributeRunTimeInfo');
            String dataType = (String)runtimeInfo.get('dataType');

            if (dataType.equalsIgnoreCase('Text')) runtimeInfo.put('value', String.valueOf(attributeValues[i]));
            else if (dataType.equalsIgnoreCase('Picklist')) {

                // Locate the PickList option
                Iterator<Object> options = ((List<Object>)runtimeInfo.get('values')).iterator();
                while (options.hasNext()) {

                    Map<String, Object> option = (Map<String, Object>)options.next();
                    if (option.get('value').equals(attributeValues[i])) {

                        runtimeInfo.put('selectedItem', option);
                        break;
                    }
                }
            }
            else throw new CpqUtilException(commsBase_CPQUtils.class.getName() + ' - Unsupported Attribute Data Type "' + dataType + '"');
        }
    }

    /**
     * Finds an attribute in a Line Item's JSON field.  The attribute code to look for
     * can have two flavours:
     * 
     * (1) Just the code (i.e. ATT-DEVICE-COLOR)
     * (2) The attribute category code, followed by the code (i.e. VLO-PRO-0015::ATT-DEVICE-COLOR)
     * 
     * In the first form, this function will simply return the first attribute with a matching code in
     * any category.  This should work in 99% of cases, but just in case two attributes share the same
     * code (but sit in different categories), we can use the more qualified second form above which
     * will only look in the specific category for the attribute.
     * 
     * @param attributeCode  The attribute code (or category_code::attribute_code) to look for
     * @param jsonAttributes The JSON blob containing all the attribute data for the line item
     * 
     * @return The attribute object, or null if it wasn't found
     */
    private Map<String, Object> findAttribute(String attributeCode, Map<String, Object> jsonAttributes) {

        // Handle both forms of an attribute code
        String searchGroup = null;
        String searchCode  = attributeCode;
        if (attributeCode.contains('::')) {
            searchGroup = attributeCode.split('::')[0];
            searchCode  = attributeCode.split('::')[1];
        }

        // Go through the list of Attribute Groups
        Iterator<String> attributeGroupNames = jsonAttributes.keySet().iterator();
        while (attributeGroupNames.hasNext()) {
        
            String groupName = attributeGroupNames.next();
        
            // Search this group's attributes we are performing a global search accross all groups or if this group is the one we are interested in
            if (searchGroup == null || searchGroup.equalsIgnoreCase(groupName)) {

                // Go through the list of Attributes
                Iterator<Object> attributes = ((List<Object>)jsonAttributes.get(groupName)).iterator();
                while (attributes.hasNext()) {                
            
                    // Check if this is the attribute we want to update
                    Map<String, Object> attribute = (Map<String, Object>)attributes.next();
                    if (((String)attribute.get('attributeuniquecode__c')).equalsIgnoreCase(searchCode)) return attribute;
                }
            }
        }

        // If we make it here, we didn't find the attribute
        return null;
    }

    /**
     * Copies (Inherits) the Service & Billing Account information from a root line item
     * to all of its children, granchildren, etc.  This function can be passed a
     * specific line item Id (lineItemId) or a cart Id (cartId) to process all root 
     * line items currently in the cart
     *
     * @param inputMap   - The input data provided in the call to this method
     * @param outputMap  - The output object where any results will be stored
     * @param optionsMap - Any options to aid in the execution of this class
     * 
     * @throws CpqUtilException if any problems occur trying to inherit the account information
     */
    global void inheritAccounts(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> optionsMap) {

        // Extract the input arguments
        // Line Item Id or Cart Id
        Id cartId = (Id)inputMap.get(PARAM_CART_ID);
        Id lineItemId = (Id)inputMap.get(PARAM_LINE_ITEM_ID);

        if (String.isBlank(cartId) && String.isBlank(lineItemId)) throw new CpqUtilException('Missing Input Map parameter ' + PARAM_CART_ID + '" or "' + PARAM_LINE_ITEM_ID + '"');

        // If we have been given a cart Id, process all root line items
        SObject[] lineItems = null;
        if (!String.isBlank(cartId)) {

            // Get all the line items in the cart
            lineItems = Database.query('SELECT ' + FIELD_BILLING_ACCOUNT + ', ' + FIELD_SERVICE_ACCOUNT + ', ' + FIELD_ROOT_ITEM_ID + ' FROM ' + getLineItemType(cartId) + ' WHERE ' + commsBase_DemoUtils.getType(cartId) + 'Id=\'' + cartId + '\'');
        }
        else {

            // Get all the child line items of a particular line item
            lineItems = Database.query('SELECT ' + FIELD_BILLING_ACCOUNT + ', ' + FIELD_SERVICE_ACCOUNT + ', ' + FIELD_ROOT_ITEM_ID + ' FROM ' + commsBase_DemoUtils.getType(lineItemId) + ' WHERE ' + FIELD_ROOT_ITEM_ID + '=\'' + lineItemId + '\'');
        }

        // Process the line items
        if (!lineItems.isEmpty()) {

            // Build a set of root line items
            Map<Id, SObject> rootLineItems = new Map<Id, SObject>();
            for (SObject li: lineItems) {
                if (li.Id == li.get(FIELD_ROOT_ITEM_ID)) rootLineItems.put(li.Id, li);
            }

            // Update Billing & Service Account information for all line items
            List<SObject> updatedLineItems = new List<SObject>();
            for (SObject li: lineItems) {

                // If this isn't a root line item, update the accounts
                if (li.Id != li.get(FIELD_ROOT_ITEM_ID)) {

                    SObject rootItem = rootLineItems.get((Id)li.get(FIELD_ROOT_ITEM_ID));
                    li.put(FIELD_SERVICE_ACCOUNT, rootItem.get(FIELD_SERVICE_ACCOUNT));
                    li.put(FIELD_BILLING_ACCOUNT, rootItem.get(FIELD_BILLING_ACCOUNT));

                    updatedLineItems.add(li);
                }
            }

            update updatedLineItems;
        }
    }

    /**
     * Determines the SObject type of the line items for a given cart
     * 
     * @param cartId  The cart Id
     * 
     * @return The type of SObject used for line items in this cart
     */
    private String getLineItemType(Id cartId) {

        String cartType = commsBase_DemoUtils.getType(cartId);
        if (cartType.equalsIgnoreCase('Opportunity')) return 'OpportunityLineItem';
        else if (cartType.equalsIgnoreCase('Quote')) return 'QuoteLineItem';
        else if (cartType.equalsIgnoreCase('Order')) return 'OrderItem';

        // If we make it here, the cart type isn't supported by this code
        throw new CpqUtilException('Unknown Cart Type "' + cartType + '"');
    }    
}