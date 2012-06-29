public class Podracer {

  public List<Podracer__c> getPodracers() {
    return [ SELECT Name FROM Podracer__c LIMIT 10 ];
  }
}