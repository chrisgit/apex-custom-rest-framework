@SuppressWarnings('PMD.ApexSharingViolations')
public with sharing class AccountUpdateCommand {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void execute(AccountRestDto dto, string accountId) {
        validateUpdateRequest(dto);

        Savepoint sp = Database.setSavepoint();
        try {
            Account acc = AccountRestDtoMapper.toAccountSObject(dto);
            acc.Id = accountId;
            update acc;
        } catch (Exception exc) {
            Database.rollback(sp);
            throw exc;            
        }
    }

    private static void validateUpdateRequest(AccountRestDto dto) {
        if (dto.hasAccountId()) {
            InvalidRequestException.raise('Update Account. Unexpected field AccountId');          
        }
        if (dto.hasContacts() == true) {
            InvalidRequestException.raise('Update Account. Unexpected list of contacts, please supply account only');
        }
    }
}