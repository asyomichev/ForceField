trigger onUpdate on Podracer__c (after update) {
  for (Podracer__c p : trigger.new) {
    RecallDataSource__c rds = RecallDataSource__c.getOrgDefaults();
  
    String podracerModelEncoded = EncodingUtil.urlEncode(p.name, 'UTF-8');

    String body = 'Model:' + p.name;
    body += '\n\rLength:' + p.cokpitLength__c + ' meters (cockpit) ' + p.engineLength__c + ' meters (engine)';
    body += '\n\rClass:' + p.classs__c;
    body += '\n\rCrew:' + p.crew__c;
    body += '\n\rMaximum speed:' + p.maxSpeed__c + ' km/h';

    PodracerUpdater.sendUpdate(p.name, body);
  }
}