public class QCloudFunctions {
    
    private static String cloudFunctionsUrl = TMI_RCC__c.getOrgDefaults().Google_Cloud_Functions_URL__c;
    private static String secretKey = TMI_RCC__c.getOrgDefaults().Secret_Key__c;
    
    @future(callout = true)
    public static void doRequest(String endpoint, String method, String requestBody, Map<String, String> headers){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cloudFunctionsUrl + endpoint);
        req.setMethod(method.toUpperCase());
        
        JWT jwt = new JWT();
        jwt.setKey(secretKey);
        
        System.debug(requestBody);
        
        req.setHeader('X-Bearer-Token', jwt.encode(new Map<String, Object>{'endpoint' => endpoint}, 60 * 5));
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        req.setBody(requestBody);
        
        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        
        System.debug(res.getBody());
        
    }
    
    public class QFirebaseMessageNotificationPayload{
        
        public String title;
        public String body;
        
        public QFirebaseMessageNotificationPayload(){}
        
    }
    
    public class QFirebaseMessagePayload{
        
        public QFirebaseMessagePayload(){}
        
    }
    
    public class QFirebaseMessageUserPayload{
        
        public String id;
        public String user_id;
        public Boolean history;
        public Long created_at;
        public Long deleted_at;
        public String company_name;
        public String first_name;
        public String last_name;
        public String img;
        public String role;
        public String user_type;
        
        public QFirebaseMessageUserPayload(){}
        
    }
    
    public class QFirebaseMessageChatPayload{
        
        public String id;
        public String app_id;
        public String area;
        public Long closed_at;
        public Long updated_at;
        public Long deleted_at;
        public String description;
        public String title;
        public String owner_id;
        public String chat_type;
        public String image_url;
        public String image_path;
        public List<QFirebaseMessageUserPayload> members = new List<QFirebaseMessageUserPayload>();
        
        public QFirebaseMessageChatPayload(){}       
        
    }
    
    public class QFirebaseMessage{
        
        public String app_id;
        public String chat_id;
        public String chat_role;
        public Long created_at = System.now().getTime() * 1000;
        public Long deleted_at;
        public Long updated_at;
        public String message_category = 'system';
        public String message_type;
        public Boolean notify = false;
        public String user_id;
        public Boolean history = true;
        
        public List<String> user_fcm_tokens = new List<String>();
        
        public QFirebaseMessageNotificationPayload notification_payload = new QFirebaseMessageNotificationPayload();
        public QFirebaseMessagePayload payload = new QFirebaseMessagePayload();
        public QFirebaseMessageUserPayload user_payload = new QFirebaseMessageUserPayload();
        public QFirebaseMessageChatPayload chat_payload = new QFirebaseMessageChatPayload();
        
        public QFirebaseMessage(){}
        
        public void setUserFields(Utente__c user){
            
            if(user != null){
                
            	this.user_id = user.Id;
                
                this.user_payload.company_name = user.Ragione_Sociale__c;
                this.user_payload.first_name = user.Nome__c;
                this.user_payload.img = user.URL_Foto__c;
                this.user_payload.last_name = user.Cognome__c;
                this.user_payload.role = user.Ruolo__c;
                this.user_payload.user_type = user.Tipologia__c;
                
                for(Dispositivo__c d : user.Dispositivi__r){
                    
                    this.user_fcm_tokens.add(d.Firebase_Token__c);
                    
                }
                
            }
            
        }
        
        public void setChatFields(Chat__c chat){            
            
            this.app_id = chat.App__c;
            this.chat_id = chat.Id;
            
            this.chat_payload.id = chat.Id;
            this.chat_payload.app_id = chat.App__c;
            this.chat_payload.area = chat.Area__c;
            this.chat_payload.closed_at = chat.Data_Ora_Chiusura__c != null ? chat.Data_Ora_Chiusura__c.getTime() : null;
            this.chat_payload.updated_at = chat.LastModifiedDate != null ? chat.LastModifiedDate.getTime() : null;
            this.chat_payload.deleted_at = chat.Data_Ora_Eliminazione__c != null ? chat.Data_Ora_Eliminazione__c.getTime() : null;
            this.chat_payload.description = chat.Descrizione__c;
            this.chat_payload.title = chat.Nome__c;
            this.chat_payload.owner_id = chat.Proprietario__c;
            this.chat_payload.chat_type = chat.Tipologia__c;
            this.chat_payload.image_url = chat.URL_Immagine__c;
            this.chat_payload.image_path = chat.Riferimento_Immagine__c;
            
        }
        
        public void setUserChatFields(Utente_Chat__c userChat){    
            
            this.chat_role = userChat.Ruolo_Chat__c;
            
        }
        
        public void setChatMembersFields(List<Utente_Chat__c> members){    
            
            for(Utente_Chat__c member : members){
                
                QFirebaseMessageUserPayload userPayload = new QFirebaseMessageUserPayload();
                
                userPayload.company_name = member.Utente__r.Azienda__c;
                userPayload.first_name = member.Utente__r.Nome__c;
                userPayload.last_name = member.Utente__r.Cognome__c;
                userPayload.img = member.Utente__r.Riferimento_Immagine_Profilo__c;
                userPayload.role = member.Ruolo_Chat__c;
                userPayload.user_type = member.Utente__r.Tipologia__c;
                userPayload.id = member.Id;
                userPayload.user_id = member.Utente__c;
                userPayload.history = member.Abilita_Storico__c;
                userPayload.created_at = member.Data_Ora_Aggiunta__c != null ? member.Data_Ora_Aggiunta__c.getTime() : null;
                userPayload.deleted_at = member.Data_Ora_Rimozione__c != null ? member.Data_Ora_Rimozione__c.getTime() : null;
                
                this.chat_payload.members.add(userPayload);
            }
            
        }
        
    }

}