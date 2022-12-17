# InsurePlus
InsurePlus is a tool intended to be used by Insurance Claim Specialists.

Claim Specialists are tasked with regularly using a Reserving Tool to help them estimate how much a given claim is going to cost the company.
There are lots of guidelines on how frequently an examiner should be using the Reserving Tool. An examiner has to use the reserving tool a 
certain number of days after the claim re-opens, after being assigned the claim, or after an examiner last used the Reserving Tool on that claim.

In essence, InsurePlus comprises a Stored Procedure which determines show long an examiner has until they are required to use the Reserving Tool;
and if they are already past their due date, how many days they have been overdue. This is done for all the claims assigned to all
the Claim Specialists using the Reserve Tool in an insurance organisation.

Step 1:
The first step of this project is to write 3 queries, which gives us:
1. the last date a claimant re-opened claim
2. the date an examiner was assigned a claim
3. the last date an examiner published on the Reserving Tool for each claim

Step 2:
I. Joining fields from different tables in the database
II. Filtering out claims not to be included

Step 3:
More filtering, but mainly related to total reserve amounts

Step 4:

First, we need to create one variable to set the "As Of" date (the date the report is run)
Two custom variables are created as well:
1. Published Reserving Tool table
• Used to get the most recent publish in Reserving Tool
2. Assigned Date table
• Used to get current examiner assigned date

Step 5:
Writing the SELECT statement part of the query

Step 6:
Formulating the Stored Procedure out of the results of the previous steps
