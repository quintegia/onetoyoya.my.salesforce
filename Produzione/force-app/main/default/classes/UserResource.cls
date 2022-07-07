@RestResource(urlMapping='/user/*')
global class UserResource {
    
    @HttpGet
    global static void doGet(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
            
            return;
            
        }
        
        CustomResponse res = new CustomResponse(RestContext.response);        
        
        Utente__c user = ca.getUser();
        Id userId = user.Id;
        String appId = ca.getAppId();
        String deviceId = ca.getDeviceId();
            
        res.setBody(getUserDataByUserIdAppIdAndDeviceId(userId, appId, deviceId));        
        res.send();
        
    }
    
    @HttpPost
    global static void doPost(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
            
            return;
            
        }
        
        String action = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/')+1);        
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        //Id userId = 'a4n0E000000n0wsQAA';
        
        Utente__c user = ca.getUser();
        Id userId = user.Id;
        String appId = ca.getAppId();
        String deviceId = ca.getDeviceId();
        
        if(RestContext.request.requestBody == null){  
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Request body missing.'});
            res.send();
            
            return;
            
        }          
            
        String body = RestContext.request.requestBody.toString();
        
        if(String.isEmpty(body)){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Request body is empty.'});
            res.send();
            
            return;
            
        }
        
        Map<String, Object> decodedBody;
        
        try{
        
            decodedBody = (Map<String, Object>) JSON.deserializeUntyped(body);
            
        }catch(Exception ex){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Malformed json.'});
            res.send();
            
            return;
            
        }
        
        if('update_info'.equals(action)){
            
            String email = (String) decodedBody.get('email');
            String firstName = (String) decodedBody.get('firstName');
            String lastName = (String) decodedBody.get('lastName');
            String companyRole = (String) decodedBody.get('companyRole');
            String companyName = (String) decodedBody.get('companyName');
            
            Boolean needUpdate = false;
            
            if(String.isNotBlank(email)){ 
                
                user.Email__c = email;
                needUpdate = true;
                
            }
            
            if(String.isNotBlank(firstName)){
                
                user.Nome__c = firstName;
                needUpdate = true;
                
            }
            
            if(String.isNotBlank(lastName)){
                
                user.Cognome__c = lastName;
                needUpdate = true;
                
            }
            
            if(String.isNotBlank(companyRole)){
                
                user.Ruolo__c = companyRole;
                needUpdate = true;
                
            }
            
            if(String.isNotBlank(companyName)){
                
                user.Ragione_Sociale__c = companyName;
                needUpdate = true;
                
            }
            
            if(needUpdate && !ca.isStealth()){
                
                try{
            
                    update user;
                    
                }catch(Exception ex){
            
                    res.setStatusCode(500);
                    res.setBody(new Map<String, Object>{'error' => ex.getMessage()});
                    res.send();
                    
                    return;
                    
                }
                
            }
            
            res.setBody(getUserDataByUserIdAppIdAndDeviceId(userId, appId, deviceId));        
            res.send();
            
            return;
            
        }
        
        if('change_password'.equals(action)){
            
            String oldPassword = (String) decodedBody.get('oldPassword');
            String newPassword = (String) decodedBody.get('newPassword');
            String newPasswordConfirm = (String) decodedBody.get('newPasswordConfirm');
            
            if(String.isBlank(oldPassword) || String.isBlank(newPassword) || String.isBlank(newPasswordConfirm)){ 
            
                res.setStatusCode(500);
                res.setBody(new Map<String, Object>{'error' => 'Tutti i campi sono obbligatori'});
                res.send();
                
                return;
                
            }
            
            if(!oldPassword.equals(user.Password__c)){ 
            
                res.setStatusCode(500);
                res.setBody(new Map<String, Object>{'error' => 'La vecchia password non coincide con quella attuale.'});
                res.send();
                
                return;
                
            }
            
            if(newPassword.length() < 8){ 
            
                res.setStatusCode(500);
                res.setBody(new Map<String, Object>{'error' => 'La nuova password deve avere almeno 8 caratteri.'});
                res.send();
                
                return;
                
            }
            
            if(!newPassword.equals(newPasswordConfirm)){ 
            
                res.setStatusCode(500);
                res.setBody(new Map<String, Object>{'error' => 'Le 2 nuove password non coincidono.'});
                res.send();
                
                return;
                
            }
            
            user.Password__c = newPassword;
            
            if(!ca.isStealth()){
            
                update user;
                
            }
            
            List<Dispositivo__c> devices = [SELECT Id, Dispositivo__c, Token__c FROM Dispositivo__c WHERE Dispositivo__c != :deviceId AND Utente__c = :userId];
            
            for(Dispositivo__c device : devices){
                
                device.Token__c = null;
                
            }
            
            if(!ca.isStealth()){
            
                update devices;
                
            }
            
            res.setBody(getUserDataByUserIdAppIdAndDeviceId(userId, appId, deviceId));        
            res.send();
            
            return;
            
        }        
        
        if('accept_privacy'.equals(action)){
            
            if(!ca.isStealth()){
                
                user.Data_Ora_Accettazione_Privacy__c = System.now();
                
                try{
            
                    update user;
                    
                }catch(Exception ex){
            
                    res.setStatusCode(500);
                    res.setBody(new Map<String, Object>{'error' => ex.getMessage()});
                    res.send();
                    
                    return;
                    
                }
                
            }
            
            res.setBody(getUserDataByUserIdAppIdAndDeviceId(userId, appId, deviceId));        
            res.send();
            
            return;
            
        }
        
        if('update_profile_image'.equals(action)){
            
            String imagePath = (String) decodedBody.get('image_path');
            
            if(String.isNotBlank(imagePath)){ 
                
                user.Riferimento_Immagine_Profilo__c = imagePath;
                
            }
            
            if(!ca.isStealth()){
                
                try{
            
                    update user;
                    
                }catch(Exception ex){
            
                    res.setStatusCode(500);
                    res.setBody(new Map<String, Object>{'error' => ex.getMessage()});
                    res.send();
                    
                    return;
                    
                }
                
            }
            
            res.setBody(getUserDataByUserIdAppIdAndDeviceId(userId, appId, deviceId));        
            res.send();
            
            return;
            
        }
        
        res.setStatusCode(500);
        res.setBody(new Map<String, Object>{'error' => 'Invalid Request.'});
        res.send();
        
        return;
        
    }
    
    public static UserData getUserDataByUserIdAppIdAndDeviceId(String userId, String appId, String deviceId){
        
        UserData userData = new UserData();
        Utente__c user = getUserById(userId, appId);
        Dispositivo__c device = getDeviceByDeviceIdAndUserId(deviceId, userId);
        
        userData.id = user.Id;
        userData.deviceId = deviceId;
        userData.token = device.Token__c;
        userData.nickname = user.Nickname__c;
        userData.email = user.Email__c;
        userData.firstName = user.Nome__c;
        userData.lastName = user.Cognome__c;
        userData.role = user.Tipologia__c;
        userData.appId = user.App__c;
        userData.companyName = user.Ragione_Sociale__c;
        userData.province = user.Provincia__c;
        userData.profilePictureUrl = user.URL_Foto__c;
        userData.profilePicturePath = user.Riferimento_Immagine_Profilo__c;
        userData.companyRole = user.Ruolo__c;
        userData.answeredQuestions = [SELECT COUNT() FROM Risposta_questionario__c WHERE Utente__c = :userId];
        userData.viewedArticles = [SELECT COUNT() FROM Utente_Articolo__c WHERE Utente__c = :userId AND Tipologia__c = 'Visualizzazione'];
        userData.receivedNotifications = 0;
        userData.privacyAcceptedAt = user.Data_Ora_Accettazione_Privacy__c != null ? user.Data_Ora_Accettazione_Privacy__c.getTime() : null;
        
        if(device.Incognito__c){
            
            userData.privacyAcceptedAt = System.now().getTime();
            
        }
        
        Boolean userIsSlave = user.Utente_Master__c != null;
        Boolean userIsDealer = 'Dealer'.equalsIgnoreCase(user.Tipologia__c);
        
        String userRole = user.Tipologia__c.toLowerCase();
        
        if(userIsSlave){
            userId = user.Utente_Master__c;
            userRole += '_slave';
        }
        
        userData.slave = userIsSlave;
        
        List<Gruppo__c> userGroups = getUserGroups(userId, userIsDealer);
        List<Gruppo__c> allGroups = getAllGroups();
        
        List<String> brands = new List<String>();
        List<String> groups = new List<String>();
        
        List<GroupData> parentGroups = new List<GroupData>();
        List<GroupData> childGroups = new List<GroupData>();
        
        for(Gruppo__c g : getParentGroups(userGroups, allGroups)){
            
            parentGroups.add(new GroupData(g));
            
        }
        
        for(Gruppo__c g : getChildGroups(userGroups, allGroups)){
            
            childGroups.add(new GroupData(g));
            
        }
        
        userData.parentGroups = parentGroups;
        userData.childGroups = childGroups;
        
        List<GroupData> allUserGroups = new List<GroupData>();
        allUserGroups.addAll(parentGroups);
        allUserGroups.addAll(childGroups);
        
        for(GroupData gd : allUserGroups){
            
            if('Marchio'.equalsIgnoreCase(gd.groupType) && !brands.contains(gd.name)){
                brands.add(gd.name);
            }
            
        }
        
        String brandsConcats = '';
        
        groups.add(userRole);
        
        for(String b : brands){
            
            groups.add(userRole + '_' + b.toLowerCase());
            
            brandsConcats += b.toLowerCase() + '_';
            
        }
        
        brandsConcats = brandsConcats.removeEndIgnoreCase('_');
        
        groups.add(userRole + '_' + brandsConcats);
        
        userData.brands = brands;
        userData.groups = groups; 
        
        return userData;
        
    }
    
    public static Utente__c getUserById(Id userId, Id appId){
        
        Utente__c u = null;
        
        try{
            
            u = [SELECT Id, Nickname__c, Password__c, Nome__c, Cognome__c, App__c, Ragione_Sociale__c, Provincia__c, Tipologia__c, Email__c, URL_Foto__c, Utente_Master__c,
                 Ruolo__c, Data_Ora_Accettazione_Privacy__c, Azienda_Permessi_Visualizzazione__c, Riferimento_Immagine_Profilo__c, COD_CASA__c
                 FROM Utente__c 
                 WHERE Id = :userId AND App__c = :appId LIMIT 1];
            
        }catch(Exception ex){
            
            System.debug(ex.getMessage());
            
        }
        
        return u;
        
    }
    
    public static Utente__c getUserByNickname(String nickname, Id appId){
        
        Utente__c u = null;
        
        try{
            
            u = [SELECT Id, Nickname__c, Password__c, Nome__c, Cognome__c, App__c, Ragione_Sociale__c, Provincia__c, Tipologia__c, Email__c, URL_Foto__c, Utente_Master__c,
                 Ruolo__c, Data_Ora_Accettazione_Privacy__c, Azienda_Permessi_Visualizzazione__c, Riferimento_Immagine_Profilo__c, COD_CASA__c
                 FROM Utente__c 
                 WHERE Nickname__c = :nickname AND App__c = :appId LIMIT 1];
            
        }catch(Exception ex){
            
            System.debug(ex.getMessage());
            
        }
        
        return u;
        
    }
    
    public static Dispositivo__c getDeviceByDeviceId(String deviceId){
        
        Dispositivo__c d = null;
        
        try{
            
            d = [SELECT Id, Dispositivo__c, Token__c, Incognito__c, Utente__c FROM Dispositivo__c WHERE Dispositivo__c = :deviceId LIMIT 1];
            
        }catch(Exception ex){
            
            System.debug(ex.getMessage());
            
        }
        
        return d;
        
    }
    
    public static Dispositivo__c getDeviceByDeviceIdAndUserId(String deviceId, String userId){
        
        Dispositivo__c d = null;
        
        try{
            
            d = [SELECT Id, Dispositivo__c, Token__c, Incognito__c, Utente__c FROM Dispositivo__c WHERE Dispositivo__c = :deviceId AND Utente__c = :userId LIMIT 1];
            
        }catch(Exception ex){
            
            System.debug(ex.getMessage());
            
        }
        
        return d;
        
    }
    
    public static List<Gruppo__c> getParentGroups(List<Gruppo__c> usersGroups, List<Gruppo__c> allGroups){
        
        List<Gruppo__c> parentGroups = new List<Gruppo__c>();
       	Set<Id> usersGroupsIds = new Set<Id>();
        Map<Id, Id> allGroupsIds = new Map<Id, Id>();
        
        for(Gruppo__c ug : usersGroups){
            usersGroupsIds.add(ug.Id);
        }
        
        for(Gruppo__c ag : allGroups){
            allGroupsIds.put(ag.Id, ag.Genitore__c);
        }
        
        Set<Id> parentGroupsIds = getParentGroupsRecursive(usersGroupsIds, allGroupsIds);
        
        for(Gruppo__c ag : allGroups){
            
            if(parentGroupsIds.contains(ag.Id)){
                
                parentGroups.add(ag);
                
            }
            
        }
        
        return parentGroups;
        
    }
    
    // Funzione ricorsiva per il recupero dei dati con approccio bottom -> top
    public static Set<Id> getParentGroupsRecursive(Set<Id> usersGroups, Map<Id, Id> allGroupsMap){
        
        Set<Id> parentIds = new Set<Id>();
        
        for(Id childId : allGroupsMap.keySet()){
            
            Id parentId = allGroupsMap.get(childId);
            
            if(usersGroups.contains(childId) && !usersGroups.contains(parentId) && parentId != null){
                
                parentIds.add(parentId);
                
            }
            
        }
        
        if(parentIds.size() > 0){
        
        	usersGroups.addAll(parentIds);
        
        	return getParentGroupsRecursive(usersGroups, allGroupsMap);
            
        }
        
        return usersGroups;
        
    }
    
    public static List<Gruppo__c> getChildGroups(List<Gruppo__c> usersGroups, List<Gruppo__c> allGroups){
        
        List<Gruppo__c> childGroups = new List<Gruppo__c>();
       	Set<Id> usersGroupsIds = new Set<Id>();
        Map<Id, Id> allGroupsIds = new Map<Id, Id>();
        
        for(Gruppo__c ug : usersGroups){
            usersGroupsIds.add(ug.Id);
        }
        
        for(Gruppo__c ag : allGroups){
            allGroupsIds.put(ag.Id, ag.Genitore__c);
        }
        
        Set<Id> childGroupsIds = getGhildGroupsRecursive(usersGroupsIds, allGroupsIds);
        
        for(Gruppo__c ag : allGroups){
            
            if(childGroupsIds.contains(ag.Id)){
                
                childGroups.add(ag);
                
            }
            
        }
        
        return childGroups;
        
    }
    
    // Funzione ricorsiva per il recupero dei dati con approccio top -> bottom
    public static Set<Id> getGhildGroupsRecursive(Set<Id> usersGroups, Map<Id, Id> allGroupsMap){
        
        Set<Id> childIds = new Set<Id>();
        
        System.debug(usersGroups);
        System.debug(allGroupsMap);
        
        for(Id childId : allGroupsMap.keySet()){
            
            Id parentId = allGroupsMap.get(childId);
            
            if(usersGroups.contains(parentId) && !usersGroups.contains(childId)){
                
                childIds.add(childId);
                
            }
            
        }
        
        System.debug(childIds);
        
        if(childIds.size() > 0){
        
        	usersGroups.addAll(childIds);
        
        	return getGhildGroupsRecursive(usersGroups, allGroupsMap);
            
        }
        
        return usersGroups;
        
    }
    
    public static List<Gruppo__c> getAllGroups(){
        
        return [SELECT Id, Genitore__c, Name, Tipologia__c, Sigla__c, Ordine__c, Url_Logo__c, Colore__c, Genitore__r.Genitore__c, Gruppo_Master__c 
                FROM Gruppo__c ORDER BY Ordine__c];
        
    }
    
    public static List<Gruppo__c> getUserGroups(Id userId, Boolean userIsDealer){

        if(userIsDealer){
            
            return [SELECT Id, Genitore__c, Name, Tipologia__c, Sigla__c, Ordine__c, Url_Logo__c, Colore__c, Genitore__r.Genitore__c, Gruppo_Master__c 
                    FROM Gruppo__c 
                    WHERE Id IN (SELECT Gruppo__c 
                                 FROM Utente_Gruppo__c 
                                 WHERE Utente__c = :userId AND Gruppo__r.Genitore__r.Genitore__r.Gruppo_Master__c = null)
                    ORDER BY Ordine__c];
            
        }
        
        return [SELECT Id, Genitore__c, Name, Tipologia__c, Sigla__c, Ordine__c, Url_Logo__c, Colore__c, Genitore__r.Genitore__c, Gruppo_Master__c 
                FROM Gruppo__c WHERE Id IN (SELECT Gruppo__c FROM Utente_Gruppo__c WHERE Utente__c = :userId) ORDER BY Ordine__c];
        
    }
    
    public static List<Gruppo__c> getGroupsByIds(List<Id> groupsIds){
        
        return [SELECT Id, Genitore__c, Name, Tipologia__c, Sigla__c, Ordine__c, Url_Logo__c, Colore__c, Genitore__r.Genitore__c, Gruppo_Master__c 
                FROM Gruppo__c WHERE Id IN :groupsIds ORDER BY Ordine__c];
        
    }
    
    public static List<Gruppo__c> filterGroupsByBrandId(List<Gruppo__c> groups, Id brandId){
        
        List<Gruppo__c> filtered = new List<Gruppo__c>();
        
        for(Gruppo__c g : groups){
            if(g.Genitore__r.Genitore__c == brandId){
                filtered.add(g);
            }
        }
        
        return filtered;
        
    }
    
    public static List<Gruppo__c> getUserGroupAncestors(String userId){
        
        List<Gruppo__c> allGroups = getAllGroups();
        List<Gruppo__c> userGroups = getUserGroups(userId, false);
        
        return getParentGroups(userGroups, allGroups);
        
    }
    
    public static List<Gruppo__c> getUserGroupChildren(String userId){
            
        List<Gruppo__c> allGroups = getAllGroups();
        List<Gruppo__c> userGroups = getUserGroups(userId, false);
        
        System.debug(userGroups);
        
        return getChildGroups(userGroups, allGroups);
        
    }
    
    public static List<Gruppo__c> getAllRelatedUserGroups(String userId){
            
        List<Gruppo__c> allGroups = getAllGroups();
        List<Gruppo__c> userGroups = getUserGroups(userId, false);
        List<Gruppo__c> relatedGroups = getParentGroups(userGroups, allGroups);
        relatedGroups.addAll(getChildGroups(userGroups, allGroups));
        
        return relatedGroups;
        
    }
    
    public static List<Utente_Gruppo__c> getActiveUsersGroupsByGroupsIds(Set<Id> groupsIds){
        
        return [SELECT Utente__c, Gruppo__c, Gruppo__r.Genitore__c, Gruppo__r.Genitore__r.Genitore__c FROM
                Utente_Gruppo__c WHERE Gruppo__c IN :groupsIds AND Utente__r.Non_Considerare_Analisi__c = false AND Utente__r.Tipologia__c = 'Dealer'];
        
    }

}