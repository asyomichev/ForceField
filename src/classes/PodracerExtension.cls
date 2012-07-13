/**
  Controller extension for acquiring additional podracer details outside
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
  
  public List<String> getRecallInfo() {
      if (null == recallInfo) {
        
        // Retrieve podracer model
        List<Podracer__c> pl = [SELECT Name FROM Podracer__c WHERE Id = :this.podracerId LIMIT 1];
        
        // Retrieve podracer model and escape for URI usage
        String podracerModel = pl.get(0).Name;
        String podracerModelEncoded = EncodingUtil.urlEncode(podracerModel, 'UTF-8');
        
        // Call out to the reference data hub
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('http://evening-beach-9369.herokuapp.com/podracer/' + podracerModelEncoded);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
          // Request failed - leave the recall list null, 
          // so a request will be retried later
          System.debug('DataHub error at ' + req.getEndpoint() + ' : ' +
            res.getStatusCode() + ' ' + res.getStatus());
        } else {
          // Parse out the recall list
          recallInfo = new String[]{};
          System.debug('DataHub returned '+res.getBody());
          boolean header = true;
          for (String line : res.getBody().split('[\n\r]'))
          {
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
        
      }
      return recallInfo;
  }
}