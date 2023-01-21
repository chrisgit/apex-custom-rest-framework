@SuppressWarnings('PMD.ApexSharingViolations')
public with sharing class AccountContactDeleteCommand {

    public static void execute(string accountId) {
        Savepoint sp = Database.setSavepoint();
        try {
            delete [SELECT Id FROM Contact WHERE AccountId = :accountId];
            delete [SELECT Id FROM Account WHERE Id = :accountId];
        } catch (Exception exc) {
            Database.rollback(sp);
            throw exc;            
        }        
    }

}