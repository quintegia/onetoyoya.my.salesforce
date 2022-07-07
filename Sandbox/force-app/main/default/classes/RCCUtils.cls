// @internal Controlla versione original_dev_2021
public class RCCUtils {
    // Recupera l'utente in base al suo id
    public static Utente__c findUserById(Id userId) {
        Utente__c u = null;

        try {
            u = [SELECT Id FROM Utente__c WHERE Id = :userId LIMIT 1];
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }

        return u;
    }

    public static List<Gruppo__c> findUserBrandsByUserId(Id userId) {
        Set<Id> userGroups = findUserGroupsByUserId(userId, true);

        return [
            SELECT Id, Name
            FROM Gruppo__c
            WHERE Id IN :userGroups AND Tipologia__c = 'Marchio'
            ORDER BY Ordine__c ASC
        ];
    }

    // Recupera i gruppi in base all'utente
    public static Set<Id> findUserGroupsByUserId(
        Id userId,
        Boolean limitToBrands
    ) {
        List<Utente_Gruppo__c> userGroups = [
            SELECT Id, Gruppo__c, Gruppo__r.Name
            FROM Utente_Gruppo__c
            WHERE Utente__c = :userId
        ];
        List<Gruppo__c> allGroups = [
            SELECT Id, Genitore__c, Name, Genitore__r.Name
            FROM Gruppo__c
            ORDER BY Genitore__c DESC
        ];

        Map<Id, Id> allGroupsMap = new Map<Id, Id>();
        Set<Id> userGroupsIds = new Set<Id>();

        for (Utente_Gruppo__c ug : userGroups) {
            userGroupsIds.add(ug.Gruppo__c);
        }

        Id rootGroup = null;

        for (Gruppo__c g : allGroups) {
            if (g.Genitore__c == null) {
                rootGroup = g.Id;
            }

            if (g.Genitore__c != rootGroup || !limitToBrands) {
                allGroupsMap.put(g.Id, g.Genitore__c);
            }
        }

        return findUserGroupsRecursive(userGroupsIds, allGroupsMap);
    }

    // Funzione ricorsiva per il recupero dei dati con approccio bottom -> top
    public static Set<Id> findUserGroupsRecursive(
        Set<Id> userGroups,
        Map<Id, Id> allGroupsMap
    ) {
        Set<Id> parentIds = new Set<Id>();

        for (Id childId : allGroupsMap.keySet()) {
            Id parentId = allGroupsMap.get(childId);

            if (
                userGroups.contains(childId) &&
                !userGroups.contains(parentId) &&
                parentId != null
            ) {
                parentIds.add(parentId);
            }
        }

        if (parentIds.size() > 0) {
            userGroups.addAll(parentIds);

            return findUserGroupsRecursive(userGroups, allGroupsMap);
        }

        return userGroups;
    }

    public static String dateFormat(Date currentDate) {
        List<String> months = new List<String>();

        months.add('Gennaio');
        months.add('Febbraio');
        months.add('Marzo');
        months.add('Aprile');
        months.add('Maggio');
        months.add('Giugno');
        months.add('Luglio');
        months.add('Agosto');
        months.add('Settembre');
        months.add('Ottobre');
        months.add('Novembre');
        months.add('Dicembre');

        return String.valueOf(currentDate.day()) +
            ' ' +
            months.get(currentDate.month() - 1) +
            ' ' +
            String.valueOf(currentDate.year());
    }
}