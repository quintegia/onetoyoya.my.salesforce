@isTest
public class RefreshTokenResourceTest {
    
    static String endpoint = '/services/apexrest/refresh_token';
    
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
    static void testLoginWithWrongToken(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('wrong secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', '');
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        RefreshTokenResource.getToken();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithCorrectTokenButMissingDevice(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5));
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        RefreshTokenResource.getToken();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testLoginWithCorrectToken(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        Test.startTest();
        
        RefreshTokenResource.getToken();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }

}