@RestResource(urlMapping='/password_reset/*')
global class PasswordResetResource {
    
    @HttpPost
    global static void doPost(){
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
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
        
        String nicknameOrEmail = (String) decodedBody.get('usernameOrEmail');
        
        if(String.isBlank(nicknameOrEmail)){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Campo obbligatorio.'});
            res.send();
            
            return;
            
        }
        
        Utente__c foundUser;
        String appId = RestContext.request.headers.get('x-app-id');
        
        try{
            
            foundUser = [SELECT Id, Nickname__c, Email__c FROM Utente__c WHERE App__c = :appId AND (Nickname__c = :nicknameOrEmail OR Email__c = :nicknameOrEmail) LIMIT 1];
            
        }catch(Exception ex){
            
            System.debug(ex.getMessage());
            
        }
        
        if(foundUser == null){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Utente non trovato.'});
            res.send();
            
            return;
            
        }
            
        Map<String, Object> conf = new Map<String, Object>();
        String newPassword = generateRandomString(8);
        
        conf.put('senderName', 'TMI Channel');
        conf.put('subject', 'Nuova Password Provvisoria');
        conf.put('htmlBody', '<p>Le tue nuove credenziali di accesso:</p><p><strong>Utente:</strong> ' + foundUser.Nickname__c + '<br/><strong>Password:</strong> ' + newPassword + '</p>');
        conf.put('textBody', 'Le tue nuove credenziali di accesso:\r\n\r\nUtente: ' + foundUser.Nickname__c + '\r\nPassword: ' + newPassword);
        conf.put('recipients', new List<String>{foundUser.Email__c});
        
        Boolean sent = false;
        
        try{
            sent = QUtilities.sendMail(conf);
        }catch(Exception ex){
            
        }
        
        if(!sent){
            
            res.setStatusCode(500);
            res.setBody(new Map<String, Object>{'error' => 'Errore.'});
            res.send();
            
            return;
            
        }
            
        List<Dispositivo__c> devices = [SELECT Id, Dispositivo__c, Token__c FROM Dispositivo__c WHERE Utente__c = :foundUser.Id];
        
        for(Dispositivo__c device : devices){
            
            device.Token__c = null;
            
        }
        
        update devices;
        
        foundUser.Password__c = newPassword;
        
        update foundUser;
        
        res.setBody(true);
        res.send();
        
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

}