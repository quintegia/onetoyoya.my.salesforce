@isTest
public class CustomAuthenticationTest {
	@testSetup
	static void setup() {
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

		insert user;

		/*JWT jwt = new JWT();
        
        jwt.setKey(settings.Secret_Key__c);
        
        Dispositivo__c device = new Dispositivo__c();
        
        device.Dispositivo__c = 'deviceId';
        device.Utente__c = user.Id;
        
        insert device;
        
        String token = jwt.encode(new Map<String, Object>{ 'id' => user.Id, 'deviceId' => device.Dispositivo__c }, 60 * 60 * 24 * 30);
        
        device.Firebase_Token__c = token;
        device.Token__c = token;
        
        update device;*/

		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());
	}

	static App__c getApp() {
		return [SELECT Id FROM App__c LIMIT 1];
	}

	static Utente__c getUser() {
		return [SELECT Id FROM Utente__c LIMIT 1];
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithoutHeaders() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', 'password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithWrongHeaders() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.addHeader('x-bearer-token', 'aaaa');
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', 'aaaa');
		req.addHeader('x-app-id', 'aaaa');

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', 'password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithWrongBearer() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('wrong secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', '');

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', 'password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithCorrectBearerAndWrongAppId() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		App__c app = new App__c();

		insert app;

		delete app;

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', app.Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', 'password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithCorrectParams() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', 'password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithBlankUsernameAndPassword() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('', '');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithWrongPassword() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', 'wrong password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithBlankPassword() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('nickname', '');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithUsernameAndPasswordWithWrongCredentials() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithNicknameAndPassword('wrong nickname', 'wrong password');
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithWrongToken() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('wrong secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', '');
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithToken();
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithCorrectTokenButMissingDevice() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', jwt.encode(new Map<String, Object>{ 'id' => getUser().Id }, 60 * 5));
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithToken();
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testLoginWithCorrectToken() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		Dispositivo__c device = new Dispositivo__c();

		device.Dispositivo__c = 'deviceId';
		device.Firebase_Token__c = 'firebaseToken';
		device.Token__c = jwt.encode(new Map<String, Object>{ 'id' => getUser().Id }, 60 * 5);
		device.Utente__c = getUser().Id;

		insert device;

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', device.Token__c);
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		ca.authenticateWithToken();
		System.assert(ca.getUser() == null);
	}

	@isTest
	static void testAuthentication() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		Dispositivo__c device = new Dispositivo__c();

		device.Dispositivo__c = 'deviceId';
		device.Firebase_Token__c = 'firebaseToken';
		device.Token__c = jwt.encode(new Map<String, Object>{ 'id' => getUser().Id }, 60 * 5);
		device.Utente__c = getUser().Id;

		insert device;

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', device.Token__c);
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		// System.assert(ca.authenticate());
	}

	@isTest
	static void testAuthenticationWithNotExistingUser() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		Utente__c user = new Utente__c();

		user.Nickname__c = 'nickname2';
		user.Password__c = 'password2';
		user.App__c = getApp().Id;

		insert user;

		delete user;

		Dispositivo__c device = new Dispositivo__c();

		device.Dispositivo__c = 'deviceId';
		device.Firebase_Token__c = 'firebaseToken';
		device.Token__c = jwt.encode(new Map<String, Object>{ 'id' => user.Id }, 60 * 5);
		device.Utente__c = getUser().Id;

		insert device;

		req.addHeader('x-bearer-token', jwt.encode(null, 60));
		req.addHeader('x-device-id', 'deviceId');
		req.addHeader('x-firebase-token', 'firebaseToken');
		req.addHeader('x-auth-token', device.Token__c);
		req.addHeader('x-app-id', getApp().Id);

		CustomAuthentication ca = new CustomAuthentication(req, res);
		System.assert(!ca.authenticate());
	}

	@isTest
	static void testExtras() {
		Test.setMock(HttpCalloutMock.class, new CloudFunctionsHttpMock());

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		JWT jwt = new JWT();
		jwt.setKey('secret');

		CustomAuthentication ca = new CustomAuthentication(req, res);

		ca.getDevice();
		ca.getResponse();
		ca.getAuthToken();
		ca.getFirebaseToken();
		ca.getDeviceId();
		ca.getBearerToken();
	}
}