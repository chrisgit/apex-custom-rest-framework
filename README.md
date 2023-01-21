Custom REST API
--------------------

Couple of years ago I worked for a Salesforce ISV, we had custom REST api in Salesforce, however
- had many REST endpoints
- resulted in a lot of global classes (which are difficult to remove if you create packages)
- there was nothing to deal with common cross cutting concerns

As part of an exercise I decided to see if we could reduce the cost of creating new custom REST endpoints or make them cookie cutter.

## Out of the box custom REST api

Creating a custom REST api in Salesforce is relatively easy, attribute a class with RestResource, specify a path and attribute methods with one of the http verbs. 

```Java
@RestResource(urlMapping='/Account/*')
global with sharing class MyRestResource {

    @HttpDelete
    global static void doDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account account = [SELECT Id FROM Account WHERE Id = :accountId];
        delete account;
    }
  
    @HttpGet
    global static Account doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :accountId];
        return result;
    }
  
  @HttpPost
    global static String doPost(String name,
        String phone, String website) {
        Account account = new Account();
        account.Name = name;
        account.phone = phone;
        account.website = website;
        insert account;
        return account.Id;
    }
}
```

Salesforce will deal with routing to your class.

Note: The full path of your custom REST api is `{your salesforce instance url}/services/apexrest/{your custom route}`

Additionally Salesforce can do a lot of hard work for you in binding/unbinding to complex objects

```Java
    @HttpPost
    global static void doPOST(AppDto app) {
        execute(RequestType.HTTPPOST);        
    }
    
    // Global DTO
    global class AppDto {
		public Integer Id;
        public string Forename;
        public string Surname;
    }
```

Call with a payload similar to the one below
```Json
{
    "app": {
        "ApplicantId": 8899,
        "Forename": "Jay",
        "Surname": "Man",
    }
}
```

## The framework

The concept I decided to create here was inspired by middleware components like Ruby/RACK or ASP.Net/HttpModules. The middleware is to handle cross cutting concerns performing validation, routing and dispatching. 

With this design there is a single global CUSTOM REST endpoint to handle all incoming requests. The requests are handled by controllers that are registered with a dispatcher and called based on route matching. If the dispatcher finds a matching route the controllers execute method is called, if a route is not matched then the dispatcher automatically returns a 404.

My first implimentation used a pipeline to handle all cross cutting concerns, of which, the dispatcher was just one element. Each element in the pipeline adhered to an interface and was added to the pipeline using a registration process; the pipeline elements could run before the request was handled, afer the response had been created, on error only (i.e. exceptions thrown), always (irrespective of whethr an exception was thrown) or any combination.

For this demo I have embedded a "pipeline" by way of methods on a base controller using the [Template Method Pattern](https://en.wikipedia.org/wiki/Template_method_pattern). When invoked the base controller will call the following methods
- validatePermissions, to ensuring the user calling the API has the appropriate permissions
- validateHttpHeaders, to ensure the caller has specified the appropriate headers
- validateParameters, to ensure that the correct URL parameters have been set
Before calling the appropriate method which matches the requests http verb

Of course using a pipeline (or template method pattern) you can add extra elements to the process such as logging, sending telemetry etc.

## Pre-requisites
- [Code Editor](https://code.visualstudio.com/download)
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)
- [Salesforce Developer Hub](https://developer.salesforce.com/promotions/orgs/dx-signup)

## Getting started
Create a scratch org using scripts from root ./scripts/create-scratch-org.sh
Push source code using scripts from root ./scripts/push-source-code.sh
Open the scratch org instance in a browser with `sfdx force:org:open -u apex-custom-rest`

## The demo code

There is a single [RestEndpoint](src/force-app/main/default/classes/Rest/RestEndpoint.cls) which creates an instance of the 
[RestDipatcher](src/force-app/main/default/classes/Rest/RestDispatcher.cls), if a route match is found a controller is called.

Adding new endpoints ought to be as easy as creating a new controller and registering it with the dispatcher.

[Example Account Controller](src/force-app/main/default/classes/AccountContact/Controllers/AccountContactRestController.cls)  
[Example Account By Id Controller](src/force-app/main/default/classes/AccountContact/Controllers/AccountIdContactRestController.cls)

Account Controller and Account By Id Controller can be consolidated into a single controller but for simplicity written as two controllers.

Whilst not strictly vertical sliced architecture, the folders structure here relates to functional elements of the application, not technical. 

There is also an example postman collection.

## Adding new Controllers

Create a controller inheriting from the BaseController class, override the http verb methods; if you do not override a method then a http status code 405 Method Not Allowed is returned if the caller tries to use the verb.

```
// A simple http GET only controller
public with sharing class SomeController extends BaseController {
    protected override RestResponseWrapper handleGet() {
        return Response.Ok(QueryClass.getObjects());
    }
}
```

Next, add the dispatcher to the rest endpoint and use the dispatchers register method to add your route along with a controller

```
@RestResource(UrlMapping = '/someapi/*')
global inherited sharing class SomeRestEndpoint {
    private static RestDispatcher dispatcher = new RestDispatcher();

    static
    {
        dispatcher.register('/pathFromRoot', SomeController.class);
    }
```

Create http verb methods on the endpoint class and redirect them to use the dispatcher.

The RestResource(UrlMapping) can be anything; in the demo it is a catch all. If your path has parameters you can add them in curly brackets, i.e. `/pathFromRoot/{someId}`. If you add a property to your controller that matches the name of a parameter in the path it will automatically be available for use in your controller.

Note:
This code was part of my Apex Playground repository but broken out into its own repository to make it easier to follow and maintain.
