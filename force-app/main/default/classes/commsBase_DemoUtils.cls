/**
 * This will provide some useful utilities when building demonstrations and/or Proof-of-Concepts
 * 
 * 
 * @author Joe McMaster (jmcmaster@vlocity.com)
 * @version 1.1
 * 
 * History
 * -------
 * v1.0 - May 4, 2020  - Initial Version
 * v1.1 - Aug 27, 2020 - Added Metadata utilities (Tooling API)
 *                     - Added SObject utilities
 * 
 */
public with sharing class commsBase_DemoUtils {

    static String VLOCITY_NS  = 'vlocity_cmt';

    // Debug Control
    static boolean DEBUG = true;

    // APIs
    static String API_TOOLING = '/services/data/v45.0/tooling';

    // Custom Exceptions
    public class MissingDataException extends Exception {}
    public class DataMismatchException extends Exception {}

    /**
     * Generates all messages using a consistent structure
     * 
     * @param msg  The message
     * @param e    Any exception
     */
    private static void debug(String msg) {

        if (DEBUG) System.debug(LoggingLevel.INFO, commsBase_DemoUtils.class.getName() + ' - ' + msg);
        else System.debug(LoggingLevel.DEBUG, commsBase_DemoUtils.class.getName() + ' - ' + msg);
    }
    private static void info(String msg) {
        System.debug(LoggingLevel.INFO, commsBase_DemoUtils.class.getName() + ' - ' + msg);
    }
    private static void warn(String msg) {
        warn(msg, null);
    }    
    private static void warn(String msg, Exception e) {
        System.debug(LoggingLevel.WARN, commsBase_DemoUtils.class.getName() + ' - ' + msg);
    }
    private static void err(String msg) {
        err(msg, null);
    }    
    private static void err(String msg, Exception e) {
        System.debug(LoggingLevel.ERROR, commsBase_DemoUtils.class.getName() + ' - ' + msg);
    }

    /**
     * Substitutes any %ns% strings with the actual Vlocity Namespace
     * 
     * @param input  The input string
     * 
     * @return The output string with namespace substitutions
     */
    public static String ns(String input) {

        return input.replaceAll('%ns%', VLOCITY_NS);
    }

    /**
     * Returns a mandatory value from a map
     * 
     * @param key   The key to look for
     * @param data  The map to look in
     * 
     * @return The value corresponding to the key
     * 
     * @throws MissingDataException if the key doesn't exist in the map or corresponds to a null value
     */
    public static Object getMandatory(String key, Map<String, Object> data) {

        if (data != null) {
        
            if (data.containsKey(key)) return data.get(key);

            throw new MissingDataException('key "' + key + '" was not found in the data provided');
        }
        
        throw new MissingDataException('No data provided');
    }
    
    /**
     * Returns a mandatory String value from a map
     * 
     * @param key   The key to look for
     * @param data  The map to look in
     * 
     * @return The String value corresponding to the key
     * 
     * @throws MissingDataException if the key doesn't exist in the map or corresponds to a null value
     * @throws DataMismatchException if the corresponding value is not a String
     */
    public static String getMandatoryString(String key, Map<String, Object> data) {

        Object obj = getMandatory(key, data);
        if (obj instanceof String) return (String)obj;

        throw new DataMismatchException('key "' + key + '=' + obj + '" is not a String');
    }

    /**
     * Returns a mandatory Id value from a map
     * 
     * @param key   The key to look for
     * @param data  The map to look in
     * 
     * @return The Id value corresponding to the key
     * 
     * @throws MissingDataException if the key doesn't exist in the map or corresponds to a null value
     * @throws DataMismatchException if the corresponding value is not an Id
     */
    public static String getMandatoryId(String key, Map<String, Object> data) {

        Object obj = getMandatory(key, data);
        if (obj instanceof Id) return (Id)obj;
        else if (obj instanceof String) return Id.valueOf((String)obj);  // Attempt to convert from String -> Id

        throw new DataMismatchException('key "' + key + '=' + obj + '" is not an Id');
    }

    /**
     * Determines the SObject Type for a given Id 
     * 
     * @param id  The SObject Id
     * 
     * @return The SObject Type
     */
    public static String getType(Id id) {

        return id.getSobjectType().getDescribe().getName();
    }

    /**
     * Performs an HTTP request to the Salesforce Tooling API allowing you to manipulate metadata from Apex
     * 
     * @param method   The HTTP Method to use (GET, POST, etc.)
     * @param path     The path which will be added to the Tooling API URL (i.e. /services/data/v45.0/tooling/<path>)
     * @param payload  The payload (List or Map object)
     * 
     * @return The response object (Map or List)
     */
    private static Object toolingAPI(String method, String path, Object payload) {

        String url = URL.getSalesforceBaseUrl().toExternalForm() + API_TOOLING + path;

        // Formulate the HTTP Request
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method.toUpperCase());
        req.setEndpoint(url);
        if (payload != null) req.setBody(JSON.serialize(payload));        

        // Send the Request and process the response
        debug('Tooling API Request -> ' + method + ' ' + url);
        HttpResponse response = new Http().send(req);
        debug('Tooling API Response -> ' + response.getBody());

        return JSON.deserializeUntyped(response.getBody());
    }

    /**
     * Determines if a given field has been defined on the given SObject
     * 
     * @param sObjectType  The developer name of the SObject (i.e. OrderItem)
     * @param fieldName    The developer name of the field
     * 
     * @return true if the field exists, false otherwise
     */
    public static Boolean fieldExists(String sObjectType, String fieldName) {

        String query = 'SELECT Id, DeveloperName, TableEnumOrId FROM CustomField WHERE TableEnumOrId=\'' + sObjectType + '\' AND DeveloperName=\'' + fieldName + '\'';
        String path  = '/query?q=' + query.replaceAll(' ', '+');

        List<Object> records = (List<Object>)((Map<String, Object>)toolingAPI('GET', path, null)).get('records');

        return !records.isEmpty();
    }

    /**
     * Creates a text field if it doesn't yet exist
     * 
     * @param sObjectType   The name of the SObject to which the field will be added
     * @param fieldDevName  The field developer name
     * @param fieldLength   The maximum number of characters
     * @param fieldLabel    The field label
     * @param fieldDesc     The field description
     *      
     */
    public static void createTextField(String sObjectType, String fieldDevName, Integer fieldLength, String fieldLabel, String fieldDesc) {        

        String fullName = sObjectType + '.' + fieldDevName + '__c';

        if (fieldExists(sObjectType, fieldDevName)) {
            info('Field ' + fullName + ' already exists');
            return;
        }

        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('type', 'Text');
        metadata.put('description', fieldDesc);
        metadata.put('inlineHelpText', '');
        metadata.put('precision', fieldLength);
        metadata.put('label', fieldLabel);            
        metadata.put('required', false);

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('FullName', fullName);
        payload.put('Metadata', metadata);

        Map<String, Object> response = (Map<String, Object>)toolingAPI('POST', '/sobjects/CustomField', payload);

        if ((Boolean)response.get('success')) info('Successfully created field ' + fullName);
        else err('Failed to create field ' + fullName + ' -> ' + JSON.serialize(response));
    }

    /**
     * Creates a currency field if it doesn't yet exist
     * 
     * @param sObjectType   The name of the SObject to which the field will be added
     * @param fieldDevName  The field developer name
     * @param fieldLength   The number of digits to the left of the decimal point
     * @param fieldDecimals The number of digits to the right of the decimal point
     * @param fieldLabel    The field label
     * @param fieldDesc     The field description
     *      
     */
    public static void createCurrencyField(String sObjectType, String fieldDevName, Integer fieldLength, Integer fieldDecimals, String fieldLabel, String fieldDesc) {        

        String fullName = sObjectType + '.' + fieldDevName + '__c';

        if (fieldExists(sObjectType, fieldDevName)) {
            info('Field ' + fullName + ' already exists');
            return;
        }

        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('type', 'Currency');
        metadata.put('description', fieldDesc);
        metadata.put('inlineHelpText', '');
        metadata.put('precision', fieldLength + fieldDecimals);
        metadata.put('scale', fieldDecimals);
        metadata.put('label', fieldLabel);            
        metadata.put('required', false);

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('FullName', fullName);
        payload.put('Metadata', metadata);

        Map<String, Object> response = (Map<String, Object>)toolingAPI('POST', '/sobjects/CustomField', payload);

        if ((Boolean)response.get('success')) info('Successfully created field ' + fullName);
        else err('Failed to create field ' + fullName + ' -> ' + JSON.serialize(response));
    }

    /**
     * Retrieves the metadata for a given object such as fields, relationships, etc.  The metadata for the SObject
     * will be cached (currently no expiry)
     * 
     * @param objectType  The object type (i.e. Account) for which to retrieve metadata
     * 
     * @return The metadata for an object
     */
    public static Schema.DescribeSObjectResult getMetadata(String objectType) {

        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(new String[]{objectType});
        if (descResult.isEmpty()) throw new MissingDataException('SObject "' + objectType + '" was not found');

        return descResult[0];
    }
    
    /**
     * Retrieves all the fields for a given SObject
     * 
     * @param objectType  The SObject type (i.e. Account) for which to retrieve the list of fields
     * 
     * @return The set of fields
     */
    public static Map<String, SObjectField> getFields(String objectType) {

        return getMetadata(objectType).fields.getMap();
    }
    
    /**
     * Runs a SOQL Query and returns a list of results
     * 
     * @param query  The SOQL Query to run
     * 
     * @return The results as a list
     */
    public static List<SObject> query(String query) {

        String finalQuery = query;

        // If we find a SELECT * query, this is not supported natively by SF, so we will instead query the object type to get a list of fields to query
        // Note on Regex Below, there are 6 Regex Groups
        //   Group 0 - The entire string
        //   Group 1 - Beginning of Query (i.e. SELECT)
        //   Group 2 - Optional/Extra fields (i.e. relationships) to grab when executing a SELECT *
        //   Group 3 - FROM
        //   Group 4 - SObject Type
        //   Group 5 - The remainder of the SOQL statement (i.e. WHERE, LIMIT, etc.)
        Pattern p = Pattern.compile('^(.+) \\*(\\s*,\\s*\\S+)* ([Ff][Rr][Oo][Mm]) (\\S+)(.*)$');
        Matcher m = p.matcher(query);
        if (m.matches()) {

            // Add beginning of the query
            String buf = '';
            buf += m.group(1) + ' ';
            
            // Get All Possible SObject Columns
            String columns = '';

            Map<String, SObjectField> fields = getFields(m.group(4));
            Iterator<String> fieldIterator = fields.keySet().iterator();
            while (fieldIterator.hasNext()) {
                
                DescribeFieldResult field = fields.get(fieldIterator.next()).getDescribe();
                
                if (columns.length() > 0) columns += ',';
                columns += field.getName();
            }
            buf += columns + ' ';
            
            // Add the remainder of the query
            if (m.group(2) != null) buf += m.group(2) + ' ';
            buf += m.group(3) + ' ';
            buf += m.group(4);
            buf += m.group(5);
            
            finalQuery = buf;
        }

        // Insert the Vlocity namespace
        finalQuery = ns(finalQuery);

        // Perform the Query
        debug('SOQL Query -> ' + finalQuery);        
        List<SObject> records = Database.query(finalQuery);
        debug('SOQL Result -> ' + records.size() + ' records returned');

        return records;
    }

    /**
     * Converts a list of SObjects to a map of key:value pairs based on the specified field
     * such as Id, Name, etc.  Any duplicate keys will be overwritten so be sure the field you 
     * use is unique for each record.
     * 
     * @param sobjList  The list of SObjects
     * @param byField   The field whose value will be used as the key to create the map entry
     * 
     * @return A key-value Map of SObjects
     */
    public static Map<Object, SObject> toMap(List<SObject> objs, String byField) {

        Map<Object, SObject> objMap = new Map<Object, SObject>();

        for(SObject obj: objs) objMap.put(obj.get(ns(byField)), obj);

        return objMap;        
    }

    /**
     * Runs a SOQL Query and returns a map of results, indexed by the value of the specified field
     * 
     * @param query    The SOQL Query to run
     * @param byField  The field whose value will be used as the key to create the map entry
     * 
     * @return A key-value Map of SObjects
     */
    public static Map<Object, SObject> queryAsMap(String query, String byField) {

        return toMap(query(query), byField);
    }

    /**
     * Creates a new SObject/Record for insertion
     * 
     * @param type  The SObject Type to instantiate
     * 
     * @return The newly created SObject
     */
    public static SObject newSObject(String type) {

        Schema.SObjectType target = Schema.getGlobalDescribe().get(ns(type));
        if (target == null) throw new SObjectException('Unable to instantiate SObject of type "' + ns(type) + '" as it was not found');

        return target.newSObject();
    }

    /**
     * Creates a new SObject/Record and populates fields for insertion
     * 
     * @param type   The SObject Type to instantiate
     * @param fields A set of field names and corresponding values to set on the newly created SObject
     * 
     * @return The newly created SObject
     */
    public static SObject newSObject(String type, Map<String, Object> fields) {

        SObject sobj = newSObject(type);

        // Set all the fields
        Iterator<String> fieldNames = fields.keySet().iterator();
        while (fieldNames.hasNext()) {

            String fieldName = fieldNames.next();
            sobj.put(ns(fieldName), fields.get(fieldName));
        }
        
        return sobj;
    }

    /**
     * Inserts a new SObject
     * 
     * @param sobj  The SObject to upsert
     * 
     * @return The insertion result
     */
    public static Database.SaveResult insertRecord(SObject sobj) {

        Database.SaveResult result = Database.insert(sobj);

        if (result.isSuccess()) {
            if (DEBUG) info(sobj.getSObjectType() + ' successfully inserted -> ' + result.getId());
        }
        else {
            err('Failed to insert ' + sobj.getSObjectType());
            for (Database.Error err: result.getErrors()) {
                err(err.getStatusCode() + ': ' + err.getMessage());
                err('Fields that affected this error -> ' + JSON.serialize(err.getFields()));                
            }

            throw new DmlException('Failed to insert ' + sobj.getSObjectType());
        }

        return result;
    }
    
    /**
     * Prints out all Governor limits and how much you've consumed
     * 
     */
    public static void debugLimits() {
        
        System.debug('----------------- LIMITS ----------------------');
        System.debug('LIMITS -> Aggregate Queries  : ' + Limits.getAggregateQueries() + '/' + Limits.getLimitAggregateQueries());
        System.debug('LIMITS -> Async Calls        : ' + Limits.getAsyncCalls() + '/' + Limits.getLimitAsyncCalls());
        System.debug('LIMITS -> Callouts           : ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());
        System.debug('LIMITS -> CPU Time           : ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
        System.debug('LIMITS -> DML Rows           : ' + Limits.getDMLRows() + '/' + Limits.getLimitDMLRows());
        System.debug('LIMITS -> DML Statements     : ' + Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements());
        System.debug('LIMITS -> Email Invocations  : ' + Limits.getEmailInvocations() + '/' + Limits.getLimitEmailInvocations());
        System.debug('LIMITS -> Future Calls       : ' + Limits.getFutureCalls() + '/' + Limits.getLimitFutureCalls());
        System.debug('LIMITS -> Heap Size          : ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
        System.debug('LIMITS -> Mobile Apex Calls  : ' + Limits.getMobilePushApexCalls() + '/' + Limits.getLimitMobilePushApexCalls());
        System.debug('LIMITS -> Queries            : ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        System.debug('LIMITS -> Query Locator Rows : ' + Limits.getQueryLocatorRows() + '/' + Limits.getLimitQueryLocatorRows());
        System.debug('LIMITS -> Query Rows         : ' + Limits.getQueryRows() + '/' + Limits.getLimitQueryRows());
        System.debug('LIMITS -> Queueable Jobs     : ' + Limits.getQueueableJobs() + '/' + Limits.getLimitQueueableJobs());
        System.debug('LIMITS -> SOSL Queries       : ' + Limits.getSoslQueries() + '/' + Limits.getLimitSoslQueries());
        System.debug('----------------- LIMITS ----------------------');
    }    
}