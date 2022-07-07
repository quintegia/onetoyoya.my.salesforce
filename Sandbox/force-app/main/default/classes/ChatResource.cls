@RestResource(urlMapping='/chats/*')
global class ChatResource {
    
    @HttpGet
    global static void doGet(){
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
            
            return;
            
        }
        
        String userId = ca.getUser().Id;
        String appId = ca.getAppId();
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        //String action = getAction();
        
        String requestPath = getRequestPath();
        
        System.debug(requestPath);
        
        if(match('/chats', requestPath).matches()){
            
            ChatUtils.findAllChats(userId, appId, res);
            
            return;
            
        }else if(match('/chats/members', requestPath).matches()){
            
            ChatUtils.findAllMembers(userId, appId, res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/members', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/members', requestPath);
            m.matches();
            
            ChatUtils.findChatMembers(m.group(1), res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/notifications', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/notifications', requestPath);
            m.matches();
            
            ChatUtils.findChatMemberNotificationStatus(userId, appId, m.group(1), res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/members/([\\w]*)', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/members/([\\w]*)', requestPath);
            m.matches();
            
            ChatUtils.findChatMember(m.group(1), m.group(2), res);
            
            return;
            
        }
        
        res.setBody('Not Found.');        
        res.setStatusCode(400);        
        res.send();
        
    }
    
    @HttpPost
    global static void doPost(){          
        
        CustomAuthentication ca = new CustomAuthentication(RestContext.request, RestContext.response);
        
        if(!ca.authenticate()){
            
            ca.getResponse().send();
            
            return;
            
        }
        
        String userId = ca.getUser().Id;
        String appId = ca.getAppId();
        
        //String userId = 'a4n0E000000Q8BuQAK';
        //String appId = 'a4l0E000000DvYeQAK';
        
        CustomResponse res = new CustomResponse(RestContext.response);
        
        String requestPath = getRequestPath();
        
        System.debug(requestPath);
        
        Object body = getBody();
        
        if(match('/chats', requestPath).matches()){
            
            ChatUtils.createChat(body, userId, appId, res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/members/([\\w]*)/exit', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/members/([\\w]*)/exit', requestPath);
            m.matches();
            
            ChatUtils.exitChatMemberFromChat(userId, appId, m.group(1), m.group(2), res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/notifications', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/notifications', requestPath);
            m.matches();
            
            ChatUtils.toggleChatMemberNotificationStatus(userId, appId, m.group(1), res);
            
            return;
            
        }else if(match('/chats/([\\w]*)', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)', requestPath);
            m.matches();
            
            ChatUtils.updateChat(body, userId, m.group(1), res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/members', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/members', requestPath);
            m.matches();
            
            ChatUtils.addMembersToChat(body, userId, m.group(1), res);
            
            return;
            
        }else if(match('/chats/([\\w]*)/members/([\\w]*)/toggleAdmin', requestPath).matches()){
            
            Matcher m = match('/chats/([\\w]*)/members/([\\w]*)/toggleAdmin', requestPath);
            m.matches();
            
            ChatUtils.toggleAdmin(userId, appId, m.group(1), m.group(2), res);
            
            return;
            
        }
        
        res.setBody('Not Found.');        
        res.setStatusCode(400);        
        res.send();
        
    }
    
    /*@HttpPut
    global static void doPut(){
        
    }
    
    @HttpPatch
    global static void doPatch(){
        
    }
    
    @HttpDelete
    global static void doDelete(){
        
    }*/
    
    public static Matcher match(String regex, String text){
        
        Pattern myPattern = Pattern.compile(regex); 
        Matcher myMatcher = myPattern.matcher(text);
        
        return myMatcher;

    }
    
    private static String getRequestPath(){
        
        return RestContext.request.requestURI;
        
    }
    
    private static Object getBody(){
        if(RestContext.request.requestBody == null){  
            
            return null;
            
        }
        
        try{
            
            return JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            
        }catch(Exception ex){
            
            return null;
            
        }
            
        
    }

}