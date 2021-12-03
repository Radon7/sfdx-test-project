public without sharing class InstanceTriggerHandler {
  // Set a couple of constants to help code cleaness
  private static final String[] UPDATE_FIELDS = new String[]{
    'Type__c', 'Pippo',
    'Licenses__c',
    'Account__c'
  };
  private static final String ACC_FIELD = 'Account__c';

  /**
   * @description "Roll-up" license on account from Instances when some fields change
   * @param  newInstances    new instances (empty or null on delete)
   * @param  oldInstancesMap old instances map (empty or null on insert)
   */
  public static void calculateLicenses(Instance__c[] newInstances, Map<Id, Instance__c> oldInstancesMap) {
    Set<Id> accIds = getAccountIds(newInstances, oldInstancesMap);
    if (accIds.isEmpty()) return;
    Map<Id, Integer> licenseMap = getLicensesByAccount(accIds);
    Account[] accsToUpdate = new Account[]{};
    for (Id accId : accIds) {
      accsToUpdate.add(new Account(
        Id = accId,
        TotalLicenses__c = licenseMap.containsKey(accId) ? licenseMap.get(accId) : 0
      ));
    }
    update accsToUpdate;
  }

  /**
   * @description Helper method to filter and return relevant account ids
   * @param  newInstances    new instances
   * @param  oldInstancesMap old map instances
   * @return                 Set<Id> of account ids that needs to be recalculated
   */
  private static Set<Id> getAccountIds(Instance__c[] newInstances, Map<Id, Instance__c> oldInstancesMap) {
    Set<Id> accIds = new Set<Id>();
    for (Instance__c inst : getChangedInstances(newInstances, oldInstancesMap)) {
      accIds.add(inst.Account__c);
    }
    return accIds;
  }

  /**
   * @description Get changed instances based on the constants defined before. 
   * if account is changed it is added both the old and the new
   * @param  newInstances    new instances
   * @param  oldInstancesMap old instances map 
   * @return                 list of all instaces changed.
   */
  private static Instance__c[] getChangedInstances(Instance__c[] newInstances, Map<Id, Instance__c> oldInstancesMap) {
    if (newInstances == null || newInstances.isEmpty()) return oldInstancesMap.values();
    if (oldInstancesMap == null || oldInstancesMap.keySet().isEmpty()) return newInstances;
    Instance__c[] changed = new Instance__c[]{};
    for (Instance__c inst : newInstances) {
      Instance__c oldInst = oldInstancesMap.get(inst.Id);
      if (isChanged(inst, oldInst)) {
        changed.add(inst);
      }
      if (inst.get(ACC_FIELD) != oldInst.get(ACC_FIELD)) {
        changed.add(oldInst);
      }
    }
    return changed;
  }

  /**
   * @description Check if a record is changed based on the field provided above
   * @param  inst1 Instance
   * @param  inst2 Instance
   * @return       true if at least one field has changed
   */
  private static Boolean isChanged(Instance__c inst1, Instance__c inst2) {
    for (String field : UPDATE_FIELDS) {
      if (inst1.get(field) != inst2.get(field)) return true;
    }
    return false;
  }

  /**
   * @description getLicensesByAccount description
   * @param  accIds accIds description
   * @return        return description
   */
  private static Map<Id, Integer> getLicensesByAccount(Set<Id> accIds) {
    Map<Id, Integer> totLicensesMap = new Map<Id, Integer>();
    AggregateResult[] licenseByAcc = [
      SELECT SUM(Licenses__c) Total, Account__c
      FROM Instance__c
      WHERE Account__c IN :accIds
      AND Type__c = 'Standard'
      GROUP BY Account__c
    ];
    for (AggregateResult ar : licenseByAcc) {
      totLicensesMap.put(
        (Id) ar.get('Account__c'), 
        Integer.valueOf(ar.get('Total'))
      );
    }
    return totLicensesMap;
  }
}
