global class PodracerUpdater {

  @future (callout=true)
  public static void sendUpdate(String externalId, String updateBody) {
    RecallDataSource__c rds = RecallDataSource__c.getOrgDefaults();
 
    String podracerModelEncoded = EncodingUtil.urlEncode(externalId, 'UTF-8');

    HttpRequest req = new HttpRequest();
    req.setMethod('PUT');
    req.setEndpoint(rds.dataHubURL__c + externalId);
    req.setBody(updateBody);
    Http http = new Http();
    HTTPResponse res = http.send(req);
  }
  
}