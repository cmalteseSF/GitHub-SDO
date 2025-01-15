/** Handy utility for generating demo admin platform events
 * @author	Joe McMaster (joe.mcmaster@salesforce.com)
 */
public with sharing class COM_DemoSystemEvent 
{

    /** Creates and sends a demo system event
     * @param type     The event type
     * @param severity The severity (Info, Error, etc.)
     * @param message  The message to send
     */
    private static void send(String type, String severity, String message) 
    {
        // Create the event
        COM_Demo_System_Event__e event = new COM_Demo_System_Event__e();
        event.Type__c     = type;
        event.Severity__c = severity;
        event.Message__c  = message;

        List<COM_Demo_System_Event__e> events = new List<COM_Demo_System_Event__e>();
        events.add(event);
        
        // Transmit the Event
        List<Database.SaveResult> results = EventBus.publish(events);        
    }

    /** Creates and sends an informational demo system event 
     * @param type     The event type
     * @param message  The message to send
     */
    @AuraEnabled
    public static void info(String type, String message) 
    {

        System.debug(LoggingLevel.INFO, type + ' - ' + message);
        send(type, 'Info', message);
    }

    /** Creates and sends an error demo system event
        @param type     The event type
       @param message  The message to send
     */
    @AuraEnabled    
    public static void error(String type, String message) {

        System.debug(LoggingLevel.ERROR, type + ' - ' + message);
        send(type, 'Error', message);
    }
}