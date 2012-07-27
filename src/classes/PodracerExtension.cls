/**
 * Controller extension for acquiring additional podracer details (recall info)
 */
public class PodracerExtension {
  private final Id podracerId;
  
  List<String> recallInfo;
  
  public PodracerExtension(ApexPages.StandardController controller){
      this.podracerId = ((Podracer__c) controller.getRecord()).Id;
  }

  public PodracerExtension(Id id){
      this.podracerId = id;
  }
  
  /** Read external flag from custom settings */
  private boolean isDataSourceExternal()
  {
      RecallDataSource__c rds = RecallDataSource__c.getOrgDefaults();
      boolean rc = (null != rds && rds.external__c);
      System.debug('Recall Info external data source: ' + rc); 
      return rc;
  }
  
  /** Retrieve recall data externally from Data Hub */
  private List<String> getRecallsExternally(ID podracerID, String podracerName) {
      List<String> recallInfo = new String[]{};
      RecallDataSource__c rds = RecallDataSource__c.getOrgDefaults();

      // Retrieve podracer model and escape for URI usage
      String podracerModel = podracerName;
      String podracerModelEncoded = EncodingUtil.urlEncode(podracerModel, 'UTF-8');
    
      // Call out to the reference data hub
      HttpRequest req = new HttpRequest();
      req.setMethod('GET');
      req.setEndpoint(rds.dataHubURL__c + podracerModelEncoded);
      Http http = new Http();
      HTTPResponse res = http.send(req);
      if (res.getStatusCode() != 200) {
          // Request failed - leave the recall list null, 
          // so a request will be retried later
          System.debug('DataHub error at ' + req.getEndpoint() + ' : ' +
            res.getStatusCode() + ' ' + res.getStatus());
      } else {
          // Parse out the recall list
          System.debug('DataHub returned '+res.getBody());
          boolean header = true;
          for (String line : res.getBody().split('[\n\r]')) {
              if (!header) {
                  // Ignore header lines
                  recallInfo.add(line);
              }
              if ('Recalls:' == line) {
                  // all following lines do not belong to header
                  // and should be included in the recall list
                  header = false;
              }
          }
      }
      return recallInfo;
  }

  /** Retrieve recall data internally by querying the corresponding custom object */
  private List<String> getRecallsInternally(ID podracerID, String podracerName) {
      List<String> recallInfo = new String[]{};
      List<Recall__c> recalls = [ SELECT Name, Podracer__c FROM Recall__c WHERE Podracer__c = :podracerID ];
      if (null == recalls) {
          recallInfo.add('No recalls found');
      } else {
          for (Recall__c recall : recalls) {
              recallInfo.add(recall.name);
          }
      }
      return recallInfo;
  }

  /** Entry point for the VF page - retrieve recall info according to the datasource configuration */  
  public List<String> getRecallInfo() {
      if (null == this.recallInfo) {
        
          // Retrieve podracer model
          List<Podracer__c> pl = [SELECT Name FROM Podracer__c WHERE Id = :this.podracerId LIMIT 1];
        
          // Depending on the configuration of datasource, either retrieve recalls externally,
          // or read from a custom object internally
          if (isDataSourceExternal()) {   
              this.recallInfo = getRecallsExternally(this.podracerId, pl.get(0).Name);
          } else {
              this.recallInfo = getRecallsInternally(this.podracerId, pl.get(0).Name);
          }
      }        
      return this.recallInfo;
  }
}