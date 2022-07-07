public class UtenteChatUtils {
    
    //private static String cloudFunctionsUrl = 'https://us-central1-tmi-rcc-dev.cloudfunctions.net';
    //private static String secretKey = 'FC87870580712462C0577DDA12D77B041B81DE5F58200EBFCE86C0B835057C02';    
    
    public static void insertFromTrigger(Map<Id, Utente_Chat__c> membersMap){
        
        Map<Id, Boolean> membersToAdd = new Map<Id, Boolean>();
        
        for(Id memberId : membersMap.keySet()){
            membersToAdd.put(memberId, true);
        }
        
        addOrRemoveMembers(membersMap, membersToAdd);
        
    }
    
    public static void updateFromTrigger(Map<Id, Utente_Chat__c> newUsersChatsMap, Map<Id, Utente_Chat__c> oldUsersChatsMap){
        
        Map<Id, Utente_Chat__c> membersToAddOrRemoveList = new Map<Id, Utente_Chat__c>();
        Map<Id, Boolean> membersToAddOrRemove = new Map<Id, Boolean>();
        
        for(String key : newUsersChatsMap.keySet()){
            
            Utente_Chat__c newUsersChats = newUsersChatsMap.get(key);
            Utente_Chat__c oldUsersChats = oldUsersChatsMap.get(key);
            
            if(newUsersChats.Data_Ora_Rimozione__c != null && oldUsersChats.Data_Ora_Rimozione__c == null){
                
                membersToAddOrRemoveList.put(newUsersChats.Id, newUsersChats);
                membersToAddOrRemove.put(newUsersChats.Id, false);
                
            }
            
            if(newUsersChats.Data_Ora_Rimozione__c == null && oldUsersChats.Data_Ora_Rimozione__c != null){
                
                membersToAddOrRemoveList.put(newUsersChats.Id, newUsersChats);
                membersToAddOrRemove.put(newUsersChats.Id, true);
                
            }
            
            
        }
        
        if(membersToAddOrRemoveList.size() > 0){
            
            addOrRemoveMembers(membersToAddOrRemoveList, membersToAddOrRemove);
                
        }
        
    }
    
    private static void addOrRemoveMembers(Map<Id, Utente_Chat__c> membersMap, Map<Id, Boolean> userToAddOrRemove){
        
        Set<Id> userIds = new Set<Id>();
        Set<Id> chatIds = new Set<Id>();
        
        for(String key : membersMap.keySet()){
            userIds.add(membersMap.get(key).Utente__c);
            chatIds.add(membersMap.get(key).Chat__c);
        }
        
        Map<Id, Utente__c> userMap = getUserMapByIds(userIds);        
        Map<Id, Chat__c> chatMap = getChatMapByIds(chatIds);        
        
        List<Object> messages = new List<Object>();        
        
        List<Utente_Chat__c> members = [SELECT Id, Chat__c, Ruolo_Chat__c, Utente__r.Azienda__c, Utente__r.Nome__c, Utente__r.Cognome__c, Utente__r.Tipologia__c, 
                                        Utente__r.Riferimento_Immagine_Profilo__c, Utente__c, Data_Ora_Aggiunta__c, Data_Ora_Rimozione__c, Abilita_Storico__c
                                        FROM Utente_Chat__c WHERE Chat__c IN :chatIds];
        
        for(String key : membersMap.keySet()){
            
            Utente_Chat__c member = membersMap.get(key);
            
            Utente__c currentUser;
            Chat__c currentChat;
            
            if(userMap.containsKey(member.Utente__c)){
                
                currentUser = userMap.get(member.Utente__c);
                
            }
            
            if(chatMap.containsKey(member.Chat__c)){
                
                currentChat = chatMap.get(member.Chat__c);
                
            }
            
            QCloudFunctions.QFirebaseMessage data = new QCloudFunctions.QFirebaseMessage();
            
            data.setUserFields(currentUser);
            data.setChatFields(currentChat);
            data.setUserChatFields(member);
            
            List<Utente_Chat__c> chatMembers = new List<Utente_Chat__c>();
            
            for(Utente_Chat__c chatMember : members){
                
                if(chatMember.Chat__c == member.Chat__c){
                    
                    chatMembers.add(chatMember);
                    
                }                
                
            }
            
        	data.setChatMembersFields(chatMembers);            
            
            data.message_type = userToAddOrRemove.get(key) ? 'add_to_chat' : 'remove_from_chat';
            
            messages.add(data);
        }
        
        QCloudFunctions.doRequest('/addMessages', 'POST', JSON.serialize(new Map<String, Object>{'messages' => messages}, false), null);
        
        sendMailLog(JSON.serialize(new Map<String, Object>{'messages' => messages}));
        
    }
    
    private static Map<Id, Utente__c> getUserMapByIds(Set<Id> usersIds){
        Map<Id, Utente__c> out = new Map<Id, Utente__c>();
        List<Utente__c> users = [SELECT Id, Nome__c, Cognome__c, Ragione_Sociale__c, Tipologia__c, Ruolo__c, URL_Foto__c, Riferimento_Immagine_Profilo__c,
                                 (SELECT Id, Firebase_Token__c, Utente__c FROM Dispositivi__r) 
                                 FROM Utente__c 
                                 WHERE Id IN :usersIds];
        
        for(Utente__c u : users){
            
            out.put(u.Id, u);
            
        }
        
        return out;
    }
    
    private static Map<Id, Chat__c> getChatMapByIds(Set<Id> chatsIds){
        Map<Id, Chat__c> out = new Map<Id, Chat__c>();
        List<Chat__c> chats = [SELECT Id, App__c, Area__c, Data_Ora_Chiusura__c, Data_Ora_Eliminazione__c, Descrizione__c, Nome__c, Proprietario__c, Tipologia__c, URL_Immagine__c,
                               Riferimento_Immagine__c, LastModifiedDate 
                               FROM Chat__c WHERE Id IN :chatsIds];
        
        for(Chat__c c : chats){
            
            out.put(c.Id, c);
            
        }
        return out;
    }
    
    @future
    private static void sendMailLog(String body){
        
        Map<String, Object> mailConf = new Map<String, Object>();
        
        mailConf.put('senderName', 'Francesco');
        mailConf.put('subject', 'Log - UtenteChatUtils');
        mailConf.put('htmlBody', body);
        mailConf.put('textBody', body);
        mailConf.put('attachment', null);
        mailConf.put('recipients', new List<String>{'francesco.marchesin@quintegia.it'});
        
        QUtilities.sendMail(mailConf);
        
    }
    
}