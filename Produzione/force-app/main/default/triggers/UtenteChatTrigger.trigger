trigger UtenteChatTrigger on Utente_Chat__c (after insert, after update, after delete) {
    
    if(Trigger.isInsert){
        
        UtenteChatUtils.insertFromTrigger(Trigger.newMap);
        
    }else if(Trigger.isUpdate){
        
        UtenteChatUtils.updateFromTrigger(Trigger.newMap, Trigger.oldMap);
        
    }/*else if(Trigger.isDelete){
        
        UtenteChatUtils.deleteFromTrigger(Trigger.newMap, Trigger.oldMap);
        
    }*/

}