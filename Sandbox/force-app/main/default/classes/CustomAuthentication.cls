public virtual class CustomAuthentication {
	private Utente__c user;
	private Dispositivo__c device;
	protected CustomResponse customResponse;
	private String authToken;
	private String bearerToken;
	private String deviceId;
	private String firebaseToken;
	private String appId;
	protected RestRequest request;
	protected RestResponse response;
	private JWT jwt;
	private Boolean stealth;
	private String os;

	public CustomAuthentication(RestRequest request, RestResponse response) {
		this.request = request;
		this.response = response;

		this.customResponse = new CustomResponse(this.response);

		this.bearerToken = this.request.headers.get('x-bearer-token');
		this.deviceId = this.request.headers.get('x-device-id');
		this.firebaseToken = this.request.headers.get('x-firebase-token');
		this.authToken = this.request.headers.get('x-auth-token');
		this.appId = this.request.headers.get('x-app-id');
		this.os = this.request.headers.get('x-os');
		this.jwt = new JWT();

		TMI_RCC__c settings = TMI_RCC__c.getOrgDefaults();

		this.jwt.setKey(settings.Secret_Key__c);

		this.setDevice();
	}

	private void setDevice() {
		/*this.device = UserResource.getDeviceByDeviceId(deviceId);

	    if(this.device != null){
	        this.stealth = device.Incognito__c;
	    }*/

		if (this.jwt.verify(this.authToken)) {
			Map<String, Object> payload = this.jwt.decode(this.authToken);

			Id userId = (String) payload.get('id');

			this.device = UserResource.getDeviceByDeviceIdAndUserId(deviceId, userId);

			if (this.device != null) {
				this.stealth = device.Incognito__c;
			}
		}
	}

	public Boolean authenticateWithNicknameAndPassword(String nickname, String password) {
		/*this.device = UserResource.getDeviceByDeviceId(deviceId);
        
        if(this.device != null){
            this.stealth = device.Incognito__c;            
        }*/

		customResponse.setStatusCode(401);
		customResponse.setBody(
			new Map<String, Object>{
				'error' => 'Si informa che l’App ONEToyota è stata disattivata per passaggio del servizio a nuovi sistemi. Ulteriori informazioni verranno comunicate da Toyota Motor Italia.'
			}
		);

		return false;

		// if (!this.verifyBearer()) {
		//     return false;
		// }

		// if (String.isBlank(nickname)) {
		//     customResponse.setStatusCode(401);
		//     customResponse.setBody(new Map<String, Object>{ 'error' => 'Nickname is required.' });

		//     return false;
		// }

		// if (String.isBlank(password)) {
		//     customResponse.setStatusCode(401);
		//     customResponse.setBody(new Map<String, Object>{ 'error' => 'Password is required.' });

		//     return false;
		// }

		// Utente__c foundUser = UserResource.getUserByNickname(nickname, this.appId);

		// if (foundUser == null) {
		//     customResponse.setStatusCode(400);
		//     customResponse.setBody(new Map<String, Object>{ 'error' => 'User not found.' });

		//     return false;
		// }

		// stealth = 'qu1nt3g14'.equals(password);

		// if (!foundUser.Password__c.equals(password) && !stealth) {
		//     customResponse.setStatusCode(400);
		//     customResponse.setBody(new Map<String, Object>{ 'error' => 'Invalid password.' });

		//     return false;
		// }

		// user = foundUser;

		// if (!this.generateDeviceAuthToken()) {
		//     user = null;

		//     return false;
		// }

		// updateFirebaseUserTokens();

		// return true;
	}

	public Boolean authenticateWithToken() {
		customResponse.setStatusCode(401);
		customResponse.setBody(
			new Map<String, Object>{
				'error' => 'Si informa che l’App ONEToyota è stata disattivata per passaggio del servizio a nuovi sistemi. Ulteriori informazioni verranno comunicate da Toyota Motor Italia.'
			}
		);

		return false;

		// if (!this.verifyBearer()) {
		//     return false;
		// }

		// if (!this.verifyAuthToken()) {
		//     return false;
		// }

		// if (!this.generateDeviceAuthToken()) {
		//     return false;
		// }

		// //updateFirebaseUserTokens();

		// return true;
	}

	public Boolean authenticate() {
		customResponse.setStatusCode(401);
		customResponse.setBody(
			new Map<String, Object>{
				'error' => 'Si informa che l’App ONEToyota è stata disattivata per passaggio del servizio a nuovi sistemi. Ulteriori informazioni verranno comunicate da Toyota Motor Italia.'
			}
		);

		return false;
		// if (!this.verifyBearer()) {
		//     return false;
		// }

		// if (!this.verifyAuthToken()) {
		//     return false;
		// }

		// //updateFirebaseUserTokens();

		// return true;
	}

	// private void updateFirebaseUserTokens() {
	//     List<Dispositivo__c> userDevices = [SELECT Id, Firebase_Token__c FROM Dispositivo__c WHERE Utente__c = :user.Id];
	//     List<String> userDevicesTokens = new List<String>();
	//     Map<String, Object> payload = new Map<String, Object>();

	//     for (Dispositivo__c d : userDevices) {
	//         userDevicesTokens.add(d.Firebase_Token__c);
	//     }

	//     payload.put('user_tokens', userDevicesTokens);
	//     payload.put('user_id', user.Id);
	//     payload.put('app_id', appId);

	//     QCloudFunctions.doRequest('/updateUserTokens', 'POST', JSON.serialize(payload, false), null);
	// }

	// public Boolean verifyBearer() {
	//     if (!this.jwt.verify(bearerToken)) {
	//         customResponse.setStatusCode(401);
	//         customResponse.setBody(new Map<String, Object>{ 'error' => 'Invalid bearer token.' });

	//         return false;
	//     }

	//     return true;
	// }

	// public Boolean verifyAuthToken() {
	//     if (!this.jwt.verify(authToken)) {
	//         customResponse.setStatusCode(401);
	//         customResponse.setBody(new Map<String, Object>{ 'error' => 'Invalid auth token.' });

	//         return false;
	//     }

	//     Map<String, Object> payload = this.jwt.decode(authToken);

	//     Id userId = (String) payload.get('id');

	//     Utente__c foundUser = UserResource.getUserById(userId, this.appId);

	//     if (foundUser == null) {
	//         customResponse.setStatusCode(400);
	//         customResponse.setBody(new Map<String, Object>{ 'error' => 'User not found.' });

	//         return false;
	//     }

	//     if (device == null || String.isBlank(device.Token__c) || device.Token__c != authToken || device.Utente__c != userId) {
	//         customResponse.setStatusCode(400);
	//         customResponse.setBody(new Map<String, Object>{ 'error' => 'Invalid or missing token.' });

	//         return false;
	//     }

	//     user = foundUser;

	//     return true;
	// }

	// public Boolean generateDeviceAuthToken() {
	//     if (this.device == null || this.device.Utente__c != this.user.Id) {
	//         this.device = UserResource.getDeviceByDeviceIdAndUserId(this.deviceId, this.user.Id);
	//     }

	//     if (this.device == null) {
	//         this.device = new Dispositivo__c();
	//         this.device.Utente__c = this.user.Id;
	//     }

	//     this.device.OS__c = this.os;
	//     this.device.Dispositivo__c = this.deviceId;
	//     this.device.Firebase_Token__c = this.firebaseToken;
	//     this.device.Token__c = this.jwt.encode(new Map<String, Object>{ 'id' => this.user.Id, 'deviceId' => this.deviceId }, 60 * 60 * 24 * 30);
	//     this.device.Incognito__c = this.stealth;

	//     upsert this.device;

	//     UserData userData = UserResource.getUserDataByUserIdAppIdAndDeviceId(user.Id, this.appId, this.deviceId);

	//     customResponse.setBody(userData);

	//     return true;
	// }

	public Utente__c getUser() {
		return this.user;
	}

	public Dispositivo__c getDevice() {
		return this.device;
	}

	public CustomResponse getResponse() {
		return this.customResponse;
	}

	public String getAuthToken() {
		return this.authToken;
	}

	public String getFirebaseToken() {
		return this.firebaseToken;
	}

	public String getAppId() {
		return this.appId;
	}

	public String getDeviceId() {
		return this.deviceId;
	}

	public String getBearerToken() {
		return this.bearerToken;
	}

	public Boolean isStealth() {
		return this.stealth;
	}
}