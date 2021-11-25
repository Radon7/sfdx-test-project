trigger InstanceTrigger on Instance__c (after insert, after update, after delete) {
  InstanceTriggerHandler.calculateLicenses(Trigger.new, Trigger.oldMap);
}