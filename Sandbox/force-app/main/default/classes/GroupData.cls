public class GroupData {
    
    public String id;
    public String parentId;
    public String name;
    public String shortName;
    public String groupType;
    public String color;
    public String logoUrl;
    public Decimal order;

    public GroupData(Gruppo__c g){
        
        this.id = g.Id;
        this.parentId = g.Genitore__c;
        this.name = g.Name;
        this.shortName = g.Sigla__c;
        this.groupType = g.Tipologia__c;
        this.color = g.Colore__c;
        this.logoUrl = g.URL_Logo__c;
        this.order = g.Ordine__c;
        
    }

}