public with sharing class RevInsightsConfigurationModifier extends wavetemplate.WavetemplateConfigurationModifier
{
    // *****  Main method upon wizard config retrieval ***** /
    public override void onConfigurationRetrieval(wavetemplate.WaveTemplateInfo template)
     {
         hasOpportunitySplits(template);
     }


    private void hasOpportunitySplits(wavetemplate.WaveTemplateInfo template)
      {
          Schema.SObjectType splittypes = Schema.getGlobalDescribe().get('OpportunitySplitType');
          if (splittypes == null) {
            System.debug('OpportunitySplitType doesn\'t exist in the org.');
            template.getVariables().get('Has_OpportunitySplits').setComputedValue('No');
          }
          else {
            String query = 'SELECT DeveloperName, MasterLabel, SplitField, SplitEntity FROM OpportunitySplitType WHERE IsActive = true AND IsTotalValidated = true AND SplitEntity = \'Opportunity\'';
            try {
              List<SObject> activeSplitTypes = Database.query(query);
              if (activeSplitTypes.isEmpty()) {
                System.debug('No active 100% split types for opportunity');
                template.getVariables().get('Has_OpportunitySplits').setComputedValue('No');
              }
              else {
                  template.getVariables().get('Has_OpportunitySplits').setComputedValue('Yes');
              }
            }
            catch (Exception e) {
              System.debug('something went wrong, no splits:' + e);
            }
          }
    }
    
    
      private void setReconfigurePath(wavetemplate.WaveTemplateInfo template, wavetemplate.Answers answers)
      {
        
      }



    //*********************Validation Before APP Creation**************************************************
    // Executes when we click on Create-APP button
    public override void beforeAppCreate(wavetemplate.WaveTemplateInfo template, wavetemplate.Answers answers)
    {
      try {
          WaveAutoInstallRequest latestRequest = [Select Id, TemplateApiName, RequestStatus, CreatedDate From WaveAutoInstallRequest where TemplateApiName =: template.getApiName() order by CreatedDate desc Limit 1];
          if(latestRequest.RequestStatus == 'InProgress') {
              List<WaveCompatibilityCheckItem> checkListItems = this.getCompatibiltyCheckItems(template, false, true);
              // get the payloadFromTheApp
              String payload = '';
              for (WaveCompatibilityCheckItem objectToValidate : checkListItems) {
                  if(objectToValidate.taskResult == 'Completed'){
                      payload = objectToValidate.payload;
                  }
              }
              if(payload != ''){
                  Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
                  for (String key : payloadMap.keySet()) {
                      answers.put(key, payloadMap.get(key));
                  }
              }
              answers.put('autoInstall', true);
          }
      } catch(Exception e){
          // Could not find latest request continue as normal
      }
    }
    
    private List<WaveCompatibilityCheckItem> getCompatibiltyCheckItems(wavetemplate.WaveTemplateInfo waveTemplate, boolean thisVersionOnly, boolean includePayload){
        String versionCriteria = '';
        if (thisVersionOnly){
            versionCriteria = ' AND TemplateVersion = ' +
                            (null == waveTemplate.getReleaseInfo() || null == waveTemplate.getReleaseInfo().getTemplateVersion() ? 'null' : '\''+ waveTemplate.getReleaseInfo().getTemplateVersion() + '\'');
        }
        String query = 'SELECT Id, TaskName, TaskResult, TemplateApiName, TemplateVersion ' + (includePayload ? ', Payload' : '') +
                       ' FROM WaveCompatibilityCheckItem' +
                       ' WHERE TemplateApiName = \'' + waveTemplate.getApiName() + '\'' +
                        versionCriteria;
        return Database.query(query);
    }
}