@isTest
public class AccessTokenResourceTest {
    
    static String endpoint = '/services/apexrest/access_token';
    
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
        
        insert user;
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c LIMIT 1];
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithoutHeaders(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', 'password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithWrongHeaders(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', 'aaaa');
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', 'aaaa');
        req.addHeader('x-app-id', 'aaaa');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', 'password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithWrongBearer(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('wrong secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', '');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', 'password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithCorrectBearerAndWrongAppId(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        App__c app = new App__c();
        
        insert app;
        
        delete app;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', app.Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', 'password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithCorrectParams(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', getApp().Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', 'password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithBlankUsernameAndPassword(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', getApp().Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('', '');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithWrongPassword(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', getApp().Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', 'wrong password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithBlankPassword(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', getApp().Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('nickname', '');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithUsernameAndPasswordWithWrongCredentials(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', getApp().Id);
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        AccessTokenResource.getToken('wrong nickname', 'wrong password');
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }

}