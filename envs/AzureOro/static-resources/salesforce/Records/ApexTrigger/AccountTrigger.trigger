trigger AccountTrigger on Account (

    before insert,

    before update,

    before delete,

    after insert,

    after update,

    after delete,

    after undelete)

{

        if (Trigger.isBefore)

        {

 			if(Trigger.isUpdate)

            {

                

            }

            else if(Trigger.isInsert)

            {

                

            }

            else if(Trigger.isDelete)

            {

                AccountUtil.handleBeforeDelete(Trigger.old);

            }

        }

        else if (Trigger.isAfter)

        {

            if(Trigger.isInsert)

            {    
				AccountUtil.searchAndMergeAccounts(Trigger.new);
            }          

            if(Trigger.isUpdate)

            {
				//AccountUtil.searchAndMergeAccounts(Trigger.new);
            }

        }

}