public class ChatUtils {
    
    public static void createChat(Object body, Id userId, Id appId, CustomResponse res){
        
        Map<String, Object> chatBody = (Map<String, Object>) body;
        
        Chat__c chat = new Chat__c();
        List<Utente_Chat__c> members = new List<Utente_Chat__c>();
        Set<Id> userIds = new Set<Id>();
        
        userIds.add(userId);
        
        chat.App__c = appId;
        chat.Proprietario__c = userId;
        
        List<Map<String, Object>> chatMembers;
        
        if(chatBody.containsKey('chat_title')){
            
            chat.Nome__c = (String) chatBody.get('chat_title');
            
        }
        
        if(chatBody.containsKey('chat_description')){
            
            chat.Descrizione__c = (String) chatBody.get('chat_description');
            
        }
        
        if(chatBody.containsKey('chat_area')){
            
            chat.Area__c = (String) chatBody.get('chat_area');
            
        }
        
        if(chatBody.containsKey('chat_image_url')){
            
            chat.URL_Immagine__c = (String) chatBody.get('chat_image_url');
            
        }
        
        if(chatBody.containsKey('chat_image_path')){
            
            chat.Riferimento_Immagine__c = (String) chatBody.get('chat_image_path');
            
        }
        
        chat.Tipologia__c = 'group';
        List<String> chatTypes = new List<String>{'group', 'direct', 'channel'};
        
        if(chatBody.containsKey('chat_type') && chatBody.get('chat_type') != null && chatTypes.contains((String) chatBody.get('chat_type'))){
            
            chat.Tipologia__c = (String) chatBody.get('chat_type');
            
        }
        
        if(chat.Tipologia__c == 'direct'){
            
            List<String> chatUsersIds = new List<String>{userId};
            
            if(chatBody.containsKey('members')){
            
            	List<Object> memberIds = (List<Object>) chatBody.get('members');
            
                for(Object memberId : memberIds){
                    
                    chatUsersIds.add((String) memberId);
                    
                }
                
            }
            
            List<Utente__c> chatUsers = [SELECT Id, Nome__c, Cognome__c FROM Utente__c WHERE Id IN :chatUsersIds];
            
            Utente__c creator;
            Utente__c host;
            
            for(Utente__c chatUser : chatUsers){
                
                if(chatUser.Id == userId){
                    creator = chatUser;
                }else{
                    host = chatUser;
                }
                
            }
            
            String creatorFullName = creator.Nome__c + ' ' + creator.Cognome__c;
            String hostFullName = host.Nome__c + ' ' + host.Cognome__c;
            
            chat.Nome__c = creator.Id + ':' + creatorFullName + '|' + host.Id + ':' +  + hostFullName;
            chat.Descrizione__c = 'Conversazione tra ' + creatorFullName + ' 3 ' + hostFullName;
            
        }
        
        try{
        
        	insert chat;
            
        }catch(Exception ex){
        
            res.setBody(ex.getMessage());
                
            res.setStatusCode(500);        
            res.send();
            
            return;
            
        }
                
        Utente_Chat__c admin = new Utente_Chat__c();
        
        admin.Chat__c = chat.Id;
        admin.Abilita_Notifiche__c = true;
        admin.Aggiunto_Da_Utente__c = userId;
        admin.Data_Ora_Aggiunta__c = System.now();
        admin.Utente__c = userId;
        admin.Abilita_Storico__c = true;
        admin.Aggiunto_Da_Utente__c = userId;
        admin.Ruolo_Chat__c = 'admin';
        
        members.add(admin);
        
        if(chatBody.containsKey('members')){
            
            List<Object> memberIds = (List<Object>) chatBody.get('members');
            
            for(Object memberId : memberIds){
                
                userIds.add((String) memberId);
                
                Utente_Chat__c userChat = new Utente_Chat__c();
                
                userChat.Chat__c = chat.Id;
                userChat.Abilita_Notifiche__c = true;
                userChat.Aggiunto_Da_Utente__c = userId;
                userChat.Data_Ora_Aggiunta__c = System.now();
                userChat.Ruolo_Chat__c = 'guest';
                userChat.Utente__c = (String) memberId;
                
                members.add(userChat);
                
            }
            
        }
        
        try{
        
        	insert members;
            
        }catch(Exception ex){
            
            //Database.rollback(sp);
        
            res.setBody(ex.getMessage());
                
            res.setStatusCode(500);        
            res.send();
            
            return;
            
        }
        
        res.setBody(getChatObjectById(chat.Id));
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static void updateChat(Object body, Id userId, Id chatId, CustomResponse res){
        
        Map<String, Object> chatBody = (Map<String, Object>) body;
        
        Chat__c chat = [SELECT Id, App__c, Area__c, Data_Ora_Chiusura__c, Data_Ora_Eliminazione__c, Descrizione__c, Nome__c, Proprietario__c, Tipologia__c, URL_Immagine__c,
                        LastModifiedDate, Riferimento_Immagine__c 
                        FROM Chat__c WHERE Id = :chatId LIMIT 1];
        
        Utente__c user = [SELECT Id, Nome__c, Cognome__c, Ragione_Sociale__c, Tipologia__c, Ruolo__c, URL_Foto__c, Riferimento_Immagine_Profilo__c, 
                                 (SELECT Id, Firebase_Token__c, Utente__c FROM Dispositivi__r) 
                                 FROM Utente__c 
                                 WHERE Id = :userId LIMIT 1];
        
        Utente_Chat__c userChat = [SELECT Id, Ruolo_Chat__c FROM Utente_Chat__c WHERE Utente__c = :userId AND Chat__c = :chatId];
        List<Utente_Chat__c> members = [SELECT Id, Chat__c, Ruolo_Chat__c, Utente__r.Azienda__c, Utente__r.Nome__c, Utente__r.Cognome__c, Utente__r.Tipologia__c, 
                                        Utente__r.Riferimento_Immagine_Profilo__c, Utente__c, Data_Ora_Aggiunta__c, Data_Ora_Rimozione__c, Abilita_Storico__c
                                        FROM Utente_Chat__c WHERE Chat__c = :chatId];
        
        String chatTitle;
        String chatDescription;
        String chatArea;
        String chatImageUrl;
        
        if(chatBody.containsKey('chat_title') && chat.Tipologia__c != 'direct'){
            
            chat.Nome__c = (String) chatBody.get('chat_title');
            
        }
        
        if(chatBody.containsKey('chat_description') && chat.Tipologia__c != 'direct'){
            
            chat.Descrizione__c = (String) chatBody.get('chat_description');
            
        }
        
        if(chatBody.containsKey('chat_area') && chat.Tipologia__c != 'direct'){
            
            chat.Area__c = (String) chatBody.get('chat_area');
            
        }
        
        if(chatBody.containsKey('chat_image_url') && chat.Tipologia__c != 'direct'){
            
            chat.URL_Immagine__c = (String) chatBody.get('chat_image_url');
            
        }
        
        if(chatBody.containsKey('chat_image_path') && chat.Tipologia__c != 'direct'){
            
            chat.Riferimento_Immagine__c = (String) chatBody.get('chat_image_path');
            
        }
        
        try{
        
        	update chat;
            
        }catch(Exception ex){
        
            res.setBody(ex.getMessage());
                
            res.setStatusCode(500);        
            res.send();
            
            return;
            
        }
        
        List<Object> messages = new List<Object>();
        
        QCloudFunctions.QFirebaseMessage data = new QCloudFunctions.QFirebaseMessage();
        
        data.setUserFields(user);
        data.setChatFields(chat);
        data.setUserChatFields(userChat);
        data.setChatMembersFields(members);
        
        data.message_type = 'update_chat_info';
        
        messages.add(data);
        
        QCloudFunctions.doRequest('/addMessages', 'POST', JSON.serialize(new Map<String, Object>{'messages' => messages}, false), null);
        
        res.setBody(getChatObjectById(chat.Id));
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static void addMembersToChat(Object body, Id userId, Id chatId, CustomResponse res){
        
        Utente_Chat__c currentUserChat = [SELECT Id, Ruolo_Chat__c FROM Utente_Chat__c WHERE Utente__c = :userId AND Chat__c = :chatId LIMIT 1];
        
        if(currentUserChat.Ruolo_Chat__c != 'admin'){
        
            res.setBody('Current user cannot add new members');
                
            res.setStatusCode(500);        
            res.send();
            
        }
        
        Chat__c chat = [SELECT Id, App__c, Area__c, Data_Ora_Chiusura__c, Data_Ora_Eliminazione__c, Descrizione__c, Nome__c, Proprietario__c, Tipologia__c, URL_Immagine__c,
                        LastModifiedDate, Riferimento_Immagine__c
                        FROM Chat__c WHERE Id = :chatId LIMIT 1];
        
        Utente__c user = [SELECT Id, Nome__c, Cognome__c, Ragione_Sociale__c, Tipologia__c, Ruolo__c, URL_Foto__c, Riferimento_Immagine_Profilo__c,
                          (SELECT Id, Firebase_Token__c, Utente__c FROM Dispositivi__r) 
                          FROM Utente__c 
                          WHERE Id = :userId LIMIT 1];
        
        Map<String, Object> chatBody = (Map<String, Object>) body;
        
        List<Utente_Chat__c> members = new List<Utente_Chat__c>();
        Set<Id> usersIds = new Set<Id>();
        
        if(chatBody.containsKey('members')){
            
            List<Object> membersObjects = (List<Object>) chatBody.get('members');
            
            for(Object memberObject : membersObjects){
                
                Map<String, Object> member = (Map<String, Object>) memberObject;
                
                Utente_Chat__c userChat = new Utente_Chat__c();
                
                userChat.Chat__c = chatId;
                userChat.Abilita_Storico__c = (Boolean) member.get('historyEnabled');
                userChat.Abilita_Notifiche__c = true;
                userChat.Aggiunto_Da_Utente__c = userId;
                userChat.Data_Ora_Aggiunta__c = System.now();
                userChat.Ruolo_Chat__c = 'guest';
                userChat.Utente__c = (String) member.get('userId');
                
                usersIds.add((String) member.get('userId'));
                
                members.add(userChat);
                
            }
            
        }
        
        List<Utente_Chat__c> existingMembers = [SELECT Id, Utente__c FROM Utente_Chat__c WHERE Utente__c IN :usersIds AND Chat__c = :chatId];
        
        for(Utente_Chat__c m : members){
            for(Utente_Chat__c em : existingMembers){
                if(m.Utente__c == em.Utente__c){
                    m.Id = em.Id;
                    m.Data_Ora_Rimozione__c = null;                 
                }
            }
        }
        
        try{
        
        	upsert members;
            
        }catch(Exception ex){
            
            //Database.rollback(sp);
        
            res.setBody(ex.getMessage());
                
            res.setStatusCode(500);        
            res.send();
            
            return;
            
        }
        
        res.setBody(members);
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static Map<String, Object> getChatObjectById(Id chatId){
        
        Chat__c chat = [SELECT Id, App__c, Area__c, Data_Ora_Chiusura__c, Data_Ora_Eliminazione__c, Descrizione__c, Nome__c,
                        Name, Proprietario__c, Tipologia__c, URL_Immagine__c, CreatedDate, Riferimento_Immagine__c,
                        (SELECT Id, Chat__c, Name, Abilita_Notifiche__c, Abilita_Storico__c, Aggiunto_Da_Utente__c, Data_Ora_Aggiunta__c, 
                         Data_Ora_Rimozione__c, Data_Ora_Ultimo_Accesso__c, Rimosso_Da_Utente__c, Ruolo_Chat__c, Utente__c, CreatedDate,
                         Utente__r.Dismesso__c, Utente__r.Azienda__c, Utente__r.App__c, Utente__r.Citta__c, Utente__r.Nome_Commerciale__c, 
                         Utente__r.Ragione_Sociale__c, Utente__r.Ruolo__c, Utente__r.Referente__c, Utente__r.Email__c, Utente__r.Nome__c, 
                         Utente__r.Cognome__c, Utente__r.Indirizzo_Sede_Legale__c, Utente__r.COD_CASA__c, Utente__r.Nickname__c, 
                         Utente__r.Non_Considerare_Analisi__c, Utente__r.Data_Ora_Accettazione_Privacy__c, Utente__r.URL_Foto__c, Utente__r.Provincia__c, 
                         Utente__r.CL_Fatturato__c, Utente__r.Tipologia__c, Utente__r.CL_Vendite__c, Utente__r.CL_Anzianita__c, Utente__r.Utente_Master__c, 
                         Utente__r.PIVA__c, Utente__r.CAP__c, Utente__r.Riferimento_Immagine_Profilo__c
                         FROM Utenti_Chat__r)
                        FROM Chat__c WHERE Id = :chatId LIMIT 1];
            
        Map<String, Object> o = new Map<String, Object>();
        List<Object> members = new List<Object>();
        
        o.put('id', chat.Id);
        o.put('appId', chat.App__c);
        o.put('title', chat.Nome__c);
        o.put('description', chat.Descrizione__c);
        o.put('area', chat.Area__c);
        o.put('imageUrl', chat.URL_Immagine__c);
        o.put('imagePath', chat.Riferimento_Immagine__c);
        o.put('ownerId', chat.Proprietario__c);
        o.put('type', chat.Tipologia__c);
        o.put('createdAt', chat.CreatedDate.getTime());
        o.put('closedAt', chat.Data_Ora_Chiusura__c != null ? chat.Data_Ora_Chiusura__c.getTime() : null);
        o.put('deletedAt', chat.Data_Ora_Eliminazione__c != null ? chat.Data_Ora_Eliminazione__c.getTime() : null);
        
        for(Utente_Chat__c uc : chat.Utenti_Chat__r){
            
            Map<String, Object> mo = new Map<String, Object>();
            
            UserData userData = new UserData();
            userData.fromUtenteChat(uc);
            
            mo.put('user', userData);
            mo.put('addedAt', uc.Data_Ora_Aggiunta__c != null ? uc.Data_Ora_Aggiunta__c.getTime() : null);
            mo.put('removedAt', uc.Data_Ora_Rimozione__c != null ? uc.Data_Ora_Rimozione__c.getTime() : null);
            mo.put('lastLogin', null);
            mo.put('historyEnabled', uc.Abilita_Storico__c);
            mo.put('role', uc.Ruolo_Chat__c);
            
            members.add(mo);
            
        }
        
        o.put('members', members);
        
        return o;
        
    }
    
    public static void findAllChats(Id userId, Id appId, CustomResponse res){
        
        List<Object> response = new List<Object>();
        
        List<Chat__c> chats = [SELECT Id, App__c, Area__c, Data_Ora_Chiusura__c, Data_Ora_Eliminazione__c, Descrizione__c, Nome__c,
                               Name, Proprietario__c, Tipologia__c, URL_Immagine__c, CreatedDate, Riferimento_Immagine__c,
                               (SELECT Id, Chat__c, Name, Abilita_Notifiche__c, Abilita_Storico__c, Aggiunto_Da_Utente__c, Data_Ora_Aggiunta__c, 
                                Data_Ora_Rimozione__c, Data_Ora_Ultimo_Accesso__c, Rimosso_Da_Utente__c, Ruolo_Chat__c, Utente__c, CreatedDate,
                                Utente__r.Dismesso__c, Utente__r.Azienda__c, Utente__r.App__c, Utente__r.Citta__c, Utente__r.Nome_Commerciale__c, 
                                Utente__r.Ragione_Sociale__c, Utente__r.Ruolo__c, Utente__r.Referente__c, Utente__r.Email__c, Utente__r.Nome__c, 
                                Utente__r.Cognome__c, Utente__r.Indirizzo_Sede_Legale__c, Utente__r.COD_CASA__c, Utente__r.Nickname__c, 
                                Utente__r.Non_Considerare_Analisi__c, Utente__r.Data_Ora_Accettazione_Privacy__c, Utente__r.URL_Foto__c, Utente__r.Provincia__c, 
                                Utente__r.CL_Fatturato__c, Utente__r.Tipologia__c, Utente__r.CL_Vendite__c, Utente__r.CL_Anzianita__c, Utente__r.Utente_Master__c, 
                                Utente__r.PIVA__c, Utente__r.CAP__c, Utente__r.Riferimento_Immagine_Profilo__c
                               FROM Utenti_Chat__r)
                               FROM Chat__c WHERE Id IN (SELECT Chat__c FROM Utente_Chat__c WHERE Utente__c = :userId)];
        
        for(Chat__c c : chats){
            
            Map<String, Object> o = new Map<String, Object>();
            List<Object> members = new List<Object>();
            
            o.put('id', c.Id);
            o.put('appId', c.App__c);
            o.put('title', c.Nome__c);
            o.put('description', c.Descrizione__c);
            o.put('area', c.Area__c);
            o.put('imageUrl', c.URL_Immagine__c);
            o.put('imagePath', c.Riferimento_Immagine__c);
            o.put('ownerId', c.Proprietario__c);
            o.put('type', c.Tipologia__c);
            o.put('createdAt', c.CreatedDate.getTime());
            o.put('closedAt', c.Data_Ora_Chiusura__c != null ? c.Data_Ora_Chiusura__c.getTime() : null);
            o.put('deletedAt', c.Data_Ora_Eliminazione__c != null ? c.Data_Ora_Eliminazione__c.getTime() : null);
            
            for(Utente_Chat__c uc : c.Utenti_Chat__r){
                
                Map<String, Object> mo = new Map<String, Object>();
                
                UserData userData = new UserData();
                userData.fromUtenteChat(uc);
                
                mo.put('user', userData);
                mo.put('addedAt', uc.Data_Ora_Aggiunta__c != null ? uc.Data_Ora_Aggiunta__c.getTime() : null);
                mo.put('removedAt', uc.Data_Ora_Rimozione__c != null ? uc.Data_Ora_Rimozione__c.getTime() : null);
                mo.put('lastLogin', null);
                mo.put('historyEnabled', uc.Abilita_Storico__c);
                mo.put('role', uc.Ruolo_Chat__c);
                
                members.add(mo);
                
            }
            
            o.put('members', members);
            
            /*o.put('role', c.Ruolo_Chat__c);            
            o.put('lastLogin', c.Data_Ora_Ultimo_Accesso__c != null ? c.Data_Ora_Ultimo_Accesso__c.getTime() : null);
            o.put('addedAt', c.Data_Ora_Aggiunta__c != null ? c.Data_Ora_Aggiunta__c.getTime() : null);
            o.put('notificationsEnabled', c.Abilita_Notifiche__c);*/
            
            response.add(o);
            
        }
        
        res.setBody(response);
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static void findAllMembers(Id userId, Id appId, CustomResponse res){
        
        List<Object> response = new List<Object>();
        
        List<Utente__c> users = [SELECT Id, Dismesso__c, Azienda__c, App__c, Citta__c, Nome_Commerciale__c, Ragione_Sociale__c, Ruolo__c,
                                 Referente__c, Email__c, Nome__c, Cognome__c, Indirizzo_Sede_Legale__c, COD_CASA__c, Nickname__c, 
                                 Non_Considerare_Analisi__c, Data_Ora_Accettazione_Privacy__c, URL_Foto__c, Provincia__c, CL_Fatturato__c, 
                                 Tipologia__c, CL_Vendite__c, CL_Anzianita__c, Utente_Master__c, PIVA__c, CAP__c, Utente_Demo__c, Riferimento_Immagine_Profilo__c
                                 FROM Utente__c WHERE App__c = :appId];
        
        Utente__c currentUser;
        
        for(Utente__c u : users){
            
            if(u.Id == userId){
                
                currentUser = u;
                
            }
            
        }
        
        for(Utente__c u : users){
            
            Map<String, Object> o = new Map<String, Object>();
            
            UserData userData = new UserData();
            userData.fromUtente(u);
            
            o.put('user', userData);
            o.put('addedAt', null);
            o.put('lastLogin', null);
            o.put('historyEnabled', null);
            o.put('role', null);
            
            if(currentUser.Id != u.Id && (!u.Utente_Demo__c || (u.Utente_Demo__c && currentUser.Utente_Demo__c))){
            
            	response.add(o);
                
            }
            
        }
            
        
        res.setBody(response);
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static List<Object> getChatMembers(Id chatId){
        
        List<Object> response = new List<Object>();
        
        List<Utente_Chat__c> usersChats = [SELECT Id, Chat__c, Utente__c, CreatedDate, Abilita_Storico__c, Ruolo_Chat__c, Data_Ora_Aggiunta__c,
                                           Utente__r.Dismesso__c, Utente__r.Azienda__c, Utente__r.App__c, Utente__r.Citta__c, Utente__r.Nome_Commerciale__c, 
                                           Utente__r.Ragione_Sociale__c, Utente__r.Ruolo__c, Utente__r.Referente__c, Utente__r.Email__c, Utente__r.Nome__c, 
                                           Utente__r.Cognome__c, Utente__r.Indirizzo_Sede_Legale__c, Utente__r.COD_CASA__c, Utente__r.Nickname__c, 
                                           Utente__r.Non_Considerare_Analisi__c, Utente__r.Data_Ora_Accettazione_Privacy__c, Utente__r.URL_Foto__c, Utente__r.Provincia__c, 
                                           Utente__r.CL_Fatturato__c, Utente__r.Tipologia__c, Utente__r.CL_Vendite__c, Utente__r.CL_Anzianita__c, Utente__r.Utente_Master__c, 
                                           Utente__r.PIVA__c, Utente__r.CAP__c, Utente__r.Riferimento_Immagine_Profilo__c
                                           FROM Utente_Chat__c WHERE Chat__c =: chatId AND Data_Ora_Rimozione__c = null];
        
        for(Utente_Chat__c uc : usersChats){
            
            Map<String, Object> o = new Map<String, Object>();
            
            UserData userData = new UserData();
            userData.fromUtenteChat(uc);
            
            o.put('id', uc.Id);
            o.put('user', userData);            
            o.put('addedAt', uc.Data_Ora_Aggiunta__c.getTime());
            o.put('lastLogin', null);
            o.put('historyEnabled', uc.Abilita_Storico__c);
            o.put('role', uc.Ruolo_Chat__c);
            
            response.add(o);
            
        }
        
        return response;
        
    }
    
    public static void findChatMembers(Id chatId, CustomResponse res){
        
        res.setBody(getChatMembers(chatId));
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    
    
    public static void findChatMember(Id chatId, Id memberId, CustomResponse res){

        try{
        
            Utente_Chat__c userChat = [SELECT Id, Chat__c, Utente__c, CreatedDate, Abilita_Storico__c, Ruolo_Chat__c, Data_Ora_Aggiunta__c,
                                       Utente__r.Dismesso__c, Utente__r.Azienda__c, Utente__r.App__c, Utente__r.Citta__c, Utente__r.Nome_Commerciale__c, 
                                       Utente__r.Ragione_Sociale__c, Utente__r.Ruolo__c, Utente__r.Referente__c, Utente__r.Email__c, Utente__r.Nome__c, 
                                       Utente__r.Cognome__c, Utente__r.Indirizzo_Sede_Legale__c, Utente__r.COD_CASA__c, Utente__r.Nickname__c, 
                                       Utente__r.Non_Considerare_Analisi__c, Utente__r.Data_Ora_Accettazione_Privacy__c, Utente__r.URL_Foto__c, Utente__r.Provincia__c, 
                                       Utente__r.CL_Fatturato__c, Utente__r.Tipologia__c, Utente__r.CL_Vendite__c, Utente__r.CL_Anzianita__c, Utente__r.Utente_Master__c, 
                                       Utente__r.PIVA__c, Utente__r.CAP__c, Utente__r.Riferimento_Immagine_Profilo__c
                                       FROM Utente_Chat__c WHERE Chat__c =: chatId AND Utente__c =:memberId LIMIT 1];
            
            Map<String, Object> o = new Map<String, Object>();
            
            UserData userData = new UserData();
            userData.fromUtenteChat(userChat);
            
            o.put('id', userChat.Id);
            o.put('user', userData);
            
            o.put('addedAt', userChat.Data_Ora_Aggiunta__c.getTime());
            o.put('lastLogin', null);
            o.put('historyEnabled', userChat.Abilita_Storico__c);
            o.put('role', userChat.Ruolo_Chat__c);
            
            res.setBody(o);            
            res.setStatusCode(200);
            
        }catch(Exception ex){
            
            res.setStatusCode(400);
            
        }            
                
        res.send();
        
    }
    
    public static void findChatMemberNotificationStatus(Id userId, Id appId, Id chatId, CustomResponse res){
        
        Boolean response = false;
        
        try{
            
            Utente_Chat__c userChat = [SELECT Id, Abilita_Notifiche__c FROM Utente_Chat__c WHERE Utente__c = :userId AND Chat__c = :chatId LIMIT 1];
            
            response = userChat.Abilita_Notifiche__c;
            
        }catch(Exception ex){
            
        }
        
        res.setBody(response);
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static void toggleChatMemberNotificationStatus(Id userId, Id appId, Id chatId, CustomResponse res){
        
        Boolean response = false;
        
        try{
            
            Utente_Chat__c userChat = [SELECT Id, Abilita_Notifiche__c FROM Utente_Chat__c WHERE Utente__c = :userId AND Chat__c = :chatId LIMIT 1];
            
            userChat.Abilita_Notifiche__c = !userChat.Abilita_Notifiche__c;
            
            update userChat;
            
            response = userChat.Abilita_Notifiche__c;
            
        }catch(Exception ex){
            
        }
        
        res.setBody(response);
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static void exitChatMemberFromChat(Id userId, Id appId, Id chatId, Id memberId, CustomResponse res){
        
        Boolean response = false;
        
        Utente_Chat__c currentUserChat = [SELECT Id, Ruolo_Chat__c FROM Utente_Chat__c WHERE Utente__c = :userId AND Chat__c = :chatId LIMIT 1];
        
        if(currentUserChat.Ruolo_Chat__c != 'admin' && currentUserChat.Id != memberId){
        
            res.setBody('Current user cannot exit another member');
                
            res.setStatusCode(500);        
            res.send();
            
        }
        
        try{
            
            Utente_Chat__c userChat = [SELECT Id, Data_Ora_Rimozione__c, Abilita_Notifiche__c FROM Utente_Chat__c WHERE Id = :memberId AND Chat__c = :chatId LIMIT 1];
            
            userChat.Data_Ora_Rimozione__c = System.now();
            userChat.Abilita_Notifiche__c = false;
            
            update userChat;
            
            response = true;
            
        }catch(Exception ex){
        
            res.setBody(ex.getMessage());
                
            res.setStatusCode(500);        
            res.send();
            
        }
        
        res.setBody(response);
            
        res.setStatusCode(200);        
        res.send();
        
    }
    
    public static void toggleAdmin(Id userId, Id appId, Id chatId, Id memberId, CustomResponse res){
        
        Utente_Chat__c currentUserChat = [SELECT Id, Ruolo_Chat__c FROM Utente_Chat__c WHERE Utente__c = :userId AND Chat__c = :chatId LIMIT 1];
        
        if(currentUserChat.Ruolo_Chat__c != 'admin' && currentUserChat.Id != memberId){
        
            res.setBody('Current user cannot change another member role');
                
            res.setStatusCode(500);        
            res.send();
            
            return;
            
        }
        
        try{
            
            Utente_Chat__c userChat = [SELECT Id, Ruolo_Chat__c FROM Utente_Chat__c WHERE Id = :memberId AND Chat__c = :chatId LIMIT 1];
            
            userChat.Ruolo_Chat__c = 'admin'.equals(userChat.Ruolo_Chat__c) ? 'guest' : 'admin';
            
            update userChat;
            
        }catch(Exception ex){
        
            res.setBody(ex.getMessage());                
            res.setStatusCode(500);         
        	res.send();
            
            return;
            
        }
        
        res.setBody(true);            
        res.setStatusCode(200);  
        
        res.send();
        
    }

}