// Controller for /accounts endpount
public with sharing class AccountContactRestController extends BaseController {
    protected override RestResponseWrapper handleGet() {
        return Response.Ok(AccountContactQueries.getAllAccountsWithContacts());
    }

    protected override RestResponseWrapper handlePost() {
        if (Request.hasBody() == false) {
            return Response.BadRequest();
        }
        AccountRestDto dto = (AccountRestDto)Request.deserialiseBody(AccountRestDto.class);
        Id accountId = AccountContactCreateCommand.execute(dto);

        return Response.Ok(AccountContactQueries.getAccountByIdWithContacts(accountId));
    }
}
