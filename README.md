# GDP33 Posit for RISC-V
Posits for RISC-V
Implement Posit Processing Unit on CV32E40P

Posit: Link
CV32E40P: Link

-----------------------------------------------------------------------

To commit changes: 
use "git add <filename>" to add to commit
use "git restore <filename> --staged" to remove from commit
Then "git commit", the first line is the title of the commit, then two lines down list changes starting with "*"

e.g: 
New Commit

* 1 change
* 2 change

Create new branch: "git checkout -b <branch_name>"

Push to remote branch: whilst on local branch "git push origin <remote_name>:<local_name>"

Then go to github.com and create pull request if needed, and ask for reviewer

## Clone the original CV32E40P repo
```
git clone https://github.com/openhwgroup/cv32e40p
cd cv32e40p/ 
git checkout fcd5968
```
