@isTest
public class PasswordResetResourceTest {
    
    static String endpoint = '/services/apexrest/password_reset';
    
    @testSetup
    static void setup(){
        
        TMI_RCC__c settings = new TMI_RCC__c();
        
        settings.Secret_Key__c = 'secret';
        
        insert settings;
        
        App__c app = new App__c();
        
        insert app;
        
        Utente__c user = new Utente__c();
        
        user.Nickname__c = 'nickname';
        user.Password__c = 'password';
        user.App__c = app.Id;
        user.Email__c = 'it@quintegia.it';
        
        insert user;
        
        Utente__c user2 = new Utente__c();
        
        user2.Nickname__c = 'nickname2';
        user2.Password__c = 'password2';
        user2.App__c = app.Id;
        
        insert user2;
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c LIMIT 1];
        
    }
    
    @isTest
    static void testPasswordResetWithoutBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        req.requestBody = null;
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithEmptyBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithWrongBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{acsdc00asdc99""sdcs"}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithBlankUser(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{"usernameOrEmail":""}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithNotExistingUser(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{"usernameOrEmail":"iusadhciasd"}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithNicknameButWithoutAppId(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{"usernameOrEmail":"nickname"}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithNicknameButWithoutEmail(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{"usernameOrEmail":"nickname2"}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithNickname(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{"usernameOrEmail":"nickname"}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testPasswordResetWithEmail(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        req.requestBody = Blob.valueOf('{"usernameOrEmail":"it@quintegia.it"}');
        
        PasswordResetResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }

}