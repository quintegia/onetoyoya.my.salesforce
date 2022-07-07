@isTest
public class ChatResourceTest {
    
    static String endpoint = '/chats';
    
    @testSetup
    static void setup(){
        
        TMI_RCC__c settings = new TMI_RCC__c();
        
        settings.Secret_Key__c = 'secret';
        settings.Google_Cloud_Functions_URL__c = 'https://us-central1-tmi-rcc-dev.cloudfunctions.net';
        
        insert settings;
        
        App__c app = new App__c();
        
        insert app;
        
        Utente__c user = new Utente__c();
        
        user.Nickname__c = 'nickname';
        user.Password__c = 'password';
        user.App__c = app.Id;
        user.Tipologia__c = 'Dealer';
        user.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert user;
        
        Utente__c user2 = new Utente__c();
        
        user2.Nickname__c = 'nickname2';
        user2.Password__c = 'password2';
        user2.App__c = app.Id;
        user2.Tipologia__c = 'Dealer';
        user.Azienda_Permessi_Visualizzazione__c = 'TMI';
        
        insert user2;
        
        Chat__c chat1 = new Chat__c();
        
        chat1.App__c = app.Id;
        chat1.Area__c = 'Sales';
        chat1.Descrizione__c = 'Desc';
        chat1.Nome__c = 'Chat';
        chat1.Proprietario__c = user.Id;
        
        insert chat1;
        
        Utente_Chat__c userChat1 = new Utente_Chat__c();
        
        userChat1.Chat__c = chat1.Id;
        userChat1.Utente__c = user.Id;
        userChat1.Abilita_Notifiche__c = false;
        userChat1.Abilita_Storico__c = true;
        userChat1.Aggiunto_Da_Utente__c = user.Id;
        userChat1.Data_Ora_Aggiunta__c = System.now();
        userChat1.Ruolo_Chat__c = 'admin';
        
        insert userChat1;
        
        Utente_Chat__c userChat2 = new Utente_Chat__c();
        
        userChat2.Chat__c = chat1.Id;
        userChat2.Utente__c = user2.Id;
        userChat2.Abilita_Notifiche__c = false;
        userChat2.Abilita_Storico__c = true;
        userChat2.Aggiunto_Da_Utente__c = user2.Id;
        userChat2.Data_Ora_Aggiunta__c = System.now();
        userChat2.Ruolo_Chat__c = 'guest';
        
        insert userChat2;
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
    }
    
    static App__c getApp(){
        
        return [SELECT Id FROM App__c LIMIT 1];
        
    }
    
    static Utente__c getUser(){
        
        return [SELECT Id FROM Utente__c LIMIT 1];
        
    }
    
    static Utente__c getUser2(){
        
        return [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
    }
    
    static Chat__c getChat(){
        
        return [SELECT Id FROM Chat__c LIMIT 1];
        
    }
    
    static Gruppo__c getGroup(){
        
        return [SELECT Id FROM Gruppo__c LIMIT 1];
        
    }
    
    static Utente_Chat__c getUserChat(){
        
        return [SELECT Id FROM Utente_Chat__c LIMIT 1];
        
    }
    
    @isTest
    static void testUnauthenticatedGet(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('wrong secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testUnauthenticatedPost(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('wrong secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostChats(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('{"chat_title":"Gruppo","chat_description":"Descrizione","chat_area":"Sales","chat_image_url":null,"members": ["' + u.Id + '"]}');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostCreateDirectChat(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('{"chat_title":null,"chat_description":null,"chat_area":null,"chat_image_url":null,"members": ["' + u.Id + '"],"chat_type":"direct"}');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostUpdateChat(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        
        req.requestURI = endpoint + '/' + chat.Id;
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('{"chat_title":"Gruppo2","chat_description":"Descrizione2","chat_area":"Sales","chat_image_url":null}');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostAddMembersToChat(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        Utente__c user = getUser2();
        
        req.requestURI = endpoint + '/' + chat.Id + '/members';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('{"members": [{"userId": "' + user.Id + '", "historyEnabled": true}]}');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostChatToggleAdmin(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        Utente__c user = getUser();
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        //Utente_Chat__c uc = [SELECT Id FROM Utente_Chat__c WHERE Utente__c = :u.Id AND Chat__c = :chat.Id LIMIT 1];
        
        req.requestURI = endpoint + '/' + chat.Id + '/members/' + u.Id + '/toggleAdmin';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        req.requestBody = Blob.valueOf('{"members": [{"userId": "' + u.Id + '", "historyEnabled": true}]}');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        //System.assert(body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostWrong(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint + 'asdasxa';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('{"chat_title":"Gruppo","chat_description":"Descrizione","chat_area":"Sales","chat_image_url":null,"members": ["' + u.Id + '"]}');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        //System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostChatExit(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        Utente_Chat__c member = getUserChat();
        
        req.requestURI = endpoint + '/' + chat.Id + '/members/' + member.Id + '/exit';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedPostChatToggleNotifications(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        
        req.requestURI = endpoint + '/' + chat.Id + '/notifications';
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Utente__c u = [SELECT Id FROM Utente__c WHERE Nickname__c = 'nickname2' LIMIT 1];
        
        req.requestBody = Blob.valueOf('');
        
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
        
        Test.startTest();
        
        ChatResource.doPost();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedGetChats(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint;
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedGetWrong(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint + '/asdxasd';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode != 200);
        //System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedGetChatsMembers(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        req.requestURI = endpoint + '/members';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedGetChatMembers(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        
        req.requestURI = endpoint + '/' + chat.Id + '/members';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedGetChatMemberNotificationStatus(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        
        req.requestURI = endpoint + '/' + chat.Id + '/notifications';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }
    
    @isTest
    static void testAuthenticatedGetChatMemberInfo(){
        
        Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        JWT jwt = new JWT();
        jwt.setKey('secret');
        
        Chat__c chat = getChat();
        Utente__c user = getUser();
        
        req.requestURI = endpoint + '/' + chat.Id + '/members/' + user.Id;
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
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
        
        Test.startTest();
        
        ChatResource.doGet();
        
        Test.stopTest();
        
        String body = res.responseBody.toString();
        
        System.assert(res.statusCode == 200);
        System.assert(!body.containsIgnoreCase('error'));
        
    }

}