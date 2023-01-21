@SuppressWarnings('PMD.ApexSharingViolations')
public with sharing class AccountContactCreateCommand {
    public static Id execute(AccountRestDto dto) {
        validateCreateRequest(dto);

        Savepoint sp = Database.setSavepoint();
        try {
            Account acc = createAccount(dto);
            createContacts(dto, acc);
            return acc.Id;
        } catch (Exception exc) {
            Database.rollback(sp);
            throw exc;
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Account createAccount(AccountRestDto dto) {
        Account acc = AccountRestDtoMapper.toAccountSObject(dto);
        insert acc;
        return acc;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void createContacts(AccountRestDto dto, Account acc) {
        if (dto.hasContacts() == false) {
            return;
        }

        List<Contact> contacts = AccountRestDtoMapper.toContactSObject(dto);
        for (Contact cnt : contacts) {
            cnt.AccountId = acc.Id;
        }

        insert contacts;
    }

    private static void validateCreateRequest(AccountRestDto dto) {
        if (dto.hasAccountId()) {
            InvalidRequestException.raise('Create Account and Contacts. Unexpected field AccountId');
        }
    }
}