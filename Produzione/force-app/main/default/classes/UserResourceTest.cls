@isTest
public class UserResourceTest {
    
    static String endpoint = '/services/apexrest/user';
    
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
        user.Tipologia__c = 'Dealer';
        user.App__c = app.Id;
        
        insert user;
        
        Gruppo__c mainGroup = new Gruppo__c();
        
        mainGroup.Name = 'Main';
        
        insert mainGroup;
        
        Gruppo__c brandGroup = new Gruppo__c();
        
        brandGroup.Name = 'Brand 1';
        brandGroup.Tipologia__c = 'Marchio';
        brandGroup.Genitore__c = mainGroup.Id;
        
        insert brandGroup;
        
        Gruppo__c zoneGroup = new Gruppo__c();
        
        zoneGroup.Name = 'Zone 1';
        zoneGroup.Tipologia__c = 'Zona';
        zoneGroup.Genitore__c = brandGroup.Id;
        
        insert zoneGroup;
        
        Utente_Gruppo__c userGroup = new Utente_Gruppo__c();
        
        userGroup.Utente__c = user.Id;
        userGroup.Gruppo__c = zoneGroup.Id;
        
        insert userGroup;
                
        Insieme_Opzioni_Domanda__c questionOptionSet = new Insieme_Opzioni_Domanda__c();
        
        insert questionOptionSet;
        
        Domanda_questionario__c question = new Domanda_questionario__c();
        
        question.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        question.Data_Ora_Inizio__c = System.now();
        question.Data_Ora_Fine__c = System.now().addDays(1);
        
        insert question;
        
        Opzione_Domanda__c questionOption = new Opzione_Domanda__c();
        
        questionOption.Insieme_Opzioni_Domanda__c = questionOptionSet.Id;
        
        insert questionOption;
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id, Nickname__c FROM Utente__c LIMIT 1];
        
    }
    
    static Domanda_questionario__c getQuestion(){
        
        return [SELECT Id FROM Domanda_questionario__c LIMIT 1];
        
    }
    
    @isTest
    static void testUpdateInfoUnauthtenticated(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testgetInfo(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doGet();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testGetUserByNickname(){
        
        Test.startTest();
        
        UserResource.getUserByNickname(getUser().Nickname__c, getApp().Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetDeviceByDeviceId(){
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        Test.startTest();
        
        UserResource.getDeviceByDeviceId(device.Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateInfoWithoutBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUpdateInfoWithEmptyBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUpdateInfoWithWrongBody(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{cdofas£$%£$sdf}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUpdateInfoWithWrongAction(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/asdkuah';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"email":"email","firstName":"firstName","lastName":"lastName","companyRole":"companyRole","companyName":"companyName"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUpdateInfoWithWrongEmailAddress(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/update_info';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"email":"email","firstName":"firstName","lastName":"lastName","companyRole":"companyRole","companyName":"companyName"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUpdateInfo(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/update_info';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"email":"it@quintegia.it","firstName":"firstName","lastName":"lastName","companyRole":"companyRole","companyName":"companyName"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    
    
    @isTest
    static void testUpdateInfoIncognito(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/update_info';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Incognito__c = true;
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"email":"it@quintegia.it","firstName":"firstName","lastName":"lastName","companyRole":"companyRole","companyName":"companyName"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testChangePasswordWithBlankFields(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/change_password';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"oldPassword":"","newPassword":"","newPasswordConfirm":""}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testChangePasswordWithWrongOldPassword(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/change_password';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"oldPassword":"asdasd","newPassword":"asd","newPasswordConfirm":"asd"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testChangePasswordWithOldPasswordCorrectButNewPasswordShort(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/change_password';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"oldPassword":"password","newPassword":"asd","newPasswordConfirm":"asd"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testChangePasswordWithOldPasswordCorrectButNewPasswordsMismatching(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/change_password';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"oldPassword":"password","newPassword":"asdASD123","newPasswordConfirm":"asdASD1234"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testChangePassword(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/change_password';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"oldPassword":"password","newPassword":"asdASD123","newPasswordConfirm":"asdASD123"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAcceptPrivacy(){
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = endpoint + '/accept_privacy';
        req.httpMethod = 'POST';
        
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Firebase_Token__c = 'firebaseToken';
        device.Token__c = jwt.encode(new Map<String, Object>{'id' => getUser().Id}, 60 * 5);
        device.Utente__c = getUser().Id;
        
        insert device;
        
        req.addHeader('x-bearer-token', jwt.encode(null, 60));
        req.addHeader('x-device-id', 'deviceId');
        req.addHeader('x-firebase-token', 'firebaseToken');
        req.addHeader('x-auth-token', device.Token__c);
        req.addHeader('x-app-id', getApp().Id);
        
        req.requestBody = Blob.valueOf('{"action":"accept_privacy"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        
        UserResource.doPost();
        
        System.debug(res.responseBody.toString());
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
}