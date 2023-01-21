public with sharing class AccountContactQueries {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<AccountRestDto> getAllAccountsWithContacts() {
        List<Account> accounts = [
            SELECT Id, Name, AccountNumber, Industry, 
                (SELECT Id, FirstName, LastName, HomePhone, MobilePhone, Email
                FROM Contacts) 
            FROM Account
            LIMIT 100];

        return AccountRestDtoMapper.toDto(accounts);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<AccountRestDto> getAccountByIdWithContacts(Id accountId) {
        List<Account> accounts = [
            SELECT Id, Name, AccountNumber, Industry, 
                (SELECT Id, FirstName, LastName, HomePhone, MobilePhone, Email
                FROM Contacts) 
            FROM Account
            WHERE Id = :accountId
            LIMIT 1];
        
        if (accounts.size() == 0) {
            throw new AccountNotFoundException(string.format('Account [{0}] not found', new Object[] { accountId }));
        }

        return AccountRestDtoMapper.toDto(accounts);
    }
}
