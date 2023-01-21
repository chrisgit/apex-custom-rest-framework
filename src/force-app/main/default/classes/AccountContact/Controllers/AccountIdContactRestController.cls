// Controller for /account/{id} endpoint
public with sharing class AccountIdContactRestController extends BaseController {
    public string accountId;

    protected override RestResponseWrapper handleGet() {
        try {
            return Response.Ok(AccountContactQueries.getAccountByIdWithContacts(accountId));
        } Catch (AccountNotFoundException exc) {
            return Response.NotFound();
        }
    }

    protected override RestResponseWrapper handlePut() {
        if (Request.hasBody() == false) {
            return Response.BadRequest();
        }
        AccountRestDto dto = (AccountRestDto)Request.deserialiseBody(AccountRestDto.class);
        AccountUpdateCommand.execute(dto, accountId);

        return Response.Ok(AccountContactQueries.getAccountByIdWithContacts(accountId));
    }

    protected override RestResponseWrapper handleDelete() {
        AccountContactDeleteCommand.execute(accountId);

        return Response.NoContent();
    }
}
