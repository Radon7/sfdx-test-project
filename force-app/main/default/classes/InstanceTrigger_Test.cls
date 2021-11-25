@isTest
private class InstanceTrigger_Test {
  
  @TestSetup
  static void makeData() {
    Account[] accs = new Account[]{new Account(Name = 'testAcc')};
    accs.add(new Account(Name = 'testAcc2'));
    insert accs;
    Instance__c[] insts = new Instance__c[]{}; 
    insts.add(new Instance__c(Account__c = accs[0].Id, Type__c = 'Trial', Licenses__c = 2));
    insts.add(new Instance__c(Account__c = accs[1].Id, Type__c = 'Standard', Licenses__c = 4));
    insert insts;
  }

  @IsTest
  static void testInsert () {
    Account acc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
    Account acc2 = [SELECT Id FROM Account WHERE Name = 'testAcc2'];
    Test.startTest();
    Instance__c[] insts = new Instance__c[]{}; 
    insts.add(new Instance__c(Account__c = acc.Id, Type__c = 'Standard', Licenses__c = 3));
    insts.add(new Instance__c(Account__c = acc2.Id, Type__c = 'Standard', Licenses__c = 4));
    insts.add(new Instance__c(Account__c = acc2.Id, Type__c = 'Trial', Licenses__c = 4));
    insert insts;
    Test.stopTest();
    System.assertEquals(3, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc'].TotalLicenses__c);
    System.assertEquals(8, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc2'].TotalLicenses__c);
  }

  @IsTest
  static void testUpdate(){
    Instance__c inst = [SELECT Id, Type__c FROM Instance__c WHERE Account__r.Name = 'testAcc'];
    Instance__c inst2 = [SELECT Id, Account__c, Licenses__c FROM Instance__c WHERE Account__r.Name = 'testAcc2'];
    Test.startTest();
    inst.Type__c = 'Standard';
    inst2.Licenses__c = 5;
    update new Instance__c[] {inst, inst2};
    Test.stopTest();
    System.assertEquals(2, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc'].TotalLicenses__c);
    System.assertEquals(5, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc2'].TotalLicenses__c);
    inst.Account__c = inst2.Account__c;
    update inst;
    System.assertEquals(0, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc'].TotalLicenses__c);
    System.assertEquals(7, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc2'].TotalLicenses__c);    
  }

  @IsTest
  static void testDelete(){
    Test.startTest();
    delete [SELECT Id FROM Instance__c WHERE Account__r.Name = 'testAcc2'];
    Test.stopTest();
    System.assertEquals(0, [SELECT TotalLicenses__c FROM Account WHERE Name = 'testAcc2'].TotalLicenses__c);    
  }
}